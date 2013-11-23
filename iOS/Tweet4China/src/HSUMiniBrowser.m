//
//  HSUMiniBrowser.m
//  Tweet4China
//
//  Created by Jason Hsu on 4/29/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUMiniBrowser.h"
#import "HSUStatusView.h"
#import "HSUStatusActionView.h"
#import "HSUStatusViewController.h"

@interface HSUMiniBrowser () <UIWebViewDelegate, UIScrollViewDelegate>

@property (nonatomic, strong) HSUTableCellData *cellData;
@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) UIWebView *webview;

@end

@implementation HSUMiniBrowser

- (id)initWithURL:(NSURL *)url cellData:(HSUTableCellData *)cellData
{
    self = [super init];
    if (self) {
        self.url = url;
        self.cellData = cellData;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = @"Loading...";
    self.view.backgroundColor = bw(0xd0);
    
#if __IPHONE_OS_VERSION_MIN_REQUIRED < 70000
    NSDictionary *attributes = @{UITextAttributeTextColor: bw(50),
                                 UITextAttributeTextShadowColor: kWhiteColor,
                                 UITextAttributeTextShadowOffset: [NSValue valueWithCGSize:ccs(0, 1)]};
    self.navigationController.navigationBar.titleTextAttributes = attributes;
#endif
    
    // subviews
    UIWebView *webview = [[UIWebView alloc] init];
    [self.view addSubview:webview];
    self.webview = webview;
    webview.delegate = self;
    webview.scrollView.delegate = self;
    webview.scalesPageToFit = YES;
    webview.allowsInlineMediaPlayback = YES;
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:self.url];
    [webview loadRequest:request];
    UIColor *webviewBGC = [UIColor clearColor];
    webview.backgroundColor = webviewBGC;
    UIView *diandian = [[UIView alloc] initWithFrame:self.view.bounds];
    diandian.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg_swipe_tile"]];
    [self.view insertSubview:diandian belowSubview:webview];
    diandian.alpha = 0.2;
    
    UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [closeButton setImage:[UIImage imageNamed:@"icn_nav_bar_light_close"] forState:UIControlStateNormal];
    [closeButton sizeToFit];
    closeButton.width *= 1.2;
    [closeButton setTapTarget:self action:@selector(_closeButtonTouched)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:closeButton];
    
    UIButton *actionsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [actionsButton setImage:[UIImage imageNamed:@"icn_nav_bar_light_actions"] forState:UIControlStateNormal];
    [actionsButton sizeToFit];
    actionsButton.width *= 1.6;
    [actionsButton setTapTarget:self action:@selector(_actionsButtonTouched)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:actionsButton];
}

- (void)viewDidLayoutSubviews
{
    if (RUNNING_ON_IOS_7) {
        self.webview.frame = ccr(0, 54, self.width, self.height-54);
    } else {
        self.webview.frame = ccr(0, 0, self.width, self.height);
    }
}

- (BOOL)shouldAutorotate
{
    return YES;
}

#pragma mark - webview delegate
- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    self.navigationItem.title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
}

#pragma mark - actions
- (void)_closeButtonTouched
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)_actionsButtonTouched
{
    UIEvent *event = self.cellData.renderData[@"more"];
    [event performSelector:@selector(fire:) withObject:nil];
}

@end
