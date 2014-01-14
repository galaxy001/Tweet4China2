//
//  HSUWebBrowserViewController.m
//  Tweet4China
//
//  Created by Jason Hsu on 14-1-14.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUWebBrowserViewController.h"
#import <RETableViewManager/RETableViewOptionsController.h>
#import <SVWebViewController/SVWebViewController.h>
#import "HSUAddBookMarkViewController.h"

@interface HSUWebBrowserViewController ()

@property (nonatomic, weak) RETableViewSection *bookmarkSection;
@property (nonatomic, weak) RETableViewSection *tabSection;
@property (nonatomic, weak) RETableViewItem *currentItem;
@property (nonatomic, strong) SVModalWebViewController *webViewController;

@end

@implementation HSUWebBrowserViewController

- (id)init
{
    return [self initWithStyle:UITableViewStyleGrouped];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                              initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                              target:self
                                              action:@selector(add)];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSArray *bookmarks = [[NSUserDefaults standardUserDefaults] arrayForKey:@"bookmarks"];
    if (!bookmarks) {
        bookmarks = @[@{@"name": @"Google", @"url": @"http://www.google.com/ncr"},
                      @{@"name": @"Facebook", @"url": @"http://www.facebook.com"},
                      @{@"name": @"Wikipedia", @"url": @"http://www.wikipedia.com"},
                      @{@"name": @"Twitter", @"url": @"http://twitter.com"},];
        [[NSUserDefaults standardUserDefaults] setObject:bookmarks forKey:@"bookmarks"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    if (!self.bookmarkSection || bookmarks.count != self.bookmarkSection.items.count) {
        [self.manager removeSection:self.bookmarkSection];
        
        __weak typeof(self)weakSelf = self;
        RETableViewSection *section = [RETableViewSection section];
        self.bookmarkSection = section;
        [self.manager addSection:section];
        
        for (NSDictionary *bookmark in bookmarks) {
            NSString *name = bookmark[@"name"];
            NSString *url = bookmark[@"url"];
            
            [section addItem:
             [RETableViewItem itemWithTitle:name
                              accessoryType:UITableViewCellAccessoryDisclosureIndicator
                           selectionHandler:^(RETableViewItem *item)
              {
                  [item deselectRowAnimated:YES];
                  
                  weakSelf.webViewController = [[SVModalWebViewController alloc] initWithAddress:url];
                  weakSelf.webViewController.modalPresentationStyle = UIModalPresentationPageSheet;
                  [weakSelf presentViewController:weakSelf.webViewController animated:YES completion:NULL];
              }]];
        }
    }
    
    if (self.webViewController) {
        
        NSString *title = [[self.webViewController.viewControllers.lastObject navigationItem] title];
        if ([title length]) {
            title = [title length] ? S(@"%@ - %@", _("Current"), title) : _("Current");
        }
        
        [self.manager removeSection:self.tabSection];
        RETableViewSection *section = [RETableViewSection section];
        self.tabSection = section;
        [self.manager addSection:section];
        
        __weak typeof(self)weakSelf = self;
        RETableViewItem *currentItem = [RETableViewItem itemWithTitle:title
                                                        accessoryType:UITableViewCellAccessoryNone
                                                     selectionHandler:^(RETableViewItem *item)
                                        {
                                            [weakSelf presentViewController:weakSelf.webViewController animated:YES completion:nil];
                                        }];
        self.currentItem = currentItem;
        [self.tabSection addItem:currentItem];
    }
    
    [self.tableView reloadData];
}

- (void)add
{
    HSUAddBookMarkViewController *viewController = [[HSUAddBookMarkViewController alloc] init];
    HSUNavigationController *nav = [[HSUNavigationController alloc] initWithRootViewController:viewController];
    [self presentViewController:nav animated:YES completion:nil];
}

@end
