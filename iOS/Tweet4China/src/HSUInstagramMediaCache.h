//
//  HSUInstagramMediaCache.h
//  Tweet4China
//
//  Created by Jason Hsu on 14-1-12.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HSUInstagramMediaCache : NSObject

+ (void)setMediaUrl:(NSString *)mediaUrl forWebUrl:(NSString *)webUrl;
+ (NSString *)mediaUrlForWebUrl:(NSString *)webUrl;

@end