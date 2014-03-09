//
//  HSUStatusCell.h
//  Tweet4China
//
//  Created by Jason Hsu on 3/10/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HSUBaseTableCell.h"
#import "HSUStatusView.h"
#import "T4CStatusCellData.h"

#define padding_S 10

#define HSUStatusCellOtherCellSwipedNotification @"HSUStatusCell_OtherCellSwiped"

@class HSUStatusView;
@interface HSUStatusCell : HSUBaseTableCell

@property (nonatomic, strong) T4CStatusCellData *data;
@property (nonatomic, strong) HSUStatusView *statusView;
@property (nonatomic, weak) UIButton *showActionsButton;

+ (HSUStatusViewStyle)statusStyle;

@end
