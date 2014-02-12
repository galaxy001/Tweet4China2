//
//  T4CMessagesViewController.m
//  Tweet4China
//
//  Created by Jason Hsu on 14-2-3.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "T4CMessagesViewController.h"
#import "HPGrowingTextView.h"
#import "T4CMessageCellData.h"

@interface T4CMessagesViewController () <UITextViewDelegate>

@property (nonatomic, weak) UILabel *wordCountLabel;
@property (nonatomic, assign) BOOL layoutForTextChanged;

@property (nonatomic, strong) UIBarButtonItem *actionsBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *sendBarButtonItem;

@end

@implementation T4CMessagesViewController

- (id)init
{
    self = [super init];
    if (self) {
        self.pullToRefresh = NO;
        self.infiniteScrolling = NO;
        notification_add_observer(HSUNewDirectMessagesReceivedNotification, self, @selector(receivedNewMessages:));
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = _("Direct Message");
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = kWhiteColor;
    UIGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapTableView)];
    [self.tableView addGestureRecognizer:tapGesture];
    
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
    
    NSArray *messages = self.conversation[@"messages"];
    for (NSDictionary *message in messages) {
        T4CMessageCellData *cellData =
        [[T4CMessageCellData alloc] initWithRawData:message
                                           dataType:kDataType_Message];
        cellData.target = self;
        [self.data addObject:cellData];
    }
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
    
    UIEdgeInsets inset = self.tableView.contentInset;
    inset.bottom = self.view.height - self.toolbar.top;
    self.tableView.contentInset = inset;
    [self _scrollToBottomWithAnimation:NO];
}

- (void)_scrollToBottomWithAnimation:(BOOL)animation
{
    [self.tableView setContentOffset:ccp(0, MAX(self.tableView.contentSize.height-self.tableView.height+self.tableView.contentInset.bottom, -self.tableView.contentInset.top)) animated:animation];
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if ([self.navigationController.viewControllers indexOfObject:viewController] <
        [self.navigationController.viewControllers indexOfObject:self]) {
        
        if (self.textView.hasText) {
            notification_post_with_object(HSUConversationBackWithIncompletedSendingNotification, @[self.conversation, self.textView.text]);
        }
        [self.navigationController popViewControllerAnimated:YES];
    }
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
    T4CMessageCellData *appendingCellData =
    [[T4CMessageCellData alloc] initWithRawData:message
                                       dataType:kDataType_Message];
    appendingCellData.target = self;
    [self.data addObject:appendingCellData];
    [self _retrySendMessage:message];
    self.textView.text = nil;
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
    self.conversation = conversation;
    
    NSArray *messages = self.conversation[@"messages"];
    for (NSDictionary *message in messages) {
        T4CMessageCellData *cellData =
        [[T4CMessageCellData alloc] initWithRawData:message
                                           dataType:kDataType_Message];
        cellData.target = self;
        [self.data addObject:cellData];
    }
    [self.tableView reloadData];
    
    [self _scrollToBottomWithAnimation:YES];
}

-(void)keyboardWillShow:(NSNotification *)note{
    
    [super keyboardWillShow:note];
    
    [self _scrollToBottomWithAnimation:NO];
}

- (NSString *)textViewPlaceHolder
{
    return _("Start a new message");
}

- (void)receivedNewMessages:(NSNotification *)notification
{
    NSArray *newMessages = notification.object;
    BOOL hasNew = NO;
    for (NSDictionary *newMessage in newMessages) {
        if ([newMessage[@"recipient"][@"screen_name"] isEqualToString:self.herProfile[@"screen_name"]] ||
            [newMessage[@"sender"][@"screen_name"] isEqualToString:self.herProfile[@"screen_name"]]) {
            
            T4CMessageCellData *cellData =
            [[T4CMessageCellData alloc] initWithRawData:newMessage
                                               dataType:kDataType_Message];
            cellData.target = self;
            [self.data addObject:cellData];
            hasNew = YES;
        }
    }
    if (hasNew) {
        [self.tableView reloadData];
        [self _scrollToBottomWithAnimation:YES];
    }
}

@end