//
//  HSUListsViewController.m
//  Tweet4China
//
//  Created by Jason Hsu on 2013/12/2.
//  Copyright (c) 2013年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUListsViewController.h"
#import "HSUListViewController.h"
#import "HSUListTweetsDataSource.h"
#import "HSUListViewController.h"
#import "HSUSubscribedListsDataSource.h"
#import "HSUMemberOfListsDataSource.h"
#import "HSUEditListViewController.h"

@interface HSUListsViewController () <HSUEditListViewControllerDelegate>

@property (nonatomic, weak) UISegmentedControl *typeControl;
@property (nonatomic, copy) NSString *screenName;

@property (nonatomic, strong) HSUSubscribedListsDataSource *subscribedListsDataSource;
@property (nonatomic, strong) HSUMemberOfListsDataSource *memberOfListsDataSource;

@end

@implementation HSUListsViewController

- (instancetype)initWithScreenName:(NSString *)screenName
{
    HSUSubscribedListsDataSource *dataSource = [[HSUSubscribedListsDataSource alloc] initWithScreenName:screenName];
    self = [super initWithDataSource:dataSource];
    if (self) {
        self.screenName = screenName;
        self.subscribedListsDataSource = dataSource;
        self.dataSource = dataSource;
        self.useRefreshControl = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = _("List");
    
    UISegmentedControl *typeControl = [[UISegmentedControl alloc] initWithItems:@[_("Subscribed"), _("Member of")]];
    self.typeControl = typeControl;
    [self.tableView addSubview:typeControl];
    typeControl.selectedSegmentIndex = 0;
    [typeControl addTarget:self action:@selector(typeControlValueChanged:) forControlEvents:UIControlEventValueChanged];
    if (Sys_Ver >= 7) {
        [typeControl setWidth:100 forSegmentAtIndex:0];
        [typeControl setWidth:100 forSegmentAtIndex:1];
    } else {
        [typeControl setWidth:150 forSegmentAtIndex:0];
        [typeControl setWidth:150 forSegmentAtIndex:1];
        typeControl.transform = CGAffineTransformMakeScale(.7, .7);
    }
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                              initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                              target:self
                                              action:@selector(createList)];
    
    [self.dataSource refresh];
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    HSUTableCellData *data = [self.dataSource dataAtIndexPath:indexPath];
    if ([data.dataType isEqualToString:kDataType_List]) {
        HSUTableCellData *cellData = [self.dataSource dataAtIndexPath:indexPath];
        HSUListViewController *listVC = [[HSUListViewController alloc] initWithList:cellData.rawData];
        listVC.title = cellData.rawData[@"description"];
        [self.navigationController pushViewController:listVC animated:YES];
        return;
    }
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
}

- (void)typeControlValueChanged:(UISegmentedControl *)segmentedControl
{
    if (segmentedControl.selectedSegmentIndex == 0) {
        self.dataSource = self.subscribedListsDataSource;
    } else if (segmentedControl.selectedSegmentIndex == 1) {
        if (!self.memberOfListsDataSource) {
            self.memberOfListsDataSource = [[HSUMemberOfListsDataSource alloc] initWithScreenName:self.screenName];
        }
        self.dataSource = self.memberOfListsDataSource;
        self.dataSource.delegate = self;
    }
    self.tableView.dataSource = self.dataSource;
    if (self.dataSource.count == 0) {
        [self.dataSource refresh];
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
    HSUTableCellData *cellData = [[HSUTableCellData alloc] initWithRawData:list dataType:kDataType_List];
    [self.subscribedListsDataSource.data addObject:cellData];
    [self.tableView reloadData];
}

@end
