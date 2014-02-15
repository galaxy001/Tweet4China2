//
//  T4CDiscoverViewController.m
//  Tweet4China
//
//  Created by Jason Hsu on 14-2-14.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "T4CDiscoverViewController.h"

@interface T4CDiscoverViewController ()

@end

@implementation T4CDiscoverViewController

- (BOOL)filterData:(NSDictionary *)data
{
    if (![super filterData:data]) {
        return NO;
    }
    if ([data[@"retweet_count"] integerValue] ||
        [data[@"retweeted_status"][@"retweet_count"] integerValue] ||
        [data[@"favorite_count"] integerValue] ||
        [data[@"retweeted_status"][@"favorite_count"] integerValue]) {
        return YES;
    }
    return NO;
}

- (NSUInteger)requestCount
{
    return 200;
}

@end
