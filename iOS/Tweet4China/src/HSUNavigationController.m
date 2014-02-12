//
//  HSUNavigationController.m
//  Tweet4China
//
//  Created by Jason Hsu on 2013/12/2.
//  Copyright (c) 2013年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUNavigationController.h"

@interface HSUNavigationController ()

@property (nonatomic, weak) UIProgressView *progressBar;

@end

@implementation HSUNavigationController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
#ifdef __IPHONE_7_0
    if (Sys_Ver >= 7 && IPHONE) {
        self.tabBarController.tabBar.barTintColor = bwa(255, 0.9);
    }
#endif
    
    if (Sys_Ver >= 7) {
        UIProgressView *progressBar = [[UIProgressView alloc] init];
        [self.navigationBar addSubview:progressBar];
        progressBar.trackTintColor = kWhiteColor;
        progressBar.top = self.navigationBar.height - progressBar.height;
        progressBar.width = self.navigationBar.width;
        self.progressBar = progressBar;
    }
    
    self.view.backgroundColor = kWhiteColor;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    if (self.presentingViewController) {
        return;
    }
    for (UIViewController *childVC in self.viewControllers) {
        if (self.navigationBar.isHidden) {
            childVC.view.size = ccs(self.view.width, self.view.height);
        } else {
            childVC.view.size = ccs(self.view.width, self.view.height-self.navigationBar.height-20);
        }
    }
}

- (BOOL)shouldAutorotate
{
    return [self.viewControllers.lastObject shouldAutorotate];
}

- (void)updateProgress:(double)progress
{
    [self.progressBar setProgress:progress animated:NO];
}

- (BOOL)prefersStatusBarHidden
{
    return [self.viewControllers.lastObject prefersStatusBarHidden];
}

@end
