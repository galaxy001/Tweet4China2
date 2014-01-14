//
//  HSUInstagramMediaCache.m
//  Tweet4China
//
//  Created by Jason Hsu on 14-1-12.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUInstagramMediaCache.h"


static NSMutableDictionary *instagramCache;
static NSUInteger instagramCount;
#define InstagramCacheFileName @"tweet4china.instagram"

@implementation HSUInstagramMediaCache

+ (void)initialize
{
    instagramCache = [NSMutableDictionary dictionary];
}

+ (void)setMediaUrl:(NSString *)mediaUrl forWebUrl:(NSString *)webUrl
{
    if (instagramCount > 200) {
        [[NSFileManager defaultManager] removeItemAtPath:dp(InstagramCacheFileName) error:nil];
    }
    if (![instagramCache objectForKey:webUrl]) {
        instagramCache[webUrl] = mediaUrl;
        NSData *json = [NSJSONSerialization dataWithJSONObject:instagramCache options:0 error:nil];
        [json writeToFile:InstagramCacheFileName atomically:YES];
        instagramCount ++;
    }
}

+ (NSString *)mediaUrlForWebUrl:(NSString *)webUrl
{
    return [instagramCache objectForKey:webUrl];
}

@end
