//
//  T4CDiscoverViewController.m
//  Tweet4China
//
//  Created by Jason Hsu on 14-3-16.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "T4CDiscoverViewController.h"
#import <RETableViewManager/RETableViewManager.h>
#import <RETableViewManager/RETableViewOptionsController.h>
#import "HSUWebBrowserViewController.h"
#import "T4CHotViewController.h"
#import "HSUSettingsViewController.h"

@interface T4CDiscoverViewController ()

@property (nonatomic, strong) RETableViewManager *manager;

@property (nonatomic, strong) HSUWebBrowserViewController *webVC;
@property (nonatomic, strong) T4CHotViewController *hotVC;

@end

@implementation T4CDiscoverViewController

- (UITableViewStyle)tableViewStyle
{
    return UITableViewStyleGrouped;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.pullToRefresh = NO;
    self.infiniteScrolling = NO;
    
    self.navigationItem.rightBarButtonItems = @[self.composeBarButton, self.searchBarButton];
    
    self.view.backgroundColor = kWhiteColor;
    
#if __IPHONE_OS_VERSION_MIN_REQUIRED < 70000
    NSDictionary *attributes = @{UITextAttributeTextColor: bw(50),
                                 UITextAttributeTextShadowColor: kWhiteColor,
                                 UITextAttributeTextShadowOffset: [NSValue valueWithCGSize:ccs(0, 1)]};
    self.navigationController.navigationBar.titleTextAttributes = attributes;
#endif
    
    self.manager = [[RETableViewManager alloc] initWithTableView:self.tableView];
    
    __weak typeof(self)weakSelf = self;
    
    RETableViewSection *section = [RETableViewSection section];
    [self.manager addSection:section];
    RETableViewItem *webItem =
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
         
         weakSelf.webVC = [[HSUWebBrowserViewController alloc] init];
         [weakSelf.navigationController pushViewController:weakSelf.webVC animated:YES];
     }];
    webItem.image = [UIImage imageNamed:@"icn_web_browser"];
    [section addItem:webItem];
    
    section = [RETableViewSection section];
    [self.manager addSection:section];
    RETableViewItem *hotItem =
    [RETableViewItem itemWithTitle:_("Hot")
                     accessoryType:UITableViewCellAccessoryDisclosureIndicator
                  selectionHandler:^(RETableViewItem *item)
     {
         [item deselectRowAnimated:YES];
         weakSelf.hotVC = [[T4CHotViewController alloc] init];
         [weakSelf.navigationController pushViewController:weakSelf.hotVC animated:YES];
     }];
    hotItem.image = [UIImage imageNamed:@"icn_web_browser"];
    [section addItem:hotItem];
    
    section = [RETableViewSection section];
    [self.manager addSection:section];
    RETableViewItem *settingsItem =
    [RETableViewItem itemWithTitle:_("Settings")
                     accessoryType:UITableViewCellAccessoryDisclosureIndicator
                  selectionHandler:^(RETableViewItem *item)
     {
         [item deselectRowAnimated:YES];
         HSUSettingsViewController *settingsVC = [[HSUSettingsViewController alloc] init];
         [weakSelf.navigationController pushViewController:settingsVC animated:YES];
     }];
    settingsItem.image = [UIImage imageNamed:@"icn_web_browser"];
    [section addItem:settingsItem];
}

@end
