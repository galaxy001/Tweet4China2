//
//  HSUDirectMessagePersonsDataSource.m
//  Tweet4China
//
//  Created by Jason Hsu on 14-1-5.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUDirectMessagePersonsDataSource.h"

@implementation HSUDirectMessagePersonsDataSource

- (void)fetchDataWithSuccess:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure
{
    if (self.keyword.length) {
        [super fetchDataWithSuccess:success failure:failure];
    } else {
        // find friends
        if (!self.friends) {
            // use cache
            self.friends = [[NSUserDefaults standardUserDefaults] objectForKey:@"friends"];
            if (self.friends) {
                success(self.friends);
            }
            // update
            __weak typeof(self) weakSelf = self;
            [twitter getFriendsWithCount:100 success:^(id responseObj) {
                // update cache
                weakSelf.friends = responseObj[@"users"];
                [[NSUserDefaults standardUserDefaults] setObject:weakSelf.friends forKey:@"friends"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                
                if (!weakSelf.keyword.length) {
                    success(weakSelf.friends);
                }
            } failure:^(NSError *error) {
                failure(error);
            }];
        } else {
            // use cache
            success(self.friends);
        }
    }
}

@end
