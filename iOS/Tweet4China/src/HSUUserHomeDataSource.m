//
//  HSUUserHomeDataSource.m
//  Tweet4China
//
//  Created by Jason Hsu on 5/3/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUUserHomeDataSource.h"

@implementation HSUUserHomeDataSource

- (void)fetchRefreshDataWithSuccess:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure
{
    [TWENGINE getHomeTimelineSinceID:nil count:self.requestCount success:^(id responseObj) {
        NSDictionary *tweet = [responseObj lastObject];
        self.lastStatsuID = tweet[@"id_str"];
        success(responseObj);
    } failure:^(NSError *error) {
        failure(error);
    }];
}

- (void)fetchMoreDataWithSuccess:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure
{
    [TWENGINE getHomeTimelineWithMaxID:self.lastStatsuID count:self.requestCount success:^(id responseObj) {
        NSDictionary *tweet = [responseObj lastObject];
        self.lastStatsuID = tweet[@"id_str"];
        success(responseObj);
    } failure:^(NSError *error) {
        failure(error);
    }];
}

- (void)saveCache
{
    
}

@end
