//
//  HSUSettingsVC.m
//  Tweet4China
//
//  Created by Jason Hsu on 13-12-30.
//  Copyright (c) 2013年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUSettingsViewController.h"
#import <RETableViewManager/RETableViewManager.h>
#import <RETableViewManager/RETableViewOptionsController.h>
#import "HSUAccountsViewController.h"
#import "HSUShadowsocksViewController.h"
#import <Appirater/Appirater.h>

@interface HSUSettingsViewController () <RETableViewManagerDelegate>

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
@property (nonatomic, strong) RETableViewManager *manager;
#endif

@end

@implementation HSUSettingsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = _(@"Settings");
    self.view.backgroundColor = kWhiteColor;
    self.tableView = [[UITableView alloc] initWithFrame:self.tableView.frame style:UITableViewStyleGrouped];
    
#if __IPHONE_OS_VERSION_MIN_REQUIRED < 70000
    NSDictionary *attributes = @{UITextAttributeTextColor: bw(50),
                                 UITextAttributeTextShadowColor: kWhiteColor,
                                 UITextAttributeTextShadowOffset: [NSValue valueWithCGSize:ccs(0, 1)]};
    self.navigationController.navigationBar.titleTextAttributes = attributes;
#endif
    
    UIBarButtonItem *doneBarButtonItem = [[UIBarButtonItem alloc]
                                          initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                          target:self
                                          action:@selector(_doneButtonTouched)];
    self.navigationItem.rightBarButtonItem = doneBarButtonItem;
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
    self.manager = [[RETableViewManager alloc] initWithTableView:self.tableView];
    
    RETableViewSection *section = [RETableViewSection section];
    [self.manager addSection:section];
    [section addItem:
     [RETableViewItem itemWithTitle:_(@"Accounts")
                      accessoryType:UITableViewCellAccessoryDisclosureIndicator
                   selectionHandler:^(RETableViewItem *item)
      {
          [item deselectRowAnimated:YES];
          
          HSUAccountsViewController *accountsVC = [[HSUAccountsViewController alloc] init];
          [self.navigationController pushViewController:accountsVC animated:YES];
      }]];
    
    section = [RETableViewSection section];
    [self.manager addSection:section];
    [section addItem:
     [RETableViewItem itemWithTitle:_(@"Shadowsocks")
                      accessoryType:UITableViewCellAccessoryDisclosureIndicator
                   selectionHandler:^(RETableViewItem *item)
      {
          [item deselectRowAnimated:YES];
          
          HSUShadowsocksViewController *shadowsocksVC = [[HSUShadowsocksViewController alloc] init];
          [self.navigationController pushViewController:shadowsocksVC animated:YES];
      }]];
    
    section = [RETableViewSection section];
    [self.manager addSection:section];
    [section addItem:[REBoolItem itemWithTitle:_(@"Sound Effect") value:[GlobalSettings[HSUSettingSoundEffect] boolValue]]];
    [section addItem:[REBoolItem itemWithTitle:_(@"Photo Preview") value:[GlobalSettings[HSUSettingPhotoPreview] boolValue]]];
    __weak __typeof(&*self) weakSelf = self;
    [section addItem:[RERadioItem itemWithTitle:_(@"Text Size") value:GlobalSettings[HSUSettingTextSize] selectionHandler:^(RERadioItem *item) {
        [item deselectRowAnimated:YES];
        
        NSArray *options = @[@"12", @"14", @"16"];
        
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
    
    section = [RETableViewSection section];
    [self.manager addSection:section];
    [section addItem:
     [RETableViewItem itemWithTitle:_(@"Rate on App Store")
                      accessoryType:UITableViewCellAccessoryNone
                   selectionHandler:^(RETableViewItem *item)
      {
          [Appirater rateApp];
          [item deselectRowAnimated:YES];
      }]];
    [section addItem:
     [RETableViewItem itemWithTitle:_(@"Help & Feedback (Email)")
                      accessoryType:UITableViewCellAccessoryNone
                   selectionHandler:^(RETableViewItem *item)
      {
          NSString *subject = @"[Tweet4China 2.6] Feedback";
          NSString *body = _(@"\nDescribe the problem please");
          NSString *url = [NSString stringWithFormat:@"mailto:support@tuoxie.me?subject=%@&body=%@",
                           [subject stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                           [body stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
          [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
          [item deselectRowAnimated:YES];
      }]];
    
    section = [RETableViewSection section];
    [self.manager addSection:section];
    [section addItem:
     [RETableViewItem itemWithTitle:_(@"OpenSource Code (Github)")
                                      accessoryType:UITableViewCellAccessoryNone
                                   selectionHandler:^(RETableViewItem *item)
    {
        NSString *url = @"https://github.com/tuoxie007/tweet4china2";
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
        [item deselectRowAnimated:YES];
    }]];
    [section addItem:
     [RETableViewItem itemWithTitle:_(@"Official Blog (Tumblr)")
                                      accessoryType:UITableViewCellAccessoryNone
                                   selectionHandler:^(RETableViewItem *item)
    {
        NSString *url = @"http://tweet4china.tumblr.com";
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
        [item deselectRowAnimated:YES];
    }]];
    RETableViewItem *item =
    [RETableViewItem itemWithTitle:S(@"%@ (2.6)", _(@"Application Version"))
                     accessoryType:UITableViewCellAccessoryNone
                  selectionHandler:nil];
    item.selectionStyle = UITableViewCellSelectionStyleNone;
    [section addItem:item];
#endif
}

#pragma mark - actions
- (void)_doneButtonTouched
{
    // ss settings
    if (!shadowsocksStarted) {
        [[HSUAppDelegate shared] startShadowsocks];
    }
    
    // app settings
    NSDictionary *globalSettings = GlobalSettings;
    
    RETableViewSection *section  = self.manager.sections[2];
    
    REBoolItem *boolItem = section.items[0];
    BOOL soundEffect = boolItem.value;
    
    boolItem = section.items[1];
    BOOL imagePreview = boolItem.value;
    
    RETextItem *textSizeItem = section.items[2];
    NSString *textSize = textSizeItem.value;
    
    GlobalSettings = @{HSUSettingSoundEffect: @(soundEffect), HSUSettingPhotoPreview: @(imagePreview), HSUSettingTextSize: textSize};
    if (![globalSettings isEqualToDictionary:GlobalSettings]) {
        [[NSUserDefaults standardUserDefaults] setValue:GlobalSettings forKey:HSUSettings];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [[NSNotificationCenter defaultCenter] postNotificationName:HSUSettingsUpdatedNotification object:GlobalSettings];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
