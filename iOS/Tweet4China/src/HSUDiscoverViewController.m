//
//  HSUDiscoverViewController.m
//  Tweet4China
//
//  Created by Jason Hsu on 2/28/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUDiscoverViewController.h"
#import "NJKWebViewProgress.h"

#define StartURL @"http://m.facebook.com"

@interface HSUDiscoverViewController () <UITextFieldDelegate, UIWebViewDelegate, UIScrollViewDelegate, NJKWebViewProgressDelegate>

@property (nonatomic, weak) UIWebView *webView;
@property (nonatomic, weak) UITextField *urlTextField;
@property (nonatomic, weak) UIView *tabBarBackground;
@property (nonatomic, strong) NSURL *currentURL;
@property (nonatomic, strong) NJKWebViewProgress *progressHandler;
@property (nonatomic, weak) UIProgressView *progressBar;

@end

@implementation HSUDiscoverViewController

- (void)viewDidLoad
{
    self.progressHandler = [[NJKWebViewProgress alloc] init];
    self.progressHandler.webViewProxyDelegate = self;
    self.progressHandler.progressDelegate = self;
    
    UIWebView *webView = [[UIWebView alloc] init];
    [self.view addSubview:webView];
    self.webView = webView;
    webView.scrollView.delegate = self;
    webView.scalesPageToFit = YES;
    webView.allowsInlineMediaPlayback = YES;
    webView.backgroundColor = kWhiteColor;
    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:StartURL]]];
    webView.frame = self.view.bounds;
    webView.delegate = self.progressHandler;
    
    self.hideRightButtons = YES;
    self.useRefreshControl = NO;
    self.useDefaultStatusView = YES;
    
    [super viewDidLoad];
    
    [self.tableView removeFromSuperview];
}

- (void)viewWillAppear:(BOOL)animated
{
    UITextField *urlTextField = [[UITextField alloc] init];
    [self.navigationController.navigationBar addSubview:urlTextField];
    self.urlTextField = urlTextField;
    urlTextField.delegate = self;
    urlTextField.keyboardType = UIKeyboardTypeURL;
    urlTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    urlTextField.placeholder = @"Enter URL";
    urlTextField.backgroundColor = bw(245);
    urlTextField.layer.sublayerTransform = CATransform3DMakeTranslation(5, 0, 0);
    
    UIProgressView *progressBar = [[UIProgressView alloc] init];
    [self.navigationController.navigationBar addSubview:progressBar];
    progressBar.top = self.navigationController.navigationBar.height - progressBar.height;
    progressBar.width = self.navigationController.navigationBar.width;
    self.progressBar = progressBar;
    
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    if (!self.urlTextField.hasText) {
        self.urlTextField.text = StartURL;
    }
    
    [super viewDidAppear:animated];
}

- (void)viewDidLayoutSubviews
{
    self.webView.frame = ccr(0, 0, self.view.width, self.view.height);
    
    self.urlTextField.frame = ccr(20, 7, self.view.width-45, self.navigationController.navigationBar.height-14);
    self.urlTextField.layer.cornerRadius = 5;
    
    [super viewDidLayoutSubviews];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    textField.backgroundColor = bw(225);
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    textField.backgroundColor = bw(245);
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    NSString *url = self.urlTextField.text;
    if (![url hasPrefix:@"http"]) {
        url = [@"http://" stringByAppendingString:url];
    }
    [self.webView stopLoading];
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
    [textField resignFirstResponder];
    
    return NO;
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if ([request.URL.absoluteString hasPrefix:@"webviewprogressproxy"]) {
        return YES;
    }
    self.currentURL = request.URL;
    return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    NSString *urlString = webView.request.URL.absoluteString;
    if ([urlString hasPrefix:@"http://"]) {
        urlString = [urlString substringFromIndex:7];
    }
    self.urlTextField.text = urlString;
}

- (void)webViewProgress:(NJKWebViewProgress *)webViewProgress updateProgress:(float)progress
{
    if (progress == 0.0) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        self.progressBar.progress = 0;
        [UIView animateWithDuration:0.27 animations:^{
            self.progressBar.alpha = 1.0;
        }];
    } else if (progress == 1.0) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        [UIView animateWithDuration:0.27 delay:progress - self.progressBar.progress options:0 animations:^{
            self.progressBar.alpha = 0.0;
        } completion:nil];
    }
    
    [self.progressBar setProgress:progress animated:NO];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.urlTextField resignFirstResponder];
    if (!self.urlTextField.isEditing && self.currentURL) {
        self.urlTextField.text = self.currentURL.absoluteString;
    }
}

@end
