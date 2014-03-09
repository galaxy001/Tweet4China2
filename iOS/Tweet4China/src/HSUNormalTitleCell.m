//
//  HSUNormalTitleCell.m
//  Tweet4China
//
//  Created by Jason Hsu on 5/1/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUNormalTitleCell.h"

@implementation HSUNormalTitleCell

+ (CGFloat)heightForData:(T4CTableCellData *)data
{
    return 44;
}

- (void)setupWithData:(T4CTableCellData *)data
{
    [super setupWithData:data];
    
    self.cornerLeftTop.hidden = YES;
    self.cornerRightTop.hidden = YES;
    self.cornerLeftBottom.hidden = YES;
    self.cornerRightBottom.hidden = YES;
    self.textLabel.text = data.rawData[@"title"];
    if (IPHONE) {
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    self.backgroundColor = kWhiteColor;
    self.contentView.backgroundColor = kClearColor;
    self.textLabel.backgroundColor = kClearColor;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (IPAD && Sys_Ver >= 7) {
        // ugly code, resolve issue caused by cell.separatorInset = edi(0, tableView.width, 0, 0)
        self.textLabel.left = 14;
        [self.textLabel sizeToFit];
        self.textLabel.leftCenter = ccp(14, self.contentView.height/2);
    }
}

@end
