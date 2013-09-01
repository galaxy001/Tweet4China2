//
//  HSUTwitterAPI.m
//  Tweet4China
//
//  Created by Jason Hsu on 13/7/22.
//  Copyright (c) 2013年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUTwitterAPI.h"
#import <Accounts/Accounts.h>
#import <Social/Social.h>
#import "FHSTwitterEngine.h"
#import "OAToken.h"
#import "OARequestParameter.h"
#import "OAMutableURLRequest.h"


@interface FHSTwitterEngine (Private)

@property (retain, nonatomic) OAConsumer *consumer;

@end

id RemoveFuckingNull(id rootObject);

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

@interface HSUTwitterAPI ()

@property (nonatomic, strong) ACAccount *account;
@property (nonatomic, strong) ACAccountStore *accountStore;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@end

@implementation HSUTwitterAPI

- (id)init
{
#ifndef kTwitterAppKey
    #error "Define your kTwitterAppKey in HSUAppDefinitions.h before compile"
#endif
#ifndef kTwitterAppSecret
    #error "Define your kTwitterAppSecret in HSUAppDefinitions.h before compile"
#endif
    self = [super init];
    if (self) {
        self.dateFormatter = [[NSDateFormatter alloc]init];
        NSLocale *usLocale = [[NSLocale alloc]initWithLocaleIdentifier:@"en_US"];
        [self.dateFormatter setLocale:usLocale];
        [self.dateFormatter setDateStyle:NSDateFormatterLongStyle];
        [self.dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
        [self.dateFormatter setDateFormat:@"EEE MMM dd HH:mm:ss ZZZZ yyyy"];
        
        FHSTwitterEngine *engine = [FHSTwitterEngine sharedEngine];
        [engine permanentlySetConsumerKey:kTwitterAppKey andSecret:kTwitterAppSecret];
        [engine loadAccessToken];
        self.accountStore = [[ACAccountStore alloc] init];
        if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) {
            
            ACAccountType *twitterAccountType = [self.accountStore
                                                 accountTypeWithAccountTypeIdentifier:
                                                 ACAccountTypeIdentifierTwitter];
            [self.accountStore
             requestAccessToAccountsWithType:twitterAccountType
             options:NULL
             completion:^(BOOL granted, NSError *error) {
                 if (granted) {
                     NSArray *twitterAccounts =
                     [self.accountStore accountsWithAccountType:twitterAccountType];
                     
                     for (ACAccount *account in twitterAccounts) {
                         if ([account.username isEqualToString:[self mySettings][@"screen_name"]]) {
                             self.account = account;
                             return ;
                         }
                     }
                 }
                 if (!self.isAuthorized) {
                     [self authorize];
                 }
             }];
        }
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(shadowsocksStarted)
         name:HSUShadowsocksStarted
         object:nil];
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

- (void)shadowsocksStarted
{
    if (!self.isAuthorized) {
        [self authorize];
    }
}

- (BOOL)isAuthorized
{
    return [FHSTwitterEngine sharedEngine].isAuthorized && self.account != nil;
}

- (void)authorize
{
    if ([HSUAppDelegate shared].shadowsocksStarted) {
        [self authorizeByFHSTwitterEngine];
    }
}

- (void)authorizeByFHSTwitterEngine
{
    FHSTwitterEngine *engine = [FHSTwitterEngine sharedEngine];
    [engine showOAuthLoginControllerFromViewController:[HSUAppDelegate shared].window.rootViewController
                                        withCompletion:^(BOOL success)
     {
         if (success) {
             ACAccountType *twitterAccountType = [[HSUTwitterAPI shared].accountStore
                                                  accountTypeWithAccountTypeIdentifier:
                                                  ACAccountTypeIdentifierTwitter];
             ACAccount *newAccount = [[ACAccount alloc] initWithAccountType:twitterAccountType];
             newAccount.credential = [[ACAccountCredential alloc]
                                      initWithOAuthToken:[FHSTwitterEngine sharedEngine].accessToken.key
                                      tokenSecret:[FHSTwitterEngine sharedEngine].accessToken.secret];
             
             [[HSUTwitterAPI shared] syncGetUserSettingsWithSuccess:^(id responseObj) {
                 NSDictionary *userSettings = responseObj;
                 newAccount.username = userSettings[@"screen_name"];
                 [[NSUserDefaults standardUserDefaults] setObject:responseObj forKey:kUserSettings_DBKey];
                 [[NSUserDefaults standardUserDefaults] synchronize];
                 if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) {
                     
                     [[HSUTwitterAPI shared].accountStore saveAccount:newAccount
                                                withCompletionHandler:^(BOOL success, NSError *error)
                     {
                         HSUTwitterAPI *api = [HSUTwitterAPI shared];
                         ACAccountType *twitterAccountType = [api.accountStore
                                                              accountTypeWithAccountTypeIdentifier:
                                                              ACAccountTypeIdentifierTwitter];
                         [api.accountStore
                          requestAccessToAccountsWithType:twitterAccountType
                          options:NULL
                          completion:^(BOOL granted, NSError *error) {
                              if (granted) {
                                  NSArray *twitterAccounts =
                                  [api.accountStore accountsWithAccountType:twitterAccountType];
                                  
                                  for (ACAccount *account in twitterAccounts) {
                                      if ([account.username isEqualToString:[api mySettings][@"screen_name"]]) {
                                          api.account = account;
                                          [[NSNotificationCenter defaultCenter]
                                           postNotificationName:HSUTwiterLoginSuccess
                                           object:self
                                           userInfo:@{@"success": @YES}];
                                          break;
                                      }
                                  }
                              }
                          }];
                     }];
                 }
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
    return self.account.username;
}

- (NSDictionary *)mySettings
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:kUserSettings_DBKey];
}

- (void)getUserSettingsWithSuccess:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    [self sendWithUrl:url_account_settings
               method:SLRequestMethodGET
           parameters:nil
              success:success
              failure:failure];
}
- (void)syncGetUserSettingsWithSuccess:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    [self syncSendByFHSTwitterEngineWithUrl:url_account_settings
                                     method:SLRequestMethodGET
                                 parameters:nil
                                    success:success
                                    failure:failure];
}
- (void)getHomeTimelineWithMaxID:(NSString *)maxID count:(int)count success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    [self sendGETWithUrl:url_statuses_home_timeline
              parameters:maxID ? @{@"max_id": maxID} : nil
                 success:success failure:failure];
}
- (void)getHomeTimelineSinceID:(NSString *)sinceID count:(int)count success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure
{
    [self sendGETWithUrl:url_statuses_home_timeline
              parameters:sinceID ? @{@"since_id": sinceID} : nil
                 success:success failure:failure];
}
- (void)getMentionsTimelineSinceID:(NSString *)sinceID maxID:(NSString *)maxID count:(NSUInteger)count success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure
{
    NSMutableDictionary *params = [@{} mutableCopy];
    if (sinceID) params[@"since_id"] = sinceID;
    if (maxID) params[@"max_id"] = maxID;
    if (count) params[@"count"] = @(count);
    [self sendGETWithUrl:url_statuses_metions_timeline
              parameters:params
                 success:success failure:failure];
}
- (void)getUserTimelineWithScreenName:(NSString *)screenName success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    [self sendGETWithUrl:url_statuses_user_timeline
              parameters:screenName ? @{@"screen_name": screenName} : nil
                 success:success failure:failure];
}
- (void)getDirectMessagesSinceID:(NSString *)sinceID success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    NSMutableDictionary *params = [@{} mutableCopy];
    params[@"since_id"] = sinceID ?: @"-1";
    params[@"count"] = @"200";
    params[@"skip_status"] = @"true";
    [self sendByFHSTwitterEngineWithUrl:url_direct_messages
                                 method:SLRequestMethodGET
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
- (void)lookupUser:(NSString *)screenName success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    [self sendGETWithUrl:url_users_lookup
              parameters:@{@"screen_name": screenName}
                 success:^(id responseObj) {
                     NSArray *users = responseObj;
                     if (users.count) {
                         success(users[0]);
                     }
                 } failure:failure];
}
- (void)sendStatus:(NSString *)status inReplyToID:(NSString *)inReplyToID imageFilePath:(NSString *)imageFilePath location:(CLLocationCoordinate2D)location success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    NSMutableDictionary *params = [@{} mutableCopy];
    NSString *url = url_statuses_update;
    
    params[@"status"] = status;
    
    if (inReplyToID) {
        params[kTwitter_Parameter_Key_Reply_ID] = inReplyToID;
    }
    
    if (imageFilePath) {
        url = url_statuses_update_with_media;
        UIImage *image = [UIImage imageWithContentsOfFile:imageFilePath];
        params[@"media[]"] = UIImageJPEGRepresentation(image, 1.f);
    }
    
    if (location.latitude && location.longitude) {
        params[@"lat"] = S(@"%g", location.latitude);
        params[@"long"] = S(@"%g", location.longitude);
    }
    
    [self sendPOSTWithUrl:url parameters:params success:success failure:failure];
}
- (void)sendDirectMessage:(NSString *)message toUser:(NSString *)screenName success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    [self sendByFHSTwitterEngineWithUrl:url_direct_messages_new
                                 method:SLRequestMethodPOST
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
    if (sinceID) params[@"since_id"] = sinceID;
    if (screenName) params[@"screen_name"] = screenName;
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
- (void)getFriendsWithSuccess:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    [self sendGETWithUrl:url_friends_ids
              parameters:nil
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
                                 method:SLRequestMethodGET
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
    [self sendPOSTWithUrl:url_friendships_destroy parameters:nil success:success failure:failure];
}
- (void)markStatus:(NSString *)statusID success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
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
                                 method:SLRequestMethodPOST
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
    [self sendWithUrl:url method:SLRequestMethodGET parameters:parameters success:success failure:failure];
}

- (void)sendPOSTWithUrl:(NSString *)url parameters:(NSDictionary *)parameters success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    [self sendWithUrl:url method:SLRequestMethodPOST parameters:parameters success:success failure:failure];
}

- (void)sendWithUrl:(NSString *)url method:(SLRequestMethod)method parameters:(NSDictionary *)parameters success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    if (!self.account) {
        // todo
        NSLog(@"not authorized");
        return;
    }
    
    NSData *media = parameters[@"media[]"];
    if ([parameters isKindOfClass:[NSMutableDictionary class]] &&
        media) {
        NSMutableDictionary *mp = (NSMutableDictionary *)parameters;
        [mp removeObjectForKey:@"media[]"];
        parameters = mp;
    }
    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                            requestMethod:method
                                                      URL:[NSURL URLWithString:url]
                                               parameters:parameters];
    if (media) {
        [request addMultipartData:media withName:@"media[]" type:@"image/jpeg" filename:@"image.jpg"];
    }
    [request setAccount:self.account];
    [request performRequestWithHandler:^(NSData *responseData,
                                         NSHTTPURLResponse *urlResponse,
                                         NSError *error) {
        dispatch_async(GCDMainThread, ^{
            if (error) {
                [self dealWithError:error errTitle:@"Some problems with your network"];
                failure(error);
                return ;
            }
            
            if (responseData) {
                id responseObj = [NSJSONSerialization JSONObjectWithData:responseData
                                                                 options:NSJSONReadingAllowFragments
                                                                   error:nil];
                if ([responseObj isKindOfClass:[NSArray class]] ||
                    [responseObj isKindOfClass:[NSDictionary class]]) {
                    
                    responseObj = RemoveFuckingNull(responseObj);
                    
                    if ([responseObj isKindOfClass:[NSDictionary class]]) {
                        if ([responseObj[@"errors"] count]) {
                            NSMutableDictionary *errorDict = [responseObj[@"errors"][0] mutableCopy];
                            errorDict[@"url"] = url;
                            NSError *error = [NSError errorWithDomain:@"api.twiiter.com" code:1 userInfo:errorDict];
                            failure(error);
                            return ;
                        }
                    }
                    
                    if (urlResponse.statusCode >= 200 && urlResponse.statusCode < 300) {
                        success(responseObj);
                        return;
                    }
                }
                
                NSError *error = [NSError errorWithDomain:@"api.twiiter.com" code:3 userInfo:responseObj];
                failure(error);
                return;
            }
            
            NSError *error = [NSError errorWithDomain:@"api.twiiter.com" code:3 userInfo:nil];
            failure(error);
        });
    }];
}

- (void)sendByFHSTwitterEngineWithUrl:(NSString *)url method:(SLRequestMethod)method parameters:(NSDictionary *)parameters success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
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
    dispatch_async(GCDBackgroundThread, ^{
        FHSTwitterEngine *engine = [FHSTwitterEngine sharedEngine];
        id responseObj;
        if (method == SLRequestMethodGET) {
            responseObj = [engine sendGETRequest:request withParameters:params];
        } else {
            responseObj = [engine sendPOSTRequest:request withParameters:params];
        }
        NSError *error = [responseObj isKindOfClass:[NSError class]] ? responseObj : nil;
        
        dispatch_async(GCDMainThread, ^{
            if (error) {
                [self dealWithError:error errTitle:@"Some problems with your network"];
                failure(error);
            } else {
                success(responseObj);
            }
        });
    });
}

- (void)syncSendByFHSTwitterEngineWithUrl:(NSString *)url method:(SLRequestMethod)method parameters:(NSDictionary *)parameters success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
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
    if (method == SLRequestMethodGET) {
        responseObj = [engine sendGETRequest:request withParameters:params];
    } else {
        responseObj = [engine sendPOSTRequest:request withParameters:params];
    }
    NSError *error = [responseObj isKindOfClass:[NSError class]] ? responseObj : nil;
    
    if (error) {
        [self dealWithError:error errTitle:@"Some problems with your network"];
        failure(error);
    } else {
        success(responseObj);
    }
}

- (void)dealWithError:(NSError *)error errTitle:(NSString *)errTitle;
{
    NSLog(@"API Request Error %@", error);
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:@"Error"
                          message:errTitle
                          delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [alert show];
}

- (NSDate *)getDateFromTwitterCreatedAt:(NSString *)twitterDate {
    return [self.dateFormatter dateFromString:twitterDate];
}

@end

id RemoveFuckingNull(id rootObject) {
    if ([rootObject isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *sanitizedDictionary = [NSMutableDictionary dictionaryWithDictionary:rootObject];
        [rootObject enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            id sanitized = removeNull(obj);
            if (!sanitized) {
                [sanitizedDictionary setObject:@"" forKey:key];
            } else {
                [sanitizedDictionary setObject:sanitized forKey:key];
            }
        }];
        return [NSMutableDictionary dictionaryWithDictionary:sanitizedDictionary];
    }
    
    if ([rootObject isKindOfClass:[NSArray class]]) {
        NSMutableArray *sanitizedArray = [NSMutableArray arrayWithArray:rootObject];
        [rootObject enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            id sanitized = removeNull(obj);
            if (!sanitized) {
                [sanitizedArray replaceObjectAtIndex:[sanitizedArray indexOfObject:obj] withObject:@""];
            } else {
                [sanitizedArray replaceObjectAtIndex:[sanitizedArray indexOfObject:obj] withObject:sanitized];
            }
        }];
        return [NSMutableArray arrayWithArray:sanitizedArray];
    }
    
    if ([rootObject isKindOfClass:[NSNull class]]) {
        return (id)nil;
    } else {
        return rootObject;
    }
}