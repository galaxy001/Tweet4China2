//
//  FBCAppDelegate.m
//  FB4China
//
//  Created by Jason Hsu on 14-1-18.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "FBCAppDelegate.h"
#import "FBCTabController.h"
#import "HSUShadowsocksProxy.h"

static HSUShadowsocksProxy *proxy;

@implementation FBCAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self startShadowsocks];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor blackColor];
    
    UIViewController *tabController = [[FBCTabController alloc] init];
    
    self.window.rootViewController = tabController;
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (void)startShadowsocks
{
    NSString *server = @"95.85.33.168";
    NSString *remotePort = @"1026";
    NSString *passowrd = @"thanksgiving";
    NSString *method = @"AES-128-CFB";
    
    if (server && remotePort && passowrd && method) {
        if (proxy) {
            [proxy updateHost:server
                         port:[remotePort integerValue]
                     password:passowrd
                       method:method];
        } else {
            proxy = [[HSUShadowsocksProxy alloc] initWithHost:server
                                                         port:[remotePort integerValue]
                                                     password:passowrd
                                                       method:method];
        }
        if (![proxy startWithLocalPort:71080]) {
            exit(0);
        }
    }
}

@end
