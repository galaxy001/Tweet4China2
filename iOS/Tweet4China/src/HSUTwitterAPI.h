//
//  HSUTwitterAPI.h
//  Tweet4China
//
//  Created by Jason Hsu on 13/7/22.
//  Copyright (c) 2013年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

typedef void (^HSUTwitterAPISuccessBlock)(id responseObj);
typedef void (^HSUTwitterAPIFailureBlock)(NSError *error);

@interface HSUTwitterAPI : NSObject

+ (instancetype)shared;
- (BOOL)isAuthorized;
- (NSString *)myScreenName;
- (void)signOut;

- (void)getUserSettingsWithSuccess:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
- (void)getHomeTimelineWithMaxID:(NSString *)maxID count:(int)count success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
- (void)getHomeTimelineSinceID:(NSString *)sinceID count:(int)count success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
- (void)getMentionsTimelineSinceID:(NSString *)sinceID maxID:(NSString *)maxID count:(NSUInteger)count success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
- (void)getUserTimelineWithScreenName:(NSString *)screenName sinceID:(NSString *)sinceID count:(int)count success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
- (void)getUserTimelineWithScreenName:(NSString *)screenName maxID:(NSString *)maxID count:(int)count success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
- (void)getFavoritesWithScreenName:(NSString *)screenName sinceID:(NSString *)sinceID count:(int)count success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
- (void)getFavoritesWithScreenName:(NSString *)screenName maxID:(NSString *)maxID count:(int)count success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
- (void)getDirectMessagesSinceID:(NSString *)sinceID success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;

- (void)getDetailsForStatus:(NSString *)statusID success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
- (void)lookupUsers:(NSArray *)userScreenNames success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
- (void)lookupUser:(NSString *)screenName success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;

- (void)sendStatus:(NSString *)status inReplyToID:(NSString *)inReplyToID imageFilePath:(NSString *)imageFilePath location:(CLLocationCoordinate2D)location success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
- (void)sendDirectMessage:(NSString *)message toUser:(NSString *)screenName success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
- (void)sendRetweetWithStatusID:(NSString *)statusID success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;

- (void)getFollowersSinceId:(NSString *)sinceID forUserScreenName:(NSString *)screenName success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
- (void)getFollowingsSinceId:(NSString *)sinceID forUserScreenName:(NSString *)screenName success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;;
- (void)getFriendsWithSuccess:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
- (void)getSentMessagesSinceID:(NSString *)sinceID success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
- (void)getTrendsWithSuccess:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;

- (void)blockUser:(NSString *)screenName success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
- (void)unblockuser:(NSString *)screenName success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
- (void)followUser:(NSString *)screenName success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
- (void)unFollowUser:(NSString *)screenName success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
- (void)markStatus:(NSString *)statusID success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
- (void)unMarkStatus:(NSString *)statusID success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
- (void)reportUserAsSpam:(NSString *)screenName success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;

- (void)deleteDirectMessage:(NSString *)messageID success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
- (void)destroyStatus:(NSString *)statusID success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;

- (void)sendGETWithUrl:(NSString *)url parameters:(NSDictionary *)parameters success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;
- (void)sendPOSTWithUrl:(NSString *)url parameters:(NSDictionary *)parameters success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure;

- (void)dealWithError:(NSError *)error errTitle:(NSString *)errTitle;

- (NSDate *)getDateFromTwitterCreatedAt:(NSString *)twitterDate;

@end
