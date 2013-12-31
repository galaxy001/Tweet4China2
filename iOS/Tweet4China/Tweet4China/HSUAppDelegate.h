//
//  HSUAppDelegate.h
//  Tweet4China
//
//  Created by Jason Hsu on 2/27/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HSUAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, weak) UIViewController *tabController;
@property (nonatomic, strong) NSDictionary *globalSettings;

+ (HSUAppDelegate *)shared;
- (BOOL)startShadowsocks;
- (void)stopShadowsocks;

@end
