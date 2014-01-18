//
//  HSUProxySettingsViewController.m
//  Tweet4China
//
//  Created by Jason Hsu on 13-8-30.
//  Copyright (c) 2013年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUProxySettingsViewController.h"
#import <RETableViewManager/RETableViewManager.h>
#import <RETableViewManager/RETableViewOptionsController.h>

@interface HSUProxySettingsViewController () <RETableViewManagerDelegate>

@property (nonatomic, strong) RETableViewManager *manager;
@property (nonatomic, strong) RETextItem *nameItem, *serverItem, *portItem, *passowrdItem;
@property (nonatomic, strong) RERadioItem *methodItem;

@end

@implementation HSUProxySettingsViewController

- (void)viewDidLoad
{
    self.title = @"shadowsocks";
    
    self.manager = [[RETableViewManager alloc] initWithTableView:self.tableView];
    
    RETableViewSection *section = [RETableViewSection section];
    [self.manager addSection:section];
    
    NSString *name = self.shadowsocks[HSUShadowsocksSettings_Desc];
    self.nameItem = [RETextItem itemWithTitle:@"Name" value:name placeholder:nil];
    [section addItem:self.nameItem];
    
    NSString *server = self.shadowsocks[HSUShadowsocksSettings_Server];
    self.serverItem = [RETextItem itemWithTitle:@"Host" value:server placeholder:nil];
    [section addItem:self.serverItem];
    
    NSString *remotePort = self.shadowsocks[HSUShadowsocksSettings_RemotePort];
    self.portItem = [RENumberItem itemWithTitle:@"Port" value:remotePort ?: @"" placeholder:nil format:@"XXXXX"];
    [section addItem:self.portItem];
    
    NSString *passowrd = self.shadowsocks[HSUShadowsocksSettings_Password];
    self.passowrdItem = [RETextItem itemWithTitle:@"Password" value:passowrd placeholder:nil];
    [section addItem:self.passowrdItem];
    
    __weak __typeof(&*self) weakSelf = self;
    NSString *method = self.shadowsocks[HSUShadowsocksSettings_Method] ?: @"Table";
    self.methodItem =
    [RERadioItem itemWithTitle:@"Method"
                         value:method
              selectionHandler:^(RERadioItem *item)
     {
         [item deselectRowAnimated:YES];
         
         NSArray *options = @[@"Table", @"AES-256-CFB", @"AES-192-CFB", @"AES-128-CFB", @"BF-CFB"];
         
         RETableViewOptionsController *optionsController = [[RETableViewOptionsController alloc] initWithItem:item options:options multipleChoice:NO completionHandler:^{
             [weakSelf.navigationController popViewControllerAnimated:YES];
             
             [item reloadRowWithAnimation:UITableViewRowAnimationNone];
         }];
         
         optionsController.delegate = weakSelf;
         optionsController.style = section.style;
         if (weakSelf.tableView.backgroundView == nil) {
             optionsController.tableView.backgroundColor = weakSelf.tableView.backgroundColor;
             optionsController.tableView.backgroundView = nil;
         }
         
         [weakSelf.navigationController pushViewController:optionsController animated:YES];
     }];
    [section addItem:self.methodItem];
    
    if (self.navigationController.viewControllers.count == 1) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
                                                 initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                 target:self
                                                 action:@selector(dismiss)];
    }
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                              initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                              target:self
                                              action:@selector(done)];
    
    [super viewDidLoad];
}

- (void)done
{
    if (!self.serverItem.value || !self.portItem.value || !self.passowrdItem.value || !self.methodItem.value) {
        return;
    }
    
    // read new settings
    NSMutableDictionary *ss = self.shadowsocks.mutableCopy ?: [NSMutableDictionary dictionary];
    ss[HSUShadowsocksSettings_Server] = self.serverItem.value;
    ss[HSUShadowsocksSettings_RemotePort] = self.portItem.value;
    ss[HSUShadowsocksSettings_Password] = self.passowrdItem.value;
    ss[HSUShadowsocksSettings_Method] = self.methodItem.value;
    ss[HSUShadowsocksSettings_Desc] = self.nameItem.value ?: @"";
    
    NSMutableArray *sss = [[[NSUserDefaults standardUserDefaults] objectForKey:HSUShadowsocksSettings] mutableCopy];
    for (NSInteger i=0; i<sss.count; i++) {
        NSDictionary *s = sss[i];
        if ([s[HSUShadowsocksSettings_Server] isEqualToString:ss[HSUShadowsocksSettings_Server]] &&
            [s[HSUShadowsocksSettings_RemotePort] isEqualToString:ss[HSUShadowsocksSettings_RemotePort]]) {
            
            __weak typeof(self)weakSelf = self;
            RIButtonItem *cancelItem = [RIButtonItem itemWithLabel:_("Cancel")];
            RIButtonItem *overrideItem = [RIButtonItem itemWithLabel:_("Override")];
            overrideItem.action = ^{
                sss[i] = s;
                [[NSUserDefaults standardUserDefaults] setObject:sss forKey:HSUShadowsocksSettings];
                [[NSUserDefaults standardUserDefaults] synchronize];
                [weakSelf.navigationController popViewControllerAnimated:YES];
            };
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:_("Server Existed") message:_("You wanna override it?") cancelButtonItem:cancelItem otherButtonItems:overrideItem, nil];
            [alert show];
            return;
        }
    }
    
    [sss addObject:ss];
    [[NSUserDefaults standardUserDefaults] setObject:sss forKey:HSUShadowsocksSettings];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self.navigationController popViewControllerAnimated:YES];
}

@end
