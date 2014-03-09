//
//  HSUNavigationController.m
//  Tweet4China
//
//  Created by Jason Hsu on 2013/12/2.
//  Copyright (c) 2013年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUNavigationController.h"

@interface HSUNavigationController ()

@end

@implementation HSUNavigationController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
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

- (BOOL)prefersStatusBarHidden
{
    return [self.viewControllers.lastObject prefersStatusBarHidden];
}

@end
