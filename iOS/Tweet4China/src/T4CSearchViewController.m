//
//  T4CSearchViewController.m
//  Tweet4China
//
//  Created by Jason Hsu on 14-2-4.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "T4CSearchViewController.h"
#import <FHSTwitterEngine/NSString+URLEncoding.h>
#import <SVPullToRefresh/SVPullToRefresh.h>

@interface T4CSearchViewController () <UITextFieldDelegate>

@property (nonatomic, weak) UISegmentedControl *typeControl;
@property (nonatomic, strong) NSMutableArray *tweetsData;
@property (nonatomic, strong) NSMutableArray *personsData;
@property (nonatomic, weak) UITextField *searchTF;
@property (nonatomic, assign) BOOL viewDidAppearCount;

@end

@implementation T4CSearchViewController

- (void)dealloc
{
    self.searchTF.delegate = nil;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.useCache = NO;
        self.pullToRefresh = NO;
        self.tweetsData = @[].mutableCopy;
        self.personsData = @[].mutableCopy;
        self.data = self.tweetsData;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UISegmentedControl *typeControl =
    [[UISegmentedControl alloc] initWithItems:@[_("Tweets"), _("User")]];
    self.typeControl = typeControl;
    [self.tableView addSubview:typeControl];
    typeControl.selectedSegmentIndex = 0;
    [typeControl addTarget:self
                    action:@selector(typeControlValueChanged:)
          forControlEvents:UIControlEventValueChanged];
    [typeControl setWidth:100 forSegmentAtIndex:0];
    [typeControl setWidth:100 forSegmentAtIndex:1];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (!self.searchTF) {
        UITextField *searchTF;
        searchTF = [[UITextField alloc] init];
        UIImageView *searchIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ic_search"]];
        searchIcon.contentMode = UIViewContentModeCenter;
        searchIcon.size = ccs(searchIcon.width + 10, searchIcon.height + 15);
        searchTF.leftView = searchIcon;
        searchTF.leftViewMode = UITextFieldViewModeAlways;
        self.searchTF = searchTF;
        searchTF.placeholder = _("Search Tweets");
        searchTF.returnKeyType = UIReturnKeySearch;
        searchTF.autocorrectionType = UITextAutocorrectionTypeNo;
        searchTF.autocapitalizationType = UITextAutocapitalizationTypeNone;
        searchTF.clearButtonMode = UITextFieldViewModeWhileEditing;
        searchTF.delegate = self;
        searchTF.size = ccs(self.width-100, 40);
        searchTF.leftTop = ccp(70, 3);
        [self.navigationController.navigationBar addSubview:searchTF];
    }
    self.searchTF.hidden = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if (self.viewDidAppearCount == 0) {
        [self.searchTF becomeFirstResponder];
    }
    self.viewDidAppearCount ++;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.searchTF resignFirstResponder];
    self.searchTF.hidden = YES;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    CGFloat originTableViewContentInsetTop = 0;
    originTableViewContentInsetTop = status_height + navbar_height;
    self.tableView.contentInset = edi(originTableViewContentInsetTop + 10 + self.typeControl.height + 10, 0, tabbar_height, 0);
    self.typeControl.topCenter = ccp(self.view.width/2, originTableViewContentInsetTop + 10 - self.tableView.contentInset.top);
}

- (void)typeControlValueChanged:(UISegmentedControl *)segmentControl
{
    if (segmentControl.selectedSegmentIndex == 0) {
        self.data = self.tweetsData;
    } else if (segmentControl.selectedSegmentIndex == 1) {
        self.data = self.personsData;
    }
    [self.tableView reloadData];
    [self.searchTF becomeFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self refresh];
    [textField resignFirstResponder];
    return NO;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.navigationController.navigationBar endEditing:YES];
}

- (void)refresh
{
    if (self.searchTF.hasText) {
        [super refresh];
    }
}

- (void)loadMore
{
    if (self.typeControl.selectedSegmentIndex == 0) {
        [super loadMore];
    } else {
        [self.tableView.infiniteScrollingView stopAnimating];
    }
}

- (NSString *)apiString
{
    if (self.typeControl.selectedSegmentIndex == 0) {
        return @"search/tweets";
    } else if (self.typeControl.selectedSegmentIndex == 1) {
        return @"users/search";
    }
    return nil;
}

- (NSString *)dataKey
{
    if (self.typeControl.selectedSegmentIndex == 0) {
        return @"statuses";
    }
    return nil;
}

- (NSDictionary *)requestParams
{
    return @{@"q": self.searchTF.text.URLEncodedString};
}

@end
