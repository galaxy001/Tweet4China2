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
#import "HSUSearchField.h"

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
    if (Sys_Ver >= 7) {
        [self.navigationController.navigationBar addSubview:typeControl];
    } else {
        [self.tableView addSubview:typeControl];
    }
    typeControl.selectedSegmentIndex = 0;
    [typeControl addTarget:self
                    action:@selector(typeControlValueChanged:)
          forControlEvents:UIControlEventValueChanged];
    if (Sys_Ver >= 7) {
        [typeControl setWidth:100 forSegmentAtIndex:0];
        [typeControl setWidth:100 forSegmentAtIndex:1];
    } else {
        [typeControl setWidth:150 forSegmentAtIndex:0];
        [typeControl setWidth:150 forSegmentAtIndex:1];
        typeControl.transform = CGAffineTransformMakeScale(.7, .7);
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (Sys_Ver >= 7) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
                                                 initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                 target:self
                                                 action:@selector(backButtonTouched)];
    }
    
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
        searchTF.text = @"@tuoxie007";
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
        }
        [self.navigationController.navigationBar addSubview:searchTF];
    }
    if (Sys_Ver >= 7) {
        ((HSUNavigationBar *)self.navigationController.navigationBar).highter = YES;
    }
    self.searchTF.hidden = NO;
    self.typeControl.hidden = NO;
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
    self.typeControl.hidden = YES;
}

- (void)backButtonTouched
{
    if (Sys_Ver >= 7) {
        ((HSUNavigationBar *)self.navigationController.navigationBar).highter = NO;
        [self.typeControl removeFromSuperview];
    }
    [self.searchTF removeFromSuperview];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    
    if (Sys_Ver >= 7) {
        ((HSUNavigationBar *)self.navigationController.navigationBar).highter = NO;
    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    CGFloat originTableViewContentInsetTop = 0;
    if (Sys_Ver >= 7) {
        originTableViewContentInsetTop = status_height + navbar_height;
    }
    if (Sys_Ver >= 7) {
        self.typeControl.topCenter = ccp(self.typeControl.superview.width/2, 3+44);
    } else {
        self.tableView.contentInset = edi(originTableViewContentInsetTop + 10 + self.typeControl.height + 10, 0, tabbar_height, 0);
        self.typeControl.topCenter = ccp(self.view.width/2, originTableViewContentInsetTop + 10 - self.tableView.contentInset.top);
    }
}

- (void)typeControlValueChanged:(UISegmentedControl *)segmentControl
{
    if (segmentControl.selectedSegmentIndex == 0) {
        self.data = self.tweetsData;
        self.tableView.infiniteScrollingView.enabled = YES;
    } else if (segmentControl.selectedSegmentIndex == 1) {
        self.data = self.personsData;
        [self.tableView.infiniteScrollingView stopAnimating];
        self.tableView.infiniteScrollingView.enabled = NO;
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
    [super scrollViewDidScroll:scrollView];
    [self.navigationController.navigationBar endEditing:YES];
}

- (void)refresh
{
    if (self.searchTF.hasText) {
        [self.data removeAllObjects];
        [self.tableView reloadData];
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

- (NSUInteger)requestCount
{
    return 100;
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
