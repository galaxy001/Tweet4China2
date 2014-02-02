//
//  T4CConnectViewController.m
//  Tweet4China
//
//  Created by Jason Hsu on 14-2-2.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "T4CConnectViewController.h"

@interface T4CConnectViewController ()

@property (nonatomic, assign) BOOL refreshCallbackFromLoadNewFollowers;

@end

@implementation T4CConnectViewController

- (NSString *)apiString
{
    return @"statuses/mentions_timeline";
}

@end
