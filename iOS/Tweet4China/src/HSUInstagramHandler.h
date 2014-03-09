//
//  HSUInstagramHandler.h
//  Tweet4China
//
//  Created by Jason Hsu on 14-1-20.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HSUInstagramHandler : NSObject

+ (BOOL)openInInstagramWithMediaID:(NSString *)mediaID;
+ (BOOL)isInstagramLink:(NSString *)urlStr;
+ (NSString *)apiUrlStringWithLink:(NSString *)link;

@end
