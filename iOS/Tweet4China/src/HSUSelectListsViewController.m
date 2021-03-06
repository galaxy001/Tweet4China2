//
//  HSUSelectListsViewController.m
//  Tweet4China
//
//  Created by Jason Hsu on 14-1-19.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUSelectListsViewController.h"
#import "T4CListCellData.h"

@interface HSUSelectListsViewController ()

@property (nonatomic, strong) NSArray *listedlists;
@property (nonatomic, copy) NSString *screenName;

@end

@implementation HSUSelectListsViewController

- (id)initWithMyLists:(NSArray *)myLists listedLists:(NSArray *)listedLists user:(NSString *)screenName
{
    self = [super init];
    if (self) {
        self.listedlists = listedLists;
        self.screenName = screenName;
        NSMutableArray *data = [NSMutableArray arrayWithCapacity:myLists.count];
        for (NSDictionary *myList in myLists) {
            T4CListCellData *cellData = [[T4CListCellData alloc] initWithRawData:myList dataType:kDataType_List];
            cellData.hideCreator = YES;
            NSString *myListID = myList[@"id_str"];
            for (NSDictionary *listedList in listedLists) {
                NSString *listedListID = listedList[@"id_str"];
                if ([myListID isEqualToString:listedListID]) {
                    cellData.listed = YES;
                    break;
                }
            }
            [data addObject:cellData];
        }
        HSUBaseDataSource *dataSource = [[HSUBaseDataSource alloc] init];
        dataSource.data = data;
        self.dataSource = dataSource;
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                              initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                              target:self
                                              action:@selector(done)];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    T4CListCellData *cellData = (T4CListCellData *)[self.dataSource dataAtIndexPath:indexPath];
    cellData.listed = !cellData.listed;
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (cell.accessoryType == UITableViewCellAccessoryCheckmark) {
        cell.accessoryType = UITableViewCellAccessoryNone;
    } else {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
}

- (void)done
{
    for (T4CListCellData *cellData in self.dataSource.allData) {
        NSDictionary *myList = cellData.rawData;
        BOOL found = NO;
        if (cellData.listed) {
            for (NSDictionary *listedList in self.listedlists) {
                if ([listedList[@"id_str"] isEqualToString:myList[@"id_str"]]) {
                    found = YES;
                    break;
                }
            }
            if (!found) {
                // add member to list
                [twitter createMember:self.screenName toList:myList[@"id_str"] success:^(id responseObj) {
                    
                } failure:^(NSError *error) {
                    [SVProgressHUD showErrorWithStatus:_("Add to List failed")];
                }];
            }
        } else {
            for (NSDictionary *listedList in self.listedlists) {
                if ([listedList[@"id_str"] isEqualToString:myList[@"id_str"]]) {
                    found = YES;
                    break;
                }
            }
            if (found) {
                // remove member from list
                [twitter destroyMember:self.screenName toList:myList[@"id_str"] success:^(id responseObj) {
                    
                } failure:^(NSError *error) {
                    [SVProgressHUD showErrorWithStatus:_("Remove from List failed")];
                }];
            }
            
        }
    }
    
    [self dismiss];
}

@end
