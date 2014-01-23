//
//  HSUTwitterAPI.m
//  Tweet4China
//
//  Created by Jason Hsu on 13/7/22.
//  Copyright (c) 2013年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUTwitterAPI.h"
#import <FHSTwitterEngine/FHSTwitterEngine.h>
#import <FHSTwitterEngine/OAToken.h>
#import <FHSTwitterEngine/OARequestParameter.h>
#import <FHSTwitterEngine/OAMutableURLRequest.h>
#import "HSUProxySettingsViewController.h"
#import "HSUShadowsocksViewController.h"
#import <Reachability/Reachability.h>
#import <AFNetworking/AFNetworkActivityIndicatorManager.h>
#import "HSUAccountsViewController.h"

#define API_URL ([url substringFromIndex:28])

@interface FHSTwitterEngine (Private)

@property (retain, nonatomic) OAConsumer *consumer;

@end

static NSString * const url_search_tweets = @"https://api.twitter.com/1.1/search/tweets.json";

static NSString * const url_users_search = @"https://api.twitter.com/1.1/users/search.json";
static NSString * const url_users_show = @"https://api.twitter.com/1.1/users/show.json";
static NSString * const url_users_report_spam = @"https://api.twitter.com/1.1/users/report_spam.json";
static NSString * const url_users_lookup = @"https://api.twitter.com/1.1/users/lookup.json";

static NSString * const url_lists_create = @"https://api.twitter.com/1.1/lists/create.json";
static NSString * const url_lists_show = @"https://api.twitter.com/1.1/lists/show.json";
static NSString * const url_lists_update = @"https://api.twitter.com/1.1/lists/update.json";
static NSString * const url_lists_members = @"https://api.twitter.com/1.1/lists/members.json";
static NSString * const url_lists_members_destroy_all = @"https://api.twitter.com/1.1/lists/members/destroy_all.json";
static NSString * const url_lists_members_create_all = @"https://api.twitter.com/1.1/lists/members/create_all.json";
static NSString * const url_lists_statuses = @"https://api.twitter.com/1.1/lists/statuses.json";
static NSString * const url_lists_list = @"https://api.twitter.com/1.1/lists/list.json";
static NSString * const url_lists_destroy = @"https://api.twitter.com/1.1/lists/destroy.json";
static NSString * const url_lists_subscriptions = @"https://api.twitter.com/1.1/lists/subscriptions.json";
static NSString * const url_lists_subscribers_create = @"https://api.twitter.com/1.1/lists/subscribers/create.json";
static NSString * const url_lists_subscribers_destroy = @"https://api.twitter.com/1.1/lists/subscribers/destroy.json";
static NSString * const url_lists_subscribers = @"https://api.twitter.com/1.1/lists/subscribers.json";
static NSString * const url_lists_memberships = @"https://api.twitter.com/1.1/lists/memberships.json";
static NSString * const url_lists_members_create = @"https://api.twitter.com/1.1/lists/members/create.json";
static NSString * const url_lists_members_destroy = @"https://api.twitter.com/1.1/lists/members/destroy.json";

static NSString * const url_statuses_home_timeline = @"https://api.twitter.com/1.1/statuses/home_timeline.json";
static NSString * const url_statuses_update = @"https://api.twitter.com/1.1/statuses/update.json";
static NSString * const url_statuses_retweets_of_me = @"https://api.twitter.com/1.1/statuses/retweets_of_me.json";
static NSString * const url_statuses_user_timeline = @"https://api.twitter.com/1.1/statuses/user_timeline.json";
static NSString * const url_statuses_metions_timeline = @"https://api.twitter.com/1.1/statuses/mentions_timeline.json";
static NSString * const url_statuses_update_with_media = @"https://api.twitter.com/1.1/statuses/update_with_media.json";
static NSString * const url_statuses_destroy = @"https://api.twitter.com/1.1/statuses/destroy/%@.json";
static NSString * const url_statuses_show = @"https://api.twitter.com/1.1/statuses/show.json";
static NSString * const url_statuses_oembed = @"https://api.twitter.com/1.1/statuses/oembed.json";
static NSString * const url_statuses_retweet = @"https://api.twitter.com/1.1/statuses/retweet/%@.json";
static NSString * const url_statuses_retweets = @"https://api.twitter.com/1.1/statuses/retweets/%@.json";

static NSString * const url_blocks_exists = @"https://api.twitter.com/1.1/blocks/exists.json";
static NSString * const url_blocks_blocking = @"https://api.twitter.com/1.1/blocks/blocking.json";
static NSString * const url_blocks_blocking_ids = @"https://api.twitter.com/1.1/blocks/blocking/ids.json";
static NSString * const url_blocks_destroy = @"https://api.twitter.com/1.1/blocks/destroy.json";
static NSString * const url_blocks_create = @"https://api.twitter.com/1.1/blocks/create.json";

static NSString * const url_help_languages = @"https://api.twitter.com/1.1/help/languages.json";
static NSString * const url_help_configuration = @"https://api.twitter.com/1.1/help/configuration.json";
static NSString * const url_help_privacy = @"https://api.twitter.com/1.1/help/privacy.json";
static NSString * const url_help_tos = @"https://api.twitter.com/1.1/help/tos.json";
static NSString * const url_help_test = @"https://api.twitter.com/1.1/help/test.json";

static NSString * const url_direct_messages_show = @"https://api.twitter.com/1.1/direct_messages/show.json";
static NSString * const url_direct_messages_new = @"https://api.twitter.com/1.1/direct_messages/new.json";
static NSString * const url_direct_messages_sent = @"https://api.twitter.com/1.1/direct_messages/sent.json";
static NSString * const url_direct_messages_destroy = @"https://api.twitter.com/1.1/direct_messages/destroy.json";
static NSString * const url_direct_messages = @"https://api.twitter.com/1.1/direct_messages.json";

static NSString * const url_friendships_no_retweets_ids = @"https://api.twitter.com/1.1/friendships/no_retweets/ids.json";
static NSString * const url_friendships_update = @"https://api.twitter.com/1.1/friendships/update.json";
static NSString * const url_friendships_outgoing = @"https://api.twitter.com/1.1/friendships/outgoing.json";
static NSString * const url_friendships_incoming = @"https://api.twitter.com/1.1/friendships/incoming.json";
static NSString * const url_friendships_lookup = @"https://api.twitter.com/1.1/friendships/lookup.json";
static NSString * const url_friendships_destroy = @"https://api.twitter.com/1.1/friendships/destroy.json";
static NSString * const url_friendships_create = @"https://api.twitter.com/1.1/friendships/create.json";

static NSString * const url_account_verify_credentials = @"https://api.twitter.com/1.1/account/verify_credentials.json";
static NSString * const url_account_update_profile_colors = @"https://api.twitter.com/1.1/account/update_profile_colors.json";
static NSString * const url_account_update_profile_background_image = @"https://api.twitter.com/1.1/account/update_profile_background_image.json";
static NSString * const url_account_update_profile_image = @"https://api.twitter.com/1.1/account/update_profile_image.json";
static NSString * const url_account_settings = @"https://api.twitter.com/1.1/account/settings.json";
static NSString * const url_account_update_profile = @"https://api.twitter.com/1.1/account/update_profile.json";

static NSString * const url_favorites_list = @"https://api.twitter.com/1.1/favorites/list.json";
static NSString * const url_favorites_create = @"https://api.twitter.com/1.1/favorites/create.json";
static NSString * const url_favorites_destroy = @"https://api.twitter.com/1.1/favorites/destroy.json";

static NSString * const url_application_rate_limit_status = @"https://api.twitter.com/1.1/application/rate_limit_status.json";

static NSString * const url_followers_ids = @"https://api.twitter.com/1.1/followers/ids.json";

static NSString * const url_friends_ids = @"https://api.twitter.com/1.1/friends/ids.json";

static NSString * const url_trends_place = @"https://api.twitter.com/1.1/trends/place.json";

static NSString * const url_reverse_geocode = @"https://api.twitter.com/1.1/geo/reverse_geocode.json";

@interface HSUTwitterAPI () <FHSTwitterEngineAccessTokenDelegate>

@property (nonatomic, assign, getter = isAuthorizing) BOOL authorizing;
@property (nonatomic, copy) NSString *accessToken;

@end

@implementation HSUTwitterAPI

- (id)init
{
#ifndef kTwitterAppKey
    #error "Define your kTwitterAppKey in HSUDefinitions.h before compile"
#endif
#ifndef kTwitterAppSecret
    #error "Define your kTwitterAppSecret in HSUDefinitions.h before compile"
#endif
    self = [super init];
    if (self) {
        FHSTwitterEngine *engine = self.engine;
        [engine permanentlySetConsumerKey:kTwitterAppKey andSecret:kTwitterAppSecret];
        [engine loadAccessToken];
        if (!self.isAuthorized) {
            [self authorize];
        }
    }
    return self;
}

+ (instancetype)shared
{
    static HSUTwitterAPI *api = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        api = [[HSUTwitterAPI alloc] init];
    });
    return api;
}

- (void)storeAccessToken:(NSString *)accessToken
{
    if (accessToken.length) { // add
        self.accessToken = accessToken;
    } else if ([accessToken isEqualToString:@""]) { // remove
        [self removeAccount:self.myScreenName];
    }
}

- (NSString *)loadAccessToken
{
    return [self mySettings][@"access_token"];
}

- (void)removeAccount:(NSString *)screenName
{
    NSMutableDictionary *userSettings = [[[NSUserDefaults standardUserDefaults] objectForKey:HSUUserSettings] mutableCopy];
    [userSettings removeObjectForKey:self.myScreenName];
    [[NSUserDefaults standardUserDefaults] setObject:userSettings forKey:HSUUserSettings];
    if ([screenName isEqualToString:self.myScreenName]) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:HSUCurrentScreenName];
        [[NSNotificationCenter defaultCenter] postNotificationName:HSUTwiterLogout object:nil];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)loadAccount:(NSString *)screenName
{
    [[NSUserDefaults standardUserDefaults] setObject:screenName forKey:HSUCurrentScreenName];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self.engine loadAccessToken];
    notification_post_with_objct_and_userinfo(HSUTwiterLoginSuccess, self, @{@"success": @YES});
}

- (BOOL)isAuthorized
{
    return self.engine.isAuthorized;
}

- (FHSTwitterEngine *)engine
{
    FHSTwitterEngine *engine = [FHSTwitterEngine sharedEngine];
    engine.delegate = self;
    return engine;
}

- (void)authorize
{
    if (shadowsocksStarted) {
        if (self.authorizing) {
            return;
        }
        self.authorizing = YES;
        
        NSMutableDictionary *userSettings = [[[NSUserDefaults standardUserDefaults] objectForKey:HSUUserSettings] mutableCopy];
        if (userSettings.count) {
            [UIApplication sharedApplication].keyWindow.userInteractionEnabled = NO;
            double delayInSeconds = 1.0;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [UIApplication sharedApplication].keyWindow.userInteractionEnabled = YES;
                HSUAccountsViewController *accountsVC = [[HSUAccountsViewController alloc] init];
                HSUNavigationController *nav = [[HSUNavigationController alloc] initWithRootViewController:accountsVC];
                [[HSUAppDelegate shared].tabController presentViewController:nav animated:YES completion:nil];
                return;
            });
        }
        
        [UIApplication sharedApplication].keyWindow.userInteractionEnabled = NO;
        double delayInSeconds = 1.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [UIApplication sharedApplication].keyWindow.userInteractionEnabled = YES;
            [twitter authorizeByOAuth];
        });
    } else {
        [[HSUAppDelegate shared] startShadowsocks];
    }
}

- (void)authorizeByOAuth
{
    FHSTwitterEngine *engine = self.engine;
    UIViewController *viewController = [HSUAppDelegate shared].window.rootViewController.presentedViewController ?: [HSUAppDelegate shared].window.rootViewController;
    [engine showOAuthLoginControllerFromViewController:viewController
                                        withCompletion:^(int success)
     {
         if (success == YES) {
             [HSUTwitterAPI shared].authorizing = NO;
             [[HSUTwitterAPI shared] syncGetUserSettingsWithSuccess:^(id responseObj) {
                 NSMutableDictionary *userSettings = [[[NSUserDefaults standardUserDefaults] objectForKey:HSUUserSettings] mutableCopy] ?: [NSMutableDictionary dictionary];
                 NSMutableDictionary *us = [responseObj mutableCopy];
                 us[@"access_token"] = twitter.accessToken;
                 userSettings[us[@"screen_name"]] = us;
                 [[NSUserDefaults standardUserDefaults] setObject:us[@"screen_name"] forKey:HSUCurrentScreenName];
                 [[NSUserDefaults standardUserDefaults] setObject:userSettings forKey:HSUUserSettings];
                 [[NSUserDefaults standardUserDefaults] synchronize];
                 notification_post_with_objct_and_userinfo(HSUTwiterLoginSuccess, self, @{@"success": @YES});
                 [Flurry logEvent:@"authorize_by_oauth_success" withParameters:@{@"network": NetWorkStatus}];
             } failure:^(NSError *error) {
                 [[HSUTwitterAPI shared] dealWithError:error errTitle:_("Fetch account info failed")];
                 notification_post_with_objct_and_userinfo(HSUTwiterLoginSuccess, self, @{@"success": @NO, @"error": error});
                 [Flurry logEvent:@"authorize_by_oauth_failed" withParameters:@{@"network": NetWorkStatus}];
             }];
         } else if (success == NO) {
             if ([Reachability reachabilityForInternetConnection].isReachable) {
                 RIButtonItem *cancelItem = [RIButtonItem itemWithLabel:_("Retry Later")];
                 RIButtonItem *changeServerItem = [RIButtonItem itemWithLabel:_("Change Server")];
                 UIAlertView *alert = [[UIAlertView alloc] initWithTitle:_("Connection failed")
                                                                 message:_("api_request_failed_alert_message")
                                                        cancelButtonItem:cancelItem
                                                        otherButtonItems:changeServerItem, nil];
                 changeServerItem.action = ^{
                     HSUShadowsocksViewController *ssVC = [[HSUShadowsocksViewController alloc] init];
                     HSUNavigationController *nav = [[HSUNavigationController alloc] initWithRootViewController:ssVC];
                     UIViewController *rootVC = [HSUAppDelegate shared].tabController;
                     if (rootVC.presentedViewController) {
                         rootVC = rootVC.presentedViewController;
                     }
                     [rootVC presentViewController:nav animated:YES completion:^{
                         [HSUTwitterAPI shared].authorizing = NO;
                     }];
                 };
                 cancelItem.action = ^{
                     [HSUTwitterAPI shared].authorizing = NO;
                 };
                 [alert show];
             } else {
                 [HSUTwitterAPI shared].authorizing = NO;
                 [SVProgressHUD showErrorWithStatus:_("Check your network")];
             }
         } else {
             [HSUTwitterAPI shared].authorizing = NO;
         }
     }];
}

- (NSString *)myScreenName
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:HSUCurrentScreenName];
}

- (NSDictionary *)mySettings
{
    NSDictionary *userSettings = [[NSUserDefaults standardUserDefaults] objectForKey:HSUUserSettings];
    return userSettings[self.myScreenName];
}

- (void)getUserSettingsWithSuccess:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    [self sendWithUrl:url_account_settings
               method:@"GET"
           parameters:nil
              success:success
              failure:failure];
}
- (void)syncGetUserSettingsWithSuccess:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    id ret = [self syncSendByFHSTwitterEngineWithUrl:url_account_settings
                                              method:@"GET"
                                          parameters:nil];
    if ([ret isKindOfClass:[NSError class]]) {
        failure(ret);
    } else {
        success(ret);
    }
    
}
- (void)getHomeTimelineWithMaxID:(NSString *)maxID count:(int)count success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    NSMutableDictionary *params = [@{} mutableCopy];
    if (maxID) params[@"max_id"] = @([maxID longLongValue] - 1);
    if (count) params[@"count"] = @(count);
    [self sendGETWithUrl:url_statuses_home_timeline
              parameters:params
                 success:success failure:failure];
}
- (void)getHomeTimelineSinceID:(NSString *)sinceID count:(int)count success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure
{
    NSMutableDictionary *params = [@{} mutableCopy];
    if (sinceID) params[@"since_id"] = sinceID;
    if (count) params[@"count"] = @(count);
    [self sendGETWithUrl:url_statuses_home_timeline
              parameters:params
                 success:success failure:failure];
}
- (void)getMentionsTimelineSinceID:(NSString *)sinceID maxID:(NSString *)maxID count:(NSUInteger)count success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure
{
    NSMutableDictionary *params = [@{} mutableCopy];
    if (sinceID) params[@"since_id"] = sinceID;
    if (maxID) params[@"max_id"] = @([maxID longLongValue] - 1);
    if (count) params[@"count"] = @(count);
    [self sendGETWithUrl:url_statuses_metions_timeline
              parameters:params
                 success:success failure:failure];
}
- (void)getUserTimelineWithScreenName:(NSString *)screenName sinceID:(NSString *)sinceID count:(int)count success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    NSMutableDictionary *params = [@{} mutableCopy];
    if (screenName) params[@"screen_name"] = screenName;
    if (sinceID) params[@"since_id"] = sinceID;
    if (count) params[@"count"] = @(count);
    [self sendGETWithUrl:url_statuses_user_timeline
              parameters:params
                 success:success failure:failure];
}
- (void)getUserTimelineWithScreenName:(NSString *)screenName maxID:(NSString *)maxID count:(int)count success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    NSMutableDictionary *params = [@{} mutableCopy];
    if (screenName) params[@"screen_name"] = screenName;
    if (maxID) params[@"max_id"] = @([maxID longLongValue] - 1);
    if (count) params[@"count"] = @(count);
    [self sendGETWithUrl:url_statuses_user_timeline
              parameters:params
                 success:success failure:failure];
}
- (void)getFavoritesWithScreenName:(NSString *)screenName sinceID:(NSString *)sinceID count:(int)count success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    NSMutableDictionary *params = [@{} mutableCopy];
    if (screenName) params[@"screen_name"] = screenName;
    if (sinceID) params[@"since_id"] = sinceID;
    if (count) params[@"count"] = @(count);
    [self sendGETWithUrl:url_favorites_list
              parameters:params
                 success:success failure:failure];
}
- (void)getFavoritesWithScreenName:(NSString *)screenName maxID:(NSString *)maxID count:(int)count success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    NSMutableDictionary *params = [@{} mutableCopy];
    if (screenName) params[@"screen_name"] = screenName;
    if (maxID) params[@"max_id"] = @([maxID longLongValue] - 1);
    if (count) params[@"count"] = @(count);
    [self sendGETWithUrl:url_favorites_list
              parameters:params
                 success:success failure:failure];
}
- (void)getDirectMessagesSinceID:(NSString *)sinceID success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    NSMutableDictionary *params = [@{} mutableCopy];
    if (sinceID) params[@"since_id"] = sinceID;
    params[@"count"] = @"200";
    params[@"skip_status"] = @"true";
    [self sendGETWithUrl:url_direct_messages
              parameters:params
                 success:success
                 failure:^(NSError *error) {
                     if (error.code != 204) {
                         failure(error);
                     } else {
                         success(@[]);
                     }
                 }];
}
- (void)getSentMessagesSinceID:(NSString *)sinceID success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    NSMutableDictionary *params = [@{} mutableCopy];
    if (sinceID) params[@"since_id"] = sinceID;
    params[@"count"] = @"200";
    [self sendGETWithUrl:url_direct_messages_sent
              parameters:params
                 success:success
                 failure:^(NSError *error) {
                     if (error.code != 204) {
                         failure(error);
                     } else {
                         success(@[]);
                     }
                 }];
}
- (void)getListsWithScreenName:(NSString *)screenName success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure
{
    [self sendGETWithUrl:url_lists_list
              parameters:@{@"screen_name": screenName}
                 success:success
                 failure:failure];
}
- (void)getListsSubscribedWithScreenName:(NSString *)screenName count:(int)count success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    [self sendGETWithUrl:url_lists_subscriptions
              parameters:@{@"screen_name": screenName, @"count": @(count)}
                 success:success
                 failure:failure];
}
- (void)getListTimelineWithListID:(NSString *)listID maxID:(NSString *)maxID count:(int)count success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure
{
    if (maxID) maxID = S(@"%lld", [maxID longLongValue] - 1);
    [self sendGETWithUrl:url_lists_statuses
              parameters:@{@"list_id": listID, @"max_id": maxID, @"count": @(count)}
                 success:success
                 failure:failure];
}
- (void)getListTimelineWithListID:(NSString *)listID sinceID:(NSString *)sinceID count:(int)count success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure
{
    NSMutableDictionary *params = [@{} mutableCopy];
    if (sinceID) params[@"since_id"] = sinceID;
    if (count) params[@"count"] = @(count);
    params[@"list_id"] = listID;
    [self sendGETWithUrl:url_lists_statuses
              parameters:params
                 success:success
                 failure:failure];
}
- (void)deleteListWithListID:(NSString *)listID success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    [self sendPOSTWithUrl:url_lists_destroy
               parameters:@{@"list_id": listID}
                  success:success
                  failure:failure];
}
- (void)updateListWithListID:(NSString *)listID name:(NSString *)name desc:(NSString *)desc mode:(NSString *)mode success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    [self sendPOSTWithUrl:url_lists_update
               parameters:@{@"list_id": listID, @"name": name, @"description": desc, @"mode": mode}
                  success:success
                  failure:failure];
}
- (void)createListWithName:(NSString *)name desc:(NSString *)desc mode:(NSString *)mode success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    [self sendPOSTWithUrl:url_lists_create
               parameters:@{@"name": name, @"description": desc, @"mode": mode}
                  success:success
                  failure:failure];
}
- (void)subscribeListWithListID:(NSString *)listID success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    [self sendPOSTWithUrl:url_lists_subscribers_create
               parameters:@{@"list_id": listID}
                  success:success
                  failure:failure];
}
- (void)getListsListedUser:(NSString *)screenName success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    [self sendGETWithUrl:url_lists_memberships
               parameters:@{@"screen_name": screenName}
                  success:success
                  failure:failure];
}
- (void)getMyListsListedUser:(NSString *)screenName success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    [self sendGETWithUrl:url_lists_memberships
              parameters:@{@"screen_name": screenName, @"filter_to_owned_lists": @YES}
                 success:success
                 failure:failure];
}
- (void)createMember:(NSString *)screenName toList:(NSString *)listID success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    [self sendPOSTWithUrl:url_lists_members_create
              parameters:@{@"screen_name": screenName, @"list_id": listID}
                 success:success
                 failure:failure];
}
- (void)destroyMember:(NSString *)screenName toList:(NSString *)listID success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    [self sendPOSTWithUrl:url_lists_members_destroy
              parameters:@{@"screen_name": screenName, @"list_id": listID}
                 success:success
                 failure:failure];
}
- (void)unsubscribeListWithListID:(NSString *)listID success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    [self sendPOSTWithUrl:url_lists_subscribers_destroy
               parameters:@{@"list_id": listID}
                  success:success
                  failure:failure];
}
- (void)getListSubscribersWithListID:(NSString *)listID sinceID:(NSString *)sinceID success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure
{
    NSMutableDictionary *params = [@{@"list_id": listID} mutableCopy];
    if (sinceID) params[@"cursor"] = sinceID;
    [self sendGETWithUrl:url_lists_subscribers
              parameters:params
                 success:success
                 failure:failure];
}
- (void)getListMembersWithListID:(NSString *)listID sinceID:(NSString *)sinceID success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure
{
    NSMutableDictionary *params = [@{@"list_id": listID} mutableCopy];
    if (sinceID) params[@"cursor"] = sinceID;
    [self sendGETWithUrl:url_lists_members
              parameters:params
                 success:success
                 failure:failure];
}
- (void)getDetailsForStatus:(NSString *)statusID success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    [self sendGETWithUrl:url_statuses_show
              parameters:statusID ? @{@"id": statusID} : nil
                 success:success failure:failure];
}
- (void)lookupUsers:(NSArray *)users success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    if (!users.count) return;
    [self sendGETWithUrl:url_users_lookup
              parameters:@{@"user_id": [users componentsJoinedByString:@","]}
                 success:success failure:failure];
}
- (void)showUser:(NSString *)screenName success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    [self sendGETWithUrl:url_users_show
              parameters:@{@"screen_name": screenName}
                 success:success
                 failure:failure];
}
- (void)oembedStatus:(NSString *)statusID success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure
{
    [self sendGETWithUrl:url_statuses_oembed
              parameters:@{@"id": statusID}
                 success:success
                 failure:failure];
}
- (void)getRetweetsForStatus:(NSString *)statusID count:(int)count success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure
{
    [self sendGETWithUrl:S(url_statuses_retweets, statusID)
              parameters:@{@"count": @(count)}
                 success:success failure:failure];
}
- (void)sendStatus:(NSString *)status inReplyToID:(NSString *)inReplyToID imageFilePath:(NSString *)imageFilePath location:(CLLocation *)location placeId:(NSString *)placeId success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    FHSTwitterEngine *engine = self.engine;
    NSData *imageData = UIImageJPEGRepresentation([UIImage imageWithContentsOfFile:imageFilePath], 0.92);
    
    [engine postTweet:status withImageData:imageData inReplyTo:inReplyToID location:location placeId:placeId success:^(id responseObj) {
        notification_post_with_object(HSUPostTweetProgressChangedNotification, @(1));
    } failure:failure progress:^(double progress) {
        notification_post_with_object(HSUPostTweetProgressChangedNotification, @(progress));
    }];
}
- (void)sendDirectMessage:(NSString *)message toUser:(NSString *)screenName success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    [self sendPOSTWithUrl:url_direct_messages_new
               parameters:@{@"text": message, @"screen_name": screenName}
                  success:success
                  failure:failure];
}
- (void)sendRetweetWithStatusID:(NSString *)statusID success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    [self sendPOSTWithUrl:[NSString stringWithFormat:url_statuses_retweet, statusID]
               parameters:nil
                  success:success
                  failure:failure];
}
- (void)getFollowersSinceId:(NSString *)sinceID forUserScreenName:(NSString *)screenName success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    NSMutableDictionary *params = [@{} mutableCopy];
    if (sinceID) params[@"cursor"] = sinceID;
    if (screenName) params[@"screen_name"] = screenName;
    params[@"count"] = @"50";
    [self sendGETWithUrl:url_followers_ids
              parameters:params
                 success:^(id responseObj)
     {
         NSMutableDictionary *usersDict = [responseObj mutableCopy];
         [self lookupUsers:usersDict[@"ids"]
                   success:^(id responseObj) {
             usersDict[@"users"] = responseObj;
             success(usersDict);
         } failure:failure];
     } failure:failure];
}
- (void)getFollowingsSinceId:(NSString *)sinceID forUserScreenName:(NSString *)screenName success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    NSMutableDictionary *params = [@{} mutableCopy];
    if (sinceID) params[@"cursor"] = sinceID;
    if (screenName) params[@"screen_name"] = screenName;
    params[@"count"] = @"50";
    [self sendGETWithUrl:url_friends_ids
              parameters:params
                 success:^(id responseObj)
     {
         NSMutableDictionary *usersDict = [responseObj mutableCopy];
         if ([usersDict[@"ids"] count]) {
             [self lookupUsers:usersDict[@"ids"]
                       success:^(id responseObj) {
                           usersDict[@"users"] = responseObj;
                           success(usersDict);
                       } failure:failure];
         } else {
             success(@{@"users": @[]});
         }
     } failure:failure];
}
- (void)getFriendsSinceId:(NSString *)sinceId count:(int)count success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    NSMutableDictionary *params = [@{} mutableCopy];
    if (sinceId) params[@"cursor"] = sinceId;
    if (count) params[@"count"] = @(count); // max 5000
    [self sendGETWithUrl:url_friends_ids
              parameters:params
                 success:^(id responseObj)
     {
         NSMutableDictionary *usersDict = [responseObj mutableCopy];
         [self lookupUsers:usersDict[@"ids"]
                   success:^(id responseObj) {
                       usersDict[@"users"] = responseObj;
                       success(usersDict);
                   } failure:failure];
     } failure:failure];
}
- (void)getFriendsWithCount:(int)count success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    [self getFriendsSinceId:nil count:count success:success failure:failure];
}
- (void)getFriendsWithSuccess:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    [self getFriendsWithCount:100 success:success failure:failure];
}
- (void)getTrendsWithSuccess:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    [self sendGETWithUrl:url_trends_place
              parameters:@{@"id": @"1"}
                 success:success failure:failure];
}
- (void)lookupFriendshipsWithScreenNames:(NSArray *)screenNames success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    NSString *screenName = [screenNames componentsJoinedByString:@","];
    [self sendGETWithUrl:url_friendships_lookup
              parameters:@{@"screen_name": screenName}
                 success:success
                 failure:failure];
}
- (void)searchUserWithKeyword:(NSString *)keyword success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure
{
    [self sendGETWithUrl:url_users_search
              parameters:@{@"q": keyword, @"page": @1, @"count": @20}
                 success:success
                 failure:failure];
}
- (void)searchTweetsWithKeyword:(NSString *)keyword sinceID:(NSString *)sinceID count:(int)count success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    NSMutableDictionary *params = @{}.mutableCopy;
    params[@"q"] = keyword;
    if (sinceID) params[@"since_id"] = sinceID;
    if (count) params[@"count"] = @(count);
    [self sendGETWithUrl:url_search_tweets
              parameters:params
                 success:success
                 failure:failure];
}
- (void)reverseGeocodeWithLocation:(CLLocation *)location success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure
{
    [self sendGETWithUrl:url_reverse_geocode
              parameters:@{@"lat": @(location.coordinate.latitude), @"long": @(location.coordinate.longitude), @"max_results": @1}
                 success:success
                 failure:failure];
}
- (void)blockUser:(NSString *)screenName success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    [self sendPOSTWithUrl:url_blocks_create
               parameters:@{@"screen_name": screenName}
                  success:success failure:failure];
}
- (void)unblockuser:(NSString *)screenName success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    [self sendPOSTWithUrl:url_blocks_destroy
               parameters:@{@"screen_name": screenName}
                  success:success failure:failure];
}
- (void)followUser:(NSString *)screenName success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    [self sendPOSTWithUrl:url_friendships_create
               parameters:@{@"screen_name": screenName}
                  success:success failure:failure];
}
- (void)unFollowUser:(NSString *)screenName success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    [self sendPOSTWithUrl:url_friendships_destroy
               parameters:@{@"screen_name": screenName}
                  success:success failure:failure];
}
- (void)markStatus:(NSString *)statusID success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    [self sendPOSTWithUrl:url_favorites_create
               parameters:@{@"id": statusID}
                  success:success failure:failure];
}
- (void)unMarkStatus:(NSString *)statusID success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    [self sendPOSTWithUrl:url_favorites_destroy
               parameters:@{@"id": statusID}
                  success:success failure:failure];
}
- (void)reportUserAsSpam:(NSString *)screenName success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    [self sendPOSTWithUrl:url_users_report_spam
               parameters:@{@"screen_name": screenName}
                  success:success failure:failure];
}
- (void)deleteDirectMessage:(NSString *)messageID success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    [self sendPOSTWithUrl:url_direct_messages_destroy
               parameters:@{@"id": messageID}
                  success:success
                  failure:failure];
}
- (void)destroyStatus:(NSString *)statusID success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    [self sendPOSTWithUrl:S(url_statuses_destroy, statusID)
               parameters:nil
                  success:success failure:failure];
}

- (void)updateAvatar:(UIImage *)avatar success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    dispatch_async(GCDBackgroundThread, ^{
        id response = [self.engine setProfileImageWithImageData:UIImageJPEGRepresentation(avatar, .92)];
        dispatch_async(GCDMainThread, ^{
            if ([response isKindOfClass:[NSError class]]) {
                failure(response);
            } else {
                success(response); // error is profile dictionary
            }
        });
    });
}

- (void)updateBanner:(UIImage *)banner success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure
{
    dispatch_async(GCDBackgroundThread, ^{
        id response = [self.engine setBannerImageWithImageData:UIImageJPEGRepresentation(banner, .92)];
        dispatch_async(GCDMainThread, ^{
            if ([response isKindOfClass:[NSError class]]) {
                NSError *error = response;
                if (error.code != 204) {
                    failure(response);
                    return ;
                }
            }
            success(response);
        });
    });
}

- (void)updateProfile:(NSDictionary *)profile success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    dispatch_async(GCDBackgroundThread, ^{
        id response = [self.engine updateUserProfileWithDictionary:profile];
        dispatch_async(GCDMainThread, ^{
            if ([response isKindOfClass:[NSError class]]) {
                NSError *error = response;
                if (error.code != 204) {
                    failure(response);
                    return ;
                }
            }
            success(response);
        });
    });
}

- (void)sendGETWithUrl:(NSString *)url parameters:(NSDictionary *)parameters success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    [self sendWithUrl:url method:@"GET" parameters:parameters success:success failure:failure];
}

- (void)sendPOSTWithUrl:(NSString *)url parameters:(NSDictionary *)parameters success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    [self sendWithUrl:url method:@"POST" parameters:parameters success:success failure:failure];
}

- (void)sendWithUrl:(NSString *)url method:(NSString *)method parameters:(NSDictionary *)parameters success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    if (!self.myScreenName) {
        NSLog(@"not authorized");
        failure(nil);
        [self authorize];
        return;
    }
    
    [self sendByFHSTwitterEngineWithUrl:url method:method parameters:parameters success:success failure:failure];
}

- (void)sendByFHSTwitterEngineWithUrl:(NSString *)url method:(NSString *)method parameters:(NSDictionary *)parameters success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
#ifdef DEBUG
    NSLog(@"api request - %@\n%@", [url substringFromIndex:@"https://api.twitter.com/1.1/".length], parameters);
#endif
    FHSTwitterEngine *engine = self.engine;
    NSURL *baseURL = [NSURL URLWithString:url];
    OAMutableURLRequest *request = [OAMutableURLRequest requestWithURL:baseURL consumer:engine.consumer token:engine.accessToken];
    
    NSMutableArray *params = @[].mutableCopy;
    for (NSString *key in parameters.allKeys) {
        NSString *value = [NSString stringWithFormat:@"%@", parameters[key]];
        OARequestParameter *param = [OARequestParameter requestParameterWithName:key value:value];
        [params addObject:param];
    }
    
    [[AFNetworkActivityIndicatorManager sharedManager] incrementActivityCount];
    dispatch_async(GCDBackgroundThread, ^{
        FHSTwitterEngine *engine = twitter.engine;
        id responseObj;
        if ([method isEqualToString:@"GET"]) {
            responseObj = [engine sendGETRequest:request withParameters:params];
        } else {
            responseObj = [engine sendPOSTRequest:request withParameters:params];
        }
        NSError *error = [responseObj isKindOfClass:[NSError class]] ? responseObj : nil;
        
        dispatch_async(GCDMainThread, ^{
            
            [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
            
            if (error) {
                if ([error code] == 204) { // Error Domain=Twitter successfully processed the request, but did not return any content Code=204 "The operation couldn’t be completed. (Twitter successfully processed the request, but did not return any content error 204.)"
                    failure(error);
                    [Flurry logEvent:@"twitter_api_request_failed" withParameters:@{@"url": API_URL, @"network": NetWorkStatus}];
                } else {
                    failure(error);
                    [Flurry logEvent:@"twitter_api_request_failed" withParameters:@{@"url": API_URL, @"network": NetWorkStatus}];
                }
            } else {
                success(responseObj);
                [Flurry logEvent:@"twitter_api_request_success" withParameters:@{@"url": API_URL, @"network": NetWorkStatus}];
            }
        });
    });
}

- (id)syncSendByFHSTwitterEngineWithUrl:(NSString *)url method:(NSString *)method parameters:(NSDictionary *)parameters
{
    FHSTwitterEngine *engine = self.engine;
    NSURL *baseURL = [NSURL URLWithString:url];
    OAMutableURLRequest *request = [OAMutableURLRequest requestWithURL:baseURL consumer:engine.consumer token:engine.accessToken];
    
    NSMutableArray *params = @[].mutableCopy;
    for (NSString *key in parameters.allKeys) {
        NSString *value = parameters[key];
        OARequestParameter *param = [OARequestParameter requestParameterWithName:key value:value];
        [params addObject:param];
    }
    id responseObj;
    if ([method isEqualToString:@"GET"]) {
        responseObj = [engine sendGETRequest:request withParameters:params];
    } else {
        responseObj = [engine sendPOSTRequest:request withParameters:params];
    }
    NSError *error = [responseObj isKindOfClass:[NSError class]] ? responseObj : nil;
    
    if (error) {
        [Flurry logEvent:@"twitter_api_request_failed" withParameters:@{@"url": API_URL, @"network": NetWorkStatus}];
        return error;
    } else {
        [Flurry logEvent:@"twitter_api_request_success" withParameters:@{@"url": API_URL, @"network": NetWorkStatus}];
        return responseObj;
    }
}

- (void)dealWithError:(NSError *)error errTitle:(NSString *)errTitle;
{
#if DEBUG
    if (error) {
        NSLog(@"API Request Error %@", error);
    }
#endif
    if (!error) {
        return;
    }
    if (error.code == 204) { // error like "no more data"
        return;
    }
    
    if ([Reachability reachabilityForInternetConnection].isReachable) {
        RIButtonItem *cancelItem = [RIButtonItem itemWithLabel:_("Retry Later")];
        RIButtonItem *changeServerItem = [RIButtonItem itemWithLabel:_("Change Server")];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:_("Connection failed")
                                                        message:_("api_request_failed_alert_message")
                                               cancelButtonItem:cancelItem
                                               otherButtonItems:changeServerItem, nil];
        changeServerItem.action = ^{
            HSUShadowsocksViewController *ssVC = [[HSUShadowsocksViewController alloc] init];
            HSUNavigationController *nav = [[HSUNavigationController alloc] initWithRootViewController:ssVC];
            UIViewController *rootVC = [HSUAppDelegate shared].tabController;
            if (rootVC.presentedViewController) {
                rootVC = rootVC.presentedViewController;
            }
            [rootVC presentViewController:nav animated:YES completion:nil];
        };
        [alert show];
    } else {
        [SVProgressHUD showErrorWithStatus:_("Check your network")];
    }
}

- (NSDate *)getDateFromTwitterCreatedAt:(NSString *)twitterDate
{
    return [self.engine getDateFromTwitterCreatedAt:twitterDate];
}

- (NSDictionary *)networkStatus
{
    NSString *networkType = @"none";
    if ([Reachability reachabilityForInternetConnection].isReachableViaWiFi) {
        networkType = @"WiFi";
    } else if ([Reachability reachabilityForInternetConnection].isReachableViaWWAN) {
        networkType = @"WWAN";
    }
    
    NSString *ss = [HSUAppDelegate shared].shadwosocksServer ?: @"";
    
    return @{@"reachability": networkType, @"ssserver": ss, @"ssstarted": @(shadowsocksStarted)};
}

@end