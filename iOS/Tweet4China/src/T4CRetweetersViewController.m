//
//  T4CRetweetersViewController.m
//  Tweet4China
//
//  Created by Jason Hsu on 14-2-6.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "T4CRetweetersViewController.h"

@interface T4CRetweetersViewController ()

@end

@implementation T4CRetweetersViewController

- (id)init
{
    self = [super init];
    if (self) {
        self.useCache = NO;
        self.pullToRefresh = NO;
        self.infiniteScrolling = NO;
    }
    return self;
}

- (NSString *)apiString
{
    return S(@"statuses/retweets/%lld", self.statusID);
}

- (NSUInteger)requestCount
{
    return 100;
}

- (int)requestDidFinishRefreshWithData:(NSArray *)dataArr
{
    NSMutableArray *users = [NSMutableArray arrayWithCapacity:dataArr.count];
    for (NSDictionary *tweet in dataArr) {
        [users addObject:tweet[@"user"]];
    }
    return [super requestDidFinishRefreshWithData:users];
}

- (void)requestDidFinishLoadMoreWithData:(NSArray *)dataArr
{
    NSMutableArray *users = [NSMutableArray arrayWithCapacity:dataArr.count];
    for (NSDictionary *tweet in dataArr) {
        [users addObject:tweet[@"user"]];
    }
    [super requestDidFinishRefreshWithData:users];
}

@end
