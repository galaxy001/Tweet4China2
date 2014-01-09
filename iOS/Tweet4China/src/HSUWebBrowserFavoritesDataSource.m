//
//  HSUWebBrowserFavoritesDataSource.m
//  Tweet4China
//
//  Created by Jason Hsu on 14-1-10.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUWebBrowserFavoritesDataSource.h"

@interface HSUWebBrowserFavoritesDataSource ()

@end

@implementation HSUWebBrowserFavoritesDataSource

- (id)init
{
    self = [super init];
    if (self) {
        self.favorites = [[NSUserDefaults standardUserDefaults] objectForKey:@"web_browser_favorites"];
        self.favorites = @[@{@"title": @"Google", @"url": @"http://www.google.com"}, @{@"title": @"Twitter", @"url": @"http://twitter.com"}].mutableCopy;
    }
    return self;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.favorites.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"favorite_cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"favorite_cell"];
    }
    NSString *title = self.favorites[indexPath.row][@"title"];
    cell.textLabel.text = title;
    return cell;
}

@end
