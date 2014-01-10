//
//  HSUWebBrowserTabsDataSource.h
//  Tweet4China
//
//  Created by Jason Hsu on 14-1-10.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HSUWebBrowserTabsDataSource : NSObject <UITableViewDataSource>

@property (nonatomic, strong) NSMutableArray *tabs;

- (void)addTabAtIndex:(NSUInteger)index title:(NSString *)title url:(NSString *)url;
- (void)removeAllTabs;

@end
