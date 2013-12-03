//
//  HSUListViewController.m
//  Tweet4China
//
//  Created by Jason Hsu on 2013/12/2.
//  Copyright (c) 2013年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUListViewController.h"
#import "HSUListTweetsDataSource.h"

@interface HSUListViewController ()

@end

@implementation HSUListViewController

- (instancetype)initWithDataSource:(HSUListTweetsDataSource *)dataSource
{
    self = [super init];
    if (self) {
        self.dataSource = dataSource;
        self.useRefreshControl = YES;
    }
    return self;
}

@end
