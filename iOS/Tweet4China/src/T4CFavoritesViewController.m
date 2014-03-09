//
//  T4CFavoritesViewController.m
//  Tweet4China
//
//  Created by Jason Hsu on 14-2-4.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "T4CFavoritesViewController.h"

@interface T4CFavoritesViewController ()

@end

@implementation T4CFavoritesViewController

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
    return @"favorites/list";
}

- (NSDictionary *)requestParams
{
    return @{@"screen_name": self.screenName};
}

@end
