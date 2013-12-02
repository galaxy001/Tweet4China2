//
//  HSUiPadTabController.m
//  Tweet4China
//
//  Created by Jason Hsu on 10/31/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUiPadTabController.h"
#import "HSUHomeViewController.h"
#import "HSUConnectViewController.h"
#import "HSUDiscoverViewController.h"
#import "HSUProfileViewController.h"
#import "HSUNavigationBar.h"

@interface HSUiPadTabController ()

@property (nonatomic, strong) NSArray *viewControllers;
@property (nonatomic, retain) NSArray *tabBarItemsData;
@property (nonatomic, retain) NSMutableArray *tabBarItems;
@property (nonatomic, weak) UIButton *selectedTabBarItem;
@property (nonatomic, weak) UITabBarItem *lastSelectedTabBarItem;
@property (nonatomic, weak) UIViewController *mainVC;

@end

@implementation HSUiPadTabController

- (id)init
{
    self = [super init];
    if (self) {
        UINavigationController *homeNav = [[HSUNavigationController alloc] initWithNavigationBarClass:[HSUNavigationBar class] toolbarClass:nil];
        HSUHomeViewController *homeVC = [[HSUHomeViewController alloc] init];
        homeNav.viewControllers = @[homeVC];
        if (RUNNING_ON_IOS_7) {
            homeNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Home" image:[UIImage imageNamed:@"icn_tab_home_selected"] selectedImage:[UIImage imageNamed:@"ic_tab_home_default"]];
        } else {
            homeNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Home" image:[UIImage imageNamed:@"icn_tab_home_selected"] tag:1];
        }
        [homeNav.tabBarItem setTitlePositionAdjustment:UIOffsetMake(0, -1)];
        
        UINavigationController *connectNav = [[HSUNavigationController alloc] initWithNavigationBarClass:[HSUNavigationBar class] toolbarClass:nil];
        HSUConnectViewController *connectVC = [[HSUConnectViewController alloc] init];
        connectNav.viewControllers = @[connectVC];
        if (RUNNING_ON_IOS_7) {
            connectNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Connect" image:[UIImage imageNamed:@"icn_tab_connect_selected"] selectedImage:[UIImage imageNamed:@"ic_tab_at_default"]];
        } else {
            connectNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Connect" image:[UIImage imageNamed:@"icn_tab_connect_selected"] tag:2];
        }
        [connectNav.tabBarItem setTitlePositionAdjustment:UIOffsetMake(0, -1)];
        
        UINavigationController *discoverNav = [[HSUNavigationController alloc] initWithNavigationBarClass:[HSUNavigationBar class] toolbarClass:nil];
        HSUDiscoverViewController *discoverVC = [[HSUDiscoverViewController alloc] init];
        discoverNav.viewControllers = @[discoverVC];
        if (RUNNING_ON_IOS_7) {
            discoverNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Discover" image:[UIImage imageNamed:@"icn_tab_discover_selected"] selectedImage:[UIImage imageNamed:@"ic_tab_hash_default"]];
        } else {
            discoverNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Discover" image:[UIImage imageNamed:@"icn_tab_discover_selected"] tag:3];
        }
        [discoverNav.tabBarItem setTitlePositionAdjustment:UIOffsetMake(0, -1)];
        
        UINavigationController *meNav = [[HSUNavigationController alloc] initWithNavigationBarClass:[HSUNavigationBar class] toolbarClass:nil];
        HSUProfileViewController *meVC = [[HSUProfileViewController alloc] init];
        meNav.viewControllers = @[meVC];
        if (RUNNING_ON_IOS_7) {
            meNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Me" image:[UIImage imageNamed:@"icn_tab_me_selected"] selectedImage:[UIImage imageNamed:@"ic_tab_profile_default"]];
        } else {
            meNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Me" image:[UIImage imageNamed:@"icn_tab_me_selected"] tag:4];
        }
        [meNav.tabBarItem setTitlePositionAdjustment:UIOffsetMake(0, -1)];
        
        self.viewControllers = @[homeNav, connectNav, discoverNav, meNav];
        
        self.lastSelectedTabBarItem = homeNav.tabBarItem;
    }
    return self;
}

- (void)viewDidLoad
{
    UIImageView *tabBar = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bg_tab_bar"]];
    tabBar.frame = CGRectMake(0, 0, kIPadTabBarWidth, kWinHeight);
    tabBar.userInteractionEnabled = YES;
    [self.view addSubview:tabBar];
    
    CGFloat paddingTop = 24;
    CGFloat buttonItemHeight = 87;
    
    self.tabBarItemsData = @[@{@"title": @"Home", @"imageName": @"home"},
                             @{@"title": @"Connect", @"imageName": @"connect"},
                             @{@"title": @"Discover", @"imageName": @"discover"},
                             @{@"title": @"Me", @"imageName": @"me"}];
    
    self.tabBarItems = [@[] mutableCopy];
    for (NSDictionary *tabBarItemData in self.tabBarItemsData) {
        NSString *title = tabBarItemData[@"title"];
        NSString *imageName = tabBarItemData[@"imageName"];
        
        UIButton *tabBarItem = [UIButton buttonWithType:UIButtonTypeCustom];
        tabBarItem.tag = [self.tabBarItemsData indexOfObject:tabBarItemData];
        [tabBarItem setImage:[UIImage imageNamed:[NSString stringWithFormat:@"icn_tab_%@_default", imageName]] forState:UIControlStateNormal];
        [tabBarItem setImage:[UIImage imageNamed:[NSString stringWithFormat:@"icn_tab_%@_selected", imageName]] forState:UIControlStateHighlighted];
        tabBarItem.frame = CGRectMake(0, buttonItemHeight*[self.tabBarItemsData indexOfObject:tabBarItemData], kIPadTabBarWidth, buttonItemHeight);
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
            [tabBarItem setImage:[UIImage imageNamed:[NSString stringWithFormat:@"icn_tab_%@_selected", imageName]] forState:UIControlStateNormal];
        }
        [self.tabBarItems addObject:tabBarItem];
        
        [tabBarItem addTarget:self action:@selector(iPadTabBarItemTouched:) forControlEvents:UIControlEventTouchDown];
    }
    
    for (UIViewController *childVC in self.viewControllers) {
        childVC.left = tabBar.right;
        childVC.width -= childVC.left;
        [self addChildViewController:childVC];
    }
    self.mainVC = self.viewControllers[0];
    [self.view addSubview:self.mainVC.view];
    
    [super viewDidLoad];
}

- (void)iPadTabBarItemTouched:(id)sender
{
    if (![TWENGINE isAuthorized]) {
        return;
    }
    for (UIButton *tabBarItem in self.tabBarItems) {
        NSString *imageName = self.tabBarItemsData[tabBarItem.tag][@"imageName"];
        if (tabBarItem == sender) {
            UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"icn_tab_%@_selected", imageName]];
            [tabBarItem setImage:image forState:UIControlStateNormal];
            [self.mainVC.view removeFromSuperview];
            self.mainVC = self.viewControllers[[self.tabBarItems indexOfObject:tabBarItem]];
            [self.view addSubview:self.mainVC.view];
        } else {
            UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"icn_tab_%@_default", imageName]];
            [tabBarItem setImage:image forState:UIControlStateNormal];
        }
    }
    self.selectedTabBarItem = sender;
}

- (BOOL)shouldAutorotate
{
    UIViewController *presentedVC = self.presentedViewController;
    if ([presentedVC isKindOfClass:[UINavigationController class]]) {
        UINavigationController *nav = (UINavigationController *)presentedVC;
        UIViewController *currentVC = nav.viewControllers.lastObject;
        return currentVC.shouldAutorotate;
    }
    return NO;
}

@end
