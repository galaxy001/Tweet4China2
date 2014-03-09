//
//  T4CNewFollersViewController.m
//  Tweet4China
//
//  Created by Jason Hsu on 14-2-5.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "T4CNewFollowersViewController.h"

@interface T4CNewFollowersViewController ()

@end

@implementation T4CNewFollowersViewController

- (id)init
{
    self = [super init];
    if (self) {
        self.useCache = NO;
        self.pullToRefresh = NO;
        self.infiniteScrolling = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    for (NSDictionary *user in self.followers) {
        T4CTableCellData *cellData = [self createTableCellDataWithRawData:user];
        [self.data addObject:cellData];
    }
}

@end
