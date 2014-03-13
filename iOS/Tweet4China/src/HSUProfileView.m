//
//  HSUProfileView.m
//  Tweet4China
//
//  Created by Jason Hsu on 5/1/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUProfileView.h"
#import <AFNetworking/AFNetworking.h>

#define kLabelWidth 280
#define kNormalTextSize 13

@interface HSUProfileView ()

@property (nonatomic, strong) UIImageView *infoBGView;
@property (nonatomic, strong) UIScrollView *infoView;
@property (nonatomic, strong) UIPageControl *pager;
@property (nonatomic, strong) UIView *avatarBGView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UIImageView *verifyFlag;
@property (nonatomic, strong) UILabel *screenNameLabel;
@property (nonatomic, strong) UILabel *followedLabel;
@property (nonatomic, strong) UILabel *descLabel;
@property (nonatomic, strong) UILabel *locationLabel;
@property (nonatomic, strong) UILabel *siteLabel;

@property (nonatomic, strong) UIButton *tweetsButton;
@property (nonatomic, strong) UILabel *tweetsCountLabel;
@property (nonatomic, strong) UIButton *followingButton;
@property (nonatomic, strong) UILabel *followingCountLabel;
@property (nonatomic, strong) UIButton *followersButton;
@property (nonatomic, strong) UILabel *followersCountLabel;

@property (nonatomic, strong) UIButton *actionsButton;
@property (nonatomic, strong) UIButton *followButton;
@property (nonatomic, strong) UIButton *settingsButton;

@property (nonatomic, strong) UIButton *messagesButton;
@property (nonatomic, strong) UIButton *listButton;

@property (nonatomic, weak) UIView *contentView;

@end

@implementation HSUProfileView
{
    CGFloat buttonsPanelWidth;
    CGFloat buttonHeight;
}

- (id)initWithScreenName:(NSString *)screenName width:(CGFloat)width delegate:(id<HSUProfileViewDelegate>)delegate
{
    self = [super init];
    if (self) {
        UIView *contentView = [[UIView alloc] init];
        self.contentView = contentView;
        contentView.width = kWinWidth-kIPADMainViewPadding*2;
        [self addSubview:contentView];
        
        UIImageView *infoBGView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bg_profile_empty"]];
        [contentView addSubview:infoBGView];
        self.infoBGView = infoBGView;
        
        UIPageControl *pager = [[UIPageControl alloc] init];
        [infoBGView addSubview:pager];
        self.pager = pager;
        pager.numberOfPages = 2;
        pager.size = ccs(30, 30);
        pager.bottomCenter = ccp(infoBGView.width/2, infoBGView.height);
        pager.backgroundColor = kClearColor;
        pager.hidden = YES;
        
        UIScrollView *infoView = [[UIScrollView alloc] init];
        [contentView addSubview:infoView];
        self.infoView = infoView;
        infoView.pagingEnabled = YES;
        infoView.frame = infoBGView.frame;
        infoView.contentSize = ccs(infoView.width*2, infoView.height);
        infoView.showsHorizontalScrollIndicator = NO;
        infoView.showsVerticalScrollIndicator = NO;
        infoView.delegate = self;
        UIGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:delegate action:@selector(bannerButtonTouched)];
        [infoView addGestureRecognizer:gesture];
        
        UIView *avatarBGView = [[UIView alloc] init];
        [infoView addSubview:avatarBGView];
        self.avatarBGView = avatarBGView;
        avatarBGView.backgroundColor = kWhiteColor;
        avatarBGView.layer.cornerRadius = 4;
        avatarBGView.size = ccs(68, 68);
        if (IPAD) {
            avatarBGView.size = ccs(96, 96);
        }
        avatarBGView.topCenter = ccp(infoView.width/2, 16);
        
        UIButton *avatarButton = [[UIButton alloc] init];
        [avatarBGView addSubview:avatarButton];
        self.avatarButton = avatarButton;
        avatarButton.backgroundColor = bw(229);
        avatarButton.layer.cornerRadius = 4;
        avatarButton.size = ccs(avatarBGView.width-8, avatarBGView.height-8);
        avatarButton.center = avatarBGView.boundsCenter;
        [avatarButton setTapTarget:delegate action:@selector(avatarButtonTouched)];
        
        UILabel *nameLabel = [[UILabel alloc] init];
        [infoView addSubview:nameLabel];
        self.nameLabel = nameLabel;
        nameLabel.font = [UIFont boldSystemFontOfSize:17];
        nameLabel.textColor = kWhiteColor;
        nameLabel.textAlignment = NSTextAlignmentCenter;
        nameLabel.backgroundColor = kClearColor;
        nameLabel.shadowOffset = ccs(0, 1);
        nameLabel.shadowColor = kGrayColor;
        nameLabel.size = ccs(kLabelWidth, 17*1.2);
        nameLabel.topCenter = ccp(infoView.width/2, avatarBGView.bottom+7);
        nameLabel.text = screenName.twitterScreenName;
        
        UIImageView *verifyFlag = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icn_block_verified"]];
        [infoView addSubview:verifyFlag];
        self.verifyFlag = verifyFlag;
        verifyFlag.hidden = YES;
        
        UILabel *screenNameLabel = [[UILabel alloc] init];
        [infoView addSubview:screenNameLabel];
        self.screenNameLabel = screenNameLabel;
        screenNameLabel.font = [UIFont systemFontOfSize:kNormalTextSize];
        screenNameLabel.textColor = kWhiteColor;
        screenNameLabel.textAlignment = NSTextAlignmentCenter;
        screenNameLabel.backgroundColor = kClearColor;
        screenNameLabel.shadowOffset = ccs(0, 1);
        screenNameLabel.shadowColor = kGrayColor;
        screenNameLabel.text = screenName.twitterScreenName;
        [screenNameLabel sizeToFit];
        screenNameLabel.topCenter = ccp(infoView.width/2, nameLabel.bottom+5);
        
        UILabel *followedLabel = [[UILabel alloc] init];
        [infoView addSubview:followedLabel];
        self.followedLabel = followedLabel;
        followedLabel.font = [UIFont systemFontOfSize:10];
        followedLabel.textColor = kWhiteColor;
        followedLabel.textAlignment = NSTextAlignmentCenter;
        followedLabel.backgroundColor = rgba(0, 0, 0, .3);
        followedLabel.shadowOffset = ccs(0, 1);
        followedLabel.shadowColor = kGrayColor;
        followedLabel.layer.cornerRadius = 3;
        followedLabel.clipsToBounds = YES;
        followedLabel.text = _("FOLLOWS YOU");
        [followedLabel sizeToFit];
        followedLabel.width += 4;
        followedLabel.leftBottom = screenNameLabel.rightBottom;
        followedLabel.right += 4;
        followedLabel.hidden = YES;
        
        UILabel *descLabel = [[UILabel alloc] init];
        [infoView addSubview:descLabel];
        self.descLabel = descLabel;
        descLabel.font = [UIFont systemFontOfSize:14];
        descLabel.textColor = kWhiteColor;
        descLabel.textAlignment = NSTextAlignmentCenter;
        descLabel.backgroundColor = kClearColor;
        descLabel.lineBreakMode = NSLineBreakByWordWrapping;
        descLabel.numberOfLines = 5;
        descLabel.shadowOffset = ccs(0, 1);
        descLabel.shadowColor = kGrayColor;
        descLabel.size = ccs(infoView.width-40, infoView.width / 4);
        descLabel.left = infoView.width + 20;
        
        UILabel *locationLabel = [[UILabel alloc] init];
        [infoView addSubview:locationLabel];
        self.locationLabel = locationLabel;
        locationLabel.font = [UIFont systemFontOfSize:kNormalTextSize];
        locationLabel.textColor = kWhiteColor;
        locationLabel.textAlignment = NSTextAlignmentCenter;
        locationLabel.backgroundColor = kClearColor;
        locationLabel.shadowOffset = ccs(0, 1);
        locationLabel.shadowColor = kGrayColor;
        locationLabel.size = ccs(kLabelWidth, kNormalTextSize*1.2);
        locationLabel.topCenter = ccp(infoView.width/2*3, descLabel.bottom+5);
        
        UILabel *siteLabel = [[UILabel alloc] init];
        [infoView addSubview:siteLabel];
        self.siteLabel = siteLabel;
        siteLabel.font = [UIFont boldSystemFontOfSize:kNormalTextSize];
        siteLabel.textColor = kWhiteColor;
        siteLabel.textAlignment = NSTextAlignmentCenter;
        siteLabel.backgroundColor = kClearColor;
        siteLabel.shadowOffset = ccs(0, 1);
        siteLabel.shadowColor = kGrayColor;
        siteLabel.size = ccs(kLabelWidth, kNormalTextSize*1.2);
        siteLabel.topCenter = ccp(infoView.width/2*3, locationLabel.bottom+5);
        
        contentView.frame = infoView.bounds;
        
        UIView *referenceButtonBGView = [[UIView alloc] init];
        [contentView addSubview:referenceButtonBGView];
        if (IPAD) {
            referenceButtonBGView.backgroundColor = self.superview.backgroundColor;
        } else {
            referenceButtonBGView.backgroundColor = bw(232);
        }
        referenceButtonBGView.frame = ccr(0, infoView.bottom, contentView.width, 48);
        
        UIButton *tweetsButton = [[UIButton alloc] init];
        [referenceButtonBGView addSubview:tweetsButton];
        self.tweetsButton = tweetsButton;
        tweetsButton.backgroundColor = kWhiteColor;
        tweetsButton.frame = ccr(0, 1, 107, referenceButtonBGView.height-2);
        [tweetsButton setTitleColor:bw(153) forState:UIControlStateNormal];
        tweetsButton.titleLabel.font = [UIFont systemFontOfSize:9];
        [tweetsButton setTitle:_("TWEETS") forState:UIControlStateNormal];
        CGFloat titleWidth = [[tweetsButton titleForState:UIControlStateNormal] sizeWithFont:tweetsButton.titleLabel.font].width;
        CGFloat left = tweetsButton.width/2 - titleWidth/2 - 10;
        [tweetsButton setTitleEdgeInsets:UIEdgeInsetsMake(0, -left, 0, left)];
        [tweetsButton setTapTarget:delegate action:@selector(tweetsButtonTouched)];
        
        UILabel *tweetsCountLabel = [[UILabel alloc] init];
        [tweetsButton addSubview:tweetsCountLabel];
        self.tweetsCountLabel = tweetsCountLabel;
        tweetsCountLabel.backgroundColor = kClearColor;
        tweetsCountLabel.font = [UIFont boldSystemFontOfSize:13];
        tweetsCountLabel.textColor = kBlackColor;
        tweetsCountLabel.leftTop = ccp(10, 9);
        
        UIButton *followingButton = [[UIButton alloc] init];
        [referenceButtonBGView addSubview:followingButton];
        self.followingButton = followingButton;
        followingButton.backgroundColor = kWhiteColor;
        followingButton.frame = ccr(tweetsButton.right+1, 1, 105, tweetsButton.height);
        [followingButton setTitleColor:bw(153) forState:UIControlStateNormal];
        followingButton.titleLabel.font = [UIFont systemFontOfSize:9];
        [followingButton setTitle:_("FOLLOWING") forState:UIControlStateNormal];
        titleWidth = [[followingButton titleForState:UIControlStateNormal] sizeWithFont:followingButton.titleLabel.font].width;
        left = followingButton.width/2 - titleWidth/2 - 10;
        [followingButton setTitleEdgeInsets:UIEdgeInsetsMake(0, -left, 0, left)];
        [followingButton setTapTarget:delegate action:@selector(followingsButtonTouched)];
        
        UILabel *followingCountLabel = [[UILabel alloc] init];
        [followingButton addSubview:followingCountLabel];
        self.followingCountLabel = followingCountLabel;
        followingCountLabel.backgroundColor = kClearColor;
        followingCountLabel.font = [UIFont boldSystemFontOfSize:13];
        followingCountLabel.textColor = kBlackColor;
        followingCountLabel.leftTop = ccp(10, 9);
        
        UIButton *followersButton = [[UIButton alloc] init];
        [referenceButtonBGView addSubview:followersButton];
        self.followersButton = followersButton;
        followersButton.backgroundColor = kWhiteColor;
        followersButton.frame = ccr(followingButton.right+1, 1, 106, followingButton.height);
        [followersButton setTitleColor:bw(153) forState:UIControlStateNormal];
        followersButton.titleLabel.font = [UIFont systemFontOfSize:9];
        [followersButton setTitle:_("FOLLOWERS") forState:UIControlStateNormal];
        titleWidth = [[followersButton titleForState:UIControlStateNormal] sizeWithFont:followingButton.titleLabel.font].width;
        left = followingButton.width/2 - titleWidth/2 - 10;
        [followersButton setTitleEdgeInsets:UIEdgeInsetsMake(0, -left, 0, left)];
        [followersButton setTapTarget:delegate action:@selector(followersButtonTouched)];
        
        UILabel *followersCountLabel = [[UILabel alloc] init];
        [followersButton addSubview:followersCountLabel];
        self.followersCountLabel = followersCountLabel;
        followersCountLabel.backgroundColor = kClearColor;
        followersCountLabel.font = [UIFont boldSystemFontOfSize:13];
        followersCountLabel.textColor = kBlackColor;
        followersCountLabel.leftTop = ccp(10, 9);
        
        UIView *buttonsPanel = [[UIView alloc] init];
        [contentView addSubview:buttonsPanel];
        if (IPAD) {
            buttonsPanel.frame = ccr([referenceButtonBGView convertPoint:followersButton.rightTop fromView:contentView].x, referenceButtonBGView.top, referenceButtonBGView.width-followersButton.right, referenceButtonBGView.height-1);
        } else {
            buttonsPanel.frame = ccr(0, referenceButtonBGView.bottom, contentView.width, 48);
        }
        buttonsPanel.backgroundColor = kWhiteColor;
        
        buttonsPanelWidth = buttonsPanel.width;
        UIButton *settingsButton;
        UIButton *messagesButton;
        UIButton *followButton;
        UIButton *listButton;
        if ([screenName isEqualToString:MyScreenName]) {
            // settingsButton
            settingsButton = [[UIButton alloc] init];
            self.settingsButton = settingsButton;
            [buttonsPanel addSubview:settingsButton];
            [settingsButton setTapTarget:delegate action:@selector(settingsButtonTouched)];
            [settingsButton setBackgroundImage:[[UIImage imageNamed:@"btn_floating_segment_default"] stretchableImageFromCenter]
                                      forState:UIControlStateNormal];
            [settingsButton setBackgroundImage:[[UIImage imageNamed:@"btn_floating_segment_selected"] stretchableImageFromCenter]
                                      forState:UIControlStateHighlighted];
            [settingsButton setImage:[UIImage imageNamed:@"icn_profile_settings"] forState:UIControlStateNormal];
            settingsButton.size = ccs(42, 30);
        } else {
            
            // messagesButton
            messagesButton = [[UIButton alloc] init];
            self.messagesButton = messagesButton;
            [buttonsPanel addSubview:messagesButton];
            [messagesButton setTapTarget:delegate action:@selector(messagesButtonTouched)];
            [messagesButton setBackgroundImage:[[UIImage imageNamed:@"btn_floating_segment_default"] stretchableImageFromCenter]
                                      forState:UIControlStateNormal];
            [messagesButton setBackgroundImage:[[UIImage imageNamed:@"btn_floating_segment_selected"] stretchableImageFromCenter]
                                      forState:UIControlStateHighlighted];
            [messagesButton setImage:[UIImage imageNamed:@"icn_profile_messages"] forState:UIControlStateNormal];
            messagesButton.size = ccs(42, 30);
            
            // list button
            listButton = [[UIButton alloc] init];
            self.listButton = listButton;
            [buttonsPanel addSubview:listButton];
            [listButton setTapTarget:delegate action:@selector(listButtonTouched)];
            [listButton setBackgroundImage:[[UIImage imageNamed:@"btn_floating_segment_default"] stretchableImageFromCenter]
                                  forState:UIControlStateNormal];
            [listButton setBackgroundImage:[[UIImage imageNamed:@"btn_floating_segment_selected"] stretchableImageFromCenter]
                                  forState:UIControlStateHighlighted];
            [listButton setImage:[UIImage imageNamed:@"icn_activity_listed_default"] forState:UIControlStateNormal];
            listButton.size = ccs(42, 30);
            
            // followButton
            followButton = [[UIButton alloc] init];
            [buttonsPanel addSubview:followButton];
            self.followButton = followButton;
            [followButton setTapTarget:delegate action:@selector(followButtonTouched:)];
            followButton.imageEdgeInsets = UIEdgeInsetsMake(0, -5, 0, 0);
            followButton.titleLabel.font = [UIFont boldSystemFontOfSize:13];
            followButton.size = ccs(80, 30);
            followButton.contentEdgeInsets = edi(0, 10, 0, 10);
        }
        
        buttonHeight = buttonsPanel.height/2;
        
//        float buttonHeight = buttonsPanel.height/2;
        if (IPAD) {
//            followButton.rightCenter = ccp(buttonsPanel.width - 10, buttonHeight);
//            if (followButton) {
//                messagesButton.rightCenter = ccp(followButton.left - 10, buttonHeight);
//            } else {
//                messagesButton.rightCenter = ccp(buttonsPanel.width - 10, buttonHeight);
//            }
//            if (messagesButton) {
//                settingsButton.rightCenter = ccp(messagesButton.left - 10, buttonHeight);
//            } else {
//                settingsButton.rightCenter = ccp(buttonsPanel.width - 10, buttonHeight);
//            }
            contentView.height = referenceButtonBGView.bottom;
        } else {
//            followButton.rightCenter = ccp(buttonsPanel.width - 10, buttonHeight);
//            settingsButton.leftCenter = ccp(10, buttonHeight);
//            messagesButton.leftCenter = ccp(10, buttonHeight);
            contentView.height = buttonsPanel.bottom;
        }
//
        self.size = ccs(width, contentView.height);
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.contentView.left = self.width/2 - self.contentView.width/2;
    if (IPAD) {
        self.followButton.rightCenter = ccp(buttonsPanelWidth - 10, buttonHeight);
        if (self.followButton) {
            self.messagesButton.rightCenter = ccp(self.followButton.left - 10, buttonHeight);
        } else {
            self.messagesButton.rightCenter = ccp(buttonsPanelWidth - 10, buttonHeight);
        }
        if (self.messagesButton) {
            self.settingsButton.rightCenter = ccp(self.messagesButton.left - 10, buttonHeight);
            self.listButton.rightCenter = ccp(self.messagesButton.left - 10, buttonHeight);
        } else {
            self.settingsButton.rightCenter = ccp(buttonsPanelWidth - 10, buttonHeight);
        }
    } else {
        self.followButton.rightCenter = ccp(buttonsPanelWidth - 10, buttonHeight);
        self.settingsButton.leftCenter = ccp(10, buttonHeight);
        self.messagesButton.leftCenter = ccp(10, buttonHeight);
        self.listButton.leftCenter = ccp(self.messagesButton.right+10, buttonHeight);
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    self.pager.currentPage = (NSInteger)(scrollView.contentOffset.x / self.infoView.width);
}

- (void)setupWithProfile:(NSDictionary *)profile
{
    NSString *avatarUrl = profile[@"profile_image_url_https"];
    avatarUrl = [avatarUrl stringByReplacingOccurrencesOfString:@"normal" withString:@"bigger"];
    [self.avatarButton setImageWithUrlStr:avatarUrl forState:UIControlStateNormal placeHolder:nil success:nil failure:nil];
    self.screenNameLabel.text = [profile[@"screen_name"] twitterScreenName];
    [self.screenNameLabel sizeToFit];
    self.nameLabel.text = profile[@"name"];
    self.descLabel.text = profile[@"description"];
//    self.descLabel.size = [self.descLabel sizeThatFits:ccs(self.width-40, 0)];
//    [self.descLabel sizeToFit];
//    self.descLabel.bottomCenter = ccp(self.infoView.width/2*3, self.locationLabel.top - 5);
    self.locationLabel.text = profile[@"location"];
    self.locationLabel.topCenter = ccp(self.infoView.width/2*3, self.locationLabel.top);
    self.siteLabel.text = [self _websiteForProfile:profile];
    self.siteLabel.topCenter = ccp(self.infoView.width/2*3, self.siteLabel.top);
    self.pager.hidden = NO;
    NSString *bannerUrl = [profile[@"profile_banner_url"] stringByAppendingString:@"/mobile_retina"];
    [self.infoBGView setImageWithUrlStr:bannerUrl placeHolder:[UIImage imageNamed:@"bg_profile_empty"]];
    if ([profile[@"verified"] boolValue]) {
        self.verifyFlag.hidden = NO;
        if ([self.nameLabel.text respondsToSelector:@selector(sizeWithAttributes:)]) {
            NSDictionary *attr = @{NSFontAttributeName: self.nameLabel.font};
            self.verifyFlag.leftCenter = ccp([self.nameLabel.text sizeWithAttributes:attr].width/2 + self.nameLabel.center.x + 5, self.nameLabel.center.y);
        } else {
            self.verifyFlag.leftCenter = ccp([self.nameLabel.text sizeWithFont:self.nameLabel.font].width/2 + self.nameLabel.center.x + 5, self.nameLabel.center.y);
        }
    } else {
        self.verifyFlag.hidden = YES;
    }
    
    self.tweetsCountLabel.text = [NSString stringSplitWithCommaFromInteger:[profile[@"statuses_count"] integerValue]];
    [self.tweetsCountLabel sizeToFit];
    self.tweetsButton.titleEdgeInsets = UIEdgeInsetsMake(16, self.tweetsButton.titleEdgeInsets.left, self.tweetsButton.titleEdgeInsets.bottom, self.tweetsButton.titleEdgeInsets.right);
    self.followingCountLabel.text = [NSString stringSplitWithCommaFromInteger:[profile[@"friends_count"] integerValue]];
    [self.followingCountLabel sizeToFit];
    self.followingButton.titleEdgeInsets = UIEdgeInsetsMake(16, self.followingButton.titleEdgeInsets.left, self.followingButton.titleEdgeInsets.bottom, self.followingButton.titleEdgeInsets.right);
    self.followersCountLabel.text = [NSString stringSplitWithCommaFromInteger:[profile[@"followers_count"] integerValue]];
    [self.followersCountLabel sizeToFit];
    self.followersButton.titleEdgeInsets = UIEdgeInsetsMake(16, self.followersButton.titleEdgeInsets.left, self.followersButton.titleEdgeInsets.bottom, self.followersButton.titleEdgeInsets.right);
    
    if ([profile[@"blocked"] boolValue]) {
        [self.followButton setBackgroundImage:[[UIImage imageNamed:@"btn_standard_blue_border_default"] stretchableImageFromCenter]
                                     forState:UIControlStateNormal];
        [self.followButton setBackgroundImage:[[UIImage imageNamed:@"btn_standard_blue_border_pressed"] stretchableImageFromCenter]
                                     forState:UIControlStateHighlighted];
        [self.followButton setImage:[UIImage imageNamed:@"icn_blocked_default"] forState:UIControlStateNormal];
        self.followButton.titleLabel.font = [UIFont boldSystemFontOfSize:13];
        [self.followButton setTitleColor:rgb(85, 172, 238) forState:UIControlStateNormal];
        [self.followButton setTitle:_("Blocked") forState:UIControlStateNormal];
    } else if ([profile[@"following"] boolValue]) {
        [self.followButton setBackgroundImage:[[UIImage imageNamed:@"btn_following_default"] stretchableImageFromCenter]
                                     forState:UIControlStateNormal];
        [self.followButton setBackgroundImage:[[UIImage imageNamed:@"btn_following_pressed"] stretchableImageFromCenter]
                                     forState:UIControlStateHighlighted];
        [self.followButton setImage:[UIImage imageNamed:@"icn_follow_text_checked"] forState:UIControlStateNormal];
        [self.followButton setTitleColor:kWhiteColor forState:UIControlStateNormal];
        [self.followButton setTitle:_("Following") forState:UIControlStateNormal];
    } else {
        [self.followButton setBackgroundImage:[[UIImage imageNamed:@"btn_standard_blue_border_default"] stretchableImageFromCenter]
                                     forState:UIControlStateNormal];
        [self.followButton setBackgroundImage:[[UIImage imageNamed:@"btn_standard_blue_border_pressed"] stretchableImageFromCenter]
                                     forState:UIControlStateHighlighted];
        [self.followButton setImage:[UIImage imageNamed:@"icn_follow_text"] forState:UIControlStateNormal];
        self.followButton.titleLabel.font = [UIFont boldSystemFontOfSize:13];
        [self.followButton setTitleColor:rgb(85, 172, 238) forState:UIControlStateNormal];
        [self.followButton setTitle:_("Follow") forState:UIControlStateNormal];
    }
    [self.followButton sizeToFit];
    
    self.followButton.enabled = ![profile[@"following"] isKindOfClass:[NSString class]];
    
    [self setNeedsLayout];
}

- (NSString *)_websiteForProfile:(NSDictionary *)profile
{
    NSArray *urls = profile[@"entities"][@"url"][@"urls"];
    if (urls.count) {
        NSString *displayUrl = urls[0][@"display_url"];
        if (displayUrl.length) {
            return displayUrl;
        }
        return [[urls[0][@"url"]
                 stringByReplacingOccurrencesOfString:@"http://" withString:@""]
                stringByReplacingOccurrencesOfString:@"https://" withString:@""];
    }
    return nil;
}

- (UIImage *)avatarImage
{
    return [self.avatarButton imageForState:UIControlStateNormal];
}

- (UIImage *)bannerImage
{
    return self.infoBGView.image;
}

- (void)hideDMIndicator
{
    [self.dmIndicator removeFromSuperview];
}

- (void)showFollowed
{
    __weak typeof(self)weakSelf = self;
    [UIView animateWithDuration:.7 animations:^{
        weakSelf.screenNameLabel.left -= weakSelf.followedLabel.width / 2 + 2;
        weakSelf.followedLabel.left -= weakSelf.followedLabel.width / 2 + 2;
    } completion:^(BOOL finished) {
        weakSelf.followedLabel.hidden = NO;
        weakSelf.followedLabel.alpha = 0;
        [UIView animateWithDuration:.2 animations:^{
            weakSelf.followedLabel.alpha = 1;
        }];
    }];
}

@end
