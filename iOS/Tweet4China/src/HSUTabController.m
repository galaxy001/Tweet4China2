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
//#import "HSUDiscoverViewController.h"
#import "HSUWebBrowserViewController.h"
#import "HSUProfileViewController.h"
#import "HSUConversationsViewController.h"
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
        // Home
        UINavigationController *homeNav = [[HSUNavigationController alloc] initWithNavigationBarClass:[HSUNavigationBar class]
                                                                                         toolbarClass:nil];
        UIViewController *homeVC = [[HSUHomeViewController alloc] init];
        homeNav.viewControllers = @[homeVC];
        homeNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:_("Home")
                                                           image:[UIImage imageNamed:@"icn_tab_home_default"]
                                                             tag:1];
        [homeNav.tabBarItem setTitlePositionAdjustment:UIOffsetMake(0, -1)];
        
        // Connect
        UINavigationController *connectNav = [[HSUNavigationController alloc] initWithNavigationBarClass:[HSUNavigationBar class]
                                                                                            toolbarClass:nil];
        UIViewController *connectVC = [[HSUConnectViewController alloc] init];
        connectNav.viewControllers = @[connectVC];
        connectNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:_("Connect")
                                                              image:[UIImage imageNamed:@"icn_tab_connect_default"]
                                                                tag:2];
        [connectNav.tabBarItem setTitlePositionAdjustment:UIOffsetMake(0, -1)];
        
        // Message
        UINavigationController *messageNav = [[HSUNavigationController alloc] initWithNavigationBarClass:[HSUNavigationBar class]
                                                                                            toolbarClass:nil];
        UIViewController *messageVC = [[HSUConversationsViewController alloc] init];
        messageNav.viewControllers = @[messageVC];
        messageNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:_("Message")
                                                              image:[UIImage imageNamed:@"icn_tab_message_default"]
                                                                tag:2];
        [messageNav.tabBarItem setTitlePositionAdjustment:UIOffsetMake(0, -1)];
        
        // Discover
        UINavigationController *discoverNav = [[HSUNavigationController alloc] initWithNavigationBarClass:[HSUNavigationBar class]
                                                                                             toolbarClass:nil];
        UIViewController *discoverVC = [[HSUWebBrowserViewController alloc] init];
        discoverNav.viewControllers = @[discoverVC];
        discoverNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:_("Discover")
                                                               image:[UIImage imageNamed:@"icn_tab_discover_default"]
                                                                 tag:3];
        [discoverNav.tabBarItem setTitlePositionAdjustment:UIOffsetMake(0, -1)];
        
        // Me
        UINavigationController *meNav = [[HSUNavigationController alloc] initWithNavigationBarClass:[HSUNavigationBar class]
                                                                                       toolbarClass:nil];
        UIViewController *meVC = [[HSUProfileViewController alloc] init];
        meNav.viewControllers = @[meVC];
        meNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:_("Me")
                                                         image:[UIImage imageNamed:@"icn_tab_me_default"]
                                                           tag:4];
        [meNav.tabBarItem setTitlePositionAdjustment:UIOffsetMake(0, -1)];
        
        self.viewControllers = @[homeNav, connectNav, messageNav, discoverNav, meNav];
        
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
                    indicator.rightTop = ccp(subView.width-10, 0);
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
