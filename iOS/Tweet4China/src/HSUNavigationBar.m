//
//  HSUNavitationBar.m
//  Tweet4China
//
//  Created by Jason Hsu on 2/28/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUNavigationBar.h"
#import "HSUComposeViewController.h"

@implementation HSUNavigationBar
{
    BOOL set;
}

- (void)layoutSubviews
{
    if (!set && !RUNNING_ON_IOS_7) {
        [self setBackgroundImage:[[UIImage imageNamed:@"bg_nav_bar"] stretchableImageFromCenter] forBarMetrics:UIBarMetricsDefault];
        set = YES;
    }
    [super layoutSubviews];
}

- (CGSize)sizeThatFits:(CGSize)size {
    if (RUNNING_ON_IOS_7) {
        return [super sizeThatFits:size];
    } else {
        return CGSizeMake(self.frame.size.width, 44);
    }
}

@end
