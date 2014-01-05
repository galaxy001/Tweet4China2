//
//  HSUCreateDirectMessageViewController.m
//  Tweet4China
//
//  Created by Jason Hsu on 14-1-5.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUCreateDirectMessageViewController.h"
#import "HSUDirectMessagePersonsDataSource.h"
#import "HSUMessagesDataSource.h"
#import "HSUMessagesViewController.h"

@interface HSUCreateDirectMessageViewController ()

@end

@implementation HSUCreateDirectMessageViewController

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.searchTF.returnKeyType = UIReturnKeyDone;
    
    [self.dataSource loadMore];
}

- (void)touchAvatar:(HSUTableCellData *)cellData
{
    [self sendMessageTo:cellData.rawData];
}

- (void)sendMessageTo:(NSDictionary *)user
{
    NSString *screenName = user[@"screen_name"];
    __weak typeof(self)weakSelf = self;
    [SVProgressHUD showWithStatus:nil];
    [TWENGINE lookupFriendshipsWithScreenNames:@[screenName] success:^(id responseObj) {
        NSDictionary *ship = responseObj[0];
        NSArray *connections = ship[@"connections"];
        BOOL followedMe = NO;
        if ([connections isKindOfClass:[NSArray class]]) {
            for (NSString *connection in connections) {
                if ([connection isEqualToString:@"followed_by"]) {
                    followedMe = YES;
                    break;
                }
            }
        }
        if (followedMe) {
            HSUMessagesDataSource *dataSource = [[HSUMessagesDataSource alloc] initWithConversation:nil];
            HSUMessagesViewController *messagesVC = [[HSUMessagesViewController alloc] initWithDataSource:dataSource];
            messagesVC.herProfile = user;
            NSDictionary *userProfiles = [[NSUserDefaults standardUserDefaults] valueForKey:HSUUserProfiles];
            if (userProfiles[MyScreenName]) {
                messagesVC.myProfile = userProfiles[MyScreenName];
                [SVProgressHUD dismiss];
                [weakSelf.navigationController pushViewController:messagesVC animated:YES];
            } else {
                [TWENGINE showUser:MyScreenName success:^(id responseObj) {
                    [SVProgressHUD dismiss];
                    messagesVC.myProfile = responseObj;
                    [weakSelf.navigationController pushViewController:messagesVC animated:YES];
                } failure:^(NSError *error) {
                    [SVProgressHUD dismiss];
                }];
            }
        } else {
            [SVProgressHUD dismiss];
            NSString *message = [NSString stringWithFormat:@"%@ @%@, @%@ ", _(@"You can not send direct message to"), screenName, screenName, _(@"is not following you.")];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:message delegate:nil cancelButtonTitle:_(@"OK") otherButtonTitles:nil, nil];
            [alert show];
        }
    } failure:^(NSError *error) {
        [SVProgressHUD dismiss];
    }];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (self.searchTF.text.length) {
        NSString *screenName = self.searchTF.text;
        [SVProgressHUD showWithStatus:[NSString stringWithFormat:@"%@ @%@", _(@"Finding"), screenName]];
        __weak typeof(self) weakSelf = self;
        [TWENGINE showUser:screenName success:^(id responseObj) {
            [weakSelf sendMessageTo:responseObj];
        } failure:^(NSError *error) {
            [SVProgressHUD dismiss];
        }];
    }
    
    [textField resignFirstResponder];
    return NO;
}

@end
