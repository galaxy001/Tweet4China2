//
//  T4CListsViewController.m
//  Tweet4China
//
//  Created by Jason Hsu on 14-2-4.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "T4CListsViewController.h"
#import "HSUEditListViewController.h"

@interface T4CListsViewController () <HSUEditListViewControllerDelegate>

@property (nonatomic, weak) UISegmentedControl *typeControl;
@property (nonatomic, strong) NSMutableArray *subData, *memData;

@end

@implementation T4CListsViewController

- (id)init
{
    self = [super init];
    if (self) {
        self.useCache = NO;
        self.pullToRefresh = NO;
        self.infiniteScrolling = NO;
        self.subData = self.data;
        self.memData = @[].mutableCopy;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = _("Lists");
    
    UISegmentedControl *typeControl = [[UISegmentedControl alloc] initWithItems:@[_("Subscribed"), _("Member of")]];
    self.typeControl = typeControl;
    [self.tableView addSubview:typeControl];
    typeControl.selectedSegmentIndex = 0;
    [typeControl addTarget:self action:@selector(typeControlValueChanged:) forControlEvents:UIControlEventValueChanged];
    [typeControl setWidth:100 forSegmentAtIndex:0];
    [typeControl setWidth:100 forSegmentAtIndex:1];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                              initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                              target:self
                                              action:@selector(createList)];
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

- (void)typeControlValueChanged:(UISegmentedControl *)segmentedControl
{
    if (segmentedControl.selectedSegmentIndex == 0) {
        self.memData = self.data;
        self.data = self.subData;
    } else if (segmentedControl.selectedSegmentIndex == 1) {
        self.subData = self.data;
        self.data = self.memData;
    }
    if (!self.data.count) {
        [self refresh];
    }
    [self.tableView reloadData];
}

- (void)createList
{
    HSUEditListViewController *editListVC = [[HSUEditListViewController alloc] initWithList:nil];
    editListVC.delegate = self;
    HSUNavigationController *nav = [[HSUNavigationController alloc] initWithRootViewController:editListVC];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)editListViewControllerDidSaveList:(NSDictionary *)list
{
    if (self.typeControl.selectedSegmentIndex == 1) {
        self.typeControl.selectedSegmentIndex = 0;
        self.memData = self.data;
        self.data = self.subData;
    }
    T4CTableCellData *cellData = [self createTableCellDataWithRawData:list];
    [self.data insertObject:cellData atIndex:0];
    [self.tableView reloadData];
}

- (NSString *)apiString
{
    if (self.typeControl.selectedSegmentIndex == 0) {
        return @"lists/list";
    } else if (self.typeControl.selectedSegmentIndex == 1) {
        return @"lists/memberships";
    }
    return nil;
}

- (NSDictionary *)requestParams
{
    return @{@"screen_name": self.screenName};
}

- (NSString *)dataKey
{
    if (self.typeControl.selectedSegmentIndex == 1) { // member of
        return @"lists";
    }
    return nil;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *list = [self.data[indexPath.row] rawData];
    return [list[@"user"][@"screen_name"] isEqualToString:MyScreenName];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.typeControl.selectedSegmentIndex == 0) {
        NSDictionary *list = [self.data[indexPath.row] rawData];
        [SVProgressHUD showWithStatus:nil];
        [twitter deleteListWithListID:list[@"id_str"] success:^(id responseObj) {
            [SVProgressHUD dismiss];
            [self.data removeObjectAtIndex:indexPath.row];
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        } failure:^(NSError *error) {
            [SVProgressHUD showErrorWithStatus:_("Delete List failed")];
        }];
    }
}

- (NSUInteger)requestCount
{
    return 0;
}

@end
