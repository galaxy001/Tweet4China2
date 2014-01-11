//
//  HSUMessageDataSource.m
//  Tweet4China
//
//  Created by Jason Hsu on 5/21/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUMessagesDataSource.h"

@implementation HSUMessagesDataSource

- (id)initWithConversation:(NSDictionary *)conversation
{
    self = [super init];
    if (self) {
        self.conversation = conversation;
        for (NSDictionary *message in conversation[@"messages"]) {
            HSUTableCellData *cellData = [[HSUTableCellData alloc] initWithRawData:message dataType:kDataType_Message];
            [self.data addObject:cellData];
        }
    }
    return self;
}

- (void)deleteConversation
{
    notification_post_with_object(HSUDeleteConversationNotification, self.conversation);
    for (NSDictionary *message in self.conversation[@"messages"]) {
        [twitter deleteDirectMessage:message[@"id_str"] success:^(id responseObj) {
            
        } failure:^(NSError *error) {
            
        }];
    }
}

@end
