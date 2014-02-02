//
//  HSUBaseTableCell.m
//  Tweet4China
//
//  Created by Jason Hsu on 3/10/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUBaseTableCell.h"
#import "HSUUIEvent.h"

@implementation HSUBaseTableCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
#ifdef __IPHONE_7_0
        if (Sys_Ver >= 7) {
            self.separatorInset = edi(0, 0, 0, 0);
        }
#endif
        if (IPAD) {
            UIImageView *cornerLeftTop = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"table_corner_left_top"]];
            UIImageView *cornerRightTop = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"table_corner_right_top"]];
            UIImageView *cornerLeftBottom = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"table_corner_left_bottom"]];
            UIImageView *cornerRightBottom = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"table_corner_right_bottom"]];
            
            self.cornerLeftTop = cornerLeftTop;
            self.cornerRightTop = cornerRightTop;
            self.cornerLeftBottom = cornerLeftBottom;
            self.cornerRightBottom = cornerRightBottom;
            
            [self.contentView addSubview:cornerLeftTop];
            [self.contentView addSubview:cornerRightTop];
            [self.contentView addSubview:cornerLeftBottom];
            [self.contentView addSubview:cornerRightBottom];
            
            cornerLeftTop.hidden = YES;
            cornerRightTop.hidden = YES;
            cornerLeftBottom.hidden = YES;
            cornerRightBottom.hidden = YES;
            
            self.selectionStyle = UITableViewCellSelectionStyleNone;
        }
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (IPAD) {
        self.contentView.width = kWinWidth - kIPADMainViewPadding*2;
        self.contentView.topCenter = ccp(self.center.x, self.contentView.top);
        self.backgroundColor = rgb(244, 248, 251);
        self.contentView.backgroundColor = kWhiteColor;
        self.cornerRightTop.right = self.contentView.width;
    }
}

- (void)setupControl:(UIControl *)control forKey:(NSString *)key
{
    [self setupControl:control forKey:key cleanOldEvents:YES];
}

- (void)setupControl:(UIControl *)control forKey:(NSString *)key cleanOldEvents:(BOOL)clean
{
    HSUUIEvent *event = self.data.events[key];
    if (event) {
        if (clean) {
            [control removeTarget:nil action:NULL forControlEvents:event.events];
        }
        [control addTarget:event action:@selector(fire:) forControlEvents:event.events];
    }
}

- (void)setupWithData:(T4CTableCellData *)data
{
    self.data = data;
}

+ (CGFloat)heightForData:(T4CTableCellData *)data
{
    return 0;
}

@end
