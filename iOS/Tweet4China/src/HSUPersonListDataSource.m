//
//  HSUPersonListDataSource.m
//  Tweet4China
//
//  Created by Jason Hsu on 5/3/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUPersonListDataSource.h"

@implementation HSUPersonListDataSource

- (id)initWithScreenName:(NSString *)screenName
{
    self = [super init];
    if (self) {
        self.screenName = screenName;
    }
    return self;
}

- (void)fetchDataWithSuccess:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure
{
    @throw [[NSException alloc] init];
}

- (void)loadMore
{
    [super loadMore];
    
    [self fetchDataWithSuccess:^(id responseObj) {
        NSDictionary *dict = responseObj;
        self.nextCursor = dict[@"next_cursor_str"];
        self.prevCursor = dict[@"previous_cursor_str"];
        NSArray *users = dict[@"users"];
        if (users.count) {
            HSUTableCellData *loadMoreCellData = self.data.lastObject;
            [self.data removeLastObject];
            for (NSDictionary *tweet in users) {
                HSUTableCellData *cellData =
                [[HSUTableCellData alloc] initWithRawData:tweet dataType:kDataType_Person];
                [self.data addObject:cellData];
            }
            if (!loadMoreCellData) {
                loadMoreCellData = [[HSUTableCellData alloc] init];
                loadMoreCellData.rawData = @{@"status": @(kLoadMoreCellStatus_Done)};
                loadMoreCellData.dataType = kDataType_LoadMore;
            }
            [self.data addObject:loadMoreCellData];
            
            [self.data.lastObject renderData][@"status"] = @(kLoadMoreCellStatus_Done);
            [self.delegate preprocessDataSourceForRender:self];
        } else {
            [self.data.lastObject renderData][@"status"] = @(kLoadMoreCellStatus_NoMore);
        }
        [self.delegate dataSource:self didFinishLoadMoreWithError:nil];
        self.loadingCount --;
    } failure:^(NSError *error) {
        [TWENGINE dealWithError:error errTitle:_(@"Load followers failed")];
        [self.delegate dataSource:self didFinishLoadMoreWithError:error];
    }];
}

@end
