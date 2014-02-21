//
//  HSUAttributedLabel.m
//  Tweet4China
//
//  Created by Jason Hsu on 13-12-29.
//  Copyright (c) 2013年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUAttributedLabel.h"

@implementation HSUAttributedLabel

@dynamic activeLink;

- (void)touchesBegan:(NSSet *)touches
           withEvent:(UIEvent *)event
{
//    [super touchesBegan:touches withEvent:event];
//    
    UITouch *touch = [touches anyObject];
    
    self.activeLink = [self linkAtPoint:[touch locationInView:self]];
    
    if (!self.activeLink) {
        self.longPressed = YES;
        if ([self.delegate respondsToSelector:@selector(attributedLabelDidLongPressed:)]) {
            __weak __typeof(&*self)weakSelf = self;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                if (weakSelf.longPressed) {
                    [weakSelf.delegate attributedLabelDidLongPressed:weakSelf];
                    weakSelf.longPressed = NO;
                }
            });
        }
        [super touchesBegan:touches withEvent:event];
    } else {
        self.longPressed = YES;
        if ([self.delegate respondsToSelector:@selector(attributedLabel:didSelectLinkWithURL:)]) {
            __weak __typeof(&*self)weakSelf = self;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                if (weakSelf.longPressed) {
                    weakSelf.longPressed = NO;
                    [weakSelf.delegate attributedLabel:weakSelf didSelectLinkWithURL:self.activeLink.URL];
                }
            });
        }
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self touchesEnded:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches
           withEvent:(UIEvent *)event
{
    if (self.activeLink) {
        NSTextCheckingResult *result = self.activeLink;
        self.activeLink = nil;
        
        switch (result.resultType) {
            case NSTextCheckingTypeLink:
                if (self.longPressed) {
                    self.longPressed = NO;
                    if ([self.delegate respondsToSelector:@selector(attributedLabel:didReleaseLinkWithURL:)]) {
                        [self.delegate attributedLabel:self didReleaseLinkWithURL:result.URL];
                        return;
                    }
                }
                break;
            case NSTextCheckingTypeAddress:
                if ([self.delegate respondsToSelector:@selector(attributedLabel:didSelectLinkWithAddress:)]) {
                    [self.delegate attributedLabel:self didSelectLinkWithAddress:result.addressComponents];
                    return;
                }
                break;
            case NSTextCheckingTypePhoneNumber:
                if ([self.delegate respondsToSelector:@selector(attributedLabel:didSelectLinkWithPhoneNumber:)]) {
                    [self.delegate attributedLabel:self didSelectLinkWithPhoneNumber:result.phoneNumber];
                    return;
                }
                break;
            case NSTextCheckingTypeDate:
                if (result.timeZone && [self.delegate respondsToSelector:@selector(attributedLabel:didSelectLinkWithDate:timeZone:duration:)]) {
                    [self.delegate attributedLabel:self didSelectLinkWithDate:result.date timeZone:result.timeZone duration:result.duration];
                    return;
                } else if ([self.delegate respondsToSelector:@selector(attributedLabel:didSelectLinkWithDate:)]) {
                    [self.delegate attributedLabel:self didSelectLinkWithDate:result.date];
                    return;
                }
                break;
            case NSTextCheckingTypeTransitInformation:
                if ([self.delegate respondsToSelector:@selector(attributedLabel:didSelectLinkWithTransitInformation:)]) {
                    [self.delegate attributedLabel:self didSelectLinkWithTransitInformation:result.components];
                    return;
                }
            default:
                break;
        }
        
        // Fallback to `attributedLabel:didSelectLinkWithTextCheckingResult:` if no other delegate method matched.
        if ([self.delegate respondsToSelector:@selector(attributedLabel:didSelectLinkWithTextCheckingResult:)]) {
            [self.delegate attributedLabel:self didSelectLinkWithTextCheckingResult:result];
        }
    } else {
        self.longPressed = NO;
        [super touchesEnded:touches withEvent:event];
    }
}

@end
