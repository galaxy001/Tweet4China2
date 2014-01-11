//
//  HSUListPersonsDataSource.m
//  Tweet4China
//
//  Created by Jason Hsu on 2013/12/2.
//  Copyright (c) 2013年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUListMembersDataSource.h"

@implementation HSUListMembersDataSource

- (instancetype)initWithList:(NSDictionary *)list
{
    self = [super init];
    if (self) {
        self.list = list;
    }
    return self;
}

-(void)fetchDataWithSuccess:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure
{
    [twitter getListMembersWithListID:self.list[@"id_str"] sinceID:self.nextCursor success:success failure:failure];
}

- (void)refresh
{
    [self loadMore];
}

@end
