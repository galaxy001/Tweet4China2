//
//  T4CMessagesViewController.h
//  Tweet4China
//
//  Created by Jason Hsu on 14-2-3.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "T4CReplableViewController.h"

@interface T4CMessagesViewController : T4CReplableViewController

@property (nonatomic, strong) NSDictionary *myProfile;
@property (nonatomic, strong) NSDictionary *herProfile;
@property (nonatomic, assign) BOOL followedMe;
@property (nonatomic, assign) BOOL relactionshipLoaded;
@property (nonatomic, strong) NSDictionary *conversation;

@property (nonatomic, assign) float keyboardHeight;
@property (nonatomic, assign) float keyboardAnimationDuration;
@property (nonatomic, assign) float defaultKeyboardHeight;

- (void)updateConversation:(NSDictionary *)conversation;

@end
