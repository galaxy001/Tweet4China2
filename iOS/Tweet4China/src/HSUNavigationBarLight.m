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
    if (!set && !RUNNING_ON_IPHONE_7) {
        [self setBackgroundImage:[[UIImage imageNamed:@"bg_nav_bar_light"] stretchableImageFromCenter] forBarMetrics:UIBarMetricsDefault];
        set = YES;
    }
    [super layoutSubviews];
}

- (CGSize)sizeThatFits:(CGSize)size {
    if (RUNNING_ON_IPHONE_7) {
        return [super sizeThatFits:size];
    } else {
        return CGSizeMake(self.frame.size.width, 44);
    }
}

@end
