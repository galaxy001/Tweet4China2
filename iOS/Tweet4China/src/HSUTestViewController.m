//
//  HSUTestViewController.m
//  Tweet4China
//
//  Created by Jason Hsu on 13-9-1.
//  Copyright (c) 2013年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUTestViewController.h"

@interface HSUTestViewController ()
{
    UITextView *contentTV;
}

@end

@implementation HSUTestViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button setTitle:@"test" forState:UIControlStateNormal];
    [button sizeToFit];
    button = button;
    [self.view addSubview:button];
    button.frame = CGRectMake(0, 0, 50, 50);
    [button removeFromSuperview];
    
    contentTV = [[UITextView alloc] init];
    [self.view addSubview:contentTV];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    contentTV.frame = ccr(0, 0, self.view.width, 200);
}

@end
