//
//  HSUSearchPersonDataSource.m
//  Tweet4China
//
//  Created by Jason Hsu on 10/20/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUSearchPersonDataSource.h"

@implementation HSUSearchPersonDataSource

- (void)fetchDataWithSuccess:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure
{
    if (![self.keyword length]) {
        success(@[]);
        return;
    }
    NSString *keyword = self.keyword;
    __weak typeof(self)weakSelf = self;
    [twitter searchUserWithKeyword:self.keyword success:^(id responseObj) {
        if ([weakSelf.keyword isEqualToString:keyword]) {
            success(responseObj);
        }
    } failure:^(NSError *error) {
        if ([weakSelf.keyword isEqualToString:keyword]) {
            failure(error);
        }
    }];
}

- (void)refresh
{
    self.loadingCount ++;
    
    [self.data removeAllObjects];
    [self fetchDataWithSuccess:^(id responseObj) {
        NSArray *users = responseObj;
        for (NSDictionary *user in users) {
            T4CTableCellData *cellData =
            [[T4CTableCellData alloc] initWithRawData:user dataType:kDataType_Person];
            [self.data addObject:cellData];
        }
        
        [self.delegate preprocessDataSourceForRender:self];
        [self.delegate dataSource:self didFinishLoadMoreWithError:nil];
        self.loadingCount --;
    } failure:^(NSError *error) {
        [twitter dealWithError:error errTitle:_("Load search result failed")];
        [self.delegate dataSource:self didFinishLoadMoreWithError:error];
    }];
}

@end
