//
//  HSUModelWebViewController.m
//  Tweet4China
//
//  Created by Jason Hsu on 14-1-23.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUModalWebViewController.h"
#import <SVWebViewController/SVWebViewController.h>

@interface HSUModalWebViewController ()

@property (nonatomic, strong) SVWebViewController *webViewController;
@property (nonatomic, strong) UIBarButtonItem *userAgentButton;

@end

@implementation HSUModalWebViewController



- (id)initWithURL:(NSURL *)URL {
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:HSUSettings][HSUSettingDesktopUserAgent] boolValue]) {
        [HSUCommonTools switchToDesktopUserAgent];
    } else {
        [HSUCommonTools resetUserAgent];
    }
    return [super initWithURL:URL];
    
    if (self = [super initWithURL:URL]) {
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                    target:self
                                                                                    action:@selector(doneButtonClicked:)];
        
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            self.webViewController.navigationItem.leftBarButtonItems = @[doneButton, self.userAgentButton];
        else
            self.webViewController.navigationItem.rightBarButtonItems = @[doneButton, self.userAgentButton];
    }
    return self;
}

- (UIBarButtonItem *)userAgentButton
{
    if (!_userAgentButton) {
        _userAgentButton = [[UIBarButtonItem alloc]
                            initWithTitle:[HSUCommonTools isDesktopUserAgent] ? _("Mobile Mode") : _("Desktop Mode")
                            style:UIBarButtonItemStylePlain
                            target:self
                            action:@selector(switchUserAgent)];
        
    }
    return _userAgentButton;
}

- (void)switchUserAgent
{
    if ([HSUCommonTools isDesktopUserAgent]) {
        [HSUCommonTools resetUserAgent];
    } else {
        [HSUCommonTools switchToDesktopUserAgent];
    }
    self.userAgentButton.title = [HSUCommonTools isDesktopUserAgent] ? _("Mobile Mode") : _("Desktop Mode");
    [self.webViewController.webView reload];
}

@end
