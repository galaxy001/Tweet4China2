//
//  HSUGeneralSettingsViewController.m
//  Tweet4China
//
//  Created by Jason Hsu on 14-1-18.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUGeneralSettingsViewController.h"
#import <RETableViewManager/RETableViewManager.h>
#import <RETableViewManager/RETableViewOptionsController.h>
#import <HSUWebCache/HSUWebCache.h>

@interface HSUGeneralSettingsViewController () <RETableViewManagerDelegate>

@property (nonatomic, weak) REBoolItem *soundEffectItem;
@property (nonatomic, weak) REBoolItem *photoPreviewItem;
@property (nonatomic, weak) RERadioItem *textSizeItem;
@property (nonatomic, weak) REBoolItem *roundAvatarItem;
@property (nonatomic, weak) REBoolItem *desktopUserAgentItem;
@property (nonatomic, weak) REBoolItem *excludeRepliesItem;
@property (nonatomic, weak) REBoolItem *selectBeforeStartCameraItem;
@property (nonatomic, weak) REBoolItem *showOriginalImageItem;
@property (nonatomic, weak) REBoolItem *overseasItem;
@property (nonatomic, weak) REBoolItem *autoUpdateConnectItem;
@property (nonatomic, weak) REBoolItem *autoUpdateConversationItem;
@property (nonatomic, weak) REBoolItem *refreshThenScrollToTopItem;
@property (nonatomic, weak) REBoolItem *insertMoreToUpperItem;
@property (nonatomic, weak) RERadioItem *pageCountItem;
@property (nonatomic, weak) RERadioItem *pageCountWWANItem;
@property (nonatomic, weak) RERadioItem *cacheSizeItem;
@property (nonatomic, weak) RETableViewItem *cleanCacheItem;

@end

@implementation HSUGeneralSettingsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem *doneBarButtonItem = [[UIBarButtonItem alloc]
                                          initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                          target:self
                                          action:@selector(_doneButtonTouched)];
    self.navigationItem.rightBarButtonItem = doneBarButtonItem;
    
    RETableViewSection *section = [RETableViewSection section];
    [self.manager addSection:section];
    
    REBoolItem *soundEffectItem = [REBoolItem itemWithTitle:_("Sound Effect")
                                                      value:boolSetting(HSUSettingSoundEffect)];
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
    
    REBoolItem *photoPreviewItem = [REBoolItem itemWithTitle:_("Photo Preview")
                                                       value:boolSetting(HSUSettingPhotoPreview)];
    self.photoPreviewItem = photoPreviewItem;
    [section addItem:photoPreviewItem];
    photoPreviewItem.switchValueChangeHandler = ^(REBoolItem *item) {
        
        if (![[HSUAppDelegate shared] buyProApp]) {
            item.value = NO;
            [weakSelf.tableView reloadData];
            return ;
        }
    };
    
    RERadioItem *textSizeItem = [RERadioItem itemWithTitle:_("Text Size")
                                                     value:setting(HSUSettingTextSize) selectionHandler:^(RERadioItem *item) {
        [item deselectRowAnimated:YES];
        
        if (![[HSUAppDelegate shared] buyProApp]) {
            return ;
        }
        
        NSArray *options = @[@"12", @"14", @"16", @"18", @"20", @"25", @"30", @"50", @"100"];
        
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
    
    REBoolItem *roundAvatarItem = [REBoolItem itemWithTitle:_("Round Avatar")
                                                      value:boolSetting(HSUSettingRoundAvatar)];
    self.roundAvatarItem = roundAvatarItem;
    [section addItem:roundAvatarItem];
    roundAvatarItem.switchValueChangeHandler = ^(REBoolItem *item) {
        
        if (![[HSUAppDelegate shared] buyProApp]) {
            item.value = NO;
            [weakSelf.tableView reloadData];
            return ;
        }
    };
    
    REBoolItem *desktopUserAgentItem = [REBoolItem itemWithTitle:_("Desktop Web Browser")
                                                           value:boolSetting(HSUSettingDesktopUserAgent)];
    self.desktopUserAgentItem = desktopUserAgentItem;
    [section addItem:desktopUserAgentItem];
    desktopUserAgentItem.switchValueChangeHandler = ^(REBoolItem *item) {
        
        if (![[HSUAppDelegate shared] buyProApp]) {
            item.value = NO;
            [weakSelf.tableView reloadData];
            return ;
        }
        
    };
    
    REBoolItem *excludeRepliesItem = [REBoolItem itemWithTitle:_("Exclude Replies")
                                                         value:boolSetting(HSUSettingExcludeReplies)];
    self.excludeRepliesItem = excludeRepliesItem;
    [section addItem:excludeRepliesItem];
    excludeRepliesItem.switchValueChangeHandler = ^(REBoolItem *item) {
        
        if (![[HSUAppDelegate shared] buyProApp]) {
            item.value = NO;
            [weakSelf.tableView reloadData];
            return ;
        }
        
    };
    
    RERadioItem *pageCountItem =
    [RERadioItem itemWithTitle:_("Page Size (WiFi)")
                         value:setting(HSUSettingPageCount) ?: S(@"%d", kRequestDataCountViaWifi)
              selectionHandler:^(RERadioItem *item)
     {
         [item deselectRowAnimated:YES];
         
         if (![[HSUAppDelegate shared] buyProApp]) {
             return ;
         }
         
         NSArray *options = @[@"20", @"50", @"100", @"200"];
         
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
    self.pageCountItem = pageCountItem;
    [section addItem:pageCountItem];
    
    RERadioItem *pageCountWWANItem =
    [RERadioItem itemWithTitle:_("Page Size (Cellular)")
                         value:setting(HSUSettingPageCountWWAN) ?: S(@"%d", kRequestDataCountViaWWAN)
              selectionHandler:^(RERadioItem *item)
     {
         [item deselectRowAnimated:YES];
         
         if (![[HSUAppDelegate shared] buyProApp]) {
             return ;
         }
         
         NSArray *options = @[@"20", @"50", @"100", @"200"];
         
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
    self.pageCountWWANItem = pageCountWWANItem;
    [section addItem:pageCountWWANItem];
    
    REBoolItem *selectBeforeStartCameraItem =
    [REBoolItem itemWithTitle:_("Select before start camera")
                        value:boolSetting(HSUSettingSelectBeforeStartCamera)];
    self.selectBeforeStartCameraItem = selectBeforeStartCameraItem;
    [section addItem:selectBeforeStartCameraItem];
    selectBeforeStartCameraItem.switchValueChangeHandler = ^(REBoolItem *item) {
        
        if (![[HSUAppDelegate shared] buyProApp]) {
            item.value = NO;
            [weakSelf.tableView reloadData];
            return ;
        }
        
    };
    
    REBoolItem *showOriginalImageItem =
    [REBoolItem itemWithTitle:_("Original image quality")
                        value:boolSetting(HSUSettingShowOriginalImage)];
    self.showOriginalImageItem = showOriginalImageItem;
    [section addItem:showOriginalImageItem];
    showOriginalImageItem.switchValueChangeHandler = ^(REBoolItem *item) {
        
        if (![[HSUAppDelegate shared] buyProApp]) {
            item.value = NO;
            [weakSelf.tableView reloadData];
            return ;
        }
        
    };
    
    REBoolItem *overseasItem = [REBoolItem itemWithTitle:_("Connect directly")
                                                   value:boolSetting(HSUSettingOverseas)];
    self.overseasItem = overseasItem;
    [section addItem:overseasItem];
    overseasItem.switchValueChangeHandler = ^(REBoolItem *item) {
        
        if (![[HSUAppDelegate shared] buyProApp]) {
            item.value = NO;
            [weakSelf.tableView reloadData];
            return ;
        }
        
        RIButtonItem *cancelItem = [RIButtonItem itemWithLabel:_("Cancel")];
        RIButtonItem *restartItem = [RIButtonItem itemWithLabel:_("Restart Now")];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:_("App need restart to apply this optional") cancelButtonItem:cancelItem otherButtonItems:restartItem, nil];
        [alert show];
        cancelItem.action = ^{
            item.value = !item.value;
            [weakSelf.tableView reloadData];
        };
        restartItem.action = ^{
            [weakSelf _doneButtonTouched];
            exit(0);
        };
    };
    
    REBoolItem *autoUpdateConnectItem = [REBoolItem itemWithTitle:_("Auto Update Connect")
                                                            value:boolSetting(HSUSettingAutoUpdateConnect)];
    self.autoUpdateConnectItem = autoUpdateConnectItem;
    [section addItem:autoUpdateConnectItem];
    autoUpdateConnectItem.switchValueChangeHandler = ^(REBoolItem *item) {
        
        if (![[HSUAppDelegate shared] buyProApp]) {
            item.value = NO;
            [weakSelf.tableView reloadData];
            return ;
        }
    };
    
    REBoolItem *autoUpdateConversationItem = [REBoolItem itemWithTitle:_("Auto Update Messages")
                                                                 value:boolSetting(HSUSettingAutoUpdateConversation)];
    self.autoUpdateConversationItem = autoUpdateConversationItem;
    [section addItem:autoUpdateConversationItem];
    autoUpdateConversationItem.switchValueChangeHandler = ^(REBoolItem *item) {
        
        if (![[HSUAppDelegate shared] buyProApp]) {
            item.value = NO;
            [weakSelf.tableView reloadData];
            return ;
        }
    };
    
    REBoolItem *refreshThenScrollToTopItem = [REBoolItem itemWithTitle:_("Refresh then Scroll to Top")
                                                                 value:boolSetting(HSUSettingRefreshThenScrollToTop)];
    self.refreshThenScrollToTopItem = refreshThenScrollToTopItem;
    [section addItem:refreshThenScrollToTopItem];
    refreshThenScrollToTopItem.switchValueChangeHandler = ^(REBoolItem *item) {
        
        if (![[HSUAppDelegate shared] buyProApp]) {
            item.value = NO;
            [weakSelf.tableView reloadData];
            return ;
        }
    };

    REBoolItem *insertMoreToUpperItem = [REBoolItem itemWithTitle:_("Insert More to Upper")
                                                                 value:boolSetting(HSUSettingRefreshThenScrollToTop)];
    self.insertMoreToUpperItem = insertMoreToUpperItem;
    [section addItem:insertMoreToUpperItem];
    insertMoreToUpperItem.switchValueChangeHandler = ^(REBoolItem *item) {

        if (![[HSUAppDelegate shared] buyProApp]) {
            item.value = NO;
            [weakSelf.tableView reloadData];
            return ;
        }
    };
    
    RERadioItem *cacheSizeItem =
    [RERadioItem itemWithTitle:_("Cache Size")
                         value:setting(HSUSettingCacheSize)
              selectionHandler:^(RERadioItem *item)
    {
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
    
    RETableViewItem *cleanCacheItem =
    [RETableViewItem
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
     }];
    self.cleanCacheItem = cleanCacheItem;
    [section addItem:self.cleanCacheItem];
}

- (void)_doneButtonTouched
{
    // app settings
    NSDictionary *globalSettings = GlobalSettings;
    
    BOOL soundEffect = self.soundEffectItem.value;
    BOOL imagePreview = self.photoPreviewItem.value;
    BOOL roundAvatar = self.roundAvatarItem.value;
    BOOL desktopUserAgent = self.desktopUserAgentItem.value;
    BOOL excludeReplies = self.excludeRepliesItem.value;
    BOOL selectBeforeStartCamera = self.selectBeforeStartCameraItem.value;
    BOOL showOriginalImage = self.showOriginalImageItem.value;
    BOOL connectDirectly = self.overseasItem.value;
    BOOL autoUpdateConnect = self.autoUpdateConnectItem.value;
    BOOL autoUpdateConversation = self.autoUpdateConversationItem.value;
    BOOL refreshThenScrollToTop = self.refreshThenScrollToTopItem.value;
    BOOL insertMoreToUpper = self.insertMoreToUpperItem.value;
    NSString *pageCount = self.pageCountItem.value;
    NSString *pageCountWWAN = self.pageCountWWANItem.value;
    NSString *textSize = self.textSizeItem.value;
    NSString *cacheSize = self.cacheSizeItem.value;
    
    GlobalSettings = @{HSUSettingSoundEffect: @(soundEffect),
                       HSUSettingPhotoPreview: @(imagePreview),
                       HSUSettingTextSize: textSize,
                       HSUSettingCacheSize: cacheSize,
                       HSUSettingRoundAvatar: @(roundAvatar),
                       HSUSettingPageCount: pageCount,
                       HSUSettingPageCountWWAN: pageCountWWAN,
                       HSUSettingDesktopUserAgent: @(desktopUserAgent),
                       HSUSettingExcludeReplies: @(excludeReplies),
                       HSUSettingSelectBeforeStartCamera: @(selectBeforeStartCamera),
                       HSUSettingShowOriginalImage: @(showOriginalImage),
                       HSUSettingOverseas: @(connectDirectly),
                       HSUSettingAutoUpdateConnect: @(autoUpdateConnect),
                       HSUSettingAutoUpdateConversation: @(autoUpdateConversation),
                       HSUSettingRefreshThenScrollToTop: @(refreshThenScrollToTop),
                       HSUSettingInsertMoreToUpper:@(insertMoreToUpper)};
    
    if (![globalSettings isEqualToDictionary:GlobalSettings]) {
        if ([globalSettings[HSUSettingDesktopUserAgent] boolValue] != [GlobalSettings[HSUSettingDesktopUserAgent] boolValue]) {
            notification_post(HSUSettingUserAgentChangedNotification);
        }
        if ([globalSettings[HSUSettingExcludeReplies] boolValue] != [GlobalSettings[HSUSettingExcludeReplies] boolValue]) {
            notification_post(HSUSettingExcludeRepliesChangedNotification);
        }
        [[NSUserDefaults standardUserDefaults] setValue:GlobalSettings forKey:HSUSettings];
        [[NSUserDefaults standardUserDefaults] synchronize];
        notification_post_with_object(HSUSettingsUpdatedNotification, GlobalSettings);
        [[HSUAppDelegate shared] updateImageCacheSize];
        if (desktopUserAgent) {
            [HSUCommonTools switchToDesktopUserAgent];
        } else {
            [HSUCommonTools resetUserAgent];
        }
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
