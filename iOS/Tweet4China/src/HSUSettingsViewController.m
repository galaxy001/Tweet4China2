//
//  HSUSettingsVC.m
//  Tweet4China
//
//  Created by Jason Hsu on 13-12-30.
//  Copyright (c) 2013年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUSettingsViewController.h"
#import <RETableViewManager/RETableViewManager.h>
#import <RETableViewManager/RETableViewOptionsController.h>
#import "HSUAccountsViewController.h"
#import "HSUShadowsocksViewController.h"
#import <Appirater/Appirater.h>
#import <HSUWebCache/HSUWebCache.h>
#import "HSUAppDelegate.h"
#import "HSUGeneralSettingsViewController.h"
#import "HSUAboutViewController.h"
#import "HSUWebBrowserViewController.h"

@interface HSUSettingsViewController () <RETableViewManagerDelegate>

@property (nonatomic, strong) RETableViewManager *manager;

@end

@implementation HSUSettingsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = _("Settings");
    self.view.backgroundColor = kWhiteColor;
    self.tableView = [[UITableView alloc] initWithFrame:self.tableView.frame style:UITableViewStyleGrouped];
    
#if __IPHONE_OS_VERSION_MIN_REQUIRED < 70000
    NSDictionary *attributes = @{UITextAttributeTextColor: bw(50),
                                 UITextAttributeTextShadowColor: kWhiteColor,
                                 UITextAttributeTextShadowOffset: [NSValue valueWithCGSize:ccs(0, 1)]};
    self.navigationController.navigationBar.titleTextAttributes = attributes;
#endif
    
    UIBarButtonItem *doneBarButtonItem = [[UIBarButtonItem alloc]
                                          initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                          target:self
                                          action:@selector(_doneButtonTouched)];
    self.navigationItem.rightBarButtonItem = doneBarButtonItem;
    
    self.manager = [[RETableViewManager alloc] initWithTableView:self.tableView];
    
    __weak typeof(self)weakSelf = self;
    
    RETableViewSection *section = [RETableViewSection section];
    [self.manager addSection:section];
    [section addItem:
     [RETableViewItem itemWithTitle:_("General")
                      accessoryType:UITableViewCellAccessoryDisclosureIndicator
                   selectionHandler:^(RETableViewItem *item)
      {
          [item deselectRowAnimated:YES];
          
          HSUGeneralSettingsViewController *generalSettingsVC = [[HSUGeneralSettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
          [weakSelf.navigationController pushViewController:generalSettingsVC animated:YES];
      }]];
    
    [section addItem:
     [RETableViewItem itemWithTitle:_("Accounts")
                      accessoryType:UITableViewCellAccessoryDisclosureIndicator
                   selectionHandler:^(RETableViewItem *item)
      {
          [item deselectRowAnimated:YES];
          
          HSUAccountsViewController *accountsVC = [[HSUAccountsViewController alloc] init];
          [weakSelf.navigationController pushViewController:accountsVC animated:YES];
      }]];
    
    [section addItem:
     [RETableViewItem itemWithTitle:_("Proxy Server")
                      accessoryType:UITableViewCellAccessoryDisclosureIndicator
                   selectionHandler:^(RETableViewItem *item)
      {
          [item deselectRowAnimated:YES];
          
          if (![[HSUAppDelegate shared] buyProApp]) {
              return ;
          }
          
          HSUShadowsocksViewController *shadowsocksVC = [[HSUShadowsocksViewController alloc] init];
          [weakSelf.navigationController pushViewController:shadowsocksVC animated:YES];
      }]];
    
    section = [RETableViewSection section];
    [self.manager addSection:section];
    RETableViewItem *wbItem =
    [RETableViewItem itemWithTitle:_("Web Browser")
                     accessoryType:UITableViewCellAccessoryDisclosureIndicator
                  selectionHandler:^(RETableViewItem *item)
     {
         
         NSUInteger useBrowserCount = [[[NSUserDefaults standardUserDefaults] objectForKey:@"UseBrowserCount"] unsignedIntegerValue];
         if (useBrowserCount ++ > 10) {
             if (![[HSUAppDelegate shared] buyProApp]) {
                 return ;
             }
         }
         [[NSUserDefaults standardUserDefaults] setInteger:useBrowserCount forKey:@"UseBrowserCount"];
         [[NSUserDefaults standardUserDefaults] synchronize];
         
         [item deselectRowAnimated:YES];
         
         if (!shadowsocksStarted) {
             [[HSUAppDelegate shared] startShadowsocks];
         }
         
         static HSUWebBrowserViewController *webVC;
         static dispatch_once_t onceToken;
         dispatch_once(&onceToken, ^{
             webVC = [[HSUWebBrowserViewController alloc] init];
         });
         [self.navigationController pushViewController:webVC animated:YES];
     }];
    wbItem.image = [UIImage imageNamed:@"icn_web_browser"];
    [section addItem:wbItem];
    
    section = [RETableViewSection section];
    [self.manager addSection:section];
    [section addItem:
     [RETableViewItem itemWithTitle:_("Rate Tweet4China")
                      accessoryType:UITableViewCellAccessoryNone
                   selectionHandler:^(RETableViewItem *item)
      {
          [Appirater rateApp];
          [item deselectRowAnimated:YES];
      }]];
    [section addItem:
     [RETableViewItem itemWithTitle:_("Help & Feedback")
                      accessoryType:UITableViewCellAccessoryNone
                   selectionHandler:^(RETableViewItem *item)
      {
          NSString *subject = S(@"[%@] Feedback", [HSUCommonTools version]);
          NSString *body = _("\nDescribe the problem please");
          NSString *url = [NSString stringWithFormat:@"mailto:support@tuoxie.me?subject=%@&body=%@",
                           [subject stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                           [body stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
          [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
          [item deselectRowAnimated:YES];
      }]];
#ifdef FreeApp
    [section addItem:
     [RETableViewItem itemWithTitle:_("Buy Pro")
                      accessoryType:UITableViewCellAccessoryNone
                   selectionHandler:^(RETableViewItem *item)
      {
          [[HSUAppDelegate shared] buyProApp];
          
          [item deselectRowAnimated:YES];
      }]];
#endif
    
    section = [RETableViewSection section];
    [self.manager addSection:section];
    [section addItem:
     [RETableViewItem itemWithTitle:_("About")
                      accessoryType:UITableViewCellAccessoryDisclosureIndicator
                   selectionHandler:^(RETableViewItem *item)
      {
          [item deselectRowAnimated:YES];
          
          HSUAboutViewController *aboutSettingsVC = [[HSUAboutViewController alloc] initWithStyle:UITableViewStyleGrouped];
          [weakSelf.navigationController pushViewController:aboutSettingsVC animated:YES];
      }]];
}

#pragma mark - actions
- (void)_doneButtonTouched
{
    // ss settings
    if (!shadowsocksStarted) {
        [[HSUAppDelegate shared] startShadowsocks];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
