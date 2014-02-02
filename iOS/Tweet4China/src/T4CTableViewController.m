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
#import "T4CGapCellData.h"
#import "T4CGapCell.h"
#import "T4CStatusViewController.h"
#import "HSUChatStatusCell.h"
#import "HSUMainStatusCell.h"
#import "T4CLoadingRepliedStatusCell.h"
#import "T4CNewFollowersCell.h"

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
        
        self.cellTypes = @{kDataType_Status: [HSUStatusCell class],
                           kDataType_Gap: [T4CGapCell class],
                           kDataType_ChatStatus: [HSUChatStatusCell class],
                           kDataType_MainStatus: [HSUMainStatusCell class],
                           kDataType_LoadingReply: [T4CLoadingRepliedStatusCell class],
                           kDataType_NewFollowers: [T4CNewFollowersCell class]};
        
        self.cellDataTypes = @{kDataType_Status: [T4CStatusCellData class],
                               kDataType_Gap: [T4CGapCellData class],
                               kDataType_ChatStatus: [T4CStatusCellData class],
                               kDataType_MainStatus: [T4CStatusCellData class]};
        
        self.data = @[].mutableCopy;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (!self.data.count) {
        [self refresh];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // register table view cell
    for (NSString *dataType in self.cellTypes) {
        [self.tableView registerClass:self.cellTypes[dataType] forCellReuseIdentifier:dataType];
    }
    
    __weak typeof(self)weakSelf = self;
    if (self.pullToRefresh) {
        [self.tableView addPullToRefreshWithActionHandler:^{
            [weakSelf refresh];
        }];
        self.tableView.pullToRefreshView.soundEffectEnabled = [setting(HSUSettingSoundEffect) boolValue];
        if (!self.tableView.pullToRefreshView.arrow) {
            self.tableView.pullToRefreshView.arrow = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icn_arrow_notif_dark"]];
        }
    }
    if (self.infiniteScrolling) {
        [self.tableView addInfiniteScrollingWithActionHandler:^{
            [weakSelf loadMore];
        }];
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

- (void)refresh
{
    self.refreshState = T4CLoadingState_Loading;
    NSMutableDictionary *params = self.requestParams.mutableCopy;
    if (self.topID) {
        params[@"since_id"] = @(self.topID);
    }
    if (self.requestCount) {
        params[@"count"] = @(self.requestCount);
    }
    __weak typeof(self)weakSelf = self;
    [twitter sendGETWithUrl:self.requestUrl parameters:params success:^(id responseObj) {
        if ([responseObj isKindOfClass:[NSDictionary class]]) {
            NSDictionary *responseDict = responseObj;
            NSString *nextCursor = responseDict[@"next_cursor"];
            if (nextCursor) { // page api
                self.bottomID = [nextCursor longLongValue];
            }
            NSArray *arrayData = responseDict[self.dataKey];
            arrayData = arrayData.count ? arrayData : nil;
            [weakSelf requestDidFinishRefreshWithData:arrayData];
            weakSelf.refreshState = arrayData ? T4CLoadingState_Done : T4CLoadingState_NoMore;
        } else if ([responseObj count]) {
            [weakSelf requestDidFinishRefreshWithData:responseObj];
            weakSelf.refreshState = T4CLoadingState_Done;
        } else {
            [weakSelf requestDidFinishRefreshWithData:nil];
            weakSelf.refreshState = T4CLoadingState_NoMore;
        }
    } failure:^(NSError *error) {
        if (error.code == 204) {
            [weakSelf requestDidFinishRefreshWithData:nil];
            weakSelf.refreshState = T4CLoadingState_NoMore;
        } else {
            [weakSelf requestDidFinishLoadingWithError:error];
            weakSelf.refreshState = T4CLoadingState_Error;
        }
    }];
}

- (void)loadGap:(T4CGapCellData *)gapCellData
{
    NSInteger gapIndex = [self.data indexOfObject:gapCellData];
    if (gapIndex <= 0 || gapIndex >= self.data.count-1) {
        return;
    }
    
    T4CTableCellData *gapTopData = self.data[gapIndex - 1];
    T4CTableCellData *gapBottomData = self.data[gapIndex + 1];
    long long gapTopID = [gapTopData.rawData[@"id"] longLongValue];
    long long gapBotID = [gapBottomData.rawData[@"id"] longLongValue];
    
    self.gapCellData = gapCellData;
    self.gapCellData.state = T4CLoadingState_Loading;
    NSMutableDictionary *params = self.requestParams.mutableCopy;
    params[@"max_id"] = @(gapTopID - 1);
    params[@"since_id"] = @(gapBotID);
    if (self.requestCount) {
        params[@"count"] = @(self.requestCount);
    }
    __weak typeof(self)weakSelf = self;
    [twitter sendGETWithUrl:self.requestUrl parameters:params success:^(id responseObj) {
        if ([responseObj isKindOfClass:[NSDictionary class]]) {
            NSDictionary *responseDict = responseObj;
            NSString *nextCursor = responseDict[@"next_cursor"];
            if (nextCursor) { // page api
                self.bottomID = [nextCursor longLongValue];
            }
            NSArray *arrayData = responseDict[self.dataKey];
            arrayData = arrayData.count ? arrayData : nil;
            [weakSelf requestDidFinishLoadGapWithData:arrayData];
            weakSelf.gapCellData.state = arrayData ? T4CLoadingState_Done : T4CLoadingState_NoMore;
        } else if ([responseObj count]) {
            [weakSelf requestDidFinishLoadGapWithData:responseObj];
            weakSelf.gapCellData.state = T4CLoadingState_Done;
        } else {
            [weakSelf requestDidFinishLoadMoreWithData:nil];
            weakSelf.gapCellData.state = T4CLoadingState_NoMore;
        }
    } failure:^(NSError *error) {
        if (error.code == 204) {
            [weakSelf requestDidFinishLoadGapWithData:nil];
            weakSelf.gapCellData.state = T4CLoadingState_NoMore;
        } else {
            [weakSelf requestDidFinishLoadingWithError:error];
            weakSelf.gapCellData.state = T4CLoadingState_Error;
        }
    }];
}

- (void)loadMore
{
    self.loadMoreState = T4CLoadingState_Loading;
    NSMutableDictionary *params = self.requestParams.mutableCopy;
    if (self.bottomID) {
        params[@"max_id"] = @(self.bottomID - 1);
    }
    if (self.requestCount) {
        params[@"count"] = @(self.requestCount);
    }
    __weak typeof(self)weakSelf = self;
    [twitter sendGETWithUrl:self.requestUrl parameters:params success:^(id responseObj) {
        if ([responseObj isKindOfClass:[NSDictionary class]]) {
            NSDictionary *responseDict = responseObj;
            NSString *nextCursor = responseDict[@"next_cursor"];
            if (nextCursor) { // page api
                self.bottomID = [nextCursor longLongValue];
            }
            NSArray *arrayData = responseDict[self.dataKey];
            arrayData = arrayData.count ? arrayData : nil;
            [weakSelf requestDidFinishLoadMoreWithData:arrayData];
            weakSelf.refreshState = arrayData ? T4CLoadingState_Done : T4CLoadingState_NoMore;
        } else if ([responseObj count]) {
            [weakSelf requestDidFinishLoadMoreWithData:responseObj];
            weakSelf.loadMoreState = T4CLoadingState_Done;
        } else {
            [weakSelf requestDidFinishLoadMoreWithData:nil];
            weakSelf.loadMoreState = T4CLoadingState_NoMore;
        }
    } failure:^(NSError *error) {
        if (error.code == 204) {
            [weakSelf requestDidFinishLoadMoreWithData:nil];
            weakSelf.loadMoreState = T4CLoadingState_NoMore;
        } else {
            [weakSelf requestDidFinishLoadingWithError:error];
            weakSelf.loadMoreState = T4CLoadingState_Error;
        }
    }];
}

// 数据经过解析之后，拿到数组才送到这里
- (void)requestDidFinishRefreshWithData:(NSArray *)dataArr
{
    if (dataArr.count) {
        NSDictionary *topData = dataArr.firstObject;
        long long topID = [topData[@"id"] longLongValue];
        self.topID = topID;
        
        NSDictionary *newBotData = dataArr.lastObject;
        long long newBotID = [newBotData[@"id"] longLongValue];
        
        NSDictionary *curTopData = [self.data.firstObject rawData];
        long long curTopID = [curTopData[@"id"] longLongValue];
        BOOL gapped = curTopID > 0 && newBotID > curTopID;
        BOOL inserted = self.data.count > 0;
        
        NSMutableArray *newDataArr = [NSMutableArray array];
        for (NSDictionary *rawData in dataArr) {
            [newDataArr addObject:[self createTableCellDataWithRawData:rawData]];
        }
        if (gapped) {
            [newDataArr addObject:[[T4CGapCellData alloc] initWithRawData:nil dataType:kDataType_Gap]];
        }
        [newDataArr addObjectsFromArray:self.data];
        self.data = newDataArr;
        
        NSDictionary *botData = [self.data.lastObject rawData];
        self.bottomID = [botData[@"id"] longLongValue];
        
        [self.tableView reloadData];
        if (inserted) {
            [self scrollTableViewToCurrentOffsetAfterInsertNewCellCount:dataArr.count+(gapped?1:0)];
        }
    }
    [self.tableView.pullToRefreshView stopAnimating];
}

- (void)requestDidFinishLoadGapWithData:(NSArray *)dataArr
{
    if (dataArr.count) {
        NSUInteger gapIndex = [self.data indexOfObject:self.gapCellData];
        NSIndexSet *set = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(gapIndex, dataArr.count)];
        NSMutableArray *newData = [NSMutableArray arrayWithCapacity:dataArr.count];
        for (NSDictionary *rawData in dataArr) {
            [newData addObject:[self createTableCellDataWithRawData:rawData]];
        }
        [self.data insertObjects:newData atIndexes:set];
        
        [self.tableView reloadData];
        [self scrollTableViewToCurrentOffsetAfterInsertNewCellCount:dataArr.count];
    }
}

- (void)requestDidFinishLoadMoreWithData:(NSArray *)dataArr
{
    if (dataArr.count) {
        NSDictionary *bottomData = dataArr.lastObject;
        long long bottomID = [bottomData[@"id"] longLongValue];
        
        self.bottomID = bottomID;
        for (NSDictionary *rawData in dataArr) {
            [self.data addObject:[self createTableCellDataWithRawData:rawData]];
        }
        
        [self.tableView reloadData];
    }
    [self.tableView.infiniteScrollingView stopAnimating];
}

// 真有错误才到这里，204不算的，一般是网络错误
- (void)requestDidFinishLoadingWithError:(NSError *)error
{
    NSLog(@"Error: %@", error);
}

- (void)scrollTableViewToCurrentOffsetAfterInsertNewCellCount:(NSUInteger)count
{
    if (self.data.count) {
        CGRect visibleRect = ccr(0, self.tableView.contentOffset.y+self.tableView.contentInset.top,
                                 self.tableView.width, self.tableView.height);
        NSArray *indexPathsVisibleRows = [self.tableView indexPathsForRowsInRect:visibleRect];
        NSIndexPath *firstIndexPath = indexPathsVisibleRows[0];
        NSInteger firstRow = firstIndexPath.row + count;
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:firstRow inSection:0]
                              atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
    }
}

- (T4CTableCellData *)createTableCellDataWithRawData:(NSDictionary *)rawData
{
    Class dataClass = self.cellDataTypes[[self dataTypeOfData:rawData]] ?: [T4CTableCellData class];
    T4CTableCellData *celldata = [[dataClass alloc] init];
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    T4CTableCellData *cellData = self.data[indexPath.row];
    if ([cellData.dataType isEqualToString:kDataType_Gap]) {
        T4CGapCellData *gapCellData = (T4CGapCellData *)cellData;
        [self loadGap:gapCellData];
    } else if ([cellData.dataType isEqualToString:kDataType_Status] ||
               [cellData.dataType isEqualToString:kDataType_ChatStatus]) {
        T4CStatusViewController *statusVC = [[T4CStatusViewController alloc] init];
        statusVC.status = cellData.rawData;
        [self.navigationController pushViewController:statusVC animated:YES];
    }
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

- (NSString *)requestUrlWithAPIString:(NSString *)apiString
{
    return [NSString stringWithFormat:@"https://api.twitter.com/1.1/%@.json", apiString];
}

- (NSString *)requestUrl
{
    return [self requestUrlWithAPIString:self.apiString];
}

- (void)addEventWithName:(NSString *)name target:(id)target action:(SEL)action events:(UIControlEvents)events
{
    for (uint i=0; i<self.data.count; i++) {
        HSUUIEvent *cellEvent = [[HSUUIEvent alloc] initWithName:name target:target action:action events:events];
        cellEvent.cellData = self.data[i];
        cellEvent.cellData.events[name] = cellEvent;
    }
}

@end
