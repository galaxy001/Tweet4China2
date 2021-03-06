//
//  HSUAddBookMarkViewController.m
//  Tweet4China
//
//  Created by Jason Hsu on 14-1-14.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUAddBookmarkViewController.h"
#import <RETableViewManager/RETableViewOptionsController.h>

@interface HSUAddBookmarkViewController ()

@property (nonatomic, weak) RETextItem *nameItem, *urlItem;

@end

@implementation HSUAddBookmarkViewController

- (id)init
{
    return [self initWithStyle:UITableViewStyleGrouped];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    RETableViewSection *section = [RETableViewSection section];
    [self.manager addSection:section];
    
    __weak typeof(self)weakSelf = self;
    RETextItem *nameItem = [RETextItem itemWithTitle:_("Name")];
    self.nameItem = nameItem;
    [section addItem:nameItem];
    nameItem.onChange = ^(RETextItem *item) {
        if (weakSelf.nameItem.value.length && weakSelf.urlItem.value.length) {
            self.navigationItem.rightBarButtonItem.enabled = YES;
        }
    };
    
    RETextItem *urlItem = [RETextItem itemWithTitle:_("Address")];
    self.urlItem = urlItem;
    [section addItem:urlItem];
    urlItem.onChange = ^(RETextItem *item) {
        if (weakSelf.nameItem.value.length && weakSelf.urlItem.value.length) {
            self.navigationItem.rightBarButtonItem.enabled = YES;
        }
    };
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
                                             initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                             target:self
                                             action:@selector(dismiss)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                              initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                              target:self
                                              action:@selector(save)];
    self.navigationItem.rightBarButtonItem.enabled = NO;
}

- (void)save
{
    NSString *name = self.nameItem.value;
    NSString *url = self.urlItem.value;
    
    if (!name || !url) {
        return;
    }
    
    if (![url hasPrefix:@"http"]) {
        url = S(@"http://%@", url);
    }
    
    NSMutableArray *bookmarks = [[[NSUserDefaults standardUserDefaults] objectForKey:@"bookmarks"] mutableCopy];
    [bookmarks addObject:@{@"name": name, @"url": url}];
    [[NSUserDefaults standardUserDefaults] setObject:bookmarks forKey:@"bookmarks"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self dismiss];
}

@end
