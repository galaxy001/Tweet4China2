//
//  HSUNavigationBarLight.m
//  Tweet4China
//
//  Created by Jason Hsu on 4/29/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUNavigationBarLight.h"

@implementation HSUNavigationBarLight
{
    BOOL set;
}

- (void)layoutSubviews
{
    if (!set) {

    }
}

- (CGSize)sizeThatFits:(CGSize)size {
    return CGSizeMake(self.frame.size.width, 34);
}

@end
