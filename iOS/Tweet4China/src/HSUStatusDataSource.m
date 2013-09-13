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
        HSUTableCellData *mainCellData = [[HSUTableCellData alloc] initWithRawData:status dataType:kDataType_MainStatus];
        [self.data addObject:mainCellData];
        
        self.delegate = delegate;
        [self.delegate preprocessDataSourceForRender:self];
    }
    return self;
}

- (void)loadMore
{
    // load context data, then call finish on delegate
    NSDictionary *status = [self rawDataAtIndex:0];
    if ([status[@"in_reply_to_status_id_str"] length]) {
        [TWENGINE getDetailsForStatus:status[@"in_reply_to_status_id_str"] success:^(id responseObj) {
            HSUTableCellData *chatCellData = [[HSUTableCellData alloc] initWithRawData:responseObj dataType:kDataType_ChatStatus];
            [self.data insertObject:chatCellData atIndex:0];
            [self.delegate dataSource:self didFinishRefreshWithError:nil];
        } failure:^(NSError *error) {
            [self.delegate dataSource:self didFinishRefreshWithError:error];
        }];
    }
}

@end
