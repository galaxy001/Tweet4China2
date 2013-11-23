//
//  HSUDefinitions.h
//  Tweet4China
//
//  Created by Jason Hsu on 2/28/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#ifndef Tweet4China_HSUDefinitions_h
#define Tweet4China_HSUDefinitions_h

// Define twitter application consumer key & secret.
// Access level of your twitter application should contains Read, write, and direct messages
// if you want to use all of the features.
#define kTwitterAppKey @"JotIXH4moIF1fIJDVJ50eQ"
#define kTwitterAppSecret @"5TKbyf4fDyjzse0GqJ62YwABgP6zKuZCbCHUeYTqugc"
#define UseXAuth YES

#import "UIImageView+Additions.h"
#import "HSUNetworkActivityIndicatorManager.h"
#import "UIAlertView+Blocks.h"
#import "UIActionSheet+Blocks.h"
#import "UIImage+Additions.h"
#import "UIButton+Additions.h"
#import "UIView+Additions.h"
#import "UIViewController+Additions.h"
#import "HSUTwitterAPI.h"
#import "HSUAppDelegate.h"
#import "NSString+Additions.h"
#import "HSUTableCellData.h"
#import "HSUUIEvent.h"
#import "HSUCommonTools.h"
#import "HSULoadMoreCell.h"
#import "HSUNavigationBar.h"
#import "HSUNavigationBarLight.h"
#import "HSUDraftManager.h"
#import "NSData+MD5.h"
#import "SVProgressHUD.h"

#import <SystemConfiguration/SystemConfiguration.h>
#import <MobileCoreServices/MobileCoreServices.h>

BOOL shadowsocksStarted;

#define kTabBarHeight 44
#define kIPadTabBarWidth 84
#define kIPADMainViewWidth 626

#define SuppressPerformSelectorLeakWarning(Stuff) \
do { \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Warc-performSelector-leaks\"") \
Stuff; \
_Pragma("clang diagnostic pop") \
} while (0)


#define GCDBackgroundThread dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
#define GCDMainThread dispatch_get_main_queue()
#define dp(filename) [([NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]) stringByAppendingPathComponent:filename]
#define tp(filename) [([NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0])stringByAppendingPathComponent:filename]
#define ccr(x, y, w, h) CGRectMake(floorf(x), floorf(y), floorf(w), floorf(h))
#define ccp(x, y) CGPointMake(floorf(x), floorf(y))
#define ccs(w, h) CGSizeMake(floorf(w), floorf(h))
#define edi(top, left, bottom, right) UIEdgeInsetsMake(floorf(top), floorf(left), floorf(bottom), floorf(right))
#define cgrgba(r, g, b, a) [[UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:a] CGColor]
#define cgrgb(r, g, b) [[UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:1] CGColor]
#define rgba(r, g, b, a) [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:a]
#define rgb(r, g, b) [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:1]
#define bw(w) [UIColor colorWithWhite:w/255.0f alpha:1]
#define bwa(w, a) [UIColor colorWithWhite:w/255.0f alpha:a]
#define L(s) NSLog(@"%@", s);
#define LR(rect) NSLog(@"%@", NSStringFromCGRect(rect));
#define LF(f,...) NSLog(f,##__VA_ARGS__);
#define S(f,...) [NSString stringWithFormat:f,##__VA_ARGS__]
#define kBlackColor [UIColor blackColor]
#define kWhiteColor [UIColor whiteColor]
#define kClearColor [UIColor clearColor]
#define kGrayColor [UIColor grayColor]
#define kWinWidth [HSUCommonTools winWidth]
#define kWinHeight [HSUCommonTools winHeight]
#define TWENGINE [HSUTwitterAPI shared]
#define RUNNING_ON_IOS_6 ([[UIDevice currentDevice].systemVersion compare:@"7"] == NSOrderedAscending)
#define RUNNING_ON_IOS_7 ([[UIDevice currentDevice].systemVersion compare:@"7"] >= NSOrderedDescending)
#define IPAD [HSUCommonTools isIPad]
#define IPHONE [HSUCommonTools isIPhone]

#define kNamedImageView(s) [[UIImageView alloc] initWithImage:[UIImage imageNamed:s]]
#define GRAY_INDICATOR [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray]
#define MyScreenName [[NSUserDefaults standardUserDefaults] objectForKey:kUserSettings_DBKey][@"screen_name"]
#define DEF_NavitationController_Light [[UINavigationController alloc] initWithNavigationBarClass:[HSUNavigationBarLight class] toolbarClass:nil]
#define kScreenHeight [UIScreen mainScreen].bounds.size.height
#define kScreenWidth [UIScreen mainScreen].bounds.size.width


#define HSUStartRefreshingNotification @"HSUStartRefreshingNotification"
#define HSUDeleteConversationNotification @"HSUDeleteConversationNotification"
#define HSUConversationBackWithIncompletedSendingNotification @"HSUConversationBackWithIncompletedSendingNotification"
#define HSUDraftsCountChangedNotification @"HSUDraftsCountChangedNotification"
#define HSUTwiterLoginSuccess @"HSUTwiterLoginSuccess"
#define HSUGalleryViewDidAppear @"HSUGalleryViewDidAppear"
#define HSUGalleryViewDidDisappear @"HSUGalleryViewDidDisappear"
#define HSUStatusDidDelete @"HSUStatusDidDelete"

#define kDataType_MainStatus @"MainStatus"
#define kDataType_DefaultStatus @"DefaultStatus"
#define kDataType_ChatStatus @"ChatStatus"
#define kDataType_Person @"Person"
#define kDataType_LoadMore @"LoadMore"
#define kDataType_NormalTitle @"NormalTitle"
#define kDataType_Drafts @"Drafts"
#define kDataType_Draft @"Draft"
#define kDataType_Message @"Message"
#define kDataType_Conversation @"Conversation"

#define kTwitterReplyID_ParameterKey @"in_reply_to_status_id"
#define kUserSettings_DBKey @"user_settings"
#define kUserProfile_DBKey @"user_profile"
#define kDiscoverHomePage @"HSUDiscoverHomePage"

#define kShadowsocksSettings_Server @"server"
#define kShadowsocksSettings_RemotePort @"remote_port"
#define kShadowsocksSettings_Password @"password"
#define kShadowsocksSettings_Method @"method"
#define kShadowsocksSettings_Direct @"direct"
#define ShadowSocksPort 71080

#endif