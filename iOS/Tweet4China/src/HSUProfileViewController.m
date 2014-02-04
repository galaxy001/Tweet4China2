//
//  HSUProfileViewController.m
//  Tweet4China
//
//  Created by Jason Hsu on 2/28/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUProfileViewController.h"
#import "HSUProfileView.h"
#import "HSUProfileDataSource.h"
#import "HSUPersonListDataSource.h"
#import "HSUUserHomeDataSource.h"
#import "HSUTweetsViewController.h"
#import "HSUFollowersDataSource.h"
#import "HSUFollowingDataSource.h"
#import "HSUPersonListViewController.h"
#import "HSUComposeViewController.h"
#import "HSUNavigationBarLight.h"
#import "HSUConversationsViewController.h"
#import "HSUProxySettingsViewController.h"
#import "HSUFavoritesDataSource.h"
#import "HSUSubscribedListsDataSource.h"
#import <OpenCam/OpenCam.h>
#import "HSUEditProfileViewController.h"
#import "HSUTabController.h"
#import "HSUiPadTabController.h"
#import "HSUMessagesDataSource.h"
#import "HSUMessagesViewController.h"
#import "HSUSearchPersonDataSource.h"
#import "HSUSearchPersonViewController.h"
#import "HSUListsViewController.h"
#import "HSUPhotosViewController.h"
#import "HSURecentPhotosDataSource.h"
#import "HSUSelectListsViewController.h"
#import "T4CUserTimelineViewController.h"
#import "T4CFollowersViewController.h"
#import "T4CFollowingViewController.h"
#import "T4CPhotosViewController.h"
#import "T4CListsViewController.h"

@interface HSUProfileViewController () <HSUProfileViewDelegate, OCMCameraViewControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, strong) HSUProfileView *profileView;
@property (nonatomic) NSTimeInterval lastUpdateTime;
@property (nonatomic) BOOL presenting;
@property (nonatomic) BOOL selectPhotoForAvatar; // YES for avatar, NO for banner
@property (nonatomic, strong) UIBarButtonItem *addFriendBarButton;
@property (nonatomic, weak) UIImageView *addFriendButtonIndicator;
@property (nonatomic) BOOL relationshipLoaded;
@property (nonatomic) BOOL followedMe;

@end

@implementation HSUProfileViewController

- (id)init
{
    return [self initWithScreenName:MyScreenName];
}

- (id)initWithScreenName:(NSString *)screenName
{
    self = [super init];
    if (self) {
        self.screenName = screenName;
        self.useRefreshControl = NO;
        if (self.screenName) {
            self.dataSource = [[HSUProfileDataSource alloc] initWithScreenName:screenName];
        }
        notification_add_observer(HSUTwiterLoginSuccess, self, @selector(updateScreenName));
        notification_add_observer(HSUTabControllerDidSelectViewControllerNotification, self, @selector(tabDidSelected:));
    }
    return self;
}

- (void)viewDidLoad
{
    self.navigationItem.rightBarButtonItems = @[self.composeBarButton, self.searchBarButton];
    self.navigationItem.leftBarButtonItems = @[self.actionBarButton];
    
    [super viewDidLoad];
    
    HSUProfileView *profileView = [[HSUProfileView alloc]
                                   initWithScreenName:self.screenName
                                   width:self.tableView.width-kIPADMainViewPadding*2
                                   delegate:self];
    if (self.profile) {
        [profileView setupWithProfile:self.profile];
    }
    self.tableView.tableHeaderView = profileView;
    self.profileView = profileView;
    
    if ([self isMe]) {
        self.navigationItem.title = _("Me");
    } else if (self.profile) {
        self.navigationItem.title = self.profile[@"name"];
    } else {
        self.navigationItem.title = self.screenName;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.addFriendButtonIndicator.hidden = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (!self.presenting) {
        [self refreshDataIfNeed];
    }
    self.presenting = NO;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    self.addFriendButtonIndicator.hidden = YES;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    self.navigationItem.title = nil;
}

- (void)tabDidSelected:(NSNotification *)notification
{
    if (self.navigationController == notification.object) {
        if (self.view.window) {
            if (self.tableView.contentOffset.y <= 0) {
                [self refreshData];
            }
            if (Sys_Ver >= 7) {
                [self.tableView setContentOffset:ccp(0, -120)];
            }
        }
    }
}

- (void)refreshDataIfNeed
{
    [((HSUProfileDataSource *)self.dataSource) refreshLocalData];
    
    __weak typeof(self) weakSelf = self;
    
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    if (now - self.lastUpdateTime > 60) {
        self.lastUpdateTime = now;
        self.navigationItem.title = self.profile ? _("Updating...") : _("Loading...");
        [twitter showUser:self.screenName success:^(id responseObj) {
            weakSelf.navigationItem.title = nil;
            [weakSelf updateProfile:responseObj];
        } failure:^(NSError *error) {
            weakSelf.navigationItem.title = _("Error Occurred");
            weakSelf.lastUpdateTime = 0;
        }];
    }
    
    if (!self.isMe && !self.relationshipLoaded) {
        [twitter lookupFriendshipsWithScreenNames:@[self.screenName] success:^(id responseObj) {
            weakSelf.relationshipLoaded = YES;
            NSDictionary *ship = responseObj[0];
            NSArray *connections = ship[@"connections"];
            BOOL followedMe = NO;
            if ([connections isKindOfClass:[NSArray class]]) {
                for (NSString *connection in connections) {
                    if ([connection isEqualToString:@"followed_by"]) {
                        followedMe = YES;
                        break;
                    }
                }
            }
            if (followedMe) {
                [weakSelf.profileView showFollowed];
            }
        } failure:^(NSError *error) {
            
        }];
    }
    
    [self.tableView reloadData];
}

- (void)updateProfile:(NSDictionary *)profile
{
    [self.profileView setupWithProfile:profile];
    self.profile = profile;
    
    if (self.isMe) {
        NSMutableDictionary *profiles = [[[NSUserDefaults standardUserDefaults] objectForKey:HSUUserProfiles] mutableCopy] ?: [NSMutableDictionary dictionary];
        profiles[twitter.myScreenName] = profile;
        [[NSUserDefaults standardUserDefaults] setObject:profiles forKey:HSUUserProfiles];
        [[NSUserDefaults standardUserDefaults] synchronize];
    } else {
        self.navigationItem.title = profile[@"name"];
    }
}

- (void)updateScreenName
{
    if (self.isMe) {
        self.screenName = MyScreenName;
        self.dataSource = [[HSUProfileDataSource alloc] initWithScreenName:self.screenName];
        self.tableView.dataSource = self.dataSource;
        [self refreshData];
    }
}

- (NSString *)screenName
{
    if (_screenName) {
        return _screenName;
    }
    self.screenName = MyScreenName;
    return _screenName;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    T4CTableCellData *data = [self.dataSource dataAtIndexPath:indexPath];
    NSDictionary *rawData = data.rawData;
    if ([data.dataType isEqualToString:kDataType_NormalTitle]) {
        if ([rawData[@"action"] isEqualToString:kAction_UserTimeline]) {
            [self tweetsButtonTouched];
            return;
        } else if ([rawData[@"action"] isEqualToString:kAction_Following]) {
            [self followingsButtonTouched];
            return;
        } else if ([rawData[@"action"] isEqualToString:kAction_Followers]) {
            [self followersButtonTouched];
            return;
        } else if ([rawData[@"action"] isEqualToString:kAction_Favorites]) {
            [self favoritesButtonTouched];
            return;
        } else if ([rawData[@"action"] isEqualToString:kAction_Lists]) {
            [self listsButtonTouched];
            return;
        } else if ([rawData[@"action"] isEqualToString:kAction_Photos]) {
            if (![[HSUAppDelegate shared] buyProApp]) {
                return;
            }
            
            [self photosButtonTouched];
            return;
        }
    } else if ([data.dataType isEqualToString:kDataType_Drafts]) {
        if ([rawData[@"action"] isEqualToString:kAction_Drafts]) {
            [self draftsButtonTouched];
        }
    }
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
}

- (void)tweetsButtonTouched
{
    T4CUserTimelineViewController *tweetsVC = [[T4CUserTimelineViewController alloc] init];
    tweetsVC.screenName = self.screenName;
    [self.navigationController pushViewController:tweetsVC animated:YES];
}

- (void)followingsButtonTouched
{
    T4CFollowingViewController *followersVC = [[T4CFollowingViewController alloc] init];
    followersVC.screenName = self.screenName;
    [self.navigationController pushViewController:followersVC animated:YES];
}

- (void)followersButtonTouched
{
    T4CFollowersViewController *followersVC = [[T4CFollowersViewController alloc] init];
    followersVC.screenName = self.screenName;
    [self.navigationController pushViewController:followersVC animated:YES];
}

- (void)favoritesButtonTouched
{
    HSUTweetsDataSource *dataSource = [[HSUFavoritesDataSource alloc] initWithScreenName:self.screenName];
    HSUTweetsViewController *detailVC = [[HSUTweetsViewController alloc] initWithDataSource:dataSource];
    [self.navigationController pushViewController:detailVC animated:YES];
    [dataSource refresh];
}

- (void)listsButtonTouched
{
    T4CListsViewController *listsVC = [[T4CListsViewController alloc] init];
    listsVC.screenName = self.screenName;
    [self.navigationController pushViewController:listsVC animated:YES];
}

- (void)draftsButtonTouched
{
    [[HSUDraftManager shared] presentDraftsViewController];
}

- (void)photosButtonTouched
{
    T4CPhotosViewController *photosVC = [[T4CPhotosViewController alloc] init];
    photosVC.screenName = self.screenName;
    [self.navigationController pushViewController:photosVC animated:YES];
}

- (void)followButtonTouched:(UIButton *)followButton
{
    followButton.enabled = NO;
    if ([self.profile[@"blocked"] boolValue]) {
        RIButtonItem *cancelItem = [RIButtonItem itemWithLabel:_("Cancel")];
        RIButtonItem *unblockItem = [RIButtonItem itemWithLabel:_("Unblock")];
        __weak typeof(self)weakSelf = self;
        unblockItem.action = ^{
            [twitter unblockuser:self.screenName success:^(id responseObj) {
                NSMutableDictionary *profile = weakSelf.profile.mutableCopy;
                profile[@"blocked"] = @(NO);
                profile[@"following"] = @(NO);
                weakSelf.profile = profile;
                [weakSelf.profileView setupWithProfile:profile];
            } failure:^(NSError *error) {
                [twitter dealWithError:error errTitle:_("Unblock failed")];
            }];
        };
        UIActionSheet *blockActionSheet = [[UIActionSheet alloc] initWithTitle:nil cancelButtonItem:cancelItem destructiveButtonItem:unblockItem otherButtonItems:nil, nil];
        [blockActionSheet showInView:[UIApplication sharedApplication].keyWindow];
    } else if ([self.profile[@"following"] boolValue]) {
        __weak typeof(self)weakSelf = self;
        [twitter unFollowUser:self.screenName success:^(id responseObj) {
            NSMutableDictionary *profile = weakSelf.profile.mutableCopy;
            profile[@"following"] = @(NO);
            weakSelf.profile = profile;
            [weakSelf.profileView setupWithProfile:profile];
            followButton.enabled = YES;
        } failure:^(NSError *error) {
            [twitter dealWithError:error errTitle:_("Unfollow failed")];
            followButton.enabled = YES;
        }];
    } else {
        __weak typeof(self)weakSelf = self;
        [twitter followUser:self.screenName success:^(id responseObj) {
            NSMutableDictionary *profile = weakSelf.profile.mutableCopy;
            profile[@"following"] = @(YES);
            weakSelf.profile = profile;
            [weakSelf.profileView setupWithProfile:profile];
            followButton.enabled = YES;
        } failure:^(NSError *error) {
            [twitter dealWithError:error errTitle:_("Follow failed")];
            followButton.enabled = YES;
        }];
    }
}

- (void)messagesButtonTouched
{
    if (self.isMe) {
        HSUConversationsViewController *conversationsVC = [[HSUConversationsViewController alloc] init];
        UINavigationController *nav = [[HSUNavigationController alloc] initWithNavigationBarClass:[HSUNavigationBarLight class] toolbarClass:nil];
        nav.viewControllers = @[conversationsVC];
        [self.navigationController presentViewController:nav animated:YES completion:nil];
        [self.profileView hideDMIndicator];
    } else {
        if (![[HSUAppDelegate shared] buyProApp]) {
            return;
        }
        
        __weak typeof(self)weakSelf = self;
        if (self.relationshipLoaded) {
            if (self.followedMe) {
                [self startDirectMessage];
            } else {
                NSString *message = [NSString stringWithFormat:@"%@ @%@, @%@ %@", _("You can not send direct message to"), self.screenName, self.screenName, _("is not following you.")];
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:message delegate:nil cancelButtonTitle:_("OK") otherButtonTitles:nil, nil];
                [alert show];
            }
        } else {
            [SVProgressHUD showWithStatus:_("Please Wait")];
            NSString *screenName = self.screenName;
            [twitter lookupFriendshipsWithScreenNames:@[screenName] success:^(id responseObj) {
                NSDictionary *ship = responseObj[0];
                NSArray *connections = ship[@"connections"];
                BOOL followedMe = NO;
                if ([connections isKindOfClass:[NSArray class]]) {
                    for (NSString *connection in connections) {
                        if ([connection isEqualToString:@"followed_by"]) {
                            followedMe = YES;
                            break;
                        }
                    }
                }
                if (followedMe) {
                    [weakSelf startDirectMessage];
                } else {
                    [SVProgressHUD dismiss];
                    NSString *message = [NSString stringWithFormat:@"%@ @%@, @%@ %@", _("You can not send direct message to"), screenName, screenName, _("is not following you.")];
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:message delegate:nil cancelButtonTitle:_("OK") otherButtonTitles:nil, nil];
                    [alert show];
                }
            } failure:^(NSError *error) {
                [SVProgressHUD dismiss];
            }];
        }
    }
}

- (void)startDirectMessage
{
    __weak typeof(self)weakSelf = self;
    HSUMessagesDataSource *dataSource = [[HSUMessagesDataSource alloc] initWithConversation:nil];
    __block HSUMessagesViewController *messagesVC = [[HSUMessagesViewController alloc] initWithDataSource:dataSource];
    HSUNavigationController *nav = [[HSUNavigationController alloc] initWithRootViewController:messagesVC];
    messagesVC.herProfile = self.profile;
    messagesVC.myProfile = nil;
    NSDictionary *userProfiles = [[NSUserDefaults standardUserDefaults] valueForKey:HSUUserProfiles];
    if (userProfiles[MyScreenName]) {
        messagesVC.myProfile = userProfiles[MyScreenName];
        [SVProgressHUD dismiss];
        [self presentViewController:nav animated:YES completion:nil];
    } else {
        [twitter showUser:MyScreenName success:^(id responseObj) {
            [SVProgressHUD dismiss];
            messagesVC.myProfile = responseObj;
            [weakSelf presentViewController:nav animated:YES completion:nil];
        } failure:^(NSError *error) {
            [SVProgressHUD dismiss];
        }];
    }
}

- (void)actionsButtonTouched
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil cancelButtonItem:nil destructiveButtonItem:nil otherButtonItems:nil];
    uint count = 0;
    
    RIButtonItem *reportSpamItem = [RIButtonItem itemWithLabel:_("Report Spam")];
    reportSpamItem.action = ^{
        [twitter reportUserAsSpam:self.screenName success:^(id responseObj) {
            
        } failure:^(NSError *error) {
            [twitter dealWithError:error errTitle:_("Report Spam failed")];
        }];
    };
    [actionSheet addButtonItem:reportSpamItem];
    count ++;
    
    if ([self.profile[@"blocked"] boolValue]) {
        RIButtonItem *unblockItem = [RIButtonItem itemWithLabel:_("Unblock")];
        __weak typeof(self)weakSelf = self;
        unblockItem.action = ^{
            [twitter unblockuser:self.screenName success:^(id responseObj) {
                NSMutableDictionary *profile = self.profile.mutableCopy;
                profile[@"blocked"] = @(NO);
                profile[@"following"] = @(NO);
                weakSelf.profile = profile;
                [weakSelf.profileView setupWithProfile:profile];
            } failure:^(NSError *error) {
                [twitter dealWithError:error errTitle:_("Unblock failed")];
            }];
        };
        [actionSheet addButtonItem:unblockItem];
    } else {
        RIButtonItem *blockItem = [RIButtonItem itemWithLabel:_("Block")];
        __weak typeof(self)weakSelf = self;
        blockItem.action = ^{
            [twitter blockUser:self.screenName success:^(id responseObj) {
                NSMutableDictionary *profile = weakSelf.profile.mutableCopy;
                profile[@"blocked"] = @(YES);
                profile[@"following"] = @(NO);
                weakSelf.profile = profile;
                [weakSelf.profileView setupWithProfile:profile];
            } failure:^(NSError *error) {
                [twitter dealWithError:error errTitle:_("Block failed")];
            }];
        };
        [actionSheet addButtonItem:blockItem];
    }
    [actionSheet setDestructiveButtonIndex:count];
    count ++;
    
    RIButtonItem *cancelItem = [RIButtonItem itemWithLabel:_("Cancel")];
    [actionSheet addButtonItem:cancelItem];
    [actionSheet setCancelButtonIndex:count];
    count ++;
    
    [actionSheet showInView:[UIApplication sharedApplication].keyWindow];
}

- (void)settingsButtonTouched
{
    if (self.profile) {
        if ((self.profile[@"profile_image_url_https"] == nil || self.profileView.avatarImage) &&
            (self.profile[@"profile_banner_url"] == nil || self.profileView.bannerImage)) {
            
            HSUEditProfileViewController *editProfileVC = [[HSUEditProfileViewController alloc] init];
            editProfileVC.profile = self.profile;
            editProfileVC.avatarImage = self.profileView.avatarImage;
            editProfileVC.bannerImage = self.profileView.bannerImage;
            editProfileVC.profileVC = self;
            HSUNavigationController *nav = [[HSUNavigationController alloc] initWithRootViewController:editProfileVC];
            [self presentViewController:nav animated:YES completion:nil];
            self.presenting = YES;
        }
    }
}

- (void)selectPhotoForAvatar:(BOOL)forAvatar
{
    OCMCameraViewController *cameraVC = [OpenCam cameraViewController];
    if (forAvatar) {
        cameraVC.maxWidth = 640;
    } else {
        cameraVC.maxWidth = 1280;
    }
    cameraVC.delegate = self;
    [self presentViewController:cameraVC animated:YES completion:nil];
    self.selectPhotoForAvatar = forAvatar;
}

- (void)avatarButtonTouched
{
    if (self.isMe) {
        if (![[HSUAppDelegate shared] buyProApp]) {
            return ;
        }
        [self selectPhotoForAvatar:YES];
    } else {
        NSString *url = self.profile[@"profile_image_url_https"];
        if (url) {
            url = [url stringByReplacingOccurrencesOfString:@"_normal" withString:@""];
            [self openPhotoURL:[NSURL URLWithString:url] withCellData:nil];
        }
    }
}

- (void)bannerButtonTouched
{
    if (self.isMe) {
        if (![[HSUAppDelegate shared] buyProApp]) {
            return ;
        }
        [self selectPhotoForAvatar:NO];
    }
}

- (void)_composeButtonTouched
{
    HSUComposeViewController *composeVC = [[HSUComposeViewController alloc] init];
    if (![self.screenName isEqualToString:[twitter myScreenName]]) {
        composeVC.defaultText = [NSString stringWithFormat:@"@%@ ", self.screenName];
        composeVC.defaultSelectedRange = NSMakeRange(0, composeVC.defaultText.length);
    }
    UINavigationController *nav = [[HSUNavigationController alloc] initWithNavigationBarClass:[HSUNavigationBarLight class] toolbarClass:nil];
    nav.viewControllers = @[composeVC];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)cameraViewControllerDidFinish:(OCMCameraViewController *)cameraViewController
{
    UIImage *image = cameraViewController.photo;
    if (image) {
        __weak typeof(self) weakSelf = self;
        [SVProgressHUD showWithStatus:_("Uploading...")];
        // get center square
        if (image.size.width > image.size.height) {
            image = [image subImageAtRect:ccr(image.size.width/2-image.size.height/2, 0, image.size.height, image.size.height)];
        } else if (image.size.width < image.size.height) {
            image = [image subImageAtRect:ccr(0, image.size.height/2-image.size.width/2, image.size.width, image.size.width)];
        }
        if (self.selectPhotoForAvatar) {
            [twitter updateAvatar:image success:^(id responseObj) {
                [weakSelf refreshData];
                [SVProgressHUD dismiss];
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
                [weakSelf refreshData];
                [SVProgressHUD dismiss];
            } failure:^(NSError *error) {
                [SVProgressHUD showErrorWithStatus:_("Upload failed")];
            }];
        }
        self.selectPhotoForAvatar = NO;
    }
}

- (void)refreshData
{
    self.lastUpdateTime = 0;
    [self refreshDataIfNeed];
}

- (BOOL)isMe
{
    return [self.profile[@"screen_name"] isEqualToString:MyScreenName] || self.navigationController.viewControllers.count == 1;
}

- (UIBarButtonItem *)addFriendBarButton
{
    if (!_addFriendBarButton) {
        if (Sys_Ver >= 7) {
            _addFriendBarButton = [[UIBarButtonItem alloc]
                                   initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                   target:self
                                   action:@selector(_addButtonTouched)];
        } else {
            UIButton *addFriendButton = [[UIButton alloc] init];
            [addFriendButton addTarget:self action:@selector(_addButtonTouched) forControlEvents:UIControlEventTouchUpInside];
            [addFriendButton setImage:[UIImage imageNamed:@"icn_nav_bar_people_1"] forState:UIControlStateNormal];
            [addFriendButton sizeToFit];
            addFriendButton.width *= 1.4;
            _addFriendBarButton = [[UIBarButtonItem alloc] initWithCustomView:addFriendButton];
        }
        
        if (![[[NSUserDefaults standardUserDefaults] objectForKey:HSUAddFriendBarTouched] boolValue]) {
            UIImage *indicatorImage = [UIImage imageNamed:@"unread_indicator"];
            UIImageView *indicator = [[UIImageView alloc] initWithImage:indicatorImage];
            [self.navigationController.navigationBar addSubview:indicator];
            _addFriendButtonIndicator = indicator;
            indicator.leftTop = ccp(self.navigationController.navigationBar.width-23, 0);
        }
    }
    return _addFriendBarButton;
}

- (void)_addButtonTouched
{
    if (![twitter isAuthorized] || [SVProgressHUD isVisible]) {
        return;
    }
    
    HSUSearchPersonDataSource *dataSource = [[HSUSearchPersonDataSource alloc] init];
    HSUSearchPersonViewController *addFriendVC = [[HSUSearchPersonViewController alloc] initWithDataSource:dataSource];
    [self.navigationController pushViewController:addFriendVC animated:YES];
    
    if (![[[NSUserDefaults standardUserDefaults] objectForKey:HSUAddFriendBarTouched] boolValue]) {
        [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:HSUAddFriendBarTouched];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [_addFriendButtonIndicator removeFromSuperview];
    }
}

- (void)listButtonTouched
{
    [SVProgressHUD showWithStatus:nil];
    [twitter getListsWithScreenName:MyScreenName success:^(id responseObj) {
        NSArray *mySubLists = responseObj;
        NSMutableArray *myLists = [NSMutableArray array];
        for (NSDictionary *mySubList in mySubLists) {
            if ([mySubList[@"user"][@"screen_name"] isEqualToString:MyScreenName]) {
                [myLists addObject:mySubList];
            }
        }
        [twitter getMyListsListedUser:self.screenName success:^(id responseObj) {
            [SVProgressHUD dismiss];
            NSDictionary *dict = responseObj;
            NSArray *listedLists = dict[@"lists"];
            HSUSelectListsViewController *selectListsVC = [[HSUSelectListsViewController alloc] initWithMyLists:myLists listedLists:listedLists user:self.screenName];
            HSUNavigationController *nav = [[HSUNavigationController alloc] initWithRootViewController:selectListsVC];
            [self presentViewController:nav animated:YES completion:nil];
        } failure:^(NSError *error) {
            [SVProgressHUD showErrorWithStatus:_("Load lists failed")];
        }];
    } failure:^(NSError *error) {
        [SVProgressHUD showErrorWithStatus:_("Load lists failed")];
    }];
}

@end
