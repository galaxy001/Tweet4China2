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

@end

@implementation HSUProxySettingsViewController

- (void)viewDidLoad
{
    self.title = @"shadowsocks";
    
    self.manager = [[RETableViewManager alloc] initWithTableView:self.tableView];
    
    RETableViewSection *section = [RETableViewSection section];
    [self.manager addSection:section];
    
    NSString *server = self.shadowsocks[HSUShadowsocksSettings_Server];
    [section addItem:[RETextItem itemWithTitle:@"Host" value:server placeholder:nil]];
    
    NSString *remotePort = self.shadowsocks[HSUShadowsocksSettings_RemotePort];
    [section addItem:[RENumberItem itemWithTitle:@"Port" value:remotePort ?: @"" placeholder:nil format:@"XXXXX"]];
    
    NSString *passowrd = self.shadowsocks[HSUShadowsocksSettings_Password];
    [section addItem:[RETextItem itemWithTitle:@"Password" value:passowrd placeholder:nil]];
    
    __weak __typeof(&*self) weakSelf = self;
    NSString *method = self.shadowsocks[HSUShadowsocksSettings_Method] ?: @"Table";
    [section addItem:
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
    }]];
    
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
    RETableViewSection *section  = self.manager.sections[0];
    
    RETextItem *serverItem = section.items[0];
    RENumberItem *portItem = section.items[1];
    RETextItem *passowrdItem = section.items[2];
    RETextItem *methodItem = section.items[3];
    if (!serverItem.value || !portItem.value || !passowrdItem.value || !methodItem.value) {
        return;
    }
    
    // read new settings
    NSMutableDictionary *ss = self.shadowsocks.mutableCopy ?: [NSMutableDictionary dictionary];
    ss[HSUShadowsocksSettings_Server] = serverItem.value;
    ss[HSUShadowsocksSettings_RemotePort] = portItem.value;
    ss[HSUShadowsocksSettings_Password] = passowrdItem.value;
    ss[HSUShadowsocksSettings_Method] = methodItem.value;
    if (self.navigationController.viewControllers.count == 1) {
        ss[HSUShadowsocksSettings_Selected] = @YES;
    }
    
    NSMutableArray *sss = [[[NSUserDefaults standardUserDefaults] objectForKey:HSUShadowsocksSettings] mutableCopy];
    [sss addObject:ss];
    [[NSUserDefaults standardUserDefaults] setObject:sss forKey:HSUShadowsocksSettings];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // setting for first launch in opensource or network problem accoured
    // not pushed from settings view controller
    if ([ss[HSUShadowsocksSettings_Selected] boolValue]) {
        if (![[HSUAppDelegate shared] startShadowsocks]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                            message:_("Finish Settings or Tap Cancel")
                                                           delegate:nil
                                                  cancelButtonTitle:_("OK")
                                                  otherButtonTitles:nil, nil];
            [alert show];
        } else {
            [self dismiss];
        }
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

@end
