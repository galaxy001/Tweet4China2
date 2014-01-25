//
//  HSUDraftsDataSource.m
//  Tweet4China
//
//  Created by Jason Hsu on 5/15/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUDraftsDataSource.h"
#import "HSUDraftManager.h"

@implementation HSUDraftsDataSource

- (id)init
{
    self = [super init];
    if (self) {
        [self refresh];
    }
    return self;
}

- (void)refresh
{
    [self.data removeAllObjects];
    NSArray *drafts = [[HSUDraftManager shared] draftsSortedByUpdateTime];
    for (NSDictionary *draft in drafts) {
        T4CTableCellData *cellData = [[T4CTableCellData alloc] initWithRawData:draft dataType:kDataType_Draft];
        [self.data addObject:cellData];
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        T4CTableCellData *cellData = [self dataAtIndexPath:indexPath];
        if ([[HSUDraftManager shared] removeDraft:cellData.rawData]) {
            [self removeCellData:cellData];
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
        }
    }
}

@end
