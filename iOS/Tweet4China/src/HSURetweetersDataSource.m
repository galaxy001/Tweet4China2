//
//  HSURetweetersDataSource.m
//  Tweet4China
//
//  Created by Jason Hsu on 14-1-12.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSURetweetersDataSource.h"

@implementation HSURetweetersDataSource

- (void)fetchDataWithSuccess:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure
{
    [twitter getRetweetsForStatus:self.statusID count:100 success:^(id responseObj) {
        NSMutableArray *users = [NSMutableArray array];
        for (NSDictionary *tweet in responseObj) {
            NSDictionary *user = tweet[@"user"];
            [users addObject:user];
        }
        success(users);
    } failure:failure];
}

@end
