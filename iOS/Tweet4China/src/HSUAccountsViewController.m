//
//  HSUAccountsViewController.m
//  Tweet4China
//
//  Created by Jason Hsu on 13-12-30.
//  Copyright (c) 2013年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUAccountsViewController.h"
#import <RETableViewManager/RETableViewManager.h>
#import "HSUProxySettingsViewController.h"
#import "HSUConversationsDataSource.h"
#import "HSUProfileDataSource.h"

@interface HSUAccountsViewController ()

@property (nonatomic, strong) RETableViewManager *manager;

@end

@implementation HSUAccountsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = _("Accounts");
    self.tableView = [[UITableView alloc] initWithFrame:self.tableView.frame style:UITableViewStyleGrouped];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.manager = [[RETableViewManager alloc] initWithTableView:self.tableView];
    
    RETableViewSection *section = [RETableViewSection section];
    [self.manager addSection:section];
    
    NSDictionary *userSettings = [[NSUserDefaults standardUserDefaults] objectForKey:HSUUserSettings];
    for (NSDictionary *us in userSettings.allValues) {
        NSString *screenName = us[@"screen_name"];
        NSString *title = S(@"@%@", screenName);
        NSDictionary *userProfiles = [[NSUserDefaults standardUserDefaults] valueForKey:HSUUserProfiles];
        if (userProfiles[screenName]) {
            title = S(@"%@ (%@)", userProfiles[screenName][@"name"], title);
        }
        UITableViewCellAccessoryType accessorType = [twitter.myScreenName isEqualToString:screenName] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        RETableViewItem *item =
        [RETableViewItem itemWithTitle:title
                         accessoryType:accessorType
                      selectionHandler:^(RETableViewItem *item)
         {
             __weak typeof(self)weakSelf = self;
             if (![screenName isEqualToString:twitter.myScreenName]) {
                 [twitter loadAccount:screenName];
                 // clear old dm cache
                 [[NSUserDefaults standardUserDefaults] removeObjectForKey:[HSUConversationsDataSource cacheKey]];
                 [[NSUserDefaults standardUserDefaults] removeObjectForKey:S(@"%@_first_id_str", [HSUProfileDataSource cacheKey])];
                 [[NSUserDefaults standardUserDefaults] synchronize];
                 if (weakSelf.navigationController.viewControllers.count > 1) {
                     [weakSelf.navigationController popViewControllerAnimated:YES];
                 } else {
                     [weakSelf dismiss];
                 }
             }
             [item deselectRowAnimated:YES];
         }];
        [section addItem:item];
        item.editingStyle = UITableViewCellEditingStyleDelete;
        item.deletionHandler = ^(RETableViewItem *item) {
            [twitter removeAccount:screenName];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:[HSUConversationsDataSource cacheKey]];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:S(@"%@_first_id_str", [HSUProfileDataSource cacheKey])];
            [[NSUserDefaults standardUserDefaults] synchronize];
        };
    }
    
    [section addItem:
     [RETableViewItem itemWithTitle:_("Add New")
                      accessoryType:UITableViewCellAccessoryDisclosureIndicator
                   selectionHandler:^(RETableViewItem *item)
      {
          [item deselectRowAnimated:YES];
          
          if (userSettings.count) {
              if (![[HSUAppDelegate shared] buyProApp]) {
                  return ;
              }
          }
          
          NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
          for (NSHTTPCookie *each in cookieStorage.cookies) {
              [cookieStorage deleteCookie:each];
          }
          [twitter authorizeByOAuth];
      }]];
    
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

@end
