//
//  HSUEditListViewController.h
//  Tweet4China
//
//  Created by Jason Hsu on 14-1-11.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol HSUEditListViewControllerDelegate;

@interface HSUEditListViewController : UITableViewController

- (instancetype)initWithList:(NSDictionary *)list;

@property (nonatomic, weak) id<HSUEditListViewControllerDelegate> delegate;

@end

@protocol HSUEditListViewControllerDelegate <NSObject>

- (void)editListViewControllerDidSaveList:(NSDictionary *)list;

@end