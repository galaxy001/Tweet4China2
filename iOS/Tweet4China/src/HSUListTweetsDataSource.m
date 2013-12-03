//
//  HSUListDataSource.m
//  Tweet4China
//
//  Created by Jason Hsu on 2013/12/2.
//  Copyright (c) 2013年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUListTweetsDataSource.h"

@implementation HSUListTweetsDataSource

- (instancetype)initWithListId:(NSString *)listId
{
    self = [super init];
    if (self) {
        self.listId = listId;
    }
    return self;
}

- (void)fetchRefreshDataWithSuccess:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure
{
    NSString *latestIdStr = [self rawDataAtIndex:0][@"id_str"];
    if (!latestIdStr) {
        latestIdStr = @"1";
    }
    [TWENGINE getListTimelineWithListID:self.listId sinceID:latestIdStr count:self.requestCount success:^(id responseObj) {
        success(responseObj);
    } failure:^(NSError *error) {
        failure(error);
    }];
}

- (void)fetchMoreDataWithSuccess:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure
{
    HSUTableCellData *lastStatusData = [self dataAtIndex:self.count-2];
    NSString *lastStatusId = lastStatusData.rawData[@"id_str"];
    [TWENGINE getListTimelineWithListID:self.listId maxID:lastStatusId count:self.requestCount success:^(id responseObj) {
        success(responseObj);
    } failure:^(NSError *error) {
        failure(error);
    }];
}

@end
