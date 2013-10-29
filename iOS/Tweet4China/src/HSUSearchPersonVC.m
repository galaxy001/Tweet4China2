//
//  HSUAddFriendVC.m
//  Tweet4China
//
//  Created by Jason Hsu on 10/20/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUSearchPersonVC.h"
#import "HSUPersonListDataSource.h"
#import "HSUSearchPersonDataSource.h"

@interface HSUSearchPersonVC () <UITextFieldDelegate>

@property (nonatomic, weak) UITextField *searchTF;

@end

@implementation HSUSearchPersonVC

- (void)viewDidLoad
{
    UITextField *searchTF = [[UITextField alloc] init];
    self.searchTF = searchTF;
    searchTF.size = ccs(self.width-100, 40);
    searchTF.leftTop = ccp(80, 3);
    searchTF.placeholder = @"Search User";
    searchTF.leftViewMode = UITextFieldViewModeAlways;
    searchTF.returnKeyType = UIReturnKeySearch;
    searchTF.delegate = self;
    [searchTF addTarget:self action:@selector(searchKeywordChanged:) forControlEvents:UIControlEventEditingChanged];
    
    self.hideRightButtons = YES;
    
    self.dataSource = [[HSUSearchPersonDataSource alloc] init];
    
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController.navigationBar addSubview:self.searchTF];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self.searchTF becomeFirstResponder];
    
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.searchTF removeFromSuperview];
}

- (void)searchKeywordChanged:(UITextField *)searchTF
{
    ((HSUSearchPersonDataSource *)self.dataSource).keyword = searchTF.text;
    [self.dataSource loadMore];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return NO;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.navigationController.navigationBar endEditing:YES];
}

@end
