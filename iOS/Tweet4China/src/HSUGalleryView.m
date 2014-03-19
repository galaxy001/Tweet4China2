//
//  HSUGalleryView.m
//  Tweet4China
//
//  Created by Jason Hsu on 4/26/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUGalleryView.h"
#import "HSUStatusActionView.h"
#import "HSUStatusView.h"

@interface HSUGalleryView() <UIScrollViewDelegate>

@property (nonatomic, weak) UIActivityIndicatorView *spinner;
@property (nonatomic, weak) UIView *startPhotoView;
@property (nonatomic, assign) UIDeviceOrientation imageOrientation;
@property (nonatomic, assign) BOOL detectedOrientation;

@end

@implementation HSUGalleryView
{
    UIScrollView *imagePanel;
    HSUStatusView *statusView;
    
    T4CTableCellData *cellData;
}

- (void)dealloc
{
    notification_remove_observer(self);
    imagePanel.delegate = nil;
}

- (id)initWithData:(T4CTableCellData *)data
{
    self = [super initWithFrame:[UIApplication sharedApplication].keyWindow.bounds];
    if (self) {
        cellData = data;
        
        self.backgroundColor = kBlackColor;
        
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

- (id)initWithData:(T4CTableCellData *)data image:(UIImage *)image
{
    self = [self initWithData:data];
    if (self) {
        [self.imageView setImage:image];
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

- (id)initWithData:(T4CTableCellData *)data imageURL:(NSURL *)imageURL
{
    self = [self initWithData:data];
    if (self) {
        [self.spinner startAnimating];
        __weak typeof(&*self)weakSelf = self;
        [self.imageView setImageWithUrlStr:imageURL.absoluteString placeHolder:nil success:^{
            [weakSelf.spinner stopAnimating];
        } failure:^{
            [weakSelf.spinner stopAnimating];
        }];
    }
    return self;
}

- (id)initWithData:(T4CTableCellData *)data previewImage:(UIImage *)previewImage originalImageURL:(NSURL *)originalImageURL
{
    self = [self initWithData:data];
    if (self) {
        [self.spinner startAnimating];
        __weak typeof(&*self)weakSelf = self;
        [self.imageView setImageWithUrlStr:originalImageURL.absoluteString placeHolder:previewImage success:^{
            [weakSelf.spinner stopAnimating];
        } failure:^{
            [weakSelf.spinner stopAnimating];
        }];
        
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

- (id)initStartPhotoView:(UIView *)startPhotoView originalImageURL:(NSURL *)originalImageURL
{
    self = [self initWithData:nil];
    if (self) {
        self.startPhotoView = startPhotoView;
        UIImage *previewImage = [startPhotoView isKindOfClass:[UIButton class]] ? [((UIButton *)startPhotoView) imageForState:UIControlStateNormal] : ((UIImageView *)startPhotoView).image;
        if (originalImageURL) {
            [self.spinner startAnimating];
            __weak typeof(&*self)weakSelf = self;
            [self.imageView setImageWithUrlStr:originalImageURL.absoluteString placeHolder:previewImage success:^{
                [weakSelf.spinner stopAnimating];
            } failure:^{
                [weakSelf.spinner stopAnimating];
            }];
        } else {
            [self.imageView setImage:previewImage];
        }
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

- (void)showWithAnimation:(BOOL)animation
{
    if (Sys_Ver < 7) {
        [[UIApplication sharedApplication] setStatusBarHidden:YES];
    }
    [self resetImageOrientation];
    if (animation) {
        if (IPAD || UIDeviceOrientationIsLandscape(self.imageOrientation) || !self.startPhotoView) {
            self.alpha = 0;
            [UIView animateWithDuration:.3 animations:^{
                self.alpha = 1;
            } completion:^(BOOL finished) {
                if (Sys_Ver >= 7) {
                    notification_post(HSUGalleryViewDidAppear);
                }
            }];
        } else {
            CGRect photoButtonFrameInGallery =
            [self.startPhotoView.superview convertRect:self.startPhotoView.frame
                                                toView:self];
            self.imageView.frame = photoButtonFrameInGallery;
            self.imageView.contentMode = UIViewContentModeScaleAspectFill;
            self.imageView.clipsToBounds = YES;
            self.backgroundColor = kClearColor;
            
            __weak typeof(self)weakSelf = self;
            [UIView animateWithDuration:.1 animations:^{
                weakSelf.backgroundColor = kBlackColor;
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:.3 animations:^{
                    CGRect frame;
                    CGSize size = weakSelf.size;
                    if (weakSelf.imageView.image) {
                        if (IPHONE) {
                            CGFloat dstHeight = size.width * weakSelf.imageView.image.size.height / weakSelf.imageView.image.size.width;
                            if (dstHeight > [HSUCommonTools winHeight]) {
                                size.height = [HSUCommonTools winHeight];
                                size.width = weakSelf.imageView.image.size.width / weakSelf.imageView.image.size.height * [HSUCommonTools winHeight];
                            } else {
                                size.height = dstHeight;
                            }
                        } else {
                            CGFloat dstWidth = size.height * weakSelf.imageView.image.size.width / weakSelf.imageView.image.size.height;
                            if (dstWidth > [HSUCommonTools winWidth]) {
                                size.width = [HSUCommonTools winWidth];
                                size.height = weakSelf.imageView.image.size.height / weakSelf.imageView.image.size.width * [HSUCommonTools winWidth];
                            } else {
                                size.width = dstWidth;
                            }
                        }
                    }
                    frame.size = size;
                    frame.origin = ccp(weakSelf.width/2-size.width/2, weakSelf.height/2-size.height/2);
                    weakSelf.imageView.frame = frame;
                } completion:^(BOOL finished) {
                    weakSelf.imageView.frame = weakSelf.bounds;
                    weakSelf.imageView.contentMode = UIViewContentModeScaleAspectFit;
                    weakSelf.imageView.clipsToBounds = NO;
                    if (Sys_Ver >= 7) {
                        notification_post(HSUGalleryViewDidAppear);
                    }
                }];
            }];
        }
    } else {
        if (Sys_Ver >= 7) {
            notification_post(HSUGalleryViewDidAppear);
        }
    }
}

- (void)_fireTapGesture:(UIGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateEnded) {
        [self dismiss];
    }
}

- (void)dismiss
{
    if (Sys_Ver >= 7) {
        notification_post(HSUGalleryViewDidDisappear);
    } else {
        [[UIApplication sharedApplication] setStatusBarHidden:NO];
    }
    
    if (IPAD || UIDeviceOrientationIsLandscape(self.imageOrientation) || !self.startPhotoView) {
        [UIView animateWithDuration:.3 animations:^{
            self.alpha = 0;
        } completion:^(BOOL finished) {
            [self removeFromSuperview];
        }];
    } else {
        imagePanel.zoomScale = 1; // reset scale
        
        CGRect frame;
        CGSize size = self.size;
        if (IPHONE) {
            CGFloat dstHeight = size.width * self.imageView.image.size.height / self.imageView.image.size.width;
            if (dstHeight > [HSUCommonTools winHeight]) {
                size.height = [HSUCommonTools winHeight];
                size.width = self.imageView.image.size.width / self.imageView.image.size.height * [HSUCommonTools winHeight];
            } else {
                size.height = dstHeight;
            }
        } else {
            CGFloat dstWidth = size.height * self.imageView.image.size.width / self.imageView.image.size.height;
            if (dstWidth > [HSUCommonTools winWidth]) {
                size.width = [HSUCommonTools winWidth];
                size.height = self.imageView.image.size.height / self.imageView.image.size.width * [HSUCommonTools winWidth];
            } else {
                size.width = dstWidth;
            }
        }
        frame.size = size;
        frame.origin = ccp(self.width/2-size.width/2, self.height/2-size.height/2);
        self.imageView.frame = frame;
        self.imageView.contentMode = UIViewContentModeScaleAspectFill;
        self.imageView.clipsToBounds = YES;
        
        CGRect photoButtonFrameInGallery =
        [self.startPhotoView.superview convertRect:self.startPhotoView.frame
                                            toView:self];
        __weak typeof(self)weakSelf = self;
        [UIView animateWithDuration:.3 animations:^{
            weakSelf.imageView.frame = photoButtonFrameInGallery;
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:.1 animations:^{
                weakSelf.backgroundColor = kClearColor;
            } completion:^(BOOL finished) {
                [weakSelf removeFromSuperview];
            }];
        }];
    }
}

- (void)_fireLongPressGesture:(UIGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateBegan) {
        RIButtonItem *cancelItem = [RIButtonItem itemWithLabel:_("Cancel")];
        RIButtonItem *saveItem = [RIButtonItem itemWithLabel:_("Save Image")];
        __weak typeof(self)weakSelf = self;
        saveItem.action = ^{
            UIImageWriteToSavedPhotosAlbum(weakSelf.imageView.image, weakSelf, @selector(image:didFinishSavingWithError:contextInfo:), nil);
        };
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil cancelButtonItem:cancelItem destructiveButtonItem:nil otherButtonItems:saveItem, nil];
        [actionSheet showInView:self.window];
    }
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo;
{
    [self dismiss];
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}

- (void)deviceOrientationDidChange:(NSNotification *)notification
{
    __weak typeof(self)weakSelf = self;
    [UIView animateWithDuration:.3 animations:^{
        [weakSelf resetImageOrientation];
    }];
}

- (void)resetImageOrientation
{
    // TODO 为什么 Device Orientation 和 Status Orientation是反着的
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    self.imageOrientation = orientation;
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
    } else if (orientation == UIDeviceOrientationFaceUp
               || orientation == UIDeviceOrientationFaceDown) {
        
        if (self.detectedOrientation) {
            return;
        }
        
        self.detectedOrientation = YES;
        UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        if (interfaceOrientation == UIInterfaceOrientationLandscapeLeft) {
            imagePanel.transform = CGAffineTransformMakeRotation(-M_PI/2);
            imagePanel.bounds = ccr(0, 0, kScreenHeight, kScreenWidth);
        } else if (interfaceOrientation == UIInterfaceOrientationLandscapeRight) {
            imagePanel.transform = CGAffineTransformMakeRotation(M_PI/2);
            imagePanel.bounds = ccr(0, 0, kScreenHeight, kScreenWidth);
        } else if (interfaceOrientation == UIInterfaceOrientationPortrait) {
            imagePanel.transform = CGAffineTransformMakeRotation(0);
            imagePanel.bounds = ccr(0, 0, kScreenWidth, kScreenHeight);
        } else if (interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {
            imagePanel.transform = CGAffineTransformMakeRotation(-M_PI);
            imagePanel.bounds = ccr(0, 0, kScreenWidth, kScreenHeight);
        }
    }
    
    self.imageView.frame = imagePanel.bounds;
}

@end
