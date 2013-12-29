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
#import "HSUSubscribedListsViewController.h"
#import "HSUSubscribedListsDataSource.h"

@interface HSUProfileViewController () <HSUProfileViewDelegate>

@property (nonatomic, strong) HSUProfileView *profileView;
@property (nonatomic, assign) BOOL isMeTab;

@end

@implementation HSUProfileViewController

- (id)init
{
    self = [self initWithScreenName:MyScreenName];
    if (self) {
        self.isMeTab = YES;
    }
    return self;
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
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    HSUProfileView *profileView = [[HSUProfileView alloc] initWithScreenName:self.screenName delegate:self];
    if (self.profile) {
        [profileView setupWithProfile:self.profile];
    }
    self.tableView.tableHeaderView = profileView;
    self.profileView = profileView;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [TWENGINE showUser:self.screenName success:^(id responseObj) {
        NSDictionary *profile = responseObj;
        [self.profileView setupWithProfile:profile];
        self.profile = profile;
        [[NSUserDefaults standardUserDefaults] setObject:self.profile forKey:kUserProfile_DBKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    } failure:^(NSError *error) {
        
    }];
    [self.tableView reloadData];
}

- (void)updateScreenName
{
    if (self.isMeTab) {
        self.screenName = MyScreenName;
        self.dataSource = [[HSUProfileDataSource alloc] initWithScreenName:self.screenName];
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
    HSUTableCellData *data = [self.dataSource dataAtIndexPath:indexPath];
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
    HSUUserHomeDataSource *dataSource = [[HSUUserHomeDataSource alloc] init];
    dataSource.screenName = self.screenName;
    HSUTweetsViewController *detailVC = [[HSUTweetsViewController alloc] initWithDataSource:dataSource];
    [self.navigationController pushViewController:detailVC animated:YES];
    [dataSource refresh];
}

- (void)followingsButtonTouched
{
    HSUPersonListDataSource *dataSource = [[HSUFollowingDataSource alloc] initWithScreenName:self.screenName];
    HSUPersonListViewController *detailVC = [[HSUPersonListViewController alloc] initWithDataSource:dataSource];
    [self.navigationController pushViewController:detailVC animated:YES];
}

- (void)followersButtonTouched
{
    HSUPersonListDataSource *dataSource = [[HSUFollowersDataSource alloc] initWithScreenName:self.screenName];
    HSUPersonListViewController *detailVC = [[HSUPersonListViewController alloc] initWithDataSource:dataSource];
    [self.navigationController pushViewController:detailVC animated:YES];
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
    HSUSubscribedListsDataSource *dataSource = [[HSUSubscribedListsDataSource alloc] initWithScreenName:self.screenName];
    HSUSubscribedListsViewController *listVC = [[HSUSubscribedListsViewController alloc] initWithDataSource:dataSource];
    [self.navigationController pushViewController:listVC animated:YES];
    [dataSource refresh];
}

- (void)draftsButtonTouched
{
    [[HSUDraftManager shared] presentDraftsViewController];
}

- (void)followButtonTouched:(UIButton *)followButton
{
    followButton.enabled = NO;
    if ([self.profile[@"blocked"] boolValue]) {
        RIButtonItem *cancelItem = [RIButtonItem itemWithLabel:_(@"Cancel")];
        RIButtonItem *unblockItem = [RIButtonItem itemWithLabel:_(@"Unblock")];
        unblockItem.action = ^{
            [TWENGINE unblockuser:self.screenName success:^(id responseObj) {
                NSMutableDictionary *profile = self.profile.mutableCopy;
                profile[@"blocked"] = @(NO);
                profile[@"following"] = @(NO);
                self.profile = profile;
                [self.profileView setupWithProfile:profile];
            } failure:^(NSError *error) {
                [TWENGINE dealWithError:error errTitle:_(@"Unblock failed")];
            }];
        };
        UIActionSheet *blockActionSheet = [[UIActionSheet alloc] initWithTitle:nil cancelButtonItem:cancelItem destructiveButtonItem:unblockItem otherButtonItems:nil, nil];
        [blockActionSheet showInView:[UIApplication sharedApplication].keyWindow];
    } else if ([self.profile[@"following"] boolValue]) {
        [TWENGINE unFollowUser:self.screenName success:^(id responseObj) {
            NSMutableDictionary *profile = self.profile.mutableCopy;
            profile[@"following"] = @(NO);
            self.profile = profile;
            [self.profileView setupWithProfile:profile];
            followButton.enabled = YES;
        } failure:^(NSError *error) {
            [TWENGINE dealWithError:error errTitle:_(@"Unfollow failed")];
            followButton.enabled = YES;
        }];
    } else {
        [TWENGINE followUser:self.screenName success:^(id responseObj) {
            NSMutableDictionary *profile = self.profile.mutableCopy;
            profile[@"following"] = @(YES);
            self.profile = profile;
            [self.profileView setupWithProfile:profile];
            followButton.enabled = YES;
        } failure:^(NSError *error) {
            [TWENGINE dealWithError:error errTitle:_(@"Follow failed")];
            followButton.enabled = YES;
        }];
    }
}

- (void)messagesButtonTouched
{
    HSUConversationsViewController *conversationsVC = [[HSUConversationsViewController alloc] init];
    UINavigationController *nav = [[HSUNavigationController alloc] initWithNavigationBarClass:[HSUNavigationBarLight class] toolbarClass:nil];
    nav.viewControllers = @[conversationsVC];
    [self.navigationController presentViewController:nav animated:YES completion:nil];
}

- (void)actionsButtonTouched
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil cancelButtonItem:nil destructiveButtonItem:nil otherButtonItems:nil];
    uint count = 0;
    
    /*
    if ([self.profile[@"following"] boolValue]) {
        if ([self.profile[@"notifications"] boolValue]) {
            RIButtonItem *turnOffNotiItem = [RIButtonItem itemWithLabel:_(@"Turn off notifications")];
            turnOffNotiItem.action = ^{
                
            };
            [actionSheet addButtonItem:turnOffNotiItem];
        } else {
            RIButtonItem *turnOnNotiItem = [RIButtonItem itemWithLabel:_(@"Turn on notifications")];
            turnOnNotiItem.action = ^{
                
            };
            [actionSheet addButtonItem:turnOnNotiItem];
        }
        count ++;
        
        if ([self.profile[@"retweets"] boolValue]) {
            RIButtonItem *turnOffRetweetsItem = [RIButtonItem itemWithLabel:_(@"Turn off Retweets")];
            turnOffRetweetsItem.action = ^{
                
            };
            [actionSheet addButtonItem:turnOffRetweetsItem];
        } else {
            RIButtonItem *turnOnRetweetsItem = [RIButtonItem itemWithLabel:_(@"Turn on Retweets")];
            turnOnRetweetsItem.action = ^{
                
            };
            [actionSheet addButtonItem:turnOnRetweetsItem];
        }
        count ++;
    }
    */
    
    RIButtonItem *reportSpamItem = [RIButtonItem itemWithLabel:_(@"Report Spam")];
    reportSpamItem.action = ^{
        [TWENGINE reportUserAsSpam:self.screenName success:^(id responseObj) {
            
        } failure:^(NSError *error) {
            [TWENGINE dealWithError:error errTitle:_(@"Report Spam failed")];
        }];
    };
    [actionSheet addButtonItem:reportSpamItem];
    count ++;
    
    if ([self.profile[@"blocked"] boolValue]) {
        RIButtonItem *unblockItem = [RIButtonItem itemWithLabel:_(@"Unblock")];
        unblockItem.action = ^{
            [TWENGINE unblockuser:self.screenName success:^(id responseObj) {
                NSMutableDictionary *profile = self.profile.mutableCopy;
                profile[@"blocked"] = @(NO);
                profile[@"following"] = @(NO);
                self.profile = profile;
                [self.profileView setupWithProfile:profile];
            } failure:^(NSError *error) {
                [TWENGINE dealWithError:error errTitle:_(@"Unblock failed")];
            }];
        };
        [actionSheet addButtonItem:unblockItem];
    } else {
        RIButtonItem *blockItem = [RIButtonItem itemWithLabel:_(@"Block")];
        blockItem.action = ^{
            [TWENGINE blockUser:self.screenName success:^(id responseObj) {
                NSMutableDictionary *profile = self.profile.mutableCopy;
                profile[@"blocked"] = @(YES);
                profile[@"following"] = @(NO);
                self.profile = profile;
                [self.profileView setupWithProfile:profile];
            } failure:^(NSError *error) {
                [TWENGINE dealWithError:error errTitle:_(@"Block failed")];
            }];
        };
        [actionSheet addButtonItem:blockItem];
    }
    [actionSheet setDestructiveButtonIndex:count];
    count ++;
    
    RIButtonItem *cancelItem = [RIButtonItem itemWithLabel:_(@"Cancel")];
    [actionSheet addButtonItem:cancelItem];
    [actionSheet setCancelButtonIndex:count];
    count ++;
    
    [actionSheet showInView:[UIApplication sharedApplication].keyWindow];
}

- (void)settingsButtonTouched
{
    RIButtonItem *cancelItem = [RIButtonItem itemWithLabel:_(@"Cancel")];
    RIButtonItem *proxySettingsItem = [RIButtonItem itemWithLabel:_(@"Proxy Settings")];
    RIButtonItem *helpItem = [RIButtonItem itemWithLabel:_(@"Help")];
    RIButtonItem *signOutItem = [RIButtonItem itemWithLabel:_(@"Sign Out")];
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                     cancelButtonItem:cancelItem
                                                destructiveButtonItem:nil
                                                     otherButtonItems:proxySettingsItem, helpItem, signOutItem, nil];
    [actionSheet showInView:self.view.window];
    proxySettingsItem.action = ^{
        HSUProxySettingsViewController *proxySettingsVC = [[HSUProxySettingsViewController alloc] init];
        UINavigationController *nav = [[HSUNavigationController alloc] initWithRootViewController:proxySettingsVC];
        [self presentViewController:nav animated:YES completion:nil];
    };
    helpItem.action = ^{
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://github.com/tuoxie007/Tweet4China2"]];
    };
    signOutItem.action = ^{
        RIButtonItem *doSignOutItem = [RIButtonItem itemWithLabel:_(@"Sign Out")];
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                         cancelButtonItem:cancelItem
                                                    destructiveButtonItem:doSignOutItem
                                                         otherButtonItems:nil];
        [actionSheet showInView:self.view.window];
        doSignOutItem.action = ^{
            [TWENGINE signOut];
        };
    };
}

- (void)_composeButtonTouched
{
    HSUComposeViewController *composeVC = [[HSUComposeViewController alloc] init];
    if (![self.screenName isEqualToString:[TWENGINE myScreenName]]) {
        composeVC.defaultText = [NSString stringWithFormat:@"@%@ ", self.screenName];
        composeVC.defaultSelectedRange = NSMakeRange(0, composeVC.defaultText.length);
    }
    UINavigationController *nav = [[HSUNavigationController alloc] initWithNavigationBarClass:[HSUNavigationBarLight class] toolbarClass:nil];
    nav.viewControllers = @[composeVC];
    [self presentViewController:nav animated:YES completion:nil];
}

@end
