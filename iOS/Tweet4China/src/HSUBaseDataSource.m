//
//  HSUBaseDataSource.m
//  Tweet4China
//
//  Created by Jason Hsu on 3/10/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUBaseDataSource.h"
#import "HSUBaseTableCell.h"

@implementation HSUBaseDataSource

- (void)dealloc
{
    notification_remove_observer(self);
}

- (id)init
{
    self = [super init];
    if (self) {
        self.requestCount = 200;
        self.data = [[NSMutableArray alloc] init];
        notification_add_observer(HSUSettingsUpdatedNotification, self, @selector(settingsUpdated:));
        notification_add_observer(HSUTwiterLoginSuccess, self, @selector(twitterLoginSuccess:));
        notification_add_observer(HSUTwiterLogout, self, @selector(twitterLogout));
    }
    return self;
}

#pragma mark - TableView
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!self.loadingCount && self.count > 1) {
        HSUTableCellData *cellData = [self dataAtIndex:indexPath.row];
        if ([cellData.dataType isEqualToString:kDataType_LoadMore] &&
            [cellData.rawData[@"status"] integerValue] == kLoadMoreCellStatus_Done) {
            
            cellData.rawData = @{@"status": @(kLoadMoreCellStatus_Loading)};
            [self loadMore];
        }
    }
    
    HSUTableCellData *cellData = [self dataAtIndexPath:indexPath];
    HSUBaseTableCell *cell = (HSUBaseTableCell *)[tableView dequeueReusableCellWithIdentifier:cellData.dataType];
    [cell setupWithData:cellData];
    
    if (IPAD) {
        if (indexPath.section == 0 && indexPath.row == self.count - 1) {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
            if (iOS_Ver >= 7) {
                cell.separatorInset = edi(0, tableView.width, 0, 0);
            }
#endif
        }
    }
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return self.data.count;
    }
    return 0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

#pragma mark - Data
- (NSArray *)allData
{
    return self.data;
}

- (HSUTableCellData *)dataAtIndex:(NSInteger)index
{
    if (self.data.count > index) {
        return self.data[index];
    }
    // Warn
    return nil;
}

- (HSUTableCellData *)dataAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section) {
        return nil;
    }
    return [self dataAtIndex:indexPath.row];
}

- (NSMutableDictionary *)renderDataAtIndex:(NSInteger)index;
{
    return [self dataAtIndex:index].renderData;
}

- (NSMutableDictionary *)renderDataAtIndexPath:(NSIndexPath *)indexPath
{
    return [self dataAtIndexPath:indexPath].renderData;
}

- (NSInteger)count
{
    return self.data.count;
}

- (NSDictionary *)rawDataAtIndex:(NSInteger)index
{
    return [self dataAtIndex:index].rawData;
}

- (NSDictionary *)rawDataAtIndexPath:(NSIndexPath *)indexPath
{
    return [self dataAtIndexPath:indexPath].rawData;
}

- (void)addEventWithName:(NSString *)name target:(id)target action:(SEL)action events:(UIControlEvents)events
{
    for (uint i=0; i<self.count; i++) {
        HSUUIEvent *cellEvent = [[HSUUIEvent alloc] initWithName:name target:target action:action events:events];
        cellEvent.cellData = [self dataAtIndex:i];
        [self renderDataAtIndex:i][name] = cellEvent;
    }
}

- (void)refresh
{
    self.loadingCount ++;
    notification_post(HSUStartRefreshingNotification);
}

- (void)loadMore
{
    self.loadingCount ++;
}

- (void)loadFromIndex:(NSInteger)startIndex toIndex:(NSInteger)endIndex
{
    
}

- (void)saveCache
{
    uint cacheSize = kRequestDataCountViaWifi;
    NSMutableArray *cacheDataArr = [NSMutableArray arrayWithCapacity:cacheSize];
    for (HSUTableCellData *cellData in self.data) {
        if (cacheDataArr.count < cacheSize) {
            if (![cellData.dataType isEqualToString:kDataType_LoadMore]) {
                [cacheDataArr addObject:cellData.cacheData];
            }
        } else {
            break;
        }
    }
    if (cacheDataArr.count) {
        [[NSUserDefaults standardUserDefaults] setObject:cacheDataArr forKey:self.class.cacheKey];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:self.class.cacheKey];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSString *)cacheKey
{
    return self.description.lowercaseString;
}

+ (id)dataSourceWithDelegate:(id<HSUBaseDataSourceDelegate>)delegate useCache:(BOOL)useCahce
{
    HSUBaseDataSource *dataSource = [[self alloc] init];
    dataSource.delegate = delegate;
    if (!TWENGINE.isAuthorized) {
        return dataSource;
    }
    if (useCahce) {
        NSArray *cacheDataArr = [[NSUserDefaults standardUserDefaults] arrayForKey:self.cacheKey];
        if (cacheDataArr) {
            NSMutableArray *mData = [NSMutableArray arrayWithCapacity:cacheDataArr.count];
            for (NSDictionary *cacheData in cacheDataArr) {
                [mData addObject:[[HSUTableCellData alloc] initWithCacheData:cacheData]];
            }
            if (![((HSUTableCellData *)mData.lastObject).dataType isEqualToString:kDataType_LoadMore]) {
                HSUTableCellData *loadMoreCellData = [[HSUTableCellData alloc] init];
                loadMoreCellData.rawData = @{@"status": @(kLoadMoreCellStatus_Done)};
                loadMoreCellData.dataType = kDataType_LoadMore;
                [mData addObject:loadMoreCellData];
            }
            dataSource.data = mData;
        }
        [dataSource.delegate preprocessDataSourceForRender:dataSource];
    }
    return dataSource;
}

- (void)removeCellData:(HSUTableCellData *)cellData
{
    [self.data removeObject:cellData];
}

- (void)settingsUpdated:(NSNotification *)notification
{
    for (HSUTableCellData *data in self.data) {
        [data.renderData removeObjectForKey:@"text_height"];
        [data.renderData removeObjectForKey:@"height"];
    }
    [self.delegate reloadData];
}

- (void)twitterLoginSuccess:(NSNotification *)notification
{
    [self.data removeAllObjects];
    [self saveCache];
    [self.delegate reloadData];
}

- (void)twitterLogout
{
    [self.data removeAllObjects];
    [self.delegate reloadData];
}

@end
