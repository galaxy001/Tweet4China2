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
#import "HSUWebBrowserBookmarksDataSource.h"
#import "HSUWebBrowserTabsDataSource.h"

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
    } else if ([text isEqualToString:@"about:blank"]) {
        text = nil;
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
@property (nonatomic, strong) UIBarButtonItem *bookmarksBarItem;

@property (nonatomic, weak) UITableView *bookmarksView;
@property (nonatomic, weak) UITableView *tabsView;
@property (nonatomic, strong) HSUWebBrowserBookmarksDataSource *bookmarksDataSource;
@property (nonatomic, strong) HSUWebBrowserTabsDataSource *tabsDataSource;
@property (nonatomic, weak) UISegmentedControl *segmentedControl;
@property (nonatomic) NSUInteger tabIndex;

@end

@implementation HSUDiscoverViewController

- (void)viewDidLoad
{
    self.progressHandler = [[NJKWebViewProgress alloc] init];
    self.progressHandler.webViewProxyDelegate = self;
    self.progressHandler.progressDelegate = self;
    
    UIWebView *webView = [[UIWebView alloc] init];
    self.webView = webView;
    webView.scalesPageToFit = YES;
    webView.allowsInlineMediaPlayback = YES;
    webView.backgroundColor = bw(240);
    webView.frame = self.view.bounds;
    webView.hidden = YES;
    
    UITableView *bookmarksView = [[UITableView alloc] initWithFrame:self.webView.frame];
    self.bookmarksView = bookmarksView;
    bookmarksView.contentInset = self.webView.scrollView.contentInset;
    [self.view addSubview:bookmarksView];
    bookmarksView.delegate = self;
    bookmarksView.backgroundColor = kWhiteColor;
    self.bookmarksDataSource = [[HSUWebBrowserBookmarksDataSource alloc] init];
    bookmarksView.dataSource = self.bookmarksDataSource;
    notification_add_observer(HSUBookmarkUpdatedNotification, self.bookmarksView, @selector(reloadData));
    
    UITableView *tabsView = [[UITableView alloc] initWithFrame:self.webView.frame];
    self.tabsView = tabsView;
    tabsView.contentInset = self.webView.scrollView.contentInset;
    [self.view addSubview:tabsView];
    tabsView.delegate = self;
    tabsView.backgroundColor = kWhiteColor;
    self.tabsDataSource = [[HSUWebBrowserTabsDataSource alloc] init];
    tabsView.dataSource = self.tabsDataSource;
    tabsView.left = self.view.width;
    
    UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:@[_(@"Bookmarks"), _(@"Tabs")]];
    self.segmentedControl = segmentedControl;
    [segmentedControl setWidth:100 forSegmentAtIndex:0];
    [segmentedControl setWidth:100 forSegmentAtIndex:1];
    segmentedControl.center = ccp(self.width/2, 20 + navbar_height + 25);
    segmentedControl.selectedSegmentIndex = 0;
    [self.view addSubview:segmentedControl];
    [segmentedControl addTarget:self action:@selector(segmentChanged:) forControlEvents:UIControlEventValueChanged];
    
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
        [self showWebView];
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
        urlTextField.delegate = self;
        
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
    
    if (!self.urlTextField.hasText && self.webView.request.URL.absoluteString.length) {
        self.urlTextField.text = self.webView.request.URL.absoluteString;
        [self.urlTextField setNeedsDisplay];
    }
    
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self.view addSubview:self.webView];
    self.webView.delegate = self.progressHandler;
    self.webView.scrollView.delegate = self;
    if (Sys_Ver >= 7) {
        self.webView.scrollView.contentInset = edi(navbar_height+20, 0, tabbar_height, 0);
        self.bookmarksView.contentInset = edi(navbar_height+20+50, 0, tabbar_height, 0);
        self.tabsView.contentInset = edi(navbar_height+20+50, 0, tabbar_height, 0);
    }
    
    [self resetStatus];
    
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.sb removeFromSuperview];
}

- (void)viewDidLayoutSubviews
{
    self.webView.frame = ccr(0, 0, self.view.width, self.view.height);
    
    // urltextfield frame
    [self setURLTextFieldWidth];
    if (Sys_Ver < 7) {
        self.urlTextField.height = navbar_height-20;
        self.urlTextField.top = 10;
    }
    self.urlTextFieldBackgrondView.frame = self.urlTextField.frame;
    self.progressView.height = self.urlTextField.height;
    self.progressView.leftTop = self.urlTextField.leftTop;
    
    [super viewDidLayoutSubviews];
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if (viewController != self) {
        [navigationController pushViewController:self animated:NO];
        if (self.webView.canGoBack) {
            [self.webView goBack];
            self.bookmarksView.hidden = YES;
            self.tabsView.hidden = YES;
        } else {
            [self hideWebview];
        }
    }
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    UIButton *overlayButton = [[UIButton alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:overlayButton];
    self.overlayButton = overlayButton;
    [overlayButton setTapTarget:self action:@selector(overlayButtonTouched)];
    
    [self.webView loadHTMLString:@"<html></html>" baseURL:nil];
    self.tabIndex = self.tabsDataSource.tabs.count;
    [self showWebView];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    NSString *url = self.urlTextField.text;
    if (![url hasPrefix:@"http"]) {
        url = [@"http://" stringByAppendingString:url];
    }
    self.tabIndex = self.tabsDataSource.tabs.count;
    [self.webView stopLoading];
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
    [self showWebView];
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
    if (webView.request.URL.absoluteString.length &&
        ![webView.request.URL.absoluteString isEqualToString:@"about:blank"]) {
        
        NSString *title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
        [self.tabsDataSource addTabAtIndex:self.tabIndex title:title url:webView.request.URL.absoluteString];
        [self resetStatus];
    }
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
    if (self.webView.request.URL.absoluteString.length == 0 ||
        [self.webView.request.URL.absoluteString isEqualToString:@"about:blank"]) {
        
        progress = 0;
    }
    
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
    if (!self.urlTextField.hasText && self.webView.request.URL.absoluteString.length) {
        self.urlTextField.text = self.webView.request.URL.absoluteString;
        [self.urlTextField setNeedsDisplay];
    }
}

- (void)addPreviewPageIfCanGoBack
{
    if (self.navigationController.viewControllers.count == 1) {
        self.navigationController.delegate = self;
        UIViewController *prevPage = [[UIViewController alloc] init];
        prevPage.view.backgroundColor = kWhiteColor;
        self.navigationController.viewControllers = @[prevPage, self];
        
        NSArray *subviews = self.navigationController.navigationBar.subviews;
        for (UIView *subview in subviews) { // hide back bar button and keep back gesture enabled
            if ([[[subview class] description] isEqualToString:@"_UINavigationBarBackIndicatorView"] ||
                [[[subview class] description] isEqualToString:@"UINavigationItemView"] ||
                [[[subview class] description] isEqualToString:@"UINavigationItemButtonView"]) {
                
                subview.hidden = YES;
            }
        }
    }
}

- (void)addBarButtonsIfNeed
{
    if (!self.stopBarItem) {
        self.stopBarItem = [[UIBarButtonItem alloc]
                            initWithBarButtonSystemItem:UIBarButtonSystemItemStop
                            target:self.webView
                            action:@selector(stopLoading)];
    }
    if (!self.reloadBarItem) {
        self.reloadBarItem = [[UIBarButtonItem alloc]
                              initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                              target:self.webView
                              action:@selector(reload)];
    }
    if (!self.bookmarksBarItem) {
        self.bookmarksBarItem = [[UIBarButtonItem alloc]
                                 initWithBarButtonSystemItem:UIBarButtonSystemItemBookmarks
                                 target:self
                                 action:@selector(bookmarksButtonTouched)];
    }
    
    if (self.webView.isHidden) {
        self.navigationItem.rightBarButtonItem = nil;
        self.navigationItem.leftBarButtonItem = nil;
    } else {
        self.navigationItem.leftBarButtonItem = self.bookmarksBarItem;
        if (self.webView.isLoading) {
            self.navigationItem.rightBarButtonItem = self.stopBarItem;
        } else if (self.webView.request) {
            self.navigationItem.rightBarButtonItem = self.reloadBarItem;
        } else {
            self.navigationItem.rightBarButtonItem = nil;
        }
    }
//    
//    if (self.webView.isLoading) {
//        self.navigationItem.leftBarButtonItem = self.bookmarksBarItem;
//        self.navigationItem.rightBarButtonItem = self.stopBarItem;
//    } else if (self.webView.request) {
//        self.navigationItem.leftBarButtonItem = self.bookmarksBarItem;
//        self.navigationItem.rightBarButtonItem = self.reloadBarItem;
//    } else {
//        self.navigationItem.rightBarButtonItem = nil;
//        self.navigationItem.leftBarButtonItem = nil;
//    }
}

- (void)setURLTextFieldWidth
{
    CGFloat left = 20;
    if (self.navigationItem.leftBarButtonItem) {
        left += 40;
    }
    
    CGFloat urlTextFieldWidth = self.view.width - left - 20;
    if (self.navigationItem.rightBarButtonItem) {
        urlTextFieldWidth -= 30;
    }
    
    if (self.urlTextField.width &&
        (self.urlTextField.width != urlTextFieldWidth || self.urlTextField.left != left)) {
        [UIView animateWithDuration:.2 animations:^{
            self.urlTextField.frame = ccr(left, 7, urlTextFieldWidth, navbar_height-14);
        }];
    } else {
        self.urlTextField.frame = ccr(left, 7, urlTextFieldWidth, navbar_height-14);
    }
}

- (void)resetStatus
{
    if (!self.webView.hidden &&
        !self.urlTextField.isEditing &&
        self.webView.request.URL.absoluteString.length &&
        ![self.webView.request.URL.absoluteString isEqualToString:@"about:blank"]) {
        
        self.urlTextField.text = self.webView.request.URL.absoluteString;
    } else if (self.webView.isHidden) {
        self.urlTextField.text = nil;
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
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *urlStr;
    if (tableView == self.bookmarksView) {
        NSDictionary *bookmark = self.bookmarksDataSource.bookmarks[indexPath.row];
        urlStr = bookmark[@"url"];
        self.tabIndex = self.tabsDataSource.tabs.count;
    } else {
        if (indexPath.row < self.tabsDataSource.tabs.count) {
            NSDictionary *tab = self.tabsDataSource.tabs[indexPath.row];
            urlStr = tab[@"url"];
            self.tabIndex = indexPath.row;
        }
    }
    [self.webView loadHTMLString:@"<html></html>" baseURL:nil];
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlStr]]];
    self.urlTextField.text = urlStr;
    [self showWebView];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44;
}

- (void)bookmarksButtonTouched
{
    // todo add tab
    [self hideWebview];
    [self resetStatus];
}

- (void)segmentChanged:(UISegmentedControl *)segment
{
    if (segment.selectedSegmentIndex == 0) {
        [UIView animateWithDuration:.2 animations:^{
            self.bookmarksView.left = 0;
            self.tabsView.left = self.view.width;
        }];
    } else if (segment.selectedSegmentIndex == 1) {
        [UIView animateWithDuration:.2 animations:^{
            self.bookmarksView.right = 0;
            self.tabsView.left = 0;
        }];
    }
}

- (void)showWebView
{
    self.webView.hidden = NO;
    self.bookmarksView.hidden = YES;
    self.tabsView.hidden = YES;
    self.segmentedControl.hidden = YES;
    
    self.bookmarksView.scrollsToTop = NO;
    self.tabsView.scrollsToTop = NO;
    self.webView.scrollView.scrollsToTop = YES;
}

- (void)hideWebview
{
    self.webView.hidden = YES;
    self.bookmarksView.hidden = NO;
    self.tabsView.hidden = NO;
    self.segmentedControl.hidden = NO;
    [self.bookmarksView reloadData];
    
    self.bookmarksView.scrollsToTop = YES;
    self.tabsView.scrollsToTop = YES;
    self.webView.scrollView.scrollsToTop = NO;
    
    [self.tabsView reloadData];
}

@end
