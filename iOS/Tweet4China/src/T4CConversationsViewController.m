//
//  T4CConversationsViewController.m
//  Tweet4China
//
//  Created by Jason Hsu on 14-2-3.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "T4CConversationsViewController.h"
#import "T4CConversationCellData.h"
#import <AudioToolbox/AudioToolbox.h>
#import <SVPullToRefresh/SVPullToRefresh.h>

@interface T4CConversationsViewController ()

@end

@implementation T4CConversationsViewController

- (id)init
{
    self = [super init];
    if (self) {
        notification_add_observer(HSUCheckUnreadTimeNotification, self, @selector(refresh));
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem = self.actionBarButton;
    self.navigationItem.rightBarButtonItems = @[self.composeBarButton, self.searchBarButton];
    [self refresh];
}

- (void)refresh
{
    if (self.refreshState != T4CLoadingState_Done) {
        return;
    }
    
    NSString *sinceId;
    T4CTableCellData *firstData = self.data.firstObject;
    if (firstData) {
        sinceId = [firstData.rawData[@"messages"] lastObject][@"id_str"];
    }
    
    self.refreshState = T4CLoadingState_Loading;
    __weak typeof(self)weakSelf = self;
    [twitter getDirectMessagesSinceID:sinceId success:^(id responseObj) {
        id rMsgs = responseObj;
        [twitter getSentMessagesSinceID:sinceId success:^(id responseObj) {
            id sMsgs = responseObj;
            // merge received messages & sent messages
            NSArray *messages = [[NSArray arrayWithArray:rMsgs] arrayByAddingObjectsFromArray:sMsgs];
            messages = [messages sortedArrayUsingComparator:^NSComparisonResult(id msg1, id msg2) {
                NSNumber *id1 = msg1[@"id"];
                NSNumber *id2 = msg2[@"id"];
                return [id1 compare:id2];
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
                for (T4CConversationCellData *oldCellData in weakSelf.data) {
                    if ([oldCellData.rawData[@"user"][@"screen_name"] isEqualToString:sender_sn] ||
                        [oldCellData.rawData[@"user"][@"screen_name"] isEqualToString:recipient_sn]) {
                        NSMutableDictionary *rawData = oldCellData.rawData.mutableCopy;
                        rawData[@"messages"] = [rawData[@"messages"] arrayByAddingObjectsFromArray:messages];
                        oldCellData.rawData = rawData;
                        found = YES;
                        for (NSDictionary *message in messages) {
                            if ([message[@"recipient"][@"screen_name"] isEqualToString:MyScreenName]) {
                                oldCellData.unreadDM = YES;
                                break;
                            }
                        }
                        break;
                    }
                }
                
                if (!found) {
                    T4CConversationCellData *cellData =
                    [[T4CConversationCellData alloc] initWithRawData:conversation
                                                            dataType:kDataType_Conversation];
                    [weakSelf.data insertObject:cellData atIndex:0];
                    for (NSDictionary *message in messages) {
                        if ([message[@"recipient"][@"screen_name"] isEqualToString:MyScreenName]) {
                            cellData.unreadDM = YES;
                            break;
                        }
                    }
                }
            }
            
            [self.data sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                T4CTableCellData *cellData1 = obj1;
                T4CTableCellData *cellData2 = obj2;
                NSArray *messages1 = cellData1.rawData[@"messages"];
                NSArray *messages2 = cellData2.rawData[@"messages"];
                NSDictionary *message1 = [messages1 lastObject];
                NSDictionary *message2 = [messages2 lastObject];
                return [message2[@"id"] compare:message1[@"id"]];
            }];
            
            [weakSelf.tableView reloadData];
            [weakSelf.tableView.pullToRefreshView stopAnimating];
            weakSelf.refreshState = T4CLoadingState_Done;
            if ([rMsgs count]) {
                AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
                if (!weakSelf.view.window) { // not appear
                    [weakSelf showUnreadIndicator];
                }
            }
            if (messages.count) {
                [weakSelf saveCache];
            }
        } failure:^(NSError *error) {
            [weakSelf.tableView.pullToRefreshView stopAnimating];
            if (error.code == 204) {
                weakSelf.refreshState = T4CLoadingState_Done;
            } else {
                weakSelf.refreshState = T4CLoadingState_Error;
            }
        }];
    } failure:^(NSError *error) {
        [weakSelf.tableView.pullToRefreshView stopAnimating];
        if (error.code == 204) {
            weakSelf.refreshState = T4CLoadingState_Done;
        } else {
            weakSelf.refreshState = T4CLoadingState_Error;
        }
    }];
}

@end
