//
//  HSUSearchTweetsViewController.m
//  Tweet4China
//
//  Created by Jason Hsu on 14-1-12.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUSearchViewController.h"
#import "HSUSearchField.h"
#import "HSUSearchTweetsDataSource.h"
#import "HSUSearchPersonDataSource.h"
#import "HSUProfileViewController.h"

@interface HSUSearchViewController () <UITextFieldDelegate>

@property (nonatomic, weak) UISegmentedControl *typeControl;
@property (nonatomic, strong) HSUSearchTweetsDataSource *searchTweetsDataSource;
@property (nonatomic, strong) HSUSearchPersonDataSource *searchPeronsDataSource;

@end

@implementation HSUSearchViewController

- (void)dealloc
{
    self.searchTF.delegate = nil;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.searchTweetsDataSource = [[HSUSearchTweetsDataSource alloc] init];
        self.searchPeronsDataSource = [[HSUSearchPersonDataSource alloc] init];
        self.dataSource = self.searchTweetsDataSource;
    }
    return self;
}

- (void)viewDidLoad
{
    self.useRefreshControl = NO;
    
    [super viewDidLoad];
    
    UISegmentedControl *typeControl = [[UISegmentedControl alloc] initWithItems:@[_("Tweets"),
                                                                                  _("User")]];
    self.typeControl = typeControl;
    [self.tableView addSubview:typeControl];
    typeControl.selectedSegmentIndex = 0;
    [typeControl addTarget:self action:@selector(typeControlValueChanged:) forControlEvents:UIControlEventValueChanged];
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

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    CGFloat originTableViewContentInsetTop = 0;
    if (Sys_Ver >= 7) {
        originTableViewContentInsetTop = status_height + navbar_height;
    }
    self.tableView.contentInset = edi(originTableViewContentInsetTop + 10 + self.typeControl.height + 10, 0, tabbar_height, 0);
    self.typeControl.topCenter = ccp(self.view.width/2, originTableViewContentInsetTop + 10 - self.tableView.contentInset.top);
}

- (void)typeControlValueChanged:(UISegmentedControl *)segmentControl
{
    if (segmentControl.selectedSegmentIndex == 0) {
        self.dataSource = self.searchTweetsDataSource;
    } else if (segmentControl.selectedSegmentIndex == 1) {
        self.dataSource = self.searchPeronsDataSource;
    }
    self.tableView.dataSource = self.dataSource;
    self.dataSource.delegate = self;
    [self.tableView reloadData];
    [self.searchTF becomeFirstResponder];
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    HSUTableCellData *data = [self.dataSource dataAtIndexPath:indexPath];
    if ([data.dataType isEqualToString:kDataType_Person]) {
        [self touchAvatar:data];
        return;
    }
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
}

- (void)touchAvatar:(HSUTableCellData *)cellData
{
    if ([cellData.dataType isEqualToString:kDataType_Person]) {
        NSString *screenName = cellData.rawData[@"screen_name"];
        HSUProfileViewController *profileVC = [[HSUProfileViewController alloc] initWithScreenName:screenName];
        profileVC.profile = cellData.rawData;
        [self.navigationController pushViewController:profileVC animated:YES];
    } else {
        NSString *screenName = cellData.rawData[@"retweeted_status"][@"user"][@"screen_name"] ?: cellData.rawData[@"user"][@"screen_name"];
        HSUProfileViewController *profileVC = [[HSUProfileViewController alloc] initWithScreenName:screenName];
        profileVC.profile = cellData.rawData[@"retweeted_status"][@"user"] ?: cellData.rawData[@"user"];
        [self.navigationController pushViewController:profileVC animated:YES];
    }
}

- (void)preprocessDataSourceForRender:(HSUBaseDataSource *)dataSource
{
    [super preprocessDataSourceForRender:dataSource];
    [dataSource addEventWithName:@"follow" target:self action:@selector(follow:) events:UIControlEventTouchUpInside];
}

- (void)follow:(HSUTableCellData *)cellData
{
    NSString *screenName = cellData.rawData[@"screen_name"];
    cellData.renderData[@"sending_following_request"] = @(YES);
    [self.tableView reloadData];
    
    if ([cellData.rawData[@"following"] boolValue]) {
        __weak typeof(self)weakSelf = self;
        [twitter unFollowUser:screenName success:^(id responseObj) {
            cellData.renderData[@"sending_following_request"] = @(NO);
            NSMutableDictionary *rawData = cellData.rawData.mutableCopy;
            rawData[@"following"] = @(NO);
            cellData.rawData = rawData;
            [weakSelf.tableView reloadData];
        } failure:^(NSError *error) {
            [twitter dealWithError:error errTitle:_("Unfollow failed")];
        }];
    } else {
        __weak typeof(self)weakSelf = self;
        [twitter followUser:screenName success:^(id responseObj) {
            cellData.renderData[@"sending_following_request"] = @(NO);
            NSMutableDictionary *rawData = cellData.rawData.mutableCopy;
            rawData[@"following"] = @(YES);
            cellData.rawData = rawData;
            [weakSelf.tableView reloadData];
        } failure:^(NSError *error) {
            [twitter dealWithError:error errTitle:_("Follow failed")];
        }];
    }
}

@end
