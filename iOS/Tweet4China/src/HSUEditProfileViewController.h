//
//  HSUEditProfileViewController.h
//  Tweet4China
//
//  Created by Jason Hsu on 14-1-2.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HSUProfileViewController.h"

@interface HSUEditProfileViewController : UITableViewController

@property (nonatomic, strong) UIImage *avatarImage;
@property (nonatomic, strong) UIImage *bannerImage;
@property (nonatomic, strong) NSDictionary *profile;
@property (nonatomic, weak) HSUProfileViewController *profileVC;

@end
