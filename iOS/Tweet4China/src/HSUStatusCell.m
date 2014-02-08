//
//  HSUStatusCell.m
//  Tweet4China
//
//  Created by Jason Hsu on 3/10/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUStatusCell.h"
#import <TTTAttributedLabel/TTTAttributedLabel.h>
#import <FHSTwitterEngine/FHSTwitterEngine.h>
#import "HSUStatusView.h"
#import "HSUStatusActionView.h"
#import "T4CStatusCellData.h"

@interface HSUStatusCell ()

@property (nonatomic, weak) UIImageView *flagIV;
@property (nonatomic, weak) HSUStatusActionView *actionV;

@end

@implementation HSUStatusCell

+ (HSUStatusViewStyle)statusStyle
{
    return HSUStatusViewStyle_Default;
}

- (void)dealloc
{
    notification_remove_observer(self);
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        notification_add_observer(HSUStatusShowActionsNotification, self, @selector(showActions:));
        
        UIGestureRecognizer *longTouchGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longTouched:)];
        [self addGestureRecognizer:longTouchGesture];
        
        self.backgroundColor = kWhiteColor;
        
        self.statusView = [[HSUStatusView alloc] initWithFrame:ccr(padding_S, padding_S, self.contentView.width-padding_S*4, 0)
                                                    style:[[self class] statusStyle]];
        
        [self.contentView addSubview:self.statusView];
        
        UIButton *showActionsButton = [[UIButton alloc] init];
        [self.contentView addSubview:showActionsButton];
        self.showActionsButton = showActionsButton;
        [showActionsButton setImage:[UIImage imageNamed:@"icn_actions_more_small"]
                           forState:UIControlStateNormal];
        [showActionsButton sizeToFit];
        showActionsButton.size = ccs(showActionsButton.width*.5, showActionsButton.height*.5);
        [showActionsButton setTapTarget:self action:@selector(showActions)];
        [showActionsButton setHitTestEdgeInsets:edi(-50, -20, -20, -20)];
        
        UIImageView *flagIV = [[UIImageView alloc] init];
        [self.contentView addSubview:flagIV];
        self.flagIV = flagIV;
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.statusView.frame = ccr(self.statusView.left, self.statusView.top, self.contentView.width-padding_S*3, self.contentView.height-padding_S*2);
    self.flagIV.rightTop = ccp(self.contentView.width, 0);
    self.showActionsButton.rightBottom = ccp(self.contentView.width-10, self.contentView.height-10);
}

- (void)setupWithData:(T4CStatusCellData *)data
{
    [super setupWithData:data];
    
    if (self.statusView.style == HSUStatusActionViewStyle_Gallery) {
        self.statusView.style = HSUStatusActionViewStyle_Default;
    }
    
    BOOL retweeted = [data.mainStatus[@"retweeted"] boolValue];
    BOOL favorited = [data.mainStatus[@"favorited"] boolValue];
    
    if (retweeted && favorited) {
        self.flagIV.image = [UIImage imageNamed:@"ic_dogear_both"];
    } else if (retweeted) {
        self.flagIV.image = [UIImage imageNamed:@"ic_dogear_rt"];
    } else if (favorited) {
        self.flagIV.image = [UIImage imageNamed:@"ic_dogear_fave"];
    } else {
        self.flagIV.image = nil;
    }
    [self.flagIV sizeToFit];
    
    [self.statusView setupWithData:data];
    [self setupTapEventOnButton:self.statusView.avatarB name:@"touchAvatar"];
    [self.showActionsButton setTapTarget:self action:@selector(showActions)];
    
    self.contentView.backgroundColor = kClearColor;
    self.statusView.alpha = 1;
    self.data.mode = @"default";
    
    self.actionV.hidden = YES;
}

+ (CGFloat)heightForData:(T4CStatusCellData *)data
{
    if (data.cellHeight) {
        return data.cellHeight;
    }
    
    CGFloat height = [HSUStatusView heightForData:data constraintWidth:[HSUCommonTools winWidth] - 20 - padding_S*2] + padding_S * 2;
    data.cellHeight = height;
    return height;
}

- (void)showActions:(NSNotification *)notification {
    if (notification.object == self.data || notification.object != self) {
        if (self.actionV && !self.actionV.hidden) {
            [self showActions];
        }
    }
}

- (void)showActions
{
    if (self.actionV) {
        __weak typeof(self)weakSelf = self;
        [UIView animateWithDuration:0.2 animations:^{
            weakSelf.statusView.style = HSUStatusActionViewStyle_Default;
            [weakSelf.statusView setupWithData:weakSelf.data];
            [weakSelf.statusView setNeedsLayout];
            weakSelf.contentView.backgroundColor = IPAD ? kWhiteColor : kClearColor;
            weakSelf.actionV.alpha = 0;
        } completion:^(BOOL finish){
            [weakSelf.actionV removeFromSuperview];
            weakSelf.actionV = nil;
        }];
        self.data.mode = @"default";
    } else {
        HSUStatusActionView *actionV = [[HSUStatusActionView alloc] initWithStatus:self.data.mainStatus style:HSUStatusActionViewStyle_Inline];
        self.actionV = actionV;
        [self.contentView addSubview:actionV];
        
        [self setupTapEventOnButton:actionV.replayB name:@"reply"];
        [self setupTapEventOnButton:actionV.retweetB name:@"retweet"];
        [self setupTapEventOnButton:actionV.favoriteB name:@"favorite"];
        [self setupTapEventOnButton:actionV.rtB name:@"rt"];
        [self setupTapEventOnButton:actionV.moreB name:@"more"];
        [self setupTapEventOnButton:actionV.deleteB name:@"delete"];
        
        actionV.size = ccs(self.showActionsButton.left-20-kLargeAvatarSize-20, 36);
        actionV.leftBottom = ccp(kLargeAvatarSize+20, self.height);
        actionV.alpha = 0;
        __weak typeof(self)weakSelf = self;
        [UIView animateWithDuration:0.2 animations:^{
            weakSelf.statusView.style = HSUStatusActionViewStyle_Gallery;
            [weakSelf.statusView setupWithData:weakSelf.data];
            [weakSelf.statusView setNeedsLayout];
            weakSelf.contentView.backgroundColor = bwa(1, .8);
            actionV.alpha = 1;
        }];
        
        self.data.mode = @"action";
        notification_post_with_object(HSUStatusShowActionsNotification, self);
    }
}

- (void)longTouched:(UIGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateBegan) {
        [self.data more];
    }
}

@end
