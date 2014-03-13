//
//  FBCViewController.m
//  FB4China
//
//  Created by Jason Hsu on 14-1-18.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "FBCViewController.h"
#import "FBCTabController.h"

@interface FBCViewController () <UIWebViewDelegate>

//@property (nonatomic, weak) UIView *webHeadBack;
//@property (nonatomic, weak) UIView *statusBack;

@end

@implementation FBCViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadWebView:) name:@"facebook_login_success" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didLogout) name:@"Logout" object:nil];
    
    self.navigationItem.title = self.title;
    
//    UIView *webHeadBack = [[UIView alloc] initWithFrame:self.view.bounds];
//    [self.view addSubview:webHeadBack];
//    webHeadBack.backgroundColor = [UIColor blackColor];
//    self.webHeadBack = webHeadBack;
    
    self.webView = [[UIWebView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [self.view addSubview:self.webView];
    self.webView.delegate = self;
    [self.webView scalesPageToFit];
    [self.webView loadHTMLString:@"<html><body></body></html>" baseURL:nil];
    
//    UIView *statusBack = [[UIView alloc] initWithFrame:self.view.bounds];
//    [self.view addSubview:statusBack];
//    statusBack.backgroundColor = [UIColor blackColor];
//    self.statusBack = statusBack;
    
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [self.view addSubview:spinner];
    self.spinner = spinner;
    spinner.center = self.view.center;
    
    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(detectURL) userInfo:nil repeats:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.tabBarController.delegate = self;
    if ([self.address isEqualToString:@"https://m.facebook.com/profile.php"]) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Logout"
                                                                                 style:UIBarButtonItemStylePlain
                                                                                target:self action:@selector(logout)];
    }
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                                                                           target:self.webView
                                                                                           action:@selector(reload)];
}

- (void)reloadWebView:(NSNotification *)notification
{
    if (notification.object != self) {
        [self.webView reload];
    }
}

- (void)detectURL
{
    if (self.webView.canGoBack && !self.navigationItem.leftBarButtonItem) {
        if (self.rootAddress && ![self.currentAddress hasPrefix:self.address]) {
            self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
                                                     initWithImage:[UIImage imageNamed:@"icn_nav_back"]
                                                     style:UIBarButtonItemStylePlain
                                                     target:self
                                                     action:@selector(goBack)];
        }
    } else {
        self.navigationItem.title = self.title;
    }
    self.navigationItem.title = [self.webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    [self hideHTMLTags];
//    NSLog(@"%@", self.currentAddress);
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    self.webView.frame = self.view.bounds;
//    self.webHeadBack.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height/2);
//    self.statusBack.frame = CGRectMake(0, 0, self.view.bounds.size.width, 20);
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)goBack
{
    [self.webView goBack];
    self.navigationItem.leftBarButtonItem = nil;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
//    NSLog(@"did start %@", webView.request.URL);
    if (!self.isLogin && [webView.request.URL.absoluteString hasPrefix:self.address]) {
        self.login = YES;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"facebook_login_success" object:self];
    }
    [self removeHTMLTags];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
//    NSLog(@"should start %d %@", navigationType, request.URL);
    if ([webView.request.URL.absoluteString isEqualToString:@"about:blank"]) {
        [self.spinner startAnimating];
    }
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [self removeHTMLTags];
    return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
//    NSLog(@"finish %@", webView.request.URL);
    NSString *url = webView.request.URL.absoluteString;
    if ([url isEqualToString:@"about:blank"]) {
        [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.address]]];
    } else if (self.spinner.isAnimating) {
        [self.spinner stopAnimating];
    }

    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    if ([url hasPrefix:self.address] &&
        url.length > self.address.length &&
        ![url hasPrefix:@"https://m.facebook.com/login"] &&
        self.rootAddress == nil) {
        
        self.rootAddress = url;
    }
    [self removeHTMLTags];
}

- (void)removeHTMLTags
{
    [self.webView stringByEvaluatingJavaScriptFromString:
     @"document.getElementById('header').remove();"
     @"document.getElementById('footer').remove();"
     @"document.getElementsByClassName('appBanner')[0].remove();"
     @"document.getElementsByClassName('other-links')[0].remove();"
     @"document.getElementsByClassName('storyAggregation')[0].remove();"];
}

- (void)hideHTMLTags
{
    [self.webView stringByEvaluatingJavaScriptFromString:
     @"var styleElement = document.createElement('style');"
     @"styleElement.type = 'text/css';"
     @"styleElement.appendChild(document.createTextNode('#header, .appBanner, .other-links, #footer, .storyAggregation {display:none;}'));"
     @"document.getElementsByTagName('head')[0].appendChild(styleElement);"];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (BOOL)prefersStatusBarHidden
{
    BOOL hidden = UIInterfaceOrientationIsLandscape(self.interfaceOrientation);
    self.navigationController.navigationBar.hidden = hidden;
    self.tabBarController.tabBar.hidden = hidden;
    self.webView.scrollView.contentInset = UIEdgeInsetsMake(hidden?0:64, 0, hidden?0:44, 0);
//    self.statusBack.hidden = hidden;
    return hidden;
}

- (NSString *)currentAddress
{
    return [self.webView stringByEvaluatingJavaScriptFromString:@"window.location.href"];
}

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController
{
    if (tabBarController.selectedIndex == 0) {
        return self.isLogin;
    }
    
    return YES;
}

- (void)reloadStartPage
{
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.address]]];
}

- (void)logout
{
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie *each in cookieStorage.cookies) {
        [cookieStorage deleteCookie:each];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Logout" object:nil];
}

- (void)didLogout
{
    [self.webView reload];
}

@end
