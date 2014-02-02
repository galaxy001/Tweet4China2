//
//  HSUDefinitions.h
//  Tweet4China
//
//  Created by Jason Hsu on 2/28/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

// Define twitter application consumer key & secret.
// Access level of your twitter application should contains Read, write, and direct messages
// if you want to use all of the features.
#define kTwitterAppKey @"JotIXH4moIF1fIJDVJ50eQ"
#define kTwitterAppSecret @"5TKbyf4fDyjzse0GqJ62YwABgP6zKuZCbCHUeYTqugc"

#define FreeAppleID @"445052810"
#define ProAppleID @"791880602"
#define Free_Flurry_API_Key @"4R9B8GXYZGZ23WPW8HJW"
#define Pro_Flurry_API_Key @"MTYFGCVWN5PZ8JD8N9HW"

//#define FreeApp
#ifdef FreeApp
#define AppleID FreeAppleID
#define Flurry_API_Key Free_Flurry_API_Key
#else
#define AppleID ProAppleID
#define Flurry_API_Key Pro_Flurry_API_Key
#endif

#define WXAppID @"wxf12b4ac0a3c0c4d8"
#define WXAppKey @"8adda3d2bca193381a5fae61812bb37d"

#import "UIImageView+Additions.h"
#import "HSUNetworkActivityIndicatorManager.h"
#import <UIAlertView-Blocks/UIAlertView+Blocks.h>
#import <UIAlertView-Blocks/UIActionSheet+Blocks.h>
#import "UIImage+Additions.h"
#import "UIButton+Additions.h"
#import <HSUWebCache/UIButton+HSUWebCache.h>
#import <HSUWebCache/UIImageView+HSUWebCache.h>
#import "UIView+Additions.h"
#import "UIViewController+Additions.h"
#import "HSUTwitterAPI.h"
#import "HSUAppDelegate.h"
#import "NSString+Additions.h"
#import "HSUUIEvent.h"
#import "HSUCommonTools.h"
#import "HSULoadMoreCell.h"
#import "HSUNavigationBar.h"
#import "HSUNavigationBarLight.h"
#import "HSUDraftManager.h"
#import "NSData+MD5.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import "HSUNavigationController.h"
#import "Flurry.h"
#import "NSArray+Additions.h"
#import "T4CTableCellData.h"

#import <SystemConfiguration/SystemConfiguration.h>
#import <MobileCoreServices/MobileCoreServices.h>

BOOL shadowsocksStarted;

#define kTabBarHeight 44
#define kIPadTabBarWidth 84
#define kIPADMainViewPadding (IPAD ? 29 : 0)
#define HSUiPadBgColor rgb(244, 248, 251)

#define kRequestDataCountViaWifi 50
#define kRequestDataCountViaWWAN 20

//#define MakeScreenshot

#define SuppressPerformSelectorLeakWarning(Stuff) \
do { \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Warc-performSelector-leaks\"") \
Stuff; \
_Pragma("clang diagnostic pop") \
} while (0)



typedef NS_ENUM(NSInteger, T4CLoadingState) {
    T4CLoadingState_Done,
    T4CLoadingState_Loading,
    T4CLoadingState_Error,
    T4CLoadingState_NoMore,
};


#define _(s) NSLocalizedString(@s, nil)
#define __(s) NSLocalizedString(@"s", nil)
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
#define kLightBlueColor rgb(141, 157, 168)
#define kWinWidth [HSUCommonTools winWidth]
#define kWinHeight [HSUCommonTools winHeight]
#define twitter [HSUTwitterAPI shared]
#define SDK_Ver __IPHONE_OS_VERSION_MAX_ALLOWED
#define Sys_Ver MIN([[UIDevice currentDevice].systemVersion floatValue], __IPHONE_OS_VERSION_MAX_ALLOWED/10000.0)
#define IPAD [HSUCommonTools isIPad]
#define IPHONE [HSUCommonTools isIPhone]

#define kNamedImageView(s) [[UIImageView alloc] initWithImage:[UIImage imageNamed:s]]
#define GRAY_INDICATOR [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray]
#define MyScreenName [twitter myScreenName]
#define DEF_NavitationController_Light [[HSUNavigationController alloc] initWithNavigationBarClass:[HSUNavigationBarLight class] toolbarClass:nil]
#define kScreenHeight [UIScreen mainScreen].bounds.size.height
#define kScreenWidth [UIScreen mainScreen].bounds.size.width


#define HSUDeleteConversationNotification @"HSUDeleteConversationNotification"
#define HSUConversationBackWithIncompletedSendingNotification @"HSUConversationBackWithIncompletedSendingNotification"
#define HSUDraftsCountChangedNotification @"HSUDraftsCountChangedNotification"
#define HSUTwiterLoginSuccess @"HSUTwiterLoginSuccess"
#define HSUTwiterLogout @"HSUTwiterLogout"
#define HSUGalleryViewDidAppear @"HSUGalleryViewDidAppear"
#define HSUGalleryViewDidDisappear @"HSUGalleryViewDidDisappear"
#define HSUStatusDidDelete @"HSUStatusDidDelete"

#define kDataType_MainStatus @"MainStatus"
#define kDataType_LoadingReply @"LoadingReply"
#define kDataType_Status @"Status"
#define kDataType_DefaultStatus @"DefaultStatus"
#define kDataType_ChatStatus @"ChatStatus"
#define kDataType_Gap @"Gap"
#define kDataType_Person @"Person"
#define kDataType_LoadMore @"LoadMore"
#define kDataType_NormalTitle @"NormalTitle"
#define kDataType_Drafts @"Drafts"
#define kDataType_Draft @"Draft"
#define kDataType_Message @"Message"
#define kDataType_Conversation @"Conversation"
#define kDataType_List @"List"
#define kDataType_Photo @"Photo"
#define kDataType_NewFollowers @"NewFollowers"
#define kDataType_NewRetweets @"NewRetweets"

#define kTwitterReplyID_ParameterKey @"in_reply_to_status_id"
#define HSUUserSettings @"HSUUserSettings"
#define HSUCurrentScreenName @"HSUCurrentScreenName"
#define HSUUserProfiles @"HSUUserProfiles"
#define kDiscoverHomePage @"HSUDiscoverHomePage"

#define setting(key) [[[NSUserDefaults standardUserDefaults] objectForKey:HSUSettings] objectForKey:key]
#define HSUShadowsocksSettings_Desc @"desc"
#define HSUShadowsocksSettings_Server @"server"
#define HSUShadowsocksSettings_RemotePort @"remote_port"
#define HSUShadowsocksSettings_Password @"password"
#define HSUShadowsocksSettings_Method @"method"
#define HSUShadowsocksSettings_Direct @"direct"
#define HSUShadowsocksSettings_Selected @"selected"
#define HSUShadowsocksSettings_Buildin @"buildin"
#define HSUShadowsocksSettings @"HSUShadowsocksSettings"
#define ShadowSocksPort 71080

#define GlobalSettings ([HSUAppDelegate shared].globalSettings)
#define HSUSettings @"HSUSettings"
#define HSUSettingsUpdatedNotification @"HSUSettingsUpdatedNotification"
#define HSUSettingUserAgentChangedNotification @"HSUSettingUserAgentChangedNotification"
#define HSUSettingExcludeRepliesChangedNotification @"HSUSettingExcludeRepliesChangedNotification"
#define HSUSettingSoundEffect @"sound_effect"
#define HSUSettingPhotoPreview @"photo_preview"
#define HSUSettingTextSize @"text_size"
#define HSUSettingCacheSize @"cache_size"
#define HSUSettingRoundAvatar @"round_avatar"
#define HSUSettingPageCount @"page_count"
#define HSUSettingPageCountWWAN @"page_count_wwan"
#define HSUSettingDesktopUserAgent @"desktop_useragent"
#define HSUSettingExcludeReplies @"exclude_replies"

#define HSUDataSourceUpdatedNotification @"HSUDataSourceUpdatedNotification"
#define HSUStatusStyleUpdatedNotification @"HSUStatusStyleUpdatedNotification"
#define HSUCheckUnreadTimeNotification @"HSUCheckUnreadTimeNotification"

#define HSUActionBarTouched @"HSUActionBarTouched"
#define HSUAddFriendBarTouched @"HSUAddFriendBarTouched"
#define HSUTabControllerDidSelectViewControllerNotification @"HSUTabControllerDidSelectViewControllerNotification"
#define HSUActionBarTouchedNotification @"HSUActionBarTouchedNotification"
#define HSUStatusUpdatedNotification @"HSUStatusUpdatedNotification"
#define HSUPostTweetProgressChangedNotification @"HSUPostTweetProgressChangedNotification"
#define HSUBookmarkUpdatedNotification @"HSUBookmarkUpdatedNotification"

#define status_height 20
//[[UIApplication sharedApplication] statusBarFrame].size.height
#define navbar_height self.navigationController.navigationBar.height
#define tabbar_height self.tabBarController.tabBar.height
#define toolbar_height 44

#define NetWorkStatus [twitter networkStatus]

BOOL statusViewTestLabelInited;
