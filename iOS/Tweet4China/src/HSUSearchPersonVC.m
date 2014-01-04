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
#if __IPHONE_OS_VERSION_MAX_ALLOWED < 70000
#import <QuartzCore/QuartzCore.h>
#endif

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
    self.useRefreshControl = NO;
    self.hideRightButtons = YES;
    
    self.dataSource = [[HSUSearchPersonDataSource alloc] init];
    
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItem = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    UITextField *searchTF;
    if (iOS_Ver >= 7) {
        searchTF = [[UITextField alloc] init];
    } else {
        searchTF = [[HSUSearchField alloc] init];
    }
    self.searchTF = searchTF;
    searchTF.placeholder = _(@"Search User");
    searchTF.leftViewMode = UITextFieldViewModeAlways;
    searchTF.returnKeyType = UIReturnKeySearch;
    searchTF.autocorrectionType = UITextAutocorrectionTypeNo;
    searchTF.autocapitalizationType = UITextAutocapitalizationTypeNone;
    searchTF.clearButtonMode = UITextFieldViewModeWhileEditing;
    searchTF.delegate = self;
    if (iOS_Ver >= 7) {
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
    __weak typeof(self) weakSelf = self;
    dispatch_async(GCDMainThread, ^{
        [weakSelf.dataSource.data removeAllObjects];
        [weakSelf.tableView reloadData];
        
        ((HSUSearchPersonDataSource *)weakSelf.dataSource).keyword = searchTF.text;
        [weakSelf.dataSource loadMore];
    });
}

- (void)dataSource:(HSUBaseDataSource *)dataSource didFinishLoadMoreWithError:(NSError *)error
{
    [super dataSource:dataSource didFinishLoadMoreWithError:error];
    [((UIRefreshControl *)self.refreshControl) endRefreshing];
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
