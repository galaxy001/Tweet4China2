//
//  HSUTabController.m
//  Tweet4China
//
//  Created by Jason Hsu on 2/28/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUTabController.h"
#import "HSUWebBrowserViewController.h"
#import "HSUProfileViewController.h"
#import "HSUConversationsViewController.h"
#import "HSUNavigationBar.h"
#import "HSUGalleryView.h"
#import "T4CHomeViewController.h"
#import "T4CConnectViewController.h"
#import "T4CConversationsViewController.h"
#import "T4CDiscoverViewController.h"

@interface HSUTabController () <UITabBarControllerDelegate>

@property (nonatomic, weak) UITabBarItem *lastSelectedTabBarItem;
@property (nonatomic, strong) NSArray *unreadIndicators;
@property (nonatomic, weak) UIProgressView *progressBar;

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
        UINavigationController *homeNav =
        [[HSUNavigationController alloc] initWithNavigationBarClass:[HSUNavigationBar class]
                                                       toolbarClass:nil];
        UIViewController *homeVC = [[T4CHomeViewController alloc] init];
        homeNav.viewControllers = @[homeVC];
        homeNav.tabBarItem =
        [[UITabBarItem alloc] initWithTitle:_("Home")
                                      image:[UIImage imageNamed:@"icn_tab_home_default"]
                                        tag:1];
        [homeNav.tabBarItem setTitlePositionAdjustment:UIOffsetMake(0, -1)];
        
        // Connect
        UINavigationController *connectNav =
        [[HSUNavigationController alloc] initWithNavigationBarClass:[HSUNavigationBar class]
                                                       toolbarClass:nil];
        UIViewController *connectVC = [[T4CConnectViewController alloc] init];
        connectNav.viewControllers = @[connectVC];
        connectNav.tabBarItem =
        [[UITabBarItem alloc] initWithTitle:_("Connect")
                                      image:[UIImage imageNamed:@"icn_tab_connect_default"]
                                        tag:2];
        [connectNav.tabBarItem setTitlePositionAdjustment:UIOffsetMake(0, -1)];
        
        // Discover
        UINavigationController *discoverNav =
        [[HSUNavigationController alloc] initWithNavigationBarClass:[HSUNavigationBar class]
                                                       toolbarClass:nil];
        UIViewController *discoverVC = [[T4CDiscoverViewController alloc] init];
        discoverNav.viewControllers = @[discoverVC];
        discoverNav.tabBarItem =
        [[UITabBarItem alloc] initWithTitle:_("Discover")
                                      image:[UIImage imageNamed:@"icn_tab_discover_default"]
                                        tag:3];
        [discoverNav.tabBarItem setTitlePositionAdjustment:UIOffsetMake(0, -1)];
        
        // Message
        UINavigationController *messageNav =
        [[HSUNavigationController alloc] initWithNavigationBarClass:[HSUNavigationBar class]
                                                       toolbarClass:nil];
        UIViewController *messageVC = [[T4CConversationsViewController alloc] init];
        [messageNav view];
        messageNav.viewControllers = @[messageVC];
        messageNav.tabBarItem =
        [[UITabBarItem alloc] initWithTitle:_("Message")
                                      image:[UIImage imageNamed:@"icn_tab_message_default"]
                                        tag:2];
        [messageNav.tabBarItem setTitlePositionAdjustment:UIOffsetMake(0, -1)];
        
        // Me
        UINavigationController *meNav =
        [[HSUNavigationController alloc] initWithNavigationBarClass:[HSUNavigationBar class]
                                                       toolbarClass:nil];
        UIViewController *meVC = [[HSUProfileViewController alloc] init];
        meNav.viewControllers = @[meVC];
        meNav.tabBarItem =
        [[UITabBarItem alloc] initWithTitle:_("Me")
                                      image:[UIImage imageNamed:@"icn_tab_me_default"]
                                        tag:4];
        [meNav.tabBarItem setTitlePositionAdjustment:UIOffsetMake(0, -1)];
        
        self.viewControllers = @[homeNav, connectNav, discoverNav, messageNav, meNav];
        
        self.delegate = self;
        self.lastSelectedTabBarItem = homeNav.tabBarItem;
        
        notification_add_observer(HSUTwiterLoginSuccess, self, @selector(hideUnreadIndicators));
        notification_add_observer(HSUTwiterLogout, self, @selector(hideUnreadIndicators));
        notification_add_observer(HSUPostTweetProgressChangedNotification, self, @selector(updateProgress:));
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
        self.tabBar.barTintColor = bwa(255, 0.9);
    }
#endif
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    for (UINavigationController *nav in self.viewControllers) {
        [nav.viewControllers.firstObject view];
    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    self.tabBar.bottom = self.view.height;
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
        NSArray *vcs = ((UINavigationController *)self.selectedViewController).viewControllers;
        if (vcs.count == 1) {
            id currentVC = vcs.lastObject;
            if ([currentVC isKindOfClass:[T4CTableViewController class]]) {
                [((T4CTableViewController *)currentVC) tabItemTapped];
            }
        }
    }
    self.lastSelectedTabBarItem = item;
    [self hideUnreadIndicatorOnTabBarItem:item];
}

- (void)showUnreadIndicatorOnTabBarItem:(UITabBarItem *)tabBarItem
{
    uint idx = [self.tabBar.items indexOfObject:tabBarItem];
    if (idx == NSNotFound) {
        return;
    }
    
    if (!self.unreadIndicators) {
        NSMutableArray *unreadIndicators = [NSMutableArray arrayWithCapacity:self.tabBar.items.count];
        for (int i=0; i<self.tabBar.items.count; i++) {
            UIImage *indicatorImage = [UIImage imageNamed:@"unread_indicator"];
            UIImageView *indicator = [[UIImageView alloc] initWithImage:indicatorImage];
            indicator.hidden = YES;
            indicator.leftTop = ccp(35 + i * self.tabBar.width / self.tabBar.items.count, 0);
            [self.tabBar addSubview:indicator];
            [unreadIndicators addObject:indicator];
            self.unreadIndicators = unreadIndicators;
        }
    }
    
    [self.unreadIndicators[idx] setHidden:NO];
}

- (void)hideUnreadIndicatorOnTabBarItem:(UITabBarItem *)tabBarItem
{
    uint idx = [self.tabBar.items indexOfObject:tabBarItem];
    if (idx == NSNotFound) {
        return;
    }
    
    [self.unreadIndicators[idx] setHidden:YES];
}

- (BOOL)hasUnreadIndicatorOnTabBarItem:(UITabBarItem *)tabBarItem
{
    uint idx = [self.tabBar.items indexOfObject:tabBarItem];
    if (idx == NSNotFound) {
        return NO;
    }
    
    return [self.unreadIndicators[idx] isHidden];
}

- (void)hideUnreadIndicators
{
    for (UITabBarItem *item in self.tabBar.items) {
        [self hideUnreadIndicatorOnTabBarItem:item];
    }
}

- (void)updateProgress:(NSNotification *)notification
{
    double progress = [notification.object doubleValue];
    if (!self.progressBar) {
        UIProgressView *progressBar = [[UIProgressView alloc] init];
        [self.tabBar addSubview:progressBar];
        progressBar.trackTintColor = kWhiteColor;
        progressBar.width = self.tabBar.width;
        self.progressBar = progressBar;
    }
    __weak typeof(self)weakSelf = self;
    [self.progressBar setProgress:progress animated:NO];
    if (progress == 0) {
        [UIView animateWithDuration:0.5 animations:^{
            weakSelf.progressBar.alpha = 1.0;
        }];
    } else if (progress == 1) {
        double delayInSeconds = 1.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [UIView animateWithDuration:0.5 delay:progress - self.progressBar.progress options:0 animations:^{
                weakSelf.progressBar.alpha = 0.0;
            } completion:nil];
        });
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


-(UIImage *)getImageWithTintedColor:(UIImage *)image withTint:(UIColor *)color withIntensity:(float)alpha {
    CGSize size = image.size;
    
    UIGraphicsBeginImageContextWithOptions(size, FALSE, 2);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    [image drawAtPoint:CGPointZero blendMode:kCGBlendModeNormal alpha:1.0];
    
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextSetBlendMode(context, kCGBlendModeOverlay);
    CGContextSetAlpha(context, alpha);
    
    CGContextFillRect(UIGraphicsGetCurrentContext(), CGRectMake(CGPointZero.x, CGPointZero.y, image.size.width, image.size.height));
    
    UIImage * tintedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return tintedImage;
}

@end
