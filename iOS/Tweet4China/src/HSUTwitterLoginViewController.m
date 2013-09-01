//
//  HSUTwitterLoginViewController.m
//  Tweet4China
//
//  Created by Jason Hsu on 13-8-30.
//  Copyright (c) 2013年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUTwitterLoginViewController.h"

@interface HSUTwitterLoginViewController () <UIWebViewDelegate>

@property (nonatomic, weak) UIWebView *webView;
@property (nonatomic, weak) UIActivityIndicatorView *spinner;

@end

@implementation HSUTwitterLoginViewController

- (void)viewDidLoad
{
    UIWebView *webView = [[UIWebView alloc] init];
    [self.view addSubview:webView];
    self.webView = webView;
    webView.delegate = self;
    
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] init];
    [self.view addSubview:spinner];
    self.spinner = spinner;
    self.spinner.hidesWhenStopped = YES;
    
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    self.webView.frame = self.view.bounds;
    self.spinner.center = self.view.boundsCenter;
    
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:HSUTwitterLoginUrl]]];
    
    [super viewDidAppear:animated];
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    [self.spinner startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self.spinner stopAnimating];
}

@end
