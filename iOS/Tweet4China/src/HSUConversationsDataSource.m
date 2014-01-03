//
//  HSUMessagesDataSource.m
//  Tweet4China
//
//  Created by Jason Hsu on 5/21/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUConversationsDataSource.h"

@implementation HSUConversationsDataSource

- (id)init
{
    self = [super init];
    if (self) {
        notification_add_observer(HSUConversationBackWithIncompletedSendingNotification, self, @selector(_conversationBack:));
    }
    return self;
}

- (void)refresh
{
    [super refresh];
    
    NSString *sinceId = nil;
    for (HSUTableCellData *cellData in self.data) {
        NSDictionary *conversation = cellData.rawData;
        NSArray *messages = conversation[@"messages"];
        if (messages.count) {
            NSDictionary *message = messages.lastObject;
            sinceId = message[@"id_str"];
            break;
        }
    }
    [SVProgressHUD showWithStatus:_(self.count ? @"Updating..." : @"Loading...")];
    [TWENGINE getDirectMessagesSinceID:sinceId success:^(id responseObj) {
        id rMsgs = responseObj;
        [TWENGINE getSentMessagesSinceID:sinceId success:^(id responseObj) {
            id sMsgs = responseObj;
            // merge received messages & sent messages
            NSArray *messages = [[NSArray arrayWithArray:rMsgs] arrayByAddingObjectsFromArray:sMsgs];
            messages = [messages sortedArrayUsingComparator:^NSComparisonResult(id msg1, id msg2) {
                NSString *id_str1 = msg1[@"id_str"];
                NSString *id_str2 = msg2[@"id_str"];
                return [id_str1 compare:id_str2];
            }];
            
            // reorgnize messages as dict, friend_screen_name as key, refered messages as value
            NSMutableDictionary *conversations = [[NSMutableDictionary alloc] init];
            NSMutableArray *orderedFriendScreenNames = [NSMutableArray array];
            for (NSDictionary *message in messages) {
                NSString *sender_sn = message[@"sender_screen_name"];
                NSString *recipient_sn = message[@"recipient_screen_name"];
                
                NSString *fsn = [MyScreenName isEqualToString:sender_sn] ? recipient_sn : sender_sn;
                NSMutableArray *conversation = conversations[fsn];
                if (!conversation) {
                    conversation = [NSMutableArray array];
                    conversations[fsn] = conversation;
                    [orderedFriendScreenNames addObject:fsn];
                }
                [conversation addObject:message];
            }
            
            // create cell data, rawData is dict with keys: user, messages, created_at
            for (NSString *fsn in orderedFriendScreenNames) {
                NSMutableDictionary *conversation = [NSMutableDictionary dictionary];
                NSArray *messages = conversations[fsn];
                NSDictionary *latestMessage = messages.lastObject;
                NSString *sender_sn = latestMessage[@"sender_screen_name"];
                NSString *recipient_sn = latestMessage[@"recipient_screen_name"];
                
                conversation[@"user"] = [fsn isEqualToString:sender_sn] ? latestMessage[@"sender"] : latestMessage[@"recipient"];
                conversation[@"messages"] = messages;
                conversation[@"created_at"] = latestMessage[@"created_at"];
                
                BOOL found = NO;
                for (HSUTableCellData *oldCellData in self.data) {
                    if ([oldCellData.rawData[@"user"][@"screen_name"] isEqualToString:sender_sn] ||
                        [oldCellData.rawData[@"user"][@"screen_name"] isEqualToString:recipient_sn]) {
                        NSMutableDictionary *rawData = oldCellData.rawData.mutableCopy;
                        rawData[@"messages"] = [rawData[@"messages"] arrayByAddingObjectsFromArray:messages];
                        oldCellData.rawData = rawData;
                        found = YES;
                    }
                }
                
                if (!found) {
                    HSUTableCellData *cellData = [[HSUTableCellData alloc] initWithRawData:conversation
                                                                                  dataType:kDataType_Conversation];
                    [self.data insertObject:cellData atIndex:0];
                }
            }
            
            [self saveCache];
            [self.delegate preprocessDataSourceForRender:self];
            [self.delegate dataSource:self didFinishRefreshWithError:nil];
            self.loadingCount --;
            
            [SVProgressHUD dismiss];
        } failure:^(NSError *error) {
            [SVProgressHUD showErrorWithStatus:_(@"Load Messages failed")];
        }];
    } failure:^(NSError *error) {
        [SVProgressHUD showErrorWithStatus:_(@"Load Messages failed")];
    }];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        HSUTableCellData *cellData = [self dataAtIndexPath:indexPath];
        NSArray *messages = cellData.rawData[@"messages"];
        for (NSDictionary *message in messages) {
            [TWENGINE deleteDirectMessage:message[@"id_str"] success:^(id responseObj) {
                
            } failure:^(NSError *error) {
                
            }];
        }
        [self removeCellData:cellData];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
    }
}

+ (id)dataSourceWithDelegate:(id<HSUBaseDataSourceDelegate>)delegate useCache:(BOOL)useCahce
{
    HSUConversationsDataSource *dataSource = [super dataSourceWithDelegate:delegate useCache:useCahce];
    HSUTableCellData *lastCellData = dataSource.data.lastObject;
    if (lastCellData &&
        [lastCellData.dataType isEqualToString:kDataType_LoadMore]) {
        
        [dataSource.data removeLastObject];
    }
    return dataSource;
}

- (void)_conversationBack:(NSNotification *)notification
{
    NSArray *obj = notification.object;
    NSDictionary *conversation = obj[0];
    NSString *text = obj[1];
    for (uint i=0; i<self.count; i++) {
        HSUTableCellData *cd = [self dataAtIndex:i];
        if (cd.rawData == conversation) {
            cd.renderData[@"typingMessage"] = text;
        }
    }
}

@end
