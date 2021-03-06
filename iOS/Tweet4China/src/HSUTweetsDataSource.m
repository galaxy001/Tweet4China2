//
//  HSUTweetsDataSource.m
//  Tweet4China
//
//  Created by Jason Hsu on 5/3/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUTweetsDataSource.h"
#import <Reachability/Reachability.h>

@implementation HSUTweetsDataSource

- (id)init
{
    self = [super init];
    if (self) {
        notification_add_observer(HSUStatusDidDeleteNotification, self, @selector(statusDidDelete:));
        notification_add_observer(HSUSettingExcludeRepliesChangedNotification, self, @selector(clearCache));
    }
    return self;
}

- (void)refresh
{
    [super refresh];
    
    __weak typeof(self)weakSelf = self;
    [self fetchRefreshDataWithSuccess:^(id responseObj) {
        NSArray *tweets = responseObj;
        BOOL oldCount = self.count;
        if (tweets.count) {
            
            if (tweets.count >= weakSelf.lastRefreshRequestCount) {
                [weakSelf.data removeAllObjects];
            }
            
            for (int i=tweets.count-1; i>=0; i--) {
                if ([setting(HSUSettingExcludeReplies) boolValue]) {
                    if ([tweets[i][@"in_reply_to_status_id"] integerValue]) {
                        continue;
                    }
                }
                T4CTableCellData *cellData =
                [[T4CTableCellData alloc] initWithRawData:tweets[i] dataType:kDataType_DefaultStatus];
                cellData.unread = YES;
                [weakSelf.data insertObject:cellData atIndex:0];
            }
            weakSelf.unreadCount = tweets.count;
            
            T4CTableCellData *lastCellData = weakSelf.data.lastObject;
            if (![lastCellData.dataType isEqualToString:kDataType_LoadMore]) {
                T4CTableCellData *loadMoreCellData = [[T4CTableCellData alloc] init];
                loadMoreCellData.rawData = @{@"status": @(kLoadMoreCellStatus_Done)};
                loadMoreCellData.dataType = kDataType_LoadMore;
                [weakSelf.data addObject:loadMoreCellData];
            }
            [weakSelf saveCache];
            [weakSelf.delegate preprocessDataSourceForRender:weakSelf];
        }
        [weakSelf.data.lastObject setRawData:@{@"status": @([responseObj count] ? kLoadMoreCellStatus_Done : kLoadMoreCellStatus_NoMore)}];
        if (tweets.count >= weakSelf.lastRefreshRequestCount || oldCount == 0) {
            [weakSelf.delegate dataSource:weakSelf didFinishRefreshWithError:nil];
        } else {
            [weakSelf.delegate dataSource:weakSelf insertRowsFromIndex:0 length:tweets.count];
        }
        weakSelf.loadingCount --;
    } failure:^(NSError *error) {
        [twitter dealWithError:error errTitle:_("Load failed")];
        [weakSelf.data.lastObject setRawData:@{@"status": (!error ||error.code == 204) ? @(kLoadMoreCellStatus_NoMore) : @(kLoadMoreCellStatus_Error)}];
        [weakSelf.delegate dataSource:self didFinishRefreshWithError:error];
        weakSelf.loadingCount --;
    }];
}

- (void)loadMore
{
    [super loadMore];
    
    __weak typeof(self)weakSelf = self;
    [self fetchMoreDataWithSuccess:^(id responseObj) {
        id loadMoreCellData = weakSelf.data.lastObject;
        [weakSelf.data removeLastObject];
        NSUInteger oldCount = weakSelf.count;
        for (NSDictionary *tweet in responseObj) {
            if ([setting(HSUSettingExcludeReplies) boolValue]) {
                if ([tweet[@"in_reply_to_status_id"] integerValue]) {
                    continue;
                }
            }
            T4CTableCellData *cellData =
            [[T4CTableCellData alloc] initWithRawData:tweet dataType:kDataType_DefaultStatus];
            [weakSelf.data addObject:cellData];
        }
        [weakSelf.data addObject:loadMoreCellData];
        
        [weakSelf.data.lastObject setRawData:@{@"status": @([responseObj count] ? kLoadMoreCellStatus_Done : kLoadMoreCellStatus_NoMore)}];
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

- (NSUInteger)requestCount
{
    if ([Reachability reachabilityForInternetConnection].isReachableViaWiFi) {
        return [setting(HSUSettingPageCount) integerValue] ?: kRequestDataCountViaWifi;
    } else {
        return [setting(HSUSettingPageCountWWAN) integerValue] ?: kRequestDataCountViaWWAN;
    }
}

- (void)fetchRefreshDataWithSuccess:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure
{
}

- (void)fetchMoreDataWithSuccess:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure
{
}

- (void)statusDidDelete:(NSNotification *)notification
{
    NSString *idStr = notification.object;
    for (int i=0; i<self.count; i++) {
        T4CTableCellData *cellData = self.data[i];
        if ([cellData.rawData[@"id_str"] isEqualToString:idStr]) {
            [self removeCellData:cellData];
            [self.delegate reloadData];
            break;
        }
    }
}

@end
