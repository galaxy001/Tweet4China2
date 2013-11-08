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

@interface HSUHomeViewController ()

@end

@implementation HSUHomeViewController

- (id)init
{
    self = [super init];
    if (self) {
        self.dataSourceClass = [HSUHomeDataSource class];
#ifndef DEBUG
        [HSUHomeDataSource checkUnreadForViewController:self];
#endif
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(twitterLoginSuccess:)
         name:HSUTwiterLoginSuccess object:[HSUTwitterAPI shared]];
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated
{
    if (!shadowsocksStarted) {
        HSUProxySettingsViewController *psVC = [[HSUProxySettingsViewController alloc] init];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:psVC];
        [self presentViewController:nav animated:YES completion:nil];
        return;
    }
    
    if (self.dataSource.count == 0) {
        [self.refreshControl beginRefreshing];
        [self.dataSource refresh];
    }
    
    [super viewDidAppear:animated];
}

- (void)twitterLoginSuccess:(NSNotification *)notification
{
    NSError *error = notification.userInfo[@"error"];
    BOOL success = [notification.userInfo[@"success"] boolValue];
    if (error || !success) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Authorize Error" message:error.description delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
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
