//
//  T4CFollowersViewController.m
//  Tweet4China
//
//  Created by Jason Hsu on 14-2-4.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "T4CFollowersViewController.h"

@interface T4CFollowersViewController ()

@end

@implementation T4CFollowersViewController

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
    return @"followers/list";
}

- (NSDictionary *)requestParams
{
    return @{@"screen_name": self.screenName};
}

- (NSString *)dataKey
{
    return @"users";
}

@end
