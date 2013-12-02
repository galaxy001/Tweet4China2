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
        [SVProgressHUD showWithStatus:@"Loading Lists"];
    }
    [TWENGINE getListsWithScreenName:self.screenName success:^(id responseObj) {
        [SVProgressHUD dismiss];
        NSArray *lists = responseObj;
        if (lists.count) {
            
            for (int i=lists.count-1; i>=0; i--) {
                HSUTableCellData *cellData =
                [[HSUTableCellData alloc] initWithRawData:lists[i] dataType:kDataType_List];
                [self.data insertObject:cellData atIndex:0];
            }
            
            HSUTableCellData *lastCellData = self.data.lastObject;
            if (![lastCellData.dataType isEqualToString:kDataType_LoadMore]) {
                HSUTableCellData *loadMoreCellData = [[HSUTableCellData alloc] init];
                loadMoreCellData.rawData = @{@"status": @(kLoadMoreCellStatus_NoMore)};
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
        [TWENGINE dealWithError:error errTitle:@"Load failed"];
        [self.delegate dataSource:self didFinishRefreshWithError:error];
        self.loadingCount --;
    }];
}

@end
