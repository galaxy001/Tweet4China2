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

#define toolbar_height 44

@interface HSUConversationsViewController ()

//@property (nonatomic, weak) UIToolbar *toolbar;
//@property (nonatomic, assign) BOOL editing;
//@property (nonatomic, weak) UIButton *editButton;

@end

@implementation HSUConversationsViewController

- (id)init
{
    self = [super init];
    if (self) {
        self.dataSourceClass = [HSUConversationsDataSource class];
//        self.useRefreshControl = NO;
//        self.title = _("Messages");
    }
    return self;
}

- (void)viewDidLoad
{
    notification_add_observer(HSUDeleteConversationNotification, self, @selector(_conversationDeleted:));
    [super viewDidLoad];
    UIBarButtonItem *composeBarButton;
    if (Sys_Ver >= 7) {
        composeBarButton = [[UIBarButtonItem alloc]
                            initWithBarButtonSystemItem:UIBarButtonSystemItemCompose
                            target:self
                            action:@selector(_composeButtonTouched)];
    } else {
        UIButton *composeButton = [[UIButton alloc] init];
        [composeButton addTarget:self action:@selector(_composeButtonTouched) forControlEvents:UIControlEventTouchUpInside];
        [composeButton setImage:[UIImage imageNamed:@"icn_nav_bar_light_compose_dm"] forState:UIControlStateNormal];
        [composeButton sizeToFit];
        composeButton.width *= 1.4;
        composeBarButton = [[UIBarButtonItem alloc] initWithCustomView:composeButton];
    }
    self.navigationItem.rightBarButtonItem = composeBarButton;
}

- (void)viewDidAppear:(BOOL)animated
{
    if (self.viewDidAppearCount == 0) {
//        [self.dataSource refresh];
    } else {
        [self.tableView reloadData];
    }
    
    [super viewDidAppear:animated];
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
