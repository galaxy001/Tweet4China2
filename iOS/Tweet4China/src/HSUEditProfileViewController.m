//
//  HSUEditProfileViewController.m
//  Tweet4China
//
//  Created by Jason Hsu on 14-1-2.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUEditProfileViewController.h"
#import <RETableViewManager/RETableViewManager.h>
#import <RETableViewManager/RETableViewOptionsController.h>
#import <OpenCam/OpenCam.h>

@interface HSUEditProfileViewController () <RETableViewManagerDelegate, OCMCameraViewControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, strong) RETableViewManager *manager;
@property (nonatomic, weak) RETableViewItem *avatarItem;
@property (nonatomic, weak) RETableViewItem *bannerItem;
@property (nonatomic, weak) RETextItem *nameItem;
@property (nonatomic, weak) RETextItem *locationItem;
@property (nonatomic, weak) RETextItem *urlItem;
@property (nonatomic, weak) RELongTextItem *descItem;
@property (nonatomic) BOOL updated;
@property (nonatomic) BOOL selectPhotoForAvatar;

@end

@implementation HSUEditProfileViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.tableView.frame style:UITableViewStyleGrouped];
    
    self.title = _("Edit Profile");
    
    self.manager = [[RETableViewManager alloc] initWithTableView:self.tableView];
    
    RETableViewSection *section = [RETableViewSection section];
    [self.manager addSection:section];
    
    RETableViewItem *avatarItem = [RETableViewItem itemWithTitle:_("Avatar")];
    if (self.avatarImage) {
        avatarItem.image = [self.avatarImage scaleToWidth:48];
    }
    self.avatarItem = avatarItem;
    [section addItem:avatarItem];
    __weak typeof(self) weakSelf = self;
    avatarItem.selectionHandler = ^(RETableViewItem *item) {
        [item deselectRowAnimated:YES];
        
        if (![[HSUAppDelegate shared] buyProApp]) {
            return ;
        }
        
        [weakSelf avatarTouched];
    };
    
    section = [RETableViewSection section];
    [self.manager addSection:section];
    
    RETableViewItem *bannerItem = [RETableViewItem itemWithTitle:_("Banner")];
    if (self.bannerImage) {
        bannerItem.image = [self.bannerImage scaleToWidth:96];
    }
    self.bannerItem = bannerItem;
    [section addItem:bannerItem];
    bannerItem.selectionHandler = ^(RETableViewItem *item) {
        [item deselectRowAnimated:YES];
        
        if (![[HSUAppDelegate shared] buyProApp]) {
            return ;
        }
        
        [weakSelf bannerTouched];
    };
    
    section = [RETableViewSection section];
    [self.manager addSection:section];
    
    RETextItem *nameItem = [RETextItem itemWithTitle:_("Name")];
    self.nameItem = nameItem;
    [section addItem:nameItem];
    nameItem.clearButtonMode = UITextFieldViewModeWhileEditing;
    nameItem.value = self.profile[@"name"];
    nameItem.charactersLimit = 20;
    nameItem.onChange = ^(RETextItem *item) {
        BOOL changed = ![item.value isEqualToString:weakSelf.profile[@"name"]];
        weakSelf.navigationItem.rightBarButtonItem.enabled = changed;
        weakSelf.updated = changed;
    };
    
    RETextItem *locationItem = [RETextItem itemWithTitle:_("Location")];
    self.locationItem = locationItem;
    [section addItem:locationItem];
    locationItem.clearButtonMode = UITextFieldViewModeWhileEditing;
    locationItem.value = self.profile[@"location"];
    locationItem.charactersLimit = 30;
    locationItem.onChange = ^(RETextItem *item) {
        BOOL changed = ![item.value isEqualToString:weakSelf.profile[@"location"]];
        weakSelf.navigationItem.rightBarButtonItem.enabled = changed;
        weakSelf.updated = changed;
    };
    
    RETextItem *urlItem = [RETextItem itemWithTitle:_("Site")];
    self.urlItem = urlItem;
    [section addItem:urlItem];
    urlItem.clearButtonMode = UITextFieldViewModeWhileEditing;
    urlItem.value = [self _websiteForProfile:self.profile];
    urlItem.charactersLimit = 92;
    urlItem.onChange = ^(RETextItem *item) {
        BOOL changed = ![item.value isEqualToString:[weakSelf _websiteForProfile:weakSelf.profile]];
        weakSelf.navigationItem.rightBarButtonItem.enabled = changed;
        weakSelf.updated = changed;
    };
    
    // todo: always failed
    section = [RETableViewSection section];
    [self.manager addSection:section];
    
    RELongTextItem *descItem = [RELongTextItem item];
    self.descItem = descItem;
    [section addItem:descItem];
    descItem.value = self.profile[@"description"];
    descItem.placeholder = _("Introduce yourself");
    descItem.cellHeight = 88;
    descItem.charactersLimit = 160;
    descItem.onChange = ^(RETextItem *item) {
        BOOL changed = ![item.value isEqualToString:weakSelf.profile[@"description"]];
        self.navigationItem.rightBarButtonItem.enabled = YES;
        weakSelf.updated = changed;
    };
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:_("Cancel") style:UIBarButtonItemStylePlain target:self action:@selector(cancel)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:_("Save") style:UIBarButtonItemStyleDone target:self action:@selector(save)];
    self.navigationItem.rightBarButtonItem.enabled = NO;
}

- (void)selectPhotoForAvatar:(BOOL)forAvatar
{
    OCMCameraViewController *cameraVC = [OpenCam cameraViewController];
    cameraVC.enterCameraRollAtStart = YES;
    if (forAvatar) {
        cameraVC.maxWidth = 640;
    } else {
        cameraVC.maxWidth = 1280;
    }
    cameraVC.delegate = self;
    [self presentViewController:cameraVC animated:YES completion:nil];
    self.selectPhotoForAvatar = forAvatar;
}

- (void)avatarTouched
{
    [self selectPhotoForAvatar:YES];
}

- (void)bannerTouched
{
    [self selectPhotoForAvatar:NO];
}

- (void)cameraViewControllerDidFinish:(OCMCameraViewController *)cameraViewController
{
    UIImage *image = cameraViewController.photo;
    if (image) {
        [SVProgressHUD showWithStatus:_("Uploading...")];
        // get center square
        if (image.size.width > image.size.height) {
            image = [image subImageAtRect:ccr(image.size.width/2-image.size.height/2, 0, image.size.height, image.size.height)];
        } else if (image.size.width < image.size.height) {
            image = [image subImageAtRect:ccr(0, image.size.height/2-image.size.width/2, image.size.width, image.size.width)];
        }
        __weak typeof(self) weakSelf = self;
        if (self.selectPhotoForAvatar) {
            [twitter updateAvatar:image success:^(id responseObj) {
                weakSelf.avatarItem.image = [image scaleToWidth:48];
                [weakSelf.tableView reloadData];
                [SVProgressHUD dismiss];
                [weakSelf.profileVC reloadData];
                weakSelf.navigationItem.rightBarButtonItem.enabled = YES;
            } failure:^(NSError *error) {
                [SVProgressHUD showErrorWithStatus:_("Upload failed")];
            }];
        } else {
            // get center rectangle
            if (image.size.width > image.size.height * 2) {
                image = [image subImageAtRect:ccr(image.size.width/2-image.size.height, 0, image.size.height*2, image.size.height)];
            } else if (image.size.width < image.size.height * 2) {
                image = [image subImageAtRect:ccr(0, image.size.height-image.size.width/2, image.size.width, image.size.width/2)];
            }
            [twitter updateBanner:image success:^(id responseObj) {
                weakSelf.bannerItem.image = [image scaleToWidth:96];
                [weakSelf.tableView reloadData];
                [SVProgressHUD dismiss];
                [weakSelf.profileVC reloadData];
                weakSelf.navigationItem.rightBarButtonItem.enabled = YES;
            } failure:^(NSError *error) {
                [SVProgressHUD showErrorWithStatus:_("Upload failed")];
            }];
        }
        self.selectPhotoForAvatar = NO;
    }
}

- (void)cancel
{
    [self dismiss];
}

- (void)save
{
    if (![[HSUAppDelegate shared] buyProApp]) {
        return ;
    }
    
    if (!self.updated) {
        [self dismiss];
        return;
    }
    
    [SVProgressHUD showWithStatus:_("Updating...")];
    NSMutableDictionary *profile = [NSMutableDictionary dictionary];
    if (self.nameItem.value) {
        profile[@"name"] = self.nameItem.value;
    }
    if (self.locationItem.value) {
        profile[@"location"] = self.locationItem.value;
    }
    if (self.urlItem.value) {
        NSString *url = self.urlItem.value;
        if ([url hasPrefix:@"http://"] || [url hasPrefix:@"https://"]) {
            url = S(@"http://%@", url);
        }
        profile[@"url"] = url;
    }
    if (self.descItem.value) {
        profile[@"description"] = self.descItem.value;
    }
    __weak typeof(self) weakSelf = self;
    [twitter updateProfile:profile success:^(id responseObj) {
        [SVProgressHUD dismiss];
        [weakSelf dismiss];
        [weakSelf.profileVC reloadData];
    } failure:^(NSError *error) {
        [SVProgressHUD showErrorWithStatus:_("Update failed")];
    }];
}

- (NSString *)_websiteForProfile:(NSDictionary *)profile
{
    NSArray *urls = profile[@"entities"][@"url"][@"urls"];
    if (urls.count) {
        NSString *displayUrl = urls[0][@"display_url"];
        if (displayUrl.length) {
            return displayUrl;
        }
        return [[urls[0][@"url"]
                 stringByReplacingOccurrencesOfString:@"http://" withString:@""]
                stringByReplacingOccurrencesOfString:@"https://" withString:@""];
    }
    return nil;
}

@end
