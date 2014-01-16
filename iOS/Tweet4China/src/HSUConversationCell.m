//
//  HSUConversationCell.m
//  Tweet4China
//
//  Created by Jason Hsu on 13/5/22.
//  Copyright (c) 2013年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUConversationCell.h"
#import "NSDate+Additions.h"

@interface HSUConversationCell ()

@property (nonatomic, weak) UIImageView *replyIcon;
@property (nonatomic, weak) UIImageView *avatarView;
@property (nonatomic, weak) UILabel *nameLabel;
@property (nonatomic, weak) UILabel *snLabel;
@property (nonatomic, weak) UILabel *timeLabel;
@property (nonatomic, weak) UILabel *contentLabel;
@property (nonatomic, weak) UIImageView *unreadIndicator;

@end

@implementation HSUConversationCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        UIImageView *replyIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ic_dm_reply_default"]];
        [self.contentView addSubview:replyIcon];
        self.replyIcon = replyIcon;
        
        UIImageView *avatarView = [[UIImageView alloc] init];
        [self.contentView addSubview:avatarView];
        self.avatarView = avatarView;
        avatarView.layer.cornerRadius = 3;
        avatarView.layer.masksToBounds = YES;
        
        UILabel *nameLabel = [[UILabel alloc] init];
        [self.contentView addSubview:nameLabel];
        self.nameLabel = nameLabel;
        nameLabel.backgroundColor = kClearColor;
        nameLabel.textColor = kBlackColor;
        nameLabel.font = [UIFont boldSystemFontOfSize:14];
        nameLabel.highlightedTextColor = kWhiteColor;
        
        UILabel *snLabel = [[UILabel alloc] init];
        [self.contentView addSubview:snLabel];
        self.snLabel = snLabel;
        snLabel.backgroundColor = kClearColor;
        snLabel.textColor = kGrayColor;
        snLabel.highlightedTextColor = kWhiteColor;
        snLabel.font = [UIFont systemFontOfSize:12];
        
        UILabel *timeLabel = [[UILabel alloc] init];
        [self.contentView addSubview:timeLabel];
        self.timeLabel = timeLabel;
        timeLabel.backgroundColor = kClearColor;
        timeLabel.textColor = kGrayColor;
        timeLabel.highlightedTextColor = kWhiteColor;
        timeLabel.font = [UIFont systemFontOfSize:12];
        
        UILabel *contentLabel = [[UILabel alloc] init];
        [self.contentView addSubview:contentLabel];
        self.contentLabel = contentLabel;
        contentLabel.backgroundColor = kClearColor;
        contentLabel.textColor = kGrayColor;
        contentLabel.highlightedTextColor = kWhiteColor;
        contentLabel.font = [UIFont systemFontOfSize:12];
        
        UIImageView *unreadIndicator = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"unread_indicator"]];
        self.unreadIndicator = unreadIndicator;
        [self.contentView addSubview:unreadIndicator];
        unreadIndicator.hidden = YES;
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.replyIcon.leftTop = ccp(10, 20);
    self.avatarView.frame = ccr(29, 10, 32, 32);
    self.nameLabel.leftTop = ccp(66, 10);
    self.timeLabel.leftTop = ccp(self.contentView.width-10-self.timeLabel.width, 12);
    self.snLabel.frame = ccr(self.nameLabel.right + 4, 12, self.timeLabel.left-self.nameLabel.right - 4, self.snLabel.height);
    self.contentLabel.frame = ccr(67, 28, self.contentView.width-67-32, self.contentLabel.height);
    self.unreadIndicator.leftTop = ccp(5, 5);
}

+ (CGFloat)heightForData:(HSUTableCellData *)data
{
    return 53;
}

- (void)setupWithData:(HSUTableCellData *)data
{
    [super setupWithData:data];
    
    NSDictionary *user = data.rawData[@"user"];
    NSString *name = user[@"name"];
    NSString *sn = [user[@"screen_name"] twitterScreenName];
    NSString *avatarUrl = user[@"profile_image_url_https"];
    NSDate *createdDate = [twitter getDateFromTwitterCreatedAt:data.rawData[@"created_at"]];
    NSString *time = createdDate.pureTwitterDisplay;
    NSDictionary *latestMessage = [data.rawData[@"messages"] lastObject];
    NSString *content = latestMessage[@"text"];
    BOOL waitingReply = [latestMessage[@"sender_screen_name"] isEqualToString:MyScreenName];
    
    self.replyIcon.hidden = !waitingReply;
    [self.avatarView setImageWithUrlStr:avatarUrl placeHolder:nil];
    self.nameLabel.text = name;
    self.snLabel.text = sn;
    self.timeLabel.text = time;
    self.contentLabel.text = content;
    self.unreadIndicator.hidden = ![data.renderData[@"unread_dm"] boolValue];
    
    [self.nameLabel sizeToFit];
    [self.snLabel sizeToFit];
    [self.timeLabel sizeToFit];
    [self.contentLabel sizeToFit];
}

@end
