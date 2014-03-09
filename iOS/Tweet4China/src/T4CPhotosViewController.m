//
//  T4CPhotosViewController.m
//  Tweet4China
//
//  Created by Jason Hsu on 14-2-4.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "T4CPhotosViewController.h"
#import "HSUInstagramHandler.h"

@interface T4CPhotosViewController ()

@end

@implementation T4CPhotosViewController

- (id)init
{
    self = [super init];
    if (self) {
        self.useCache = NO;
    }
    return self;
}

- (BOOL)filterData:(NSDictionary *)tweet
{
    NSDictionary *entities = tweet[@"entities"];
    if (entities) {
        NSArray *medias = entities[@"media"];
        NSArray *urls = entities[@"urls"];
        if (medias.count) {
            NSDictionary *media = medias[0];
            NSString *type = media[@"type"];
            if ([type isEqualToString:@"photo"]) {
                return YES;
            }
        } else if (urls.count) {
            for (NSDictionary *urlDict in urls) {
                NSString *expandedUrl = urlDict[@"expanded_url"];
                if ([self isPhotoUrl:expandedUrl]) {
                    return YES;
                }
            }
        }
    }
    return NO;
}

- (BOOL)isPhotoUrl:(NSString *)url
{
    return [HSUInstagramHandler isInstagramLink:url];
}

- (NSUInteger)requestCount
{
    return 200;
}

@end
