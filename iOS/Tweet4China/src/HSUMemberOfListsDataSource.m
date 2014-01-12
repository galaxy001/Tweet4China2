//
//  HSUMemberOfListsDataSource.m
//  Tweet4China
//
//  Created by Jason Hsu on 2013/12/2.
//  Copyright (c) 2013年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUMemberOfListsDataSource.h"

@implementation HSUMemberOfListsDataSource

- (void)refresh
{
    [self.data removeAllObjects];
    if (self.count == 0 && [twitter isAuthorized]) {
        [SVProgressHUD showWithStatus:_("Loading Lists")];
    }
    __weak typeof(self)weakSelf = self;
    [twitter getListsSubscribedWithScreenName:self.screenName count:10000 success:^(id responseObj) {
        [SVProgressHUD dismiss];
        NSArray *lists = responseObj[@"lists"];
        if (lists.count) {
            for (int i=lists.count-1; i>=0; i--) {
                HSUTableCellData *cellData =
                [[HSUTableCellData alloc] initWithRawData:lists[i] dataType:kDataType_List];
                [weakSelf.data addObject:cellData];
            }
            
            HSUTableCellData *lastCellData = weakSelf.data.lastObject;
            if (![lastCellData.dataType isEqualToString:kDataType_LoadMore]) {
                HSUTableCellData *loadMoreCellData = [[HSUTableCellData alloc] init];
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
        [SVProgressHUD dismiss];
        [twitter dealWithError:error errTitle:_("Load failed")];
        [weakSelf.delegate dataSource:weakSelf didFinishRefreshWithError:error];
        weakSelf.loadingCount --;
    }];
}

@end
