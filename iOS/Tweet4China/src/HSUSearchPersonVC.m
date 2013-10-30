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

@interface HSUSearchField : UITextField

@end

@implementation HSUSearchField

// placeholder position
- (CGRect)textRectForBounds:(CGRect)bounds
{
    return CGRectInset(bounds, 24, 4);
}

// text position
- (CGRect)editingRectForBounds:(CGRect)bounds
{
    return CGRectInset(bounds, 24, 4);
}

@end

@interface HSUSearchPersonVC () <UITextFieldDelegate>

@property (nonatomic, weak) UITextField *searchTF;

@end

@implementation HSUSearchPersonVC

- (void)viewDidLoad
{
    self.hideRightButtons = YES;
    
    self.dataSource = [[HSUSearchPersonDataSource alloc] init];
    
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    UITextField *searchTF;
    if (RUNNING_ON_IPHONE_7) {
        searchTF = [[UITextField alloc] init];
    } else {
        searchTF = [[HSUSearchField alloc] init];
    }
    self.searchTF = searchTF;
    searchTF.placeholder = @"Search User";
    searchTF.leftViewMode = UITextFieldViewModeAlways;
    searchTF.returnKeyType = UIReturnKeySearch;
    searchTF.delegate = self;
    if (RUNNING_ON_IPHONE_7) {
        searchTF.size = ccs(self.width-100, 40);
        searchTF.leftTop = ccp(80, 3);
    } else {
        searchTF.font = [UIFont systemFontOfSize:14];
        searchTF.size = ccs(self.width-55, 25);
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
    
    [searchTF addTarget:self action:@selector(searchKeywordChanged:) forControlEvents:UIControlEventEditingChanged];
    [self.navigationController.navigationBar addSubview:searchTF];
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
