//
//  HSUTweetsDataSource.m
//  Tweet4China
//
//  Created by Jason Hsu on 5/3/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUTweetsDataSource.h"

@implementation HSUTweetsDataSource

- (void)refresh
{
    [super refresh];
    
    [self fetchMoreDataWithSuccess:^(id responseObj) {
        NSArray *tweets = responseObj;
        if (tweets.count) {
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
        [TWENGINE dealWithError:error errTitle:@"Load failed"];
        [self.delegate dataSource:self didFinishRefreshWithError:error];
    }];
}

- (void)loadMore
{
    [super loadMore];
    
    [self fetchMoreDataWithSuccess:^(id responseObj) {
        [responseObj removeObjectAtIndex:0];
        id loadMoreCellData = self.data.lastObject;
        [self.data removeLastObject];
        for (NSDictionary *tweet in responseObj) {
            HSUTableCellData *cellData =
            [[HSUTableCellData alloc] initWithRawData:tweet dataType:kDataType_DefaultStatus];
            [self.data addObject:cellData];
        }
        [self.data addObject:loadMoreCellData];
        
        [self saveCache];
        [self.data.lastObject renderData][@"status"] = @(kLoadMoreCellStatus_Done);
        [self.delegate preprocessDataSourceForRender:self];
        [self.delegate dataSource:self didFinishLoadMoreWithError:nil];
        self.loadingCount --;
    } failure:^(NSError *error) {
        [TWENGINE dealWithError:error errTitle:@"Load failed"];
        [self.data.lastObject renderData][@"status"] = @(kLoadMoreCellStatus_Error);
        [self.delegate dataSource:self didFinishLoadMoreWithError:nil];
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

@end
