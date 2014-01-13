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

@property (nonatomic, retain) NSMutableArray *tabBarItems;
@property (nonatomic, weak) UIButton *selectedTabBarItem;
@property (nonatomic, weak) UITabBarItem *lastSelectedTabBarItem;

@end

@implementation HSUTabController

- (void)dealloc
{
    notification_remove_observer(self);
}

- (id)init
{
    self = [super init];
    if (self) {
        UINavigationController *homeNav = [[HSUNavigationController alloc] initWithNavigationBarClass:[HSUNavigationBar class]
                                                                                         toolbarClass:nil];
        HSUHomeViewController *homeVC = [[HSUHomeViewController alloc] init];
        homeNav.viewControllers = @[homeVC];
#ifdef __IPHONE_7_0
        if (Sys_Ver >= 7) {
            homeNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:_("Home")
                                                               image:[UIImage imageNamed:@"icn_tab_home_selected"]
                                                       selectedImage:[UIImage imageNamed:@"ic_tab_home_default"]];
        } else {
#endif
            homeNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:_("Home")
                                                               image:[UIImage imageNamed:@"icn_tab_home_selected"]
                                                                 tag:1];
#ifdef __IPHONE_7_0
        }
#endif
        [homeNav.tabBarItem setTitlePositionAdjustment:UIOffsetMake(0, -1)];

        UINavigationController *connectNav = [[HSUNavigationController alloc] initWithNavigationBarClass:[HSUNavigationBar class]
                                                                                            toolbarClass:nil];
        HSUConnectViewController *connectVC = [[HSUConnectViewController alloc] init];
        connectNav.viewControllers = @[connectVC];
#ifdef __IPHONE_7_0
        if (Sys_Ver >= 7) {
            connectNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:_("Connect")
                                                                  image:[UIImage imageNamed:@"icn_tab_connect_selected"]
                                                          selectedImage:[UIImage imageNamed:@"ic_tab_at_default"]];
        } else {
#endif
            connectNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:_("Connect")
                                                                  image:[UIImage imageNamed:@"icn_tab_connect_selected"]
                                                                    tag:2];
#ifdef __IPHONE_7_0
        }
#endif
        [connectNav.tabBarItem setTitlePositionAdjustment:UIOffsetMake(0, -1)];
        
        UINavigationController *discoverNav = [[HSUNavigationController alloc] initWithNavigationBarClass:[HSUNavigationBar class]
                                                                                             toolbarClass:nil];
        HSUDiscoverViewController *discoverVC = [[HSUDiscoverViewController alloc] init];
        discoverNav.viewControllers = @[discoverVC];
#ifdef __IPHONE_7_0
        if (Sys_Ver >= 7) {
            discoverNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:_("Discover")
                                                                   image:[UIImage imageNamed:@"icn_tab_discover_selected"]
                                                           selectedImage:[UIImage imageNamed:@"ic_tab_hash_default"]];
        } else {
#endif
            discoverNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:_("Discover")
                                                                   image:[UIImage imageNamed:@"icn_tab_discover_selected"]
                                                                     tag:3];
#ifdef __IPHONE_7_0
        }
#endif
        [discoverNav.tabBarItem setTitlePositionAdjustment:UIOffsetMake(0, -1)];
        
        UINavigationController *meNav = [[HSUNavigationController alloc] initWithNavigationBarClass:[HSUNavigationBar class]
                                                                                       toolbarClass:nil];
        HSUProfileViewController *meVC = [[HSUProfileViewController alloc] init];
        meNav.viewControllers = @[meVC];
#ifdef __IPHONE_7_0
        if (Sys_Ver >= 7) {
            meNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:_("Me")
                                                             image:[UIImage imageNamed:@"icn_tab_me_selected"]
                                                     selectedImage:[UIImage imageNamed:@"ic_tab_profile_default"]];
        } else {
#endif
            meNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:_("Me")
                                                             image:[UIImage imageNamed:@"icn_tab_me_selected"]
                                                               tag:4];
#ifdef __IPHONE_7_0
        }
#endif
        [meNav.tabBarItem setTitlePositionAdjustment:UIOffsetMake(0, -1)];
        
        self.viewControllers = @[homeNav, connectNav, discoverNav, meNav];
        
        self.delegate = self;
        self.lastSelectedTabBarItem = homeNav.tabBarItem;
        
        notification_add_observer(HSUTwiterLoginSuccess, self, @selector(hideUnreadIndicators));
        notification_add_observer(HSUTwiterLogout, self, @selector(hideUnreadIndicators));
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tabBar.frame = CGRectMake(0, kWinHeight-kTabBarHeight, kWinWidth, kTabBarHeight);
    ((UIView *)[self.view.subviews objectAtIndex:0]).frame = CGRectMake(0, 0, kWinWidth, kWinHeight-kTabBarHeight);
    
#ifdef __IPHONE_7_0
    if (Sys_Ver >= 7 && IPHONE) {
        self.tabBarController.tabBar.barTintColor = bwa(255, 0.9);
    }
#endif
}

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController
{
    if ([twitter isAuthorized]) {
        notification_post_with_object(HSUTabControllerDidSelectViewControllerNotification, viewController);
        return YES;
    }
    return NO;
}

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    if (self.lastSelectedTabBarItem == item) {
        HSUBaseViewController *currentVC = ((UINavigationController *)self.selectedViewController).viewControllers[0];
        if ([currentVC respondsToSelector:@selector(tableView)]) {
            [currentVC.tableView setContentOffset:ccp(0, 0) animated:YES];
        }
    }
    self.lastSelectedTabBarItem = item;
}

- (void)showUnreadIndicatorOnTabBarItem:(UITabBarItem *)tabBarItem
{
    uint idx = [self.tabBar.items indexOfObject:tabBarItem];
    if (idx == NSNotFound) {
        return;
    }
    
    UIImage *indicatorImage = [UIImage imageNamed:@"unread_indicator"];
    UIImageView *indicator = [[UIImageView alloc] initWithImage:indicatorImage];
    indicator.tag = 111;
    uint curIdx = 0;
    for (UIView *subView in self.tabBar.subviews) {
        if ([subView isKindOfClass:NSClassFromString(@"UITabBarButton")]) {
            if (idx == curIdx) {
                if (![subView viewWithTag:indicator.tag]) {
                    indicator.rightTop = ccp(subView.width-15, 0);
                    [subView addSubview:indicator];
                }
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

- (void)hideUnreadIndicators
{
    for (UITabBarItem *item in self.tabBar.items) {
        [self hideUnreadIndicatorOnTabBarItem:item];
    }
}

- (BOOL)shouldAutorotate
{
    return self.selectedViewController.shouldAutorotate;
}

- (BOOL)prefersStatusBarHidden
{
    return self.selectedViewController.prefersStatusBarHidden;
}

@end
