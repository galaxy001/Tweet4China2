//
//  T4CPersonCellData.m
//  Tweet4China
//
//  Created by Jason Hsu on 14-1-25.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "T4CPersonCellData.h"
#import "T4CTableViewController.h"

@implementation T4CPersonCellData

- (void)follow
{
    static int followCount = 0;
    followCount ++;
    if (followCount > 10 && followCount % 5 == 0) {
        [[[UIAlertView alloc] initWithTitle:_("Warning")
                                    message:_("Twitter may lock your account if you follow more users in a short time!")
                                   delegate:nil
                          cancelButtonTitle:_("I got it")
                          otherButtonTitles:nil, nil]
         show];
        return;
    }
    T4CTableViewController *viewController = self.target;
    NSString *screenName = self.rawData[@"screen_name"];
    self.sendingFollowingRequest = YES;
    [viewController.tableView reloadData];
    
    if ([self.rawData[@"following"] boolValue]) {
        __weak typeof(self)weakSelf = self;
        [twitter unFollowUser:screenName success:^(id responseObj) {
            weakSelf.sendingFollowingRequest = NO;
            NSMutableDictionary *rawData = weakSelf.rawData.mutableCopy;
            rawData[@"following"] = @(NO);
            weakSelf.rawData = rawData;
            [viewController.tableView reloadData];
            notification_post_with_object(HSUUserUnfollowedNotification, screenName);
        } failure:^(NSError *error) {
            [twitter dealWithError:error errTitle:_("Unfollow failed")];
        }];
    } else {
        __weak typeof(self)weakSelf = self;
        [twitter followUser:screenName success:^(id responseObj) {
            weakSelf.sendingFollowingRequest = NO;
            NSMutableDictionary *rawData = weakSelf.rawData.mutableCopy;
            rawData[@"following"] = @(YES);
            weakSelf.rawData = rawData;
            [viewController.tableView reloadData];
        } failure:^(NSError *error) {
            [twitter dealWithError:error errTitle:_("Follow failed")];
        }];
    }
}

@end
