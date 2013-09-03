//
//  HSUProxySettingsViewController.m
//  Tweet4China
//
//  Created by Jason Hsu on 13-8-30.
//  Copyright (c) 2013年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUProxySettingsViewController.h"
#import "RETableViewManager.h"

@interface HSUProxySettingsViewController ()

@property (nonatomic, strong) RETableViewManager *manager;

@end

@implementation HSUProxySettingsViewController

- (void)viewDidLoad
{
    self.title = @"shadowsocks settings";
    
    self.manager = [[RETableViewManager alloc] initWithTableView:self.tableView];
    RETableViewSection *section = [RETableViewSection sectionWithHeaderTitle:@"Host"];
    [self.manager addSection:section];
    NSString *server = [[NSUserDefaults standardUserDefaults] objectForKey:kShadowsocksSettings_Server];
    [section addItem:[RETextItem itemWithTitle:nil value:server placeholder:@"IP or Domain"]];
    
    section = [RETableViewSection sectionWithHeaderTitle:@"Port"];
    [self.manager addSection:section];
    NSString *remotePort = [[NSUserDefaults standardUserDefaults] objectForKey:kShadowsocksSettings_RemotePort];
    [section addItem:[RENumberItem itemWithTitle:nil value:remotePort ?: @"" placeholder:@"e.g. 8123" format:@"XXXX"]];
    
    section = [RETableViewSection sectionWithHeaderTitle:@"Password"];
    [self.manager addSection:section];
    NSString *passowrd = [[NSUserDefaults standardUserDefaults] objectForKey:kShadowsocksSettings_Password];
    [section addItem:[RETextItem itemWithTitle:nil value:passowrd placeholder:@"e.g. shadow.1989.6.31"]];
    
    section = [RETableViewSection sectionWithHeaderTitle:@"Encryption Method"];
    [self.manager addSection:section];
    NSString *method = [[NSUserDefaults standardUserDefaults] objectForKey:kShadowsocksSettings_Method];
    for (NSString *value in @[@"Table", @"AES-256-CFB", @"AES-192-CFB", @"AES-128-CFB", @"BF-CFB"]) {
        UITableViewCellAccessoryType accessoryType =
        [method isEqualToString:[value lowercaseString]] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        [section addItem:
         [RETableViewItem itemWithTitle:value
                          accessoryType:accessoryType
                       selectionHandler:^(RETableViewItem *item)
          {
              [section.items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                  RETableViewItem *aItem = obj;
                  aItem.accessoryType = aItem == item ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
              }];
              [self.tableView reloadData];
              [[NSUserDefaults standardUserDefaults] setObject:[value lowercaseString] forKey:kShadowsocksSettings_Method];
              [[NSUserDefaults standardUserDefaults] synchronize];
          }]];
    }
    
//    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
//                                              initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
//                                              target:self
//                                              action:@selector(cancel)];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                              initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                              target:self
                                              action:@selector(done)];
    
    [super viewDidLoad];
}

- (void)cancel
{
    [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:kShadowsocksSettings_Direct];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self dismiss];
}

- (void)done
{
    RETableViewSection *section  = self.manager.sections[0];
    RETextItem *item = section.items[0];
    
    section  = self.manager.sections[1];
    RENumberItem *remotePortItem = section.items[0];
    
    section  = self.manager.sections[2];
    RETextItem *passowrdItem = section.items[0];
    
    [[NSUserDefaults standardUserDefaults] setObject:item.value forKey:kShadowsocksSettings_Server];
    [[NSUserDefaults standardUserDefaults] setObject:remotePortItem.value forKey:kShadowsocksSettings_RemotePort];
    [[NSUserDefaults standardUserDefaults] setObject:passowrdItem.value forKey:kShadowsocksSettings_Password];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    if (!StartProxy()) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:@"Finish Settings or Tap Cancel"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil, nil];
        [alert show];
    } else {
        [self dismiss];
    }
}

@end
