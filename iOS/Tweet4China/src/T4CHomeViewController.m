//
//  T4CHomeViewController.m
//  Tweet4China
//
//  Created by Jason Hsu on 14-1-25.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "T4CHomeViewController.h"

@interface T4CHomeViewController ()

@end

@implementation T4CHomeViewController

- (NSString *)apiString
{
    return @"statuses/home_timeline";
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem = self.actionBarButton;
    self.navigationItem.rightBarButtonItems = @[self.composeBarButton, self.searchBarButton];
}

@end
