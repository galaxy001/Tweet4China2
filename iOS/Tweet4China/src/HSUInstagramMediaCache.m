//
//  HSUInstagramMediaCache.m
//  Tweet4China
//
//  Created by Jason Hsu on 14-1-12.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUInstagramMediaCache.h"


static NSUserDefaults *instagramUserDefaults;
static NSUInteger instagramCount;
const static NSString *InstagramUserDefaultsSuiteName = @"tweet4china.instagram.com";

@implementation HSUInstagramMediaCache

+ (void)initialize
{
    instagramUserDefaults = [[NSUserDefaults alloc] initWithSuiteName:[InstagramUserDefaultsSuiteName copy]];
    instagramCount = [[instagramUserDefaults dictionaryRepresentation] count];
}

+ (void)setMediaUrl:(NSString *)mediaUrl forWebUrl:(NSString *)webUrl
{
    if (instagramCount > 200) {
        [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:[InstagramUserDefaultsSuiteName copy]];
    }
    if (![instagramUserDefaults stringForKey:webUrl]) {
        [instagramUserDefaults setObject:mediaUrl forKey:webUrl];
        [instagramUserDefaults synchronize];
        instagramCount ++;
    }
}

+ (NSString *)mediaUrlForWebUrl:(NSString *)webUrl
{
    return [instagramUserDefaults objectForKey:webUrl];
}

@end
