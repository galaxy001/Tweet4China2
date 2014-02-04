//
//  T4CStatusCellData.m
//  Tweet4China
//
//  Created by Jason Hsu on 14-1-25.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "T4CStatusCellData.h"
#import "HSUProfileViewController.h"

@implementation T4CStatusCellData

- (void)touchAvatar
{
    NSDictionary *status = self.rawData;
    HSUProfileViewController *profileVC = [[HSUProfileViewController alloc] initWithScreenName:status[@"user"][@"screen_name"]];
    profileVC.profile = profileVC.profile = self.rawData[@"user"];
    UIViewController *viewController = self.target;
    [viewController.navigationController pushViewController:profileVC animated:YES];
}

@end
