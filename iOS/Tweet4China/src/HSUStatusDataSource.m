//
//  HSUStatusDataSource.m
//  Tweet4China
//
//  Created by Jason Hsu on 4/18/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUStatusDataSource.h"

@implementation HSUStatusDataSource

- (id)initWithDelegate:(id<HSUBaseDataSourceDelegate>)delegate status:(NSDictionary *)status
{
    self = [super init];
    if (self) {
        self.mainStatus = status;
        
        HSUTableCellData *mainCellData = [[HSUTableCellData alloc] initWithRawData:status dataType:kDataType_MainStatus];
        [self.data addObject:mainCellData];
        
        self.delegate = delegate;
        [self.delegate preprocessDataSourceForRender:self];
    }
    return self;
}

- (void)refresh
{
    // load context data, then call finish on delegate
    if (self.loadingCount) {
        return;
    }
    [super refreshSilenced];
    NSDictionary *status = [self.data[0] rawData];
    if ([status[@"in_reply_to_status_id_str"] length]) {
        __weak typeof(self)weakSelf = self;
        [twitter getDetailsForStatus:status[@"in_reply_to_status_id_str"] success:^(id responseObj) {
            HSUTableCellData *chatCellData = [[HSUTableCellData alloc] initWithRawData:responseObj dataType:kDataType_ChatStatus];
            [weakSelf.data insertObject:chatCellData atIndex:0];
            [weakSelf.delegate dataSource:weakSelf insertRowsFromIndex:0 length:1];
            weakSelf.loadingCount --;
//            [weakSelf refresh];
        } failure:^(NSError *error) {
            [weakSelf.delegate dataSource:weakSelf didFinishRefreshWithError:error];
        }];
    }
}

- (void)loadMore
{
    NSDictionary *status = self.mainStatus[@"retweeted_status"] ?: self.mainStatus;
    NSString *keyword = [NSString stringWithFormat:@"@%@", status[@"user"][@"screen_name"]];
    NSString *mainStatusID = status[@"id_str"];
    __weak typeof(self) weakSelf = self;
    [twitter searchTweetsWithKeyword:keyword sinceID:mainStatusID count:20 success:^(id responseObj) {
        NSUInteger oldCount = weakSelf.count;
        NSArray *tweets = ((NSDictionary *)responseObj)[@"statuses"];
        
        NSUInteger newTweetsCount = 0;
        for (NSDictionary *tweet in tweets) {
            if ([tweet[@"in_reply_to_status_id_str"] isEqualToString:mainStatusID]) {
                HSUTableCellData *cellData = [[HSUTableCellData alloc] initWithRawData:tweet dataType:kDataType_ChatStatus];
                [weakSelf.data addObject:cellData];
                newTweetsCount += 1;
            }
        }
        
        if (newTweetsCount) {
            [weakSelf.delegate dataSource:weakSelf insertRowsFromIndex:oldCount length:newTweetsCount];
        }
    } failure:^(NSError *error) {
    }];
}

- (void)clearCache
{
    
}

@end
