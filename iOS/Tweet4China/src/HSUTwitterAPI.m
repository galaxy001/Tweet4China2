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
static NSString * const url_statuses_destroy = @"https://api.twitter.com/1.1/statuses/destroy.json";
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
    self = [super init];
    if (self) {
        self.dateFormatter = [[NSDateFormatter alloc] init];
        [self.dateFormatter setDateFormat:@"EEE MMM dd HH:mm:ss ZZZZ yyyy"];
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
    return self.account != nil;
}

- (void)authorize
{
    if (!self.accountStore) {
        self.accountStore = [[ACAccountStore alloc] init];
    }
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) {
        
        // Obtain access to the user's Twitter accounts
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
                 if (twitterAccounts.count) {
                     self.account = twitterAccounts[0];
                 }
             }
         }];
    }
}

- (NSString *)myScreenName
{
    return self.account.identifier;
}

- (void)getUserSettingsWithSuccess:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    [self sendGETWithUrl:url_account_settings parameters:nil success:success failure:failure];
}
- (void)getHomeTimelineWithMaxID:(NSString *)maxID count:(int)count success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    [self sendGETWithUrl:url_statuses_home_timeline
              parameters:@{@"max_id": maxID}
                 success:success failure:failure];
}
- (void)getHomeTimelineSinceID:(NSString *)sinceID count:(int)count success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure
{
    [self sendGETWithUrl:url_statuses_home_timeline
              parameters:@{@"since_id": sinceID}
                 success:success failure:failure];
}
- (void)getMentionsTimelineSinceID:(NSString *)sinceID maxID:(NSString *)maxID count:(NSUInteger)count success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure
{
    [self sendGETWithUrl:url_statuses_metions_timeline
              parameters:@{@"since_id": sinceID, @"max_id": maxID, @"count": @(count)}
                 success:success failure:failure];
}
- (void)getUserTimelineWithScreenName:(NSString *)screenName success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    [self sendGETWithUrl:url_statuses_user_timeline
              parameters:@{@"screen_name": screenName}
                 success:success failure:failure];
}
- (void)getDirectMessagesSinceID:(NSString *)sinceID success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    [self sendGETWithUrl:url_direct_messages
              parameters:@{@"since_id": sinceID}
                 success:success failure:failure];
}
- (void)getDetailsForStatus:(NSString *)statusID success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    [self sendGETWithUrl:url_statuses_show
              parameters:@{@"id": statusID}
                 success:success failure:failure];
}
- (void)lookupUsers:(NSArray *)users success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    [self sendGETWithUrl:url_users_lookup
              parameters:@{@"screen_name": [users componentsJoinedByString:@","]}
                 success:success failure:failure];
}
- (void)sendStatus:(NSString *)status inReplyToID:(NSString *)inReplyToID imageFilePath:(NSString *)imageFilePath location:(CLLocationCoordinate2D)location success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    if (imageFilePath) {
        [self sendPOSTWithUrl:url_statuses_update_with_media parameters:nil success:success failure:failure];
    } else {
        [self sendPOSTWithUrl:url_statuses_update parameters:nil success:success failure:failure];
    }
}
- (void)sendDirectMessage:(NSString *)message toUser:(NSString *)screenName success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    [self sendPOSTWithUrl:url_direct_messages_new
               parameters:@{@"text": message, @"screen_name": screenName}
                  success:success failure:failure];
}
- (void)sendRetweetWithStatusID:(NSString *)statusID success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    [self sendPOSTWithUrl:[NSString stringWithFormat:url_statuses_retweet, statusID]
               parameters:nil success:success failure:failure];
}
- (void)getFollowersSinceId:(NSString *)sinceID forUserScreenName:(NSString *)screenName success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    [self sendGETWithUrl:url_followers_ids parameters:nil success:^(id responseObj) {
        NSArray *users = responseObj;
        [self lookupUsers:users success:success failure:failure];
    } failure:failure];
}
- (void)getFriendsWithSuccess:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    [self sendGETWithUrl:url_friends_ids parameters:nil success:^(id responseObj) {
        NSArray *users = responseObj;
        [self lookupUsers:users success:success failure:failure];
    } failure:failure];
}
- (void)getSentMessagesSinceID:(NSString *)sinceID success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    [self sendGETWithUrl:url_direct_messages_sent parameters:nil success:success failure:failure];
}
- (void)getTrendsWithSuccess:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    [self sendGETWithUrl:url_trends_place parameters:nil success:success failure:failure];
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
    [self sendPOSTWithUrl:url_direct_messages_destroy
               parameters:@{@"id": messageID}
                  success:success failure:failure];
}
- (void)destroyStatus:(NSString *)statusID success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
{
    [self sendPOSTWithUrl:url_statuses_destroy
               parameters:@{@"id": statusID}
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
    
    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                            requestMethod:method
                                                      URL:[NSURL URLWithString:url]
                                               parameters:parameters];
    [request setAccount:self.account];
    
    [request performRequestWithHandler:^(NSData *responseData,
                                         NSHTTPURLResponse *urlResponse,
                                         NSError *error) {
        dispatch_sync(GCDMainThread, ^{
            if (responseData) {
                if (urlResponse.statusCode >= 200 && urlResponse.statusCode < 300) {
                    id responseObj = [NSJSONSerialization JSONObjectWithData:responseData
                                                                     options:NSJSONReadingAllowFragments
                                                                       error:nil];
                    if ([responseObj isKindOfClass:[NSArray class]] ||
                        [responseObj isKindOfClass:[NSDictionary class]]) {
                        dispatch_sync(GCDMainThread, ^{
                            success(responseObj);
                        });
                        return;
                    }
                } else {
                    [self dealWithError:error errTitle:@"Some problems with your network"];
                    failure(error);
                }
            }
        });
    }];
}

- (void)dealWithError:(NSError *)error errTitle:(NSString *)errTitle;
{
    NSLog(@"API Request Error %@", error);
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:errTitle delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [alert show];
}

- (NSDate *)getDateFromTwitterCreatedAt:(NSString *)twitterDate {
    return [self.dateFormatter dateFromString:twitterDate];
}

@end
