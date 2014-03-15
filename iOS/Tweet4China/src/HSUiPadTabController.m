//
//  HSUiPadTabController.m
//  Tweet4China
//
//  Created by Jason Hsu on 10/31/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUiPadTabController.h"
#import "T4CHomeViewController.h"
#import "T4CConnectViewController.h"
#import "HSUProfileViewController.h"
#import "HSUNavigationBar.h"
#import "T4CConversationsViewController.h"
#import "T4CDiscoverViewController.h"

@interface HSUiPadTabController ()

@property (nonatomic, strong) NSArray *viewControllers;
@property (nonatomic, retain) NSArray *tabBarItemsData;
@property (nonatomic, retain) NSMutableArray *tabBarItems;
@property (nonatomic, weak) UIButton *selectedTabBarItem;
@property (nonatomic, weak) UITabBarItem *lastSelectedTabBarItem;
@property (nonatomic, weak) UIViewController *mainVC;
@property (nonatomic, weak) UIView *tabBar;
@property (nonatomic, weak) UILabel *uploadProgressLabel;

@end

@implementation HSUiPadTabController

- (id)init
{
    self = [super init];
    if (self) {
        UINavigationController *homeNav = [[HSUNavigationController alloc]
                                           initWithNavigationBarClass:[HSUNavigationBar class]
                                           toolbarClass:nil];
        T4CHomeViewController *homeVC = [[T4CHomeViewController alloc] init];
        homeVC.tabController = self;
        homeNav.viewControllers = @[homeVC];
        
        UINavigationController *connectNav = [[HSUNavigationController alloc]
                                              initWithNavigationBarClass:[HSUNavigationBar class]
                                              toolbarClass:nil];
        T4CConnectViewController *connectVC = [[T4CConnectViewController alloc] init];
        connectVC.tabController = self;
        connectNav.viewControllers = @[connectVC];
        
        UINavigationController *messageNav = [[HSUNavigationController alloc]
                                              initWithNavigationBarClass:[HSUNavigationBar class]
                                              toolbarClass:nil];
        T4CConversationsViewController *messageVC = [[T4CConversationsViewController alloc] init];
        messageVC.tabController = self;
        messageNav.viewControllers = @[messageVC];
        
        UINavigationController *discoverNav = [[HSUNavigationController alloc]
                                               initWithNavigationBarClass:[HSUNavigationBar class]
                                               toolbarClass:nil];
        T4CDiscoverViewController *discoverVC = [[T4CDiscoverViewController alloc] init];
//        discoverVC.tabController = self;
        discoverNav.viewControllers = @[discoverVC];
        
        UINavigationController *meNav = [[HSUNavigationController alloc]
                                         initWithNavigationBarClass:[HSUNavigationBar class]
                                         toolbarClass:nil];
        HSUProfileViewController *meVC = [[HSUProfileViewController alloc] init];
        meVC.tabController = self;
        meNav.viewControllers = @[meVC];
        
        self.viewControllers = @[homeNav, connectNav, messageNav, discoverNav, meNav];
        
        notification_add_observer(HSUPostTweetProgressChangedNotification, self, @selector(updateProgress:));
    }
    return self;
}

- (void)viewDidLoad
{
    self.view.backgroundColor = kBlackColor;
    UIView *tabBar = [[UIView alloc] initWithFrame:ccr(0, Sys_Ver >= 7 ? 20 : 0, kIPadTabBarWidth, self.view.height)];
    [self.view addSubview:tabBar];
    self.tabBar = tabBar;
    tabBar.backgroundColor = kBlackColor;
    
    CGFloat paddingTop = 24;
    CGFloat buttonItemHeight = 87;
    
    self.tabBarItemsData = @[@{@"title": _("Home"), @"imageName": @"home"},
                             @{@"title": _("Connect"), @"imageName": @"connect"},
                             @{@"title": _("Message"), @"imageName": @"message"},
                             @{@"title": _("Discover"), @"imageName": @"discover"},
                             @{@"title": _("Me"), @"imageName": @"me"}];
    
    self.tabBarItems = [@[] mutableCopy];
    for (NSDictionary *tabBarItemData in self.tabBarItemsData) {
        NSString *title = tabBarItemData[@"title"];
        NSString *imageName = tabBarItemData[@"imageName"];
        
        UIButton *tabBarItem = [UIButton buttonWithType:UIButtonTypeCustom];
        tabBarItem.tag = [self.tabBarItemsData indexOfObject:tabBarItemData];
        [tabBarItem setImage:[UIImage imageNamed:[NSString stringWithFormat:@"icn_tab_%@_default", imageName]]
                    forState:UIControlStateNormal];
        [tabBarItem setImage:[UIImage imageNamed:[NSString stringWithFormat:@"icn_tab_%@_selected", imageName]]
                    forState:UIControlStateHighlighted];
        tabBarItem.frame = CGRectMake(0,
                                      buttonItemHeight*[self.tabBarItemsData indexOfObject:tabBarItemData],
                                      kIPadTabBarWidth,
                                      buttonItemHeight);
        tabBarItem.imageEdgeInsets = UIEdgeInsetsMake(paddingTop, 0, 0, 0);
        
        UILabel *titleLabel = [[UILabel alloc] init];
        titleLabel.text = title;
        titleLabel.font = [UIFont systemFontOfSize:10];
        titleLabel.backgroundColor = kClearColor;
        titleLabel.textColor = kWhiteColor;
        [titleLabel sizeToFit];
        titleLabel.center = tabBarItem.center;
        titleLabel.frame = CGRectMake(titleLabel.frame.origin.x, buttonItemHeight-titleLabel.bounds.size.height+5, titleLabel.bounds.size.width, titleLabel.bounds.size.height);
        [tabBarItem addSubview:titleLabel];
        
        [tabBar addSubview:tabBarItem];
        
        if (tabBarItem.tag == 0) {
            [tabBarItem setImage:[UIImage imageNamed:[NSString stringWithFormat:@"icn_tab_%@_selected", imageName]]
                        forState:UIControlStateNormal];
        }
        [self.tabBarItems addObject:tabBarItem];
        
        [tabBarItem addTarget:self action:@selector(iPadTabBarItemTouched:) forControlEvents:UIControlEventTouchDown];
    }
    
    self.mainVC = self.viewControllers[0];
    [self.view addSubview:self.mainVC.view];
    
    [super viewDidLoad];
}

- (void)iPadTabBarItemTouched:(id)sender
{
    if (![twitter isAuthorized]) {
        return;
    }
    for (UIButton *tabBarItem in self.tabBarItems) {
        NSString *imageName = self.tabBarItemsData[tabBarItem.tag][@"imageName"];
        if (tabBarItem == sender) {
            UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"icn_tab_%@_selected", imageName]];
            [tabBarItem setImage:image forState:UIControlStateNormal];
            UIViewController *selectedVC = self.viewControllers[[self.tabBarItems indexOfObject:tabBarItem]];
            if (self.delegate && ![self.delegate tabBarController:self shouldSelectViewController:selectedVC]) {
                return;
            }
            if (self.mainVC != selectedVC) {
                [self.mainVC.view removeFromSuperview];
                self.mainVC = selectedVC;
                [self.view addSubview:self.mainVC.view];
            } else {
                NSArray *vcs = ((UINavigationController *)self.mainVC).viewControllers;
                if (vcs.count == 1) {
                    id currentVC = vcs.lastObject;
                    if ([currentVC isKindOfClass:[T4CTableViewController class]]) {
                        [((T4CTableViewController *)currentVC) tabItemTapped];
                    }
                }
            }
        } else {
            UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"icn_tab_%@_default", imageName]];
            [tabBarItem setImage:image forState:UIControlStateNormal];
        }
    }
    self.selectedTabBarItem = sender;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    for (UIViewController *childVC in self.viewControllers) {
        childVC.left = self.tabBar.right;
        if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) { // portrait
            childVC.width = 768 - childVC.left;
            childVC.height = 1024;
            if (Sys_Ver < 7) {
                childVC.height -= 20;
            }
        } else { // landscap
            childVC.width = 1024 - childVC.left;
            childVC.height = 768;
            if (Sys_Ver < 7) {
                childVC.height -= 20;
            }
        }
        [self addChildViewController:childVC];
    }
}

- (void)updateProgress:(NSNotification *)notification
{
    double progress = [notification.object doubleValue];
    if (!self.uploadProgressLabel) {
        UILabel *uploadProgressLabel = [[UILabel alloc] init];
        self.uploadProgressLabel = uploadProgressLabel;
        [self.view addSubview:uploadProgressLabel];
        uploadProgressLabel.textColor = kWhiteColor;
        uploadProgressLabel.frame = ccr(0, 20, self.tabBar.width, 40);
        uploadProgressLabel.font = [UIFont systemFontOfSize:12];
        uploadProgressLabel.textAlignment = NSTextAlignmentCenter;
    }
    self.uploadProgressLabel.text = S(@"%@ %d%%", _("Sent"), (int)(progress*100));
    if (progress <= 0 || progress >= 1) {
        if (progress >= 1) {
            self.uploadProgressLabel.text = _("Sent");
        } else {
            self.uploadProgressLabel.text = _("Sent failed");
        }
        __weak typeof(self)weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf.uploadProgressLabel removeFromSuperview];
        });
    }
}

- (BOOL)shouldAutorotate
{
    UIViewController *presentedVC = self.presentedViewController;
    if ([presentedVC isKindOfClass:[UINavigationController class]]) {
        UINavigationController *nav = (UINavigationController *)presentedVC;
        UIViewController *currentVC = nav.viewControllers.lastObject;
        return currentVC.shouldAutorotate;
    }
    
    return self.mainVC.shouldAutorotate;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleBlackOpaque;
}

- (void)showUnreadIndicatorOnViewController:(UIViewController *)viewController
{
    for (UIViewController *item in self.viewControllers) {
        if (item == viewController) {
            UIImage *indicatorImage = [UIImage imageNamed:@"unread_indicator"];
            UIImageView *indicator = [[UIImageView alloc] initWithImage:indicatorImage];
            UIButton *tabBarItemButton = [self.tabBarItems objectAtIndex:[self.viewControllers indexOfObject:item]];
            [tabBarItemButton addSubview:indicator];
            indicator.tag = 111;
            indicator.rightTop = ccp(tabBarItemButton.width-15, 30);
            break;
        }
    }
}
- (void)hideUnreadIndicatorOnViewController:(UIViewController *)viewController
{
    for (UIViewController *item in self.viewControllers) {
        if (item == viewController) {
            UIButton *tabBarItemButton = [self.tabBarItems objectAtIndex:[self.viewControllers indexOfObject:item]];
            [[tabBarItemButton viewWithTag:111] removeFromSuperview];
            break;
        }
    }
}
- (BOOL)hasUnreadIndicatorOnViewController:(UIViewController *)viewController
{
    for (UIViewController *item in self.viewControllers) {
        if (item == viewController) {
            UIButton *tabBarItemButton = [self.tabBarItems objectAtIndex:[self.viewControllers indexOfObject:item]];
            return [tabBarItemButton viewWithTag:111] != nil;
        }
    }
    return NO;
}

- (BOOL)prefersStatusBarHidden
{
    return self.mainVC.prefersStatusBarHidden;
}

@end
