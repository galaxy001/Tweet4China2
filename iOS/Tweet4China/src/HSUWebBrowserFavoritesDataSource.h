//
//  HSUWebBrowserFavoritesDataSource.h
//  Tweet4China
//
//  Created by Jason Hsu on 14-1-10.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HSUWebBrowserFavoritesDataSource : NSObject <UITableViewDataSource>

@property (nonatomic, strong) NSMutableArray *favorites;

@end
