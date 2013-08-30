//
//  HSUHomeViewController.m
//  Tweet4China
//
//  Created by Jason Hsu on 2/28/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUHomeViewController.h"
#import "HSUHomeDataSource.h"

@interface HSUHomeViewController ()

@end

@implementation HSUHomeViewController

- (id)init
{
    self = [super init];
    if (self) {
        self.dataSourceClass = [HSUHomeDataSource class];
        [HSUHomeDataSource checkUnreadForViewController:self];
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [(HSUHomeDataSource *)self.dataSource authenticateWithSuccess:^(id responseObj) {
        [self.refreshControl beginRefreshing];
        [self.dataSource refresh];
    } failure:^(NSError *error){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Authorize Error" message:error.description delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
    }];
}

#pragma mark - dataSource delegate
- (void)dataSourceDidFindUnread:(HSUBaseDataSource *)dataSource
{
    [super dataSourceDidFindUnread:dataSource];
}


@end
