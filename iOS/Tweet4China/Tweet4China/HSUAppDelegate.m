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
#ifdef FreeApp
        self.globalSettings = @{HSUSettingSoundEffect: @YES, HSUSettingPhotoPreview: @NO, HSUSettingTextSize: @"14", HSUSettingCacheSize: @"16MB"};
#else
        self.globalSettings = @{HSUSettingSoundEffect: @YES, HSUSettingPhotoPreview: @YES, HSUSettingTextSize: @"14", HSUSettingCacheSize: @"16MB"};
#endif
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
    [self updateConfig];
    
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [Appirater setAppId:AppleID];
    
    [self alertJailbreak];
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
    [Appirater setAppId:AppleID];
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
#ifdef FreeApp
        sss = @[@{HSUShadowsocksSettings_Buildin: @YES,
                  HSUShadowsocksSettings_Desc: @"旧金山",
                  HSUShadowsocksSettings_Server: @"162.243.150.109",
                  HSUShadowsocksSettings_RemotePort: @"1026"}.mutableCopy,
                
                @{HSUShadowsocksSettings_Buildin: @YES,
                  HSUShadowsocksSettings_Desc: @"纽约",
                  HSUShadowsocksSettings_Server: @"162.243.81.212",
                  HSUShadowsocksSettings_RemotePort: @"1026"}.mutableCopy,
                
                @{HSUShadowsocksSettings_Buildin: @YES,
                  HSUShadowsocksSettings_Desc: @"纽约",
                  HSUShadowsocksSettings_Server: @"192.241.245.82",
                  HSUShadowsocksSettings_RemotePort: @"1026",
                  HSUShadowsocksSettings_Method: @"AES-128-CFB"}.mutableCopy,
                
                @{HSUShadowsocksSettings_Buildin: @YES,
                  HSUShadowsocksSettings_Desc: @"纽约",
                  HSUShadowsocksSettings_Server: @"192.241.205.25",
                  HSUShadowsocksSettings_RemotePort: @"1026"}.mutableCopy,
                
                @{HSUShadowsocksSettings_Buildin: @YES,
                  HSUShadowsocksSettings_Desc: @"纽约",
                  HSUShadowsocksSettings_Server: @"162.243.233.180",
                  HSUShadowsocksSettings_RemotePort: @"1026"}.mutableCopy,
                
                @{HSUShadowsocksSettings_Buildin: @YES,
                  HSUShadowsocksSettings_Desc: @"青岛",
                  HSUShadowsocksSettings_Server: @"115.28.20.25",
                  HSUShadowsocksSettings_RemotePort: @"1024",
                  HSUShadowsocksSettings_Method: @"Table"}.mutableCopy
                ];
#else
        sss = @[@{HSUShadowsocksSettings_Buildin: @YES,
                  HSUShadowsocksSettings_Desc: @"旧金山",
                  HSUShadowsocksSettings_Server: @"192.241.197.97",
                  HSUShadowsocksSettings_RemotePort: @"1026"}.mutableCopy,
                
                @{HSUShadowsocksSettings_Buildin: @YES,
                  HSUShadowsocksSettings_Desc: @"阿姆斯特丹",
                  HSUShadowsocksSettings_Server: @"95.85.33.168",
                  HSUShadowsocksSettings_RemotePort: @"1026"}.mutableCopy,
                
                @{HSUShadowsocksSettings_Buildin: @YES,
                  HSUShadowsocksSettings_Desc: @"青岛",
                  HSUShadowsocksSettings_Server: @"115.28.20.25",
                  HSUShadowsocksSettings_RemotePort: @"1024",
                  HSUShadowsocksSettings_Method: @"Table"}.mutableCopy
                ];
#endif
        sss[arc4random_uniform(sss.count-1)][HSUShadowsocksSettings_Selected] = @YES;
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
                if (!method) {
                    method = @"AES-128-CFB";
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
                if (proxy) {
                    [proxy updateHost:server
                                 port:[remotePort integerValue]
                             password:passowrd
                               method:method];
                } else {
                    proxy = [[HSUShadowsocksProxy alloc] initWithHost:server
                                                                 port:[remotePort integerValue]
                                                             password:passowrd
                                                               method:method];
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

- (void)buyProAppIfOverCount
{
#ifdef FreeApp // free app is restrict for using time
    NSUInteger timelineLoadCount = [[[NSUserDefaults standardUserDefaults] objectForKey:@"timeline_load_count"] unsignedIntegerValue];
    if (timelineLoadCount > 10 && (timelineLoadCount - 10) % 3 == 0) {
        [self buyProApp];
    }
    timelineLoadCount ++;
    [[NSUserDefaults standardUserDefaults] setObject:@(timelineLoadCount) forKey:@"timeline_load_count"];
    [[NSUserDefaults standardUserDefaults] synchronize];
#endif
}

// yes if pro, no if free
- (BOOL)buyProApp
{
#ifndef FreeApp // free app is restrict for using time
    return YES;
#endif
    NSString *title = _(@"pro_alert_title");
    NSString *message = _(@"pro_message_title");
    RIButtonItem *cancelItem = [RIButtonItem itemWithLabel:_(@"pro_alert_cancel_item")];
    RIButtonItem *buyItem = [RIButtonItem itemWithLabel:_(@"pro_alert_buy_item")];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message cancelButtonItem:cancelItem otherButtonItems:buyItem, nil];
    [alert show];
    buyItem.action = ^{
        [Flurry logEvent:@"buy_pro_confirm"];
        [Appirater setAppId:ProAppleID];
        [Appirater rateApp];
    };
    cancelItem.action = ^{
        [Flurry logEvent:@"buy_pro_cancel"];
    };
    [Flurry logEvent:@"buy_pro_alert"];
    return NO;
}

- (void)alertJailbreak
{
    return;
#ifndef FreeApp
    if (self.isJailBreak) {
        RIButtonItem *cancelItem = [RIButtonItem itemWithLabel:_(@"OK")];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:_(@"Jailbreak Device") message:_(@"jailbreak_alert_message") cancelButtonItem:cancelItem otherButtonItems:nil, nil];
        [alert show];
        cancelItem.action = ^{
            [Appirater setAppId:FreeAppleID];
            [Appirater rateApp];
        };
    }
#endif
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

- (void)updateConfig
{
    double delayInSeconds = 5.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, GCDBackgroundThread, ^(void){
        NSData *configJSON = [NSData dataWithContentsOfURL:[NSURL URLWithString:@"http://162.243.81.212/tweet4china/config.json"]];
        if (configJSON) {
            NSDictionary *config = [NSJSONSerialization JSONObjectWithData:configJSON options:0 error:nil];
#ifdef FreeApp
            NSArray *serverList = config[@"global"][@"free"][@"server_list"];
#else
            NSArray *serverList = config[@"global"][@"pro"][@"server_list"];
#endif
            if (serverList.count) {
                BOOL selected = NO;
                NSArray *localServerList = [[NSUserDefaults standardUserDefaults] objectForKey:HSUShadowsocksSettings];
                NSMutableArray *newServerList = @[].mutableCopy;
                for (NSDictionary *ns in serverList) {
                    [newServerList addObject:ns.mutableCopy];
                }
                for (NSDictionary *ls in localServerList) {
                    if (![ls[HSUShadowsocksSettings_Buildin] boolValue]) {
                        if ([ls[HSUShadowsocksSettings_Selected] boolValue]) {
                            selected = YES;
                        }
                        [newServerList addObject:ls.mutableCopy];
                    }
                }
                
                if (!selected) {
                    newServerList[arc4random_uniform(newServerList.count)][HSUShadowsocksSettings_Selected] = @YES;
                }
                
                [[NSUserDefaults standardUserDefaults] setObject:newServerList forKey:HSUShadowsocksSettings];
                [[NSUserDefaults standardUserDefaults] synchronize];
                [Flurry logEvent:@"server_list_updated"];
            }
            
            
            // new version
#ifdef FreeApp
            CGFloat latestVersion = [config[@"global"][@"free"][@"latest_version"] floatValue];
#else
            CGFloat latestVersion = [config[@"global"][@"pro"][@"latest_version"] floatValue];
#endif
            CGFloat currentVersion = [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] floatValue];
            if (latestVersion > currentVersion) {
                dispatch_async(GCDMainThread, ^{
                    RIButtonItem *cancelItem = [RIButtonItem itemWithLabel:_(@"Ignore")];
                    RIButtonItem *updateItem = [RIButtonItem itemWithLabel:_(@"Update")];
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:_(@"New Version") message:_(@"New version found, update now!") cancelButtonItem:cancelItem otherButtonItems:updateItem, nil];
                    [alert show];
                    updateItem.action = ^{
                        [Flurry logEvent:@"update_confirm"];
                        [Appirater rateApp];
                    };
                    cancelItem.action = ^{
                        [Flurry logEvent:@"update_ignore"];
                    };
                });
            }
        }
    });
}

@end
