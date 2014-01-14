//
//  HSUBaseDataSource.h
//  Tweet4China
//
//  Created by Jason Hsu on 3/10/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HSUTwitterAPI.h"

#define kRequestDataCountViaWifi 200
#define kRequestDataCountViaWWAN 20

@protocol HSUBaseDataSourceDelegate;
@class HSUTableCellData;
@class HSUUIEvent;
@protocol TTTAttributedLabelDelegate;
@class HSUBaseViewController;
@interface HSUBaseDataSource : NSObject <UITableViewDataSource>

//@property (nonatomic, strong) NSUserDefaults *cacheUserDefaults;

@property (nonatomic, assign) NSInteger count;
@property (nonatomic, weak) id<HSUBaseDataSourceDelegate> delegate;
@property (nonatomic, weak) id<TTTAttributedLabelDelegate> attributeLabelDelegate;
@property (nonatomic, readonly) NSArray *allData;
@property (atomic, strong) NSMutableArray *data;
//@property (nonatomic, assign, getter = isLoading) BOOL loading;
@property (nonatomic, assign) NSUInteger loadingCount;
@property (nonatomic, assign) NSUInteger requestCount;
@property (nonatomic, assign) BOOL noMoreData;

- (NSDictionary *)rawDataAtIndex:(NSInteger)index;
- (NSMutableDictionary *)renderDataAtIndex:(NSInteger)index;
- (HSUTableCellData *)dataAtIndex:(NSInteger)index;
- (NSDictionary *)rawDataAtIndexPath:(NSIndexPath *)indexPath;
- (NSMutableDictionary *)renderDataAtIndexPath:(NSIndexPath *)indexPath;
- (HSUTableCellData *)dataAtIndexPath:(NSIndexPath *)indexPath;
- (void)addEventWithName:(NSString *)name target:(id)target action:(SEL)action events:(UIControlEvents)events;

- (void)refresh;
- (void)loadMore;
- (void)saveCache;
+ (id)dataSourceWithDelegate:(id<HSUBaseDataSourceDelegate>)delegate useCache:(BOOL)useCahce;
+ (NSString *)cacheKey;
- (void)removeCellData:(HSUTableCellData *)cellData;
+ (void)checkUnreadForViewController:(HSUBaseViewController *)viewController;

@end


@protocol HSUBaseDataSourceDelegate <NSObject>

- (void)reloadData;
- (void)dataSource:(HSUBaseDataSource *)dataSource insertRowsFromIndex:(NSUInteger)fromIndex length:(NSUInteger)length;
- (void)dataSource:(HSUBaseDataSource *)dataSource didFinishRefreshWithError:(NSError *)error;
- (void)dataSource:(HSUBaseDataSource *)dataSource didFinishLoadMoreWithError:(NSError *)error;
- (void)dataSourceDidFindUnread:(HSUBaseDataSource *)dataSource;
- (void)preprocessDataSourceForRender:(HSUBaseDataSource *)dataSource;

@end