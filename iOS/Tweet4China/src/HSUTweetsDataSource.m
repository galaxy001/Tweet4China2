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
        notification_add_observer(HSUStatusDidDelete, self, @selector(statusDidDelete:));
    }
    return self;
}

- (void)refresh
{
    [super refresh];
    
    if (self.count == 0 && [TWENGINE isAuthorized]) {
        [SVProgressHUD showWithStatus:_(@"Loading Tweets")];
    }
    [self fetchRefreshDataWithSuccess:^(id responseObj) {
        [SVProgressHUD dismiss];
        NSArray *tweets = responseObj;
        if (tweets.count) {
            
            if (tweets.count >= self.requestCount) {
                [self.data removeAllObjects];
            }
            
            for (int i=tweets.count-1; i>=0; i--) {
                HSUTableCellData *cellData =
                [[HSUTableCellData alloc] initWithRawData:tweets[i] dataType:kDataType_DefaultStatus];
                [self.data insertObject:cellData atIndex:0];
            }
            
            HSUTableCellData *lastCellData = self.data.lastObject;
            if (![lastCellData.dataType isEqualToString:kDataType_LoadMore]) {
                HSUTableCellData *loadMoreCellData = [[HSUTableCellData alloc] init];
                loadMoreCellData.rawData = @{@"status": @(kLoadMoreCellStatus_Done)};
                loadMoreCellData.dataType = kDataType_LoadMore;
                [self.data addObject:loadMoreCellData];
            }
            
            [self saveCache];
            [self.delegate preprocessDataSourceForRender:self];
        }
        [self.delegate dataSource:self didFinishRefreshWithError:nil];
        self.loadingCount --;
    } failure:^(NSError *error) {
        [SVProgressHUD dismiss];
        [TWENGINE dealWithError:error errTitle:_(@"Load failed")];
        [self.delegate dataSource:self didFinishRefreshWithError:error];
        self.loadingCount --;
    }];
}

- (void)loadMore
{
    [super loadMore];
    
    [self fetchMoreDataWithSuccess:^(id responseObj) {
        id loadMoreCellData = self.data.lastObject;
        [self.data removeLastObject];
        for (NSDictionary *tweet in responseObj) {
            HSUTableCellData *cellData =
            [[HSUTableCellData alloc] initWithRawData:tweet dataType:kDataType_DefaultStatus];
            [self.data addObject:cellData];
        }
        [self.data addObject:loadMoreCellData];
        
        [self.data.lastObject setRawData:@{@"status": @(kLoadMoreCellStatus_Done)}];
        [self saveCache];
        [self.delegate preprocessDataSourceForRender:self];
        [self.delegate dataSource:self didFinishLoadMoreWithError:nil];
        self.loadingCount --;
    } failure:^(NSError *error) {
        [TWENGINE dealWithError:error errTitle:_(@"Load failed")];
        [self.data.lastObject setRawData:@{@"status": (!error ||error.code == 204) ? @(kLoadMoreCellStatus_NoMore) : @(kLoadMoreCellStatus_Error)}];
        [self.delegate dataSource:self didFinishLoadMoreWithError:error];
        self.loadingCount --;
    }];
}

- (NSUInteger)requestCount
{
    if ([Reachability reachabilityForInternetConnection].isReachableViaWiFi) {
        return kRequestDataCountViaWifi;
    } else {
        return kRequestDataCountViaWWAN;
    }
}

- (void)fetchRefreshDataWithSuccess:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure
{
}

- (void)fetchMoreDataWithSuccess:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure
{
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    if (IPAD && indexPath.row == 0) {
        UIImageView *leftTopCornerView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"table_corner_left_top"]];
        UIImageView *rightTopCornerView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"table_corner_right_top"]];
        [cell addSubview:leftTopCornerView];
        [cell addSubview:rightTopCornerView];
        rightTopCornerView.rightTop = ccp(cell.width, 0);
    }
    
    return cell;
}

- (void)statusDidDelete:(NSNotification *)notification
{
    NSString *idStr = notification.object;
    for (int i=0; i<self.count; i++) {
        HSUTableCellData *cellData = self.data[i];
        if ([cellData.rawData[@"id_str"] isEqualToString:idStr]) {
            [self removeCellData:cellData];
            if ([self.delegate respondsToSelector:@selector(tableView)]) {
                // todo: ugly code
                [[self.delegate performSelector:@selector(tableView)] reloadData];
                break;
            }
        }
    }
}

@end
