//
//  HSUCommonTools.m
//  Tweet4China
//
//  Created by Jason Hsu on 2/28/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import <MessageUI/MessageUI.h>
#import "HSUComposeViewController.h"
#import "HSUCommonTools.h"

void notification_add_observer(NSString *name, id observer, SEL selector)
{
    [[NSNotificationCenter defaultCenter] addObserver:observer selector:selector name:name object:nil];
}

void notification_remove_observer(id observer)
{
    [[NSNotificationCenter defaultCenter] removeObserver:observer];
}

void notification_post(NSString *name)
{
    [[NSNotificationCenter defaultCenter] postNotificationName:name object:nil];
}

void notification_post_with_object(NSString *name, id object)
{
    [[NSNotificationCenter defaultCenter] postNotificationName:name object:object];
}

void notification_post_with_objct_and_userinfo(NSString *name, id object, NSDictionary *userinfo)
{
    [[NSNotificationCenter defaultCenter] postNotificationName:name object:object userInfo:userinfo];
}

@interface HSUMailHelper : NSObject <MFMailComposeViewControllerDelegate>
@property (nonatomic, weak) UIViewController *currentViewController;

- (void)sendMailWithSubject:(NSString *)subject body:(NSString *)body presentFromViewController:(UIViewController *)viewController;

+ (HSUMailHelper *)getInstance;

@end

@implementation HSUMailHelper

static HSUMailHelper *mailHelper;
+ (HSUMailHelper *)getInstance
{
    if (!mailHelper) {
        mailHelper = [[HSUMailHelper alloc] init];
    }
    return mailHelper;
}

- (void)sendMailWithSubject:(NSString *)subject body:(NSString *)body presentFromViewController:(UIViewController *)viewController
{
    self.currentViewController = viewController;
    
    if([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *mailCont = [[MFMailComposeViewController alloc] init];
        mailCont.mailComposeDelegate = self;
        [mailCont setSubject:subject];
        [mailCont setMessageBody:body isHTML:YES];
        [viewController presentViewController:mailCont animated:YES completion:^{}];
    } else {
        NSString *url = [NSString stringWithFormat:@"mailto:?subject=%@&body=%@",
                         [subject stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                         [body stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
    }
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    [self.currentViewController dismissViewControllerAnimated:YES completion:^{
        mailHelper = nil;
    }];
}

@end

@implementation HSUCommonTools

static NSString *defaultUserAgent;

+ (void)initialize
{
    UIWebView *webView = [[UIWebView alloc] initWithFrame:CGRectZero];
    defaultUserAgent = [webView stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
}

+ (BOOL)isDesktopUserAgent
{
    NSString *userAgent = [[NSUserDefaults standardUserDefaults] objectForKey:@"UserAgent"];
    if (userAgent && [userAgent rangeOfString:@"Chrome"].location != NSNotFound) {
        return YES;
    }
    return NO;
}

+ (void)switchToDesktopUserAgent
{
    if ([self isDesktopUserAgent]) {
        return;
    }
    NSMutableDictionary *userDefaults = [[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] mutableCopy];
    userDefaults[@"UserAgent"] = @"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/31.0.1650.63 Safari/537.36";
    [[NSUserDefaults standardUserDefaults] registerDefaults:userDefaults];
}

+ (void)resetUserAgent
{
    if (![self isDesktopUserAgent]) {
        return;
    }
    NSMutableDictionary *userDefaults = [[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] mutableCopy];
    userDefaults[@"UserAgent"] = defaultUserAgent;
    [[NSUserDefaults standardUserDefaults] registerDefaults:userDefaults];
}

+ (BOOL)isIPhone
{
    return [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone;
}

+ (BOOL)isIPad
{
    return [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
}

+ (CGFloat)winWidth
{
    return [HSUCommonTools isIPhone] ? [[UIScreen mainScreen] bounds].size.width : [[UIScreen mainScreen] bounds].size.width - kIPadTabBarWidth;
}

+ (CGFloat)winHeight
{
    return [[UIScreen mainScreen] bounds].size.height;
}

+ (void)sendMailWithSubject:(NSString *)subject body:(NSString *)body presentFromViewController:(UIViewController *)viewController
{
    [[HSUMailHelper getInstance] sendMailWithSubject:subject body:body presentFromViewController:viewController];
}

+ (NSString *)version
{
    NSString *verNum = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
#ifdef FreeApp
    return [NSString stringWithFormat:@"Tweet4China Free %@", verNum];
#else
    return [NSString stringWithFormat:@"Tweet4China Pro %@", verNum];
#endif
}

+ (id)readJSONObjectFromFile:(NSString *)filename
{
    if (![filename hasSuffix:@"json"]) {
        filename = [NSString stringWithFormat:@"%@.json", filename];
    }
    NSData *data = [NSData dataWithContentsOfFile:dp(filename)];
    if (data) {
        return [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    }
    return nil;
}

+ (void)writeJSONObject:(id)object toFile:(NSString *)filename
{
    if (![filename hasSuffix:@"json"]) {
        filename = [NSString stringWithFormat:@"%@.json", filename];
    }
    if (object) {
        NSData *data = [NSJSONSerialization dataWithJSONObject:object options:0 error:nil];
        [data writeToFile:dp(filename) atomically:NO];
    } else {
        [[NSFileManager defaultManager] removeItemAtPath:dp(filename) error:nil];
    }
}

+ (BOOL)postTweet
{
    return [self postTweetWithMessage:nil image:nil];
}

+ (BOOL)postTweetWithMessage:(NSString *)message
{
    return [self postTweetWithMessage:message image:nil];
}

+ (BOOL)postTweetWithMessage:(NSString *)message image:(UIImage *)image
{
    return [self postTweetWithMessage:message image:image selectedRange:NSMakeRange(0, 0)];
}

+ (BOOL)postTweetWithMessage:(NSString *)message image:(UIImage *)image selectedRange:(NSRange)selectedRange
{
    return [self postTweetWithMessage:message image:image selectedRange:selectedRange inReplyToStatusId:nil];
}

+ (BOOL)postTweetWithMessage:(NSString *)message image:(UIImage *)image selectedRange:(NSRange)selectedRange inReplyToStatusId:(NSString *)inReplyToStatusId
{
    UIViewController *baseVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    if ([[UIApplication sharedApplication].keyWindow.rootViewController.presentedViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *nav = (UINavigationController *)[UIApplication sharedApplication].keyWindow.rootViewController.presentedViewController;
        if ([nav.viewControllers.lastObject isKindOfClass:[HSUComposeViewController class]]) {
            [SVProgressHUD showErrorWithStatus:@"A status is being edit"];
            return NO;
        }
        baseVC = nav;
    }
    HSUComposeViewController *composeVC = [[HSUComposeViewController alloc] init];
    composeVC.defaultText = message;
    composeVC.defaultImage = image;
    composeVC.defaultSelectedRange = selectedRange;
    composeVC.inReplyToStatusId = inReplyToStatusId;
    UINavigationController *nav = [[HSUNavigationController alloc] initWithNavigationBarClass:[HSUNavigationBarLight class] toolbarClass:nil];
    nav.viewControllers = @[composeVC];
    nav.modalPresentationStyle = UIModalPresentationPageSheet;
    [baseVC presentViewController:nav animated:YES completion:nil];
    return YES;
}

+ (NSString *)smallTwitterImageUrlStr:(NSString *)originalImageUrlStr
{
    if ([originalImageUrlStr rangeOfString:@"twimg.com"].location != NSNotFound) {
        return S(@"%@:small", originalImageUrlStr);
    }
    return originalImageUrlStr;
}

+ (void)showConfirmWithConfirmTitle:(NSString *)confirmTitle confirmBlock:(void (^)())confirmBlock
{
    RIButtonItem *cancelItem = [RIButtonItem itemWithLabel:_("Cancel")];
    RIButtonItem *confirmItem = [RIButtonItem itemWithLabel:confirmTitle];
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil cancelButtonItem:cancelItem destructiveButtonItem:confirmItem otherButtonItems:nil, nil];
    [actionSheet showInView:[UIApplication sharedApplication].keyWindow];
    confirmItem.action = confirmBlock;
}

+ (UIColor *)barTintColor
{
//    return bwa(255, 0.9);
    return [UIColor blackColor];
}

+ (UIColor *)tintColor
{
    return [UIColor whiteColor];
}

+ (UIColor *)textColor
{
//    return [UIColor whiteColor];
    return [UIColor blackColor];
}

+ (UIColor *)grayTextColor
{
//    return [UIColor lightGrayColor];
    return [UIColor grayColor];
}

+ (UIColor *)lightTextColor
{
//    return [UIColor blackColor];
    return [UIColor whiteColor];
}

@end
