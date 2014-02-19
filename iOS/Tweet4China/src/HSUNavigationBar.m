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
            [self setBackgroundColor:kBlackColor];
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
    
    if (self.highter) {
        for (UIView *subview in self.subviews) {
            if ([subview isKindOfClass:[UIButton class]]) {
                subview.top = 6;
            }
        }
    }
}

- (CGSize)sizeThatFits:(CGSize)size {
    if (Sys_Ver >= 7) {
        return CGSizeMake(self.frame.size.width, self.highter ? 88 : 44);
    } else {
        return CGSizeMake(self.frame.size.width, 44);
    }
}

- (void)setHighter:(BOOL)highter
{
    _highter = highter;
    if (highter) {
        self.height = 88;
    } else {
        self.height = 44;
    }
    [self setNeedsLayout];
}

@end
