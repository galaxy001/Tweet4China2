//
//  HSUBaseViewController.m
//  Tweet4China
//
//  Created by Jason Hsu on 3/3/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUBaseViewController.h"
#import "HSUTexturedView.h"
#import "HSUStatusCell.h"
#import "HSULoadMoreCell.h"
#import "HSUTabController.h"
#import "HSUComposeViewController.h"
#import "HSUStatusViewController.h"
#import "HSUNavigationBarLight.h"
#import "HSUNormalTitleCell.h"
#import "HSUPersonListViewController.h"
#import "HSUFollowersDataSource.h"
#import "HSUFollowingDataSource.h"
#import "HSUPersonCell.h"
#import "HSUChatStatusCell.h"
#import "HSUDefaultStatusCell.h"
#import "HSUDraftCell.h"
#import "HSUDraftsCell.h"
#import "HSUConversationCell.h"
#import "HSUMessageCell.h"
#import "HSUListCell.h"
#import "HSUSettingsViewController.h"
#import "HSUiPadTabController.h"
#import "HSUSearchPersonDataSource.h"
#import "HSUPhotoCell.h"
#import "HSUSearchTweetsDataSource.h"
#import "HSUSearchViewController.h"
#import <SVPullToRefresh/SVPullToRefresh.h>

@interface HSUBaseViewController ()

@property (nonatomic, assign) float defaultKeyboardHeight;

@end

@implementation HSUBaseViewController
{
    UIBarButtonItem *_actionBarButton;
    UIBarButtonItem *_composeBarButton;
    UIBarButtonItem *_searchBarButton;
}

#pragma mark - Liftstyle
- (void)dealloc
{
    self.tableView.delegate = nil;
    notification_remove_observer(self);
}

- (id)init
{
    self = [super init];
    if (self) {
        self.dataSourceClass = [HSUBaseDataSource class];
        self.useRefreshControl = YES;
        notification_add_observer(HSUSettingsUpdatedNotification, self, @selector(settingsUpdated:));
    }
    return self;
}

- (id)initWithDataSource:(HSUBaseDataSource *)dataSource
{
    self = [self init];
    if (self) {
        self.dataSource = dataSource;
    }
    return self;
}

- (void)viewDidLoad
{
    notification_add_observer(UIKeyboardWillChangeFrameNotification, self, @selector(keyboardFrameChanged:));
    notification_add_observer(UIKeyboardWillHideNotification, self, @selector(keyboardWillHide:));
    notification_add_observer(UIKeyboardWillShowNotification, self, @selector(keyboardWillShow:));
    notification_add_observer(HSUActionBarTouchedNotification, self, @selector(_actionBarButtonTouchedFirstTime));
    notification_add_observer(HSUPostTweetProgressChangedNotification, self, @selector(updateProgress:));
    
    if (!self.dataSource) {
        self.dataSource = [self.dataSourceClass dataSourceWithDelegate:self useCache:YES];
    }
    self.dataSource.delegate = self;
    
    for (HSUTableCellData *cellData in self.dataSource.allData) {
        cellData.delegate = self;
    }
    
    UITableView *tableView;
    if (self.tableView) {
        tableView = self.tableView;
    } else {
        tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        [self.view addSubview:tableView];
        self.tableView = tableView;
    }
    if (IPAD) {
        self.tableView.separatorColor = rgb(225, 232, 237);
    }
    // todo: rework
    [tableView registerClass:[HSUDefaultStatusCell class] forCellReuseIdentifier:kDataType_DefaultStatus];
    [tableView registerClass:[HSUChatStatusCell class] forCellReuseIdentifier:kDataType_ChatStatus];
    [tableView registerClass:[HSUPersonCell class] forCellReuseIdentifier:kDataType_Person];
    [tableView registerClass:[HSULoadMoreCell class] forCellReuseIdentifier:kDataType_LoadMore];
    [tableView registerClass:[HSUNormalTitleCell class] forCellReuseIdentifier:kDataType_NormalTitle];
    [tableView registerClass:[HSUDraftCell class] forCellReuseIdentifier:kDataType_Draft];
    [tableView registerClass:[HSUDraftsCell class] forCellReuseIdentifier:kDataType_Drafts];
    [tableView registerClass:[HSUConversationCell class] forCellReuseIdentifier:kDataType_Conversation];
    [tableView registerClass:[HSUMessageCell class] forCellReuseIdentifier:kDataType_Message];
    [tableView registerClass:[HSUListCell class] forCellReuseIdentifier:kDataType_List];
    [tableView registerClass:[HSUPhotoCell class] forCellReuseIdentifier:kDataType_Photo];
    tableView.dataSource = self.dataSource;
    tableView.delegate = self;
    if (IPAD) {
        if (Sys_Ver >= 7) {
            tableView.backgroundColor = kClearColor;
        }
        tableView.layer.cornerRadius = 5;
    }
    tableView.backgroundView = nil;
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectZero];
    footerView.backgroundColor = [UIColor clearColor];
    [self.tableView setTableFooterView:footerView];
    //        HSURefreshControl *refreshControl = [[HSURefreshControl alloc] init];
    //        [refreshControl addTarget:self.dataSource action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    //        [tableView addSubview:refreshControl];
    //        self.refreshControl = refreshControl;
    
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.navigationController.viewControllers.count > 1) {
        if (Sys_Ver < 7) {
            UIButton *backButton = [[UIButton alloc] init];
            [backButton addTarget:self action:@selector(backButtonTouched) forControlEvents:UIControlEventTouchUpInside];
            if ([self.navigationController.navigationBar isKindOfClass:[HSUNavigationBar class]]) {
                [backButton setImage:[UIImage imageNamed:@"icn_nav_bar_back"] forState:UIControlStateNormal];
            } else if ([self.navigationController.navigationBar isKindOfClass:[HSUNavigationBarLight class]]) {
                [backButton setImage:[UIImage imageNamed:@"icn_nav_bar_light_back"] forState:UIControlStateNormal];
            } else {
                @throw [[NSException alloc] init];
            }
            [backButton sizeToFit];
            backButton.width *= 2;
            self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
        } else {
            self.navigationItem.leftBarButtonItem = nil;
        }
    }
    
    if (!IPAD) {
        self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg_texture"]];
        self.tableView.frame = self.view.bounds;
    }
    
    NSIndexPath *selection = [self.tableView indexPathForSelectedRow];
	if (selection)
		[self.tableView deselectRowAtIndexPath:selection animated:YES];
    notification_post(HSUStatusCellOtherCellSwipedNotification);
}

- (void)viewDidAppear:(BOOL)animated
{
    if (self.viewDidAppearCount == 0 && self.useRefreshControl) {
        __weak typeof(self)weakSelf = self;
        [self.tableView addPullToRefreshWithActionHandler:^{
            [weakSelf.dataSource refresh];
        }];
        self.tableView.pullToRefreshView.soundEffectEnabled = [[HSUAppDelegate shared].globalSettings[HSUSettingSoundEffect] boolValue];
        self.tableView.pullToRefreshView.arrow = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icn_arrow_notif_dark"]];
    }
    
    [super viewDidAppear:animated];
    
    self.viewDidAppearCount ++;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    if (IPAD) {
        self.view.backgroundColor = rgb(244, 248, 251);
        self.tableView.frame = ccr(0, 15, self.view.width, self.view.height-30);
        self.tableView.backgroundColor = self.view.backgroundColor;
        [self.tableView reloadData];
    }
}

- (BOOL)prefersStatusBarHidden
{
    return self.statusBarHidden;
}

- (void)keyboardFrameChanged:(NSNotification *)notification
{
    NSValue *keyboardFrame = [notification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey];
    self.keyboardHeight = keyboardFrame.CGRectValue.size.height;
    self.keyboardAnimationDuration = [[notification.userInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    self.defaultKeyboardHeight = self.keyboardHeight;
    [self.view setNeedsLayout];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    self.keyboardHeight = 0;
    [self.view setNeedsDisplay];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    self.keyboardHeight = self.defaultKeyboardHeight;
    [self.view setNeedsDisplay];
}

- (void)unreadCountChanged
{
    
}

#pragma mark - TableView
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    HSUTableCellData *data = [self.dataSource dataAtIndexPath:indexPath];
    Class cellClass = [self cellClassForDataType:data.dataType];
    return [cellClass heightForData:data];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    HSUTableCellData *cellData = [self.dataSource dataAtIndexPath:indexPath];
    if ([cellData.renderData[@"unread"] boolValue]) {
        cellData.renderData[@"unread"] = @NO;
        if (indexPath.row < self.dataSource.unreadCount) {
            self.dataSource.unreadCount = indexPath.row;
            [self unreadCountChanged];
        }
    }
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    HSUTableCellData *data = [self.dataSource dataAtIndex:indexPath.row];
    if ([data.dataType isEqualToString:kDataType_DefaultStatus]) {
        if ([data.renderData[@"mode"] isEqualToString:@"action"]) {
            return NO;
        }
    } else if ([data.dataType isEqualToString:kDataType_LoadMore]) {
        return NO;
    }
    return YES;
}

- (void)tableView:(UITableView *)tableView didHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (IPAD) {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        cell.contentView.backgroundColor = rgb(235, 238, 240);
    }
}

- (void)tableView:(UITableView *)tableView didUnhighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (IPAD) {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        cell.contentView.backgroundColor = kWhiteColor;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    HSUTableCellData *data = [self.dataSource dataAtIndexPath:indexPath];
    if ([data.dataType isEqualToString:kDataType_LoadMore]) {
        [self.dataSource loadMore];
    }
}

- (Class)cellClassForDataType:(NSString *)dataType
{
    return NSClassFromString([NSString stringWithFormat:@"HSU%@Cell", dataType]);
}

- (void)dataSource:(HSUBaseDataSource *)dataSource insertRowsFromIndex:(NSUInteger)fromIndex length:(NSUInteger)length
{
    for (HSUTableCellData *cellData in self.dataSource.allData) {
        cellData.delegate = self;
    }
    
    [self.tableView reloadData];
    if (fromIndex == 0) {
        CGRect visibleRect = ccr(0, self.tableView.contentOffset.y+self.tableView.contentInset.top,
                                 self.tableView.width, self.tableView.height);
        NSArray *indexPathsVisibleRows = [self.tableView indexPathsForRowsInRect:visibleRect];
        NSIndexPath *firstIndexPath = indexPathsVisibleRows[0];
        NSInteger firstRow = firstIndexPath.row + length;
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:firstRow inSection:0]
                              atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
        [self.tableView.pullToRefreshView stopAnimating];
    }
    
    [((HSUTabController *)self.tabBarController) hideUnreadIndicatorOnTabBarItem:self.navigationController.tabBarItem]; // for iPhone
    [((HSUiPadTabController *)self.tabController) hideUnreadIndicatorOnViewController:self.navigationController]; // for iPad
}

- (void)dataSource:(HSUBaseDataSource *)dataSource didFinishRefreshWithError:(NSError *)error
{
    if (error) {
        NSLog(@"%@", error);
    } else {
        for (HSUTableCellData *cellData in self.dataSource.allData) {
            cellData.delegate = self;
        }
        
        [self.tableView reloadData];
    }
    
    if (self.view.window) {
        [((HSUTabController *)self.tabBarController) hideUnreadIndicatorOnTabBarItem:self.navigationController.tabBarItem]; // for iPhone
        [((HSUiPadTabController *)self.tabController) hideUnreadIndicatorOnViewController:self.navigationController]; // for iPad
    }
    [self.tableView.pullToRefreshView stopAnimating];
}

- (void)dataSource:(HSUBaseDataSource *)dataSource didFinishLoadMoreWithError:(NSError *)error
{
    if ([[self.dataSource.data.lastObject dataType] isEqualToString:kDataType_LoadMore]) {
        if (error && error.code != 204) {
            [self.dataSource.data.lastObject setRawData:@{@"status": @(kLoadMoreCellStatus_Error)}];
        } else {
            [self.dataSource.data.lastObject setRawData:@{@"status": @(kLoadMoreCellStatus_Done)}];
        }
    }
    [self.tableView reloadData];
}

- (void)dataSourceDidFindUnread:(HSUBaseDataSource *)dataSource
{
    [((HSUTabController *)self.tabBarController) showUnreadIndicatorOnTabBarItem:self.navigationController.tabBarItem]; // for iPhone
    [((HSUiPadTabController *)self.tabController) showUnreadIndicatorOnViewController:self.navigationController]; // for iPad
}

- (void)preprocessDataSourceForRender:(HSUBaseDataSource *)dataSource
{
}

#pragma mark - base view controller's methods
- (UIBarButtonItem *)actionBarButton
{
    if (!_actionBarButton) {
        UIButton *actionButton = [[UIButton alloc] init];
        [actionButton addTarget:self action:@selector(_actionButtonTouched) forControlEvents:UIControlEventTouchUpInside];
        if (Sys_Ver >= 7) {
            [actionButton setImage:[UIImage imageNamed:@"icn_nav_action_ios7"] forState:UIControlStateNormal];
        } else {
            [actionButton setImage:[UIImage imageNamed:@"icn_nav_action"] forState:UIControlStateNormal];
        }
        [actionButton sizeToFit];
        
        if (![[[NSUserDefaults standardUserDefaults] objectForKey:HSUActionBarTouched] boolValue]) {
            UIImage *indicatorImage = [UIImage imageNamed:@"unread_indicator"];
            UIImageView *indicator = [[UIImageView alloc] initWithImage:indicatorImage];
            [actionButton addSubview:indicator];
            indicator.leftTop = ccp(actionButton.width-10, 0);
        }
        
        _actionBarButton = [[UIBarButtonItem alloc] initWithCustomView:actionButton];
    }
    return _actionBarButton;
}

- (UIBarButtonItem *)composeBarButton
{
    if (!_composeBarButton) {
        if (Sys_Ver >= 7) {
            _composeBarButton = [[UIBarButtonItem alloc]
                                 initWithBarButtonSystemItem:UIBarButtonSystemItemCompose
                                 target:self
                                 action:@selector(_composeButtonTouched)];
        } else {
            UIButton *composeButton = [[UIButton alloc] init];
            [composeButton addTarget:self action:@selector(_composeButtonTouched) forControlEvents:UIControlEventTouchUpInside];
            [composeButton setImage:[UIImage imageNamed:@"ic_title_tweet"] forState:UIControlStateNormal];
            [composeButton sizeToFit];
            composeButton.width *= 1.4;
            _composeBarButton = [[UIBarButtonItem alloc] initWithCustomView:composeButton];
        }
    }
    return _composeBarButton;
}

- (UIBarButtonItem *)searchBarButton
{
    if (!_searchBarButton) {
        if (Sys_Ver >= 7) {
            _searchBarButton = [[UIBarButtonItem alloc]
                                initWithBarButtonSystemItem:UIBarButtonSystemItemSearch
                                target:self
                                action:@selector(_searchButtonTouched)];
        } else {
            UIButton *searchButton = [[UIButton alloc] init];
            [searchButton addTarget:self action:@selector(_searchButtonTouched) forControlEvents:UIControlEventTouchUpInside];
            [searchButton setImage:[UIImage imageNamed:@"ic_title_search"] forState:UIControlStateNormal];
            [searchButton sizeToFit];
            searchButton.width *= 1.4;
            _searchBarButton = [[UIBarButtonItem alloc] initWithCustomView:searchButton];
        }
    }
    return _searchBarButton;
}

- (void)backButtonTouched
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Actions
- (void)_composeButtonTouched
{
    if (![twitter isAuthorized] || [SVProgressHUD isVisible]) {
        return;
    }
    HSUComposeViewController *composeVC = [[HSUComposeViewController alloc] init];
    UINavigationController *nav = [[HSUNavigationController alloc] initWithNavigationBarClass:[HSUNavigationBarLight class] toolbarClass:nil];
    nav.viewControllers = @[composeVC];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)_searchButtonTouched
{
    HSUSearchViewController *searchVC = [[HSUSearchViewController alloc] init];
    [self.navigationController pushViewController:searchVC animated:YES];
}

- (void)_actionButtonTouched
{
    HSUSettingsViewController *settingsVC = [[HSUSettingsViewController alloc] init];
    UINavigationController *nav = [[HSUNavigationController alloc] initWithNavigationBarClass:[HSUNavigationBarLight class] toolbarClass:nil];
    nav.modalPresentationStyle = UIModalPresentationFormSheet;
    nav.viewControllers = @[settingsVC];
    [self presentViewController:nav animated:YES completion:nil];
    
    if (![[[NSUserDefaults standardUserDefaults] objectForKey:HSUActionBarTouched] boolValue]) {
        notification_post(HSUActionBarTouchedNotification);
    }
}

- (void)_actionBarButtonTouchedFirstTime
{
    [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:HSUActionBarTouched];
    [[NSUserDefaults standardUserDefaults] synchronize];
    _actionBarButton = nil;
    self.navigationItem.leftBarButtonItems = @[self.actionBarButton];
}

- (void)presentModelClass:(Class)modelClass
{
    UINavigationController *nav = DEF_NavitationController_Light;
    UIViewController *vc = [[modelClass alloc] init];
    nav.viewControllers = @[vc];
    [self presentViewController:nav animated:YES completion:nil];
}

- (BOOL)shouldAutorotate
{
    return IPAD || UIInterfaceOrientationIsLandscape(self.interfaceOrientation);
}

- (void)reloadData
{
    [self.tableView reloadData];
}

- (void)updateProgress:(NSNotification *)notification
{
    double progress = [notification.object doubleValue];
    [((HSUNavigationController *)self.navigationController) updateProgress:progress];
}

- (void)dataSourceWillStartRefresh:(HSUBaseDataSource *)dataSource
{
    
}

- (void)settingsUpdated:(NSNotification *)notification
{
    self.tableView.pullToRefreshView.soundEffectEnabled = [[HSUAppDelegate shared].globalSettings[HSUSettingSoundEffect] boolValue];
}

@end
