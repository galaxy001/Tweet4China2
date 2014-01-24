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
#define InstagramCacheFileName @"tweet4china.instagram.cache"

@implementation HSUInstagramMediaCache

+ (void)initialize
{
    NSData *data = [NSData dataWithContentsOfFile:dp(InstagramCacheFileName)];
    if (data) {
        instagramCache = [[NSJSONSerialization JSONObjectWithData:data options:0 error:nil] mutableCopy];
    }
    if (!instagramCache) {
        instagramCache = [NSMutableDictionary dictionary];
    }
}

+ (void)setMedia:(NSDictionary *)media forWebUrl:(NSString *)webUrl
{
    if (instagramCount > 200) {
        [[NSFileManager defaultManager] removeItemAtPath:dp(InstagramCacheFileName) error:nil];
    }
    if (![instagramCache objectForKey:webUrl]) {
        instagramCache[webUrl] = media;
        NSData *json = [NSJSONSerialization dataWithJSONObject:instagramCache options:0 error:nil];
        [json writeToFile:dp(InstagramCacheFileName) atomically:YES];
        instagramCount ++;
    }
}

+ (NSDictionary *)mediaForWebUrl:(NSString *)webUrl
{
    return [instagramCache objectForKey:webUrl];
}

@end
