//
//  T4CTwitPicHandler.m
//  Tweet4China
//
//  Created by Jason Hsu on 14-2-22.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "T4CTwitPicHandler.h"

@implementation T4CTwitPicHandler

+ (BOOL)isTwitPicLink:(NSString *)urlStr
{
    return [urlStr hasPrefix:@"http://twitpic.com/"];
}

+ (NSString *)apiUrlStringWithLink:(NSString *)link
{
    NSString *idstr = [link substringWithRange:NSMakeRange(@"http://twitpic.com/".length, 6)];
    return S(@"http://api.twitpic.com/2/media/show.json?id=%@", idstr);
}

@end
