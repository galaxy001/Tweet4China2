//
//  HSUGalleryView.m
//  Tweet4China
//
//  Created by Jason Hsu on 4/26/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "HSUGalleryView.h"
#import "AFNetworking.h"
#import "HSUStatusActionView.h"
#import "HSUStatusView.h"
#import "HSUStatusViewController.h"

@interface HSUGalleryView() <UIScrollViewDelegate>

@property (nonatomic, weak) UIActivityIndicatorView *spinner;
@property (nonatomic, weak) UIImageView *imageView;

@end

@implementation HSUGalleryView
{
    UIScrollView *imagePanel;
    HSUStatusView *statusView;
    
    HSUTableCellData *cellData;
}

- (void)dealloc
{
    notification_remove_observer(self);
}

- (id)_initWithData:(HSUTableCellData *)data
{
    self = [super initWithFrame:[UIApplication sharedApplication].keyWindow.bounds];
    if (self) {
        cellData = data;
        
        self.backgroundColor = kBlackColor;
        self.alpha = 0;
        
        // subviews
        imagePanel = [[UIScrollView alloc] initWithFrame:self.bounds];
        [self addSubview:imagePanel];
        imagePanel.contentSize = self.size;
        imagePanel.delegate = self;
        
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        [imagePanel addSubview:imageView];
        self.imageView = imageView;
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        
        UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        [self addSubview:spinner];
        self.spinner = spinner;
        spinner.transform = CGAffineTransformMakeScale(0.7, 0.7);
        spinner.center = self.boundsCenter;
        
        // gestures
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] init];
        [tapGesture addTarget:self action:@selector(_fireTapGesture:)];
        [self addGestureRecognizer:tapGesture];
        
        UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] init];
        [longPressGesture addTarget:self action:@selector(_fireLongPressGesture:)];
        [self addGestureRecognizer:longPressGesture];
        
        // rotate
        notification_add_observer(UIDeviceOrientationDidChangeNotification, self, @selector(deviceOrientationDidChange:));
    }
    return self;
}

- (id)initWithData:(HSUTableCellData *)data image:(UIImage *)image
{
    self = [self _initWithData:data];
    if (self) {
        [self.imageView setImage:image];
        [self.imageView sizeToFit];
        float zoomScale = 0;
        if (self.imageView.width / self.imageView.height > self.width / self.height) {
            zoomScale = self.width / self.imageView.width;
        } else {
            zoomScale = self.height / self.imageView.height;
        }
        imagePanel.maximumZoomScale = 2 * zoomScale;
        imagePanel.minimumZoomScale = zoomScale;
        imagePanel.zoomScale = zoomScale;
    }
    return self;
}

- (id)initWithData:(HSUTableCellData *)data imageURL:(NSURL *)imageURL
{
    self = [self _initWithData:data];
    if (self) {
        [self.spinner startAnimating];
        __weak typeof(&*self)weakSelf = self;
        [self.imageView setImageWithURLRequest:[NSURLRequest requestWithURL:imageURL] placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
            weakSelf.imageView.image = image;
            float zoomScale = 0;
            if (weakSelf.imageView.width / weakSelf.imageView.height > weakSelf.width / weakSelf.height) {
                zoomScale = weakSelf.width / weakSelf.imageView.width;
            } else {
                zoomScale = weakSelf.height / weakSelf.imageView.height;
            }
            imagePanel.maximumZoomScale = 2 * zoomScale;
            imagePanel.minimumZoomScale = zoomScale;
            imagePanel.zoomScale = zoomScale;
            [weakSelf.spinner stopAnimating];
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
            [weakSelf.spinner stopAnimating];
        }];
    }
    return self;
}

- (void)showWithAnimation:(BOOL)animation
{
    if (!RUNNING_ON_IOS_7) {
        [[UIApplication sharedApplication] setStatusBarHidden:YES];
    }
    if (animation) {
        [UIView animateWithDuration:.3 animations:^{
            self.alpha = 1;
        } completion:^(BOOL finished) {
            if (RUNNING_ON_IOS_7) {
                notification_post(HSUGalleryViewDidAppear);
            }
        }];
    } else {
        self.alpha = 1;
        if (RUNNING_ON_IOS_7) {
            notification_post(HSUGalleryViewDidAppear);
        }
    }
}

- (void)_fireTapGesture:(UIGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateEnded) {
        if (RUNNING_ON_IOS_7) {
            notification_post(HSUGalleryViewDidDisappear);
        } else {
            [[UIApplication sharedApplication] setStatusBarHidden:NO];
        }
        [UIView animateWithDuration:.3 animations:^{
            self.alpha = 0;
        } completion:^(BOOL finished) {
            [self removeFromSuperview];
        }];
    }
}

- (void)_fireLongPressGesture:(UIGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateEnded) {
        RIButtonItem *cancelItem = [RIButtonItem itemWithLabel:@"Cancel"];
        RIButtonItem *saveItem = [RIButtonItem itemWithLabel:@"Save image"];
        saveItem.action = ^{
            UIImageWriteToSavedPhotosAlbum(self.imageView.image, nil, nil, nil);
        };
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil cancelButtonItem:cancelItem destructiveButtonItem:nil otherButtonItems:saveItem, nil];
        [actionSheet showInView:self.window];
    }
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}

- (void)deviceOrientationDidChange:(NSNotification *)notification
{
    [UIView animateWithDuration:.3 animations:^{
        UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
        if (orientation == UIDeviceOrientationLandscapeLeft) {
            imagePanel.transform = CGAffineTransformMakeRotation(M_PI/2);
            imagePanel.bounds = ccr(0, 0, kScreenHeight, kScreenWidth);
        } else if (orientation == UIDeviceOrientationLandscapeRight) {
            imagePanel.transform = CGAffineTransformMakeRotation(-M_PI/2);
            imagePanel.bounds = ccr(0, 0, kScreenHeight, kScreenWidth);
        } else if (orientation == UIDeviceOrientationPortrait) {
            imagePanel.transform = CGAffineTransformMakeRotation(0);
            imagePanel.bounds = ccr(0, 0, kScreenWidth, kScreenHeight);
        } else if (orientation == UIDeviceOrientationPortraitUpsideDown) {
            imagePanel.transform = CGAffineTransformMakeRotation(-M_PI);
            imagePanel.bounds = ccr(0, 0, kScreenWidth, kScreenHeight);
        }
        
        self.imageView.frame = imagePanel.bounds;
    }];
}

@end
