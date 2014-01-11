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
    if (!latestIdStr) {
        latestIdStr = @"1";
    }
    [TWENGINE getMentionsTimelineSinceID:latestIdStr maxID:nil count:1 success:^(id responseObj) {
        NSArray *tweets = responseObj;
        NSString *lastIdStr = tweets.lastObject[@"id_str"];
        if (lastIdStr) { // updated
            [viewController dataSourceDidFindUnread:nil];
        }
    } failure:^(NSError *error) {
        
    }];
}

- (void)refresh
{
    [super refresh];
    
    NSString *latestIdStr = [self rawDataAtIndex:0][@"id_str"];
    if (!latestIdStr) {
        latestIdStr = @"1";
    }
    __weak typeof(self)weakSelf = self;
    [TWENGINE getMentionsTimelineSinceID:latestIdStr maxID:nil count:self.requestCount success:^(id responseObj) {
        NSArray *tweets = responseObj;
        if (tweets.count) {
            for (int i=tweets.count-1; i>=0; i--) {
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
        [weakSelf.delegate dataSource:weakSelf didFinishRefreshWithError:nil];
        weakSelf.loadingCount --;
    } failure:^(NSError *error) {
        [TWENGINE dealWithError:error errTitle:_(@"Load failed")];
        [weakSelf.delegate dataSource:self didFinishRefreshWithError:error];
    }];
}

- (void)loadMore
{
    [super loadMore];
    
    HSUTableCellData *lastStatusData = [self dataAtIndex:self.count-2];
    NSString *lastStatusId = lastStatusData.rawData[@"id_str"];
    __weak typeof(self)weakSelf = self;
    [TWENGINE getMentionsTimelineSinceID:nil maxID:lastStatusId count:self.requestCount success:^(id responseObj) {
        id loadMoreCellData = weakSelf.data.lastObject;
        [weakSelf.data removeLastObject];
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
        [weakSelf.delegate dataSource:weakSelf didFinishLoadMoreWithError:nil];
        weakSelf.loadingCount --;
    } failure:^(NSError *error) {
        [TWENGINE dealWithError:error errTitle:_(@"Load failed")];
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

-(void)saveCache
{
    [super saveCache];
    
    if (self.count) {
        NSString *firstIdStr = [self rawDataAtIndex:0][@"id_str"];
        [[NSUserDefaults standardUserDefaults] setObject:firstIdStr forKey:S(@"%@_first_id_str", [self.class cacheKey])];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

@end
