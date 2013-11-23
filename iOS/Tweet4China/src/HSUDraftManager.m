//
//  HSUDraftManager.m
//  Tweet4China
//
//  Created by Jason Hsu on 5/14/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUDraftManager.h"
#import "NSString+MD5.h"
#import "HSUDraftsViewController.h"
#import "OARequestParameter.h"
#import "HSUTabController.h"

@implementation HSUDraftManager

+ (id)shared
{
    static dispatch_once_t onceQueue;
    static HSUDraftManager *hSUDraftManager = nil;
    
    dispatch_once(&onceQueue, ^{ hSUDraftManager = [[self alloc] init]; });
    return hSUDraftManager;
}

- (NSDictionary *)saveDraftWithDraftID:(NSString *)draftID
                                 title:(NSString *)title
                                status:(NSString *)status
                         imageFilePath:(NSString *)imageFilePath
                                 reply:(NSString *)reply
                            locationXY:(CLLocationCoordinate2D)locationXY
                               placeId:(NSString *)placeId
{
    if (!draftID) {
        draftID = [status MD5Hash];
    }
    NSDictionary *drafts = [[NSUserDefaults standardUserDefaults] objectForKey:@"drafts"];
    if (!drafts) {
        drafts = [[NSMutableDictionary alloc] init];
    } else {
        drafts = [drafts mutableCopy];
    }
    NSMutableDictionary *draft = [[NSMutableDictionary alloc] init];
    draft[@"status"] = status;
    draft[@"id"] = draftID;
    if (title) draft[@"title"] = title;
    if (imageFilePath) draft[@"image_file_path"] = imageFilePath;
    if (reply) draft[kTwitterReplyID_ParameterKey] = reply;
    if (locationXY.latitude) draft[@"lat"] = S(@"%g", locationXY.latitude);
    if (locationXY.longitude) draft[@"long"] = S(@"%g", locationXY.longitude);
    if (placeId) draft[@"place_id"] = placeId;
    draft[@"update_time"] = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]];
    ((NSMutableDictionary *)drafts)[draftID] = draft;
    [[NSUserDefaults standardUserDefaults] setObject:drafts forKey:@"drafts"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    return draft;
}

- (NSDictionary *)saveDraftWithDraftID:(NSString *)draftID
                                 title:(NSString *)title
                                status:(NSString *)status
                             imageData:(NSData *)imageData
                                 reply:(NSString *)reply
                            locationXY:(CLLocationCoordinate2D)locationXY
                               placeId:(NSString *)placeId
{
    NSString *filePath = nil;
    if (imageData) {
        NSString *dir = dp(@"drafts");
        [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:0 error:nil];
        filePath = dp(S(@"drafts/%@", imageData.md5));
        [imageData writeToFile:filePath atomically:YES];
    }
    return [self saveDraftWithDraftID:draftID title:title status:status imageFilePath:filePath reply:reply locationXY:locationXY placeId:placeId];
}


- (void)activeDraft:(NSDictionary *)draft
{
    [self activeDraftWithID:draft[@"id"]];
}

- (void)activeDraftWithID:(NSString *)draftID
{
    NSMutableDictionary *drafts = [[[NSUserDefaults standardUserDefaults] objectForKey:@"drafts"] mutableCopy];
    NSMutableDictionary *draft = [drafts[draftID] mutableCopy];
    draft[@"active"] = @(YES);
    drafts[draftID] = draft;
    [[NSUserDefaults standardUserDefaults] setObject:drafts forKey:@"drafts"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    notification_post(HSUDraftsCountChangedNotification);
}

- (BOOL)removeDraft:(NSDictionary *)draft
{
    NSString *draftID = draft[@"id"];
    if (!draftID) {
        draftID = [draft[@"status"] MD5Hash];
    }
    NSString *imageFilePath = draft[@"image_file_path"];
    [[NSFileManager defaultManager] removeItemAtPath:imageFilePath error:nil];
    return [self removeDraftWithID:draftID];
}

- (BOOL)removeDraftWithID:(NSString *)draftID
{
    if (!draftID) {
        return NO;
    }
    NSMutableDictionary *drafts = [[[NSUserDefaults standardUserDefaults] objectForKey:@"drafts"] mutableCopy];
    if (drafts) {
        [drafts removeObjectForKey:draftID];
        [[NSUserDefaults standardUserDefaults] setObject:drafts forKey:@"drafts"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        notification_post(HSUDraftsCountChangedNotification);
    }
    return YES;
}

- (NSArray *)draftsSortedByUpdateTime
{
    NSDictionary *drafts = [[NSUserDefaults standardUserDefaults] objectForKey:@"drafts"];
    NSMutableArray *draftArr = [[NSMutableArray alloc] initWithCapacity:drafts.count];
    for (NSString *dID in drafts.allKeys) {
        NSDictionary *draft = drafts[dID];
        if ([draft[@"active"] boolValue]) {
            [draftArr addObject:draft];
        }
    }
    [draftArr sortUsingComparator:^NSComparisonResult(NSDictionary *d1, NSDictionary *d2) {
        return [d1[@"update_time"] doubleValue] - [d2[@"update_time"] doubleValue];
    }];
    return draftArr;
}

- (void)presentDraftsViewController
{
    UINavigationController *nav = DEF_NavitationController_Light;
    nav.viewControllers = @[[[HSUDraftsViewController alloc] init]];
    [[HSUAppDelegate shared].tabController presentViewController:nav animated:YES completion:nil];
}

- (void)sendDraft:(NSDictionary *)draft success:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure
{
    CLLocationCoordinate2D location = CLLocationCoordinate2DMake([draft[@"lat"] doubleValue], [draft[@"long"] doubleValue]);
    [TWENGINE sendStatus:draft[@"status"] inReplyToID:draft[kTwitterReplyID_ParameterKey] imageFilePath:draft[@"image_file_path"] location:location placeId:draft[@"place_id"] success:^(id responseObj) {
        success(responseObj);
    } failure:^(NSError *error) {
        failure(error);
    }];
}

@end
