//
//  HSUDiscoverViewController.m
//  Tweet4China
//
//  Created by Jason Hsu on 2/28/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUDiscoverViewController.h"
#import <NJKWebViewProgress/NJKWebViewProgress.h>
#import "HSUComposeViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <AFNetworking/AFNetworkActivityIndicatorManager.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AFNetworking/AFNetworking.h>
#import <NSString-MD5/NSString+MD5.h>
#import <FHSTwitterEngine/NSString+URLEncoding.h>

#define StartURL @"https://www.google.com/ncr"

@interface HSUURLField : UITextField

@end

@implementation HSUURLField

// placeholder position
- (CGRect)textRectForBounds:(CGRect)bounds
{
    if (Sys_Ver >= 7) {
        return CGRectInset(bounds, 4, 4);
    }
    return CGRectInset(bounds, 2, 2);
}

// text position
- (CGRect)editingRectForBounds:(CGRect)bounds
{
    return [self textRectForBounds:bounds];
}

@end

@interface HSUDiscoverViewController () <UITextFieldDelegate, UIWebViewDelegate, UIScrollViewDelegate, NJKWebViewProgressDelegate>

@property (nonatomic, weak) UIWebView *webView;
@property (nonatomic, weak) UITextField *urlTextField;
@property (nonatomic, weak) UIView *tabBarBackground;
@property (nonatomic, strong) NSURL *currentURL;
@property (nonatomic, strong) NJKWebViewProgress *progressHandler;
@property (nonatomic, weak) UIView *urlTextFieldBackgrondView;
@property (nonatomic, weak) UIView *progressView;

@property (nonatomic, copy) NSString *videoUrl;
@property (nonatomic, strong) MPMoviePlayerController *moviePlayer;
@property (nonatomic, weak) UIButton *overlayButton;

@end

@implementation HSUDiscoverViewController

- (void)viewDidLoad
{
    self.progressHandler = [[NJKWebViewProgress alloc] init];
    self.progressHandler.webViewProxyDelegate = self;
    self.progressHandler.progressDelegate = self;
    
    if (!self.startUrl) {
        self.startUrl = [[NSUserDefaults standardUserDefaults] objectForKey:kDiscoverHomePage] ?: StartURL;
    }
    
    UIWebView *webView = [[UIWebView alloc] init];
    [self.view addSubview:webView];
    self.webView = webView;
    webView.scrollView.delegate = self;
    webView.scalesPageToFit = YES;
    webView.allowsInlineMediaPlayback = YES;
    webView.backgroundColor = kWhiteColor;
    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.startUrl]]];
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
    UITextField *urlTextField = [[HSUURLField alloc] init];
    [self.navigationController.navigationBar addSubview:urlTextField];
    self.urlTextField = urlTextField;
    urlTextField.delegate = self;
    urlTextField.keyboardType = UIKeyboardTypeURL;
    urlTextField.returnKeyType = UIReturnKeyGo;
    urlTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    urlTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    urlTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    urlTextField.placeholder = _(@"Enter URL");
    urlTextField.backgroundColor = bw(245);
    urlTextField.layer.sublayerTransform = CATransform3DMakeTranslation(5, 0, 0);
    
    if (Sys_Ver >= 7) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                                  initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                  target:self
                                                  action:@selector(_menuButtonTouched)];
    } else {
        urlTextField.backgroundColor = kClearColor;
        UIView *bg = [[UIView alloc] init];
        self.urlTextFieldBackgrondView = bg;
        bg.backgroundColor = [UIColor whiteColor];
        bg.layer.cornerRadius = 3;
        [self.navigationController.navigationBar insertSubview:bg belowSubview:urlTextField];
        
        UIView *progressView = [[UIView alloc] init];
        self.progressView = progressView;
        [self.navigationController.navigationBar insertSubview:progressView belowSubview:urlTextField];
        progressView.backgroundColor = rgba(74, 156, 214, .3);
        
        UIButton *menuButton = [[UIButton alloc] init];
        [menuButton setImage:[UIImage imageNamed:@"ic_title_action"] forState:UIControlStateNormal];
        [menuButton addTarget:self action:@selector(_menuButtonTouched) forControlEvents:UIControlEventTouchUpInside];
        [menuButton sizeToFit];
        menuButton.width *= 1.5;
        UIBarButtonItem *menuBarButton = [[UIBarButtonItem alloc] initWithCustomView:menuButton];
        self.navigationItem.rightBarButtonItem = menuBarButton;
    }
    
    self.navigationItem.leftBarButtonItem = nil;
    
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    if (!self.urlTextField.hasText) {
        self.urlTextField.text = self.startUrl;
    }
    
    [super viewDidAppear:animated];
    
    [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(parseYoutube) userInfo:nil repeats:YES];
}

- (void)viewDidLayoutSubviews
{
    self.webView.frame = ccr(0, 0, self.view.width, self.view.height);
    
    self.urlTextField.frame = ccr(10, 7, self.view.width-60, self.navigationController.navigationBar.height-14);
    if (Sys_Ver < 7) {
        self.urlTextField.height = self.navigationController.navigationBar.height-20;
        self.urlTextField.top = 10;
    }
    self.urlTextFieldBackgrondView.frame = self.urlTextField.frame;
    self.progressView.height = self.urlTextField.height;
    self.progressView.leftTop = self.urlTextField.leftTop;
    self.urlTextField.layer.cornerRadius = 5;
    
    [super viewDidLayoutSubviews];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    UIButton *overlayButton = [[UIButton alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:overlayButton];
    self.overlayButton = overlayButton;
    [overlayButton setTapTarget:self action:@selector(overlayButtonTouched)];
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
    [self.overlayButton removeFromSuperview];
    
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
    if (!self.urlTextField.isEditing) {
        self.urlTextField.text = urlString;
    }
}

- (void)webViewProgress:(NJKWebViewProgress *)webViewProgress updateProgress:(float)progress
{
    if (progress == 0.0) {
        [[AFNetworkActivityIndicatorManager sharedManager] incrementActivityCount];
    } else if (progress == 1.0) {
        [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
    }
    
    [((HSUNavigationController *)self.navigationController) updateProgress:progress];
    [UIView animateWithDuration:.27 animations:^{
        self.progressView.width = progress*self.urlTextField.width;
    }];
    self.urlTextField.backgroundColor = kClearColor;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (!self.urlTextField.hasText && !self.urlTextField.isEditing && self.currentURL) {
        self.urlTextField.text = self.currentURL.absoluteString;
    }
    
    // hide bars
    if (Sys_Ver >= 7) {
        CGFloat statusHeight = 20;
        CGFloat pulledDown = scrollView.contentInset.top + scrollView.contentOffset.y;
        if (pulledDown > 0) { // push up
            self.navigationController.navigationBar.top = statusHeight - pulledDown;
            self.tabBarController.tabBar.bottom = self.view.height + pulledDown;
        } else { // pull down
            self.navigationController.navigationBar.top = statusHeight;
            self.tabBarController.tabBar.bottom = self.view.height;
        }
    }
}

- (void)_menuButtonTouched
{
    RIButtonItem *cancelItem = [RIButtonItem itemWithLabel:_(@"Cancel")];
    RIButtonItem *refreshItem = [RIButtonItem itemWithLabel:_(@"Refresh")];
    RIButtonItem *stopItem = [RIButtonItem itemWithLabel:_(@"Stop")];
    RIButtonItem *backwardItem = [RIButtonItem itemWithLabel:_(@"Backward")];
    RIButtonItem *forwardItem = [RIButtonItem itemWithLabel:_(@"Forward")];
    RIButtonItem *shareItem = [RIButtonItem itemWithLabel:_(@"Share Link")];
    RIButtonItem *copyItem = [RIButtonItem itemWithLabel:_(@"Copy URL")];
    RIButtonItem *setHomeItem = [RIButtonItem itemWithLabel:_(@"Set as Home")];
    RIButtonItem *openHomeItem = [RIButtonItem itemWithLabel:_(@"Open Home")];
    UIActionSheet *menu = [[UIActionSheet alloc]
                           initWithTitle:nil
                           cancelButtonItem:cancelItem
                           destructiveButtonItem:nil
                           otherButtonItems:
                           stopItem,
                           refreshItem,
                           backwardItem,
                           forwardItem,
                           shareItem,
                           copyItem,
                           setHomeItem,
                           openHomeItem,
                           nil];
    [menu showInView:self.view.window];
    
    refreshItem.action = ^{
        [self.webView reload];
    };
    
    stopItem.action = ^{
        [self.webView stopLoading];
    };
    
    backwardItem.action = ^{
        [self.webView goBack];
    };
    
    forwardItem.action = ^{
        [self.webView goForward];
    };
    
    shareItem.action = ^{
        HSUComposeViewController *composeVC = [[HSUComposeViewController alloc] init];
        composeVC.defaultText = S(@" %@", self.urlTextField.text);
        UINavigationController *nav = [[HSUNavigationController alloc] initWithRootViewController:composeVC];
        [self presentViewController:nav animated:YES completion:nil];
    };
    
    copyItem.action = ^{
        [UIPasteboard generalPasteboard].string = self.urlTextField.text;
    };
    
    setHomeItem.action = ^{
        [[NSUserDefaults standardUserDefaults] setObject:self.urlTextField.text forKey:kDiscoverHomePage];
        [[NSUserDefaults standardUserDefaults] synchronize];
    };
    
    openHomeItem.action = ^{
        [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:kDiscoverHomePage]]];
    };
}

- (void)parseYoutube
{
    NSString *js = @"document.getElementsByTagName('video')[0].src";
    NSString *videoUrl = [self.webView stringByEvaluatingJavaScriptFromString:js];
    if ([self.videoUrl isEqualToString:videoUrl]) {
        return;
    }
    if ([NSURL URLWithString:videoUrl]) {
        if ([videoUrl rangeOfString:@"googlevideo.com"].location != NSNotFound) {
            self.videoUrl = videoUrl;
            
            [self playVideo];
        }
    }
}

- (void)playVideo
{
    return;
    MPMoviePlayerController *moviePlayer = [[MPMoviePlayerController alloc] init];
    self.moviePlayer = moviePlayer;
    [moviePlayer setContentURL:[NSURL URLWithString:self.videoUrl]];
    [self.view addSubview:moviePlayer.view];
    moviePlayer.fullscreen = YES;
    moviePlayer.shouldAutoplay = YES;
    [moviePlayer play];
}

- (void)overlayButtonTouched
{
    [self.urlTextField resignFirstResponder];
    [self.overlayButton removeFromSuperview];
    if (!self.urlTextField.hasText) {
        self.urlTextField.text = self.webView.request.URL.absoluteString;
    }
}

@end
