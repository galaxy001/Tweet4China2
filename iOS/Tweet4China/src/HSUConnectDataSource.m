//
//  HSUConnectDataSource.m
//  Tweet4China
//
//  Created by Jason Hsu on 4/24/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUConnectDataSource.h"
#import "HSULoadMoreCell.h"
#import "HSUBaseViewController.h"

@implementation HSUConnectDataSource

+ (void)checkUnreadForViewController:(HSUBaseViewController *)viewController
{
    NSString *latestIdStr = [[NSUserDefaults standardUserDefaults] objectForKey:S(@"%@_first_id_str", self.class.cacheKey)];
    [twitter getMentionsTimelineSinceID:latestIdStr maxID:nil count:1 success:^(id responseObj) {
        NSArray *tweets = responseObj;
        NSString *lastIdStr = tweets.lastObject[@"id_str"];
        if (lastIdStr) { // updated
            [viewController dataSourceDidFindUnread:nil];
        }
    } failure:^(NSError *error) {
        
    }];
}

- (id)init
{
    self = [super init];
    if (self) {
        self.useCache = YES;
    }
    return self;
}

- (void)refresh
{
    [super refresh];
    
    NSString *latestIdStr = [self rawDataAtIndex:0][@"id_str"];
    __weak typeof(self)weakSelf = self;
    [twitter getMentionsTimelineSinceID:latestIdStr maxID:nil count:self.requestCount success:^(id responseObj) {
        NSArray *tweets = responseObj;
        BOOL oldCount = self.count;
        BOOL newCount = 0;
        if (tweets.count) {
            for (int i=tweets.count-1; i>=0; i--) {
                // todo: ugly code, remove duplicated data
                for (HSUTableCellData *cellData in weakSelf.data) {
                    NSDictionary *rawData = cellData.rawData;
                    if ([rawData[@"id_str"] isEqualToString:tweets[i][@"id_str"]]) {
                        continue;
                    }
                    newCount ++;
                }
                HSUTableCellData *cellData =
                [[HSUTableCellData alloc] initWithRawData:tweets[i] dataType:kDataType_DefaultStatus];
                [weakSelf.data insertObject:cellData atIndex:0];
            }
            
            HSUTableCellData *lastCellData = weakSelf.data.lastObject;
            if (![lastCellData.dataType isEqualToString:kDataType_LoadMore]) {
                HSUTableCellData *loadMoreCellData = [[HSUTableCellData alloc] init];
                loadMoreCellData.rawData = @{@"status": @(kLoadMoreCellStatus_Done)};
                loadMoreCellData.dataType = kDataType_LoadMore;
                [weakSelf.data addObject:loadMoreCellData];
            }
            
            [weakSelf saveCache];
            [weakSelf.delegate preprocessDataSourceForRender:weakSelf];
        }
        if (newCount >= weakSelf.requestCount || oldCount == 0) {
            [weakSelf.delegate dataSource:weakSelf didFinishRefreshWithError:nil];
        } else {
            [weakSelf.delegate dataSource:weakSelf insertRowsFromIndex:0 length:tweets.count];
        }
        
        weakSelf.loadingCount --;
    } failure:^(NSError *error) {
        [twitter dealWithError:error errTitle:_("Load failed")];
        [weakSelf.delegate dataSource:self didFinishRefreshWithError:error];
        weakSelf.loadingCount --;
    }];
}

- (void)loadMore
{
    [super loadMore];
    
    NSString *lastStatusId = [self rawDataAtIndex:self.count-2][@"id_str"];
    __weak typeof(self)weakSelf = self;
    [twitter getMentionsTimelineSinceID:nil maxID:lastStatusId count:self.requestCount success:^(id responseObj) {
        id loadMoreCellData = weakSelf.data.lastObject;
        [weakSelf.data removeLastObject];
        NSUInteger oldCount = weakSelf.count;
        for (NSDictionary *tweet in responseObj) {
            HSUTableCellData *cellData =
            [[HSUTableCellData alloc] initWithRawData:tweet dataType:kDataType_DefaultStatus];
            [weakSelf.data addObject:cellData];
        }
        [weakSelf.data addObject:loadMoreCellData];
        
        if ([responseObj count]) {
            [weakSelf.data.lastObject setRawData:@{@"status": @(kLoadMoreCellStatus_Done)}];
        } else {
            [weakSelf.data.lastObject setRawData:@{@"status": @(kLoadMoreCellStatus_NoMore)}];
        }
        [weakSelf saveCache];
        [weakSelf.delegate preprocessDataSourceForRender:weakSelf];
        [weakSelf.delegate dataSource:weakSelf insertRowsFromIndex:oldCount length:[responseObj count]];
        weakSelf.loadingCount --;
    } failure:^(NSError *error) {
        [twitter dealWithError:error errTitle:_("Load failed")];
        [weakSelf.data.lastObject setRawData:@{@"status": (!error ||error.code == 204) ? @(kLoadMoreCellStatus_NoMore) : @(kLoadMoreCellStatus_Error)}];
        [weakSelf.delegate dataSource:weakSelf didFinishLoadMoreWithError:error];
        weakSelf.loadingCount --;
    }];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!self.loadingCount && self.count > 1) {
        HSUTableCellData *cellData = [self dataAtIndex:indexPath.row];
        if ([cellData.dataType isEqualToString:kDataType_LoadMore]) {
            if (![cellData.rawData[@"status"] intValue] == kLoadMoreCellStatus_NoMore) {
                cellData.rawData = @{@"status": @(kLoadMoreCellStatus_Loading)};
                [self loadMore];
            }
        }
    }
    
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

@end
