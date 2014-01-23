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
    if (![self.keyword length]) {
        success(@[]);
        return;
    }
    NSString *keyword = self.keyword;
    __weak typeof(self)weakSelf = self;
    [twitter searchTweetsWithKeyword:self.keyword sinceID:self.lastStatusID count:100 success:^(id responseObj) {
        if (![weakSelf.keyword isEqualToString:keyword]) {
            return ;
        }
        NSArray *tweets = responseObj[@"statuses"];
        NSDictionary *tweet = tweets.lastObject;
        if (tweet) {
            weakSelf.lastStatusID = tweet[@"id_str"];
        }
        success(tweets);
    } failure:^(NSError *error) {
        if (![weakSelf.keyword isEqualToString:keyword]) {
            return ;
        }
        failure(error);
    }];
}

- (void)fetchRefreshDataWithSuccess:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure
{
    [self.data removeAllObjects];
    [self.delegate reloadData];
    [self fetchMoreDataWithSuccess:success failure:failure];
}

@end
