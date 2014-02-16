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

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"web_browser_moved_notification"]) {
        [[[UIAlertView alloc]
          initWithTitle:_("Notification")
          message:_("web_browser_moved_notification_message")
          delegate:self
          cancelButtonTitle:_("Got it")
          otherButtonTitles:nil, nil]
         show];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"web_browser_moved_notification"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

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
