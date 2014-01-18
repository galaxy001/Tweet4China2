//
//  HSUSearchTweetsViewController.m
//  Tweet4China
//
//  Created by Jason Hsu on 14-1-12.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUSearchTweetsViewController.h"
#import "HSUSearchField.h"
#import "HSUSearchTweetsDataSource.h"

@interface HSUSearchTweetsViewController () <UITextFieldDelegate>

@end

@implementation HSUSearchTweetsViewController

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
            UIImageView *searchIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ic_search"]];
            searchIcon.contentMode = UIViewContentModeCenter;
            searchIcon.size = ccs(searchIcon.width + 10, searchIcon.height + 15);
            searchTF.leftView = searchIcon;
            searchTF.leftViewMode = UITextFieldViewModeAlways;
        } else {
            searchTF = [[HSUSearchField alloc] init];
        }
        self.searchTF = searchTF;
        searchTF.placeholder = _("Search Tweets");
        searchTF.returnKeyType = UIReturnKeySearch;
        searchTF.autocorrectionType = UITextAutocorrectionTypeNo;
        searchTF.autocapitalizationType = UITextAutocapitalizationTypeNone;
        searchTF.clearButtonMode = UITextFieldViewModeWhileEditing;
        searchTF.delegate = self;
        if (Sys_Ver >= 7) {
            searchTF.size = ccs(self.width-100, 40);
            searchTF.leftTop = ccp(70, 3);
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

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    ((HSUSearchTweetsDataSource *)self.dataSource).keyword = self.searchTF.text;
    [self.dataSource refresh];
    [textField resignFirstResponder];
    return NO;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.navigationController.navigationBar endEditing:YES];
}

@end
