//
//  T4CMessageCellData.m
//  Tweet4China
//
//  Created by Jason Hsu on 14-2-4.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "T4CMessageCellData.h"
#import "HSUProfileViewController.h"

@implementation T4CMessageCellData

- (void)touchAvatar
{
    NSDictionary *status = self.rawData;
    HSUProfileViewController *profileVC = [[HSUProfileViewController alloc] initWithScreenName:status[@"sender"][@"screen_name"]];
    profileVC.profile = profileVC.profile = self.rawData[@"sender"];
    UIViewController *viewController = self.target;
    [viewController.navigationController pushViewController:profileVC animated:YES];
}

@end
