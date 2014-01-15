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

@property (nonatomic, weak) UILabel *unreadCountLabel;

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
    
    UILabel *unreadCountLabel = [[UILabel alloc] init];
    self.unreadCountLabel = unreadCountLabel;
    [self.view addSubview:unreadCountLabel];
    unreadCountLabel.backgroundColor = kBlackColor;
    unreadCountLabel.textColor = kWhiteColor;
    unreadCountLabel.font = [UIFont boldSystemFontOfSize:10];
    unreadCountLabel.textAlignment = NSTextAlignmentCenter;
    unreadCountLabel.layer.cornerRadius = 3;
    unreadCountLabel.alpha = 0.8;
    unreadCountLabel.text = @"200";
    [unreadCountLabel sizeToFit];
    unreadCountLabel.height += 2 * unreadCountLabel.layer.cornerRadius;
    unreadCountLabel.text = nil;
    unreadCountLabel.hidden = YES;
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
    
#ifdef MakeScreenshot
    self.navigationItem.leftBarButtonItems = self.navigationItem.rightBarButtonItems = nil;
#endif
    [super viewDidAppear:animated];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    self.unreadCountLabel.rightTop = ccp(kWinWidth-kIPADMainViewPadding*2-10, -3 + self.tableView.contentInset.top);
}

- (void)unreadCountChanged
{
    self.unreadCountLabel.text = S(@"%ld", (long)self.dataSource.unreadCount);
    if (self.dataSource.unreadCount > 99) {
        self.unreadCountLabel.width = 30;
    } else {
        self.unreadCountLabel.width = 20;
    }
    self.unreadCountLabel.hidden = self.dataSource.unreadCount <= 0;
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
            
//#ifndef DEBUG
            [HSUHomeDataSource checkUnreadForViewController:self];
//#endif
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
