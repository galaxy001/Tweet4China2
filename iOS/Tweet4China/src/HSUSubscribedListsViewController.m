//
//  HSUSubscribedListsViewController.m
//  Tweet4China
//
//  Created by Jason Hsu on 2013/12/2.
//  Copyright (c) 2013年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUSubscribedListsViewController.h"
#import "HSUSubscribedListsDataSource.h"

@interface HSUSubscribedListsViewController ()

@end

@implementation HSUSubscribedListsViewController

- (instancetype)initWithDataSource:(HSUSubscribedListsDataSource *)dataSource
{
    self = [super init];
    if (self) {
        self.dataSource = dataSource;
        self.useRefreshControl = NO;
    }
    return self;
}

@end
