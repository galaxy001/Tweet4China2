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

+ (void)startRefreshing
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
    if (self.isRefreshing) {
        if ([GlobalSettings[HSUSettingSoundEffect] boolValue]) {
            NSString *soundPath = [[NSBundle mainBundle] pathForResource:@"pop" ofType:@"wav"];
            SystemSoundID soundID;
            AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath: soundPath], &soundID);
            AudioServicesPlaySystemSound(soundID);
        }
    }
    
    [super endRefreshing];
}

@end
