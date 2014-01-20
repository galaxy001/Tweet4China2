//
//  HSUActivityWeixin.m
//  Tweet4China
//
//  Created by Jason Hsu on 14-1-20.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUActivityWeixin.h"

@implementation HSUActivityWeixin

- (NSString *)activityTitle {
	return _("Weixin");
}

- (UIImage *)activityImage {
    return [UIImage imageNamed:@"icn_activity_weixin"];
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
	return [WXApi isWXAppInstalled];
}

- (void)performActivity {
    [self.class shareLink:self.URLToOpen.absoluteString
                    title:self.shareTitle ?: _("Share a link from Twitter")
              description:self.shareDescription];
    BOOL completed = [[UIApplication sharedApplication] openURL:self.URLToOpen];
	[self activityDidFinish:completed];
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
    req.scene = WXSceneSession;
    BOOL sent = [WXApi sendReq:req];
    if (!sent) {
        [SVProgressHUD showErrorWithStatus:_("Weixin send failed")];
    }
    return sent;
}

@end
