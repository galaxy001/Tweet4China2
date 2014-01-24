//
//  HSUListViewController.m
//  Tweet4China
//
//  Created by Jason Hsu on 2013/12/2.
//  Copyright (c) 2013年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUListViewController.h"
#import "HSUEditListViewController.h"
#import "HSUListTweetsDataSource.h"
#import "HSUListSubscribersDataSource.h"
#import "HSUListMembersDataSource.h"

@interface HSUListViewController () <HSUEditListViewControllerDelegate>

@property (nonatomic, weak) UISegmentedControl *typeControl;
@property (nonatomic, strong) HSUListTweetsDataSource *tweetsDataSource;
@property (nonatomic, strong) HSUListSubscribersDataSource *subscribersDataSource;
@property (nonatomic, strong) HSUListMembersDataSource *membersDataSource;

@end

@implementation HSUListViewController

- (id)initWithList:(NSDictionary *)list
{
    self = [super init];
    if (self) {
        self.tweetsDataSource = [[HSUListTweetsDataSource alloc] initWithList:list];
        self.tweetsDataSource.delegate = self;
        self.subscribersDataSource = [[HSUListSubscribersDataSource alloc] initWithList:list];
        self.subscribersDataSource.delegate = self;
        self.membersDataSource = [[HSUListMembersDataSource alloc] initWithList:list];
        self.membersDataSource.delegate = self;
        self.dataSource = self.tweetsDataSource;
        self.useRefreshControl = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UISegmentedControl *typeControl = [[UISegmentedControl alloc] initWithItems:@[_("Tweets"), _("Members"), _("Subscribers")]];
    self.typeControl = typeControl;
    [self.tableView addSubview:typeControl];
    typeControl.selectedSegmentIndex = 0;
    [typeControl addTarget:self action:@selector(typeControlValueChanged:) forControlEvents:UIControlEventValueChanged];
    if (Sys_Ver >= 7) {
        [typeControl setWidth:100 forSegmentAtIndex:0];
        [typeControl setWidth:100 forSegmentAtIndex:1];
        [typeControl setWidth:100 forSegmentAtIndex:2];
    } else {
        [typeControl setWidth:150 forSegmentAtIndex:0];
        [typeControl setWidth:150 forSegmentAtIndex:1];
        [typeControl setWidth:150 forSegmentAtIndex:2];
        typeControl.transform = CGAffineTransformMakeScale(.7, .7);
    }
    
    if ([self.tweetsDataSource.list[@"user"][@"screen_name"] isEqualToString:MyScreenName]) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                                  initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
                                                  target:self
                                                  action:@selector(editList)];
    } else {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                                  initWithTitle:[self.tweetsDataSource.list[@"following"] boolValue] ? _("Unsubscribe") : _("Subscribe")
                                                  style:UIBarButtonItemStylePlain
                                                  target:self
                                                  action:@selector(subscribe)];
    }
    
    self.tableView.dataSource = self.dataSource;
    [self.dataSource refresh];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationItem.title = self.tweetsDataSource.list[@"name"];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    CGFloat originTableViewContentInsetTop = 0;
    if (Sys_Ver >= 7) {
        originTableViewContentInsetTop = status_height + navbar_height;
    }
    self.tableView.contentInset = edi(originTableViewContentInsetTop + 10 + self.typeControl.height + 10, 0, tabbar_height, 0);
    self.typeControl.topCenter = ccp(self.view.width/2, originTableViewContentInsetTop + 10 - self.tableView.contentInset.top);
}

- (void)editList
{
    HSUEditListViewController *editVC = [[HSUEditListViewController alloc] initWithList:self.tweetsDataSource.list];
    editVC.delegate = self;
    HSUNavigationController *nav = [[HSUNavigationController alloc] initWithRootViewController:editVC];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)editListViewControllerDidSaveList:(NSDictionary *)list
{
    self.navigationItem.title = list[@"name"];
    self.tweetsDataSource.list = list;
}

- (void)subscribe
{
    __weak typeof(self)weakSelf = self;
    [SVProgressHUD showWithStatus:nil];
    if ([self.tweetsDataSource.list[@"following"] boolValue]) {
        [twitter subscribeListWithListID:self.tweetsDataSource.list[@"id_str"] success:^(id responseObj) {
            NSMutableDictionary *newList = weakSelf.tweetsDataSource.list.mutableCopy;
            newList[@"following"] = @NO;
            weakSelf.tweetsDataSource.list = newList;
            weakSelf.navigationItem.rightBarButtonItem.title = _("Subscribe");
            [SVProgressHUD dismiss];
        } failure:^(NSError *error) {
            [SVProgressHUD showErrorWithStatus:_("Unsubscribe failed")];
        }];
    } else {
        [twitter subscribeListWithListID:self.tweetsDataSource.list[@"id_str"] success:^(id responseObj) {
            NSMutableDictionary *newList = weakSelf.tweetsDataSource.list.mutableCopy;
            newList[@"following"] = @YES;
            weakSelf.tweetsDataSource.list = newList;
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
        self.dataSource = self.tweetsDataSource;
    } else if (typeControl.selectedSegmentIndex == 1) {
        self.dataSource = self.membersDataSource;
    } else if (typeControl.selectedSegmentIndex == 2) {
        self.dataSource = self.subscribersDataSource;
    }
    self.tableView.dataSource = self.dataSource;
    [self.tableView reloadData];
    if (self.dataSource.count == 0) {
        [self.dataSource refresh];
    }
}

@end
