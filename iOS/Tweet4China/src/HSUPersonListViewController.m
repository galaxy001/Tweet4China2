//
//  HSUPersonListViewController.m
//  Tweet4China
//
//  Created by Jason Hsu on 5/3/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUPersonListViewController.h"
#import "HSUPersonListDataSource.h"
#import "HSUProfileViewController.h"
#import "T4CPersonCellData.h"

@implementation HSUPersonListViewController

- (instancetype)initWithDataSource:(HSUPersonListDataSource *)dataSource
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
    
    self.navigationItem.rightBarButtonItem = nil;
    [self.dataSource loadMore];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    T4CTableCellData *data = [self.dataSource dataAtIndexPath:indexPath];
    if ([data.dataType isEqualToString:kDataType_Person]) {
        [self touchAvatar:data];
        return;
    }
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
}

- (void)preprocessDataSourceForRender:(HSUBaseDataSource *)dataSource
{
    [dataSource addEventWithName:@"follow" target:self action:@selector(follow:) events:UIControlEventTouchUpInside];
    [dataSource addEventWithName:@"touchAvatar" target:self action:@selector(touchAvatar:) events:UIControlEventTouchUpInside];
}

- (void)touchAvatar:(T4CTableCellData *)cellData
{
    NSString *screenName = cellData.rawData[@"screen_name"];
    HSUProfileViewController *profileVC = [[HSUProfileViewController alloc] initWithScreenName:screenName];
    profileVC.profile = cellData.rawData;
    [self.navigationController pushViewController:profileVC animated:YES];
}

- (void)follow:(T4CPersonCellData *)cellData
{
    NSString *screenName = cellData.rawData[@"screen_name"];
    cellData.sendingFollowingRequest = YES;
    [self.tableView reloadData];
    
    if ([cellData.rawData[@"following"] boolValue]) {
        __weak typeof(self)weakSelf = self;
        [twitter unFollowUser:screenName success:^(id responseObj) {
            cellData.sendingFollowingRequest = NO;
            NSMutableDictionary *rawData = cellData.rawData.mutableCopy;
            rawData[@"following"] = @(NO);
            cellData.rawData = rawData;
            [weakSelf.tableView reloadData];
        } failure:^(NSError *error) {
            [twitter dealWithError:error errTitle:_("Unfollow failed")];
        }];
    } else {
        __weak typeof(self)weakSelf = self;
        [twitter followUser:screenName success:^(id responseObj) {
            cellData.sendingFollowingRequest = NO;
            NSMutableDictionary *rawData = cellData.rawData.mutableCopy;
            rawData[@"following"] = @(YES);
            cellData.rawData = rawData;
            [weakSelf.tableView reloadData];
        } failure:^(NSError *error) {
            [twitter dealWithError:error errTitle:_("Follow failed")];
        }];
    }
}

@end
