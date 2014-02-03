//
//  HSUCommonTools.m
//  Tweet4China
//
//  Created by Jason Hsu on 2/28/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import <MessageUI/MessageUI.h>

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

+ (BOOL)isDesktopUserAgent
{
    NSString *userAgent = [[NSUserDefaults standardUserDefaults] objectForKey:@"UserAgent"];
    if (userAgent && [userAgent rangeOfString:@"Chrome"].location != NSNotFound) {
        return YES;
    }
    return NO;
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
    }
}

@end
