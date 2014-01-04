//
//  HSUBaseViewController.h
//  Tweet4China
//
//  Created by Jason Hsu on 3/3/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HSUBaseDataSource.h"

@class HSURefreshControl;
@interface HSUBaseViewController : UIViewController <UITableViewDelegate, HSUBaseDataSourceDelegate>

@property (nonatomic, strong) Class dataSourceClass;
@property (nonatomic, strong) HSUBaseDataSource *dataSource;
@property (nonatomic, weak) HSURefreshControl *refreshControl;
@property (nonatomic, weak) HSUTableView *tableView;
@property (nonatomic, assign) BOOL hideBackButton;
@property (nonatomic, assign) BOOL hideRightButtons;
@property (nonatomic, assign) BOOL useRefreshControl;
@property (nonatomic, assign) uint viewDidAppearCount;
@property (nonatomic, assign) float keyboardHeight;
@property (nonatomic, assign) BOOL useDefaultStatusView;
@property (nonatomic, assign) BOOL statusBarHidden;

@property (nonatomic, readonly) UIBarButtonItem *actionBarButton;
@property (nonatomic, readonly) UIBarButtonItem *addFriendBarButton;
@property (nonatomic, readonly) UIBarButtonItem *composeBarButton;

@property (nonatomic, weak) id tabController;

- (id)initWithDataSource:(HSUBaseDataSource *)dataSource;
- (Class)cellClassForDataType:(NSString *)dataType;
- (void)presentModelClass:(Class)modelClass;
- (void)backButtonTouched;

@end
