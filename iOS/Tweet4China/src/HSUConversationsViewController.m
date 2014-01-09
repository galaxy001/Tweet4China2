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

@property (nonatomic, weak) UIToolbar *toolbar;
@property (nonatomic, assign) BOOL editing;
@property (nonatomic, weak) UIButton *editButton;

@end

@implementation HSUConversationsViewController

- (id)init
{
    self = [super init];
    if (self) {
        self.dataSourceClass = [HSUConversationsDataSource class];
        self.hideBackButton = YES;
        self.hideRightButtons = YES;
        self.useRefreshControl = NO;
        self.title = _(@"Messages");
    }
    return self;
}

- (void)viewDidLoad
{
    notification_add_observer(HSUDeleteConversationNotification, self, @selector(_conversationDeleted:));
    
    HSUTableView *tableView = [[HSUTableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    [self.view addSubview:tableView];
    self.tableView = tableView;
    
    [super viewDidLoad];
    
    if (!IPAD) {
        self.tableView.backgroundColor = kWhiteColor;
    }
    
    // setup navigation bar
    if (Sys_Ver < 7) {
        self.navigationController.navigationBar.tintColor = bw(212);
        NSDictionary *attributes = @{UITextAttributeTextColor: bw(50),
                                     UITextAttributeTextShadowColor: kWhiteColor,
                                     UITextAttributeTextShadowOffset: [NSValue valueWithCGSize:ccs(0, 1)]};
        self.navigationController.navigationBar.titleTextAttributes = attributes;
    }
    
    // setup close button
    UIButton *closeButton = [[UIButton alloc] init];
    if (Sys_Ver >= 7) {
        [closeButton setImage:[UIImage imageNamed:@"icn_nav_bar_close"] forState:UIControlStateNormal];
    } else {
        [closeButton setImage:[UIImage imageNamed:@"icn_nav_bar_light_close"] forState:UIControlStateNormal];
    }
    [closeButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [closeButton sizeToFit];
    [closeButton setTapTarget:self action:@selector(_closeButtonTouched)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:closeButton];
    
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
    
    // setup toolbar
    UIToolbar *toolbar = [[UIToolbar alloc] init];
    [self.view addSubview:toolbar];
    self.toolbar = toolbar;
    toolbar.size = ccs(self.width, toolbar_height);
    [toolbar setBackgroundImage:[UIImage imageNamed:@"bg_tab_bar"] forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
    
    UIButton *editButton = [[UIButton alloc] init];
    self.editButton = editButton;
    [editButton setTitle:_(@"Edit") forState:UIControlStateNormal];
    editButton.titleLabel.font = [UIFont boldSystemFontOfSize:12];
    [editButton sizeToFit];
    editButton.size = ccs(editButton.width + 20, editButton.height + 10);
    editButton.titleEdgeInsets = UIEdgeInsetsMake(-5, -10, -5, -10);
    [editButton setTitleColor:kWhiteColor forState:UIControlStateNormal];
    [editButton setBackgroundImage:[[UIImage imageNamed:@"btn_tool_bar_dark_segment_default"] stretchableImageFromCenter] forState:UIControlStateNormal];
    [editButton setBackgroundImage:[[UIImage imageNamed:@"btn_tool_bar_dark_segment_selected"] stretchableImageFromCenter] forState:UIControlStateHighlighted];
    [editButton setTapTarget:self action:@selector(_editButtonTouched)];
    UIBarButtonItem *editButtonItem = [[UIBarButtonItem alloc] initWithCustomView:editButton];
    UIBarButtonItem *placeButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    toolbar.items = @[editButtonItem, placeButtonItem];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (self.viewDidAppearCount == 1) {
        [self.dataSource refresh];
    } else {
        [self.tableView reloadData];
    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    self.toolbar.height = toolbar_height;
    self.toolbar.bottom = self.view.height;
    self.tableView.height = self.toolbar.top;
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

- (void)_editButtonTouched
{
    self.editing = !self.editing;
    [self.tableView setEditing:self.editing animated:YES];
    if (self.editing) {
        [self.editButton setTitle:_(@"Done") forState:UIControlStateNormal];
    } else {
        [self.editButton setTitle:_(@"Edit") forState:UIControlStateNormal];
    }
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
