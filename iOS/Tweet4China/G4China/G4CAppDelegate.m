//
//  G4CAppDelegate.m
//  G4China
//
//  Created by Jason Hsu on 14-1-31.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "G4CAppDelegate.h"
#import "G4CViewController.h"
#import "FBCTabController.h"
#import "HSUShadowsocksProxy.h"
#import "Flurry.h"

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
#define Flurry_API_Key @"DFQP9KW7XKRBDVS27YDJ"

static HSUShadowsocksProxy *proxy;

@implementation G4CAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self startShadowsocks];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor blackColor];
    
    UIViewController *tabController = [[G4CViewController alloc] init];
    
    self.window.rootViewController = tabController;
    [self.window makeKeyAndVisible];
    
    return YES;
}


- (void)startShadowsocks
{
    NSMutableArray *sss = [[[NSUserDefaults standardUserDefaults] objectForKey:HSUShadowsocksSettings] mutableCopy];
    if (!sss) {
        sss = @[].mutableCopy;
        
        [sss addObject:@{HSUShadowsocksSettings_Buildin: @YES,
                         HSUShadowsocksSettings_Desc: @"旧金山",
                         HSUShadowsocksSettings_Server: @"192.241.197.97",
                         HSUShadowsocksSettings_RemotePort: @"1026"}.mutableCopy];
        
        [sss addObject:@{HSUShadowsocksSettings_Buildin: @YES,
                         HSUShadowsocksSettings_Desc: @"阿姆斯特丹",
                         HSUShadowsocksSettings_Server: @"95.85.33.168",
                         HSUShadowsocksSettings_RemotePort: @"1026"}.mutableCopy];
        
        [sss addObject:@{HSUShadowsocksSettings_Buildin: @YES,
                         HSUShadowsocksSettings_Desc: @"旧金山",
                         HSUShadowsocksSettings_Server: @"162.243.150.109",
                         HSUShadowsocksSettings_RemotePort: @"1026"}.mutableCopy];
        
        [sss addObject:@{HSUShadowsocksSettings_Buildin: @YES,
                         HSUShadowsocksSettings_Desc: @"纽约",
                         HSUShadowsocksSettings_Server: @"192.241.245.82",
                         HSUShadowsocksSettings_RemotePort: @"1026"}.mutableCopy];
        
        [sss addObject:@{HSUShadowsocksSettings_Buildin: @YES,
                         HSUShadowsocksSettings_Desc: @"纽约",
                         HSUShadowsocksSettings_Server: @"192.241.205.25",
                         HSUShadowsocksSettings_RemotePort: @"1026"}.mutableCopy];
        
        [sss addObject:@{HSUShadowsocksSettings_Buildin: @YES,
                         HSUShadowsocksSettings_Desc: @"纽约",
                         HSUShadowsocksSettings_Server: @"162.243.233.180",
                         HSUShadowsocksSettings_RemotePort: @"1026"}.mutableCopy];
        
        [sss addObject:@{HSUShadowsocksSettings_Buildin: @YES,
                         HSUShadowsocksSettings_Desc: @"青岛",
                         HSUShadowsocksSettings_Server: @"115.28.20.25",
                         HSUShadowsocksSettings_RemotePort: @"1026"}.mutableCopy];
        
        sss[arc4random_uniform(sss.count-1)][HSUShadowsocksSettings_Selected] = @YES; // select from free servers
        
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

@end
