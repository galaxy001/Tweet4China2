//
//  HSUMessagesViewController.m
//  Tweet4China
//
//  Created by Jason Hsu on 5/21/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUConversationsViewController.h"
#import "HSUConversationsDataSource.h"
#import "HSUMessagesViewController.h"
#import "HSUMessagesDataSource.h"
#import "HSUCreateDirectMessageViewController.h"
#import "HSUDirectMessagePersonsDataSource.h"
#import "HSUTabController.h"

@implementation HSUConversationsViewController

- (id)init
{
    self = [super init];
    if (self) {
        self.dataSourceClass = [HSUConversationsDataSource class];
        notification_add_observer(HSUDeleteConversationNotification, self, @selector(_conversationDeleted:));
        notification_add_observer(HSUCheckUnreadTimeNotification, self, @selector(checkUnread));
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem = self.actionBarButton;
    self.navigationItem.rightBarButtonItem = self.composeBarButton;
}

- (void)viewDidAppear:(BOOL)animated
{
    if (self.viewDidAppearCount == 0 || self.dataSource.count == 0) {
        [self.dataSource refresh];
    }
    
    [super viewDidAppear:animated];
    
    [self.tableView reloadData];
}

- (void)checkUnread
{
    if (self.dataSource) {
        [self.dataSource refresh];
    } else {
        [HSUConversationsDataSource checkUnreadForViewController:self];
    }
}

- (void)_closeButtonTouched
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)_composeButtonTouched
{
    HSUDirectMessagePersonsDataSource *dataSource = [[HSUDirectMessagePersonsDataSource alloc] init];
    HSUCreateDirectMessageViewController *createDMVC = [[HSUCreateDirectMessageViewController alloc] initWithDataSource:dataSource];
    [self.navigationController pushViewController:createDMVC animated:YES];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    HSUTableCellData *cellData = [self.dataSource dataAtIndexPath:indexPath];
    cellData.renderData[@"unread_dm"] = @NO;
    
    HSUMessagesDataSource *dataSource = [[HSUMessagesDataSource alloc] initWithConversation:cellData.rawData];
    HSUMessagesViewController *messagesVC = [[HSUMessagesViewController alloc] initWithDataSource:dataSource];
    
    NSDictionary *conversation = cellData.rawData;
    NSArray *messages = conversation[@"messages"];
    for (NSDictionary *message in messages) {
        if ([message[@"sender_screen_name"] isEqualToString:MyScreenName]) {
            messagesVC.myProfile = message[@"sender"];
            messagesVC.herProfile = message[@"recipient"];
        } else {
            messagesVC.myProfile = message[@"recipient"];
            messagesVC.herProfile = message[@"sender"];
        }
        break;
    }
    
    [self.navigationController pushViewController:messagesVC animated:YES];
}

- (void)_conversationDeleted:(NSNotification *)notification
{
    for (uint i=0; i<self.dataSource.count; i++) {
        HSUTableCellData *cd = [self.dataSource dataAtIndex:i];
        if (cd.rawData == notification.object) {
            [self.dataSource.data removeObject:cd];
            [self.tableView reloadData];
            break;
        }
    }
}

@end
