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
#import <Appirater/Appirater.h>
#import "HSUiPadTabController.h"
#import "HSUComposeViewController.h"
#import <FHSTwitterEngine/NSString+URLEncoding.h>
#import <SVProgressHUD/SVProgressHUD.h>
#ifndef DEBUG
#import "Flurry.h"
#endif
#import <HSUWebCache/HSUWebCache.h>
#import <AFNetworking/AFNetworkActivityIndicatorManager.h>

static HSUShadowsocksProxy *proxy;

@implementation HSUAppDelegate

+ (HSUAppDelegate *)shared
{
    return (HSUAppDelegate *)[UIApplication sharedApplication].delegate;
}

//+ (void)initialize
//{
//    NSMutableDictionary *userDefaults = @{@"UserAgent": @"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/31.0.1650.63 Safari/537.36"}.mutableCopy;
//    [[NSUserDefaults standardUserDefaults] registerDefaults:userDefaults];
//}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.globalSettings = [[NSUserDefaults standardUserDefaults] valueForKey:HSUSettings];
    if (!self.globalSettings) {
        NSMutableDictionary *settings = @{}.mutableCopy;
        settings[HSUSettingSoundEffect] = @YES;
        settings[HSUSettingPhotoPreview] = @YES;
        settings[HSUSettingTextSize] = @"14";
        settings[HSUSettingPageCount] = S(@"%d", kRequestDataCountViaWifi);
        settings[HSUSettingPageCountWWAN] = S(@"%d", kRequestDataCountViaWWAN);
        settings[HSUSettingCacheSize] = @"16MB";
#ifdef FreeApp
        settings[HSUSettingPhotoPreview] = @NO;
#endif
        if (IPAD) {
            settings[HSUSettingTextSize] = @"16";
        }
        self.globalSettings = settings;
        [[NSUserDefaults standardUserDefaults] setObject:self.globalSettings forKey:HSUSettings];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    self.hasPro = [[NSUserDefaults standardUserDefaults] boolForKey:@"has_pro"];
    
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
    
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
    
    self.checkUnreadTimer = [NSTimer scheduledTimerWithTimeInterval:60
                                                             target:self
                                                           selector:@selector(checkUnread)
                                                           userInfo:nil
                                                            repeats:YES];
    
    [self updateImageCacheSize];
    [self logJailBreak];
    [self updateConfig];
    [self registerWeixinApp];
    
    notification_add_observer(SVProgressHUDWillAppearNotification, self, @selector(disableWindowUserinterface));
    notification_add_observer(SVProgressHUDWillDisappearNotification, self, @selector(enbleWindowUserinterface));
    
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [Appirater setAppId:AppleID];
    
    [self alertJailbreak];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    self.checkUnreadTimer = [NSTimer scheduledTimerWithTimeInterval:60
                                                             target:self
                                                           selector:@selector(checkUnread)
                                                           userInfo:nil
                                                            repeats:YES];
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
    [self.checkUnreadTimer invalidate];
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    if (url.isFileURL) {
        NSData *imgData = [NSData dataWithContentsOfURL:url];
        if (imgData) {
            UIImage *img = [UIImage imageWithData:imgData];
            if (img) {
                return [self postWithMessage:_("Just post a photo.") image:img];
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
        [HSUCommonTools postTweetWithMessage:msg image:nil selectedRange:NSMakeRange(0, msg.length)];
        return YES;
    }
    
    return NO;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    if ([WXApi handleOpenURL:url delegate:self]) {
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
    return [HSUCommonTools postTweetWithMessage:message image:image selectedRange:NSMakeRange(0, 0)];
}

- (void)configureAppirater
{
    [Appirater setAppId:AppleID];
    [Appirater setDaysUntilPrompt:1];
    [Appirater setUsesUntilPrompt:10];
    [Appirater setSignificantEventsUntilPrompt:-1];
    [Appirater setTimeBeforeReminding:2];
}

- (BOOL)startShadowsocks
{
    NSMutableArray *sss = [[[NSUserDefaults standardUserDefaults] objectForKey:HSUShadowsocksSettings] mutableCopy];
    for (NSDictionary *s in sss) {
        if ([s[HSUShadowsocksSettings_Server] isEqualToString:@"162.243.150.109"]) {
            sss = nil;
            break;
        }
    }
    if (!sss) {
        sss = @[].mutableCopy;
        
#ifndef FreeApp
        [sss addObject:@{HSUShadowsocksSettings_Buildin: @YES,
                         HSUShadowsocksSettings_Desc: @"东京",
                         HSUShadowsocksSettings_Server: @"106.187.99.175"}.mutableCopy];
        
        sss[arc4random_uniform(sss.count)][HSUShadowsocksSettings_Selected] = @YES; // select from the pro severs
#endif
        
        [sss addObject:@{HSUShadowsocksSettings_Buildin: @YES,
                         HSUShadowsocksSettings_Desc: @"东京",
                         HSUShadowsocksSettings_Server: @"106.186.113.201"}.mutableCopy];
        
        [sss addObject:@{HSUShadowsocksSettings_Buildin: @YES,
                         HSUShadowsocksSettings_Desc: @"东京",
                         HSUShadowsocksSettings_Server: @"106.186.19.228"}.mutableCopy];
        
#ifdef FreeApp
        sss[arc4random_uniform(sss.count-1)][HSUShadowsocksSettings_Selected] = @YES; // select from free servers
#endif
        
        [sss addObject:@{HSUShadowsocksSettings_Buildin: @YES,
                         HSUShadowsocksSettings_Desc: @"青岛",
                         HSUShadowsocksSettings_Server: @"115.28.20.25"}.mutableCopy];
        
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
                if (!remotePort) {
                    remotePort = @"1026";
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
    if ((timelineLoadCount > 10 && (timelineLoadCount - 10) % 3 == 0) ||
        timelineLoadCount > 15) {
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
//    if (!self.hasPro) {
//        return YES;
//    }
    NSString *title = _("pro_alert_title");
    NSString *message = _("pro_message_title");
    RIButtonItem *cancelItem = [RIButtonItem itemWithLabel:_("pro_alert_cancel_item")];
    RIButtonItem *buyItem = [RIButtonItem itemWithLabel:_("pro_alert_buy_item")];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                           cancelButtonItem:cancelItem
                                           otherButtonItems:buyItem, nil];
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
        RIButtonItem *cancelItem = [RIButtonItem itemWithLabel:_("OK")];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:_("Jailbreak Device") message:_("jailbreak_alert_message") cancelButtonItem:cancelItem otherButtonItems:nil, nil];
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
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, GCDBackgroundThread, ^(void){
#ifdef DEBUG
        NSData *configJSON = [NSData dataWithContentsOfURL:[NSURL URLWithString:@"http://tuoxie.me/tweet4china/config.json.test"]];
#else
        NSData *configJSON = [NSData dataWithContentsOfURL:[NSURL URLWithString:@"http://tuoxie.me/tweet4china/config.json"]];
#endif
        if (configJSON) {
            NSDictionary *config = [NSJSONSerialization JSONObjectWithData:configJSON options:0 error:nil];
            
            // update server
#ifdef FreeApp
            NSArray *serverList = config[@"global"][@"free"][@"server_list"];
#else
            NSArray *serverList = config[@"global"][@"pro"][@"server_list"];
#endif
            if (serverList.count) {
                BOOL selected = NO;
                NSArray *localServerList = [[NSUserDefaults standardUserDefaults] objectForKey:HSUShadowsocksSettings];
                
                BOOL hasNewServer;
                for (NSDictionary *ns in serverList) {
                    NSString *ns_server = S(@"%@:%@", ns[HSUShadowsocksSettings_Server], ns[HSUShadowsocksSettings_RemotePort]);
                    BOOL found = NO;
                    for (NSDictionary *ls in localServerList) {
                        NSString *ls_server = S(@"%@:%@", ls[HSUShadowsocksSettings_Server], ls[HSUShadowsocksSettings_RemotePort]);
                        if ([ns_server isEqualToString:ls_server]) {
                            found = YES;
                            break;
                        }
                    }
                    if (!found) {
                        hasNewServer = YES;
                        break;
                    }
                }
                
                if (hasNewServer) {
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
            }
            
            // pro
#ifdef FreeApp
            BOOL hasPro = [config[@"global"][@"free"][@"has_pro"] boolValue];
            if (hasPro) {
                [[NSUserDefaults standardUserDefaults] setBool:hasPro forKey:@"has_pro"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                self.hasPro = hasPro;
            }
#endif
            
            
            // new version
#ifdef FreeApp
            CGFloat latestVersion = [config[@"global"][@"free"][@"latest_version"] floatValue];
#else
            CGFloat latestVersion = [config[@"global"][@"pro"][@"latest_version"] floatValue];
#endif
            CGFloat currentVersion = [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] floatValue];
            if (latestVersion > currentVersion) {
                dispatch_async(GCDMainThread, ^{
                    RIButtonItem *cancelItem = [RIButtonItem itemWithLabel:_("Ignore")];
                    RIButtonItem *updateItem = [RIButtonItem itemWithLabel:_("Update")];
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:_("New Version") message:_("New version found, update now!") cancelButtonItem:cancelItem otherButtonItems:updateItem, nil];
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

- (void)disableWindowUserinterface
{
    self.window.userInteractionEnabled = NO;
}

- (void)enbleWindowUserinterface
{
    self.window.userInteractionEnabled = YES;
}

- (void)registerWeixinApp
{
    [WXApi registerApp:WXAppID];
}

- (void)askFollowAuthor
{
    if (![[[NSUserDefaults standardUserDefaults] valueForKey:@"asked_follow_author"] boolValue]) {
        NSString *authorScreenName = @"tuoxie007";
        if (![twitter.myScreenName isEqualToString:authorScreenName]) {
            [twitter showUser:authorScreenName success:^(id responseObj) {
                NSDictionary *profile = responseObj;
                if (![profile[@"following"] boolValue]) {
                    RIButtonItem *cancelItem = [RIButtonItem itemWithLabel:_("Cancel")];
                    RIButtonItem *followItem = [RIButtonItem itemWithLabel:_("OK")];
                    followItem.action = ^{
                        [twitter followUser:authorScreenName success:^(id responseObj) {
                        } failure:^(NSError *error) {
                        }];
                    };
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:_("Follow Author @tuoxie007")
                                                                    message:_("Get the latest activities about Tweet4China")
                                                           cancelButtonItem:cancelItem
                                                           otherButtonItems:followItem, nil];
                    [alert show];
                    [[NSUserDefaults standardUserDefaults] setValue:@YES forKey:@"asked_follow_author"];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                }
            } failure:^(NSError *error) {
                
            }];
        }
    }
}

@end
