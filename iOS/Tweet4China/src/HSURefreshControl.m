//
//  HSURefreshControl.m
//  Tweet4China
//
//  Created by Jason Hsu on 3/21/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSURefreshControl.h"
#import <AVFoundation/AVFoundation.h>

@implementation HSURefreshControl

- (void)dealloc
{
    notification_remove_observer(self);
}

- (id)init
{
    self = [super init];
    if (self) {
        notification_add_observer(HSUStartRefreshingNotification, self, @selector(startRefreshing));
    }
    return self;
}

- (void)startRefreshing
{
    if ([GlobalSettings[HSUSettingSoundEffect] boolValue]) {
        NSString *soundPath = [[NSBundle mainBundle] pathForResource:@"psst1" ofType:@"wav"];
        SystemSoundID soundID;
        AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath: soundPath], &soundID);
        AudioServicesPlaySystemSound(soundID);
    }
}

- (void)endRefreshing
{
    [super endRefreshing];
    if ([GlobalSettings[HSUSettingSoundEffect] boolValue]) {
        NSString *soundPath = [[NSBundle mainBundle] pathForResource:@"pop" ofType:@"wav"];
        SystemSoundID soundID;
        AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath: soundPath], &soundID);
        AudioServicesPlaySystemSound(soundID);
    }
}

@end
