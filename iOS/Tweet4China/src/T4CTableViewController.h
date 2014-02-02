//
//  T4CViewController.h
//  Tweet4China
//
//  Created by Jason Hsu on 14-1-14.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import <UIKit/UIKit.h>

@class T4CGapCellData;
@interface T4CTableViewController : UITableViewController <UIScrollViewDelegate>

@property (nonatomic, strong) NSMutableArray *data;
@property (nonatomic, assign) long long topID, bottomID;
@property (nonatomic, weak) T4CGapCellData *gapCellData;
@property (nonatomic, readonly) NSString *requestUrl, *apiString;
@property (nonatomic, readonly) NSUInteger requestCount;
@property (nonatomic, readonly) NSDictionary *requestParams;
@property (nonatomic, readonly) NSString *dataKey;
@property (nonatomic) T4CLoadingState refreshState, loadMoreState;
@property (nonatomic, assign) BOOL pullToRefresh, infiniteScrolling;

- (void)refresh;
- (void)loadGap:(T4CGapCellData *)gapCellData;
- (void)loadMore;

- (NSString *)requestUrlWithAPIString:(NSString *)apiString;

- (BOOL)filterData:(NSDictionary *)data;
- (NSString *)dataTypeOfData:(NSDictionary *)data;

- (void)scrollTableViewToCurrentOffsetAfterInsertNewCellCount:(NSUInteger)count;

- (void)requestDidFinishRefreshWithData:(NSArray *)dataArr;
- (void)requestDidFinishLoadGapWithData:(NSArray *)dataArr;
- (void)requestDidFinishLoadMoreWithData:(NSArray *)dataArr;
//- (void)requestDidFinishRefreshWithError:(NSError *)error;
- (void)requestDidFinishLoadingWithError:(NSError *)error;

@end
