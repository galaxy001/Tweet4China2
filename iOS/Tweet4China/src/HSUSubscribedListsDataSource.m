//
//  HSUListDataSource.m
//  Tweet4China
//
//  Created by Jason Hsu on 2013/12/2.
//  Copyright (c) 2013年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUSubscribedListsDataSource.h"

@implementation HSUSubscribedListsDataSource

- (id)initWithScreenName:(NSString *)screenName
{
    self = [super init];
    if (self) {
        self.screenName = screenName;
    }
    return self;
}

- (void)refresh
{
    [super refreshSilenced];
    
    [self.data removeAllObjects];
    __weak typeof(self)weakSelf = self;
    [twitter getListsWithScreenName:self.screenName success:^(id responseObj) {
        NSArray *lists = responseObj;
        if (lists.count) {
            for (int i=lists.count-1; i>=0; i--) {
                T4CTableCellData *cellData =
                [[T4CTableCellData alloc] initWithRawData:lists[i] dataType:kDataType_List];
                [weakSelf.data addObject:cellData];
            }
            
            T4CTableCellData *lastCellData = weakSelf.data.lastObject;
            if (![lastCellData.dataType isEqualToString:kDataType_LoadMore]) {
                T4CTableCellData *loadMoreCellData = [[T4CTableCellData alloc] init];
                if (lists.count < weakSelf.requestCount) {
                    loadMoreCellData.rawData = @{@"status": @(kLoadMoreCellStatus_NoMore)};
                } else {
                    loadMoreCellData.rawData = @{@"status": @(kLoadMoreCellStatus_Done)};
                }
                loadMoreCellData.dataType = kDataType_LoadMore;
                [weakSelf.data addObject:loadMoreCellData];
            }
            
            [weakSelf saveCache];
            [weakSelf.delegate preprocessDataSourceForRender:weakSelf];
        }
        [weakSelf.delegate dataSource:weakSelf didFinishRefreshWithError:nil];
        weakSelf.loadingCount --;
    } failure:^(NSError *error) {
        [twitter dealWithError:error errTitle:_("Load failed")];
        [weakSelf.delegate dataSource:weakSelf didFinishRefreshWithError:error];
        weakSelf.loadingCount --;
    }];
}

- (void)loadMore
{
    NSLog(@"!!! Not Implemented");
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *list = [self rawDataAtIndex:indexPath.row];
    return [list[@"user"][@"screen_name"] isEqualToString:MyScreenName];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *list = [self rawDataAtIndex:indexPath.row];
    [SVProgressHUD showWithStatus:nil];
    [twitter deleteListWithListID:list[@"id_str"] success:^(id responseObj) {
        [SVProgressHUD dismiss];
        [self.data removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    } failure:^(NSError *error) {
        [SVProgressHUD showErrorWithStatus:_("Delete List failed")];
    }];
}

@end
