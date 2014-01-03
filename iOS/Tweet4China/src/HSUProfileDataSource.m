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
    NSDictionary *rawData = @{@"title": _(@"Following"),
                              @"action": kAction_Following,
                              @"user_screen_name": self.screenName};
    HSUTableCellData *followingCellData = [[HSUTableCellData alloc] initWithRawData:rawData
                                                                           dataType:kDataType_NormalTitle];
    rawData = @{@"title": _(@"Followers"),
                @"action": kAction_Followers,
                @"user_screen_name": self.screenName};
    HSUTableCellData *followersCellData = [[HSUTableCellData alloc] initWithRawData:rawData
                                                                           dataType:kDataType_NormalTitle];
    rawData = @{@"title": _(@"Favorites"),
                @"action": kAction_Favorites,
                @"user_screen_name": self.screenName};
    HSUTableCellData *favoritesCellData = [[HSUTableCellData alloc] initWithRawData:rawData
                                                                           dataType:kDataType_NormalTitle];
    rawData = @{@"title": _(@"Lists"),
                @"action": kAction_Lists,
                @"user_screen_name": self.screenName};
    HSUTableCellData *listsCellData = [[HSUTableCellData alloc] initWithRawData:rawData
                                                                       dataType:kDataType_NormalTitle];
    
    [referencesData addObject:followingCellData];
    [referencesData addObject:followersCellData];
    [referencesData addObject:favoritesCellData];
    [referencesData addObject:listsCellData];
    
    [self.sectionsData addObject:referencesData];
    
    NSArray *drafts = [[HSUDraftManager shared] draftsSortedByUpdateTime];
    if ([self.screenName isEqualToString:TWENGINE.myScreenName] && drafts.count) {
        NSMutableArray *draftData = [NSMutableArray arrayWithCapacity:1];
        rawData = @{@"title": _(@"Drafts"),
                    @"count": @(drafts.count),
                    @"action": kAction_Drafts};
        HSUTableCellData *draftsCellData = [[HSUTableCellData alloc] initWithRawData:rawData
                                                                            dataType:kDataType_Drafts];
        [draftData addObject:draftsCellData];
        [self.sectionsData addObject:draftData];
        notification_add_observer(HSUDraftsCountChangedNotification, self, @selector(_notificationDraftCountChanged));
    }
}

- (void)refresh
{
    [super refresh];
    
    [self refreshLocalData];
    
    [TWENGINE getUserTimelineWithScreenName:self.screenName sinceID:nil count:3 success:^(id responseObj) {
        NSArray *tweets = responseObj;
        for (NSDictionary *tweet in tweets) {
            HSUTableCellData *statusCellData = [[HSUTableCellData alloc] initWithRawData:tweet dataType:kDataType_DefaultStatus];
            [self.data addObject:statusCellData];
        }
        [self.delegate preprocessDataSourceForRender:self];
        if (self.count) {
            NSDictionary *rawData = @{@"title": _(@"View More Tweets"),
                                      @"action": kAction_UserTimeline,
                                      @"user_screen_name": self.screenName};
            HSUTableCellData *viewMoreCellData =
            [[HSUTableCellData alloc] initWithRawData:rawData
                                             dataType:kDataType_NormalTitle];
            [self.data addObject:viewMoreCellData];
            [self.delegate dataSource:self didFinishRefreshWithError:nil];
        }
    } failure:^(NSError *error) {
        
    }];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    HSUBaseTableCell *cell = (HSUBaseTableCell *)[super tableView:tableView cellForRowAtIndexPath:indexPath];
    if (IPAD) {
        if (indexPath.section == self.sectionsData.count &&
            indexPath.row == [self.sectionsData[indexPath.section-1] count] - 1) {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
            if (iOS_Ver >= 7) {
                cell.separatorInset = edi(0, tableView.width, 0, 0);
            }
#endif
        }
    }
    return cell;
}

- (HSUTableCellData *)dataAtIndexPath:(NSIndexPath *)indexPath
{
    HSUTableCellData *data = [super dataAtIndexPath:indexPath];
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
    NSDictionary *rawData = @{@"title": _(@"Drafts"),
                              @"count": @([[HSUDraftManager shared] draftsSortedByUpdateTime].count),
                              @"action": kAction_Drafts};
    HSUTableCellData *draftsCellData = [[HSUTableCellData alloc] initWithRawData:rawData
                                                                        dataType:kDataType_Drafts];
    [self.sectionsData.lastObject removeAllObjects];
    [self.sectionsData.lastObject addObject:draftsCellData];
    
    [self.delegate dataSource:self didFinishRefreshWithError:nil];
}

+ (void)checkUnreadForViewController:(HSUBaseViewController *)viewController
{
    // check dm
    NSString *latestIdStr = [[NSUserDefaults standardUserDefaults] objectForKey:S(@"%@_first_id_str", self.class.cacheKey)];
    [TWENGINE getDirectMessagesSinceID:latestIdStr success:^(id responseObj) {
        id rMsgs = responseObj;
        [TWENGINE getSentMessagesSinceID:latestIdStr success:^(id responseObj) {
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
