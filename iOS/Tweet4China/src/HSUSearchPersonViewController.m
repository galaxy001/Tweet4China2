//
//  HSUAddFriendVC.m
//  Tweet4China
//
//  Created by Jason Hsu on 10/20/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUSearchPersonViewController.h"
#import "HSUPersonListDataSource.h"
#import "HSUSearchPersonDataSource.h"
#import "HSUSearchField.h"

@interface HSUSearchPersonViewController () <UITextFieldDelegate>

@end

@implementation HSUSearchPersonViewController

- (void)dealloc
{
    self.searchTF.delegate = nil;
}

- (void)viewDidLoad
{
    self.useRefreshControl = NO;
    
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItem = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (!self.searchTF) {
        UITextField *searchTF;
        if (Sys_Ver >= 7) {
            searchTF = [[UITextField alloc] init];
        } else {
            searchTF = [[HSUSearchField alloc] init];
        }
        self.searchTF = searchTF;
        searchTF.placeholder = _("Search User");
        searchTF.leftViewMode = UITextFieldViewModeAlways;
        searchTF.returnKeyType = UIReturnKeySearch;
        searchTF.autocorrectionType = UITextAutocorrectionTypeNo;
        searchTF.autocapitalizationType = UITextAutocapitalizationTypeNone;
        searchTF.clearButtonMode = UITextFieldViewModeWhileEditing;
        searchTF.delegate = self;
        if (Sys_Ver >= 7) {
            searchTF.size = ccs(self.width-100, 40);
            searchTF.leftTop = ccp(80, 3);
        } else {
            searchTF.font = [UIFont systemFontOfSize:14];
            searchTF.size = ccs(self.width-75, 25);
            searchTF.leftTop = ccp(40, 10);
            searchTF.backgroundColor = bw(255);
            searchTF.layer.cornerRadius = 3;
            UIImageView *leftView = [[UIImageView alloc]
                                     initWithImage:[UIImage imageNamed:@"ic_search"]
                                     highlightedImage:[UIImage imageNamed:@"ic_search_white"]];
            leftView.width *= 1.8;
            leftView.contentMode = UIViewContentModeScaleAspectFit;
            searchTF.leftView = leftView;
        }
        [self.navigationController.navigationBar addSubview:searchTF];
    }
    self.searchTF.hidden = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    if (self.viewDidAppearCount == 0) {
        [self.searchTF becomeFirstResponder];
    }
    
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.searchTF resignFirstResponder];
    self.searchTF.hidden = YES;
}

- (void)dataSource:(HSUBaseDataSource *)dataSource didFinishLoadMoreWithError:(NSError *)error
{
    [super dataSource:dataSource didFinishLoadMoreWithError:error];
    [((UIRefreshControl *)self.refreshControl) endRefreshing];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.dataSource.data removeAllObjects];
    [self.tableView reloadData];
    
    ((HSUSearchPersonDataSource *)self.dataSource).keyword = self.searchTF.text;
    [self.dataSource loadMore];
    [textField resignFirstResponder];
    return NO;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.navigationController.navigationBar endEditing:YES];
}

@end
