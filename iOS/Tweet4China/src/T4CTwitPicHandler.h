//
//  T4CTwitPicHandler.h
//  Tweet4China
//
//  Created by Jason Hsu on 14-2-22.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface T4CTwitPicHandler : NSObject

+ (BOOL)isTwitPicLink:(NSString *)urlStr;
+ (NSString *)apiUrlStringWithLink:(NSString *)link;

@end
