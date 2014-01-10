//
//  HSUWebBrowserFavoritesDataSource.h
//  Tweet4China
//
//  Created by Jason Hsu on 14-1-10.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HSUWebBrowserBookmarksDataSource : NSObject <UITableViewDataSource>

@property (nonatomic, strong) NSMutableArray *bookmarks;

- (void)addBookmarkWithTitle:(NSString *)title url:(NSString *)url;

@end
