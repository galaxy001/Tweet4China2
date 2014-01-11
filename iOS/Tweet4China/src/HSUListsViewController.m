//
//  HSUListsViewController.m
//  Tweet4China
//
//  Created by Jason Hsu on 2013/12/2.
//  Copyright (c) 2013年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUListsViewController.h"
#import "HSUListViewController.h"
#import "HSUListTweetsDataSource.h"
#import "HSUListViewController.h"
#import "HSUSubscribedListsDataSource.h"

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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    HSUTableCellData *data = [self.dataSource dataAtIndexPath:indexPath];
    if ([data.dataType isEqualToString:kDataType_List]) {
        HSUTableCellData *cellData = [self.dataSource dataAtIndexPath:indexPath];
        HSUListTweetsDataSource *dataSource = [[HSUListTweetsDataSource alloc] initWithListId:cellData.rawData[@"id"]];
        HSUListViewController *listVC = [[HSUListViewController alloc] initWithDataSource:dataSource];
        listVC.title = cellData.rawData[@"description"];
        [self.navigationController pushViewController:listVC animated:YES];
        [dataSource refresh];
        return;
    }
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
}

@end
