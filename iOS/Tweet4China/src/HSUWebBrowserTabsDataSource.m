//
//  HSUWebBrowserTabsDataSource.m
//  Tweet4China
//
//  Created by Jason Hsu on 14-1-10.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUWebBrowserTabsDataSource.h"
#import "HSUWebBrowserTabCell.h"

@implementation HSUWebBrowserTabsDataSource

#define tab_cache_key @"web_browser_tabs"

- (id)init
{
    self = [super init];
    if (self) {
        NSMutableArray *tabs = [[[NSUserDefaults standardUserDefaults] objectForKey:tab_cache_key] mutableCopy];
        if (!tabs) {
            tabs = @[].mutableCopy;
            [[NSUserDefaults standardUserDefaults] setObject:tabs forKey:tab_cache_key];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        self.tabs = tabs;
    }
    return self;
}

- (void)addTabAtIndex:(NSUInteger)index title:(NSString *)title url:(NSString *)url
{
    NSDictionary *tab = @{@"title": title, @"url": url};
    if (index < self.tabs.count) {
        [self.tabs replaceObjectAtIndex:index withObject:tab];
    } else {
        [self.tabs addObject:tab];
    }
    [[NSUserDefaults standardUserDefaults] setObject:self.tabs forKey:tab_cache_key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)removeTabAtIndex:(NSUInteger)index
{
    [self.tabs removeObjectAtIndex:index];
    [[NSUserDefaults standardUserDefaults] setObject:self.tabs forKey:tab_cache_key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.tabs.count + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    HSUWebBrowserTabCell *cell = [tableView dequeueReusableCellWithIdentifier:@"tab_cell"];
    if (!cell) {
        cell = [[HSUWebBrowserTabCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"tab_cell"];
        [cell.favoriteButton addTarget:self action:@selector(favoriteButtonTouched:) forControlEvents:UIControlEventTouchUpInside];
        [cell.favoriteButton addTarget:tableView action:@selector(reloadData) forControlEvents:UIControlEventTouchUpInside];
    }
    if (indexPath.row < self.tabs.count) {
        NSString *title = self.tabs[indexPath.row][@"title"];
        cell.textLabel.text = title;
        cell.favoriteButton.selected = [self.tabs[indexPath.row][@"selected"] boolValue];
        cell.favoriteButton.tag = indexPath.row;
        cell.favoriteButton.hidden = NO;
    } else {
        cell.textLabel.text = _(@"New Tab");
        cell.favoriteButton.selected = NO;
        cell.favoriteButton.hidden = YES;
    }
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.row < self.tabs.count;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self removeTabAtIndex:indexPath.row];
    [tableView reloadData];
}

- (void)favoriteButtonTouched:(UIButton *)favoriteButton
{
    NSMutableDictionary *tab = [[self.tabs[favoriteButton.tag] mutableCopy] mutableCopy];
    
    if (![tab[@"selected"] boolValue]) {
        NSMutableArray *bookmarks = [[[NSUserDefaults standardUserDefaults] objectForKey:@"web_browser_bookmarks"] mutableCopy];
        [bookmarks addObject:tab];
        [[NSUserDefaults standardUserDefaults] setObject:bookmarks forKey:@"web_browser_bookmarks"];
        notification_post(HSUBookmarkUpdatedNotification);
    }
    
    tab[@"selected"] = @(![tab[@"selected"] boolValue]);
    [self.tabs replaceObjectAtIndex:favoriteButton.tag withObject:tab];
    [[NSUserDefaults standardUserDefaults] setObject:self.tabs forKey:tab_cache_key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
