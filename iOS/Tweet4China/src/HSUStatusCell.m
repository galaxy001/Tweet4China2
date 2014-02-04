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
        self.backgroundColor = kWhiteColor;
        
        self.statusView = [[HSUStatusView alloc] initWithFrame:ccr(padding_S, padding_S, self.contentView.width-padding_S*4, 0)
                                                    style:[[self class] statusStyle]];
        
        [self.contentView addSubview:self.statusView];
        
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
}

- (void)setupWithData:(T4CStatusCellData *)data
{
    [super setupWithData:data];
    
    NSDictionary *rawData = data.rawData;
    BOOL retweeted = [rawData[@"retweeted_status"][@"retweeted"] boolValue] || [rawData[@"retweeted"] boolValue];
    BOOL favorited = [rawData[@"retweeted_status"][@"favorited"] boolValue] || [rawData[@"favorited"] boolValue];
    
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
//    [self setupControl:self.statusView.avatarB forKey:@"touchAvatar"];
    [self setupTapEventOnButton:self.statusView.avatarB name:@"touchAvatar"];
    
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

- (void)cellSwiped:(UIGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateEnded) {
        dispatch_async(GCDMainThread, ^{
            [self switchMode];
        });
    }
}

- (void)switchMode {
    if (self.actionV) {
        [UIView animateWithDuration:0.2 animations:^{
            self.contentView.backgroundColor = IPAD ? kWhiteColor : kClearColor;
            self.statusView.alpha = 1;
            self.actionV.alpha = 0;
        } completion:^(BOOL finish){
            [self.actionV removeFromSuperview];
            self.actionV = nil;
        }];
        self.data.mode = @"default";
    } else {
        HSUStatusActionView *actionV = [[HSUStatusActionView alloc] initWithStatus:self.data.rawData style:HSUStatusActionViewStyle_Default];
        self.actionV = actionV;
        [self.contentView addSubview:actionV];
        UIColor *actionBGC = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg_swipe_tile"]];
        actionV.backgroundColor = actionBGC;
        
        [self setupTapEventOnButton:actionV.replayB name:@"reply"];
        [self setupTapEventOnButton:actionV.retweetB name:@"retweet"];
        [self setupTapEventOnButton:actionV.favoriteB name:@"favorite"];
        [self setupTapEventOnButton:actionV.moreB name:@"more"];
        [self setupTapEventOnButton:actionV.deleteB name:@"delete"];
//        [self setupControl:actionV.replayB forKey:@"reply"];
//        [self setupControl:actionV.retweetB forKey:@"retweet"];
//        [self setupControl:actionV.favoriteB forKey:@"favorite"];
//        [self setupControl:actionV.moreB forKey:@"more"];
//        [self setupControl:actionV.deleteB forKey:@"delete"];
        
        actionV.frame = self.contentView.bounds;
        actionV.alpha = 0;
        [UIView animateWithDuration:0.2 animations:^{
            self.contentView.backgroundColor = bw(230);
            self.statusView.alpha = 0;
            actionV.alpha = 1;
        }];
        
        notification_post_with_object(HSUStatusCellOtherCellSwipedNotification, self);
        self.data.mode = @"action";
    }
}

- (void)otherCellSwiped:(NSNotification *)notification {
    if (notification.object != self) {
        if (self.actionV && !self.actionV.hidden) {
            [self switchMode];
        }
    }
}

@end
