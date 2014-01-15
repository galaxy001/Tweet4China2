//
//  HSUPersonCell.m
//  Tweet4China
//
//  Created by Jason Hsu on 3/10/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUPersonCell.h"

@interface HSUPersonCell ()

@property (nonatomic, weak) UIButton *followButton;
@property (nonatomic, weak) UIButton *avatarButton;
@property (nonatomic, weak) UILabel *nameLabel;
@property (nonatomic, weak) UILabel *screenNameLabel;
@property (nonatomic, weak) UIImageView *verifyFlag;
@property (nonatomic, weak) UILabel *ffInfoLabel;

@end

@implementation HSUPersonCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        UIButton *avatarButton = [[UIButton alloc] init];
        [self.contentView addSubview:avatarButton];
        self.avatarButton = avatarButton;
        avatarButton.frame = ccr(14, 10, 48, 48);
        avatarButton.layer.cornerRadius = 4;
        avatarButton.layer.masksToBounds = YES;
        avatarButton.backgroundColor = bw(229);
        
        UILabel *nameLabel = [[UILabel alloc] init];
        [self.contentView addSubview:nameLabel];
        self.nameLabel = nameLabel;
        nameLabel.textColor = kBlackColor;
        nameLabel.font = [UIFont boldSystemFontOfSize:14];
        nameLabel.highlightedTextColor = kWhiteColor;
        nameLabel.backgroundColor = kClearColor;
        nameLabel.frame = ccr(avatarButton.right+9, 10, 180, 18); // todo change 180 to variable
        
        UILabel *screenNameLabel = [[UILabel alloc] init];
        [self.contentView addSubview:screenNameLabel];
        self.screenNameLabel = screenNameLabel;
        screenNameLabel.textColor = kGrayColor;
        screenNameLabel.font = [UIFont systemFontOfSize:12];
        screenNameLabel.highlightedTextColor = kWhiteColor;
        screenNameLabel.backgroundColor = kClearColor;
        screenNameLabel.frame = ccr(nameLabel.left, nameLabel.bottom+2, 180, 18);
        
        UIButton *followButton = [[UIButton alloc] init];
        [self.contentView addSubview:followButton];
        self.followButton = followButton;
        followButton.size = ccs(50, 29);
        followButton.top = 10;
        
        UIImageView *verifyFlag = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icn_block_verified"]];
        [self.contentView addSubview:verifyFlag];
        self.verifyFlag = verifyFlag;
        verifyFlag.hidden = YES;
        
        UILabel *ffInfoLabel = [[UILabel alloc] init];
        [self.contentView addSubview:ffInfoLabel];
        self.ffInfoLabel = ffInfoLabel;
        ffInfoLabel.textColor = kGrayColor;
        ffInfoLabel.font = [UIFont systemFontOfSize:12];
        ffInfoLabel.highlightedTextColor = kWhiteColor;
        ffInfoLabel.backgroundColor = kClearColor;
        ffInfoLabel.frame = ccr(screenNameLabel.left, screenNameLabel.bottom+2, 180, 18);
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.followButton.right = self.contentView.width - 10;
    self.verifyFlag.leftTop = ccp(self.nameLabel.right + 3, self.nameLabel.top);
}

- (void)setupWithData:(HSUTableCellData *)data
{
    [super setupWithData:data];
    
    NSString *avatarUrl = data.rawData[@"profile_image_url_https"];
    avatarUrl = [avatarUrl stringByReplacingOccurrencesOfString:@"normal" withString:@"bigger"];
    [self.avatarButton setImageWithUrlStr:avatarUrl forState:UIControlStateNormal placeHolder:nil];
    [self setupControl:self.avatarButton forKey:@"touchAvatar"];
    
    self.nameLabel.text = data.rawData[@"name"];
    [self.nameLabel sizeToFit];
    self.screenNameLabel.text = S(@"@%@", data.rawData[@"screen_name"]);
    
    int followersCount = [data.rawData[@"followers_count"] intValue];
    int followingCount = [data.rawData[@"friends_count"] intValue];
    NSString *followersCountStr = S(@"%d", followersCount);
    NSString *followingCountStr = S(@"%d", followingCount);
    if (followersCount > 1000 * 1000) {
        followersCountStr = S(@"%0.1fM", followersCount/1000.0/1000.0);
    } else if (followersCount > 1000) {
        followersCountStr = S(@"%0.1fK", followersCount/1000.0);
    }
    if (followingCount > 1000 * 1000) {
        followingCountStr = S(@"%0.1fM", followingCount/1000.0/1000.0);
    } else if (followingCount > 1000) {
        followingCountStr = S(@"%0.1fK", followingCount/1000.0);
    }
    NSString *ffInfoText = [NSString stringWithFormat:@"%@ %@ %@ %@",
                            followersCountStr, _("Followers"), followingCountStr, _("Following")];
    NSMutableAttributedString *ffInfoTextWithAttributes = [[NSMutableAttributedString alloc] initWithString:ffInfoText];
    [ffInfoTextWithAttributes addAttribute:NSForegroundColorAttributeName
                                     value:kBlackColor
                                     range:NSMakeRange(0, followersCountStr.length)];
    [ffInfoTextWithAttributes addAttribute:NSFontAttributeName
                                     value:[UIFont boldSystemFontOfSize:12]
                                     range:NSMakeRange(0, followersCountStr.length)];
    [ffInfoTextWithAttributes addAttribute:NSForegroundColorAttributeName
                                     value:kBlackColor
                                     range:NSMakeRange(followersCountStr.length + 1 + _("Followers").length + 1, followingCountStr.length)];
    [ffInfoTextWithAttributes addAttribute:NSFontAttributeName
                                     value:[UIFont boldSystemFontOfSize:12]
                                     range:NSMakeRange(followersCountStr.length + 1 + _("Followers").length + 1, followingCountStr.length)];
    self.ffInfoLabel.attributedText = ffInfoTextWithAttributes;
    [self.ffInfoLabel sizeToFit];
    
    if ([data.rawData[@"following"] boolValue]) {
        [self.followButton setBackgroundImage:[[UIImage imageNamed:@"btn_following_default"] stretchableImageFromCenter]
                                     forState:UIControlStateNormal];
        [self.followButton setBackgroundImage:[[UIImage imageNamed:@"btn_following_pressed"] stretchableImageFromCenter]
                                     forState:UIControlStateHighlighted];
        [self.followButton setImage:[UIImage imageNamed:@"icn_follow_text_checked"] forState:UIControlStateNormal];
    } else {
        [self.followButton setBackgroundImage:[[UIImage imageNamed:@"btn_standard_blue_border_default"] stretchableImageFromCenter]
                                     forState:UIControlStateNormal];
        [self.followButton setBackgroundImage:[[UIImage imageNamed:@"btn_standard_blue_border_pressed"] stretchableImageFromCenter]
                                     forState:UIControlStateHighlighted];
        [self.followButton setImage:[UIImage imageNamed:@"icn_follow_text"] forState:UIControlStateNormal];
    }
    
    if ([data.renderData[@"sending_following_request"] boolValue]) {
        self.followButton.enabled = NO;
    } else {
        self.followButton.enabled = YES;
    }
    
    self.verifyFlag.hidden = ![data.rawData[@"verified"] boolValue];
    
    [self setupControl:self.followButton forKey:@"follow"];
}

+ (CGFloat)heightForData:(HSUTableCellData *)data
{
    return 75;
}

@end
