//
//  T4CReplableViewController.m
//  Tweet4China
//
//  Created by Jason Hsu on 14-2-8.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "T4CReplableViewController.h"
#import "HPGrowingTextView.h"

@interface T4CReplableViewController () <HPGrowingTextViewDelegate>

@property (nonatomic, strong) UIGestureRecognizer *tapGesture;

@end

@implementation T4CReplableViewController

- (void)dealloc
{
    self.textView.delegate = nil;
}

- (id)init
{
    self = [super init];
    if (self) {
        if (Sys_Ver < 7) {
            return self;
        }
        
//        notification_add_observer(UIKeyboardWillChangeFrameNotification, self, @selector(keyboardFrameChanged:));
        notification_add_observer(UIKeyboardWillHideNotification, self, @selector(keyboardWillHide:));
        notification_add_observer(UIKeyboardWillShowNotification, self, @selector(keyboardWillShow:));
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (Sys_Ver < 7) {
        return;
    }
    
    UIToolbar *toolbar = [[UIToolbar alloc] init];
    [self.view addSubview:toolbar];
    self.toolbar = toolbar;
    self.toolbar.size = ccs(self.view.width, 44);
    toolbar.bottom = self.view.height;
    
    HPGrowingTextView *textView = [[HPGrowingTextView alloc] init];
    [toolbar addSubview:textView];
    self.textView = textView;
    textView.isScrollable = NO;
    textView.contentInset = UIEdgeInsetsMake(0, 5, 0, 5);
	textView.minNumberOfLines = 1;
	textView.maxNumberOfLines = 6;
	textView.font = [UIFont systemFontOfSize:15.0f];
	textView.delegate = self;
    textView.internalTextView.scrollIndicatorInsets = UIEdgeInsetsMake(5, 0, 5, 0);
    textView.backgroundColor = [UIColor whiteColor];
    textView.internalTextView.layer.cornerRadius = 5;
    textView.frame = CGRectInset(self.toolbar.bounds, 8, 8);
    textView.width += 8;
    textView.placeholder = [self textViewPlaceHolder];
    
	UIButton *sendButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    if (Sys_Ver < 7) {
        sendButton = [[UIButton alloc] init];
    }
	[toolbar addSubview:sendButton];
	self.sendButton = sendButton;
    [sendButton setTitle:[self sendButtonTitle] forState:UIControlStateNormal];
	[sendButton addTarget:self action:@selector(_sendButtonTouched) forControlEvents:UIControlEventTouchUpInside];
    sendButton.contentEdgeInsets = edi(0, 10, 0, 10);
    [sendButton sizeToFit];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (Sys_Ver < 7) {
        return;
    }
    
    self.toolbar.bottom = self.view.height - tabbar_height;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    if (Sys_Ver < 7) {
        return;
    }
    
    self.toolbar.width = self.view.width;
    self.sendButton.rightCenter = ccp(self.toolbar.width, self.toolbar.height/2);
    self.textView.frame = CGRectInset(self.toolbar.bounds, 8, 8);
    self.textView.width -= self.sendButton.width - 8;
    
    UIEdgeInsets inset = self.tableView.contentInset;
    inset.bottom = self.view.height - self.toolbar.top;
    self.tableView.contentInset = inset;
}

-(void)keyboardWillShow:(NSNotification *)note
{
    // get keyboard size and loctaion
	CGRect keyboardBounds;
    [[note.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue: &keyboardBounds];
    NSNumber *duration = [note.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSNumber *curve = [note.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey];
    
    // Need to translate the bounds to account for rotation.
    keyboardBounds = [self.view convertRect:keyboardBounds toView:nil];
    
	// get a rect for the textView frame
	CGRect containerFrame = self.toolbar.frame;
    containerFrame.origin.y = self.view.height - (keyboardBounds.size.height + containerFrame.size.height);
	// animations settings
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:[duration doubleValue]];
    [UIView setAnimationCurve:[curve intValue]];
    [UIView setAnimationDelegate:self];
	
	// set views with new info
	self.toolbar.frame = containerFrame;
    
    // set table view
    UIEdgeInsets inset = self.tableView.contentInset;
    inset.bottom = self.view.height - containerFrame.origin.y;
    self.tableView.contentInset = inset;
	
	// commit animations
	[UIView commitAnimations];
    
    if (!self.tapGesture) {
        UIGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapTableView)];
        self.tapGesture = tapGesture;
    }
    [self.tableView addGestureRecognizer:self.tapGesture];
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    NSString *text = [self textViewDefaultText];
    if (!self.textView.hasText) {
        self.textView.text = text;
        self.textView.selectedRange = NSMakeRange(text.length, 0);
    } else if ([self.textView.text isEqualToString:text]) {
        self.textView.text = nil;
    }
}

-(void)keyboardFrameChanged:(NSNotification *)note
{
    // get a rect for the textView frame
	CGRect containerFrame = self.toolbar.frame;
    containerFrame.origin.y = self.view.height - containerFrame.size.height - tabbar_height;
    
	// set views with new info
	self.toolbar.frame = containerFrame;
    
    // set table view
    UIEdgeInsets inset = self.tableView.contentInset;
    inset.bottom = self.view.height - containerFrame.origin.y;
    self.tableView.contentInset = inset;
}

-(void)keyboardWillHide:(NSNotification *)note
{
    NSNumber *duration = [note.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSNumber *curve = [note.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey];
	
	// get a rect for the textView frame
	CGRect containerFrame = self.toolbar.frame;
    containerFrame.origin.y = self.view.height - containerFrame.size.height - tabbar_height;
	
	// animations settings
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:[duration doubleValue]];
    [UIView setAnimationCurve:[curve intValue]];
    [UIView setAnimationDelegate:self];
    
	// set views with new info
	self.toolbar.frame = containerFrame;
    
    // set table view
    UIEdgeInsets inset = self.tableView.contentInset;
    inset.bottom = self.view.height - containerFrame.origin.y;
    self.tableView.contentInset = inset;
	
	// commit animations
	[UIView commitAnimations];
    [self.tableView removeGestureRecognizer:self.tapGesture];
}

- (void)growingTextView:(HPGrowingTextView *)growingTextView willChangeHeight:(float)height
{
    float diff = (growingTextView.frame.size.height - height);
    
	CGRect r = self.toolbar.frame;
    r.size.height -= diff;
    r.origin.y += diff;
	self.toolbar.frame = r;
}

- (void)tapTableView
{
    if (self.textView.isFirstResponder) {
        [self.textView resignFirstResponder];
    }
}

- (NSString *)textViewPlaceHolder
{
    return nil;
}

- (NSString *)sendButtonTitle
{
    return _("Send");
}

- (NSString *)textViewDefaultText
{
    return nil;
}

@end
