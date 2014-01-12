//
//  HSURecentPhotosDataSource.m
//  Tweet4China
//
//  Created by Jason Hsu on 14-1-12.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSURecentPhotosDataSource.h"

@implementation HSURecentPhotosDataSource


- (void)fetchRefreshDataWithSuccess:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure
{
    __weak typeof(self)weakSelf = self;
    [super fetchRefreshDataWithSuccess:^(id responseObj) {
        NSMutableArray *tweetsWithPhoto = [NSMutableArray array];
        for (NSDictionary *tweet in responseObj) {
            NSDictionary *entities = tweet[@"entities"];
            if (entities) {
                NSArray *medias = entities[@"media"];
                NSArray *urls = entities[@"urls"];
                if (medias.count) {
                    NSDictionary *media = medias[0];
                    NSString *type = media[@"type"];
                    if ([type isEqualToString:@"photo"]) {
                        [tweetsWithPhoto addObject:tweet];
                    }
                } else if (urls.count) {
                    for (NSDictionary *urlDict in urls) {
                        NSString *expandedUrl = urlDict[@"expanded_url"];
                        if ([weakSelf isPhotoUrl:expandedUrl]) {
                            [tweetsWithPhoto addObject:tweet];
                        }
                    }
                }
            }
        }
        
        NSDictionary *tweet = [tweetsWithPhoto lastObject];
        weakSelf.lastStatusID = tweet[@"id_str"];
        
        success(tweetsWithPhoto);
        
        if (tweetsWithPhoto.count == 0 || [responseObj count] < weakSelf.requestCount) {
            [weakSelf.data.lastObject setRawData:@{@"status": @(kLoadMoreCellStatus_NoMore)}];
        }
    } failure:^(NSError *error) {
        failure(error);
    }];
}

- (void)fetchMoreDataWithSuccess:(HSUTwitterAPISuccessBlock)success failure:(HSUTwitterAPIFailureBlock)failure
{
    __weak typeof(self)weakSelf = self;
    [super fetchMoreDataWithSuccess:^(id responseObj) {
        NSMutableArray *tweetsWithPhoto = [NSMutableArray array];
        for (NSDictionary *tweet in responseObj) {
            NSDictionary *entities = tweet[@"entities"];
            if (entities) {
                NSArray *medias = entities[@"media"];
                NSArray *urls = entities[@"urls"];
                if (medias.count) {
                    NSDictionary *media = medias[0];
                    NSString *type = media[@"type"];
                    if ([type isEqualToString:@"photo"]) {
                        [tweetsWithPhoto addObject:tweet];
                    }
                } else if (urls.count) {
                    for (NSDictionary *urlDict in urls) {
                        NSString *expandedUrl = urlDict[@"expanded_url"];
                        if ([weakSelf isPhotoUrl:expandedUrl]) {
                            [tweetsWithPhoto addObject:tweet];
                        }
                    }
                }
            }
        }
        
        NSDictionary *tweet = [tweetsWithPhoto lastObject];
        weakSelf.lastStatusID = tweet[@"id_str"];
        
        success(tweetsWithPhoto);
        
        if (tweetsWithPhoto.count == 0 || [responseObj count] < weakSelf.requestCount) {
            [weakSelf.data.lastObject setRawData:@{@"status": @(kLoadMoreCellStatus_NoMore)}];
        }
    } failure:^(NSError *error) {
        failure(error);
    }];
}

- (BOOL)isPhotoUrl:(NSString *)url
{
    if ([url hasPrefix:@"http://instagram.com"] || [url hasPrefix:@"http://instagr.am"]) {
        
        return YES;
    }
    return NO;
}

@end
