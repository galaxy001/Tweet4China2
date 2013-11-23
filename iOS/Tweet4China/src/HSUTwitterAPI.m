//
//  HSUTwitterAPI.m
//  Tweet4China
//
//  Created by Jason Hsu on 13/7/22.
//  Copyright (c) 2013年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUTwitterAPI.h"
#import "FHSTwitterEngine.h"
#import "OAToken.h"
#import "OARequestParameter.h"
#import "OAMutableURLRequest.h"


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

@interface HSUTwitterAPI ()

@property (nonatomic, assign, getter = isAuthorizing) BOOL authorizing;

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
        FHSTwitterEngine *engine = [FHSTwitterEngine sharedEngine];
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

- (BOOL)isAuthorized
{
    return [FHSTwitterEngine sharedEngine].isAuthorized;
}

- (void)signOut
{
    [[FHSTwitterEngine sharedEngine] clearAccessToken];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kUserSettings_DBKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self authorize];
}

- (void)authorize
{
    if (shadowsocksStarted && !self.isAuthorizing) {
        self.authorizing = YES;
        double delayInSeconds = 1.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self authorizeByFHSTwitterEngine];
        });
    }
}

- (void)authorizeByFHSTwitterEngine
{
    if (UseXAuth) {
        [self authorizeByXAuth];
    } else {
        [self authorizeByOAuth];
    }
}

- (void)authorizeByXAuth
{
    FHSTwitterEngine *engine = [FHSTwitterEngine sharedEngine];
    RIButtonItem *loginItem = [RIButtonItem itemWithLabel:@"Login"];
    RIButtonItem *cancelItem = [RIButtonItem itemWithLabel:@"Cancel"];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Login"
                                                    message:nil
                                           cancelButtonItem:cancelItem
                                           otherButtonItems:loginItem, nil];
    loginItem.action = ^{
        [SVProgressHUD showWithStatus:@"Please Wait"];
        dispatch_async(GCDBackgroundThread, ^{
            NSError *error = [engine getXAuthAccessTokenForUsername:[[alert textFieldAtIndex:0] text]
                                                           password:[[alert textFieldAtIndex:1] text]];
            [HSUTwitterAPI shared].authorizing = NO;
            if (!error) {
                [[HSUTwitterAPI shared] syncGetUserSettingsWithSuccess:^(id responseObj) {
                    dispatch_async(GCDMainThread, ^{
                        [SVProgressHUD showSuccessWithStatus:@"Login Success"];
                        [[NSUserDefaults standardUserDefaults] setObject:responseObj forKey:kUserSettings_DBKey];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                        [[NSNotificationCenter defaultCenter]
                         postNotificationName:HSUTwiterLoginSuccess
                         object:self
                         userInfo:@{@"success": @YES}];
                    });
                } failure:^(NSError *error) {
                    [SVProgressHUD dismiss];
                    [TWENGINE dealWithError:error errTitle:@"Login Error"];
                    dispatch_async(GCDMainThread, ^{
                        [SVProgressHUD dismiss];
                        [[HSUTwitterAPI shared] dealWithError:error errTitle:@"Fetch account info failed"];
                        [[NSNotificationCenter defaultCenter]
                         postNotificationName:HSUTwiterLoginSuccess
                         object:self
                         userInfo:@{@"success": @NO, @"error": error}];
                    });
                }];
            } else {
                dispatch_async(GCDMainThread, ^{
                    [SVProgressHUD dismiss];
                    [TWENGINE dealWithError:error errTitle:@"Login Error"];
                    [[NSNotificationCenter defaultCenter]
                     postNotificationName:HSUTwiterLoginSuccess
                     object:self
                     userInfo:@{@"success": @NO}];
                });
            }
        });
    };
    cancelItem.action = ^{
        [[HSUTwitterAPI shared] authorizeByOAuth];
    };
    alert.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
    [alert show];
}

- (void)authorizeByOAuth
{
    FHSTwitterEngine *engine = [FHSTwitterEngine sharedEngine];
    [engine showOAuthLoginControllerFromViewController:[HSUAppDelegate shared].window.rootViewController
                                        withCompletion:^(BOOL success)
     {
         [HSUTwitterAPI shared].authorizing = NO;
         if (success) {
             [[HSUTwitterAPI shared] syncGetUserSettingsWithSuccess:^(id responseObj) {
                 [[NSUserDefaults standardUserDefaults] setObject:responseObj forKey:kUserSettings_DBKey];
                 [[NSUserDefaults standardUserDefaults] synchronize];
                 [[NSNotificationCenter defaultCenter]
                  postNotificationName:HSUTwiterLoginSuccess
                  object:self
                  userInfo:@{@"success": @YES}];
             } failure:^(NSError *error) {
                 [[HSUTwitterAPI shared] dealWithError:error errTitle:@"Fetch account info failed"];
                 [[NSNotificationCenter defaultCenter]
                  postNotificationName:HSUTwiterLoginSuccess
                  object:self
                  userInfo:@{@"success": @NO, @"error": error}];
             }];
         } else {
             [[NSNotificationCenter defaultCenter]
              postNotificationName:HSUTwiterLoginSuccess
              object:self
              userInfo:@{@"success": @NO}];
         }
     }];
}

- (NSString *)myScreenName
{
    return [self mySettings][@"screen_name"];
}

- (NSDictionary *)mySettings
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:kUserSettings_DBKey];
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
    if (maxID) params[@"max_id"] = S(@"%lld", [maxID longLongValue] - 1);
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
    if (maxID) params[@"max_id"] = S(@"%lld", [maxID longLongValue] - 1);
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
    if (maxID) params[@"max_id"] = S(@"%lld", [maxID longLongValue] - 1);
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
    if (maxID) params[@"max_id"] = S(@"%lld", [maxID longLongValue] - 1);
    if (count) params[@"count"] = @(count);
    [self sendGETWithUrl:url_favorites_list
              parameters:params
                 success:success failure:failure];
}
- (void)getDirectMessagesSinceID:(NSString *)sinceID success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    NSMutableDictionary *params = [@{} mutableCopy];
    params[@"since_id"] = sinceID ?: @"-1";
    params[@"count"] = @"200";
    params[@"skip_status"] = @"true";
    [self sendByFHSTwitterEngineWithUrl:url_direct_messages
                                 method:@"GET"
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
- (void)sendStatus:(NSString *)status inReplyToID:(NSString *)inReplyToID imageFilePath:(NSString *)imageFilePath location:(CLLocationCoordinate2D)location placeId:(NSString *)placeId success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    FHSTwitterEngine *engine = [FHSTwitterEngine sharedEngine];
    NSData *imageData = UIImageJPEGRepresentation([UIImage imageWithContentsOfFile:imageFilePath], 0.92);
    
    dispatch_async(GCDBackgroundThread, ^{
        id responseObj = [engine postTweet:status
                             withImageData:imageData
                                 inReplyTo:inReplyToID
                                  location:location
                                   placeId:placeId];
        NSError *error = [responseObj isKindOfClass:[NSError class]] ? responseObj : nil;
        
        dispatch_async(GCDMainThread, ^{
            if (error) {
                failure(error);
            } else {
                success(responseObj);
            }
        });
    });
}
- (void)sendDirectMessage:(NSString *)message toUser:(NSString *)screenName success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    [self sendByFHSTwitterEngineWithUrl:url_direct_messages_new
                                 method:@"POST"
                             parameters:@{@"text": message, @"screen_name": screenName}
                                success:success
                                failure:failure];
}
- (void)sendRetweetWithStatusID:(NSString *)statusID success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    [self sendPOSTWithUrl:[NSString stringWithFormat:url_statuses_retweet, statusID]
               parameters:nil success:success failure:failure];
}
- (void)getFollowersSinceId:(NSString *)sinceID forUserScreenName:(NSString *)screenName success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    NSMutableDictionary *params = [@{} mutableCopy];
    if (sinceID) params[@"cursor"] = sinceID;
    if (screenName) params[@"screen_name"] = screenName;
    params[@"count"] = @"100";
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
    params[@"count"] = @"100";
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
- (void)getFriendsWithSuccess:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    [self sendGETWithUrl:url_friends_ids
              parameters:@{@"count": @"100"}
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
- (void)getSentMessagesSinceID:(NSString *)sinceID success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    [self sendByFHSTwitterEngineWithUrl:url_direct_messages_sent
                                 method:@"GET"
                             parameters:@{@"since_id": sinceID ?: @"-1"}
                                success:success
                                failure:failure];
}
- (void)getTrendsWithSuccess:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    [self sendGETWithUrl:url_trends_place
              parameters:@{@"id": @"1"}
                 success:success failure:failure];
}
- (void)searchUserWithKeyword:(NSString *)keyword success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure
{
    [self sendGETWithUrl:url_users_search
              parameters:@{@"q": keyword, @"page": @1, @"count": @20}
                 success:success
                 failure:failure];
}
- (void)reverseGeocodeWithLocation:(CLLocationCoordinate2D)location success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure
{
    [self sendGETWithUrl:url_reverse_geocode
              parameters:@{@"lat": @(location.latitude), @"long": @(location.longitude), @"max_results": @1}
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
    [self sendByFHSTwitterEngineWithUrl:url_direct_messages_destroy
                                 method:@"POST"
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
    FHSTwitterEngine *engine = [FHSTwitterEngine sharedEngine];
    NSURL *baseURL = [NSURL URLWithString:url];
    OAMutableURLRequest *request = [OAMutableURLRequest requestWithURL:baseURL consumer:engine.consumer token:engine.accessToken];
    
    NSMutableArray *params = @[].mutableCopy;
    for (NSString *key in parameters.allKeys) {
        NSString *value = [NSString stringWithFormat:@"%@", parameters[key]];
        OARequestParameter *param = [OARequestParameter requestParameterWithName:key value:value];
        [params addObject:param];
    }
    dispatch_async(GCDBackgroundThread, ^{
        FHSTwitterEngine *engine = [FHSTwitterEngine sharedEngine];
        id responseObj;
        if ([method isEqualToString:@"GET"]) {
            responseObj = [engine sendGETRequest:request withParameters:params];
        } else {
            responseObj = [engine sendPOSTRequest:request withParameters:params];
        }
        NSError *error = [responseObj isKindOfClass:[NSError class]] ? responseObj : nil;
        
        dispatch_async(GCDMainThread, ^{
            if (error) {
                if ([error code] == 204) { // Error Domain=Twitter successfully processed the request, but did not return any content Code=204 "The operation couldn’t be completed. (Twitter successfully processed the request, but did not return any content error 204.)"
                    failure(error);
                } else {
                    [self dealWithError:error errTitle:@"Some problems with your network"];
                    failure(error);
                }
            } else {
                if ([responseObj count]) {
                    success(responseObj);
                } else {
                    failure(nil);
                }
            }
        });
    });
}

- (id)syncSendByFHSTwitterEngineWithUrl:(NSString *)url method:(NSString *)method parameters:(NSDictionary *)parameters
{
    FHSTwitterEngine *engine = [FHSTwitterEngine sharedEngine];
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
        [self dealWithError:error errTitle:@"Some problems with your network"];
        return error;
    } else {
        return responseObj;
    }
}

- (void)dealWithError:(NSError *)error errTitle:(NSString *)errTitle;
{
    if (!error) {
        return;
    }
    if (error.code == 204) {
        return;
    }
    NSLog(@"API Request Error %@", error);
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:@"Error"
                          message:errTitle
                          delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [alert show];
}

- (NSDate *)getDateFromTwitterCreatedAt:(NSString *)twitterDate {
    return [[FHSTwitterEngine sharedEngine] getDateFromTwitterCreatedAt:twitterDate];
}

@end