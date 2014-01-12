//
//  HSUSearchTweetsDataSource.m
//  Tweet4China
//
//  Created by Jason Hsu on 14-1-12.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUSearchTweetsDataSource.h"

@implementation HSUSearchTweetsDataSource

- (void)fetchMoreDataWithSuccess:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure
{
    __weak typeof(self)weakSelf = self;
    [twitter searchTweetsWithKeyword:self.keyword sinceID:self.lastStatusID count:100 success:^(id responseObj) {
        NSArray *tweets = responseObj[@"statuses"];
        NSDictionary *tweet = tweets.lastObject;
        if (tweet) {
            weakSelf.lastStatusID = tweet[@"id_str"];
        }
        success(tweets);
    } failure:failure];
}

- (void)fetchRefreshDataWithSuccess:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure
{
    [self fetchMoreDataWithSuccess:success failure:failure];
}

@end
