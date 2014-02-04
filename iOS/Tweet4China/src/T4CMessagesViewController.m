//
//  T4CMessagesViewController.m
//  Tweet4China
//
//  Created by Jason Hsu on 14-2-3.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "T4CMessagesViewController.h"
#import "HPGrowingTextView.h"

@interface T4CMessagesViewController () <UITextViewDelegate, HPGrowingTextViewDelegate>

@property (nonatomic, weak) UIView *toolbar;
@property (nonatomic, weak) UIImageView *toolbarBackground;
@property (nonatomic, weak) UIImageView *textViewBackground;
@property (nonatomic, weak) UILabel *wordCountLabel;
@property (nonatomic, assign) BOOL layoutForTextChanged;
@property (nonatomic, weak) UIView *containerView;
@property (nonatomic, weak) HPGrowingTextView *textView;

@property (nonatomic, strong) UIBarButtonItem *actionsBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *sendBarButtonItem;

@end

@implementation T4CMessagesViewController

- (void)dealloc
{
    self.textView.delegate = nil;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.pullToRefresh = NO;
        self.infiniteScrolling = NO;
        
        notification_add_observer(UIKeyboardWillHideNotification, self, @selector(keyboardWillHide:));
        notification_add_observer(UIKeyboardWillShowNotification, self, @selector(keyboardWillShow:));
    }
    return self;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = _("Direct Message");
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = kWhiteColor;
    
    UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.height - 40, self.view.width, 40)];
    self.containerView = containerView;
    
    HPGrowingTextView *textView = [[HPGrowingTextView alloc] initWithFrame:CGRectMake(6, 3, 240, 40)];
    self.textView = textView;
    
    textView.isScrollable = NO;
    textView.contentInset = UIEdgeInsetsMake(0, 5, 0, 5);
    
	textView.minNumberOfLines = 1;
	textView.maxNumberOfLines = 6;
    // you can also set the maximum height in points with maxHeight
    // textView.maxHeight = 200.0f;
	textView.returnKeyType = UIReturnKeyGo; //just as an example
	textView.font = [UIFont systemFontOfSize:15.0f];
	textView.delegate = self;
    textView.internalTextView.scrollIndicatorInsets = UIEdgeInsetsMake(5, 0, 5, 0);
    textView.backgroundColor = [UIColor whiteColor];
    
    [self.view addSubview:containerView];
    
    UIImage *rawEntryBackground = [UIImage imageNamed:@"MessageEntryInputField.png"];
    UIImage *entryBackground = [rawEntryBackground stretchableImageWithLeftCapWidth:13 topCapHeight:22];
    UIImageView *entryImageView = [[UIImageView alloc] initWithImage:entryBackground];
    entryImageView.frame = CGRectMake(5, 0, 248, 40);
    entryImageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    
    UIImage *rawBackground = [UIImage imageNamed:@"MessageEntryBackground.png"];
    UIImage *background = [rawBackground stretchableImageWithLeftCapWidth:13 topCapHeight:22];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:background];
    imageView.frame = CGRectMake(0, 0, containerView.frame.size.width, containerView.frame.size.height);
    imageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    
    textView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    [containerView addSubview:imageView];
    [containerView addSubview:textView];
    [containerView addSubview:entryImageView];
    
    UIImage *sendBtnBackground = [[UIImage imageNamed:@"MessageEntrySendButton.png"] stretchableImageWithLeftCapWidth:13 topCapHeight:0];
    UIImage *selectedSendBtnBackground = [[UIImage imageNamed:@"MessageEntrySendButton.png"] stretchableImageWithLeftCapWidth:13 topCapHeight:0];
    
	UIButton *doneBtn = [UIButton buttonWithType:UIButtonTypeCustom];
	doneBtn.frame = CGRectMake(containerView.frame.size.width - 69, 8, 63, 27);
    doneBtn.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin;
	[doneBtn setTitle:_("Send") forState:UIControlStateNormal];
    
    [doneBtn setTitleShadowColor:[UIColor colorWithWhite:0 alpha:0.4] forState:UIControlStateNormal];
    doneBtn.titleLabel.shadowOffset = CGSizeMake (0.0, -1.0);
    doneBtn.titleLabel.font = [UIFont boldSystemFontOfSize:16.0f];
    
    [doneBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	[doneBtn addTarget:self action:@selector(_sendButtonTouched) forControlEvents:UIControlEventTouchUpInside];
    [doneBtn setBackgroundImage:sendBtnBackground forState:UIControlStateNormal];
    [doneBtn setBackgroundImage:selectedSendBtnBackground forState:UIControlStateSelected];
	[containerView addSubview:doneBtn];
    containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    
    self.containerView = containerView;
    self.textView = textView;
    
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
        T4CTableCellData *cellData = [[T4CTableCellData alloc] initWithRawData:message
                                                                      dataType:kDataType_Message];
        [self.data addObject:cellData];
    }
    
//    [self preprocessDataSourceForRender:self.dataSource];
}

- (void)viewWillAppear:(BOOL)animated
{
    self.tabBarController.tabBar.hidden = YES;
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

- (void)viewWillDisappear:(BOOL)animated
{
    self.tabBarController.tabBar.hidden = NO;
    [super viewWillDisappear:animated];
}

//- (void)preprocessDataSourceForRender:(HSUBaseDataSource *)dataSource
//{
//    [super preprocessDataSourceForRender:dataSource];
//    
//    [dataSource addEventWithName:@"touchAvatar" target:self action:@selector(touchAvatar:) events:UIControlEventTouchUpInside];
//    [dataSource addEventWithName:@"retry" target:self action:@selector(retry:) events:UIControlEventTouchUpInside];
//}

- (void)_scrollToBottomWithAnimation:(BOOL)animation
{
    [self.tableView setContentOffset:ccp(0, MAX(self.tableView.contentSize.height-self.tableView.height+self.tableView.contentInset.bottom, 0)) animated:animation];
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
    T4CTableCellData *appendingCellData = [[T4CTableCellData alloc] initWithRawData:message dataType:kDataType_Message];
    [self.data addObject:appendingCellData];
//    [self preprocessDataSourceForRender:self.dataSource];
    [self _retrySendMessage:message];
    self.textView.text = nil;
//    [self textViewDidChange:self.textView];
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
        T4CTableCellData *cellData = [[T4CTableCellData alloc] initWithRawData:message
                                                                      dataType:kDataType_Message];
        [self.data addObject:cellData];
    }
    [self.tableView reloadData];
    
    [self _scrollToBottomWithAnimation:YES];
//    [self preprocessDataSourceForRender:self.dataSource];
}

- (void)touchAvatar:(T4CTableCellData *)cellData
{
//    NSString *screenName = cellData.rawData[@"sender"][@"screen_name"];
//    HSUProfileViewController *profileVC = [[HSUProfileViewController alloc] initWithScreenName:screenName];
//    profileVC.profile = cellData.rawData[@"sender"];
//    [self.navigationController pushViewController:profileVC animated:YES];
}


-(void)keyboardWillShow:(NSNotification *)note{
    // get keyboard size and loctaion
	CGRect keyboardBounds;
    [[note.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue: &keyboardBounds];
    NSNumber *duration = [note.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSNumber *curve = [note.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey];
    
    // Need to translate the bounds to account for rotation.
    keyboardBounds = [self.view convertRect:keyboardBounds toView:nil];
    
	// get a rect for the textView frame
	CGRect containerFrame = self.containerView.frame;
    containerFrame.origin.y = self.view.bounds.size.height - (keyboardBounds.size.height + containerFrame.size.height);
	// animations settings
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:[duration doubleValue]];
    [UIView setAnimationCurve:[curve intValue]];
	
	// set views with new info
	self.containerView.frame = containerFrame;
    
    // set table view
    UIEdgeInsets inset = self.tableView.contentInset;
    inset.bottom = self.view.height - containerFrame.origin.y;
    self.tableView.contentInset = inset;
    self.tableView.contentOffset = ccp(0, MAX(self.tableView.contentSize.height-self.tableView.height+self.tableView.contentInset.bottom, 0));
	
	// commit animations
	[UIView commitAnimations];
}

-(void)keyboardWillHide:(NSNotification *)note{
    NSNumber *duration = [note.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSNumber *curve = [note.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey];
	
	// get a rect for the textView frame
	CGRect containerFrame = self.containerView.frame;
    containerFrame.origin.y = self.view.bounds.size.height - containerFrame.size.height;
	
	// animations settings
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:[duration doubleValue]];
    [UIView setAnimationCurve:[curve intValue]];
    
	// set views with new info
	self.containerView.frame = containerFrame;
    
    // set table view
    UIEdgeInsets inset = self.tableView.contentInset;
    inset.bottom = self.view.height - containerFrame.origin.y;
    self.tableView.contentInset = inset;
	
	// commit animations
	[UIView commitAnimations];
}

- (void)growingTextView:(HPGrowingTextView *)growingTextView willChangeHeight:(float)height
{
    float diff = (growingTextView.frame.size.height - height);
    
	CGRect r = self.containerView.frame;
    r.size.height -= diff;
    r.origin.y += diff;
	self.containerView.frame = r;
}

-(void)resignTextView
{
	[self.textView resignFirstResponder];
}

- (void)tapTableView
{
    [self resignTextView];
}

@end