//
//  HSUDraftsCell.m
//  Tweet4China
//
//  Created by Jason Hsu on 5/16/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUDraftsCell.h"

@interface HSUDraftsCell ()

@property (nonatomic, weak) UIView *countView;
@property (nonatomic, weak) UILabel *countLabel;

@end

@implementation HSUDraftsCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        UIView *countView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"bg_dm_count"] stretchableImageFromCenter]];
        [self.contentView addSubview:countView];
        self.countView = countView;
        countView.width = 30;
        
        UILabel *countLabel = [[UILabel alloc] init];
        [self.contentView addSubview:countLabel];
        self.countLabel = countLabel;
        countLabel.textColor = kWhiteColor;
        countLabel.backgroundColor = kClearColor;
        countLabel.font = [UIFont boldSystemFontOfSize:12];
    }
    return self;
}

+ (CGFloat)heightForData:(T4CTableCellData *)data
{
    return 44;
}

- (void)setupWithData:(T4CTableCellData *)data
{
    [super setupWithData:data];
    
    self.textLabel.text = data.rawData[@"title"];
    self.backgroundColor = kWhiteColor;
    self.contentView.backgroundColor = kClearColor;
    self.textLabel.backgroundColor = kClearColor;
    
    int count = [data.rawData[@"count"] intValue];
    self.countLabel.text = S(@"%d", count);
    [self.countLabel sizeToFit];
    self.countLabel.hidden = !count;
    self.countView.hidden = !count;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.countView.rightCenter = ccp(self.contentView.width - 10, self.contentView.height/2);
    self.countLabel.center = self.countView.center;
    
    if (IPAD && Sys_Ver >= 7) {
        // ugly code, resolve issue caused by cell.separatorInset = edi(0, tableView.width, 0, 0)
        self.textLabel.left = 14;
        [self.textLabel sizeToFit];
        self.textLabel.leftCenter = ccp(14, self.contentView.height/2);
    }
}

@end
