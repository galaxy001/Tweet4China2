//
//  FBCAppDelegate.h
//  FB4China
//
//  Created by Jason Hsu on 14-1-18.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HSUServerList;
@interface FBCAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, strong) HSUServerList *serverList;

@end
