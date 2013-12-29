//
//  HSUTabController.m
//  Tweet4China
//
//  Created by Jason Hsu on 2/28/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUTabController.h"
#import "HSUHomeViewController.h"
#import "HSUConnectViewController.h"
#import "HSUDiscoverViewController.h"
#import "HSUProfileViewController.h"
#import "HSUNavigationBar.h"
#import "HSUGalleryView.h"

@interface HSUTabController () <UITabBarControllerDelegate>

@property (nonatomic, retain) NSArray *tabBarItemsData;
@property (nonatomic, retain) NSMutableArray *tabBarItems;
@property (nonatomic, weak) UIButton *selectedTabBarItem;
@property (nonatomic, weak) UITabBarItem *lastSelectedTabBarItem;

@end

@implementation HSUTabController

- (id)init
{
    self = [super init];
    if (self) {
        UINavigationController *homeNav = [[HSUNavigationController alloc] initWithNavigationBarClass:[HSUNavigationBar class] toolbarClass:nil];
        HSUHomeViewController *homeVC = [[HSUHomeViewController alloc] init];
        homeNav.viewControllers = @[homeVC];
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
        if (RUNNING_ON_IOS_7) {
            homeNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:_(@"Home") image:[UIImage imageNamed:@"icn_tab_home_selected"] selectedImage:[UIImage imageNamed:@"ic_tab_home_default"]];
        } else {
            homeNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:_(@"Home") image:[UIImage imageNamed:@"icn_tab_home_selected"] tag:1];
        }
#else
        homeNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:_(@"Home") image:[UIImage imageNamed:@"icn_tab_home_selected"] tag:1];
#endif
        [homeNav.tabBarItem setTitlePositionAdjustment:UIOffsetMake(0, -1)];

        UINavigationController *connectNav = [[HSUNavigationController alloc] initWithNavigationBarClass:[HSUNavigationBar class] toolbarClass:nil];
        HSUConnectViewController *connectVC = [[HSUConnectViewController alloc] init];
        connectNav.viewControllers = @[connectVC];
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
        if (RUNNING_ON_IOS_7) {
            connectNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:_(@"Connect") image:[UIImage imageNamed:@"icn_tab_connect_selected"] selectedImage:[UIImage imageNamed:@"ic_tab_at_default"]];
        } else {
            connectNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:_(@"Connect") image:[UIImage imageNamed:@"icn_tab_connect_selected"] tag:2];
        }
#else
        connectNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:_(@"Connect") image:[UIImage imageNamed:@"icn_tab_connect_selected"] tag:2];
#endif
        [connectNav.tabBarItem setTitlePositionAdjustment:UIOffsetMake(0, -1)];
        
        UINavigationController *discoverNav = [[HSUNavigationController alloc] initWithNavigationBarClass:[HSUNavigationBar class] toolbarClass:nil];
        HSUDiscoverViewController *discoverVC = [[HSUDiscoverViewController alloc] init];
        discoverNav.viewControllers = @[discoverVC];
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
        if (RUNNING_ON_IOS_7) {
            discoverNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:_(@"Discover") image:[UIImage imageNamed:@"icn_tab_discover_selected"] selectedImage:[UIImage imageNamed:@"ic_tab_hash_default"]];
        } else {
            discoverNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:_(@"Discover") image:[UIImage imageNamed:@"icn_tab_discover_selected"] tag:3];
        }
#else
        discoverNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:_(@"Discover") image:[UIImage imageNamed:@"icn_tab_discover_selected"] tag:3];
#endif
        [discoverNav.tabBarItem setTitlePositionAdjustment:UIOffsetMake(0, -1)];
        
        UINavigationController *meNav = [[HSUNavigationController alloc] initWithNavigationBarClass:[HSUNavigationBar class] toolbarClass:nil];
        HSUProfileViewController *meVC = [[HSUProfileViewController alloc] init];
        meNav.viewControllers = @[meVC];
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
        if (RUNNING_ON_IOS_7) {
            meNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:_(@"Me") image:[UIImage imageNamed:@"icn_tab_me_selected"] selectedImage:[UIImage imageNamed:@"ic_tab_profile_default"]];
        } else {
            meNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:_(@"Me") image:[UIImage imageNamed:@"icn_tab_me_selected"] tag:4];
        }
#else
        meNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:_(@"Me") image:[UIImage imageNamed:@"icn_tab_me_selected"] tag:4];
#endif
        [meNav.tabBarItem setTitlePositionAdjustment:UIOffsetMake(0, -1)];
        
        self.viewControllers = @[homeNav, connectNav, discoverNav, meNav];
        
        self.delegate = self;
        self.lastSelectedTabBarItem = homeNav.tabBarItem;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tabBarItemsData = @[@{@"title": _(@"Home"), @"imageName": @"home"},
                             @{@"title": _(@"Connect"), @"imageName": @"connect"},
                             @{@"title": _(@"Discover"), @"imageName": @"discover"},
                             @{@"title": _(@"Me"), @"imageName": @"me"}];
    
    self.tabBar.frame = CGRectMake(0, kWinHeight-kTabBarHeight, kWinWidth, kTabBarHeight);
    ((UIView *)[self.view.subviews objectAtIndex:0]).frame = CGRectMake(0, 0, kWinWidth, kWinHeight-kTabBarHeight);
}

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController
{
    return [TWENGINE isAuthorized];
}

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    if (self.lastSelectedTabBarItem == item) {
        HSUBaseViewController *currentVC = ((UINavigationController *)self.selectedViewController).viewControllers[0];
        [currentVC.tableView setContentOffset:ccp(0, 0) animated:YES];
    }
    self.lastSelectedTabBarItem = item;
}

- (void)showUnreadIndicatorOnTabBarItem:(UITabBarItem *)tabBarItem
{
    uint idx = [self.tabBar.items indexOfObject:tabBarItem];
    if (idx == NSNotFound) {
        return;
    }
    
    UIImage *indicatorImage = [UIImage imageNamed:@"ic_glow"];
    UIImageView *indicator = [[UIImageView alloc] initWithImage:indicatorImage];
    uint curIdx = 0;
    for (UIView *subView in self.tabBar.subviews) {
        if ([subView isKindOfClass:NSClassFromString(@"UITabBarButton")]) {
            if (idx == curIdx) {
                indicator.bottomCenter = ccp(subView.width/2, subView.height);
                [subView addSubview:indicator];
                break;
            } else {
                curIdx ++;
            }
        }
    }
}

- (void)hideUnreadIndicatorOnTabBarItem:(UITabBarItem *)tabBarItem
{
    uint idx = [self.tabBar.items indexOfObject:tabBarItem];
    if (idx == NSNotFound) {
        return;
    }
    
    uint curIdx = 0;
    for (UIView *subView in self.tabBar.subviews) {
        if ([subView isKindOfClass:NSClassFromString(@"UITabBarButton")]) {
            if (idx == curIdx) {
                if ([subView.subviews.lastObject isKindOfClass:[UIImageView class]]) {
                    [subView.subviews.lastObject removeFromSuperview];
                }
                break;
            } else {
                curIdx ++;
            }
        }
    }
}

- (BOOL)hasUnreadIndicatorOnTabBarItem:(UITabBarItem *)tabBarItem
{
    uint idx = [self.tabBar.items indexOfObject:tabBarItem];
    if (idx == NSNotFound) {
        return NO;
    }
    
    uint curIdx = 0;
    for (UIView *subView in self.tabBar.subviews) {
        if ([subView isKindOfClass:NSClassFromString(@"UITabBarButton")]) {
            if (idx == curIdx) {
                if ([subView.subviews.lastObject isKindOfClass:[UIImageView class]]) {
                    return YES;
                }
            } else {
                curIdx ++;
            }
        }
    }
    return NO;
}

- (BOOL)shouldAutorotate
{
    return NO;
}

@end
