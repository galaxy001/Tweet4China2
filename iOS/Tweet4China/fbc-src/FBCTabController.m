//
//  HSUTabController.m
//  Tweet4China
//
//  Created by Jason Hsu on 2/28/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "FBCTabController.h"
#import "FBCViewController.h"

@interface FBCTabController ()

@property (nonatomic, weak) UITabBarItem *lastSelectedTabBarItem;

@end

@implementation FBCTabController

- (void)dealloc
{
    self.delegate = nil;
}

- (id)init
{
    self = [super init];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didLogout) name:@"Logout" object:nil];
    
    if (self) {
        // Home
        FBCViewController *homeVC = [[FBCViewController alloc] init];
        UINavigationController *homeNav = [[UINavigationController alloc] initWithRootViewController:homeVC];
//        [homeVC view];
        homeVC.address = @"https://m.facebook.com/home.php";
        homeVC.title = @"Home";
        homeNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Home"
                                                          image:[UIImage imageNamed:@"icn_tab_home_default"]
                                                            tag:1];
        
        // Messages
        FBCViewController *messagesVC = [[FBCViewController alloc] init];
        UINavigationController *messagesNav = [[UINavigationController alloc] initWithRootViewController:messagesVC];
//        [messagesVC view];
        messagesVC.address = @"https://m.facebook.com/messages";
        messagesVC.title = @"Messages";
        messagesNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Messages"
                                                              image:[UIImage imageNamed:@"icn_tab_message_default"]
                                                                tag:2];
        
        // Events
        FBCViewController *eventsVC = [[FBCViewController alloc] init];
        UINavigationController *eventsNav = [[UINavigationController alloc] initWithRootViewController:eventsVC];
//        [eventsVC view];
        eventsVC.address = @"https://m.facebook.com/events";
        eventsVC.title = @"Events";
        eventsNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Events"
                                                            image:[UIImage imageNamed:@"icn_tab_discover_default"]
                                                              tag:3];
        
        // Friends
        FBCViewController *friendsVC = [[FBCViewController alloc] init];
        UINavigationController *friendsNav = [[UINavigationController alloc] initWithRootViewController:friendsVC];
//        [friendsVC view];
        friendsVC.address = @"https://m.facebook.com/findfriends";
        friendsVC.title = @"Friends";
        friendsNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Friends"
                                                              image:[UIImage imageNamed:@"icn_tab_friends_default"]
                                                                tag:4];
        
        // Profile
        FBCViewController *profileVC = [[FBCViewController alloc] init];
        UINavigationController *profileNav = [[UINavigationController alloc] initWithRootViewController:profileVC];
//        [profileVC view];
        profileVC.address = @"https://m.facebook.com/profile.php";
        profileVC.title = @"Me";
        profileNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Me"
                                                             image:[UIImage imageNamed:@"icn_tab_me_default"]
                                                               tag:5];
        
        self.viewControllers = @[homeNav, messagesNav, eventsNav, friendsNav, profileNav];
        
        self.delegate = homeVC;
    }
    return self;
}

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    if (item == self.lastSelectedTabBarItem) {
        FBCViewController *viewController = ((UINavigationController *)self.selectedViewController).viewControllers.lastObject;
        [viewController reloadStartPage];
    }
    
    self.lastSelectedTabBarItem = item;
}

- (void)didLogout
{
    [self setSelectedIndex:0];
}

@end
