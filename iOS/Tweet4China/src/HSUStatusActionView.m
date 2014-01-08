//
//  HSUStatusActionView.m
//  Tweet4China
//
//  Created by Jason Hsu on 4/27/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUStatusActionView.h"

@implementation HSUStatusActionView
{
    BOOL isMyTweet;
}

- (id)initWithStatus:(NSDictionary *)status style:(HSUStatusActionViewStyle)style
{
    self = [super init];
    if (self) {
        if (status[@"retweeted_status"]) {
            status = status[@"retweeted_status"];
        }
        
        isMyTweet = [status[@"user"][@"screen_name"] isEqualToString:TWENGINE.myScreenName];
        
        self.backgroundColor = kClearColor;
        
        // Reply
        UIButton *replayB = [[UIButton alloc] init];
        [self addSubview:replayB];
        self.replayB = replayB;
        [replayB setImage:[UIImage imageNamed:@"icn_tweet_action_reply"] forState:UIControlStateNormal];
        [replayB sizeToFit];
        
        // Retweet
        BOOL retweeted = [status[@"retweeted"] boolValue];
        UIButton *retweetB = [[UIButton alloc] init];
        [self addSubview:retweetB];
        self.retweetB = retweetB;
        if (isMyTweet) {
            [retweetB setImage:[UIImage imageNamed:@"icn_tweet_action_retweet_disabled"] forState:UIControlStateDisabled];
            retweetB.enabled = NO;
        } else if (retweeted) {
            [retweetB setImage:[UIImage imageNamed:@"icn_tweet_action_retweet_on"] forState:UIControlStateNormal];
            [retweetB setImage:[UIImage imageNamed:@"icn_tweet_action_retweet_disabled"] forState:UIControlStateDisabled];
        } else {
            [retweetB setImage:[UIImage imageNamed:@"icn_tweet_action_retweet_off"] forState:UIControlStateNormal];
            [retweetB setImage:[UIImage imageNamed:@"icn_tweet_action_retweet_disabled"] forState:UIControlStateDisabled];
        }
        [retweetB sizeToFit];
        
        // Favorite
        BOOL favorited = [status[@"favorited"] boolValue];
        UIButton *favoriteB = [[UIButton alloc] init];
        [self addSubview:favoriteB];
        self.favoriteB = favoriteB;
        if (favorited) {
            [favoriteB setImage:[UIImage imageNamed:@"icn_tweet_action_favorite_on"] forState:UIControlStateNormal];
        } else {
            [favoriteB setImage:[UIImage imageNamed:@"icn_tweet_action_favorite_off"] forState:UIControlStateNormal];
        }
        [favoriteB sizeToFit];
        
        // More
        UIButton *moreB = [[UIButton alloc] init];
        [self addSubview:moreB];
        self.moreB = moreB;
        [moreB setImage:[UIImage imageNamed:@"icn_tweet_action_more"] forState:UIControlStateNormal];
        [moreB sizeToFit];
        
        // Delete
        UIButton *deleteB = [[UIButton alloc] init];
        [self addSubview:deleteB];
        self.deleteB = deleteB;
        [deleteB setImage:[UIImage imageNamed:@"icn_tweet_action_delete"] forState:UIControlStateNormal];
        [deleteB sizeToFit];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    NSMutableArray *actionButtons = [NSMutableArray array];
    [actionButtons addObject:self.replayB];
    [actionButtons addObject:self.retweetB];
    [actionButtons addObject:self.favoriteB];
    [actionButtons addObject:self.moreB];
    if (isMyTweet) {
        [actionButtons addObject:self.deleteB];
        self.deleteB.hidden = NO;
    } else {
        self.deleteB.hidden = YES;
    }
    
    for (uint i=0; i<actionButtons.count; i++) {
        [actionButtons[i] setCenter:ccp(self.width / 2 / actionButtons.count * (2 * i + 1), self.height / 2)];
    }
}

@end
