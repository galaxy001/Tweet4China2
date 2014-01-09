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
    if (!set) {
        if (Sys_Ver < 7) {
            [self setBackgroundImage:[[UIImage imageNamed:@"bg_nav_bar"] stretchableImageFromCenter] forBarMetrics:UIBarMetricsDefault];
        } else {
            if (IPAD) {
                UIView *statusCover = [[UIView alloc] initWithFrame:ccr(0, -20, 1024, 20)];
                statusCover.backgroundColor = kBlackColor;
                [self addSubview:statusCover];
            }
        }
        set = YES;
    }
    [super layoutSubviews];
}

- (CGSize)sizeThatFits:(CGSize)size {
    if (Sys_Ver >= 7) {
        return [super sizeThatFits:size];
    } else {
        return CGSizeMake(self.frame.size.width, 44);
    }
}

@end
