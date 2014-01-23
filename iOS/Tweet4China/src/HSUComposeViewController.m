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
#ifdef __IPHONE_6_0
#import <OpenCam/OpenCam.h>
#endif

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

@end

@implementation HSUComposeViewController
{
    uint lifeCycleCount;
    
    UITextView *contentTV;
    UIView *toolbar;
    UIButton *photoBnt;
    UIButton *geoBnt;
    UIActivityIndicatorView *geoLoadingV;
    UIButton *mentionBnt;
    UIButton *tagBnt;
    UILabel *wordCountL;
    UIImageView *nippleIV;
    UIScrollView *extraPanelSV;
    UIImageView *previewIV;
    UIButton *previewCloseBnt;
    MKMapView *mapView;
    UIImageView *mapOutlineIV;
    UILabel *locationL;
    UIButton *toggleLocationBnt;
    UITableView *suggestionsTV;
    UIImageView *contentShadowV;
    
    CGFloat keyboardHeight;
    CLLocationManager *locationManager;
    CLLocationCoordinate2D location;
    NSArray *friends;
    NSArray *trends;
    NSUInteger suggestionType;
    NSMutableArray *filteredSuggestions;
    NSUInteger filterLocation;
    
    UIImage *postImage;
    
    NSString *textAtFist;
    BOOL contentChanged;
    NSString *geoCode;
    
    BOOL suggested;
    BOOL photoEdited;
}

- (void)dealloc
{
    contentTV.delegate = nil;
    extraPanelSV.delegate = nil;
    suggestionsTV.delegate = nil;
    locationManager.delegate = nil;
    notification_remove_observer(self);
    [locationManager stopUpdatingLocation];
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
    
    textAtFist = [self.defaultText copy];
    
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
    contentTV = [[UITextView alloc] init];
    [self.view addSubview:contentTV];
    contentTV.font = [UIFont systemFontOfSize:16];
    contentTV.delegate = self;
    if (self.defaultText) {
        contentTV.text = self.defaultText;
        contentTV.selectedRange = self.defaultSelectedRange;
    } else {
        contentTV.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"draft"];
    }
    
    toolbar =[UIImageView viewStrechedNamed:@"button-bar-background"];
    [self.view addSubview:toolbar];
    toolbar.userInteractionEnabled = YES;
    
    photoBnt = [[UIButton alloc] init];
    [toolbar addSubview:photoBnt];
    [photoBnt addTarget:self action:@selector(photoButtonTouched) forControlEvents:UIControlEventTouchUpInside];
    [photoBnt setImage:[UIImage imageNamed:@"button-bar-camera"] forState:UIControlStateNormal];
    photoBnt.showsTouchWhenHighlighted = YES;
    [photoBnt sizeToFit];
    photoBnt.center = ccp(25, 20);
    photoBnt.hitTestEdgeInsets = UIEdgeInsetsMake(0, -5, 0, -5);
    
    geoBnt = [[UIButton alloc] init];
    [toolbar addSubview:geoBnt];
    [geoBnt addTarget:self action:@selector(geoButtonTouched) forControlEvents:UIControlEventTouchUpInside];
    [geoBnt setImage:[UIImage imageNamed:@"compose-geo"] forState:UIControlStateNormal];
    geoBnt.showsTouchWhenHighlighted = YES;
    [geoBnt sizeToFit];
    geoBnt.center = ccp(85, 20);
    geoBnt.hitTestEdgeInsets = UIEdgeInsetsMake(0, -5, 0, -5);
    
    geoLoadingV = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [toolbar addSubview:geoLoadingV];
    geoLoadingV.center = geoBnt.center;
    geoLoadingV.hidesWhenStopped = YES;
    
    mentionBnt = [[UIButton alloc] init];
    [toolbar addSubview:mentionBnt];
    [mentionBnt setTapTarget:self action:@selector(mentionButtonTouched)];
    [mentionBnt setImage:[UIImage imageNamed:@"button-bar-at"] forState:UIControlStateNormal];
    mentionBnt.showsTouchWhenHighlighted = YES;
    [mentionBnt sizeToFit];
    mentionBnt.center = ccp(145, 20);
    mentionBnt.hitTestEdgeInsets = UIEdgeInsetsMake(0, -5, 0, -5);
    
    tagBnt = [[UIButton alloc] init];
    [toolbar addSubview:tagBnt];
    [tagBnt setTapTarget:self action:@selector(tagButtonTouched)];
    [tagBnt setImage:[UIImage imageNamed:@"button-bar-hashtag"] forState:UIControlStateNormal];
    tagBnt.showsTouchWhenHighlighted = YES;
    [tagBnt sizeToFit];
    tagBnt.center = ccp(205, 20);
    tagBnt.hitTestEdgeInsets = UIEdgeInsetsMake(0, -5, 0, -5);
    
    wordCountL = [[UILabel alloc] init];
    [toolbar addSubview:wordCountL];
    wordCountL.font = [UIFont systemFontOfSize:14];
    wordCountL.textColor = bw(140);
    wordCountL.shadowColor = kWhiteColor;
    wordCountL.shadowOffset = ccs(0, 1);
    wordCountL.backgroundColor = kClearColor;
    wordCountL.text = S(@"%d", kMaxWordLen);
    [wordCountL sizeToFit];
    wordCountL.center = ccp(294, 20);
    
    nippleIV = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"compose-nipple"]];
    [toolbar addSubview:nippleIV];
    nippleIV.center = photoBnt.center;
    nippleIV.bottom = toolbar.height + 1;
    
    extraPanelSV = [[UIScrollView alloc] init];
    [self.view addSubview:extraPanelSV];
    extraPanelSV.left = 0;
    extraPanelSV.width = self.view.width;
    extraPanelSV.pagingEnabled = YES;
    extraPanelSV.delegate = self;
    extraPanelSV.showsHorizontalScrollIndicator = NO;
    extraPanelSV.showsVerticalScrollIndicator = NO;
    extraPanelSV.backgroundColor = bw(232);
    extraPanelSV.alwaysBounceVertical = NO;
    
    previewIV = [[UIImageView alloc] init];
    [extraPanelSV addSubview:previewIV];
    previewIV.hidden = YES;
    previewIV.layer.cornerRadius = 3;
    
    previewCloseBnt = [[UIButton alloc] init];
    [extraPanelSV addSubview:previewCloseBnt];
    [previewCloseBnt setTapTarget:self action:@selector(previewCloseButtonTouched)];
    previewCloseBnt.hidden = YES;
    [previewCloseBnt setImage:[UIImage imageNamed:@"UIBlackCloseButton"] forState:UIControlStateNormal];
    [previewCloseBnt setImage:[UIImage imageNamed:@"UIBlackCloseButtonPressed"] forState:UIControlStateHighlighted];
    [previewCloseBnt sizeToFit];
    
    mapView = [[MKMapView alloc] init]; // todo: this MapView make many warning echo
    [extraPanelSV addSubview:mapView];
    mapView.zoomEnabled = NO;
    mapView.scrollEnabled = NO;
    mapView.frame = ccr(extraPanelSV.width + 10, 10, extraPanelSV.width - 20, 125);
    mapOutlineIV = [UIImageView viewStrechedNamed:@"compose-map-outline"];
    [extraPanelSV addSubview:mapOutlineIV];
    mapOutlineIV.frame = mapView.frame;
    
    locationL = [[UILabel alloc] init];
    [extraPanelSV addSubview:locationL];
    locationL.backgroundColor = kClearColor;
    locationL.font = [UIFont systemFontOfSize:14];
    locationL.textColor = bw(140);
    locationL.shadowColor = kWhiteColor;
    locationL.shadowOffset = ccs(0, 1);
    locationL.textAlignment = NSTextAlignmentCenter;
    locationL.numberOfLines = 1;
    locationL.frame = ccr(mapView.left, mapView.bottom, mapView.width, 30);
    
    toggleLocationBnt = [[UIButton alloc] init];
    [extraPanelSV addSubview:toggleLocationBnt];
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
    
    suggestionsTV = [[UITableView alloc] init];
    [self.view addSubview:suggestionsTV];
    suggestionsTV.hidden = YES;
    suggestionsTV.delegate = self;
    suggestionsTV.dataSource = self;
    suggestionsTV.width = self.view.width;
    suggestionsTV.rowHeight = 37;
    suggestionsTV.backgroundColor = bw(232);
    suggestionsTV.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    [suggestionsTV registerClass:[HSUSuggestMentionCell class] forCellReuseIdentifier:[[HSUSuggestMentionCell class] description]];
    
    contentShadowV = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"searches-top-shadow.png"] stretchableImageFromCenter]];
    [self.view addSubview:contentShadowV];
    contentShadowV.hidden = YES;
    contentShadowV.width = suggestionsTV.width;
    
    if (self.defaultImage) {
        postImage = self.defaultImage;
    }
    
    CGFloat toolbarHeight = 40;
    
    contentTV.frame = ccr(0, 0, self.view.width, self.view.height- MAX(keyboardHeight, 216)-toolbarHeight);
    toolbar.frame = ccr(0, contentTV.bottom, self.view.width, toolbarHeight);
    extraPanelSV.top = toolbar.bottom;
    extraPanelSV.height = self.view.height - extraPanelSV.top;
    extraPanelSV.contentSize = ccs(extraPanelSV.width*2, extraPanelSV.height);
    previewIV.frame = ccr(30, 30, extraPanelSV.width-60, extraPanelSV.height-60);
    previewCloseBnt.center = previewIV.rightTop;
    toggleLocationBnt.bottom = extraPanelSV.height - 10;
    suggestionsTV.top = contentTV.top + 45;
    contentShadowV.top = suggestionsTV.top;
    
    if (postImage) {
        [self photoButtonTouched];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (lifeCycleCount == 0) {
        [contentTV becomeFirstResponder];
    }
    [self textViewDidChange:contentTV];
    contentChanged = NO;
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    locationManager.pausesLocationUpdatesAutomatically = YES;
    
    NSString *friendsFileName = dp(@"tweet4china.friends");
    NSData *json = [NSData dataWithContentsOfFile:friendsFileName];
    if (json) {
        friends = [NSJSONSerialization JSONObjectWithData:json options:0 error:nil];
    }
    __weak typeof(self)weakSelf = self;
    [twitter getFriendsWithCount:100 success:^(id responseObj) {
        friends = responseObj[@"users"];
        NSData *json = [NSJSONSerialization dataWithJSONObject:friends options:0 error:nil];
        [json writeToFile:friendsFileName atomically:NO];
        [weakSelf filterSuggestions];
    } failure:^(NSError *error) {
        
    }];
    
    NSString *trendsFileName = dp(@"tweet4china.trends");
    json = [NSData dataWithContentsOfFile:trendsFileName];
    if (json) {
        trends = [NSJSONSerialization JSONObjectWithData:json options:0 error:nil];
    }
    [twitter getTrendsWithSuccess:^(id responseObj) {
        trends = responseObj[0][@"trends"];
        NSData *json = [NSJSONSerialization dataWithJSONObject:trends options:0 error:nil];
        [json writeToFile:trendsFileName atomically:NO];
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf filterSuggestions];
        });
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

    lifeCycleCount ++;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    CGFloat toolbarHeight = 40;
    
    contentTV.frame = ccr(0, 0, self.view.width, self.view.height - MAX(keyboardHeight, 216)-toolbarHeight);
    toolbar.frame = ccr(0, contentTV.bottom, self.view.width, toolbarHeight);
    extraPanelSV.top = toolbar.bottom;
    extraPanelSV.height = self.view.height - extraPanelSV.top;
    extraPanelSV.contentSize = ccs(extraPanelSV.width*2, extraPanelSV.height);
    previewIV.frame = ccr(30, 30, extraPanelSV.width-60, extraPanelSV.height-60);
    previewCloseBnt.center = previewIV.rightTop;
    toggleLocationBnt.bottom = extraPanelSV.height - 10;
    suggestionsTV.top = contentTV.top + 45;
    contentShadowV.top = suggestionsTV.top;
    
    if (suggestionType) {
        suggested = YES;
        suggestionsTV.hidden = NO;
        contentShadowV.hidden = NO;
        contentTV.height = kSingleLineHeight;
        suggestionsTV.height = self.view.height - suggestionsTV.top - keyboardHeight;
        if (Sys_Ver >= 7) {
            contentTV.top = 54;
            suggestionsTV.top = contentTV.top + 45;
            contentShadowV.top = suggestionsTV.top;
            suggestionsTV.height -= 54;
        }
        [contentTV scrollRangeToVisible:contentTV.selectedRange];
    } else {
        suggestionsTV.hidden = YES;
        contentShadowV.hidden = YES;
        if (suggested) {
            NSRange selectedRange = contentTV.selectedRange;
            NSString *text = contentTV.text;
            contentTV.text = nil;
            dispatch_async(dispatch_get_main_queue(), ^{
                contentTV.text = text;
                contentTV.selectedRange = selectedRange;
            });
        }
    }
}

- (void)keyboardFrameChanged:(NSNotification *)notification
{
    NSValue* keyboardFrame = [notification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey];
    keyboardHeight = keyboardFrame.CGRectValue.size.height;
    [self.view setNeedsLayout];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    nippleIV.hidden = NO;
}

- (void)keyboardWillShow:(NSNotification *)notification {
    nippleIV.hidden = YES;
}

- (void)cancelCompose
{
    if (self.draft) {
        NSData *imageData = UIImageJPEGRepresentation(postImage, 0.92);
        [[HSUDraftManager shared] saveDraftWithDraftID:self.draft[@"id"] title:self.title status:contentTV.text imageData:imageData reply:self.inReplyToStatusId locationXY:location placeId:geoCode];
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    if (contentChanged || postImage) {
        if ([textAtFist isEqualToString:contentTV.text]) {
            [self dismiss];
            return;
        }
        if (contentTV.text.length == 0 && !postImage) {
            [self dismiss];
            return;
        }
        RIButtonItem *cancelBnt = [RIButtonItem itemWithLabel:_("Cancel")];
        RIButtonItem *giveUpBnt = [RIButtonItem itemWithLabel:_("Don't Save")];
        giveUpBnt.action = ^{
            [self dismissViewControllerAnimated:YES completion:nil];
        };
        RIButtonItem *saveBnt = [RIButtonItem itemWithLabel:_("Save Draft")];
        saveBnt.action = ^{
            NSString *status = contentTV.text;
            NSData *imageData = UIImageJPEGRepresentation(postImage, 0.92);
            NSDictionary *draft = [[HSUDraftManager shared] saveDraftWithDraftID:nil title:self.title status:status imageData:imageData reply:self.inReplyToStatusId locationXY:location placeId:geoCode];
            [[HSUDraftManager shared] activeDraft:draft];
            [self dismissViewControllerAnimated:YES completion:nil];
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
    if (contentTV.text == nil && postImage == nil) return;
    NSString *status = contentTV.text;
    //save draft
    NSData *imageData = UIImageJPEGRepresentation(postImage, 0.92);
    NSDictionary *draft = [[HSUDraftManager shared] saveDraftWithDraftID:self.draft[@"id"] title:self.title status:status imageData:imageData reply:self.inReplyToStatusId locationXY:location placeId:geoCode];
    
    if (photoEdited) {
        UIImageWriteToSavedPhotosAlbum(postImage, 0, 0, 0);
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
    NSString *newText = [contentTV.text stringByReplacingCharactersInRange:range withString:text];
    if (newText.length < textView.text.length) { // return YES for deleting text
        return YES;
    }
    return ([TwitterText tweetLength:newText] <= 140);
}

- (void)textViewDidChange:(UITextView *)textView {
    NSUInteger wordLen = [TwitterText tweetLength:contentTV.text];
    if (wordLen > 0 || postImage) {
        self.navigationItem.rightBarButtonItem.enabled = YES;
    } else {
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
    wordCountL.text = S(@"%d", kMaxWordLen-wordLen);
    
    [self filterSuggestions];
    
    contentChanged = YES;
}

- (void)filterSuggestions {
    if (suggestionType) {
        NSInteger len = contentTV.selectedRange.location-filterLocation;
        if (len >= 0) {
            NSString *filterText = [contentTV.text substringWithRange:NSMakeRange(filterLocation, len)];
            NSString *trimmedText = [filterText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if (![trimmedText isEqualToString:filterText]) {
                suggestionType = 0;
                filteredSuggestions = nil;
                [self.view setNeedsLayout];
            }
            if (suggestionType == kSuggestionType_Mention && friends) {
                if (filterText && filterText.length) {
                    if (filteredSuggestions == nil) {
                        filteredSuggestions = [NSMutableArray array];
                    } else {
                        [filteredSuggestions removeAllObjects];
                    }
                    for (NSDictionary *friend in friends) {
                        NSString *screenName = friend[@"screen_name"];
                        if ([screenName rangeOfString:filterText].location != NSNotFound) {
                            [filteredSuggestions addObject:friend];
                        }
                    }
                } else {
                    filteredSuggestions = [friends mutableCopy];
                }
            } else if (suggestionType == kSuggestionType_Tag && trends) {
                if (filterText && filterText.length) {
                    if (filteredSuggestions == nil) {
                        filteredSuggestions = [NSMutableArray array];
                    } else {
                        [filteredSuggestions removeAllObjects];
                    }
                    for (NSDictionary *trend in trends) {
                        NSString *tag = [[trend[@"name"] substringFromIndex:1] lowercaseString];
                        if (tag && [tag rangeOfString:filterText].location != NSNotFound) {
                            [filteredSuggestions addObject:trend];
                        }
                    }
                } else {
                    filteredSuggestions = [trends mutableCopy];
                }
            }
            [suggestionsTV reloadData];
        } else {
            suggestionType = 0;
            filteredSuggestions = nil;
            [self.view setNeedsLayout];
        }
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView.width) {
        CGFloat left = photoBnt.center.x - nippleIV.width / 2;
        CGFloat right = geoBnt.center.x - nippleIV.width / 2;
        nippleIV.left = left + (right - left) * scrollView.contentOffset.x / scrollView.width;
    }
}

#pragma mark - Actions
- (void)photoButtonTouched {
    if (postImage && !previewIV.image) {
        [self photoSelected:postImage];
    }
    if (contentTV.isFirstResponder || extraPanelSV.contentOffset.x > 0) {
        [contentTV resignFirstResponder];
        [extraPanelSV setContentOffset:ccp(0, 0) animated:YES];
    } else {
        [contentTV becomeFirstResponder];
    }
    if (!postImage) {
        [self selectPhoto];
    }
}

- (void)photoSelected:(UIImage *)photo {
    postImage = photo;
    CGFloat height = previewIV.height / previewIV.width * photo.size.width;
    CGFloat top = photo.size.height/2 - height/2;
    CGImageRef imageRef = CGImageCreateWithImageInRect(photo.CGImage, ccr(0, top, photo.size.width, height));
    previewIV.image = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    previewIV.hidden = NO;
    previewCloseBnt.hidden = NO;
    [photoBnt setImage:[UIImage imageNamed:@"button-bar-camera-glow"] forState:UIControlStateNormal];
//    UIImageWriteToSavedPhotosAlbum(photo, nil, nil, nil);
    self.navigationItem.rightBarButtonItem.enabled = YES;
}

- (void)previewCloseButtonTouched {
    previewCloseBnt.hidden = YES;
    [UIView animateWithDuration:0.2 animations:^{
        previewIV.transform = CGAffineTransformMakeScale(0, 0);
        previewIV.alpha = 0;
        previewIV.center = extraPanelSV.boundsCenter;
    } completion:^(BOOL finished) {
        postImage = nil;
        previewIV.image = nil;
        previewIV.hidden = YES;
        previewIV.transform = CGAffineTransformMakeTranslation(1, 1);
        previewIV.alpha = 1;
        previewIV.center = extraPanelSV.boundsCenter;
    }];
    
    [photoBnt setImage:[UIImage imageNamed:@"button-bar-camera"] forState:UIControlStateNormal];
    [self selectPhoto];
}

- (void)geoButtonTouched {
    if (contentTV.isFirstResponder ||  extraPanelSV.contentOffset.x == 0) {
        if (contentTV.isFirstResponder) {
            [locationManager startUpdatingLocation];
            geoBnt.hidden = YES;
            [geoLoadingV startAnimating];
            [toggleLocationBnt setTitle:_("Turn off location") forState:UIControlStateNormal];
            mapOutlineIV.backgroundColor = kClearColor;
        }

        [extraPanelSV setContentOffset:ccp(extraPanelSV.width, 0) animated:YES];
        [contentTV resignFirstResponder];
    } else {
        [contentTV becomeFirstResponder];
    }
}

- (void)toggleLocationButtonTouched {
    if (toggleLocationBnt.tag) {
        [contentTV becomeFirstResponder];
        [geoBnt setImage:[UIImage imageNamed:@"compose-geo"] forState:UIControlStateNormal];
        geoBnt.hidden = NO;
        [locationManager stopUpdatingLocation];
        [toggleLocationBnt setTitle:_("Turn on location") forState:UIControlStateNormal];
        [mapView removeAnnotations:mapView.annotations];
        mapOutlineIV.backgroundColor = rgba(1, 1, 1, 0.2);
        toggleLocationBnt.tag = 0;
        [geoLoadingV stopAnimating];
    } else {
        [locationManager startUpdatingLocation];
        geoBnt.hidden = YES;
        [geoLoadingV startAnimating];
        [toggleLocationBnt setTitle:_("Turn off location") forState:UIControlStateNormal];
        mapOutlineIV.backgroundColor = kClearColor;
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    if (manager.location.horizontalAccuracy <= 50 && manager.location.verticalAccuracy <= 50) {
        [manager stopUpdatingLocation];
    }
    
    CLGeocoder *geoCoder = [[CLGeocoder alloc] init];
    [geoCoder reverseGeocodeLocation:manager.location completionHandler:^(NSArray *placemarks, NSError *error) {
        for (CLPlacemark * placemark in placemarks) {
            locationL.text = placemark.name;
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
                locationL.text = placeName;
                geoCode = placeId;
            }
        }
    } failure:^(NSError *error) {
        
    }];
    
    [geoBnt setImage:[UIImage imageNamed:@"compose-geo-highlighted"] forState:UIControlStateNormal];
    geoBnt.hidden = NO;
    [geoLoadingV stopAnimating];
    toggleLocationBnt.tag = 1;
    
    location = manager.location.coordinate;
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(location, 200, 200);
    MKCoordinateRegion adjustedRegion = [mapView regionThatFits:viewRegion];
    [mapView setRegion:adjustedRegion animated:YES];
    [mapView setCenterCoordinate:location animated:YES];
    
    HSULocationAnnotation *annotation = [[HSULocationAnnotation alloc] init];
    annotation.coordinate = location;
    [mapView removeAnnotations:mapView.annotations];
    [mapView addAnnotation:annotation];
}

- (void)mentionButtonTouched {
    NSRange range = contentTV.selectedRange;
    if (range.location == NSNotFound)
        range = NSMakeRange(0, 0);
    contentTV.text = [contentTV.text stringByReplacingCharactersInRange:range withString:@"@"];
    [contentTV becomeFirstResponder];
    contentTV.selectedRange = NSMakeRange(range.location+1, 0);
    suggestionType = kSuggestionType_Mention;
    filterLocation = contentTV.selectedRange.location;
    filteredSuggestions = [friends mutableCopy];
    [suggestionsTV reloadData];
    [self.view setNeedsLayout];
}

- (void)tagButtonTouched {
    NSRange range = contentTV.selectedRange;
    if (range.location == NSNotFound)
        range = NSMakeRange(0, 0);
    contentTV.text = [contentTV.text stringByReplacingCharactersInRange:range withString:@"#"];
    [contentTV becomeFirstResponder];
    contentTV.selectedRange = NSMakeRange(range.location+1, 0);
    suggestionType = kSuggestionType_Tag;
    filterLocation = contentTV.selectedRange.location;
    filteredSuggestions = [trends mutableCopy];
    [suggestionsTV reloadData];
    [self.view setNeedsLayout];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return MIN(filteredSuggestions.count, 30);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (suggestionType == kSuggestionType_Mention) {
        HSUSuggestMentionCell *cell = [tableView dequeueReusableCellWithIdentifier:[[HSUSuggestMentionCell class] description] forIndexPath:indexPath];
        NSDictionary *friend = filteredSuggestions[indexPath.row];
        NSString *avatar = friend[@"profile_image_url_https"];
        NSString *name = friend[@"name"];
        NSString *screenName = friend[@"screen_name"];
        [cell setAvatar:avatar name:name screenName:screenName];
        return cell;
    } else if (suggestionType == kSuggestionType_Tag) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"HSUSuggestTagCell"];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"HSUSuggestTagCell"];
        }
        NSDictionary *trend = filteredSuggestions[indexPath.row];
        NSString *tag = [trend[@"name"] substringFromIndex:1];
        cell.textLabel.text = tag;
        return cell;
    }

    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *replacement = nil;
    if (suggestionType == kSuggestionType_Mention) {
        NSDictionary *friend = filteredSuggestions[indexPath.row];
        replacement = S(@"%@ ", friend[@"screen_name"]);
    } else if (suggestionType == kSuggestionType_Tag) {
        NSDictionary *trend = filteredSuggestions[indexPath.row];
        replacement = S(@"%@ ", [trend[@"name"] substringFromIndex:1]);
    }
    NSRange range = NSMakeRange(filterLocation, contentTV.selectedRange.location - filterLocation);
    if ([self textView:contentTV shouldChangeTextInRange:range replacementText:replacement]) {
        contentTV.text = [contentTV.text stringByReplacingCharactersInRange:range withString:replacement];
        [self textViewDidChange:contentTV];
        contentTV.selectedRange = NSMakeRange(range.location+replacement.length, 0);
    }
    suggestionType = 0;
    filteredSuggestions = nil;
    [self.view setNeedsLayout];
}

- (BOOL)shouldAutorotate
{
    return NO;
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:nil];
    [contentTV becomeFirstResponder];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = info[UIImagePickerControllerEditedImage] ?: info[UIImagePickerControllerOriginalImage];
    image = image.imageRotatedToUp;
    [self photoSelected:image];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)selectPhoto
{
    OCMCameraViewController *cameraVC = [OpenCam cameraViewController];
    cameraVC.maxWidth = 640;
    cameraVC.delegate = self;
    [self presentViewController:cameraVC animated:YES completion:nil];
    [Flurry logEvent:@"start_opencam"];
}

@end
