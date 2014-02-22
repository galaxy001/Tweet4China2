//
//  HSUComposeViewController.m
//  Tweet4China
//
//  Created by Jason Hsu on 3/26/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUComposeViewController.h"
#import <FHSTwitterEngine/FHSTwitterEngine.h>
#import <FHSTwitterEngine/OARequestParameter.h>
#import <FHSTwitterEngine/OAMutableURLRequest.h>
#import "HSUSuggestMentionCell.h"
#import "UIImage+Additions.h"
#import <MapKit/MapKit.h>
#import "HSUSendBarButtonItem.h"
#import <twitter-text-objc/TwitterText.h>
#import <OpenCam/OpenCam.h>
#import <SVWebViewController/SVModalWebViewController.h>

#define kMaxWordLen 140
#define kSingleLineHeight 45
#define kSuggestionType_Mention 1
#define kSuggestionType_Tag 2

@interface HSULocationAnnotation : NSObject <MKAnnotation>
@end

@implementation HSULocationAnnotation
{
    CLLocationCoordinate2D coordinate;
}

- (CLLocationCoordinate2D)coordinate {
    return coordinate;
}

- (NSString *)title {
    return nil;
}

- (NSString *)subtitle {
    return nil;
}

- (void)setCoordinate:(CLLocationCoordinate2D)newCoordinate {
    coordinate = newCoordinate;
}

@end

@interface HSUComposeViewController () <UITextViewDelegate, UIScrollViewDelegate, UINavigationControllerDelegate, CLLocationManagerDelegate, MKMapViewDelegate, UITableViewDataSource, UITableViewDelegate, OCMCameraViewControllerDelegate>

@property (nonatomic, assign) BOOL changingSettings;
@property (nonatomic, assign) uint lifeCycleCount;

@property (nonatomic, weak) UITextView *contentTV;
@property (nonatomic, weak) UIView *toolbar;
@property (nonatomic, weak) UIButton *photoBnt;
@property (nonatomic, weak) UIButton *geoBnt;
@property (nonatomic, weak) UIActivityIndicatorView *geoLoadingV;
@property (nonatomic, weak) UIButton *mentionBnt;
@property (nonatomic, weak) UIButton *tagBnt;
@property (nonatomic, weak) UILabel *wordCountL;
@property (nonatomic, weak) UIImageView *nippleIV;
@property (nonatomic, weak) UIScrollView *extraPanelSV;
@property (nonatomic, weak) UIButton *takePhotoBnt;
@property (nonatomic, weak) UIButton *selectPhotoBnt;
@property (nonatomic, weak) UIImageView *previewIV;
@property (nonatomic, weak) UIButton *previewCloseBnt;
@property (nonatomic, weak) MKMapView *mapView;
@property (nonatomic, weak) UIImageView *mapOutlineIV;
@property (nonatomic, weak) UILabel *locationL;
@property (nonatomic, weak) UIButton *toggleLocationBnt;
@property (nonatomic, weak) UITableView *suggestionsTV;
@property (nonatomic, weak) UIImageView *contentShadowV;

@property (nonatomic, assign) CGFloat keyboardHeight;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, assign) CLLocationCoordinate2D location;
@property (nonatomic, strong) NSArray *friends;
@property (nonatomic, strong) NSArray *trends;
@property (nonatomic, assign) NSUInteger suggestionType;
@property (nonatomic, strong) NSMutableArray *filteredSuggestions;
@property (nonatomic, assign) NSUInteger filterLocation;

@property (nonatomic, strong) UIImage *postImage;

@property (nonatomic, copy) NSString *textAtFist;
@property (nonatomic, assign) BOOL contentChanged;
@property (nonatomic, copy) NSString *geoCode;

@property (nonatomic, assign) BOOL suggested;
@property (nonatomic, assign) BOOL photoEdited;

@property (nonatomic, assign) BOOL notFirstDisapear;

@end

@implementation HSUComposeViewController

- (void)dealloc
{
    notification_remove_observer(self);
    self.contentTV.delegate = nil;
    self.extraPanelSV.delegate = nil;
    self.suggestionsTV.delegate = nil;
    self.locationManager.delegate = nil;
    [self.locationManager stopUpdatingLocation];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    notification_add_observer(UIKeyboardWillChangeFrameNotification, self, @selector(keyboardFrameChanged:));
    notification_add_observer(UIKeyboardWillHideNotification, self, @selector(keyboardWillHide:));
    notification_add_observer(UIKeyboardWillShowNotification, self, @selector(keyboardWillShow:));
    
    // setup default values
    if (self.draft) {
        self.defaultTitle = self.draft[@"title"];
        self.defaultText = self.draft[@"status"];
        self.defaultSelectedRange = NSMakeRange(self.defaultText.length, 0);
        self.inReplyToStatusId = self.draft[kTwitterReplyID_ParameterKey];
        self.defaultImage = [UIImage imageWithContentsOfFile:self.draft[@"image_file_path"]];
    }
    
    self.textAtFist = [self.defaultText copy];
    
//    setup navigation bar
    if (self.defaultTitle) {
        self.title = self.defaultTitle;
    } else {
        self.title = _("New Tweet");
    }
    
    if (Sys_Ver < 7) {
        self.navigationController.navigationBar.tintColor = bw(212);
        NSDictionary *attributes = @{UITextAttributeTextColor: bw(50),
                                     UITextAttributeTextShadowColor: kWhiteColor,
                                     UITextAttributeTextShadowOffset: [NSValue valueWithCGPoint:ccp(0, 1)]};
        self.navigationController.navigationBar.titleTextAttributes = attributes;
    }
    
    UIBarButtonItem *cancelButtonItem = [[UIBarButtonItem alloc] init];
    cancelButtonItem.title = _("Cancel");
    cancelButtonItem.target = self;
    cancelButtonItem.action = @selector(cancelCompose);
    if (Sys_Ver < 7) {
        cancelButtonItem.tintColor = bw(220);
        NSDictionary *attributes = @{UITextAttributeTextColor: bw(50),
                                     UITextAttributeTextShadowColor: kWhiteColor,
                                     UITextAttributeTextShadowOffset: [NSValue valueWithCGPoint:ccp(0, 1)]};
        self.navigationController.navigationBar.titleTextAttributes = attributes;
        NSDictionary *disabledAttributes = @{UITextAttributeTextColor: bw(129),
                                             UITextAttributeTextShadowColor: kWhiteColor,
                                             UITextAttributeTextShadowOffset: [NSValue valueWithCGSize:ccs(0, 1)]};
        [cancelButtonItem setTitleTextAttributes:attributes forState:UIControlStateNormal];
        [cancelButtonItem setTitleTextAttributes:attributes forState:UIControlStateHighlighted];
        [cancelButtonItem setTitleTextAttributes:disabledAttributes forState:UIControlStateDisabled];
    }
    self.navigationItem.leftBarButtonItem = cancelButtonItem;
    
    UIBarButtonItem *sendButtonItem = [[UIBarButtonItem alloc] init];
    sendButtonItem.title = _("Tweet");
    sendButtonItem.target = self;
    sendButtonItem.action = @selector(sendTweet);
    sendButtonItem.enabled = NO;
    if (Sys_Ver < 7) {
        cancelButtonItem.tintColor = bw(220);
        NSDictionary *attributes = @{UITextAttributeTextColor: bw(50),
                                     UITextAttributeTextShadowColor: kWhiteColor,
                                     UITextAttributeTextShadowOffset: [NSValue valueWithCGPoint:ccp(0, 1)]};
        self.navigationController.navigationBar.titleTextAttributes = attributes;
        NSDictionary *disabledAttributes = @{UITextAttributeTextColor: bw(129),
                                             UITextAttributeTextShadowColor: kWhiteColor,
                                             UITextAttributeTextShadowOffset: [NSValue valueWithCGSize:ccs(0, 1)]};
        [sendButtonItem setTitleTextAttributes:attributes forState:UIControlStateNormal];
        [sendButtonItem setTitleTextAttributes:attributes forState:UIControlStateHighlighted];
        [sendButtonItem setTitleTextAttributes:disabledAttributes forState:UIControlStateDisabled];
    }
    self.navigationItem.rightBarButtonItem = sendButtonItem;
    
//    setup view
    self.view.backgroundColor = kWhiteColor;
    UITextView *contentTV = [[UITextView alloc] init];
    [self.view addSubview:contentTV];
    self.contentTV = contentTV;
    contentTV.font = [UIFont systemFontOfSize:16];
    contentTV.delegate = self;
    if (self.defaultText) {
        contentTV.text = self.defaultText;
        contentTV.selectedRange = self.defaultSelectedRange;
    } else {
        contentTV.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"draft"];
    }
    
    UIImageView *toolbar =[UIImageView viewStrechedNamed:@"button-bar-background"];
    [self.view addSubview:toolbar];
    self.toolbar = toolbar;
    toolbar.userInteractionEnabled = YES;
    
    UIButton *photoBnt = [[UIButton alloc] init];
    [toolbar addSubview:photoBnt];
    self.photoBnt = photoBnt;
    [photoBnt addTarget:self action:@selector(photoButtonTouched) forControlEvents:UIControlEventTouchUpInside];
    [photoBnt setImage:[UIImage imageNamed:@"button-bar-camera"] forState:UIControlStateNormal];
    [photoBnt setImage:[UIImage imageNamed:@"button-bar-camera-glow"] forState:UIControlStateSelected];
    photoBnt.selected = self.defaultImage != nil;
    photoBnt.showsTouchWhenHighlighted = YES;
    [photoBnt sizeToFit];
    photoBnt.center = ccp(25, 20);
    photoBnt.hitTestEdgeInsets = UIEdgeInsetsMake(0, -5, 0, -5);
    
    UIButton *geoBnt = [[UIButton alloc] init];
    [toolbar addSubview:geoBnt];
    self.geoBnt = geoBnt;
    [geoBnt addTarget:self action:@selector(geoButtonTouched) forControlEvents:UIControlEventTouchUpInside];
    [geoBnt setImage:[UIImage imageNamed:@"compose-geo"] forState:UIControlStateNormal];
    geoBnt.showsTouchWhenHighlighted = YES;
    [geoBnt sizeToFit];
    geoBnt.center = ccp(85, 20);
    geoBnt.hitTestEdgeInsets = UIEdgeInsetsMake(0, -5, 0, -5);
    
    UIActivityIndicatorView *geoLoadingV = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [toolbar addSubview:geoLoadingV];
    self.geoLoadingV = geoLoadingV;
    geoLoadingV.center = geoBnt.center;
    geoLoadingV.hidesWhenStopped = YES;
    
    UIButton *mentionBnt = [[UIButton alloc] init];
    [toolbar addSubview:mentionBnt];
    self.mentionBnt = mentionBnt;
    [mentionBnt setTapTarget:self action:@selector(mentionButtonTouched)];
    [mentionBnt setImage:[UIImage imageNamed:@"button-bar-at"] forState:UIControlStateNormal];
    mentionBnt.showsTouchWhenHighlighted = YES;
    [mentionBnt sizeToFit];
    mentionBnt.center = ccp(145, 20);
    mentionBnt.hitTestEdgeInsets = UIEdgeInsetsMake(0, -5, 0, -5);
    
    UIButton *tagBnt = [[UIButton alloc] init];
    [toolbar addSubview:tagBnt];
    self.tagBnt = tagBnt;
    [tagBnt setTapTarget:self action:@selector(tagButtonTouched)];
    [tagBnt setImage:[UIImage imageNamed:@"button-bar-hashtag"] forState:UIControlStateNormal];
    tagBnt.showsTouchWhenHighlighted = YES;
    [tagBnt sizeToFit];
    tagBnt.center = ccp(205, 20);
    tagBnt.hitTestEdgeInsets = UIEdgeInsetsMake(0, -5, 0, -5);
    
    UILabel *wordCountL = [[UILabel alloc] init];
    [toolbar addSubview:wordCountL];
    self.wordCountL = wordCountL;
    wordCountL.font = [UIFont systemFontOfSize:14];
    wordCountL.textColor = bw(140);
    wordCountL.shadowColor = kWhiteColor;
    wordCountL.shadowOffset = ccs(0, 1);
    wordCountL.backgroundColor = kClearColor;
    wordCountL.text = S(@"%d", kMaxWordLen);
    [wordCountL sizeToFit];
    wordCountL.center = ccp(294, 20);
    
    UIImageView *nippleIV = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"compose-nipple"]];
    [toolbar addSubview:nippleIV];
    self.nippleIV = nippleIV;
    nippleIV.center = photoBnt.center;
    nippleIV.bottom = toolbar.height + 1;
    
    UIScrollView *extraPanelSV = [[UIScrollView alloc] init];
    [self.view addSubview:extraPanelSV];
    self.extraPanelSV = extraPanelSV;
    extraPanelSV.left = 0;
    extraPanelSV.width = self.view.width;
    extraPanelSV.pagingEnabled = YES;
    extraPanelSV.delegate = self;
    extraPanelSV.showsHorizontalScrollIndicator = NO;
    extraPanelSV.showsVerticalScrollIndicator = NO;
    extraPanelSV.backgroundColor = bw(232);
    extraPanelSV.alwaysBounceVertical = NO;
    
    if ([setting(HSUSettingSelectBeforeStartCamera) boolValue]) {
        UIButton *takePhotoBnt = [[UIButton alloc] init];
        [extraPanelSV addSubview:takePhotoBnt];
        self.takePhotoBnt = takePhotoBnt;
        [takePhotoBnt setTapTarget:self action:@selector(takePhotoButtonTouched)];
        [takePhotoBnt setBackgroundImage:[[UIImage imageNamed:@"compose-map-toggle-button"] stretchableImageFromCenter] forState:UIControlStateNormal];
        [takePhotoBnt setBackgroundImage:[[UIImage imageNamed:@"compose-map-toggle-button-pressed"] stretchableImageFromCenter] forState:UIControlStateHighlighted];
        [takePhotoBnt setTitle:@"Take photo" forState:UIControlStateNormal];
        [takePhotoBnt setTitleColor:rgb(52, 80, 112) forState:UIControlStateNormal];
        takePhotoBnt.titleLabel.font = [UIFont boldSystemFontOfSize:13];
        [takePhotoBnt sizeToFit];
        takePhotoBnt.width = extraPanelSV.width - 20;
        takePhotoBnt.topCenter = ccp(extraPanelSV.center.x, 11);
        
        UIButton *selectPhotoBnt = [[UIButton alloc] init];
        [extraPanelSV addSubview:selectPhotoBnt];
        self.selectPhotoBnt = selectPhotoBnt;
        [selectPhotoBnt setTapTarget:self action:@selector(selectPhotoButtonTouched)];
        [selectPhotoBnt setBackgroundImage:[[UIImage imageNamed:@"compose-map-toggle-button"] stretchableImageFromCenter] forState:UIControlStateNormal];
        [selectPhotoBnt setBackgroundImage:[[UIImage imageNamed:@"compose-map-toggle-button-pressed"] stretchableImageFromCenter] forState:UIControlStateHighlighted];
        [selectPhotoBnt setTitle:@"Choose from library" forState:UIControlStateNormal];
        [selectPhotoBnt setTitleColor:rgb(52, 80, 112) forState:UIControlStateNormal];
        selectPhotoBnt.titleLabel.font = [UIFont boldSystemFontOfSize:13];
        selectPhotoBnt.frame = takePhotoBnt.frame;
        selectPhotoBnt.top = selectPhotoBnt.bottom + 10;
    }
    
    UIImageView *previewIV = [[UIImageView alloc] init];
    [extraPanelSV addSubview:previewIV];
    self.previewIV = previewIV;
    previewIV.hidden = YES;
    previewIV.layer.cornerRadius = 3;
    
    UIButton *previewCloseBnt = [[UIButton alloc] init];
    [extraPanelSV addSubview:previewCloseBnt];
    self.previewCloseBnt = previewCloseBnt;
    [previewCloseBnt setTapTarget:self action:@selector(previewCloseButtonTouched)];
    previewCloseBnt.hidden = YES;
    [previewCloseBnt setImage:[UIImage imageNamed:@"UIBlackCloseButton"] forState:UIControlStateNormal];
    [previewCloseBnt setImage:[UIImage imageNamed:@"UIBlackCloseButtonPressed"] forState:UIControlStateHighlighted];
    [previewCloseBnt sizeToFit];
    
    MKMapView *mapView = [[MKMapView alloc] init]; // todo: this MapView make many warning echo
    [extraPanelSV addSubview:mapView];
    self.mapView = mapView;
    mapView.zoomEnabled = NO;
    mapView.scrollEnabled = NO;
    mapView.frame = ccr(extraPanelSV.width + 10, 10, extraPanelSV.width - 20, 125);
    
    UIImageView *mapOutlineIV = [UIImageView viewStrechedNamed:@"compose-map-outline"];
    [extraPanelSV addSubview:mapOutlineIV];
    self.mapOutlineIV = mapOutlineIV;
    mapOutlineIV.frame = mapView.frame;
    
    UILabel *locationL = [[UILabel alloc] init];
    [extraPanelSV addSubview:locationL];
    self.locationL = locationL;
    locationL.backgroundColor = kClearColor;
    locationL.font = [UIFont systemFontOfSize:14];
    locationL.textColor = bw(140);
    locationL.shadowColor = kWhiteColor;
    locationL.shadowOffset = ccs(0, 1);
    locationL.textAlignment = NSTextAlignmentCenter;
    locationL.numberOfLines = 1;
    locationL.frame = ccr(mapView.left, mapView.bottom, mapView.width, 30);
    
    UIButton *toggleLocationBnt = [[UIButton alloc] init];
    [extraPanelSV addSubview:toggleLocationBnt];
    self.toggleLocationBnt = toggleLocationBnt;
    [toggleLocationBnt setTapTarget:self action:@selector(toggleLocationButtonTouched)];
    [toggleLocationBnt setBackgroundImage:[[UIImage imageNamed:@"compose-map-toggle-button"] stretchableImageFromCenter]
                                 forState:UIControlStateNormal];
    [toggleLocationBnt setBackgroundImage:[[UIImage imageNamed:@"compose-map-toggle-button-pressed"] stretchableImageFromCenter]
                                 forState:UIControlStateHighlighted];
    [toggleLocationBnt setTitle:_("Turn off location") forState:UIControlStateNormal];
    [toggleLocationBnt setTitleColor:rgb(52, 80, 112) forState:UIControlStateNormal];
    toggleLocationBnt.titleLabel.font = [UIFont boldSystemFontOfSize:13];
    [toggleLocationBnt sizeToFit];
    toggleLocationBnt.width = extraPanelSV.width - 20;
    toggleLocationBnt.left += extraPanelSV.width;
    
    UITableView *suggestionsTV = [[UITableView alloc] init];
    [self.view addSubview:suggestionsTV];
    self.suggestionsTV = suggestionsTV;
    suggestionsTV.hidden = YES;
    suggestionsTV.delegate = self;
    suggestionsTV.dataSource = self;
    suggestionsTV.width = self.view.width;
    suggestionsTV.rowHeight = 37;
    suggestionsTV.backgroundColor = bw(232);
    suggestionsTV.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    [suggestionsTV registerClass:[HSUSuggestMentionCell class] forCellReuseIdentifier:[[HSUSuggestMentionCell class] description]];
    
    UIImageView *contentShadowV = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"searches-top-shadow.png"] stretchableImageFromCenter]];
    [self.view addSubview:contentShadowV];
    self.contentShadowV = contentShadowV;
    contentShadowV.hidden = YES;
    contentShadowV.width = suggestionsTV.width;
    
    if (self.defaultImage) {
        self.postImage = self.defaultImage;
    }
    
    CGFloat toolbarHeight = 40;
    
    contentTV.frame = ccr(0, 0, self.view.width, self.view.height- MAX(self.keyboardHeight, 216)-toolbarHeight);
    toolbar.frame = ccr(0, contentTV.bottom, self.view.width, toolbarHeight);
    extraPanelSV.top = toolbar.bottom;
    extraPanelSV.height = self.view.height - extraPanelSV.top;
    extraPanelSV.contentSize = ccs(extraPanelSV.width*2, extraPanelSV.height);
    previewIV.frame = ccr(30, 30, extraPanelSV.width-60, extraPanelSV.height-60);
    previewCloseBnt.center = previewIV.rightTop;
    toggleLocationBnt.bottom = extraPanelSV.height - 10;
    suggestionsTV.top = contentTV.top + 45;
    contentShadowV.top = suggestionsTV.top;
    
    if (self.postImage) {
        [self photoButtonTouched];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.lifeCycleCount == 0) {
        [self.contentTV becomeFirstResponder];
    }
    [self textViewDidChange:self.contentTV];
    self.contentChanged = NO;
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (!self.notFirstDisapear) {
        self.notFirstDisapear = YES;
        self.contentTV.selectedRange = self.defaultSelectedRange;
    }
    
    if (self.changingSettings) {
        self.changingSettings = NO;
        [HSUCommonTools resetUserAgent];
        [SVProgressHUD showWithStatus:_("Updating your user settings...")];
        [twitter getUserSettingsWithSuccess:^(id responseObj) {
            [SVProgressHUD dismiss];
            NSMutableDictionary *userSettings = [[[NSUserDefaults standardUserDefaults] objectForKey:HSUUserSettings] mutableCopy] ?: [NSMutableDictionary dictionary];
            NSMutableDictionary *myUserSettings = [userSettings[MyScreenName] mutableCopy];
            NSDictionary *myNewUserSettings = responseObj;
            for (NSString *key in myNewUserSettings) {
                myUserSettings[key] = myNewUserSettings[key];
            }
            userSettings[MyScreenName] = myUserSettings;
            [[NSUserDefaults standardUserDefaults] setObject:userSettings forKey:HSUUserSettings];
            [[NSUserDefaults standardUserDefaults] synchronize];
        } failure:^(NSError *error) {
            [SVProgressHUD showErrorWithStatus:_("Load user settings failed")];
        }];
    }
    
    CLLocationManager *locationManager = [[CLLocationManager alloc] init];
    self.locationManager = locationManager;
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    locationManager.pausesLocationUpdatesAutomatically = YES;
    
    NSString *friendsFileName = dp(@"tweet4china.friends");
    NSData *json = [NSData dataWithContentsOfFile:friendsFileName];
    if (json) {
        self.friends = [NSJSONSerialization JSONObjectWithData:json options:0 error:nil];
    }
    __weak typeof(self)weakSelf = self;
    [twitter getFriendsWithCount:100 success:^(id responseObj) {
        if (weakSelf) {
            weakSelf.friends = responseObj[@"users"];
            NSData *json = [NSJSONSerialization dataWithJSONObject:weakSelf.friends options:0 error:nil];
            [json writeToFile:friendsFileName atomically:NO];
            [weakSelf filterSuggestions];
        }
    } failure:^(NSError *error) {
        
    }];
    
    NSString *trendsFileName = dp(@"tweet4china.trends");
    json = [NSData dataWithContentsOfFile:trendsFileName];
    if (json) {
        self.trends = [NSJSONSerialization JSONObjectWithData:json options:0 error:nil];
    }
    [twitter getTrendsWithSuccess:^(id responseObj) {
        if (weakSelf) {
            weakSelf.trends = responseObj[0][@"trends"];
            NSData *json = [NSJSONSerialization dataWithJSONObject:weakSelf.trends options:0 error:nil];
            [json writeToFile:trendsFileName atomically:NO];
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf filterSuggestions];
            });
        }
    } failure:^(NSError *error) {
        
    }];
}

- (void)viewWillDisappear:(BOOL)animated
{
#ifdef __IPHONE_7_0
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
#endif
    
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    self.lifeCycleCount ++;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    CGFloat toolbarHeight = 40;
    
    self.contentTV.width = self.view.width;
    self.contentTV.height = self.view.height - MAX(self.keyboardHeight, 216) - toolbarHeight;
    self.contentTV.top = 0;
    self.toolbar.frame = ccr(0, self.contentTV.bottom, self.view.width, toolbarHeight);
    self.extraPanelSV.top = self.toolbar.bottom;
    self.extraPanelSV.height = self.view.height - self.extraPanelSV.top;
    self.extraPanelSV.contentSize = ccs(self.extraPanelSV.width*2, self.extraPanelSV.height);
    self.previewIV.frame = ccr(30, 30, self.extraPanelSV.width-60, self.extraPanelSV.height-60);
    self.previewCloseBnt.center = self.previewIV.rightTop;
    self.toggleLocationBnt.bottom = self.extraPanelSV.height - 10;
    self.suggestionsTV.top = self.contentTV.top + 45;
    self.contentShadowV.top = self.suggestionsTV.top;
    
    if (self.suggestionType) {
        self.suggested = YES;
        self.suggestionsTV.hidden = NO;
        self.contentShadowV.hidden = NO;
        self.contentTV.height = kSingleLineHeight;
        self.suggestionsTV.height = self.view.height - self.suggestionsTV.top - self.keyboardHeight;
        if (Sys_Ver >= 7) {
            self.contentTV.top = 54;
            self.suggestionsTV.top = self.contentTV.top + 45;
            self.contentShadowV.top = self.suggestionsTV.top;
            self.suggestionsTV.height -= 54;
        }
        [self.contentTV scrollRangeToVisible:self.contentTV.selectedRange];
    } else {
        self.suggestionsTV.hidden = YES;
        self.contentShadowV.hidden = YES;
        if (self.suggested) {
            self.suggested = NO;
            NSRange selectedRange = self.contentTV.selectedRange;
            NSString *text = self.contentTV.text;
            self.contentTV.text = nil;
            __weak typeof(self)weakSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.contentTV.text = text;
                weakSelf.contentTV.selectedRange = selectedRange;
            });
        }
    }
}

- (void)keyboardFrameChanged:(NSNotification *)notification
{
	CGRect keyboardBounds;
    [[notification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue: &keyboardBounds];
    keyboardBounds = [self.view convertRect:keyboardBounds toView:nil];
    self.keyboardHeight = keyboardBounds.size.height;
    [self.view setNeedsLayout];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    self.nippleIV.hidden = NO;
}

- (void)keyboardWillShow:(NSNotification *)notification {
    self.nippleIV.hidden = YES;
}

- (void)cancelCompose
{
    if (self.draft) {
        NSData *imageData = UIImageJPEGRepresentation(self.postImage, 0.92);
        [[HSUDraftManager shared] saveDraftWithDraftID:self.draft[@"id"] title:self.title status:self.contentTV.text imageData:imageData reply:self.inReplyToStatusId locationXY:self.location placeId:self.geoCode];
        [[HSUDraftManager shared] activeDraft:self.draft];
        [self dismiss];
        return;
    }
    if (self.contentChanged || self.postImage) {
        if ([self.textAtFist isEqualToString:self.contentTV.text]) {
            [self dismiss];
            return;
        }
        if (self.contentTV.text.length == 0 && !self.postImage) {
            [self dismiss];
            return;
        }
        RIButtonItem *cancelBnt = [RIButtonItem itemWithLabel:_("Cancel")];
        RIButtonItem *giveUpBnt = [RIButtonItem itemWithLabel:_("Don't Save")];
        giveUpBnt.action = ^{
            [self dismissViewControllerAnimated:YES completion:nil];
        };
        RIButtonItem *saveBnt = [RIButtonItem itemWithLabel:_("Save Draft")];
        __weak typeof(self)weakSelf = self;
        saveBnt.action = ^{
            NSString *status = weakSelf.contentTV.text;
            NSData *imageData = UIImageJPEGRepresentation(weakSelf.postImage, 0.92);
            NSDictionary *draft = [[HSUDraftManager shared] saveDraftWithDraftID:nil title:weakSelf.title status:status imageData:imageData reply:weakSelf.inReplyToStatusId locationXY:weakSelf.location placeId:weakSelf.geoCode];
            [[HSUDraftManager shared] activeDraft:draft];
            [weakSelf dismissViewControllerAnimated:YES completion:nil];
        };
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil cancelButtonItem:cancelBnt destructiveButtonItem:nil otherButtonItems:giveUpBnt, saveBnt, nil];
        actionSheet.destructiveButtonIndex = 0;
        [actionSheet showInView:self.view.window];
    } else {
        [self dismiss];
    }
}

- (void)sendTweet
{
    if (self.contentTV.text == nil && self.postImage == nil) return;
    NSString *status = self.contentTV.text;
    //save draft
    NSData *imageData = UIImageJPEGRepresentation(self.postImage, 0.92);
    NSDictionary *draft = [[HSUDraftManager shared] saveDraftWithDraftID:self.draft[@"id"] title:self.title status:status imageData:imageData reply:self.inReplyToStatusId locationXY:self.location placeId:self.geoCode];
    
    if (self.photoEdited) {
        UIImageWriteToSavedPhotosAlbum(self.postImage, 0, 0, 0);
    }
    
    [[HSUDraftManager shared] sendDraft:draft success:^(id responseObj) {
        [[HSUDraftManager shared] removeDraft:draft];
    } failure:^(NSError *error) {
        if (error.code == 204) {
            [[HSUDraftManager shared] removeDraft:draft];
            [SVProgressHUD showErrorWithStatus:_("Duplicated status")];
            return ;
        }
        if (!shadowsocksStarted) {
            [[HSUAppDelegate shared] startShadowsocks];
        }
        [[HSUDraftManager shared] activeDraft:draft];
        RIButtonItem *cancelItem = [RIButtonItem itemWithLabel:_("Cancel")];
        RIButtonItem *draftsItem = [RIButtonItem itemWithLabel:_("Drafts")];
        draftsItem.action = ^{
            [[HSUDraftManager shared] presentDraftsViewController];
        };
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:_("Tweet not sent")
                                                        message:error.userInfo[@"message"]
                                               cancelButtonItem:cancelItem otherButtonItems:draftsItem, nil];
        dispatch_async(GCDMainThread, ^{
            [alert show];
        });
    }];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    NSString *newText = [self.contentTV.text stringByReplacingCharactersInRange:range withString:text];
    if (newText.length < textView.text.length) { // return YES for deleting text
        return YES;
    }
    return ([TwitterText tweetLength:newText] <= 140);
}

- (void)textViewDidChange:(UITextView *)textView {
    NSUInteger wordLen = [TwitterText tweetLength:self.contentTV.text];
    if (wordLen > 0 || self.postImage) {
        self.navigationItem.rightBarButtonItem.enabled = YES;
    } else {
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
    self.wordCountL.text = S(@"%d", kMaxWordLen-wordLen);
    
    [self filterSuggestions];
    
    self.contentChanged = YES;
}

- (void)filterSuggestions {
    if (self.suggestionType) {
        NSInteger len = self.contentTV.selectedRange.location-self.filterLocation;
        if (len >= 0) {
            NSString *filterText = [self.contentTV.text substringWithRange:NSMakeRange(self.filterLocation, len)];
            NSString *trimmedText = [filterText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if (![trimmedText isEqualToString:filterText]) {
                self.suggestionType = 0;
                self.filteredSuggestions = nil;
                [self.view setNeedsLayout];
            }
            if (self.suggestionType == kSuggestionType_Mention && self.friends) {
                if (filterText && filterText.length) {
                    if (self.filteredSuggestions == nil) {
                        self.filteredSuggestions = [NSMutableArray array];
                    } else {
                        [self.filteredSuggestions removeAllObjects];
                    }
                    for (NSDictionary *friend in self.friends) {
                        NSString *screenName = friend[@"screen_name"];
                        if ([screenName rangeOfString:filterText].location != NSNotFound) {
                            [self.filteredSuggestions addObject:friend];
                        }
                    }
                } else {
                    self.filteredSuggestions = [self.friends mutableCopy];
                }
            } else if (self.suggestionType == kSuggestionType_Tag && self.trends) {
                if (filterText && filterText.length) {
                    if (self.filteredSuggestions == nil) {
                        self.filteredSuggestions = [NSMutableArray array];
                    } else {
                        [self.filteredSuggestions removeAllObjects];
                    }
                    for (NSDictionary *trend in self.trends) {
                        NSString *tag = [[trend[@"name"] substringFromIndex:1] lowercaseString];
                        if (tag && [tag rangeOfString:filterText].location != NSNotFound) {
                            [self.filteredSuggestions addObject:trend];
                        }
                    }
                } else {
                    self.filteredSuggestions = [self.trends mutableCopy];
                }
            }
            [self.suggestionsTV reloadData];
        } else {
            self.suggestionType = 0;
            self.filteredSuggestions = nil;
            [self.view setNeedsLayout];
        }
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView.width) {
        CGFloat left = self.photoBnt.center.x - self.nippleIV.width / 2;
        CGFloat right = self.geoBnt.center.x - self.nippleIV.width / 2;
        self.nippleIV.left = left + (right - left) * scrollView.contentOffset.x / scrollView.width;
    }
}

#pragma mark - Actions
- (void)photoButtonTouched {
    if (boolSetting(HSUSettingSelectBeforeStartCamera)) {
        if ([self.contentTV isFirstResponder]) {
            [self.contentTV resignFirstResponder];
        } else {
            [self.contentTV becomeFirstResponder];
        }
        if (self.postImage && !self.previewIV.image) {
            [self photoSelected:self.postImage];
        }
        return;
    }
    if (self.postImage && !self.previewIV.image) {
        [self photoSelected:self.postImage];
    }
    if (self.contentTV.isFirstResponder || self.extraPanelSV.contentOffset.x > 0) {
        [self.contentTV resignFirstResponder];
        [self.extraPanelSV setContentOffset:ccp(0, 0) animated:YES];
    } else {
        [self.contentTV becomeFirstResponder];
    }
    if (!self.postImage) {
        [self selectPhoto];
    }
}

- (void)photoSelected:(UIImage *)photo {
    self.postImage = photo;
    CGFloat height = self.previewIV.height / self.previewIV.width * photo.size.width;
    CGFloat top = photo.size.height/2 - height/2;
    CGImageRef imageRef = CGImageCreateWithImageInRect(photo.CGImage, ccr(0, top, photo.size.width, height));
    self.previewIV.image = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    self.previewIV.hidden = NO;
    self.previewCloseBnt.hidden = NO;
    self.photoBnt.selected = YES;
    self.navigationItem.rightBarButtonItem.enabled = YES;
    
    self.takePhotoBnt.hidden = YES;
    self.selectPhotoBnt.hidden = YES;
}

- (void)previewCloseButtonTouched {
    self.previewCloseBnt.hidden = YES;
    self.takePhotoBnt.hidden = NO;
    self.selectPhotoBnt.hidden = NO;
    __weak typeof(self)weakSelf = self;
    [UIView animateWithDuration:0.2 animations:^{
        weakSelf.previewIV.transform = CGAffineTransformMakeScale(0, 0);
        weakSelf.previewIV.alpha = 0;
        weakSelf.previewIV.center = weakSelf.extraPanelSV.boundsCenter;
    } completion:^(BOOL finished) {
        weakSelf.postImage = nil;
        weakSelf.previewIV.image = nil;
        weakSelf.previewIV.hidden = YES;
        weakSelf.previewIV.transform = CGAffineTransformMakeTranslation(1, 1);
        weakSelf.previewIV.alpha = 1;
        weakSelf.previewIV.center = weakSelf.extraPanelSV.boundsCenter;
    }];
    
    self.photoBnt.selected = NO;
    
    if (![setting(HSUSettingSelectBeforeStartCamera) boolValue]) {
        [self selectPhoto];
    }
}

- (void)geoButtonTouched {
    NSDictionary *userSettings = [[NSUserDefaults standardUserDefaults] objectForKey:HSUUserSettings][MyScreenName];
    if (![userSettings[@"geo_enabled"] boolValue]) {
        RIButtonItem *cancelItem = [RIButtonItem itemWithLabel:_("Cancel")];
        RIButtonItem *openItem = [RIButtonItem itemWithLabel:_("Open Twitter Website")];
        __weak typeof(self)weakSelf = self;
        openItem.action = ^{
            [HSUCommonTools switchToDesktopUserAgent];
            SVModalWebViewController *web = [[SVModalWebViewController alloc] initWithAddress:@"https://twitter.com/settings/security"];
            [weakSelf presentViewController:web animated:YES completion:nil];
            weakSelf.changingSettings = YES;
        };
        [[[UIAlertView alloc] initWithTitle:_("Location disabled") message:_("You location is disabled, go to twitter's website and change it in your private settings.") cancelButtonItem:cancelItem otherButtonItems:openItem, nil] show];
        return;
    }
    if (self.contentTV.isFirstResponder ||  self.extraPanelSV.contentOffset.x == 0) {
        if (self.contentTV.isFirstResponder) {
            [self.locationManager startUpdatingLocation];
            self.geoBnt.hidden = YES;
            [self.geoLoadingV startAnimating];
            [self.toggleLocationBnt setTitle:_("Turn off location") forState:UIControlStateNormal];
            self.mapOutlineIV.backgroundColor = kClearColor;
        }

        [self.extraPanelSV setContentOffset:ccp(self.extraPanelSV.width, 0) animated:YES];
        [self.contentTV resignFirstResponder];
    } else {
        [self.contentTV becomeFirstResponder];
    }
}

- (void)toggleLocationButtonTouched {
    if (self.toggleLocationBnt.tag) {
        [self.contentTV becomeFirstResponder];
        [self.geoBnt setImage:[UIImage imageNamed:@"compose-geo"] forState:UIControlStateNormal];
        self.geoBnt.hidden = NO;
        [self.locationManager stopUpdatingLocation];
        [self.toggleLocationBnt setTitle:_("Turn on location") forState:UIControlStateNormal];
        [self.mapView removeAnnotations:self.mapView.annotations];
        self.mapOutlineIV.backgroundColor = rgba(1, 1, 1, 0.2);
        self.toggleLocationBnt.tag = 0;
        [self.geoLoadingV stopAnimating];
    } else {
        [self.locationManager startUpdatingLocation];
        self.geoBnt.hidden = YES;
        [self.geoLoadingV startAnimating];
        [self.toggleLocationBnt setTitle:_("Turn off location") forState:UIControlStateNormal];
        self.mapOutlineIV.backgroundColor = kClearColor;
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    if (manager.location.horizontalAccuracy <= 50 && manager.location.verticalAccuracy <= 50) {
        [manager stopUpdatingLocation];
    }
    
    CLGeocoder *geoCoder = [[CLGeocoder alloc] init];
    __weak typeof(self)weakSelf = self;
    [geoCoder reverseGeocodeLocation:manager.location completionHandler:^(NSArray *placemarks, NSError *error) {
        for (CLPlacemark * placemark in placemarks) {
            weakSelf.locationL.text = placemark.name;
            break;
        }
    }];
    
    [twitter reverseGeocodeWithLocation:manager.location success:^(id responseObj) {
        NSArray *places = responseObj[@"result"][@"places"];
        if (places.count) {
            NSArray *contained = places[0][@"contained_within"];
            if (contained.count) {
                NSString *placeName = contained[0][@"full_name"];
                NSString *placeId = contained[0][@"id"];
                weakSelf.locationL.text = placeName;
                weakSelf.geoCode = placeId;
            }
        }
    } failure:^(NSError *error) {
        
    }];
    
    [self.geoBnt setImage:[UIImage imageNamed:@"compose-geo-highlighted"] forState:UIControlStateNormal];
    self.geoBnt.hidden = NO;
    [self.geoLoadingV stopAnimating];
    self.toggleLocationBnt.tag = 1;
    
    self.location = manager.location.coordinate;
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(self.location, 200, 200);
    MKCoordinateRegion adjustedRegion = [self.mapView regionThatFits:viewRegion];
    [self.mapView setRegion:adjustedRegion animated:YES];
    [self.mapView setCenterCoordinate:self.location animated:YES];
    
    HSULocationAnnotation *annotation = [[HSULocationAnnotation alloc] init];
    annotation.coordinate = self.location;
    [self.mapView removeAnnotations:self.mapView.annotations];
    [self.mapView addAnnotation:annotation];
}

- (void)mentionButtonTouched {
    NSRange range = self.contentTV.selectedRange;
    if (range.location == NSNotFound)
        range = NSMakeRange(0, 0);
    self.contentTV.text = [self.contentTV.text stringByReplacingCharactersInRange:range withString:@"@"];
    [self.contentTV becomeFirstResponder];
    self.contentTV.selectedRange = NSMakeRange(range.location+1, 0);
    self.suggestionType = kSuggestionType_Mention;
    self.filterLocation = self.contentTV.selectedRange.location;
    self.filteredSuggestions = [self.friends mutableCopy];
    [self.suggestionsTV reloadData];
    [self.view setNeedsLayout];
}

- (void)tagButtonTouched {
    NSRange range = self.contentTV.selectedRange;
    if (range.location == NSNotFound)
        range = NSMakeRange(0, 0);
    self.contentTV.text = [self.contentTV.text stringByReplacingCharactersInRange:range withString:@"#"];
    [self.contentTV becomeFirstResponder];
    self.contentTV.selectedRange = NSMakeRange(range.location+1, 0);
    self.suggestionType = kSuggestionType_Tag;
    self.filterLocation = self.contentTV.selectedRange.location;
    self.filteredSuggestions = [self.trends mutableCopy];
    [self.suggestionsTV reloadData];
    [self.view setNeedsLayout];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return MIN(self.filteredSuggestions.count, 30);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.suggestionType == kSuggestionType_Mention) {
        HSUSuggestMentionCell *cell = [tableView dequeueReusableCellWithIdentifier:[[HSUSuggestMentionCell class] description] forIndexPath:indexPath];
        NSDictionary *friend = self.filteredSuggestions[indexPath.row];
        NSString *avatar = friend[@"profile_image_url_https"];
        NSString *name = friend[@"name"];
        NSString *screenName = friend[@"screen_name"];
        [cell setAvatar:avatar name:name screenName:screenName];
        return cell;
    } else if (self.suggestionType == kSuggestionType_Tag) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"HSUSuggestTagCell"];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"HSUSuggestTagCell"];
        }
        NSDictionary *trend = self.filteredSuggestions[indexPath.row];
        NSString *tag = [trend[@"name"] substringFromIndex:1];
        cell.textLabel.text = tag;
        return cell;
    }

    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *replacement = nil;
    if (self.suggestionType == kSuggestionType_Mention) {
        NSDictionary *friend = self.filteredSuggestions[indexPath.row];
        replacement = S(@"%@ ", friend[@"screen_name"]);
    } else if (self.suggestionType == kSuggestionType_Tag) {
        NSDictionary *trend = self.filteredSuggestions[indexPath.row];
        replacement = S(@"%@ ", [trend[@"name"] substringFromIndex:1]);
    }
    NSRange range = NSMakeRange(self.filterLocation, self.contentTV.selectedRange.location - self.filterLocation);
    if ([self textView:self.contentTV shouldChangeTextInRange:range replacementText:replacement]) {
        self.contentTV.text = [self.contentTV.text stringByReplacingCharactersInRange:range withString:replacement];
        [self textViewDidChange:self.contentTV];
        self.contentTV.selectedRange = NSMakeRange(range.location+replacement.length, 0);
    }
    self.suggestionType = 0;
    self.filteredSuggestions = nil;
    [self.view setNeedsLayout];
}

- (BOOL)shouldAutorotate
{
    return NO;
}

- (void)cameraViewControllerDidFinish:(OCMCameraViewController *)cameraViewController
{
    if (cameraViewController.photo) {
        [self photoSelected:cameraViewController.photo];
        self.photoEdited = cameraViewController.photoEdited;
    } else {
        [self.contentTV becomeFirstResponder];
    }
}

- (void)selectPhoto
{
    [self takePhotoButtonTouched];
}

- (void)selectPhotoButtonTouched
{
    OCMCameraViewController *cameraVC = [OpenCam cameraViewController];
    cameraVC.enterCameraRollAtStart = YES;
    cameraVC.maxWidth = 1136;
    cameraVC.delegate = self;
    [self presentViewController:cameraVC animated:YES completion:nil];
    [Flurry logEvent:@"start_opencam"];
}

- (void)takePhotoButtonTouched
{
    OCMCameraViewController *cameraVC = [OpenCam cameraViewController];
    cameraVC.maxWidth = 1136;
    cameraVC.delegate = self;
    [self presentViewController:cameraVC animated:YES completion:nil];
    [Flurry logEvent:@"start_opencam"];
}

@end
