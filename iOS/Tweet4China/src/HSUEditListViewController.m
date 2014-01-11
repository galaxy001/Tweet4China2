//
//  HSUEditListViewController.m
//  Tweet4China
//
//  Created by Jason Hsu on 14-1-11.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUEditListViewController.h"
#import <RETableViewManager/RETableViewManager.h>
#import <RETableViewManager/RETableViewOptionsController.h>

@interface HSUEditListViewController ()

@property (nonatomic, strong) RETableViewManager *manager;
@property (nonatomic, strong) NSDictionary *list;

@property (nonatomic, strong) RETextItem *nameItem;
@property (nonatomic, strong) RETextItem *descItem;
@property (nonatomic, strong) REBoolItem *privateItem;

@end

@implementation HSUEditListViewController

- (instancetype)initWithList:(NSDictionary *)list
{
    self = [super init];
    if (self) {
        self.list = list;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = self.list ? _("Edit List") : _("Create List");
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
                                             initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                             target:self
                                             action:@selector(dismiss)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                              initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                              target:self
                                              action:@selector(save)];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.tableView.frame style:UITableViewStyleGrouped];
    
    self.manager = [[RETableViewManager alloc] initWithTableView:self.tableView];
    
    RETableViewSection *section = [RETableViewSection section];
    [self.manager addSection:section];
    
    self.nameItem = [RETextItem itemWithTitle:_("Name") value:self.list[@"name"] placeholder:_("Type List Name")];
    self.descItem = [RELongTextItem itemWithValue:self.list[@"description"] placeholder:_("Describe the List")];
    self.descItem.cellHeight = 88;
    self.privateItem = [REBoolItem itemWithTitle:_("Private") value:[self.list[@"mode"] isEqualToString:@"private"]];
    [section addItem:self.nameItem];
    [section addItem:self.descItem];
    [section addItem:self.privateItem];
}

- (void)save
{
    NSString *name = self.nameItem.value;
    NSString *desc = self.descItem.value;
    BOOL private = self.privateItem.value;
    
    __weak typeof(self)weakSelf = self;
    if (self.list) {
        [SVProgressHUD showWithStatus:nil];
        [twitter createListWithName:name desc:desc mode:private?@"private":@"public" success:^(id responseObj) {
            [weakSelf.delegate editListViewControllerDidSaveList:responseObj];
            [weakSelf dismiss];
            [SVProgressHUD dismiss];
        } failure:^(NSError *error) {
            [SVProgressHUD showErrorWithStatus:_("Update failed")];
        }];
    } else {
        [SVProgressHUD showWithStatus:nil];
        [twitter createListWithName:name desc:desc mode:private?@"private":@"public" success:^(id responseObj) {
            [weakSelf.delegate editListViewControllerDidSaveList:responseObj];
            [weakSelf dismiss];
            [SVProgressHUD dismiss];
        } failure:^(NSError *error) {
            [SVProgressHUD showErrorWithStatus:_("Create failed")];
        }];
    }
}

@end
