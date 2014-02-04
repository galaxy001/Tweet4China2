//
//  T4CUserTimelineViewController.m
//  Tweet4China
//
//  Created by Jason Hsu on 14-2-4.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "T4CUserTimelineViewController.h"

@interface T4CUserTimelineViewController ()

@end

@implementation T4CUserTimelineViewController

- (id)init
{
    self = [super init];
    if (self) {
        self.useCache = NO;
    }
    return self;
}

- (NSString *)apiString
{
    return @"statuses/user_timeline";
}

- (NSDictionary *)requestParams
{
    return @{@"screen_name": self.screenName};
}

@end
