//
//  HSUActivityWeixin.h
//  Tweet4China
//
//  Created by Jason Hsu on 14-1-20.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import <SVWebViewController/SVWebViewControllerActivity.h>
#import "WXApi.h"

@interface HSUActivityWeixin : SVWebViewControllerActivity

@property (nonatomic, copy) NSString *shareTitle;
@property (nonatomic, copy) NSString *shareDescription;
+ (BOOL)shareLink:(NSString *)url title:(NSString *)title description:(NSString *)description;

@end
