//
//  HSULoginViewController.m
//  Tweet4China
//
//  Created by Jason Hsu on 13-12-31.
//  Copyright (c) 2013年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSULoginViewController.h"
#import <RETableViewManager/RETableViewManager.h>
#import "HSUMiniBrowser.h"

@interface HSULoginViewController ()

@property (nonatomic, strong) RETableViewManager *manager;
@property (nonatomic, weak) RETextItem *usernameItem;
@property (nonatomic, weak) RETextItem *passwordItem;

@end

@implementation HSULoginViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = _(@"Twitter Login");
    self.tableView = [[UITableView alloc] initWithFrame:self.tableView.frame style:UITableViewStyleGrouped];
    
    self.manager = [[RETableViewManager alloc] initWithTableView:self.tableView];
    
    RETableViewSection *section = [RETableViewSection section];
    [self.manager addSection:section];
    
    __weak typeof(self) weakSelf = self;
    RETextItem *usernameItem = [RETextItem itemWithTitle:_(@"Username")];
    self.usernameItem = usernameItem;
    [section addItem:usernameItem];
    usernameItem.placeholder = _(@"Username or Email");
    usernameItem.onChange = ^(RETextItem *item) {
        [weakSelf valueChanged];
    };
    
    RETextItem *passwordItem = [RETextItem itemWithTitle:_(@"Password")];
    self.passwordItem = passwordItem;
    [section addItem:passwordItem];
    passwordItem.placeholder = _(@"Password");
    passwordItem.secureTextEntry = YES;
    passwordItem.onChange = ^(RETextItem *item) {
        [weakSelf valueChanged];
    };
    
    section = [RETableViewSection section];
    [self.manager addSection:section];
    
    RETableViewItem *buttonItem =
    [RETableViewItem itemWithTitle:_(@"Register")
                     accessoryType:UITableViewCellAccessoryNone
                  selectionHandler:^(RETableViewItem *item)
    {
        [item deselectRowAnimated:YES];
        
        UINavigationController *nav = [[HSUNavigationController alloc] initWithNavigationBarClass:[HSUNavigationBarLight class] toolbarClass:nil];
        HSUMiniBrowser *miniBrowser = [[HSUMiniBrowser alloc] initWithURL:[NSURL URLWithString:@"https://mobile.twitter.com/signup"] cellData:nil];
        nav.viewControllers = @[miniBrowser];
        [self presentViewController:nav animated:YES completion:nil];
    }];
    buttonItem.textAlignment = NSTextAlignmentCenter;
    [section addItem:buttonItem];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:_(@"Login") style:UIBarButtonItemStylePlain target:self action:@selector(loginButtonTouched)];
    self.navigationItem.rightBarButtonItem.enabled = NO;
}

- (void)loginButtonTouched
{
    NSString *username = self.usernameItem.value;
    NSString *password = self.passwordItem.value;
    [TWENGINE loginWithScreenName:username andPassword:password success:^(id responseObj) {
        if (self.navigationController.viewControllers.count == 1) {
            [self dismiss];
        } else {
            [self.navigationController popViewControllerAnimated:YES];
        }
    } failure:^(NSError *error) {
        [SVProgressHUD showErrorWithStatus:error.description];
    }];
}

- (void)valueChanged
{
    self.navigationItem.rightBarButtonItem.enabled = self.usernameItem.value && self.passwordItem.value;
}

@end
