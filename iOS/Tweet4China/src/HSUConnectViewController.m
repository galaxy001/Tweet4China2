//
//  HSUMemtionViewController.m
//  Tweet4China
//
//  Created by Jason Hsu on 2/28/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUConnectViewController.h"
#import "HSUConnectDataSource.h"
#import "HSURefreshControl.h"
#import "HSUTabController.h"
#import "HSUiPadTabController.h"

@interface HSUConnectViewController ()

@end

@implementation HSUConnectViewController

- (id)init
{
    self = [super init];
    if (self) {
        self.dataSourceClass = [HSUConnectDataSource class];
        [self checkUnread];
        notification_add_observer(HSUCheckUnreadTimeNotification, self, @selector(checkUnread));
        notification_add_observer(HSUTabControllerDidSelectViewControllerNotification, self, @selector(tabDidSelected:));
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (self.dataSource.count == 0) {
        [self.refreshControl beginRefreshing];
        [self.dataSource refresh];
    }
}

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
            [HSUConnectDataSource checkUnreadForViewController:self];
#endif
    }
}

#pragma mark - dataSource delegate
- (void)dataSourceDidFindUnread:(HSUBaseDataSource *)dataSource
{
    [super dataSourceDidFindUnread:dataSource];
}

#pragma mark - TableView delegate

@end
