//
//  T4CViewController.h
//  Tweet4China
//
//  Created by Jason Hsu on 14-1-14.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import <UIKit/UIKit.h>

@class T4CGapCellData;
@class T4CStatusCellData;
@class HSUiPadTabController;
@interface T4CTableViewController : UIViewController <UIScrollViewDelegate, UINavigationControllerDelegate, UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) NSMutableArray *data;
@property (nonatomic, assign) long long topID, bottomID, nextCursor;
@property (nonatomic, weak) T4CGapCellData *gapCellData;
@property (nonatomic, readonly) NSString *requestUrl, *apiString;
@property (nonatomic, readonly) NSUInteger requestCount;
@property (nonatomic, readonly) NSDictionary *requestParams;
@property (nonatomic, readonly) NSString *dataKey;
@property (nonatomic) T4CLoadingState refreshState, loadMoreState;
@property (nonatomic, assign) BOOL pullToRefresh, infiniteScrolling;
@property (nonatomic, weak) UITableView *tableView;
@property (nonatomic, assign) BOOL useCache;
@property (nonatomic, weak) T4CStatusCellData *cellDataInNextPage;
@property (nonatomic, strong) UIBarButtonItem *actionBarButton;
@property (nonatomic, strong) UIBarButtonItem *composeBarButton;
@property (nonatomic, strong) UIBarButtonItem *searchBarButton;
@property (nonatomic, weak) HSUiPadTabController *tabController;
@property (nonatomic, readonly) T4CTableCellData *firstTimelineData;
@property (nonatomic, assign) NSUInteger unreadCount;
@property (nonatomic, assign) BOOL showUnreadCount;
@property (nonatomic, assign) NSUInteger viewDidApearCount;

- (void)refresh;
- (void)loadGap:(T4CGapCellData *)gapCellData;
- (void)loadMore;

- (void)scrollToShowPullToRefreshViewWithAnimation:(BOOL)animation;
- (void)tabItemTapped;

- (void)saveCache;
- (void)loadCache;

- (NSString *)requestUrlWithAPIString:(NSString *)apiString;
- (NSString *)requestUrlWithAPIFormat:(NSString *)apiFormat idString:(NSString *)idString;

- (BOOL)filterData:(NSDictionary *)data;
- (NSString *)dataTypeOfData:(NSDictionary *)data;
- (T4CTableCellData *)createTableCellDataWithRawData:(NSDictionary *)rawData;
- (void)showUnreadIndicator;
- (void)unreadCountChanged;

- (void)scrollTableViewToCurrentOffsetAfterInsertNewCellCount:(NSUInteger)count;

- (int)requestDidFinishRefreshWithData:(NSArray *)dataArr;
- (void)requestDidFinishLoadGapWithData:(NSArray *)dataArr;
- (void)requestDidFinishLoadMoreWithData:(NSArray *)dataArr;
- (void)requestDidFinishRefreshWithError:(NSError *)error;
- (void)requestDidFinishLoadGapWithError:(NSError *)error;
- (void)requestDidFinishLoadMoreWithError:(NSError *)error;

@end
