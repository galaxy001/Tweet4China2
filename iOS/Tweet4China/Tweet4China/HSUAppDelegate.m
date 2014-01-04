//
//  HSUAppDelegate.m
//  Tweet4China
//
//  Created by Jason Hsu on 2/27/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUAppDelegate.h"
#import "HSUTabController.h"
#import "HSUShadowsocksProxy.h"
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
#import <Appirater/Appirater.h>
#endif
#import "HSUiPadTabController.h"
#import "HSUComposeViewController.h"
#import <FHSTwitterEngine/NSString+URLEncoding.h>
#import <SVProgressHUD/SVProgressHUD.h>
#ifndef DEBUG
#import "Flurry.h"
#endif
#import <HSUWebCache/HSUWebCache.h>

static HSUShadowsocksProxy *proxy;

@implementation HSUAppDelegate

+ (HSUAppDelegate *)shared
{
    return (HSUAppDelegate *)[UIApplication sharedApplication].delegate;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.globalSettings = [[NSUserDefaults standardUserDefaults] valueForKey:HSUSettings];
    if (!self.globalSettings) {
        self.globalSettings = @{HSUSettingSoundEffect: @YES, HSUSettingPhotoPreview: @YES, HSUSettingTextSize: @"14", HSUSettingCacheSize: @"16MB"};
    }
    
    [self startShadowsocks];
    [self configureAppirater];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor blackColor];
    
    UIViewController *tabController;
    if (IPAD) {
        tabController = [[HSUiPadTabController alloc] init];
    } else {
        tabController = [[HSUTabController alloc] init];
    }
    
    self.window.rootViewController = tabController;
    self.tabController = tabController;
    [self.window makeKeyAndVisible];
    
    [Appirater setOpenInAppStore:YES];
    [Appirater appLaunched:YES];
#ifndef DEBUG
    [Flurry setLogLevel:FlurryLogLevelNone];
    [Flurry setCrashReportingEnabled:YES];
    [Flurry startSession:Flurry_API_Key];
    [Flurry logEvent:@"Launch" timed:YES];
#endif
    
    [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(checkUnread) userInfo:nil repeats:YES];
    
    [self updateImageCacheSize];
    [self logJailBreak];
    
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
#ifndef JailBreakSupported
    if (self.isJailBreak) {
        RIButtonItem *cancelItem = [RIButtonItem itemWithLabel:_(@"OK")];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:_(@"Jailbreak Device") message:_(@"jailbreak_alert_message") cancelButtonItem:cancelItem otherButtonItems:nil, nil];
        [alert show];
        cancelItem.action = ^{
            [Appirater rateApp];
        };
    }
#endif
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [self startShadowsocks];
    [Appirater appEnteredForeground:YES];
#ifndef DEBUG
    [Flurry logEvent:@"EnterForeground" timed:YES];
#endif
    [self checkUnread];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [proxy stop];
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    if (url.isFileURL) {
        NSData *imgData = [NSData dataWithContentsOfURL:url];
        if (imgData) {
            UIImage *img = [UIImage imageWithData:imgData];
            if (img) {
                return [self postWithMessage:_(@"Just post a photo.") image:img];
            }
        }
        return NO;
    }
    NSString *action = url.host;
    NSArray *queries = [url.query componentsSeparatedByString:@"&"];
    NSMutableDictionary *queriesDict = @{}.mutableCopy;
    for (NSString *query in queries) {
        NSArray *parts = [query componentsSeparatedByString:@"="];
        if (parts.count == 2) {
            NSString *key = parts[0];
            NSString *value = parts[1];
            queriesDict[key] = [value URLDecodedString];
        }
    }
    if ([action isEqualToString:@"post"] && queriesDict[@"message"]) {
        NSString *msg = queriesDict[@"message"];
        [self postWithMessage:msg image:nil selectedRange:NSMakeRange(0, msg.length)];
        return YES;
    }
    return NO;
}

- (void)checkUnread
{
    notification_post(HSUCheckUnreadTimeNotification);
}

- (BOOL)postWithMessage:(NSString *)message image:(UIImage *)image
{
    return [self postWithMessage:message image:image selectedRange:NSMakeRange(0, 0)];
}

- (BOOL)postWithMessage:(NSString *)message image:(UIImage *)image selectedRange:(NSRange)selectedRange
{
    UIViewController *baseVC = self.window.rootViewController;
    if ([self.window.rootViewController.presentedViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *nav = (UINavigationController *)self.window.rootViewController.presentedViewController;
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
    UINavigationController *nav = [[HSUNavigationController alloc] initWithNavigationBarClass:[HSUNavigationBarLight class] toolbarClass:nil];
    nav.viewControllers = @[composeVC];
    [baseVC presentViewController:nav animated:YES completion:nil];
    return YES;
}

- (void)configureAppirater
{
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
    [Appirater setAppId:@"445052810"];
    [Appirater setDaysUntilPrompt:1];
    [Appirater setUsesUntilPrompt:10];
    [Appirater setSignificantEventsUntilPrompt:-1];
    [Appirater setTimeBeforeReminding:2];
#endif
}

- (BOOL)startShadowsocks
{
    NSArray *sss = [[NSUserDefaults standardUserDefaults] objectForKey:HSUShadowsocksSettings];
    if (!sss) {
        sss = @[@{HSUShadowsocksSettings_Buildin: @YES,
                  HSUShadowsocksSettings_Desc: @"东京",
                  HSUShadowsocksSettings_Server: @"106.187.45.148",
                  HSUShadowsocksSettings_RemotePort: @"1024",
                  HSUShadowsocksSettings_Method: @"Table"}.mutableCopy,
                
                @{HSUShadowsocksSettings_Buildin: @YES,
                  HSUShadowsocksSettings_Desc: @"青岛",
                  HSUShadowsocksSettings_Server: @"115.28.20.25",
                  HSUShadowsocksSettings_RemotePort: @"1024",
                  HSUShadowsocksSettings_Method: @"Table"}.mutableCopy,
                
                @{HSUShadowsocksSettings_Buildin: @YES,
                  HSUShadowsocksSettings_Desc: @"旧金山",
                  HSUShadowsocksSettings_Server: @"192.241.197.97",
                  HSUShadowsocksSettings_RemotePort: @"1024",
                  HSUShadowsocksSettings_Method: @"Table"}.mutableCopy
                ];
        sss[arc4random_uniform(3)][HSUShadowsocksSettings_Selected] = @YES;
        [[NSUserDefaults standardUserDefaults] setObject:sss forKey:HSUShadowsocksSettings];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    for (NSDictionary *ss in sss) {
        if ([ss[HSUShadowsocksSettings_Selected] boolValue]) {
            NSString *server = ss[HSUShadowsocksSettings_Server];
            NSString *remotePort = ss[HSUShadowsocksSettings_RemotePort];
            NSString *passowrd = ss[HSUShadowsocksSettings_Password];
            NSString *method = ss[HSUShadowsocksSettings_Method];
            
            if ([ss[HSUShadowsocksSettings_Buildin] boolValue]) {
                if (!passowrd) {
                    passowrd = @"ticqoxmp~rxr";
                }
                char chars3[13];
                const char *str3 = [passowrd cStringUsingEncoding:NSASCIIStringEncoding];
                for (int i=0; i<12; i++) {
                    chars3[i] = str3[i] - i;
                }
                chars3[12] = 0;
                passowrd = [NSString stringWithCString:chars3 encoding:NSASCIIStringEncoding];
            }
            
            if (server && remotePort && passowrd && method) {
                if (proxy == nil) {
                    proxy = [[HSUShadowsocksProxy alloc] initWithHost:server port:[remotePort integerValue] password:passowrd method:method];
                }
                shadowsocksStarted = [proxy startWithLocalPort:ShadowSocksPort];
                if (!shadowsocksStarted) {
                    [Flurry logEvent:@"ss_start_failed" withParameters:@{@"ssserver": server}];
                    exit(0);
                }
                [Flurry logEvent:@"ss_start_success" withParameters:@{@"ssserver": server}];
                self.shadwosocksServer = server;
                return shadowsocksStarted;
            }
            return (shadowsocksStarted = NO);
        }
    }
    return NO;
}

- (void)stopShadowsocks
{
    [proxy stop];
    shadowsocksStarted = NO;
}

- (void)updateImageCacheSize
{
    NSString *cacheSize = GlobalSettings[HSUSettingCacheSize];
    if ([cacheSize hasSuffix:@"MB"]) {
        size_t size = [[cacheSize substringToIndex:cacheSize.length-2] longLongValue] * 1000 * 1000;
        [HSUWebCache setImageCacheSize:size];
    } else if ([cacheSize hasSuffix:@"GB"]) {
        size_t size = [[cacheSize substringToIndex:cacheSize.length-2] longLongValue] * 1000 * 1000 * 1000;
        [HSUWebCache setImageCacheSize:size];
    }
}

- (void)logJailBreak
{
    if (self.isJailBreak) {
        if (![[[NSUserDefaults standardUserDefaults] objectForKey:@"log_jail_break"] boolValue]) {
            [Flurry logEvent:@"jail_break"];
            [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:@"log_jail_break"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
}

- (BOOL)isJailBreak
{
#if TARGET_IPHONE_SIMULATOR
    return NO;
#endif
    FILE *f = fopen("/bin/bash", "r");
    BOOL isbash = NO;
    if (f != NULL)
    {
        isbash = YES;
    }
    fclose(f);
    return isbash;
}

@end
