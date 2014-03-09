//
//  T4CTagTimelineViewController.m
//  Tweet4China
//
//  Created by Jason Hsu on 14-2-4.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "T4CTagTimelineViewController.h"
#import <FHSTwitterEngine/NSString+URLEncoding.h>

@interface T4CTagTimelineViewController ()

@end

@implementation T4CTagTimelineViewController

- (id)init
{
    self = [super init];
    if (self) {
        self.useCache = NO;
        self.pullToRefresh = NO;
    }
    return self;
}

- (NSString *)apiString
{
    return @"search/tweets";
}

- (NSUInteger)requestCount
{
    return 100;
}

- (NSDictionary *)requestParams
{
    return @{@"q": S(@"#%@", self.tag).URLEncodedString};
}

- (NSString *)dataKey
{
    return @"statuses";
}

@end
