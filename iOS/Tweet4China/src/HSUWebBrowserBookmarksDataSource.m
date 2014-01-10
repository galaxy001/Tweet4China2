//
//  HSUWebBrowserFavoritesDataSource.m
//  Tweet4China
//
//  Created by Jason Hsu on 14-1-10.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUWebBrowserBookmarksDataSource.h"

#define bookmark_cache_key @"web_browser_bookmarks"

@interface HSUWebBrowserBookmarksDataSource ()

@end

@implementation HSUWebBrowserBookmarksDataSource

- (void)dealloc
{
    notification_remove_observer(self);
}

- (id)init
{
    self = [super init];
    if (self) {
        [self relaodBookmarks];
        notification_add_observer(HSUBookmarkUpdatedNotification, self, @selector(relaodBookmarks));
    }
    return self;
}

- (void)relaodBookmarks
{
    NSMutableArray *bookmarks = [[[NSUserDefaults standardUserDefaults] objectForKey:bookmark_cache_key] mutableCopy];
    if (!bookmarks) {
        bookmarks = @[].mutableCopy;
        [bookmarks addObject:@{@"title": @"Google", @"url": @"http://www.google.com"}];
        [bookmarks addObject:@{@"title": @"Facebook", @"url": @"http://facebook.com"}];
        [bookmarks addObject:@{@"title": @"Twitter", @"url": @"http://twitter.com"}];
        [bookmarks addObject:@{@"title": @"Google+", @"url": @"http://plus.google.com"}];
        [bookmarks addObject:@{@"title": @"Wikipedia", @"url": @"http://wikipedia.org"}];
        [[NSUserDefaults standardUserDefaults] setObject:bookmarks forKey:bookmark_cache_key];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    self.bookmarks = bookmarks;
}

- (void)addBookmarkWithTitle:(NSString *)title url:(NSString *)url
{
    [self.bookmarks addObject:@{@"title": title, @"url": url}];
    [[NSUserDefaults standardUserDefaults] setObject:self.bookmarks forKey:bookmark_cache_key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)removeBookmarkAtIndex:(NSUInteger)index
{
    [self.bookmarks removeObjectAtIndex:index];
    [[NSUserDefaults standardUserDefaults] setObject:self.bookmarks forKey:bookmark_cache_key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.bookmarks.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"bookmark_cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"bookmark_cell"];
    }
    NSString *title = self.bookmarks[indexPath.row][@"title"];
    cell.textLabel.text = title;
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self removeBookmarkAtIndex:indexPath.row];
    [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

@end
