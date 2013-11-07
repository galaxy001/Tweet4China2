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

#ifdef DEBUG
void ExceptionCatched(NSException *exception)
{
    NSLog(@"Exception: %@", exception.callStackSymbols);
}
#endif

int main(int argc, char *argv[])
{
#ifdef DEBUG
    NSSetUncaughtExceptionHandler(ExceptionCatched);
#endif
    @autoreleasepool {
        [AppProxyCap activate];
        [AppProxyCap setProxy:AppProxy_SOCKS Host:@"127.0.0.1" Port:ShadowSocksPort];
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([HSUAppDelegate class]));
    }
}
