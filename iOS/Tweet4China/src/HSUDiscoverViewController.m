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
#import "HSUWebBrowserFavoritesDataSource.h"

@interface HSUURLField : UITextField

@property (nonatomic, copy) NSString *urlString;

@end

@implementation HSUURLField

- (void)setText:(NSString *)text
{
    self.urlString = text;
    if ([text hasPrefix:@"http://"]) {
        text = [text substringFromIndex:@"http://".length];
    } else if ([text hasPrefix:@"https://"]) {
        text = [text substringFromIndex:@"https://".length];
    }
    if ([text hasSuffix:@"/"]) {
        text = [text substringToIndex:text.length-1];
    }
    [super setText:text];
}

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

@interface HSUDiscoverViewController () <UITextFieldDelegate, UIWebViewDelegate, UIScrollViewDelegate, NJKWebViewProgressDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, weak) UIView *tabBarBackground;
@property (nonatomic, strong) NSURL *currentURL;
@property (nonatomic, strong) NJKWebViewProgress *progressHandler;
@property (nonatomic, weak) UIView *urlTextFieldBackgrondView;
@property (nonatomic, weak) UIView *progressView;

@property (nonatomic, copy) NSString *videoUrl;
@property (nonatomic, strong) MPMoviePlayerController *moviePlayer;
@property (nonatomic, weak) UIButton *overlayButton;
@property (nonatomic, weak) UIView *sb;

@property (nonatomic, strong) UIBarButtonItem *stopBarItem;
@property (nonatomic, strong) UIBarButtonItem *reloadBarItem;

@property (nonatomic, weak) UITableView *favoritesView;
@property (nonatomic, strong) HSUWebBrowserFavoritesDataSource *favoritesDataSource;

@end

@implementation HSUDiscoverViewController

- (void)viewDidLoad
{
    self.progressHandler = [[NJKWebViewProgress alloc] init];
    self.progressHandler.webViewProxyDelegate = self;
    self.progressHandler.progressDelegate = self;
    
    if (!self.webView) {
        UIWebView *webView = [[UIWebView alloc] init];
        self.webView = webView;
        webView.scalesPageToFit = YES;
        webView.allowsInlineMediaPlayback = YES;
        webView.backgroundColor = bw(240);
        webView.frame = self.view.bounds;
    }
    
    UISwipeGestureRecognizer *gesture = [[UISwipeGestureRecognizer alloc]
                                         initWithTarget:self
                                         action:@selector(swipToLeft:)];
    gesture.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:gesture];
    
    self.hideRightButtons = YES;
    self.useRefreshControl = NO;
    self.useDefaultStatusView = YES;
    self.hideBackButton = YES;
    self.hideLeftButtons = YES;
    
    [super viewDidLoad];
    
    [self.tableView removeFromSuperview];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.view addSubview:self.webView];
    if (self.startUrl) {
        [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.startUrl]]];
    }
    
    if (!self.sb) {
        UIView *sb = [[UIView alloc] initWithFrame:ccr(0, -20, self.view.width, 20)];
        self.sb = sb;
        sb.backgroundColor = bw(245);
        [self.navigationController.navigationBar addSubview:sb];
    }
    
    if (!self.urlTextField) {
        UITextField *urlTextField = [[HSUURLField alloc] init];
        [self.navigationController.navigationBar addSubview:urlTextField];
        self.urlTextField = urlTextField;
        urlTextField.keyboardType = UIKeyboardTypeURL;
        urlTextField.returnKeyType = UIReturnKeyGo;
        urlTextField.autocorrectionType = UITextAutocorrectionTypeNo;
        urlTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        urlTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
        urlTextField.placeholder = _(@"Enter URL");
        urlTextField.backgroundColor = bw(240);
        urlTextField.layer.sublayerTransform = CATransform3DMakeTranslation(5, 0, 0);
        urlTextField.layer.cornerRadius = 5;
        
        if (Sys_Ver < 7) {
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
        }
    }
    
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    if (!self.urlTextField.hasText) {
        self.urlTextField.text = self.webView.request.URL.absoluteString;
        [self.urlTextField setNeedsDisplay];
    }
    
    self.urlTextField.delegate = self;
    
    [self.view addSubview:self.webView];
    self.webView.delegate = self.progressHandler;
    self.webView.scrollView.delegate = self;
    if (Sys_Ver >= 7) {
        self.webView.scrollView.contentInset = edi(self.navigationController.navigationBar.height+20, 0, self.tabBarController.tabBar.height, 0);
    }
    
    [self resetStatus];
    
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.sb removeFromSuperview];
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    HSUDiscoverViewController *lastPage = (HSUDiscoverViewController *)viewController;
    lastPage.webView = self.webView;
    lastPage.urlTextField = self.urlTextField;
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [self.webView goBack];
}

- (void)viewDidLayoutSubviews
{
    self.webView.frame = ccr(0, 0, self.view.width, self.view.height);
    
    // urltextfield frame
    [self setURLTextFieldWidth];
    if (Sys_Ver < 7) {
        self.urlTextField.height = self.navigationController.navigationBar.height-20;
        self.urlTextField.top = 10;
    }
    self.urlTextFieldBackgrondView.frame = self.urlTextField.frame;
    self.progressView.height = self.urlTextField.height;
    self.progressView.leftTop = self.urlTextField.leftTop;
    
    [super viewDidLayoutSubviews];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    UIButton *overlayButton = [[UIButton alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:overlayButton];
    self.overlayButton = overlayButton;
    [overlayButton setTapTarget:self action:@selector(overlayButtonTouched)];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
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
    
    [self resetStatus];
    
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    [self resetStatus];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self resetStatus];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [((HSUNavigationController *)self.navigationController) updateProgress:0];
    [UIView animateWithDuration:.27 animations:^{
        self.progressView.width = 0;
    }];
    
    [self resetStatus];
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
    
    [self resetStatus];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    // hide bars
    if (Sys_Ver >= 7) {
        CGFloat statusHeight = 20;
        CGFloat pulledDown = scrollView.contentInset.top + scrollView.contentOffset.y;
        if (pulledDown > 0) { // push up
            self.navigationController.navigationBar.top = statusHeight - pulledDown;
            self.tabBarController.tabBar.bottom = self.view.height + pulledDown;
            
            self.sb.top = pulledDown - statusHeight;
            [self.navigationController.navigationBar bringSubviewToFront:self.sb];
        } else { // pull down
            self.navigationController.navigationBar.top = statusHeight;
            self.tabBarController.tabBar.bottom = self.view.height;
            
            self.sb.top = -statusHeight;
            [self.navigationController.navigationBar bringSubviewToFront:self.sb];
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
        [self.urlTextField setNeedsDisplay];
    }
}

- (void)addPreviewPageIfCanGoBack
{
    self.webView.hidden = NO;
    self.favoritesView.hidden = YES;
    if (self.webView.canGoBack && self.navigationController.viewControllers.count == 1) {
        self.navigationController.delegate = self;
        HSUDiscoverViewController *prevPage = [[HSUDiscoverViewController alloc] init];
        self.navigationController.viewControllers = @[prevPage, self];
        
        NSArray *subviews = self.navigationController.navigationBar.subviews;
        for (UIView *subview in subviews) { // hide back bar button and keep back gesture enabled
            if ([[[subview class] description] isEqualToString:@"_UINavigationBarBackIndicatorView"] ||
                [[[subview class] description] isEqualToString:@"UINavigationItemView"] ||
                [[[subview class] description] isEqualToString:@"UINavigationItemButtonView"]) {
                
                subview.hidden = YES;
            }
        }
    } else if (!self.webView.request && !self.urlTextField.hasText) {
        self.webView.hidden = YES;
        // create favorites view
        if (!self.favoritesView) {
            UITableView *favoritesView = [[UITableView alloc] initWithFrame:self.webView.frame];
            self.favoritesView = favoritesView;
            favoritesView.contentInset = self.webView.scrollView.contentInset;
            [self.view addSubview:favoritesView];
            favoritesView.delegate = self;
            favoritesView.backgroundColor = kWhiteColor;
            self.favoritesDataSource = [[HSUWebBrowserFavoritesDataSource alloc] init];
            favoritesView.dataSource = self.favoritesDataSource;
        }
        self.favoritesView.hidden = NO;
    }
}

- (void)addBarButtonsIfNeed
{
    if (self.webView.isLoading) {
        if (!self.stopBarItem) {
            self.stopBarItem = [[UIBarButtonItem alloc]
                                initWithBarButtonSystemItem:UIBarButtonSystemItemStop
                                target:self.webView
                                action:@selector(stopLoading)];
        }
        self.navigationItem.rightBarButtonItem = self.stopBarItem;
    } else if (self.webView.request) {
        if (!self.reloadBarItem) {
            self.reloadBarItem = [[UIBarButtonItem alloc]
                                  initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                  target:self.webView
                                  action:@selector(reload)];
        }
        self.navigationItem.rightBarButtonItem = self.reloadBarItem;
    } else {
        self.navigationItem.rightBarButtonItem = nil;
    }
}

- (void)setURLTextFieldWidth
{
    CGFloat urlTextFieldWidth = self.view.width - 40;
    if (self.navigationItem.rightBarButtonItem) {
        urlTextFieldWidth = self.view.width - 70;
    }
    
    if (self.urlTextField.width &&
        self.urlTextField.width != urlTextFieldWidth) {
        [UIView animateWithDuration:.2 animations:^{
            self.urlTextField.frame = ccr(20, 7, urlTextFieldWidth, self.navigationController.navigationBar.height-14);
        }];
    } else {
        self.urlTextField.frame = ccr(20, 7, urlTextFieldWidth, self.navigationController.navigationBar.height-14);
    }
}

- (void)resetStatus
{
    if (!self.urlTextField.isEditing && self.webView.request.URL.absoluteString.length) {
        self.urlTextField.text = self.webView.request.URL.absoluteString;
    }
    [self addPreviewPageIfCanGoBack];
    [self addBarButtonsIfNeed];
    [self setURLTextFieldWidth];
}

- (void)swipToLeft:(UIGestureRecognizer *)gesture
{
    CGPoint point = [gesture locationInView:self.view];
    if (point.x > self.view.width - 20) {
        if (self.webView.canGoForward) {
            [self.webView goForward];
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *favorite = self.favoritesDataSource.favorites[indexPath.row];
    NSString *urlStr = favorite[@"url"];
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlStr]]];
    self.urlTextField.text = urlStr;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44;
}

@end
