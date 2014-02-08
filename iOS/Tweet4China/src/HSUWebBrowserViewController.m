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
#import "HSUAddBookmarkViewController.h"
#import "HSUSettingsViewController.h"

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
    
    UIButton *actionButton = [[UIButton alloc] init];
    [actionButton addTarget:self action:@selector(_actionButtonTouched) forControlEvents:UIControlEventTouchUpInside];
    if (Sys_Ver >= 7) {
        [actionButton setImage:[UIImage imageNamed:@"icn_nav_action_ios7"] forState:UIControlStateNormal];
    } else {
        [actionButton setImage:[UIImage imageNamed:@"icn_nav_action"] forState:UIControlStateNormal];
    }
    [actionButton sizeToFit];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:actionButton];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                              initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                              target:self
                                              action:@selector(add)];
    
    notification_add_observer(HSUSettingUserAgentChangedNotification, self, @selector(userAgentChanged));
    
    self.navigationItem.title = _("Browser");
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.tabSection removeAllItems];
    if (!self.tabSection) {
        RETableViewSection *section = [RETableViewSection section];
        self.tabSection = section;
        [self.manager addSection:section];
    }
    
    __weak typeof(self)weakSelf = self;
    RETableViewItem *openAddressItem = [[RETableViewItem alloc] initWithTitle:_("Open Address from Pasteboard") accessoryType:UITableViewCellAccessoryNone selectionHandler:^(RETableViewItem *item) {
        NSString *url = [UIPasteboard generalPasteboard].string;
        if (![url hasPrefix:@"http"]) {
            url = S(@"http://%@", url);
        }
        NSURL *URL = [NSURL URLWithString:url];
        if (URL) {
            weakSelf.webViewController = [[SVModalWebViewController alloc] initWithAddress:url];
//            weakSelf.webViewController.modalPresentationStyle = UIModalPresentationPageSheet;
            [weakSelf presentViewController:weakSelf.webViewController animated:YES completion:NULL];
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:_("Address not found in your pasteboard") delegate:nil cancelButtonTitle:_("OK") otherButtonTitles:nil, nil];
            [alert show];
        }
    }];
    [self.tabSection addItem:openAddressItem];
    
    if (self.webViewController) {
        
        NSString *title = [[self.webViewController.viewControllers.lastObject navigationItem] title];
        if ([title length]) {
            title = S(@"%@ - %@", _("Current"), title);
        } else {
            title = S(@"%@ - %@", _("Current"), _("browser_tab_loading"));
        }
        
        RETableViewItem *currentItem = [RETableViewItem itemWithTitle:title
                                                        accessoryType:UITableViewCellAccessoryNone
                                                     selectionHandler:^(RETableViewItem *item)
                                        {
                                            [weakSelf presentViewController:weakSelf.webViewController animated:YES completion:nil];
                                        }];
        self.currentItem = currentItem;
        [self.tabSection addItem:currentItem];
    }
    
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
        RETableViewSection *section = [RETableViewSection sectionWithHeaderTitle:_("Bookmarks")];
        self.bookmarkSection = section;
        [self.manager addSection:section];
        
        for (NSDictionary *bookmark in bookmarks) {
            NSString *name = bookmark[@"name"];
            NSString *url = bookmark[@"url"];
            
            RETableViewItem *bookmarkItem = [RETableViewItem itemWithTitle:name];
            bookmarkItem.accessoryType = UITableViewCellAccessoryNone;
            bookmarkItem.selectionHandler = ^(RETableViewItem *item)
            {
                [item deselectRowAnimated:YES];
                
                weakSelf.webViewController = [[SVModalWebViewController alloc] initWithAddress:url];
//                weakSelf.webViewController.modalPresentationStyle = UIModalPresentationPageSheet;
                [weakSelf presentViewController:weakSelf.webViewController animated:YES completion:NULL];
            };
            bookmarkItem.deletionHandler = ^(RETableViewItem *item) {
                NSMutableArray *bookmarks = [[[NSUserDefaults standardUserDefaults] arrayForKey:@"bookmarks"] mutableCopy];
                NSInteger index = [bookmarks indexOfObject:bookmark];
                if (bookmarks.count > index) {
                    [bookmarks removeObjectAtIndex:index];
                    [[NSUserDefaults standardUserDefaults] setObject:bookmarks forKey:@"bookmarks"];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                }
            };
            bookmarkItem.editingStyle = UITableViewCellEditingStyleDelete;
            [section addItem:bookmarkItem];
        }
    }
    
    [self.tableView reloadData];
}

- (void)add
{
    HSUAddBookmarkViewController *viewController = [[HSUAddBookmarkViewController alloc] init];
    HSUNavigationController *nav = [[HSUNavigationController alloc] initWithRootViewController:viewController];
    nav.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)_actionButtonTouched
{
    HSUSettingsViewController *settingsVC = [[HSUSettingsViewController alloc] init];
    UINavigationController *nav = [[HSUNavigationController alloc] initWithNavigationBarClass:[HSUNavigationBarLight class] toolbarClass:nil];
    nav.modalPresentationStyle = UIModalPresentationFormSheet;
    nav.viewControllers = @[settingsVC];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)userAgentChanged
{
    self.webViewController = nil;
}

- (BOOL)shouldAutorotate
{
    return IPAD || UIInterfaceOrientationIsLandscape(self.interfaceOrientation);
}

@end
