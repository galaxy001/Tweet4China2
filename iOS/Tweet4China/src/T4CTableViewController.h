//
//  T4CViewController.h
//  Tweet4China
//
//  Created by Jason Hsu on 14-1-14.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, T4CLoadingState) {
    T4CLoadingState_Done,
    T4CLoadingState_Loading,
    T4CLoadingState_Error,
    T4CLoadingState_NoMore,
};

@interface T4CTableViewController : UITableViewController

@property (nonatomic, strong) NSMutableArray *data;
@property (nonatomic) NSUInteger topID, bottomID;
@property (nonatomic, readonly) NSString *requestUrl;
@property (nonatomic, readonly) NSUInteger requestCount;
@property (nonatomic, readonly) NSDictionary *requestParams;
@property (nonatomic, readonly) NSString *dataKey;
@property (nonatomic) T4CLoadingState refreshState, loadMoreState;
@property (nonatomic, assign) BOOL pullToRefresh, infiniteScrolling;

- (void)refresh;
- (void)loadMore;

- (BOOL)filterData:(NSDictionary *)data;
- (NSString *)dataTypeOfData:(NSDictionary *)data;

- (void)requestDidFinishLoadingWithData:(NSArray *)dataArr;
- (void)requestDidFinishLoadingWithError:(NSError *)error;

@end
