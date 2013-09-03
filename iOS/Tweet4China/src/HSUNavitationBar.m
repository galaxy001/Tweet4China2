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
    }
}

- (CGSize)sizeThatFits:(CGSize)size {
    return CGSizeMake(self.frame.size.width, 34);
}

@end
