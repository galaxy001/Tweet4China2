//
//  T4CReplableViewController.h
//  Tweet4China
//
//  Created by Jason Hsu on 14-2-8.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "T4CTableViewController.h"

@class HPGrowingTextView;
@interface T4CReplableViewController : T4CTableViewController

@property (nonatomic, weak) UIToolbar *toolbar;
@property (nonatomic, weak) HPGrowingTextView *textView;
@property (nonatomic, weak) UIButton *sendButton;

- (NSString *)textViewPlaceHolder;
- (NSString *)sendButtonTitle;
- (NSString *)textViewDefaultText;

-(void)keyboardWillShow:(NSNotification *)note;
-(void)keyboardWillHide:(NSNotification *)note;

@end
