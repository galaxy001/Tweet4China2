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
        searchTF.placeholder = _("Search Tweets");
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
    
    self.searchTF.hidden = YES;
}

- (void)dataSource:(HSUBaseDataSource *)dataSource didFinishLoadMoreWithError:(NSError *)error
{
    [super dataSource:dataSource didFinishLoadMoreWithError:error];
    [((UIRefreshControl *)self.refreshControl) endRefreshing];
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
