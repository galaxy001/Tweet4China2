//
//  HSUProfileDataSource.m
//  Tweet4China
//
//  Created by Jason Hsu on 5/1/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUProfileDataSource.h"
#import "HSUBaseTableCell.h"
#import "HSUBaseViewController.h"

@interface HSUProfileDataSource ()

@property (nonatomic, strong) NSMutableArray *sectionsData;

@end

@implementation HSUProfileDataSource

- (id)init
{
    return [self initWithScreenName:MyScreenName];
}

- (id)initWithScreenName:(NSString *)screenName
{
    self = [super init];
    if (self) {
        self.screenName = screenName;
        [self refreshLocalData];
    }
    return self;
}

- (void)refreshLocalData
{
    self.sectionsData = [NSMutableArray arrayWithCapacity:2];
    NSMutableArray *referencesData = [NSMutableArray arrayWithCapacity:4];
    NSDictionary *rawData;
    rawData = @{@"title": _("Favorites"),
                @"action": kAction_Favorites,
                @"user_screen_name": self.screenName};
    T4CTableCellData *favoritesCellData = [[T4CTableCellData alloc] initWithRawData:rawData
                                                                           dataType:kDataType_NormalTitle];
    rawData = @{@"title": _("Lists"),
                @"action": kAction_Lists,
                @"user_screen_name": self.screenName};
    T4CTableCellData *listsCellData = [[T4CTableCellData alloc] initWithRawData:rawData
                                                                       dataType:kDataType_NormalTitle];
    rawData = @{@"title": _("Photos"),
                @"action": kAction_Photos,
                @"user_screen_name": self.screenName};
    T4CTableCellData *photosCellData = [[T4CTableCellData alloc] initWithRawData:rawData
                                                                        dataType:kDataType_NormalTitle];
    
    [referencesData addObject:photosCellData];
    [referencesData addObject:favoritesCellData];
    [referencesData addObject:listsCellData];
    
    [self.sectionsData addObject:referencesData];
    
    NSArray *drafts = [[HSUDraftManager shared] draftsSortedByUpdateTime];
    if ([self.screenName isEqualToString:twitter.myScreenName] && drafts.count) {
        NSMutableArray *draftData = [NSMutableArray arrayWithCapacity:1];
        rawData = @{@"title": _("Drafts"),
                    @"count": @(drafts.count),
                    @"action": kAction_Drafts};
        T4CTableCellData *draftsCellData = [[T4CTableCellData alloc] initWithRawData:rawData
                                                                            dataType:kDataType_Drafts];
        [draftData addObject:draftsCellData];
        [self.sectionsData addObject:draftData];
        notification_add_observer(HSUDraftsCountChangedNotification, self, @selector(_notificationDraftCountChanged));
    }
}

- (void)refresh
{
    [super refreshSilenced];
    
    [self refreshLocalData];
    
    __weak typeof(self)weakSelf = self;
    [twitter getUserTimelineWithScreenName:self.screenName sinceID:nil count:3 success:^(id responseObj) {
        NSArray *tweets = responseObj;
        for (NSDictionary *tweet in tweets) {
            T4CTableCellData *statusCellData = [[T4CTableCellData alloc] initWithRawData:tweet dataType:kDataType_DefaultStatus];
            [weakSelf.data addObject:statusCellData];
        }
        [weakSelf.delegate preprocessDataSourceForRender:weakSelf];
        if (weakSelf.count) {
            NSDictionary *rawData = @{@"title": _("View More Tweets"),
                                      @"action": kAction_UserTimeline,
                                      @"user_screen_name": weakSelf.screenName ?: @""};
            T4CTableCellData *viewMoreCellData =
            [[T4CTableCellData alloc] initWithRawData:rawData
                                             dataType:kDataType_NormalTitle];
            [weakSelf.data addObject:viewMoreCellData];
            [weakSelf.delegate dataSource:weakSelf didFinishRefreshWithError:nil];
        }
    } failure:^(NSError *error) {
        
    }];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    HSUBaseTableCell *cell = (HSUBaseTableCell *)[super tableView:tableView cellForRowAtIndexPath:indexPath];
#ifdef __IPHONE_7_0
    if (IPAD && Sys_Ver >= 7) {
        if (indexPath.section == self.sectionsData.count &&
            indexPath.row == [self.sectionsData[indexPath.section-1] count] - 1) {
            cell.separatorInset = edi(0, tableView.width, 0, 0);
        } else {
            CGFloat padding = cell.width/2-cell.contentView.width/2;
            cell.separatorInset = edi(0, padding, 0, padding);
        }
    }
#endif
    return cell;
}

- (T4CTableCellData *)dataAtIndexPath:(NSIndexPath *)indexPath
{
    T4CTableCellData *data = [super dataAtIndexPath:indexPath];
    if (data == nil) {
        data = self.sectionsData[indexPath.section-1][indexPath.row];
    }
    return data;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1 + self.sectionsData.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return [super tableView:tableView numberOfRowsInSection:section];
    }
    return [self.sectionsData[section-1] count];
}

- (void)_notificationDraftCountChanged
{
    NSDictionary *rawData = @{@"title": _("Drafts"),
                              @"count": @([[HSUDraftManager shared] draftsSortedByUpdateTime].count),
                              @"action": kAction_Drafts};
    T4CTableCellData *draftsCellData = [[T4CTableCellData alloc] initWithRawData:rawData
                                                                        dataType:kDataType_Drafts];
    [self.sectionsData.lastObject removeAllObjects];
    [self.sectionsData.lastObject addObject:draftsCellData];
    
    [self.delegate dataSource:self didFinishRefreshWithError:nil];
}

+ (void)checkUnreadForViewController:(HSUBaseViewController *)viewController
{
    // check dm
    NSString *latestIdStr = [[NSUserDefaults standardUserDefaults] objectForKey:S(@"%@_first_id_str", self.class.cacheKey)];
    [twitter getDirectMessagesSinceID:latestIdStr success:^(id responseObj) {
        id rMsgs = responseObj;
        [twitter getSentMessagesSinceID:latestIdStr success:^(id responseObj) {
            id sMsgs = responseObj;
            // merge received messages & sent messages
            NSArray *messages = [[NSArray arrayWithArray:rMsgs] arrayByAddingObjectsFromArray:sMsgs];
            if (messages.count) { // updated
                NSString *firstIdStr = messages[0][@"id_str"];
                [[NSUserDefaults standardUserDefaults] setObject:firstIdStr forKey:S(@"%@_first_id_str", self.class.cacheKey)];
                [[NSUserDefaults standardUserDefaults] synchronize];
                [viewController dataSourceDidFindUnread:nil];
            }
        } failure:^(NSError *error) {
            
        }];
    } failure:^(NSError *error) {
        
    }];
}

@end
