//
//  main.m
//  Tweet4China
//
//  Created by Jason Hsu on 2/27/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "HSUAppDelegate.h"
#import "HSUShadowsocksProxy.h"
#import "AppProxyCap.h"

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
        static HSUShadowsocksProxy *proxy;
        proxy = [[HSUShadowsocksProxy alloc] init];
        [proxy start];
        *shadowsocksStarted = YES;
        
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
        [AppProxyCap setProxy:AppProxy_SOCKS Host:@"127.0.0.1" Port:11010];
        while (!*shadowsocksStarted) {
            [NSThread sleepForTimeInterval:0.5];
        }
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([HSUAppDelegate class]));
    }
}
