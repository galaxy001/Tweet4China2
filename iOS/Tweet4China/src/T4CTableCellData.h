//
//  T4CTableCellData.h
//  Tweet4China
//
//  Created by Jason Hsu on 14-1-15.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import <Foundation/Foundation.h>

@class T4CTableViewController;
@interface T4CTableCellData : NSObject

@property (nonatomic, copy) NSString *dataType;
@property (nonatomic, strong) NSDictionary *rawData;
@property (nonatomic) CGFloat cellHeight;
@property (nonatomic) CGFloat textHeight;
@property (nonatomic, weak) id target;
@property (nonatomic, strong) NSMutableDictionary *events;
@property (nonatomic, assign) BOOL unread;
@property (nonatomic, readonly) T4CTableViewController *tableVC;

- (id)initWithRawData:(NSDictionary *)rawData dataType:(NSString *)dataType;
- (id)initWithCacheData:(NSDictionary *)cacheData;

- (NSDictionary *)cacheData;

@end
