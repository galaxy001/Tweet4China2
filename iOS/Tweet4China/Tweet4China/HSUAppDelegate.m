//
//  HSUAppDelegate.m
//  Tweet4China
//
//  Created by Jason Hsu on 2/27/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUAppDelegate.h"
#import "HSUTabController.h"
#import "HSUShadowsocksProxy.h"
#import "Appirater.h"
#import "HSUiPadTabController.h"

static HSUShadowsocksProxy *proxy;

@implementation HSUAppDelegate

+ (HSUAppDelegate *)shared
{
    return (HSUAppDelegate *)[UIApplication sharedApplication].delegate;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self startShadowsocks];
    [self configureAppirater];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor blackColor];
    
    UIViewController *tabController;
    if (IPAD) {
        tabController = [[HSUiPadTabController alloc] init];
    } else {
        tabController = [[HSUTabController alloc] init];
    }
    
    self.window.rootViewController = tabController;
    self.tabController = tabController;
    [self.window makeKeyAndVisible];
    
    [Appirater appLaunched:YES];
    
    return YES;
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [self startShadowsocks];
    [Appirater appEnteredForeground:YES];
}

- (void)configureAppirater
{
    [Appirater setAppId:@"445052810"];
    [Appirater setDaysUntilPrompt:1];
    [Appirater setUsesUntilPrompt:10];
    [Appirater setSignificantEventsUntilPrompt:-1];
    [Appirater setTimeBeforeReminding:2];
}

- (BOOL)startShadowsocks
{
    NSString *server = [[NSUserDefaults standardUserDefaults] objectForKey:kShadowsocksSettings_Server];
    NSString *remotePort = [[NSUserDefaults standardUserDefaults] objectForKey:kShadowsocksSettings_RemotePort];
    NSString *passowrd = [[NSUserDefaults standardUserDefaults] objectForKey:kShadowsocksSettings_Password];
    NSString *method = [[NSUserDefaults standardUserDefaults] objectForKey:kShadowsocksSettings_Method];
    if (server && remotePort && passowrd && method) {
        if (proxy == nil) {
            proxy = [[HSUShadowsocksProxy alloc] initWithHost:server port:[remotePort integerValue] password:passowrd method:method];
        }
        [proxy stop];
        return (shadowsocksStarted = [proxy startWithLocalPort:71080]);
    }
    return (shadowsocksStarted = NO);
}

@end
