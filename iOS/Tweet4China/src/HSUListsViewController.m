//
//  HSUListsViewController.m
//  Tweet4China
//
//  Created by Jason Hsu on 2013/12/2.
//  Copyright (c) 2013年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUListsViewController.h"
#import "HSUSubscribedListsDataSource.h"
#import "HSUListViewController.h"

@interface HSUListsViewController ()

@end

@implementation HSUListsViewController

- (instancetype)initWithDataSource:(HSUSubscribedListsDataSource *)dataSource
{
    self = [super init];
    if (self) {
        self.dataSource = dataSource;
        self.useRefreshControl = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.dataSource loadMore];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    HSUTableCellData *data = [self.dataSource dataAtIndexPath:indexPath];
    if ([data.dataType isEqualToString:kDataType_List]) {
        return;
    }
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
}

@end
