//
//  HSUDiscoverViewController.h
//  Tweet4China
//
//  Created by Jason Hsu on 2/28/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HSUBaseViewController.h"

@interface HSUDiscoverViewController : HSUBaseViewController

@property (nonatomic, strong) UITextField *urlTextField;
@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, copy) NSString *startUrl;

@end
