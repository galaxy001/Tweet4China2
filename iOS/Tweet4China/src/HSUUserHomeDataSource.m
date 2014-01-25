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
    __weak typeof(self)weakSelf = self;
    [twitter getUserTimelineWithScreenName:self.screenName sinceID:nil count:self.requestCount success:^(id responseObj) {
        NSDictionary *tweet = [responseObj lastObject];
        if (tweet) {
            weakSelf.lastStatusID = tweet[@"id_str"];
        }
        success(responseObj);
    } failure:failure];
}

- (void)fetchMoreDataWithSuccess:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure
{
    __weak typeof(self)weakSelf = self;
    [twitter getUserTimelineWithScreenName:self.screenName maxID:self.lastStatusID count:self.requestCount success:^(id responseObj) {
        NSDictionary *tweet = [responseObj lastObject];
        if (tweet) {
            weakSelf.lastStatusID = tweet[@"id_str"];
        }
        success(responseObj);
    } failure:failure];
}

@end
