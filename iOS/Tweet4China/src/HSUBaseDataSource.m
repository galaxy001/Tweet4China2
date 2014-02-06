//
//  HSUBaseDataSource.m
//  Tweet4China
//
//  Created by Jason Hsu on 3/10/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUBaseDataSource.h"
#import "T4CTableCellData.h"
#import "T4CStatusCellData.h"

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
        T4CTableCellData *cellData = [self dataAtIndex:indexPath.row];
        if ([cellData.dataType isEqualToString:kDataType_LoadMore] &&
            [cellData.rawData[@"status"] integerValue] == kLoadMoreCellStatus_Done) {
            
            cellData.rawData = @{@"status": @(kLoadMoreCellStatus_Loading)};
            [self loadMore];
        }
    }
    
    T4CTableCellData *cellData = [self dataAtIndexPath:indexPath];
    HSUBaseTableCell *cell = (HSUBaseTableCell *)[tableView dequeueReusableCellWithIdentifier:cellData.dataType];
    [cell setupWithData:cellData];
    
    if (IPAD) {
        cell.cornerLeftTop.hidden = indexPath.row != 0;
        cell.cornerRightTop.hidden = indexPath.row != 0;
    }
    
#ifdef __IPHONE_7_0
    if (IPAD && Sys_Ver >= 7) {
        if (indexPath.section == 0 && indexPath.row == self.count - 1) {
            cell.separatorInset = edi(0, tableView.width, 0, 0);
        } else {
            CGFloat padding = cell.width/2-cell.contentView.width/2;
            cell.separatorInset = edi(0, padding, 0, padding);
        }
    }
#endif
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
#ifdef MakeScreenshot
    return 0;
#endif
    return 1;
}

#pragma mark - Data
- (NSArray *)allData
{
    return self.data;
}

- (T4CTableCellData *)dataAtIndex:(NSInteger)index
{
    if (self.data.count > index) {
        return self.data[index];
    }
    // Warn
    return nil;
}

- (T4CTableCellData *)dataAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section) {
        return nil;
    }
    return [self dataAtIndex:indexPath.row];
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
        // TODO
//        [self renderDataAtIndex:i][name] = cellEvent;
    }
}

- (void)refreshSilenced
{
    self.loadingCount ++;
}

- (void)refresh
{
    self.loadingCount ++;
    
    [self.delegate dataSourceWillStartRefresh:self];
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
    if (!self.useCache) {
        return;
    }
    uint cacheSize = kRequestDataCountViaWifi;
    NSMutableArray *cacheDataArr = [NSMutableArray arrayWithCapacity:cacheSize];
    for (T4CTableCellData *cellData in self.data) {
        if (cacheDataArr.count < cacheSize) {
            if (![cellData.dataType isEqualToString:kDataType_LoadMore]) {
                [cacheDataArr addObject:cellData.cacheData];
            }
        } else {
            break;
        }
    }
    NSString *fileName = dp(self.class.cacheKey);
    if (cacheDataArr.count) {
        NSData *json = [NSJSONSerialization dataWithJSONObject:cacheDataArr options:0 error:nil];
        [json writeToFile:fileName atomically:NO];
    } else {
        [[NSFileManager defaultManager] removeItemAtPath:fileName error:nil];
    }
    
    if (self.count) {
        NSString *firstIdStr = [self rawDataAtIndex:0][@"id_str"];
        [[NSUserDefaults standardUserDefaults] setObject:firstIdStr forKey:S(@"%@_first_id_str", [self.class cacheKey])];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:S(@"%@_first_id_str", [self.class cacheKey])];
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
    if (!twitter.isAuthorized) {
        return dataSource;
    }
    
    NSString *fileName = dp(self.class.cacheKey);
    if (useCahce) {
        NSData *json = [NSData dataWithContentsOfFile:fileName];
        if (json) {
            NSArray *cacheDataArr = [NSJSONSerialization JSONObjectWithData:json options:0 error:nil];
            NSMutableArray *mData = [NSMutableArray arrayWithCapacity:cacheDataArr.count];
            for (NSDictionary *cacheData in cacheDataArr) {
//                if ([cacheDataArr indexOfObject:cacheData] < 100) {
//                    continue;
//                }
                [mData addObject:[[T4CTableCellData alloc] initWithCacheData:cacheData]];
            }
            if (![((T4CTableCellData *)mData.lastObject).dataType isEqualToString:kDataType_LoadMore]) {
                T4CTableCellData *loadMoreCellData = [[T4CTableCellData alloc] init];
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

- (void)removeCellData:(T4CTableCellData *)cellData
{
    [self.data removeObject:cellData];
}

- (void)settingsUpdated:(NSNotification *)notification
{
    statusViewTestLabelInited = NO;
    for (T4CTableCellData *data in self.data) {
        if ([data isKindOfClass:[T4CStatusCellData class]]) {
            ((T4CStatusCellData *)data).cellHeight = 0;
            ((T4CStatusCellData *)data).textHeight = 0;
        }
    }
    [self.delegate reloadData];
}

- (void)clearCache
{
    self.unreadCount = 0;
    
    [self.data removeAllObjects];
    [self saveCache];
    [self.delegate reloadData];
}

- (void)twitterLoginSuccess:(NSNotification *)notification
{
    [self clearCache];
}

- (void)twitterLogout
{
    [self clearCache];
}

+ (void)checkUnreadForViewController:(HSUBaseViewController *)viewController
{
    
}

@end
