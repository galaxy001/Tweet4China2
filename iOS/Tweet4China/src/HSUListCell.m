//
//  HSUListCell.m
//  Tweet4China
//
//  Created by Jason Hsu on 2013/12/2.
//  Copyright (c) 2013年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUListCell.h"

@interface HSUListCell ()

@property (nonatomic, weak) UILabel *nameLabel;
@property (nonatomic, weak) UILabel *creatorLabel;
@property (nonatomic, weak) UILabel *descLabel;
@property (nonatomic, weak) UIImageView *modeIcon;
@property (nonatomic, weak) UILabel *memberCountLabel;
@property (nonatomic, weak) UIImageView *creatorAvatar;

@end

@implementation HSUListCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = kWhiteColor;
        
        UILabel *nameLabel = [[UILabel alloc] init];
        self.nameLabel = nameLabel;
        [self.contentView addSubview:nameLabel];
        nameLabel.backgroundColor = kClearColor;
        nameLabel.font = [UIFont boldSystemFontOfSize:14];
        if (Sys_Ver < 7) {
            nameLabel.highlightedTextColor = kWhiteColor;
        }
        
        UILabel *descLabel = [[UILabel alloc] init];
        self.descLabel = descLabel;
        [self.contentView addSubview:descLabel];
        descLabel.backgroundColor = kClearColor;
        descLabel.font = [UIFont systemFontOfSize:14];
        descLabel.numberOfLines = 0;
        descLabel.lineBreakMode = NSLineBreakByWordWrapping;
        if (Sys_Ver < 7) {
            descLabel.highlightedTextColor = kWhiteColor;
        }
        
        UILabel *creatorLabel = [[UILabel alloc] init];
        self.creatorLabel = creatorLabel;
        [self.contentView addSubview:creatorLabel];
        creatorLabel.backgroundColor = kClearColor;
        creatorLabel.font = [UIFont systemFontOfSize:12];
        creatorLabel.textColor = kLightBlueColor;
        if (Sys_Ver < 7) {
            creatorLabel.highlightedTextColor = kWhiteColor;
        }
        
        UIImageView *modeIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icn_locked"]];
        self.modeIcon = modeIcon;
        [self.contentView addSubview:modeIcon];
        modeIcon.hidden = YES;
        
        UILabel *memberCountLabel = [[UILabel alloc] init];
        self.memberCountLabel = memberCountLabel;
        [self.contentView addSubview:memberCountLabel];
        memberCountLabel.backgroundColor = kClearColor;
        memberCountLabel.font = [UIFont systemFontOfSize:12];
        memberCountLabel.textColor = kLightBlueColor;
        if (Sys_Ver < 7) {
            memberCountLabel.highlightedTextColor = kWhiteColor;
        }
        
        UIImageView *creatorAvatar = [[UIImageView alloc] init];
        self.creatorAvatar = creatorAvatar;
        [self.contentView addSubview:creatorAvatar];
        creatorAvatar.size = ccs(32, 32);
        creatorAvatar.layer.cornerRadius = 5;
        creatorAvatar.clipsToBounds = YES;
    }
    return self;
}

- (void)setupWithData:(HSUTableCellData *)data
{
    NSString *name = data.rawData[@"name"];
    NSString *creatorName = [NSString stringWithFormat:@"by %@", data.rawData[@"user"][@"name"]];
    NSString *memberCount = data.rawData[@"member_count"];
    NSString *description = data.rawData[@"description"];
    NSString *creatorAvatarUrl = data.rawData[@"user"][@"profile_image_url_https"];
    NSString *mode = data.rawData[@"mode"];
    
    self.nameLabel.text = name;
    self.creatorLabel.text = creatorName;
    self.memberCountLabel.text = [NSString stringWithFormat:@"%@ members", memberCount];
    self.descLabel.text = description;
    self.modeIcon.hidden = [mode isEqualToString:@"public"];
    [self.creatorAvatar setImageWithUrlStr:creatorAvatarUrl placeHolder:nil];
    
    if ([data.renderData[@"hide_creator"] boolValue]) {
        self.creatorAvatar.hidden = YES;
    }
    
    if ([data.renderData[@"listed"] boolValue]) {
        self.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        self.accessoryType = UITableViewCellAccessoryNone;
    }
}

+ (CGFloat)heightForData:(HSUTableCellData *)data
{
    NSString *description = data.rawData[@"description"];
    CGSize descSize = [description
                       sizeWithFont:[UIFont systemFontOfSize:14]
                       constrainedToSize:ccs([HSUCommonTools winWidth]-62, 1000)];
    return floorf(descSize.height) + 47;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self.nameLabel sizeToFit];
    [self.creatorLabel sizeToFit];
    [self.memberCountLabel sizeToFit];
    self.descLabel.size = [self.descLabel sizeThatFits:ccs(self.contentView.width - 62, 0)];
    
    self.nameLabel.leftTop = ccp(12, 7);
    self.creatorLabel.leftBottom = self.nameLabel.rightBottom;
    self.creatorLabel.left += 5;
    self.modeIcon.leftCenter = self.creatorLabel.rightCenter;
    self.descLabel.leftTop = self.nameLabel.leftBottom;
    if (self.descLabel.text) {
        self.memberCountLabel.leftTop = self.descLabel.leftBottom;
    } else {
        self.memberCountLabel.leftTop = self.nameLabel.leftBottom;
    }
    self.creatorAvatar.rightTop = ccp(self.contentView.width-12, 10);
}

@end
