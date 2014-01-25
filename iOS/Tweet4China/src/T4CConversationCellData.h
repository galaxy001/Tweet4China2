//
//  T4CConversationCellData.h
//  Tweet4China
//
//  Created by Jason Hsu on 14-1-25.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "T4CTableCellData.h"

@interface T4CConversationCellData : T4CTableCellData

@property (nonatomic, assign) BOOL unreadDM;
@property (nonatomic, copy) NSString *typingMessage;

@end
