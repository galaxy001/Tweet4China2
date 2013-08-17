//
//  HSUFollowingDataSource.m
//  Tweet4China
//
//  Created by Jason Hsu on 5/3/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUFollowingDataSource.h"

@implementation HSUFollowingDataSource

-(void)fetchDataWithSuccess:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure
{
    [TWENGINE getFollowersSinceId:self.nextCursor forUserScreenName:self.screenName success:^(id responseObj) {
        success(responseObj);
    } failure:^(NSError *error) {
        failure(error);
    }];
}

@end
