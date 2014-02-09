//
//  HSUGalleryView.h
//  Tweet4China
//
//  Created by Jason Hsu on 4/26/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import <UIKit/UIKit.h>

@class T4CTableViewController;
@interface HSUGalleryView : UIView

@property (nonatomic, weak) T4CTableViewController *viewController;

- (id)initWithData:(T4CTableCellData *)data image:(UIImage *)image;
- (id)initWithData:(T4CTableCellData *)data imageURL:(NSURL *)imageURL;
- (id)initWithData:(T4CTableCellData *)data previewImage:(UIImage *)previewImage originalImageURL:(NSURL *)originalImageURL;

- (void)showWithAnimation:(BOOL)animation;

@end
