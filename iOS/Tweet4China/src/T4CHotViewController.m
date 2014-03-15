//
//  T4CHotViewController.m
//  Tweet4China
//
//  Created by Jason Hsu on 14-2-14.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "T4CHotViewController.h"
#import "HSUInstagramHandler.h"

@interface T4CHotViewController ()

@end

@implementation T4CHotViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationItem.leftBarButtonItem = nil;
}

- (int)requestDidFinishRefreshWithData:(NSArray *)dataArr
{
    int r = [super requestDidFinishRefreshWithData:dataArr];
    
    if (!self.unreadCount) {
        [self loadMore];
    }
    return r;
}

- (BOOL)filterData:(NSDictionary *)data
{
    if (![super filterData:data]) {
        return NO;
    }
    
    if ([data[@"user"][@"screen_name"] isEqualToString:MyScreenName]) {
        return NO;
    }
    
    if ([data[@"retweet_count"] integerValue]
        || [data[@"retweeted_status"][@"retweet_count"] integerValue]
        || [data[@"favorite_count"] integerValue]
        || [data[@"retweeted_status"][@"favorite_count"] integerValue]
        || [self hasPhoto:data]
        ) {
        
        return YES;
    }
    
    return NO;
}

- (BOOL)hasPhoto:(NSDictionary *)rawData
{
    NSDictionary *entities = rawData[@"entities"];
    if (entities) {
        NSArray *medias = entities[@"media"];
        NSArray *urls = entities[@"urls"];
        if (medias.count) {
            for (NSDictionary *media in medias) {
                NSString *type = media[@"type"];
                if ([type isEqualToString:@"photo"]) {
                    return YES;
                }
            }
        } else if (urls.count) {
            for (NSDictionary *urlDict in urls) {
                NSString *expandedUrl = urlDict[@"expanded_url"];
                if ([HSUInstagramHandler isInstagramLink:expandedUrl]) {
                    return YES;
                }
            }
        }
    }
    return YES;
}

- (NSUInteger)requestCount
{
    return 3;
}

@end
