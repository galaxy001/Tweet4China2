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
    [super refresh];
    
    if (self.count == 0 && [TWENGINE isAuthorized]) {
        [SVProgressHUD showWithStatus:_(@"Loading Lists")];
    }
    __weak typeof(self)weakSelf = self;
    [TWENGINE getListsWithScreenName:self.screenName success:^(id responseObj) {
        [SVProgressHUD dismiss];
        NSArray *lists = responseObj;
        if (lists.count) {
            
            for (int i=lists.count-1; i>=0; i--) {
                HSUTableCellData *cellData =
                [[HSUTableCellData alloc] initWithRawData:lists[i] dataType:kDataType_List];
                [weakSelf.data insertObject:cellData atIndex:0];
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
        [TWENGINE dealWithError:error errTitle:_(@"Load failed")];
        [weakSelf.delegate dataSource:weakSelf didFinishRefreshWithError:error];
        weakSelf.loadingCount --;
    }];
}

- (void)loadMore
{
    NSLog(@"!!! Not Implemented");
}

@end
