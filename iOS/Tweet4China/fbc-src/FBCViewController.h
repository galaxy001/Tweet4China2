//
//  FBCViewController.h
//  FB4China
//
//  Created by Jason Hsu on 14-1-18.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FBCViewController : UIViewController <UITabBarControllerDelegate>

@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, copy) NSString *address;
@property (nonatomic, assign, getter = isLogin) BOOL login;
@property (nonatomic, weak) UIActivityIndicatorView *spinner;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, readonly) NSString *currentAddress;
@property (nonatomic, copy) NSString *rootAddress;

@end
