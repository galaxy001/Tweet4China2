//
//  NSArray+Additions.m
//  Tweet4China
//
//  Created by Jason Hsu on 14-1-15.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "NSArray+Additions.h"

@implementation NSArray (Additions)

- (id)firstObject
{
    if (self.count) {
        return self[0];
    }
    return nil;
}

@end
