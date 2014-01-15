//
//  HSUListDataSource.m
//  Tweet4China
//
//  Created by Jason Hsu on 2013/12/2.
//  Copyright (c) 2013年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUListTweetsDataSource.h"

@implementation HSUListTweetsDataSource

- (instancetype)initWithList:(NSDictionary *)list
{
    self = [super init];
    if (self) {
        self.list = list;
    }
    return self;
}

- (void)fetchRefreshDataWithSuccess:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure
{
    NSString *latestIdStr = [self rawDataAtIndex:0][@"id_str"];
    if (!latestIdStr) {
        latestIdStr = @"1";
    }
    [twitter getListTimelineWithListID:self.list[@"id_str"] sinceID:latestIdStr count:self.requestCount success:success failure:failure];
}

- (void)fetchMoreDataWithSuccess:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure
{
    HSUTableCellData *lastStatusData = [self dataAtIndex:self.count-2];
    NSString *lastStatusId = lastStatusData.rawData[@"id_str"];
    [twitter getListTimelineWithListID:self.list[@"id_str"] maxID:lastStatusId count:self.requestCount success:success failure:failure];
}

@end
