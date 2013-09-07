//
//  main.m
//  Tweet4China
//
//  Created by Jason Hsu on 2/27/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "HSUAppDelegate.h"
#import "AppProxyCap.h"

void set_config(const char *server, const char *remote_port, const char* password, const char* method);
int local_main();

#ifdef DEBUG
void ExceptionCatched(NSException *exception)
{
    NSLog(@"Exception: %@", exception.callStackSymbols);
}
#endif

BOOL StartProxy()
{
    // uncomment to reset settings
//    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:kShadowsocksSettings_Server];
//    [[NSUserDefaults standardUserDefaults] synchronize];
    BOOL direct = [[[NSUserDefaults standardUserDefaults] objectForKey:kShadowsocksSettings_Direct] boolValue];
    if (direct) {
        *shadowsocksStarted = YES;
        return YES;
    }
    
    NSString *server = [[NSUserDefaults standardUserDefaults] objectForKey:kShadowsocksSettings_Server];
    NSString *remotePort = [[NSUserDefaults standardUserDefaults] objectForKey:kShadowsocksSettings_RemotePort];
    NSString *passowrd = [[NSUserDefaults standardUserDefaults] objectForKey:kShadowsocksSettings_Password];
    NSString *method = [[NSUserDefaults standardUserDefaults] objectForKey:kShadowsocksSettings_Method];
    if (server && remotePort && passowrd && method) {
        dispatch_async(dispatch_queue_create("shadowsocks", NULL), ^{
            set_config([server cStringUsingEncoding:NSASCIIStringEncoding],
                       [remotePort cStringUsingEncoding:NSASCIIStringEncoding],
                       [passowrd cStringUsingEncoding:NSASCIIStringEncoding],
                       [method cStringUsingEncoding:NSASCIIStringEncoding]);
            local_main();
        });
        return YES;
    }
    return NO;
}

void shadowsocksStartedNotification()
{
    *shadowsocksStarted = YES;
}

int main(int argc, char *argv[])
{
#ifdef DEBUG
    NSSetUncaughtExceptionHandler(ExceptionCatched);
#endif
    @autoreleasepool {
        shadowsocksStarted = (BOOL *)malloc(sizeof(BOOL));
        *shadowsocksStarted = NO;
        StartProxy();
        [AppProxyCap activate];
        [AppProxyCap setProxy:AppProxy_SOCKS Host:@"127.0.0.1" Port:1080];
        while (!*shadowsocksStarted) {
            [NSThread sleepForTimeInterval:0.5];
        }
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([HSUAppDelegate class]));
    }
}
