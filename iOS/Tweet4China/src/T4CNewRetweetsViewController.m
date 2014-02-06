//
//  T4CNewRetweetsViewController.m
//  Tweet4China
//
//  Created by Jason Hsu on 14-2-5.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "T4CNewRetweetsViewController.h"

@interface T4CNewRetweetsViewController ()

@end

@implementation T4CNewRetweetsViewController

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
    
    T4CTableCellData *statusCellData = [self createTableCellDataWithRawData:self.retweetedStatus];
    [self.data addObject:statusCellData];
    
    for (NSDictionary *user in self.retweetedStatus[@"retweeters"]) {
        T4CTableCellData *userCellData = [self createTableCellDataWithRawData:user];
        [self.data addObject:userCellData];
    }
}

@end
