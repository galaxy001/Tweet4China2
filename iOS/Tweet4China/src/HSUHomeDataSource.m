//
//  HSUHomeDataSource.m
//  Tweet4China
//
//  Created by Jason Hsu on 3/14/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUHomeDataSource.h"
#import "HSUBaseViewController.h"

@implementation HSUHomeDataSource

+ (void)checkUnreadForViewController:(HSUBaseViewController *)viewController
{
    NSString *latestIdStr = [[NSUserDefaults standardUserDefaults] objectForKey:S(@"%@_first_id_str", self.cacheKey)];
    if (!latestIdStr) {
        latestIdStr = @"1";
    }
    [TWENGINE getHomeTimelineSinceID:latestIdStr count:1 success:^(id responseObj) {
        NSArray *tweets = responseObj;
        NSString *lastIdStr = tweets.lastObject[@"id_str"];
        if (lastIdStr) { // updated
            [viewController dataSourceDidFindUnread:nil];
        }
    } failure:^(NSError *error) {
        
    }];
}

- (void)fetchRefreshDataWithSuccess:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure
{
    NSString *latestIdStr = [self rawDataAtIndex:0][@"id_str"];
    if (!latestIdStr) {
        latestIdStr = @"1";
    }
    [TWENGINE getHomeTimelineSinceID:latestIdStr count:self.requestCount success:^(id responseObj) {
        success(responseObj);
        // ask follow author
        if (![[[NSUserDefaults standardUserDefaults] valueForKey:@"asked_follow_author"] boolValue]) {
            NSString *authorScreenName = @"tuoxie007";
            if ([TWENGINE.myScreenName isEqualToString:authorScreenName]) {
                return ;
            }
            [TWENGINE showUser:authorScreenName success:^(id responseObj) {
                NSDictionary *profile = responseObj;
                if (![profile[@"following"] boolValue]) {
                    RIButtonItem *cancelItem = [RIButtonItem itemWithLabel:_(@"Cancel")];
                    RIButtonItem *followItem = [RIButtonItem itemWithLabel:_(@"OK")];
                    followItem.action = ^{
                        [TWENGINE followUser:authorScreenName success:^(id responseObj) {
                        } failure:^(NSError *error) {
                        }];
                    };
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:_(@"Follow Author @tuoxie007")
                                                                    message:_(@"Get the latest activities about Tweet4China")
                                                           cancelButtonItem:cancelItem
                                                           otherButtonItems:followItem, nil];
                    [alert show];
                    [[NSUserDefaults standardUserDefaults] setValue:@YES forKey:@"asked_follow_author"];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                }
            } failure:^(NSError *error) {
                
            }];
        }
        // end ask
    } failure:^(NSError *error) {
        failure(error);
    }];
}

- (void)fetchMoreDataWithSuccess:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure
{
    HSUTableCellData *lastStatusData = [self dataAtIndex:self.count-2];
    NSString *lastStatusId = lastStatusData.rawData[@"id_str"];
    [TWENGINE getHomeTimelineWithMaxID:lastStatusId count:self.requestCount success:^(id responseObj) {
        success(responseObj);
    } failure:^(NSError *error) {
        failure(error);
    }];
}

-(void)saveCache
{
    [super saveCache];
    
    if (self.count) {
        NSString *firstIdStr = [self rawDataAtIndex:0][@"id_str"];
        [[NSUserDefaults standardUserDefaults] setObject:firstIdStr forKey:S(@"%@_first_id_str", [self.class cacheKey])];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

@end
