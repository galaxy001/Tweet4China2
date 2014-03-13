//
//  FBCAppDelegate.m
//  FB4China
//
//  Created by Jason Hsu on 14-1-18.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "FBCAppDelegate.h"
#import "FBCTabController.h"
#import "HSUShadowsocksProxy.h"
#import "Flurry.h"
#import "HSUServerList.h"

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
#define ShadowSocksPort 71081
#define Flurry_API_Key @"DFQP9KW7XKRBDVS27YDJ"

#define GCDBackgroundThread dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
#define GCDMainThread dispatch_get_main_queue()

static HSUShadowsocksProxy *proxy;

@implementation FBCAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self startShadowsocks];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor blackColor];
    
    UIViewController *tabController = [[FBCTabController alloc] init];
    
    self.window.rootViewController = tabController;
    [self.window makeKeyAndVisible];
    
#ifndef DEBUG
    [Flurry setLogLevel:FlurryLogLevelNone];
    [Flurry setCrashReportingEnabled:YES];
    [Flurry startSession:Flurry_API_Key];
#endif
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ssUpdated:) name:@"ShadowsocksServerListUpdatedNotification" object:nil];
    
    self.serverList = [[HSUServerList alloc] init];
#if DEBUG
    self.serverList.configfile = @"fb.ss.json.test";
#else
    self.serverList.configfile = @"fb.ss.json";
#endif
    [self.serverList updateServerList];
    
    return YES;
}

- (void)startShadowsocks
{
    NSMutableArray *sss = [[[NSUserDefaults standardUserDefaults] objectForKey:HSUShadowsocksSettings] mutableCopy];
    if (!sss) {
        sss = @[].mutableCopy;
        
        [sss addObject:@{HSUShadowsocksSettings_Server: @"a1.tuoxie.me"}.mutableCopy];
        [sss addObject:@{HSUShadowsocksSettings_Server: @"a2.tuoxie.me"}.mutableCopy];
        [sss addObject:@{HSUShadowsocksSettings_Server: @"a3.tuoxie.me"}.mutableCopy];
        
        sss[arc4random_uniform(sss.count)][HSUShadowsocksSettings_Selected] = @YES;
        
        [[NSUserDefaults standardUserDefaults] setObject:sss forKey:HSUShadowsocksSettings];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    for (NSDictionary *ss in sss) {
        if ([ss[HSUShadowsocksSettings_Selected] boolValue]) {
            NSString *server = ss[HSUShadowsocksSettings_Server];
            NSString *remotePort = ss[HSUShadowsocksSettings_RemotePort];
            NSString *passowrd = ss[HSUShadowsocksSettings_Password];
            NSString *method = ss[HSUShadowsocksSettings_Method];
            
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
                BOOL shadowsocksStarted = [proxy startWithLocalPort:ShadowSocksPort];
                if (!shadowsocksStarted) {
                    [Flurry logEvent:@"ss_start_failed" withParameters:@{@"ssserver": server}];
                    exit(0);
                }
                [Flurry logEvent:@"ss_start_success" withParameters:@{@"ssserver": server}];
                return ;
            }
            return ;
        }
    }
    return ;
}


- (void)ssUpdated:(NSNotification *)notification
{
    NSDictionary *json = notification.object;
    NSMutableArray *proServers = [json[@"pro"] mutableCopy];
    for (int i=0; i<proServers.count; i++) {
        proServers[i] = [proServers[i] mutableCopy];
    }
    NSMutableArray *freeServers = [json[@"free"] mutableCopy];
    for (int i=0; i<freeServers.count; i++) {
        freeServers[i] = [freeServers[i] mutableCopy];
    }
#ifdef FreeApp
    NSMutableArray *servers = [NSMutableArray arrayWithArray:freeServers];
    servers[arc4random_uniform(servers.count-1)][HSUShadowsocksSettings_Selected] = @YES;
#else
    NSMutableArray *servers = [NSMutableArray arrayWithArray:proServers];
    servers[arc4random_uniform(proServers.count)][HSUShadowsocksSettings_Selected] = @YES;
#endif
    
    NSArray *oldServers = [[NSUserDefaults standardUserDefaults] arrayForKey:HSUShadowsocksSettings];
    if (oldServers.count != servers.count) {
        [[NSUserDefaults standardUserDefaults] setObject:servers forKey:HSUShadowsocksSettings];
        [[NSUserDefaults standardUserDefaults] synchronize];
    } else {
        for (NSDictionary *ns in servers) {
            BOOL found = NO;
            for (NSDictionary *os in oldServers) {
                if ([ns[HSUShadowsocksSettings_Server] isEqualToString:os[HSUShadowsocksSettings_Server]]) {
                    NSUInteger op = [os[HSUShadowsocksSettings_RemotePort] unsignedIntegerValue] ?: 1026;
                    NSUInteger np = [ns[HSUShadowsocksSettings_RemotePort] unsignedIntegerValue] ?: 1026;
                    if (op == np) {
                        found = YES;
                        break;
                    }
                }
            }
            if (!found) {
                [[NSUserDefaults standardUserDefaults] setObject:servers forKey:HSUShadowsocksSettings];
                [[NSUserDefaults standardUserDefaults] synchronize];
                break;
            }
        }
    }
    self.serverList = nil;
}

@end
