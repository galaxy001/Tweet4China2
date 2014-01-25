//
//  T4CViewController.m
//  Tweet4China
//
//  Created by Jason Hsu on 14-1-14.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "T4CTableViewController.h"
#import "HSUStatusCell.h"
#import "HSUBaseTableCell.h"
#import <SVPullToRefresh/SVPullToRefresh.h>
#import <Reachability/Reachability.h>

@interface T4CTableViewController ()

@property (nonatomic, strong) NSDictionary *cellTypes;
@property (nonatomic, strong) NSDictionary *cellDataTypes;

@end

@implementation T4CTableViewController

- (id)init
{
    self = [super init];
    if (self) {
        self.pullToRefresh = YES;
        self.infiniteScrolling = YES;
        self.cellTypes = @{kDataType_Status: [HSUStatusCell class]};
        self.cellDataTypes = @{kDataType_Status: [T4CStatusCellData class]};
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // register table view cell
    for (NSString *dataType in self.cellTypes) {
        [self.tableView registerClass:self.cellTypes[dataType] forCellReuseIdentifier:dataType];
    }
    
    if (self.pullToRefresh) {
        [self.tableView addPullToRefreshWithActionHandler:^{
            
        }];
        self.tableView.pullToRefreshView.soundEffectEnabled = YES;
        self.tableView.pullToRefreshView.arrow = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icn_arrow_notif_dark"]];
    }
    if (self.infiniteScrolling) {
        [self.tableView addInfiniteScrollingWithActionHandler:^{
            
        }];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (!self.data.count) {
        [self refresh];
    }
}

// 里面装的是cell data array
- (NSMutableArray *)data
{
    if (_data == nil) {
        _data = [NSMutableArray array];
    }
    return _data;
}

// 发送请求的函数
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
    NSString *url = [NSString stringWithFormat:@"https://api.twitter.com/1.1/%@.json", self.requestUrl];
    __weak typeof(self)weakSelf = self;
    [twitter sendGETWithUrl:url parameters:params success:^(id responseObj) {
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
        if (error.code == 204) {
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

- (void)refresh
{
    __weak typeof(self)weakSelf = self;
    self.refreshState = T4CLoadingState_Loading;
    [self loadWithMinID:self.topID maxID:0 count:self.requestCount finish:^(T4CLoadingState state) {
        weakSelf.refreshState = state;
    }];
}

- (void)loadMore
{
    __weak typeof(self)weakSelf = self;
    self.loadMoreState = T4CLoadingState_Loading;
    [self loadWithMinID:0 maxID:self.bottomID count:self.requestCount finish:^(T4CLoadingState state) {
        weakSelf.loadMoreState = state;
    }];
}

// 数据经过解析之后，拿到数组才送到这里
- (void)requestDidFinishLoadingWithData:(NSArray *)dataArr
{
    if (dataArr.count) {
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
        [self.tableView reloadData];
    }
}

// 真有错误才到这里，204不算的，一般是网络错误
- (void)requestDidFinishLoadingWithError:(NSError *)error
{
    NSLog(@"Error: %@", error);
}

- (T4CTableCellData *)createTableCellDataWithRawData:(NSDictionary *)rawData
{
    T4CTableCellData *celldata = [[self.cellDataTypes[[self dataTypeOfData:rawData]] alloc] init];
    celldata.dataType = [self dataTypeOfData:rawData];
    celldata.rawData = rawData;
    return celldata;
}

- (NSString *)dataTypeOfData:(NSDictionary *)data
{
    if (data[@"text"]) {
        return kDataType_Status;
    } else if (data[@"recipient"]) {
        return kDataType_Message;
    } else if (data[@"member_count"]) {
        return kDataType_List;
    } else if (data[@"profile_image_url"]) {
        return kDataType_Person;
    } else if (data[@"status"]) {
        return kDataType_Draft;
    }
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.data.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    T4CTableCellData *cellData = self.data[indexPath.row];
    return [self.cellTypes[cellData.dataType] heightForData:cellData];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    T4CTableCellData *cellData = self.data[indexPath.row];
    HSUBaseTableCell *cell = (HSUBaseTableCell *)[tableView dequeueReusableCellWithIdentifier:cellData.dataType];
    [cell setupWithData:cellData];
    return cell;
}

- (BOOL)filterData:(NSDictionary *)data
{
    return YES;
}

- (NSDictionary *)requestParams
{
    return @{};
}

- (NSUInteger)requestCount
{
    if ([Reachability reachabilityForInternetConnection].isReachableViaWiFi) {
        return [setting(HSUSettingPageCount) integerValue] ?: kRequestDataCountViaWifi;
    } else {
        return [setting(HSUSettingPageCountWWAN) integerValue] ?: kRequestDataCountViaWWAN;
    }
}

@end
