//
//  HSUAppDelegate.m
//  Tweet4China
//
//  Created by Jason Hsu on 2/27/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUAppDelegate.h"
#import "HSUProxyURLProtocol.h"
#import "HSUTabController.h"

void set_config(const char *server, const char *remote_port, const char* password, const char* method);
int local_main();

@implementation HSUAppDelegate

+ (HSUAppDelegate *)shared
{
    return (HSUAppDelegate *)[UIApplication sharedApplication].delegate;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Start shadow socks proxy
    dispatch_async(dispatch_queue_create("shadowsock", NULL), ^{
        set_config("209.141.36.62", "8348", "$#HAL9000!", "aes-256-cfb");
        local_main();
    });
    
    // UI initialize
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor blackColor];
    HSUTabController *tabController = [[HSUTabController alloc] init];
    self.window.rootViewController = tabController;
    self.tabController = tabController;
    [self.window makeKeyAndVisible];
    
    return YES;
}

@end
