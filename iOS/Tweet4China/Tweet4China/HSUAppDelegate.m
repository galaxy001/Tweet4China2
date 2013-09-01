//
//  HSUAppDelegate.m
//  Tweet4China
//
//  Created by Jason Hsu on 2/27/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUAppDelegate.h"
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
//    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:kShadowsocksSettings_Server];
//    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // UI initialize
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor blackColor];
    HSUTabController *tabController = [[HSUTabController alloc] init];
    self.window.rootViewController = tabController;
    self.tabController = tabController;
    [self.window makeKeyAndVisible];
    
    [self startShadowsocks];
    return YES;
}

- (void)startShadowsocks
{
    NSString *server = [[NSUserDefaults standardUserDefaults] objectForKey:kShadowsocksSettings_Server];
    NSString *remotePort = [[NSUserDefaults standardUserDefaults] objectForKey:kShadowsocksSettings_RemotePort];
    NSString *passowrd = [[NSUserDefaults standardUserDefaults] objectForKey:kShadowsocksSettings_Password];
    NSString *method = [[NSUserDefaults standardUserDefaults] objectForKey:kShadowsocksSettings_Method];
    
    if (server && remotePort && passowrd && method) {
        self.window.userInteractionEnabled = NO;
        dispatch_async(dispatch_queue_create("shadowsocks", NULL), ^{
//            set_config("209.141.36.62", "8348", "$#HAL9000!", "aes-256-cfb");
            set_config([server cStringUsingEncoding:NSASCIIStringEncoding],
                       [remotePort cStringUsingEncoding:NSASCIIStringEncoding],
                       [passowrd cStringUsingEncoding:NSASCIIStringEncoding],
                       [method cStringUsingEncoding:NSASCIIStringEncoding]);
            dispatch_async(dispatch_get_main_queue(), ^{
                self.window.userInteractionEnabled = YES;
            });
            local_main();
        });
        self.shadowsocksStarted = YES;
        [[NSNotificationCenter defaultCenter]
         postNotificationName:HSUShadowsocksStarted object:nil];
    }
}

- (BOOL)shadowsocksStarted
{
    BOOL direct = [[[NSUserDefaults standardUserDefaults] objectForKey:kShadowsocksSettings_Direct] boolValue];
    return direct || _shadowsocksStarted;
}

@end
