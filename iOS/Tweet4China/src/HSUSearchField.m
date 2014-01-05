//
//  HSUSearchField.m
//  Tweet4China
//
//  Created by Jason Hsu on 14-1-5.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUSearchField.h"

@implementation HSUSearchField

// placeholder position
- (CGRect)textRectForBounds:(CGRect)bounds
{
    return CGRectInset(bounds, 24, 4);
}

// text position
- (CGRect)editingRectForBounds:(CGRect)bounds
{
    return CGRectInset(bounds, 24, 4);
}

@end

