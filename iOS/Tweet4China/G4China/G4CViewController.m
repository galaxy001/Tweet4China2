//
//  G4CViewController.m
//  G4China
//
//  Created by Jason Hsu on 14-1-31.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "G4CViewController.h"
#import "UIView+Additions.h"
#import "NSString+URLEncoding.h"

#define TextSearchFormat @"http://www.google.com/search?q=%@"
#define ImageSearchFormat @"http://www.google.com/search?q=%@&tbm=isch"

@interface G4CViewController () <UISearchBarDelegate, UIWebViewDelegate>

@property (nonatomic, weak) UISearchBar *searchBar;
@property (nonatomic, weak) UIWebView *webView;

@end

@implementation G4CViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    UISearchBar *searchBar = [[UISearchBar alloc] init];
    [self.view addSubview:searchBar];
    self.searchBar = searchBar;
    searchBar.delegate = self;
    
    UIWebView *webView = [[UIWebView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [self.view addSubview:webView];
    self.webView = webView;
    webView.delegate = self;
    
    [searchBar becomeFirstResponder];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    self.searchBar.frame = ccr(0, 20, self.view.width, 44);
    self.webView.top = self.searchBar.hidden ? self.searchBar.top : self.searchBar.bottom;
    self.webView.height = self.view.height - self.webView.top;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    NSString *urlStr = [NSString stringWithFormat:TextSearchFormat, [searchBar.text URLEncodedString]];
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlStr]]];
    [searchBar resignFirstResponder];
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    if (!self.searchBar.hidden) {
        self.searchBar.hidden = YES;
        [self.view setNeedsLayout];
    }
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

@end
