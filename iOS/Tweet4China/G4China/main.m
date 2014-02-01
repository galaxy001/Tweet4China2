//
//  main.m
//  G4China
//
//  Created by Jason Hsu on 14-1-31.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "G4CAppDelegate.h"
#import "AppProxyCap.h"

int main(int argc, char * argv[])
{
    @autoreleasepool {
        [AppProxyCap activate];
        [AppProxyCap setProxy:AppProxy_SOCKS Host:@"127.0.0.1" Port:71080];
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([G4CAppDelegate class]));
    }
}
