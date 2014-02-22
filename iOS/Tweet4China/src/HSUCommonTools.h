//
//  HSUCommonTools.h
//  Tweet4China
//
//  Created by Jason Hsu on 2/28/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import <UIKit/UIKit.h>

void notification_add_observer(NSString *name, id observer, SEL selector);
void notification_remove_observer(id observer);
void notification_post(NSString *name);
void notification_post_with_object(NSString *name, id object);
void notification_post_with_objct_and_userinfo(NSString *name, id object, NSDictionary *userinfo);

@interface HSUCommonTools : NSObject

+ (BOOL)isIPhone;
+ (BOOL)isIPad;
+ (CGFloat)winWidth;
+ (CGFloat)winHeight;
+ (NSString *)version;
+ (void)switchToDesktopUserAgent;
+ (void)resetUserAgent;
+ (BOOL)isDesktopUserAgent;
+ (id)readJSONObjectFromFile:(NSString *)filename;
+ (void)writeJSONObject:(id)object toFile:(NSString *)filename;
+ (BOOL)postTweet;
+ (BOOL)postTweetWithMessage:(NSString *)message;
+ (BOOL)postTweetWithMessage:(NSString *)message image:(UIImage *)image;
+ (BOOL)postTweetWithMessage:(NSString *)message image:(UIImage *)image selectedRange:(NSRange)selectedRange;
+ (BOOL)postTweetWithMessage:(NSString *)message image:(UIImage *)image selectedRange:(NSRange)selectedRange inReplyToStatusId:(NSString *)inReplyToStatusId;

+ (void)sendMailWithSubject:(NSString *)subject body:(NSString *)body presentFromViewController:(UIViewController *)viewController;

+ (NSString *)smallTwitterImageUrlStr:(NSString *)originalImageUrlStr;

+ (UIColor *)barTintColor;
+ (UIColor *)tintColor;

@end
