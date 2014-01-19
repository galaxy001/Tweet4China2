//
//  HSUSelectListsViewController.h
//  Tweet4China
//
//  Created by Jason Hsu on 14-1-19.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUBaseViewController.h"

@interface HSUSelectListsViewController : HSUBaseViewController

- (id)initWithMyLists:(NSArray *)myLists listedLists:(NSArray *)listedLists user:(NSString *)screenName;

@end
