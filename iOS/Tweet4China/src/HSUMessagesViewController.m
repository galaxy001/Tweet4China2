//
//  HSUMessageViewController.m
//  Tweet4China
//
//  Created by Jason Hsu on 5/21/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUMessagesViewController.h"
#import "HSUMessagesDataSource.h"
#import "HSUSendBarButtonItem.h"
#import <UIAlertView-Blocks/UIActionSheet+Blocks.h>
#import "HSUProfileViewController.h"

@interface HSUMessagesViewController () <UITextViewDelegate>

@property (nonatomic, weak) UIImageView *toolbar;
@property (nonatomic, weak) UIImageView *textViewBackground;
@property (nonatomic, weak) UITextView *textView;
@property (nonatomic, weak) UILabel *wordCountLabel;
@property (nonatomic, assign) BOOL layoutForTextChanged;

@property (nonatomic, strong) UIBarButtonItem *actionsBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *sendBarButtonItem;

@end

@implementation HSUMessagesViewController

- (id)init
{
    self = [super init];
    if (self) {
        self.useRefreshControl = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = _("Direct Message");
    
    self.view.height = 568;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = kWhiteColor;
    
    // setup navgation bar buttons
    UIBarButtonItem *sendButtonItem = [[UIBarButtonItem alloc] init];
    self.sendBarButtonItem = sendButtonItem;
    sendButtonItem.title = _("Send");
    sendButtonItem.target = self;
    sendButtonItem.action = @selector(_sendButtonTouched);
    sendButtonItem.enabled = NO;
    
    UIImageView *toolbar = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"direct-message-bar"] stretchableImageFromCenter]];
    [self.view addSubview:toolbar];
    self.toolbar = toolbar;
    toolbar.backgroundColor = [UIColor greenColor];
    toolbar.hidden = YES;
    
    UIImageView *textViewBackground = [[UIImageView alloc] init];
    [self.view addSubview:textViewBackground];
    self.textViewBackground = textViewBackground;
    textViewBackground.image = [[UIImage imageNamed:@"direct-message-text-bubble"] stretchableImageFromCenter];
    textViewBackground.hidden = YES;
    
    UITextView *textView = [[UITextView alloc] init];
    [self.view addSubview:textView];
    self.textView = textView;
    textView.delegate = self;
    textView.backgroundColor = kClearColor;
    textView.font = [UIFont systemFontOfSize:15];
    textView.textColor = kBlackColor;
    
    UILabel *wordCountLabel = [[UILabel alloc] init];
    [self.view addSubview:wordCountLabel];
    self.wordCountLabel = wordCountLabel;
    wordCountLabel.textColor = kGrayColor;
    wordCountLabel.font = [UIFont boldSystemFontOfSize:14];
    wordCountLabel.shadowColor = kWhiteColor;
    wordCountLabel.shadowOffset = ccs(0, 1);
    wordCountLabel.backgroundColor = kClearColor;
    
    __weak typeof(self)weakSelf = self;
    [twitter lookupFriendshipsWithScreenNames:@[self.herProfile[@"screen_name"]] success:^(id responseObj) {
        weakSelf.relactionshipLoaded = YES;
        weakSelf.followedMe = NO;
        NSDictionary *ship = responseObj[0];
        NSArray *connections = ship[@"connections"];
        if ([connections isKindOfClass:[NSArray class]]) {
            for (NSString *connection in connections) {
                if ([connection isEqualToString:@"followed_by"]) {
                    weakSelf.followedMe = YES;
                    break;
                }
            }
        }
    } failure:^(NSError *error) {
    }];
    
    [self preprocessDataSourceForRender:self.dataSource];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.presentingViewController) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
                                                 initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                 target:self
                                                 action:@selector(dismiss)];
    }
    self.view.backgroundColor = kWhiteColor;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.toolbar.hidden = NO;
    self.textViewBackground.hidden = NO;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    if (self.tableView.height > self.view.height) {
        self.view.height = self.tableView.height;
    }
    if (self.textView.width == 0) {
        if (self.textView.hasText) {
            self.textView.size = ccs(self.view.width-45, 0);
        } else {
            self.textView.size = ccs(self.view.width-10, 0);
        }
    } else {
        if (self.textView.hasText) {
            self.textView.width = self.view.width-45;
        } else {
            self.textView.width = self.view.width-10;
        }
    }
    self.textView.left = 12;
    
    [self _resetToolbarLocation];
    [self _scrollToBottomWithAnimation:NO];
    self.layoutForTextChanged = NO;
    self.navigationItem.rightBarButtonItem = self.sendBarButtonItem;
}

- (void)textViewDidChange:(UITextView *)textView
{
    if (self.textView.hasText) {
        self.wordCountLabel.text = S(@"%u", 140-self.textView.text.length);
        self.sendBarButtonItem.enabled = YES;
    } else {
        self.wordCountLabel.text = nil;
        self.sendBarButtonItem.enabled = NO;
    }
    [self.wordCountLabel sizeToFit];
    self.layoutForTextChanged = YES;
    [self.view setNeedsLayout];
}

- (void)preprocessDataSourceForRender:(HSUBaseDataSource *)dataSource
{
    [super preprocessDataSourceForRender:dataSource];
    
    [dataSource addEventWithName:@"touchAvatar" target:self action:@selector(touchAvatar:) events:UIControlEventTouchUpInside];
    [dataSource addEventWithName:@"retry" target:self action:@selector(retry:) events:UIControlEventTouchUpInside];
}

- (void)_resetToolbarLocation
{
    CGSize textViewSize = self.textView.contentSize;
    if (textViewSize.height > 100) {
        textViewSize = ccs(textViewSize.width, 100);
    } else if (textViewSize.height < 1) {
        textViewSize = ccs(self.view.width-12-12, 36);
    }
    
    CGSize textViewBackgroundSize = ccs(textViewSize.width, textViewSize.height-8);
    CGSize toolbarSize = ccs(self.width, textViewBackgroundSize.height+9+7);
    UIEdgeInsets inset = self.tableView.contentInset;
    inset.bottom = toolbarSize.height;
    if (Sys_Ver >= 7) {
        if (self.keyboardHeight == 0) {
            inset.bottom += tabbar_height;
        }
    }
    
    self.tableView.height = self.view.height - self.keyboardHeight;
    self.tableView.contentInset = inset;
    self.toolbar.size = toolbarSize;
    self.textViewBackground.size = textViewBackgroundSize;
    self.textView.size = textViewSize;
    
    if (self.layoutForTextChanged) {
        [self doResetToolbarLocation];
    } else {
        if (self.toolbar.top == 0) {
            self.toolbar.bottom = self.tableView.bottom - (Sys_Ver >= 7 ? tabbar_height : 0);
            self.textViewBackground.leftTop = ccp(5, self.toolbar.top + 9);
            self.wordCountLabel.rightCenter = ccp(self.width-10, self.toolbar.rightCenter.y);
            self.textView.top = self.toolbar.top + 5;
            self.textView.width = self.width - self.textView.left * 2 - self.wordCountLabel.width;
        }
        __weak typeof(self)weakSelf = self;
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [UIView animateWithDuration:self.keyboardAnimationDuration animations:^{
            [weakSelf doResetToolbarLocation];
        }];
    }
}

- (void)doResetToolbarLocation
{
    self.toolbar.top = self.tableView.bottom - self.tableView.contentInset.bottom;
    if (IPAD) { // todo
        self.toolbar.top -=  15;
    } else if (Sys_Ver < 7 && self.keyboardHeight) {
        self.toolbar.top += tabbar_height;
    }
    self.textViewBackground.leftTop = ccp(5, self.toolbar.top + 9);
    self.wordCountLabel.rightCenter = ccp(self.width-10, self.toolbar.rightCenter.y);
    
    self.textView.top = self.toolbar.top + 5;
    self.textView.width = self.width - self.textView.left * 2 - self.wordCountLabel.width;
}

- (void)_scrollToBottomWithAnimation:(BOOL)animation
{
    [self.tableView setContentOffset:ccp(0, MAX(self.tableView.contentSize.height-self.tableView.height+self.tableView.contentInset.bottom, 0)) animated:animation];
}

- (void)backButtonTouched
{
    // todo
    if (self.textView.hasText) {
        notification_post_with_object(HSUConversationBackWithIncompletedSendingNotification, @[((HSUMessagesDataSource *)self.dataSource).conversation, self.textView.text]);
    }
    [super backButtonTouched];
}

- (void)_sendButtonTouched
{
    if (!self.textView.hasText) {
        return;
    }
    if (!self.relactionshipLoaded) {
        __weak typeof(self)weakSelf = self;
        [twitter lookupFriendshipsWithScreenNames:@[self.herProfile[@"screen_name"]] success:^(id responseObj) {
            weakSelf.relactionshipLoaded = YES;
            weakSelf.followedMe = NO;
            NSDictionary *ship = responseObj[0];
            NSArray *connections = ship[@"connections"];
            if ([connections isKindOfClass:[NSArray class]]) {
                for (NSString *connection in connections) {
                    if ([connection isEqualToString:@"followed_by"]) {
                        weakSelf.followedMe = YES;
                        break;
                    }
                }
            }
            [weakSelf _sendButtonTouched];
        } failure:^(NSError *error) {
            weakSelf.relactionshipLoaded = YES; // just try
            [weakSelf _sendButtonTouched];
        }];
    }
    
    if (!self.followedMe) {
        NSString *message = [NSString stringWithFormat:@"%@ @%@, @%@ %@", _("You can not send direct message to"), self.herProfile[@"screen_name"], self.herProfile[@"screen_name"], _("is not following you.")];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:message delegate:nil cancelButtonTitle:_("OK") otherButtonTitles:nil, nil];
        [alert show];
        return;
    }
    
    NSMutableDictionary *message = [NSMutableDictionary dictionary];
    message[@"sender"] = self.myProfile;
    message[@"recipient"] = self.herProfile;
    message[@"sender_id"] = self.myProfile[@"id"];
    message[@"sender_id_str"] = self.myProfile[@"id_str"];
    message[@"sender_screen_name"] = self.myProfile[@"screen_name"];
    message[@"recipient_id"] = self.herProfile[@"id"];
    message[@"recipient_id_str"] = self.herProfile[@"id_str"];
    message[@"recipient_screen_name"] = self.herProfile[@"screen_name"];
    message[@"text"] = self.textView.text;
    message[@"sending"] = @(YES);
    T4CTableCellData *appendingCellData = [[T4CTableCellData alloc] initWithRawData:message dataType:kDataType_Message];
    [self.dataSource.data addObject:appendingCellData];
    [self preprocessDataSourceForRender:self.dataSource];
    [self _retrySendMessage:message];
    self.textView.text = nil;
    [self textViewDidChange:self.textView];
    [self _scrollToBottomWithAnimation:NO];
}

- (void)retry:(T4CTableCellData *)cellData
{
    RIButtonItem *cancelItem = [RIButtonItem itemWithLabel:_("Cancel")];
    RIButtonItem *retryItem = [RIButtonItem itemWithLabel:_("Retry Send")];
    retryItem.action = ^{
        NSMutableDictionary *message = cellData.rawData.mutableCopy;
        cellData.rawData = message;
        [self _retrySendMessage:message];
    };
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:_("Message failed to send") cancelButtonItem:cancelItem destructiveButtonItem:nil otherButtonItems:retryItem, nil];
    [actionSheet showInView:self.view.window];
}

- (void)_retrySendMessage:(NSMutableDictionary *)message
{
    [message removeObjectForKey:@"failed"];
    [self.tableView reloadData];
    __weak typeof(self)weakSelf = self;
    [twitter sendDirectMessage:message[@"text"] toUser:message[@"recipient_screen_name"] success:^(id responseObj) {
        [message setValuesForKeysWithDictionary:responseObj];
        [message removeObjectForKey:@"sending"];
        [weakSelf.tableView reloadData];
    } failure:^(NSError *error) {
        [twitter dealWithError:error errTitle:_("Failed to send message")];
        message[@"failed"] = @(YES);
        [weakSelf.tableView reloadData];
    }];
}

- (void)updateConversation:(NSDictionary *)conversation
{
    HSUMessagesDataSource *messagesDataSource = [[HSUMessagesDataSource alloc] initWithConversation:conversation];
    self.dataSource = messagesDataSource;
    self.tableView.dataSource = messagesDataSource;
    [self.tableView reloadData];
    [self _scrollToBottomWithAnimation:YES];
    [self preprocessDataSourceForRender:self.dataSource];
}

- (void)touchAvatar:(T4CTableCellData *)cellData
{
    NSString *screenName = cellData.rawData[@"sender"][@"screen_name"];
    HSUProfileViewController *profileVC = [[HSUProfileViewController alloc] initWithScreenName:screenName];
    profileVC.profile = cellData.rawData[@"sender"];
    [self.navigationController pushViewController:profileVC animated:YES];
}

@end
