//
//  HSUFavoritesDataSource.m
//  Tweet4China
//
//  Created by Jason Hsu on 13-9-14.
//  Copyright (c) 2013年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUFavoritesDataSource.h"

@implementation HSUFavoritesDataSource

- (id)initWithScreenName:(NSString *)screenName
{
    self = [super init];
    if (self) {
        self.screenName = screenName;
    }
    return self;
}

- (void)fetchRefreshDataWithSuccess:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure
{
    __weak typeof(self)weakSelf = self;
    [twitter getFavoritesWithScreenName:self.screenName sinceID:nil count:self.requestCount success:^(id responseObj) {
        NSDictionary *tweet = [responseObj lastObject];
        if (tweet) {
            weakSelf.lastStatusID = tweet[@"id_str"];
        }
        success(responseObj);
    } failure:^(NSError *error) {
        failure(error);
    }];
}

- (void)fetchMoreDataWithSuccess:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure
{
    __weak typeof(self)weakSelf = self;
    [twitter getFavoritesWithScreenName:self.screenName maxID:self.lastStatusID count:self.requestCount success:^(id responseObj) {
        NSDictionary *tweet = [responseObj lastObject];
        if (tweet) {
            weakSelf.lastStatusID = tweet[@"id_str"];
        }
        success(responseObj);
    } failure:^(NSError *error) {
        failure(error);
    }];
}

@end
