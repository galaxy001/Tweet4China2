//
//  HSUiPadTabController.h
//  Tweet4China
//
//  Created by Jason Hsu on 10/31/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol HSUiPadTabControllerDelegate;

@interface HSUiPadTabController : UIViewController

@property (nonatomic, weak) id<HSUiPadTabControllerDelegate> delegate;

- (void)showUnreadIndicatorOnViewController:(UIViewController *)viewController;
- (void)hideUnreadIndicatorOnViewController:(UIViewController *)viewController;
- (BOOL)hasUnreadIndicatorOnViewController:(UIViewController *)viewController;

@end

@protocol HSUiPadTabControllerDelegate <NSObject>

- (BOOL)tabBarController:(HSUiPadTabController *)tabController shouldSelectViewController:(UIViewController *)viewController;

@end
