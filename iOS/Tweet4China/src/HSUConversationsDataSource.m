//
//  HSUMessagesDataSource.m
//  Tweet4China
//
//  Created by Jason Hsu on 5/21/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUConversationsDataSource.h"
#import "HSUBaseViewController.h"

@implementation HSUConversationsDataSource

- (id)init
{
    self = [super init];
    if (self) {
        self.useCache = YES;
        notification_add_observer(HSUConversationBackWithIncompletedSendingNotification, self, @selector(_conversationBack:));
    }
    return self;
}

- (void)refresh
{
    [self refreshSilenced];
    
    NSString *sinceId;
    HSUTableCellData *firstData = self.data.firstObject;
    if (firstData) {
        sinceId = [firstData.rawData[@"messages"] lastObject][@"id_str"];
    }
    
    __weak typeof(self)weakSelf = self;
    [twitter getDirectMessagesSinceID:sinceId success:^(id responseObj) {
        id rMsgs = responseObj;
        [twitter getSentMessagesSinceID:sinceId success:^(id responseObj) {
            id sMsgs = responseObj;
            // merge received messages & sent messages
            NSArray *messages = [[NSArray arrayWithArray:rMsgs] arrayByAddingObjectsFromArray:sMsgs];
            messages = [messages sortedArrayUsingComparator:^NSComparisonResult(id msg1, id msg2) {
                NSString *id_str1 = msg1[@"id_str"];
                NSString *id_str2 = msg2[@"id_str"];
                return [id_str1 compare:id_str2];
            }];
            
            NSString *latestID = messages.lastObject[@"id_str"];
            if (latestID) {
                if (![[(UIViewController *)weakSelf.delegate view] window]) { // not appear
                    [weakSelf.delegate dataSourceDidFindUnread:nil];
                }
            }
            
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
                for (HSUTableCellData *oldCellData in weakSelf.data) {
                    if ([oldCellData.rawData[@"user"][@"screen_name"] isEqualToString:sender_sn] ||
                        [oldCellData.rawData[@"user"][@"screen_name"] isEqualToString:recipient_sn]) {
                        NSMutableDictionary *rawData = oldCellData.rawData.mutableCopy;
                        rawData[@"messages"] = [rawData[@"messages"] arrayByAddingObjectsFromArray:messages];
                        oldCellData.rawData = rawData;
                        found = YES;
                        for (NSDictionary *message in messages) {
                            if ([message[@"recipient"][@"screen_name"] isEqualToString:MyScreenName]) {
                                oldCellData.renderData[@"unread_dm"] = @YES;
                                break;
                            }
                        }
                        break;
                    }
                }
                
                if (!found) {
                    HSUTableCellData *cellData = [[HSUTableCellData alloc] initWithRawData:conversation
                                                                                  dataType:kDataType_Conversation];
                    [weakSelf.data insertObject:cellData atIndex:0];
                    for (NSDictionary *message in messages) {
                        if ([message[@"recipient"][@"screen_name"] isEqualToString:MyScreenName]) {
                            cellData.renderData[@"unread_dm"] = @YES;
                            break;
                        }
                    }
                }
            }
            
            [self.data sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                HSUTableCellData *cellData1 = obj1;
                HSUTableCellData *cellData2 = obj2;
                NSArray *messages1 = cellData1.rawData[@"messages"];
                NSArray *messages2 = cellData2.rawData[@"messages"];
                NSDictionary *message1 = [messages1 lastObject];
                NSDictionary *message2 = [messages2 lastObject];
                return [message2[@"id"] compare:message1[@"id"]];
            }];
            
            [weakSelf saveCache];
            [weakSelf.delegate preprocessDataSourceForRender:weakSelf];
            [weakSelf.delegate dataSource:weakSelf didFinishRefreshWithError:nil];
            weakSelf.loadingCount --;
        } failure:^(NSError *error) {
            weakSelf.loadingCount --;
            [weakSelf.delegate dataSource:weakSelf didFinishRefreshWithError:error];
        }];
    } failure:^(NSError *error) {
        weakSelf.loadingCount --;
        [weakSelf.delegate dataSource:weakSelf didFinishRefreshWithError:error];
    }];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        HSUTableCellData *cellData = [self dataAtIndexPath:indexPath];
        NSArray *messages = cellData.rawData[@"messages"];
        for (NSDictionary *message in messages) {
            [twitter deleteDirectMessage:message[@"id_str"] success:^(id responseObj) {
                
            } failure:^(NSError *error) {
                
            }];
        }
        [self removeCellData:cellData];
        [self saveCache];
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

+ (void)checkUnreadForViewController:(HSUBaseViewController *)viewController
{
    NSString *latestIdStr = [[NSUserDefaults standardUserDefaults] objectForKey:S(@"%@_first_id_str_unread", self.class.cacheKey)];
    [twitter getDirectMessagesSinceID:latestIdStr success:^(id responseObj) {
        id rMsgs = responseObj;
        NSArray *messages = rMsgs;
        if ([rMsgs count]) {
            messages = [messages sortedArrayUsingComparator:^NSComparisonResult(id msg1, id msg2) {
                NSString *id_str1 = msg1[@"id_str"];
                NSString *id_str2 = msg2[@"id_str"];
                return [id_str1 compare:id_str2];
            }];
            NSDictionary *msg = [messages lastObject];
            [[NSUserDefaults standardUserDefaults] setObject:msg[@"id_str"] forKey:S(@"%@_first_id_str_unread", self.class.cacheKey)];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [viewController dataSourceDidFindUnread:nil];
        }
    } failure:^(NSError *error) {
        
    }];
}

- (void)clearCache
{
    [super clearCache];
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:S(@"%@_first_id_str_unread", self.class.cacheKey)];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
