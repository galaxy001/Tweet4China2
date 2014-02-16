//
//  T4CNewRetweetsCell.m
//  Tweet4China
//
//  Created by Jason Hsu on 14-2-3.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "T4CNewRetweetsCell.h"
#import "HSUStatusView.h"

@interface T4CNewRetweetsCell ()

@property (nonatomic, weak) UIImageView *indicator;
@property (nonatomic, strong) NSArray *avatars;
@property (nonatomic, weak) UILabel *descLabel;
@property (nonatomic, weak) UILabel *statusLabel;

@end

@implementation T4CNewRetweetsCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        UIImageView *indicator = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icn_new_retweets"]];
        [self.contentView addSubview:indicator];
        self.indicator = indicator;
        
        UILabel *descLabel = [[UILabel alloc] init];
        [self.contentView addSubview:descLabel];
        self.descLabel = descLabel;
        descLabel.font = [UIFont systemFontOfSize:14];
        descLabel.backgroundColor = kClearColor;
        
        UILabel *statusLabel = [[UILabel alloc] init];
        [self.contentView addSubview:statusLabel];
        self.statusLabel = statusLabel;
        statusLabel.font = [UIFont systemFontOfSize:[setting(HSUSettingTextSize) floatValue] - 2];
        statusLabel.textColor = [UIColor lightGrayColor];
        statusLabel.numberOfLines = 0;
        statusLabel.lineBreakMode = NSLineBreakByWordWrapping;
    }
    return self;
}

- (void)setupWithData:(T4CTableCellData *)data
{
    [super setupWithData:data];
    
    NSArray *retweeters = data.rawData[@"retweeters"];
    NSMutableArray *avatars = [NSMutableArray arrayWithCapacity:retweeters.count];
    for (NSDictionary *follower in [retweeters subarrayWithRange:NSMakeRange(0, MIN(6, retweeters.count))]) {
        NSString *avatarUrl = follower[@"profile_image_url_https"];
        UIImageView *avatar = [[UIImageView alloc] init];
        avatar.backgroundColor = bw(229);
        [avatar setImageWithUrlStr:avatarUrl placeHolder:nil];
        [self.contentView addSubview:avatar];
        avatar.size = ccs(32, 32);
        [avatars addObject:avatar];
        avatar.clipsToBounds = YES;
    }
    self.avatars = avatars;
    
    NSDictionary *firstRetweeter = retweeters.firstObject;
    NSString *firstRetweeterName = firstRetweeter[@"name"];
    NSString *title;
    if (retweeters.count > 1) {
        title = S(@"%@ %@ %u %@", firstRetweeterName, _("and"), retweeters.count - 1, _("others retweeted"));
    } else {
        title = S(@"%@ %@", firstRetweeterName, _("retweeted"));
    }
    NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithString:title];
    [attributedTitle addAttribute:NSFontAttributeName
                            value:[UIFont boldSystemFontOfSize:14]
                            range:NSMakeRange(0, firstRetweeterName.length)];
    self.descLabel.attributedText = attributedTitle;
    [self.descLabel sizeToFit];
    
    self.statusLabel.text = data.rawData[@"text"];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.indicator.rightTop = ccp(58, 10);
    for (NSInteger i=0; i<self.avatars.count; i++) {
        UIView *avatar = self.avatars[i];
        avatar.leftTop = ccp(self.indicator.right + 10 + i * (avatar.width + 3), 10);
        [avatar makeCornerRadius];
    }
    self.descLabel.leftTop = ccp(self.indicator.right + 10, 52);
    self.statusLabel.size = [self.statusLabel sizeThatFits:ccs(self.contentView.width-self.descLabel.left-10, 0)];
    self.statusLabel.leftTop = ccp(self.descLabel.left, self.descLabel.bottom+5);
}

+ (CGFloat)heightForData:(T4CTableCellData *)data
{
    static UILabel *statusLabel;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        statusLabel = [[UILabel alloc] init];
        statusLabel.numberOfLines = 0;
        statusLabel.lineBreakMode = NSLineBreakByWordWrapping;
    });
    statusLabel.font = [UIFont systemFontOfSize:[setting(HSUSettingTextSize) floatValue] - 2];
    statusLabel.text = data.rawData[@"text"];
    statusLabel.size = [statusLabel sizeThatFits:ccs(kWinWidth-20-48-10, 0)];
    return statusLabel.height + 80;
}

@end
