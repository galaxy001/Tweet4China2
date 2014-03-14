//
//  T4CHomeViewController.m
//  Tweet4China
//
//  Created by Jason Hsu on 14-1-25.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "T4CHomeViewController.h"
#import <SVPullToRefresh/SVPullToRefresh.h>

@interface T4CHomeViewController ()

@end

@implementation T4CHomeViewController

- (id)init
{
    self = [super init];
    if (self) {
        self.showUnreadCount = YES;
        notification_add_observer(HSUUserUnfollowedNotification, self, @selector(unfowllowedUser:));
    }
    return self;
}

- (NSString *)apiString
{
    return @"statuses/home_timeline";
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [super scrollViewDidScroll:scrollView];
    
    if (scrollView.contentOffset.y <= scrollView.contentInset.top) {
        self.unreadCount = 0;
        [self unreadCountChanged];
    }
}

//#ifdef DEBUG
//- (NSUInteger)requestCount
//{
//    return 3;
//}
//#endif

- (int)requestDidFinishRefreshWithData:(NSArray *)dataArr
{
    int r = [super requestDidFinishRefreshWithData:dataArr];
    
    [[HSUAppDelegate shared] askFollowAuthor];
    [[HSUAppDelegate shared] buyProAppIfOverCount];
    
    return r;
}

- (void)requestDidFinishRefreshWithError:(NSError *)error
{
    [super requestDidFinishRefreshWithError:error];
    
    if (!error || error.code == 204) { // no err, no data
        [[HSUAppDelegate shared] buyProAppIfOverCount];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem = self.actionBarButton;
    self.navigationItem.rightBarButtonItems = @[self.composeBarButton, self.searchBarButton];
}

- (void)unfowllowedUser:(NSNotification *)notification
{
    NSString *sn = notification.object;
    [self.data filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        T4CTableCellData *cellData = evaluatedObject;
        return ![cellData.rawData[@"user"][@"screen_name"] isEqualToString:sn];
    }]];
    [self.tableView reloadData];
}

@end
