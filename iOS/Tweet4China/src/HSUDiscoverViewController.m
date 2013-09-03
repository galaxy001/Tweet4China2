//
//  HSUDiscoverViewController.m
//  Tweet4China
//
//  Created by Jason Hsu on 2/28/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUDiscoverViewController.h"

#define StartURL @"http://www.google.com/m"

@interface HSUDiscoverViewController () <UITextFieldDelegate, UIWebViewDelegate, UIScrollViewDelegate>

@property (nonatomic, weak) UIWebView *webView;
@property (nonatomic, weak) UITextField *urlTextField;


@end

@implementation HSUDiscoverViewController

- (void)viewDidLoad
{
    UIWebView *webView = [[UIWebView alloc] init];
    [self.view addSubview:webView];
    self.webView = webView;
    webView.delegate = self;
    webView.scrollView.delegate = self;
    webView.scalesPageToFit = YES;
    webView.allowsInlineMediaPlayback = YES;
    webView.backgroundColor = kWhiteColor;
    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:StartURL]]];
    
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
    urlTextField.placeholder = @"Type URL";
    urlTextField.backgroundColor = bw(245);
    urlTextField.layer.sublayerTransform = CATransform3DMakeTranslation(5, 0, 0);
    urlTextField.text = StartURL;
    
    [super viewWillAppear:animated];
}

- (void)viewDidLayoutSubviews
{
    self.webView.frame = ccr(0, 0, self.view.width, self.view.height);
    self.webView.scrollView.contentSize = self.webView.size;
    
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

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    NSString *urlString = webView.request.URL.absoluteString;
    if ([urlString hasPrefix:@"http://"]) {
        urlString = [urlString substringFromIndex:7];
    }
    self.urlTextField.text = urlString;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.urlTextField resignFirstResponder];
    if (!self.urlTextField.isEditing) {
        self.urlTextField.text = self.webView.request.URL.absoluteString;
    }
}

@end
