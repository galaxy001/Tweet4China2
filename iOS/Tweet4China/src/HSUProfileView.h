//
//  HSUProfileView.h
//  Tweet4China
//
//  Created by Jason Hsu on 5/1/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol HSUProfileViewDelegate;
@interface HSUProfileView : UIView <UIScrollViewDelegate>

@property (nonatomic, readonly) UIImage *avatarImage;
@property (nonatomic, readonly) UIImage *bannerImage;
@property (nonatomic, weak) UIImageView *dmIndicator;

- (id)initWithScreenName:(NSString *)screenName width:(CGFloat)width delegate:(id<HSUProfileViewDelegate>)delegate;
- (void)setupWithProfile:(NSDictionary *)profile;
- (void)hideDMIndicator;
- (void)showFollowed;

@end

@protocol HSUProfileViewDelegate <NSObject>

- (void)tweetsButtonTouched;
- (void)followingsButtonTouched;
- (void)followersButtonTouched;
- (void)actionsButtonTouched;
- (void)settingsButtonTouched;
- (void)followButtonTouched:(UIButton *)followButton;
- (void)messagesButtonTouched;
- (void)avatarButtonTouched;
- (void)bannerButtonTouched;

@end