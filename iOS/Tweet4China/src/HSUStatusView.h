//
//  HSUStatusView.h
//  Tweet4China
//
//  Created by Jason Hsu on 4/27/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <TTTAttributedLabel/TTTAttributedLabel.h>
#import "T4CStatusCellData.h"

typedef NS_ENUM(NSUInteger, HSUStatusViewStyle) {
    HSUStatusViewStyle_Default = 0,
    HSUStatusViewStyle_Gallery = 1,
    HSUStatusViewStyle_Light = 2,
    HSUStatusViewStyle_Chat = 3,
};

@interface HSUStatusView : UIView <TTTAttributedLabelDelegate>

@property (nonatomic, strong) T4CStatusCellData *data;
@property (nonatomic, assign) HSUStatusViewStyle style;
@property (nonatomic, strong) UIButton *avatarB;
@property (nonatomic, weak) UIButton *imagePreviewButton;

- (id)initWithFrame:(CGRect)frame style:(HSUStatusViewStyle)style;

- (void)setupWithData:(T4CTableCellData *)cellData;
+ (CGFloat)heightForData:(T4CTableCellData *)data constraintWidth:(CGFloat)constraintWidth;

@end
