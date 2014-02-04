//
//  T4CListTimelineViewController.m
//  Tweet4China
//
//  Created by Jason Hsu on 14-2-4.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "T4CListTimelineViewController.h"
#import "HSUEditListViewController.h"

@interface T4CListTimelineViewController () <HSUEditListViewControllerDelegate>

@property (nonatomic, weak) UISegmentedControl *typeControl;
@property (nonatomic, strong) NSMutableArray *tweetsData;
@property (nonatomic, strong) NSMutableArray *subscribersData;
@property (nonatomic, strong) NSMutableArray *membersData;

@end

@implementation T4CListTimelineViewController

- (id)init
{
    self = [super init];
    if (self) {
        self.useCache = NO;
        self.pullToRefresh = NO;
        self.tweetsData = @[].mutableCopy;
        self.subscribersData = @[].mutableCopy;
        self.membersData = @[].mutableCopy;
        self.data = self.tweetsData;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = self.list[@"name"];
    UISegmentedControl *typeControl = [[UISegmentedControl alloc] initWithItems:@[_("Tweets"), _("Members"), _("Subscribers")]];
    self.typeControl = typeControl;
    [self.tableView addSubview:typeControl];
    typeControl.selectedSegmentIndex = 0;
    [typeControl addTarget:self action:@selector(typeControlValueChanged:) forControlEvents:UIControlEventValueChanged];
    [typeControl setWidth:100 forSegmentAtIndex:0];
    [typeControl setWidth:100 forSegmentAtIndex:1];
    [typeControl setWidth:100 forSegmentAtIndex:2];
    
    if ([self.list[@"user"][@"screen_name"] isEqualToString:MyScreenName]) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                                  initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
                                                  target:self
                                                  action:@selector(editList)];
    } else {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                                  initWithTitle:[self.list[@"following"] boolValue] ? _("Unsubscribe") : _("Subscribe")
                                                  style:UIBarButtonItemStylePlain
                                                  target:self
                                                  action:@selector(subscribe)];
    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    CGFloat originTableViewContentInsetTop = 0;
    originTableViewContentInsetTop = status_height + navbar_height;
    self.tableView.contentInset = edi(originTableViewContentInsetTop + 10 + self.typeControl.height + 10, 0, tabbar_height, 0);
    self.typeControl.topCenter = ccp(self.view.width/2, originTableViewContentInsetTop + 10 - self.tableView.contentInset.top);
}

- (void)editList
{
    HSUEditListViewController *editVC = [[HSUEditListViewController alloc] initWithList:self.list];
    editVC.delegate = self;
    HSUNavigationController *nav = [[HSUNavigationController alloc] initWithRootViewController:editVC];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)editListViewControllerDidSaveList:(NSDictionary *)list
{
    self.navigationItem.title = list[@"name"];
    self.list = list;
}

- (void)subscribe
{
    __weak typeof(self)weakSelf = self;
    [SVProgressHUD showWithStatus:nil];
    if ([self.list[@"following"] boolValue]) {
        [twitter unsubscribeListWithListID:self.list[@"id_str"] success:^(id responseObj) {
            NSMutableDictionary *newList = weakSelf.list.mutableCopy;
            newList[@"following"] = @NO;
            weakSelf.list = newList;
            weakSelf.navigationItem.rightBarButtonItem.title = _("Subscribe");
            [SVProgressHUD dismiss];
        } failure:^(NSError *error) {
            [SVProgressHUD showErrorWithStatus:_("Unsubscribe failed")];
        }];
    } else {
        [twitter subscribeListWithListID:self.list[@"id_str"] success:^(id responseObj) {
            NSMutableDictionary *newList = weakSelf.list.mutableCopy;
            newList[@"following"] = @YES;
            weakSelf.list = newList;
            weakSelf.navigationItem.rightBarButtonItem.title = _("Unsubscribe");
            [SVProgressHUD dismiss];
        } failure:^(NSError *error) {
            [SVProgressHUD showErrorWithStatus:_("Subscribe failed")];
        }];
    }
}

- (void)typeControlValueChanged:(UISegmentedControl *)typeControl
{
    if (typeControl.selectedSegmentIndex == 0) {
        self.data = self.tweetsData;
    } else if (typeControl.selectedSegmentIndex == 1) {
        self.data = self.membersData;
    } else if (typeControl.selectedSegmentIndex == 2) {
        self.data = self.subscribersData;
    }
    [self.tableView reloadData];
    if (self.data.count == 0) {
        [self refresh];
    }
}

- (NSString *)apiString
{
    if (self.typeControl.selectedSegmentIndex == 0) {
        return @"lists/statuses";
    } else if (self.typeControl.selectedSegmentIndex == 1) {
        return @"lists/subscribers";
    } else if (self.typeControl.selectedSegmentIndex == 2) {
        return @"lists/members";
    }
    return nil;
}

- (NSDictionary *)requestParams
{
    return @{@"list_id": self.list[@"id"]};
}

- (NSString *)dataKey
{
    if (self.typeControl.selectedSegmentIndex == 1) {
        return @"users";
    } else if (self.typeControl.selectedSegmentIndex == 2) {
        return @"users";
    }
    return nil;
}

@end
