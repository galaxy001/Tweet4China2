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
#import <HSUWebCache/HSUWebCache.h>
#import "HSUProfileViewController.h"
#import "HSUAppDelegate.h"

@interface HSUSettingsViewController () <RETableViewManagerDelegate>

@property (nonatomic, strong) RETableViewManager *manager;
@property (nonatomic, weak) REBoolItem *soundEffectItem;
@property (nonatomic, weak) REBoolItem *photoPreviewItem;
@property (nonatomic, weak) RERadioItem *textSizeItem;
@property (nonatomic, weak) RERadioItem *cacheSizeItem;

@end

@implementation HSUSettingsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = _("Settings");
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
    
    self.manager = [[RETableViewManager alloc] initWithTableView:self.tableView];
    
    RETableViewSection *section = [RETableViewSection section];
    [self.manager addSection:section];
    [section addItem:
     [RETableViewItem itemWithTitle:_("Accounts")
                      accessoryType:UITableViewCellAccessoryDisclosureIndicator
                   selectionHandler:^(RETableViewItem *item)
      {
          [item deselectRowAnimated:YES];
          
          HSUAccountsViewController *accountsVC = [[HSUAccountsViewController alloc] init];
          [self.navigationController pushViewController:accountsVC animated:YES];
      }]];
    
//#ifndef FreeApp
    section = [RETableViewSection section];
    [self.manager addSection:section];
    [section addItem:
     [RETableViewItem itemWithTitle:_("Proxy Server")
                      accessoryType:UITableViewCellAccessoryDisclosureIndicator
                   selectionHandler:^(RETableViewItem *item)
      {
          [item deselectRowAnimated:YES];
          
          if (![[HSUAppDelegate shared] buyProApp]) {
              return ;
          }
          
          HSUShadowsocksViewController *shadowsocksVC = [[HSUShadowsocksViewController alloc] init];
          [self.navigationController pushViewController:shadowsocksVC animated:YES];
      }]];
//#endif
    
    section = [RETableViewSection section];
    [self.manager addSection:section];
    REBoolItem *soundEffectItem = [REBoolItem itemWithTitle:_("Sound Effect") value:[GlobalSettings[HSUSettingSoundEffect] boolValue]];
    self.soundEffectItem = soundEffectItem;
    [section addItem:soundEffectItem];
    __weak typeof(self) weakSelf = self;
    soundEffectItem.switchValueChangeHandler = ^(REBoolItem *item) {
        
        if (![[HSUAppDelegate shared] buyProApp]) {
            item.value = YES;
            [weakSelf.tableView reloadData];
            return ;
        }
    };
    
    REBoolItem *photoPreviewItem = [REBoolItem itemWithTitle:_("Photo Preview") value:[GlobalSettings[HSUSettingPhotoPreview] boolValue]];
    self.photoPreviewItem = photoPreviewItem;
    [section addItem:photoPreviewItem];
    photoPreviewItem.switchValueChangeHandler = ^(REBoolItem *item) {
        
        if (![[HSUAppDelegate shared] buyProApp]) {
            item.value = NO;
            [weakSelf.tableView reloadData];
            return ;
        }
    };
    
    RERadioItem *textSizeItem = [RERadioItem itemWithTitle:_("Text Size") value:GlobalSettings[HSUSettingTextSize] selectionHandler:^(RERadioItem *item) {
        [item deselectRowAnimated:YES];
        
        if (![[HSUAppDelegate shared] buyProApp]) {
            return ;
        }
        
        NSArray *options = @[@"12", @"14", @"16", @"18"];
        
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
    self.textSizeItem = textSizeItem;
    [section addItem:textSizeItem];
    
    RERadioItem *cacheSizeItem = [RERadioItem itemWithTitle:_("Cache Size") value:GlobalSettings[HSUSettingCacheSize] selectionHandler:^(RERadioItem *item) {
        [item deselectRowAnimated:YES];
        
        if (![[HSUAppDelegate shared] buyProApp]) {
            return ;
        }
        
        NSArray *options = @[@"16MB", @"32MB", @"64MB", @"128MB", @"256MB", @"512MB", @"1GB", @"2GB", @"4GB"];
        
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
    self.cacheSizeItem = cacheSizeItem;
    [section addItem:cacheSizeItem];
    
    [section addItem:[RETableViewItem
                      itemWithTitle:_("Clean Cache")
                      accessoryType:UITableViewCellAccessoryNone
                      selectionHandler:^(RETableViewItem *item)
    {
        [item deselectRowAnimated:YES];
        
        [SVProgressHUD showWithStatus:nil];
        dispatch_async(GCDMainThread, ^{
            NSError *error = [HSUWebCache cleanCache];
            if (error) {
                [Flurry logError:@"clean_cache_failed" message:nil error:error];
            }
            NSString *cachePath = tp(@"");
            for (NSString *subDir in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:cachePath error:nil]) {
                if ([subDir hasSuffix:@".localstorage"] ||
                    [subDir hasPrefix:@"me.tuoxie"]) {
                    NSString *subPath = tp(subDir);
                    [[NSFileManager defaultManager] removeItemAtPath:subPath error:&error];
                    if (error) {
                        [Flurry logError:@"clean_cache_failed" message:nil error:error];
                        break;
                    }
                }
            }
            [SVProgressHUD dismiss];
        });
    }]];
    
    section = [RETableViewSection section];
    [self.manager addSection:section];
    [section addItem:
     [RETableViewItem itemWithTitle:_("Rate on App Store")
                      accessoryType:UITableViewCellAccessoryNone
                   selectionHandler:^(RETableViewItem *item)
      {
          [Appirater rateApp];
          [item deselectRowAnimated:YES];
      }]];
    [section addItem:
     [RETableViewItem itemWithTitle:_("Help & Feedback (Email)")
                      accessoryType:UITableViewCellAccessoryNone
                   selectionHandler:^(RETableViewItem *item)
      {
          NSString *subject = @"[Tweet4China 2.6] Feedback";
          NSString *body = _("\nDescribe the problem please");
          NSString *url = [NSString stringWithFormat:@"mailto:support@tuoxie.me?subject=%@&body=%@",
                           [subject stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                           [body stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
          [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
          [item deselectRowAnimated:YES];
      }]];
#ifdef FreeApp
    [section addItem:
     [RETableViewItem itemWithTitle:_("Buy Pro")
                      accessoryType:UITableViewCellAccessoryNone
                   selectionHandler:^(RETableViewItem *item)
      {
          [[HSUAppDelegate shared] buyProApp];
          
          [item deselectRowAnimated:YES];
      }]];
#endif
    
    section = [RETableViewSection section];
    [self.manager addSection:section];
    [section addItem:
     [RETableViewItem itemWithTitle:_("Developer (@tuoxie007)")
                      accessoryType:UITableViewCellAccessoryNone
                   selectionHandler:^(RETableViewItem *item)
      {
          HSUProfileViewController *profileVC = [[HSUProfileViewController alloc] initWithScreenName:@"tuoxie007"];
          [self.navigationController pushViewController:profileVC animated:YES];
          [item deselectRowAnimated:YES];
      }]];
    [section addItem:
     [RETableViewItem itemWithTitle:_("OpenSource Code (Github)")
                                      accessoryType:UITableViewCellAccessoryNone
                                   selectionHandler:^(RETableViewItem *item)
    {
        NSString *url = @"https://github.com/tuoxie007/tweet4china2";
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
        [item deselectRowAnimated:YES];
    }]];
    [section addItem:
     [RETableViewItem itemWithTitle:_("OpenCam (Github)")
                      accessoryType:UITableViewCellAccessoryNone
                   selectionHandler:^(RETableViewItem *item)
      {
          NSString *url = @"https://github.com/tuoxie007/OpenCam";
          [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
          [item deselectRowAnimated:YES];
      }]];
    [section addItem:
     [RETableViewItem itemWithTitle:_("Official Blog (Tumblr)")
                                      accessoryType:UITableViewCellAccessoryNone
                                   selectionHandler:^(RETableViewItem *item)
    {
        NSString *url = @"http://tweet4china.tumblr.com";
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
        [item deselectRowAnimated:YES];
    }]];
    NSString *verNum = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
#ifdef FreeApp
    NSString *verion = [NSString stringWithFormat:@"Free %@", verNum];
#else
    NSString *verion = [NSString stringWithFormat:@"Pro %@", verNum];
#endif
    RETableViewItem *item =
    [RETableViewItem itemWithTitle:S(@"%@ (%@)", _("Application Version"), verion)
                     accessoryType:UITableViewCellAccessoryNone
                  selectionHandler:nil];
    item.selectionStyle = UITableViewCellSelectionStyleNone;
    [section addItem:item];
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
    
    BOOL soundEffect = self.soundEffectItem.value;
    BOOL imagePreview = self.photoPreviewItem.value;
    NSString *textSize = self.textSizeItem.value;
    NSString *cacheSize = self.cacheSizeItem.value;
    
    GlobalSettings = @{HSUSettingSoundEffect: @(soundEffect), HSUSettingPhotoPreview: @(imagePreview), HSUSettingTextSize: textSize, HSUSettingCacheSize: cacheSize};
    if (![globalSettings isEqualToDictionary:GlobalSettings]) {
        [[NSUserDefaults standardUserDefaults] setValue:GlobalSettings forKey:HSUSettings];
        [[NSUserDefaults standardUserDefaults] synchronize];
        notification_post_with_object(HSUSettingsUpdatedNotification, GlobalSettings);
        [[HSUAppDelegate shared] updateImageCacheSize];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
