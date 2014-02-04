//
//  T4CConnectViewController.m
//  Tweet4China
//
//  Created by Jason Hsu on 14-2-2.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "T4CConnectViewController.h"

@interface T4CConnectViewController ()

@end

@implementation T4CConnectViewController

- (NSString *)apiString
{
    return @"statuses/mentions_timeline";
}

- (void)requestDidFinishRefreshWithData:(NSArray *)dataArr newFollowers:(NSArray *)newFollowers newRetweets:(NSArray *)newRetweets
{
    [super requestDidFinishRefreshWithData:dataArr];
    
    if (newRetweets.count) {
        T4CTableCellData *rtCellData = [[T4CTableCellData alloc]
                                        initWithRawData:newRetweets.firstObject
                                        dataType:kDataType_NewRetweets];
        [self.data insertObject:rtCellData atIndex:0];
    }
    if (newFollowers.count) {
        T4CTableCellData *nfCellData = [[T4CTableCellData alloc]
                                        initWithRawData:@{@"followers": newFollowers}
                                        dataType:kDataType_NewFollowers];
        [self.data insertObject:nfCellData atIndex:0];
    }
    [self.tableView reloadData];
    [self scrollTableViewToCurrentOffsetAfterInsertNewCellCount:2];
}

- (void)requestDidFinishRefreshWithData:(NSArray *)dataArr newFollowers:(NSArray *)newFollowers
{
    __weak typeof(self)weakSelf = self;
    [twitter sendGETWithUrl:[self requestUrlWithAPIString:@"statuses/retweets_of_me"]
                 parameters:@{@"trim_user": @"true"}
                    success:^(id responseObj)
    {
        NSMutableArray *retweetedStatuses = @[].mutableCopy;
        for (NSDictionary *t in responseObj) {
            if ([t[@"retweet_count"] longLongValue]) {
                [retweetedStatuses addObject:t];
            }
        }
//        [HSUCommonTools writeJSONObject:@[] toFile:@"connect_retweets_of_me"];
        NSArray *oldRetweetedStatuses = [HSUCommonTools readJSONObjectFromFile:@"connect_retweets_of_me"];
        NSMutableArray *diffTweets = [NSMutableArray arrayWithArray:retweetedStatuses];
        for (int i=0; i<retweetedStatuses.count; i++) {
            NSMutableDictionary *nt = [retweetedStatuses[i] mutableCopy];
            for (NSDictionary *ot in oldRetweetedStatuses) {
                if ([nt[@"id"] isEqual:ot[@"id"]]) {
                    if ([nt[@"retweet_count"] isEqual:ot[@"retweet_count"]]) {
                        [diffTweets removeObject:nt];
                    }
                    if (ot[@"retweets"]) {
                        nt[@"retweets"] = ot[@"retweets"];
                        retweetedStatuses[i] = nt;
                    }
                    break;
                }
            }
        }
//        [HSUCommonTools writeJSONObject:retweetedStatuses toFile:@"connect_retweets_of_me"];
        if (diffTweets.count) {
            NSDictionary *retweetedStatus = diffTweets.firstObject;
            NSString *tid = retweetedStatus[@"id"];
            [twitter sendGETWithUrl:[self requestUrlWithAPIFormat:@"statuses/retweets/%@" idString:tid]
                         parameters:@{@"count": @"10"}
                            success:^(id responseObj)
            {
                NSArray *retweets = responseObj;
                NSMutableDictionary *retweetedStatus;
                NSUInteger idx;
                for (NSDictionary *rt in retweetedStatuses) {
                    if ([rt[@"id"] isEqual:tid]) {
                        retweetedStatus = [rt mutableCopy];
                        idx = [retweetedStatuses indexOfObject:rt];
                        break;
                    }
                }
                NSArray *oldRetweets = retweetedStatus[@"retweets"];
                NSMutableArray *diffRetweets = [NSMutableArray arrayWithArray:retweets];
                for (NSDictionary *nt in retweets) {
                    for (NSDictionary *ot in oldRetweets) {
                        if ([nt[@"id"] isEqual:ot[@"id"]]) {
                            [diffRetweets removeObject:nt];
                            break;
                        }
                    }
                }
                if (diffRetweets.count) {
                    retweetedStatus[@"retweets"] = diffRetweets;
                    retweetedStatuses[idx] = retweetedStatus;
                    [HSUCommonTools writeJSONObject:retweetedStatuses toFile:@"connect_retweets_of_me"];
                    NSMutableArray *retweeters = [NSMutableArray arrayWithCapacity:diffRetweets.count];
                    for (NSDictionary *retweet in diffRetweets) {
                        [retweeters addObject:retweet[@"user"]];
                    }
                    retweetedStatus[@"retweeters"] = retweeters;
                    [weakSelf requestDidFinishRefreshWithData:dataArr newFollowers:newFollowers newRetweets:@[retweetedStatus]];
                } else {
                    [weakSelf requestDidFinishRefreshWithData:dataArr newFollowers:newFollowers newRetweets:nil];
                }
            } failure:^(NSError *error)
            {
                [weakSelf requestDidFinishRefreshWithData:dataArr newFollowers:newFollowers newRetweets:nil];
            }];
        }
    } failure:^(NSError *error) {
        [weakSelf requestDidFinishRefreshWithData:dataArr newFollowers:newFollowers newRetweets:nil];
    }];
}

- (void)requestDidFinishRefreshWithData:(NSArray *)dataArr
{
    NSMutableDictionary *params = [@{} mutableCopy];
    params[@"screen_name"] = MyScreenName;
    params[@"count"] = @"1000"; // max 5000
    __weak typeof(self)weakSelf = self;
    [twitter sendGETWithUrl:[self requestUrlWithAPIString:@"followers/ids"]
              parameters:params
                 success:^(id responseObj)
     {
         NSArray *newIds;
         NSDictionary *usersDict = responseObj;
         NSArray *ids = usersDict[@"ids"];
         NSString *fileName = dp(@"connect_followers_ids.json");
         NSData *oldIdsData = [NSData dataWithContentsOfFile:fileName];
         if (oldIdsData) {
             NSArray *oldIds = [NSJSONSerialization JSONObjectWithData:oldIdsData
                                                               options:0
                                                                 error:nil];
             if (oldIds) {
                 for (NSNumber *oId in oldIds) {
                     if (newIds) {
                         break;
                     }
                     for (NSNumber *nId in [ids reverseObjectEnumerator]) {
                         if ([oId isEqual:nId]) {
                             NSUInteger idx = [ids indexOfObject:nId];
                             newIds = [ids subarrayWithRange:NSMakeRange(0, idx)];
                             break;
                         }
                     }
                 }
             }
         }
         
//         newIds = [ids subarrayWithRange:NSMakeRange(0, 90)];
         if (ids.count) {
             NSData *json = [NSJSONSerialization dataWithJSONObject:ids options:0 error:nil];
             [json writeToFile:fileName atomically:NO];
         } else {
             [[NSFileManager defaultManager] removeItemAtPath:fileName error:nil];
         }
         
         if (newIds.count) {
             [twitter lookupUsers:newIds
                          success:^(id responseObj)
              {
                  NSArray *newFollowers = responseObj;
                  [weakSelf requestDidFinishRefreshWithData:dataArr newFollowers:newFollowers];
              } failure:^(NSError *error)
              {
                  [weakSelf requestDidFinishRefreshWithData:dataArr newFollowers:nil];
              }];
         } else {
             [weakSelf requestDidFinishRefreshWithData:dataArr newFollowers:nil];
         }
     } failure:^(NSError *error)
     {
        [weakSelf requestDidFinishRefreshWithData:dataArr newFollowers:nil];
     }];
}

- (long long)gapTopIDWithGapCellData:(T4CGapCellData *)gapCellData
{
    NSInteger gapIndex = [self.data indexOfObject:gapCellData];
    if (gapIndex <= 0 || gapIndex >= self.data.count-1) {
        return 0;
    }
    
    for (int i=gapIndex-1; i>0; i--) {
        T4CTableCellData *cellData = self.data[i];
        if ([cellData.dataType isEqualToString:kDataType_Status]) {
            long long gapTopID = [cellData.rawData[@"id"] longLongValue];
            return gapTopID;
        }
    }
    
    return 0;
}

- (long long)gapBotIDWithGapCellData:(T4CGapCellData *)gapCellData
{
    NSInteger gapIndex = [self.data indexOfObject:gapCellData];
    if (gapIndex <= 0 || gapIndex >= self.data.count-1) {
        return 0;
    }
    
    for (int i=gapIndex+1; i<self.data.count; i++) {
        T4CTableCellData *cellData = self.data[i];
        if ([cellData.dataType isEqualToString:kDataType_Status]) {
            long long gapBotID = [cellData.rawData[@"id"] longLongValue];
            return gapBotID;
        }
    }
    
    return 0;
}

@end
