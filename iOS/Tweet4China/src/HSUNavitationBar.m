//
//  HSUNavitationBar.m
//  Tweet4China
//
//  Created by Jason Hsu on 2/28/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUNavitationBar.h"
#import "HSUComposeViewController.h"

@implementation HSUNavitationBar
{
    BOOL set;
}

- (void)layoutSubviews
{
    if (!set) {
        self.backgroundColor = rgba(72, 150, 205, 0.9);
//        UIImage *bgImg = [UIImage imageNamed:@"bg_nav_bar"];
//        bgImg = [bgImg subImageAtRect:ccr(0, 20, bgImg.size.width, bgImg.size.height-20)];
//        [self setBackgroundImage:bgImg forBarMetrics:UIBarMetricsDefault];
    }
}

- (CGSize)sizeThatFits:(CGSize)size {
    return CGSizeMake(self.frame.size.width, 34);
}

@end
