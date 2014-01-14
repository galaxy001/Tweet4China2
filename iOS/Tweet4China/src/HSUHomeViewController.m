//
//  HSUHomeViewController.m
//  Tweet4China
//
//  Created by Jason Hsu on 2/28/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUHomeViewController.h"
#import "HSUHomeDataSource.h"
#import "HSUProxySettingsViewController.h"
#import "HSURefreshControl.h"
#import "HSUTabController.h"
#import "HSUiPadTabController.h"

@interface HSUHomeViewController ()

@end

@implementation HSUHomeViewController

- (id)init
{
    self = [super init];
    if (self) {
        self.dataSourceClass = [HSUHomeDataSource class];
        [self checkUnread];
        notification_add_observer(HSUCheckUnreadTimeNotification, self, @selector(checkUnread));
        notification_add_observer(HSUTabControllerDidSelectViewControllerNotification, self, @selector(tabDidSelected:));
    }
    return self;
}

- (void)viewDidLoad
{
    self.navigationItem.rightBarButtonItems = @[self.composeBarButton, self.searchBarButton];
    self.navigationItem.leftBarButtonItems = @[self.actionBarButton];
    
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated
{
    if (!shadowsocksStarted) {
        [[HSUAppDelegate shared] startShadowsocks];
        return;
    }
    
    if (self.dataSource.count == 0) {
        [self.refreshControl beginRefreshing];
        [self.dataSource refresh];
    }
    
//    self.navigationItem.leftBarButtonItems = self.navigationItem.rightBarButtonItems = nil;
    [super viewDidAppear:animated];
}

//- (BOOL)prefersStatusBarHidden
//{
//    return YES;
//}

- (void)tabDidSelected:(NSNotification *)notification
{
    if (self.navigationController == notification.object) {
        if (self.view.window) {
            if (self.tableView.contentOffset.y <= 0) {
                [self.refreshControl beginRefreshing];
                [self.dataSource refresh];
            }
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
            if (self.dataSource.count) {
                [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
            }
        }
    }
}

- (void)checkUnread
{
    if (!self.dataSource ||
        (self.dataSource.count &&
         !([((HSUTabController *)self.tabBarController) hasUnreadIndicatorOnTabBarItem:self.navigationController.tabBarItem] ||
           [((HSUiPadTabController *)self.tabController) hasUnreadIndicatorOnViewController:self.navigationController]))) {
            
#ifndef DEBUG
            [HSUHomeDataSource checkUnreadForViewController:self];
#endif
        }
}

- (void)twitterLoginSuccess:(NSNotification *)notification
{
    NSError *error = notification.userInfo[@"error"];
    BOOL success = [notification.userInfo[@"success"] boolValue];
    if (error || !success) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:_("Authorize Error") message:error.description delegate:nil cancelButtonTitle:_("OK") otherButtonTitles:nil, nil];
        [alert show];
    } else {
        [self.refreshControl beginRefreshing];
        [self.dataSource refresh];
    }
}

#pragma mark - dataSource delegate
- (void)dataSourceDidFindUnread:(HSUBaseDataSource *)dataSource
{
    [super dataSourceDidFindUnread:dataSource];
}


@end
