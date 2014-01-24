//
//  T4CViewController.m
//  Tweet4China
//
//  Created by Jason Hsu on 14-1-14.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "T4CViewController.h"

@interface T4CViewController ()

@end

@implementation T4CViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (NSMutableArray *)data
{
    if (_data == nil) {
        _data = [NSMutableArray array];
    }
    return _data;
}

- (void)loadWithMinID:(NSUInteger)minID maxID:(NSUInteger)maxID count:(NSUInteger)count finish:(void(^)(T4CLoadingState state))finish
{
    NSMutableDictionary *params = self.requestParams.mutableCopy;
    if (minID) {
        params[@"since_id"] = @(minID);
    }
    if (maxID) {
        params[@"max_id"] = @(maxID - 1);
        params[@"cursor"] = @(maxID);
    }
    if (count) {
        params[@"count"] = @(count);
    }
    __weak typeof(self)weakSelf = self;
    [twitter sendGETWithUrl:self.requestUrl parameters:params success:^(id responseObj) {
        T4CLoadingState state;
        if ([responseObj isKindOfClass:[NSDictionary class]]) {
            NSDictionary *responseDict = responseObj;
            NSString *nextCursor = responseDict[@"next_cursor"];
            if (nextCursor) { // page api
                self.bottomID = [nextCursor longLongValue];
            }
            NSArray *arrayData = responseDict[self.dataKey];
            arrayData = arrayData.count ? arrayData : nil;
            [weakSelf requestDidFinishLoadingWithData:arrayData];
            state = arrayData ? T4CLoadingState_Done : T4CLoadingState_NoMore;
        } else {
            NSArray *arrayData = [responseObj count] ? responseObj : nil;
            [weakSelf requestDidFinishLoadingWithData:arrayData];
            state = arrayData ? T4CLoadingState_Done : T4CLoadingState_NoMore;
        }
        if (finish) {
            finish(state);
        }
    } failure:^(NSError *error) {
        T4CLoadingState state;
        if ([error code] == 204) {
            [weakSelf requestDidFinishLoadingWithData:nil];
            state = T4CLoadingState_NoMore;
        } else {
            [weakSelf requestDidFinishLoadingWithError:error];
            state = T4CLoadingState_Error;
        }
        if (finish) {
            finish(state);
        }
    }];
}

- (void)loadWithMinID:(NSUInteger)minID maxID:(NSUInteger)maxID finish:(void(^)(T4CLoadingState state))finish
{
    [self loadWithMinID:minID maxID:maxID count:self.requestCount finish:finish];
}

- (void)refresh
{
    __weak typeof(self)weakSelf = self;
    self.refreshState = T4CLoadingState_Loading;
    [self loadWithMinID:self.topID maxID:0 finish:^(T4CLoadingState state) {
        weakSelf.refreshState = state;
    }];
}

- (void)loadMore
{
    __weak typeof(self)weakSelf = self;
    self.loadMoreState = T4CLoadingState_Loading;
    [self loadWithMinID:0 maxID:self.bottomID finish:^(T4CLoadingState state) {
        weakSelf.loadMoreState = state;
    }];
}

- (void)requestDidFinishLoadingWithData:(NSArray *)dataArr
{
    NSDictionary *topData = dataArr.firstObject;
    long topID = [topData[@"id"] longValue];
    NSDictionary *bottomData = dataArr.lastObject;
    long bottomID = [bottomData[@"id"] longValue];
    
    if (bottomID > self.topID) { // refresh
        self.topID = topID;
        NSMutableArray *newDataArr = [NSMutableArray array];
        for (NSDictionary *rawData in dataArr) {
            [newDataArr addObject:[self createTableCellDataWithRawData:rawData]];
        }
        [newDataArr addObjectsFromArray:self.data];
        self.data = newDataArr;
    } else { // load more
        self.bottomID = bottomID;
        for (NSDictionary *rawData in dataArr) {
            [self.data addObject:[self createTableCellDataWithRawData:rawData]];
        }
    }
}

- (void)requestDidFinishLoadingWithError:(NSError *)error
{
    
}

- (T4CTableCellData *)createTableCellDataWithRawData:(NSDictionary *)rawData
{
    T4CTableCellData *celldata = [[T4CTableCellData alloc] init];
    celldata.dataType = self.dataType;
    celldata.rawData = rawData;
    return celldata;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.data.count ? self.data.count + 1 : 0;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForFooterInSection:(NSInteger)section
{
    return 44;
}

- (BOOL)filterData:(NSDictionary *)data
{
    return YES;
}

@end
