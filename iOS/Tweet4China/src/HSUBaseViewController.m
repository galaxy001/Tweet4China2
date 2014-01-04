//
//  HSUBaseViewController.m
//  Tweet4China
//
//  Created by Jason Hsu on 3/3/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "HSUBaseViewController.h"
#import "HSUTexturedView.h"
#import "HSUStatusCell.h"
#import "HSURefreshControl.h"
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
#import "HSUSearchPersonVC.h"
#import "HSUListCell.h"
#import "HSUSettingsViewController.h"
#import "HSUTableView.h"
#import "HSUiPadTabController.h"

@interface HSUBaseViewController ()

@property (nonatomic, assign) float defaultKeyboardHeight;

@end

@implementation HSUBaseViewController
{
    UIBarButtonItem *_actionBarButton;
    UIBarButtonItem *_addFriendBarButton;
    UIBarButtonItem *_composeBarButton;
    UIImageView *_addFriendButtonIndicator;
}

#pragma mark - Liftstyle
- (void)dealloc
{
    notification_remove_observer(self);
}

- (id)init
{
    self = [super init];
    if (self) {
        self.dataSourceClass = [HSUBaseDataSource class];
        self.useRefreshControl = YES;
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
    
    if (!self.dataSource) {
        self.dataSource = [self.dataSourceClass dataSourceWithDelegate:self useCache:YES];
    }
    self.dataSource.delegate = self;
    
    for (HSUTableCellData *cellData in self.dataSource.allData) {
        cellData.renderData[@"delegate"] = self;
    }
    
    HSUTableView *tableView;
    if (self.tableView) {
        tableView = self.tableView;
    } else {
        tableView = [[HSUTableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        [self.view addSubview:tableView];
        self.tableView = tableView;
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
    tableView.dataSource = self.dataSource;
    tableView.delegate = self;
    if (IPAD) {
        if (iOS_Ver >= 7) {
            tableView.backgroundColor = kClearColor;
        }
        tableView.layer.cornerRadius = 5;
    }
    tableView.backgroundView = nil;
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectZero];
    footerView.backgroundColor = [UIColor clearColor];
    [self.tableView setTableFooterView:footerView];
    
    if (self.useRefreshControl) {
        HSURefreshControl *refreshControl = [[HSURefreshControl alloc] init];
        [refreshControl addTarget:self.dataSource action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
        [tableView addSubview:refreshControl];
        self.refreshControl = refreshControl;
    }
    
    if (!self.hideRightButtons) {
        self.navigationItem.rightBarButtonItems = @[self.composeBarButton];
    }
    if (self.hideBackButton) {
        self.navigationItem.backBarButtonItem = nil;
    }
    self.navigationItem.leftBarButtonItems = @[self.actionBarButton];
    
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
#if SDK_Ver >= 70000
    if (iOS_Ver >= 7) {
        if (IPHONE) {
            self.navigationController.navigationBar.barTintColor = bwa(255, 0.9);
            self.tabBarController.tabBar.barTintColor = bwa(255, 0.9);
        }
    }
#endif
    
    if (self.navigationController.viewControllers.count > 1) {
        if (iOS_Ver < 7) {
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
    
    if (IPAD) {
        self.view.backgroundColor = rgb(244, 248, 251);
        self.tableView.frame = ccr(self.view.width/2-kIPADMainViewWidth/2, 15, kIPADMainViewWidth, self.view.height-30);
    } else {
        self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg_texture"]];
        self.tableView.frame = self.view.bounds;
    }
    
    NSIndexPath *selection = [self.tableView indexPathForSelectedRow];
	if (selection)
		[self.tableView deselectRowAtIndexPath:selection animated:YES];
    notification_post(kNotification_HSUStatusCell_OtherCellSwiped);
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.viewDidAppearCount ++;
}

- (BOOL)prefersStatusBarHidden
{
    return self.statusBarHidden;
}

- (void)keyboardFrameChanged:(NSNotification *)notification
{
    NSValue* keyboardFrame = [notification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey];
    self.keyboardHeight = keyboardFrame.CGRectValue.size.height;
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
    
//    [self.tableView setContentOffset:ccp(0, self.tableView.contentSize.height) animated:YES];
}

#pragma mark - TableView
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    HSUTableCellData *data = [self.dataSource dataAtIndexPath:indexPath];
    Class cellClass = [self cellClassForDataType:data.dataType];
    return [cellClass heightForData:data];
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    HSUTableCellData *data = [self.dataSource dataAtIndex:indexPath.row];
    if ([data.dataType isEqualToString:kDataType_DefaultStatus]) {
        if ([data.renderData[@"mode"] isEqualToString:@"action"]) {
            return NO;
        }
        return YES;
    }
    if ([data.dataType isEqualToString:kDataType_LoadMore]) {
        return NO;
    }
    return YES;
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
    [self.refreshControl endRefreshing];
    for (HSUTableCellData *cellData in self.dataSource.allData) {
        cellData.renderData[@"delegate"] = self;
    }
    
    NSMutableArray *indexPaths = [[NSMutableArray alloc] init];
    for (int i=fromIndex; i<fromIndex+length; i++) {
        [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
    }
    ((HSUTableView *)self.tableView).offsetLocked = (fromIndex == 0);
    [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
    
    [((HSUTabController *)self.tabBarController) hideUnreadIndicatorOnTabBarItem:self.navigationController.tabBarItem]; // for iPhone
    [((HSUiPadTabController *)self.tabController) hideUnreadIndicatorOnViewController:self.navigationController]; // for iPad
}

- (void)dataSource:(HSUBaseDataSource *)dataSource didFinishRefreshWithError:(NSError *)error
{
    [self.refreshControl endRefreshing];
    if (error) {
        NSLog(@"%@", error);
    } else {
        for (HSUTableCellData *cellData in self.dataSource.allData) {
            cellData.renderData[@"delegate"] = self;
        }
        
        ((HSUTableView *)self.tableView).offsetLocked = NO;
        [self.tableView reloadData];
    }

    [((HSUTabController *)self.tabBarController) hideUnreadIndicatorOnTabBarItem:self.navigationController.tabBarItem]; // for iPhone
    [((HSUiPadTabController *)self.tabController) hideUnreadIndicatorOnViewController:self.navigationController]; // for iPad
}

- (void)dataSource:(HSUBaseDataSource *)dataSource didFinishLoadMoreWithError:(NSError *)error
{
    if (error.code == 204) {
        ((HSUTableView *)self.tableView).offsetLocked = NO;
        [self.tableView reloadData];
    } else if (error == nil) {
        ((HSUTableView *)self.tableView).offsetLocked = NO;
        [self.tableView reloadData];
    }
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
        if (iOS_Ver >= 7) {
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
- (UIBarButtonItem *)addFriendBarButton
{
    if (!_addFriendBarButton) {
        if (iOS_Ver >= 7) {
            _addFriendBarButton = [[UIBarButtonItem alloc]
                                   initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                   target:self
                                   action:@selector(_addButtonTouched)];
        } else {
            UIButton *addFriendButton = [[UIButton alloc] init];
            [addFriendButton addTarget:self action:@selector(_addButtonTouched) forControlEvents:UIControlEventTouchUpInside];
            [addFriendButton setImage:[UIImage imageNamed:@"icn_nav_bar_people_1"] forState:UIControlStateNormal];
            [addFriendButton sizeToFit];
            addFriendButton.width *= 1.4;
            _addFriendBarButton = [[UIBarButtonItem alloc] initWithCustomView:addFriendButton];
        }
        
        if (![[[NSUserDefaults standardUserDefaults] objectForKey:HSUAddFriendBarTouched] boolValue]) {
            UIImage *indicatorImage = [UIImage imageNamed:@"unread_indicator"];
            UIImageView *indicator = [[UIImageView alloc] initWithImage:indicatorImage];
            [self.navigationController.navigationBar addSubview:indicator];
            _addFriendButtonIndicator = indicator;
            indicator.leftTop = ccp(self.navigationController.navigationBar.width-23, 0);
        }
    }
    return _addFriendBarButton;
}

- (UIBarButtonItem *)composeBarButton
{
    if (!_composeBarButton) {
        if (iOS_Ver >= 7) {
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

- (void)backButtonTouched
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Actions
- (void)_composeButtonTouched
{
    if (![TWENGINE isAuthorized] || [SVProgressHUD isVisible]) {
        return;
    }
    HSUComposeViewController *composeVC = [[HSUComposeViewController alloc] init];
    UINavigationController *nav = [[HSUNavigationController alloc] initWithNavigationBarClass:[HSUNavigationBarLight class] toolbarClass:nil];
    nav.viewControllers = @[composeVC];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)_searchButtonTouched
{
    
}

- (void)_addButtonTouched
{
    if (![TWENGINE isAuthorized] || [SVProgressHUD isVisible]) {
        return;
    }
    HSUSearchPersonVC *addFriendVC = [[HSUSearchPersonVC alloc] init];
    [self.navigationController pushViewController:addFriendVC animated:YES];
    
    if (![[[NSUserDefaults standardUserDefaults] objectForKey:HSUAddFriendBarTouched] boolValue]) {
        [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:HSUAddFriendBarTouched];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [_addFriendButtonIndicator removeFromSuperview];
    }
}

- (void)_actionButtonTouched
{
    HSUSettingsViewController *settingsVC = [[HSUSettingsViewController alloc] init];
    UINavigationController *nav = [[HSUNavigationController alloc] initWithNavigationBarClass:[HSUNavigationBarLight class] toolbarClass:nil];
    nav.viewControllers = @[settingsVC];
    [self presentViewController:nav animated:YES completion:nil];
    
    if (![[[NSUserDefaults standardUserDefaults] objectForKey:HSUActionBarTouched] boolValue]) {
        [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:HSUActionBarTouched];
        [[NSUserDefaults standardUserDefaults] synchronize];
        _actionBarButton = nil;
        self.navigationItem.leftBarButtonItems = @[self.actionBarButton];
    }
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
    return NO;
}

- (void)reloadData
{
    [self.tableView reloadData];
}

@end
