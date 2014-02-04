//
//  HSUMessageCell.m
//  Tweet4China
//
//  Created by Jason Hsu on 5/22/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUMessageCell.h"
#import "HSUAttributedLabel.h"

@interface HSUMessageCell ()

@property (nonatomic, weak) UILabel *timeLabel;
@property (nonatomic, weak) UIImageView *contentBackground;
@property (nonatomic, weak) TTTAttributedLabel *contentLabel;
@property (nonatomic, weak) UIButton *avatarButton;
@property (nonatomic, weak) UIButton *retryButton;

@property (nonatomic, assign, getter = isMyself) BOOL myself;

@end

@implementation HSUMessageCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        UILabel *timeLabel = [[UILabel alloc] init];
        [self.contentView addSubview:timeLabel];
        self.timeLabel = timeLabel;
        timeLabel.backgroundColor = kClearColor;
        timeLabel.textColor = kGrayColor;
        timeLabel.font = [UIFont systemFontOfSize:10];
        
        UIImageView *contentBackground = [[UIImageView alloc] init];
        [self.contentView addSubview:contentBackground];
        self.contentBackground = contentBackground;
        
        TTTAttributedLabel *contentLabel = [[HSUAttributedLabel alloc] init];
        [self.contentView addSubview:contentLabel];
        self.contentLabel = contentLabel;
        contentLabel.textColor = rgb(38, 38, 38);
        contentLabel.font = [UIFont systemFontOfSize:14];
        contentLabel.backgroundColor = kClearColor;
        contentLabel.highlightedTextColor = kWhiteColor;
        contentLabel.lineBreakMode = NSLineBreakByWordWrapping;
        contentLabel.numberOfLines = 0;
        contentLabel.linkAttributes = @{(NSString *)kCTUnderlineStyleAttributeName: @(NO),
                                        (NSString *)kCTForegroundColorAttributeName: (id)cgrgb(30, 98, 164)};
        contentLabel.activeLinkAttributes = @{(NSString *)kTTTBackgroundFillColorAttributeName: (id)cgrgb(215, 230, 242),
                                              (NSString *)kTTTBackgroundCornerRadiusAttributeName: @(2)};
        contentLabel.verticalAlignment = TTTAttributedLabelVerticalAlignmentTop;
        contentLabel.lineHeightMultiple = 1;
        
        UIButton *avatarButton = [[UIButton alloc] init];
        [self.contentView addSubview:avatarButton];
        self.avatarButton = avatarButton;
        avatarButton.layer.masksToBounds = YES;
        avatarButton.size = ccs(50, 50);
        
        UIButton *retryButton = [[UIButton alloc] init];
        [self.contentView addSubview:retryButton];
        self.retryButton = retryButton;
        [retryButton setImage:[UIImage imageNamed:@"error-bubble"] forState:UIControlStateNormal];
        [retryButton sizeToFit];
        retryButton.hidden = YES;
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self.avatarButton makeCornerRadius];
    self.timeLabel.topCenter = ccp(self.contentView.width/2, 6);
    if (self.isMyself) {
        self.avatarButton.rightTop = ccp(self.contentView.width-5, 6);
        self.contentBackground.size = ccs(self.contentLabel.width+7+21, self.contentLabel.height+10);
        self.contentBackground.rightTop = ccp(self.avatarButton.left-2, self.timeLabel.bottom+6);
        self.contentLabel.leftTop = ccp(self.contentBackground.left+14, self.contentBackground.top+3);
        self.retryButton.leftTop = ccp(5, self.contentBackground.top);
    } else {
        self.avatarButton.leftTop = ccp(5, 6);
        self.contentBackground.size = ccs(self.contentLabel.width+7+21, self.contentLabel.height+10);
        self.contentBackground.leftTop = ccp(self.avatarButton.right+2, self.timeLabel.bottom+6);
        self.contentLabel.leftTop = ccp(self.contentBackground.left+14, self.contentBackground.top+3);
    }
}

+ (CGFloat)heightForData:(T4CTableCellData *)data
{
    TTTAttributedLabel *testSizeLabel = [[HSUAttributedLabel alloc] init];
    testSizeLabel.textColor = rgb(38, 38, 38);
    testSizeLabel.font = [UIFont systemFontOfSize:14];
    testSizeLabel.backgroundColor = kClearColor;
    testSizeLabel.highlightedTextColor = kWhiteColor;
    testSizeLabel.lineBreakMode = NSLineBreakByWordWrapping;
    testSizeLabel.numberOfLines = 0;
    testSizeLabel.linkAttributes = @{(NSString *)kCTUnderlineStyleAttributeName: @(NO),
                                     (NSString *)kCTForegroundColorAttributeName: (id)cgrgb(30, 98, 164)};
    testSizeLabel.activeLinkAttributes = @{(NSString *)kTTTBackgroundFillColorAttributeName: (id)cgrgb(215, 230, 242),
                                           (NSString *)kTTTBackgroundCornerRadiusAttributeName: @(2)};
    testSizeLabel.verticalAlignment = TTTAttributedLabelVerticalAlignmentTop;
    testSizeLabel.lineHeightMultiple = 1;
    
    testSizeLabel.text = data.rawData[@"text"];
    CGFloat textHeight = [testSizeLabel sizeThatFits:ccs(225, 0)].height;
    return MAX(6+10+5+7+textHeight+7+6, 6+50+6);
}

- (void)setupWithData:(T4CTableCellData *)data
{
    [super setupWithData:data];
    
//    [self setupControl:self.retryButton forKey:@"retry"];
    [self setupTapEventOnButton:self.retryButton name:@"retry"];
    
    self.retryButton.hidden = YES;
    if ([data.rawData[@"sending"] boolValue]) {
        if ([data.rawData[@"failed"] boolValue]) {
            self.timeLabel.text = _("Failed");
            self.retryButton.hidden = NO;
        } else {
            self.timeLabel.text = _("Sending...");
        }
    } else {
        NSDate *createdDate = [twitter getDateFromTwitterCreatedAt:data.rawData[@"created_at"]];
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"M/d/yyyy HH:mm"];
        self.timeLabel.text = [df stringFromDate:createdDate];
    }
    [self.timeLabel sizeToFit];
    
    self.myself = [MyScreenName isEqualToString:data.rawData[@"sender_screen_name"]];
    if (self.isMyself) {
        self.contentBackground.image = [[UIImage imageNamed:@"sms-right"] stretchableImageFromCenter];
        self.contentLabel.textAlignment = NSTextAlignmentRight;
    } else {
        self.contentBackground.image = [[UIImage imageNamed:@"sms-left"] stretchableImageFromCenter];
        self.contentLabel.textAlignment = NSTextAlignmentLeft;
    }
    self.contentLabel.text = data.rawData[@"text"];
    NSString *avatarUrl = data.rawData[@"sender"][@"profile_image_url_https"];
    avatarUrl = [avatarUrl stringByReplacingOccurrencesOfString:@"normal" withString:@"bigger"];
    [self.avatarButton setImageWithUrlStr:avatarUrl forState:UIControlStateNormal placeHolder:nil];
    CGSize size = [self.contentLabel sizeThatFits:ccs(225, 0)];
    self.contentLabel.size = ccs(MAX(size.width, 30), size.height);
//    [self setupControl:self.avatarButton forKey:@"touchAvatar"];
    [self setupTapEventOnButton:self.avatarButton name:@"touchAvatar"];
}

@end
