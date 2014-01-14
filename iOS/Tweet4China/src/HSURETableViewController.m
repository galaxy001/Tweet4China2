//
//  HSURETableViewController.m
//  Tweet4China
//
//  Created by Jason Hsu on 14-1-14.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSURETableViewController.h"

#import <RETableViewManager/RETableViewManager.h>

@interface HSURETableViewController ()

@end

@implementation HSURETableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.manager = [[RETableViewManager alloc] initWithTableView:self.tableView];
}

@end
