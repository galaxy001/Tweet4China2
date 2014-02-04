//
//  T4CStatusDetailViewController.m
//  Tweet4China
//
//  Created by Jason Hsu on 14-2-2.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "T4CStatusViewController.h"
#import "T4CStatusCellData.h"
#import "T4CLoadingRepliedStatusCell.h"

@interface T4CStatusViewController ()

@property (nonatomic, strong) T4CTableCellData *loadingReplyCellData;
@property (nonatomic, strong) NSDictionary *mainStatus; // self.status or self.status.retweeted_status

@end

@implementation T4CStatusViewController

- (id)init
{
    self = [super init];
    if (self) {
        self.pullToRefresh = NO;
        self.infiniteScrolling = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItem = self.composeBarButton;
    
    self.mainStatus = self.status[@"retweeted_status"] ?: self.status;
    
    if ([self.mainStatus[@"in_reply_to_status_id"] longLongValue]) {
        self.loadingReplyCellData =
        [[T4CTableCellData alloc] initWithRawData:self.mainStatus
                                         dataType:kDataType_LoadingReply];
        [self.data addObject:self.loadingReplyCellData];
    }
    T4CStatusCellData *cellData = [[T4CStatusCellData alloc] initWithRawData:self.mainStatus
                                                                    dataType:kDataType_MainStatus];
    cellData.target = self;
    [self.data addObject:cellData];
    
    [self loadInReplyStatus];
    [self loadReplies];
}

- (void)loadInReplyStatus
{
    // TODO: use cache
    if (self.refreshState != T4CLoadingState_Done) {
        return;
    }
    
    NSDictionary *status = [self.data.firstObject rawData];
    if (![status[@"in_reply_to_status_id"] longLongValue]) {
        self.refreshState = T4CLoadingState_NoMore;
        return;
    }
    
    self.refreshState = T4CLoadingState_Loading;
    __weak typeof(self)weakSelf = self;
    [twitter getDetailsForStatus:status[@"in_reply_to_status_id"]
                         success:^(id responseObj)
    {
        if ([responseObj isKindOfClass:[NSDictionary class]]) {
            
            NSUInteger count = 1;
            if (weakSelf.loadingReplyCellData) {
                [weakSelf.data removeObject:self.loadingReplyCellData];
                weakSelf.loadingReplyCellData = nil;
                count --;
            }
            
            T4CStatusCellData *statusCellData = [[T4CStatusCellData alloc] initWithRawData:responseObj
                                                                                  dataType:kDataType_ChatStatus];
            statusCellData.target = self;
            [weakSelf.data insertObject:statusCellData atIndex:0];
            [weakSelf.tableView reloadData];
            [weakSelf scrollTableViewToCurrentOffsetAfterInsertNewCellCount:1];
            weakSelf.refreshState = T4CLoadingState_Done;
        }
    } failure:^(NSError *error)
    {
        if (error.code == 204) {
            weakSelf.refreshState = T4CLoadingState_NoMore;
        } else {
            weakSelf.refreshState = T4CLoadingState_Error;
        }
    }];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView.contentOffset.y < 10 - scrollView.contentInset.top) {
        [self loadInReplyStatus];
    }
}

- (void)loadReplies
{
    self.loadMoreState = T4CLoadingState_Loading;
    NSString *keyword = S(@"@%@", self.mainStatus[@"user"][@"screen_name"]);
    __weak typeof(self)weakSelf = self;
    [twitter searchTweetsWithKeyword:keyword
                             sinceID:self.mainStatus[@"id"]
                               count:20
                             success:^(id responseObj)
    {
        if ([responseObj isKindOfClass:[NSDictionary class]]) {
            
            weakSelf.loadMoreState = T4CLoadingState_Done;
            NSArray *tweets = ((NSDictionary *)responseObj)[@"statuses"];
            NSUInteger newTweetsCount = 0;
            for (NSDictionary *tweet in tweets) {
                if ([tweet[@"in_reply_to_status_id"] isEqual:weakSelf.mainStatus[@"id"]]) {
                    T4CStatusCellData *cellData = [[T4CStatusCellData alloc] initWithRawData:tweet
                                                                                    dataType:kDataType_ChatStatus];
                    cellData.target = self;
                    [weakSelf.data addObject:cellData];
                    newTweetsCount += 1;
                }
            }
            
            if (newTweetsCount) {
                [weakSelf.tableView reloadData];
            }
        }
    } failure:^(NSError *error)
    {
        if (error.code == 204) {
            weakSelf.loadMoreState = T4CLoadingState_NoMore;
        } else {
            weakSelf.loadMoreState = T4CLoadingState_Error;
        }
    }];
}

@end
