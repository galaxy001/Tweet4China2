//
//  main.m
//  Tweet4China
//
//  Created by Jason Hsu on 2/27/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "HSUAppDelegate.h"

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
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([HSUAppDelegate class]));
    }
}
