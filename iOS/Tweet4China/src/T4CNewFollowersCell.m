//
//  T4CNewFollowersCell.m
//  Tweet4China
//
//  Created by Jason Hsu on 14-2-2.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "T4CNewFollowersCell.h"

@interface T4CNewFollowersCell ()

@property (nonatomic, weak) UIImageView *indicator;
@property (nonatomic, strong) NSArray *avatars;
@property (nonatomic, weak) UILabel *descLabel;

@end

@implementation T4CNewFollowersCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        UIImageView *indicator = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icn_new_followers"]];
        [self.contentView addSubview:indicator];
        self.indicator = indicator;
        
        UILabel *descLabel = [[UILabel alloc] init];
        [self.contentView addSubview:descLabel];
        self.descLabel = descLabel;
        descLabel.font = [UIFont systemFontOfSize:14];
        descLabel.backgroundColor = kClearColor;
    }
    return self;
}

- (void)setupWithData:(T4CTableCellData *)data
{
    [super setupWithData:data];
    
    for (UIView *avatar in self.avatars) {
        [avatar removeFromSuperview];
    }
    NSArray *followers = data.rawData[@"followers"];
    NSMutableArray *avatars = [NSMutableArray arrayWithCapacity:followers.count];
    for (NSDictionary *follower in [followers subarrayWithRange:NSMakeRange(0, MIN(6, followers.count))]) {
        NSString *avatarUrl = follower[@"profile_image_url_https"];
        UIImageView *avatar = [[UIImageView alloc] init];
        [avatar setImageWithUrlStr:avatarUrl placeHolder:nil];
        [self.contentView addSubview:avatar];
        avatar.size = ccs(32, 32);
        [avatars addObject:avatar];
        avatar.clipsToBounds = YES;
    }
    self.avatars = avatars;
    
    NSDictionary *firstFollower = followers.firstObject;
    NSString *firstFollowerName = firstFollower[@"name"];
    NSString *title;
    if (followers.count > 1) {
        title = S(@"%@ %@ %u %@", firstFollowerName, _("and"), followers.count - 1, _("others followed you"));
    } else {
        title = S(@"%@ %@", firstFollowerName, _("followed you"));
    }
    NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithString:title];
    [attributedTitle addAttribute:NSFontAttributeName
                            value:[UIFont boldSystemFontOfSize:14]
                            range:NSMakeRange(0, firstFollowerName.length)];
    self.descLabel.attributedText = attributedTitle;
    [self.descLabel sizeToFit];
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
    self.descLabel.leftBottom = ccp(self.indicator.right + 10, self.contentView.height - 10);
}

+ (CGFloat)heightForData:(T4CTableCellData *)data
{
    return 78;
}

@end
