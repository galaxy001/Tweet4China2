//
//  HSUInstagramHandler.m
//  Tweet4China
//
//  Created by Jason Hsu on 14-1-20.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUInstagramHandler.h"

@implementation HSUInstagramHandler

+ (BOOL)openInInstagramWithMediaID:(NSString *)mediaID
{
    if (mediaID) {
        NSURL *instagramURL = [NSURL URLWithString:[NSString stringWithFormat:@"instagram://media?id=%@", mediaID]];
        if ([[UIApplication sharedApplication] canOpenURL:instagramURL]) {
            return [[UIApplication sharedApplication] openURL:instagramURL];
        }
    }
    return NO;
}

+ (BOOL)isInstagramLink:(NSString *)urlStr
{
    return ([urlStr hasPrefix:@"http://instagram.com/p/"] ||
            [urlStr hasPrefix:@"http://instagr.am/p/"]);
}

+ (NSString *)apiUrlStringWithLink:(NSString *)link
{
    return S(@"http://api.instagram.com/oembed?url=%@", link);
}

@end
