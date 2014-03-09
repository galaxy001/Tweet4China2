//
//  HSUPersonCell.m
//  Tweet4China
//
//  Created by Jason Hsu on 3/10/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUPersonCell.h"
#import "T4CPersonCellData.h"
#define _NameLabelWidth (kWinWidth - kIPADMainViewPadding * 2 - kCellPadding * 2 - kLargeAvatarSize - 50 - kCellPadding * 2)

@interface HSUPersonCell ()

@property (nonatomic, weak) UIButton *followButton;
@property (nonatomic, weak) UIButton *avatarButton;
@property (nonatomic, weak) UILabel *nameLabel;
@property (nonatomic, weak) UILabel *screenNameLabel;
@property (nonatomic, weak) UIImageView *verifyFlag;
@property (nonatomic, weak) UILabel *ffInfoLabel;
@property (nonatomic, weak) UILabel *descLabel;

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
        avatarButton.layer.masksToBounds = YES;
        avatarButton.backgroundColor = bw(229);
        avatarButton.userInteractionEnabled = NO;
        
        UILabel *nameLabel = [[UILabel alloc] init];
        [self.contentView addSubview:nameLabel];
        self.nameLabel = nameLabel;
        nameLabel.textColor = kBlackColor;
        nameLabel.font = [UIFont boldSystemFontOfSize:14];
        if (Sys_Ver < 7) {
            nameLabel.highlightedTextColor = kWhiteColor;
        }
        nameLabel.backgroundColor = kClearColor;
        nameLabel.numberOfLines = 0;
        nameLabel.lineBreakMode = NSLineBreakByWordWrapping;
        nameLabel.frame = ccr(avatarButton.right+9, 10, 180, 18); // todo change 180 to variable
        
        UILabel *screenNameLabel = [[UILabel alloc] init];
        [self.contentView addSubview:screenNameLabel];
        self.screenNameLabel = screenNameLabel;
        screenNameLabel.textColor = kGrayColor;
        screenNameLabel.font = [UIFont systemFontOfSize:12];
        if (Sys_Ver < 7) {
            screenNameLabel.highlightedTextColor = kWhiteColor;
        }
        screenNameLabel.backgroundColor = kClearColor;
        screenNameLabel.size = ccs(180, 18);
        
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
        if (Sys_Ver < 7) {
            ffInfoLabel.highlightedTextColor = kWhiteColor;
        }
        ffInfoLabel.backgroundColor = kClearColor;
        ffInfoLabel.size = ccs(180, 18);
        
        UILabel *descLabel = [[UILabel alloc] init];
        [self.contentView addSubview:descLabel];
        self.descLabel = descLabel;
        descLabel.textColor = kBlackColor;
        descLabel.font = [UIFont systemFontOfSize:14];
        if (Sys_Ver < 7) {
            descLabel.highlightedTextColor = kWhiteColor;
        }
        descLabel.backgroundColor = kClearColor;
        descLabel.numberOfLines = 0;
        descLabel.lineBreakMode = NSLineBreakByWordWrapping;
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self.avatarButton makeCornerRadius];
    self.followButton.right = self.contentView.width - 10;
    self.verifyFlag.leftTop = ccp(self.nameLabel.right + 3, self.nameLabel.top);
}

- (void)setupWithData:(T4CPersonCellData *)data
{
    [super setupWithData:data];
    
    NSString *avatarUrl = data.rawData[@"profile_image_url_https"];
    avatarUrl = [avatarUrl stringByReplacingOccurrencesOfString:@"normal" withString:@"bigger"];
    [self.avatarButton setImageWithUrlStr:avatarUrl forState:UIControlStateNormal placeHolder:nil];
    
    self.nameLabel.text = data.rawData[@"name"];
    self.nameLabel.size = ccs(_NameLabelWidth, data.textHeight);
    self.screenNameLabel.text = S(@"@%@", data.rawData[@"screen_name"]);
    self.screenNameLabel.leftTop = ccp(self.nameLabel.left, self.nameLabel.bottom+2);
    
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
    NSString *ffInfoText = [NSString stringWithFormat:@"%@ %@   %@ %@",
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
                                     range:NSMakeRange(followersCountStr.length + 1 + _("Followers").length + 3, followingCountStr.length)];
    [ffInfoTextWithAttributes addAttribute:NSFontAttributeName
                                     value:[UIFont boldSystemFontOfSize:12]
                                     range:NSMakeRange(followersCountStr.length + 1 + _("Followers").length + 3, followingCountStr.length)];
    self.ffInfoLabel.attributedText = ffInfoTextWithAttributes;
    [self.ffInfoLabel sizeToFit];
    self.ffInfoLabel.leftTop = ccp(self.screenNameLabel.left, self.screenNameLabel.bottom+2);
    
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
    
    if (data.sendingFollowingRequest) {
        self.followButton.enabled = NO;
    } else {
        self.followButton.enabled = YES;
    }
    
    self.verifyFlag.hidden = ![data.rawData[@"verified"] boolValue];
    
    self.descLabel.text = data.rawData[@"description"];
    CGFloat cellWidth = IPHONE ? 280 : 586;
    self.descLabel.size = [self.descLabel sizeThatFits:ccs(cellWidth, 0)];
    self.descLabel.leftTop = ccp(self.avatarButton.left, self.ffInfoLabel.bottom + 5);
    
   [self setupTapEventOnButton:self.followButton name:@"follow"];
}

+ (CGFloat)heightForData:(T4CPersonCellData *)data
{
    if (data.textHeight) {
        return 60 + data.textHeight + data.descHeight;
    }
    
    static UILabel *testNameHeightLabel;
    static UILabel *testHeightLabel;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        testNameHeightLabel = [[UILabel alloc] init];
        testNameHeightLabel.font = [UIFont boldSystemFontOfSize:14];
        testNameHeightLabel.numberOfLines = 0;
        testNameHeightLabel.lineBreakMode = NSLineBreakByWordWrapping;
        
        testHeightLabel = [[UILabel alloc] init];
        testHeightLabel.font = [UIFont systemFontOfSize:14];
        testHeightLabel.numberOfLines = 0;
        testHeightLabel.lineBreakMode = NSLineBreakByWordWrapping;
    });
    testNameHeightLabel.text = data.rawData[@"name"];
    CGFloat cellWidth = kWinWidth - kIPADMainViewPadding * 2 - kCellPadding * 2 - kLargeAvatarSize - 50 - kCellPadding * 2;
    CGSize nameLabelSize = [testNameHeightLabel sizeThatFits:ccs(cellWidth, 0)];
    data.textHeight = nameLabelSize.height;
    
    testHeightLabel.text = data.rawData[@"description"];
    cellWidth = kWinWidth - kIPADMainViewPadding * 2 - kCellPadding * 2;
    CGSize descLabelSize = [testHeightLabel sizeThatFits:ccs(cellWidth, 0)];
    data.descHeight = descLabelSize.height;
    
    return 60 + data.textHeight + data.descHeight;
}


@end
