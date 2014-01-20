//
//  HSUActivityWeixinMoments.m
//  Tweet4China
//
//  Created by Jason Hsu on 14-1-20.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUActivityWeixinMoments.h"

@implementation HSUActivityWeixinMoments

- (NSString *)activityTitle {
	return _("Weixin Moments");
}

- (UIImage *)activityImage {
    return [UIImage imageNamed:@"icn_activity_weixin_moments"];
}

+ (BOOL)shareLink:(NSString *)url title:(NSString *)title description:(NSString *)description
{
    WXMediaMessage *message = [WXMediaMessage message];
    message.title = title;
    message.description = description;
    WXWebpageObject *webPage = [WXWebpageObject object];
    webPage.webpageUrl = url;
    message.mediaObject = webPage;
    SendMessageToWXReq* req = [[SendMessageToWXReq alloc] init];
    req.bText = NO;
    req.message = message;
    req.scene = WXSceneTimeline;
    BOOL sent = [WXApi sendReq:req];
    if (!sent) {
        [SVProgressHUD showErrorWithStatus:_("Weixin send failed")];
    }
    return sent;
}

@end
