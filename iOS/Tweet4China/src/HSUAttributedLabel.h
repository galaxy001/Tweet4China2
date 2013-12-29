//
//  HSUAttributedLabel.h
//  Tweet4China
//
//  Created by Jason Hsu on 13-12-29.
//  Copyright (c) 2013年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "TTTAttributedLabel.h"

@protocol HSUAttributedLabelDelegate <TTTAttributedLabelDelegate>

- (void)attributedLabel:(TTTAttributedLabel *)label
  didReleaseLinkWithURL:(NSURL *)url;

- (void)attributedLabelDidLongPressed:(TTTAttributedLabel *)label;

- (void)attributedLabel:(TTTAttributedLabel *)label
didSelectLinkWithTransitInformation:(NSDictionary *)components;

@end

@interface HSUAttributedLabel : TTTAttributedLabel

@property (nonatomic) BOOL longPressed;
@property (readwrite, nonatomic, strong) NSTextCheckingResult *activeLink;
@property (nonatomic, weak) id<HSUAttributedLabelDelegate> delegate;

- (NSTextCheckingResult *)linkAtPoint:(CGPoint)p;

@end
