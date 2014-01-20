//
//  HSUAppDelegate.h
//  Tweet4China
//
//  Created by Jason Hsu on 2/27/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WXApi.h"

@interface HSUAppDelegate : UIResponder <UIApplicationDelegate, WXApiDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, weak) UIViewController *tabController;
@property (nonatomic, strong) NSDictionary *globalSettings;
@property (nonatomic, copy) NSString *shadwosocksServer;
@property (nonatomic) BOOL hasPro;
@property (nonatomic, weak) NSTimer *checkUnreadTimer;

+ (HSUAppDelegate *)shared;
- (BOOL)startShadowsocks;
- (void)stopShadowsocks;
- (void)updateImageCacheSize;
- (BOOL)isJailBreak;
- (BOOL)buyProApp;
- (void)buyProAppIfOverCount;

@end
