//
//  HSUMessageViewController.h
//  Tweet4China
//
//  Created by Jason Hsu on 5/21/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUBaseViewController.h"

@interface HSUMessagesViewController : HSUBaseViewController

@property (nonatomic, strong) NSDictionary *myProfile;
@property (nonatomic, strong) NSDictionary *herProfile;
@property (nonatomic, assign) BOOL followedMe;
@property (nonatomic, assign) BOOL relactionshipLoaded;

- (void)updateConversation:(NSDictionary *)conversation;

@end
