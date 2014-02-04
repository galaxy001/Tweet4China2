//
//  T4CViewController.m
//  Tweet4China
//
//  Created by Jason Hsu on 14-1-14.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "T4CTableViewController.h"
#import "HSUStatusCell.h"
#import "HSUBaseTableCell.h"
#import <SVPullToRefresh/SVPullToRefresh.h>
#import <Reachability/Reachability.h>
#import "T4CGapCellData.h"
#import "T4CGapCell.h"
#import "T4CStatusViewController.h"
#import "HSUChatStatusCell.h"
#import "HSUMainStatusCell.h"
#import "T4CLoadingRepliedStatusCell.h"
#import "T4CNewFollowersCell.h"
#import "T4CNewRetweetsCell.h"
#import "HSUConversationCell.h"
#import "T4CConversationCellData.h"
#import "HSUMessageCell.h"
#import "T4CMessagesViewController.h"
#import "HSUComposeViewController.h"
#import "HSUActivityWeixin.h"
#import "HSUProfileViewController.h"
#import "OpenInChromeController.h"
#import "HSUActivityWeixinMoments.h"
#import "HSUGalleryView.h"
#import "HSUInstagramHandler.h"
#import "HSUPersonCell.h"
#import "T4CPersonCellData.h"
#import "HSUListCell.h"
#import "T4CListCellData.h"
#import "T4CListTimelineViewController.h"
#import <SVWebViewController/SVModalWebViewController.h>
#import "HSUSettingsViewController.h"
#import "T4CSearchViewController.h"
#import "T4CTagTimelineViewController.h"
#import "HSUTabController.h"

@interface T4CTableViewController ()

@property (nonatomic, strong) NSDictionary *cellTypes;
@property (nonatomic, strong) NSDictionary *cellDataTypes;

@end

@implementation T4CTableViewController

- (void)dealloc
{
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.pullToRefresh = YES;
        self.infiniteScrolling = YES;
        
        self.cellTypes = @{kDataType_Status: [HSUStatusCell class],
                           kDataType_Gap: [T4CGapCell class],
                           kDataType_ChatStatus: [HSUChatStatusCell class],
                           kDataType_MainStatus: [HSUMainStatusCell class],
                           kDataType_LoadingReply: [T4CLoadingRepliedStatusCell class],
                           kDataType_NewFollowers: [T4CNewFollowersCell class],
                           kDataType_NewRetweets: [T4CNewRetweetsCell class],
                           kDataType_Conversation: [HSUConversationCell class],
                           kDataType_Message: [HSUMessageCell class],
                           kDataType_Person: [HSUPersonCell class],
                           kDataType_List: [HSUListCell class]};
        
        self.cellDataTypes = @{kDataType_Status: [T4CStatusCellData class],
                               kDataType_Gap: [T4CGapCellData class],
                               kDataType_ChatStatus: [T4CStatusCellData class],
                               kDataType_MainStatus: [T4CStatusCellData class],
                               kDataType_Conversation: [T4CConversationCellData class],
                               kDataType_Person: [T4CPersonCellData class],
                               kDataType_List: [T4CListCellData class]};
        
        self.data = @[].mutableCopy;
        self.useCache = YES;
    }
    return self;
}

- (void)loadView
{
    [super loadView];
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [self.view addSubview:tableView];
    self.tableView = tableView;
    if (IPAD) {
        self.tableView.separatorColor = rgb(225, 232, 237);
    }
    [tableView setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
    tableView.tableFooterView.backgroundColor = kClearColor;
    tableView.dataSource = self;
    tableView.delegate = self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self.useCache) {
        [self loadCache];
    }
    self.tableView.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    for (NSString *dataType in self.cellTypes) {
        [self.tableView registerClass:self.cellTypes[dataType] forCellReuseIdentifier:dataType];
    }
    
    if (!self.data.count) {
        [self refresh];
    }
    self.navigationController.delegate = self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // register table view cell
    __weak typeof(self)weakSelf = self;
    if (self.pullToRefresh) {
        [self.tableView addPullToRefreshWithActionHandler:^{
            [weakSelf refresh];
        }];
        self.tableView.pullToRefreshView.soundEffectEnabled = [setting(HSUSettingSoundEffect) boolValue];
        if (!self.tableView.pullToRefreshView.arrow) {
            self.tableView.pullToRefreshView.arrow = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icn_arrow_notif_dark"]];
        }
    }
    if (self.infiniteScrolling) {
        [self.tableView addInfiniteScrollingWithActionHandler:^{
            [weakSelf loadMore];
        }];
    }
}

// 里面装的是cell data array
- (NSMutableArray *)data
{
    if (_data == nil) {
        _data = [NSMutableArray array];
    }
    return _data;
}

- (void)refresh
{
    if (self.refreshState != T4CLoadingState_Done) {
        return;
    }
    self.refreshState = T4CLoadingState_Loading;
    NSMutableDictionary *params = self.requestParams.mutableCopy;
    if (self.topID) {
        params[@"since_id"] = @(self.topID);
    }
    if (self.requestCount) {
        params[@"count"] = @(self.requestCount);
    }
    __weak typeof(self)weakSelf = self;
    [twitter sendGETWithUrl:self.requestUrl parameters:params success:^(id responseObj) {
        if ([responseObj isKindOfClass:[NSDictionary class]]) {
            NSDictionary *responseDict = responseObj;
            NSString *nextCursor = responseDict[@"next_cursor"];
            if (nextCursor) { // page api
                self.bottomID = [nextCursor longLongValue];
            }
            NSArray *arrayData = responseDict[self.dataKey];
            arrayData = arrayData.count ? arrayData : nil;
            [weakSelf requestDidFinishRefreshWithData:arrayData];
            weakSelf.refreshState = arrayData ? T4CLoadingState_Done : T4CLoadingState_NoMore;
        } else if ([responseObj count]) {
            [weakSelf requestDidFinishRefreshWithData:responseObj];
            weakSelf.refreshState = T4CLoadingState_Done;
        } else {
            [weakSelf requestDidFinishRefreshWithData:nil];
            weakSelf.refreshState = T4CLoadingState_NoMore;
        }
    } failure:^(NSError *error) {
        if (error.code == 204) {
            [weakSelf requestDidFinishRefreshWithData:nil];
            weakSelf.refreshState = T4CLoadingState_NoMore;
        } else {
            [weakSelf requestDidFinishRefreshWithError:error];
            weakSelf.refreshState = T4CLoadingState_Error;
        }
    }];
}

- (void)loadGap:(T4CGapCellData *)gapCellData
{
    long long gapTopID = [self gapTopIDWithGapCellData:gapCellData];
    long long gapBotID = [self gapBotIDWithGapCellData:gapCellData];
    if (gapTopID == 0 || gapBotID == 0) {
        return;
    }
    
    self.gapCellData = gapCellData;
    self.gapCellData.state = T4CLoadingState_Loading;
    NSMutableDictionary *params = self.requestParams.mutableCopy;
    params[@"max_id"] = @(gapTopID - 1);
    params[@"since_id"] = @(gapBotID);
    if (self.requestCount) {
        params[@"count"] = @(self.requestCount);
    }
    __weak typeof(self)weakSelf = self;
    [twitter sendGETWithUrl:self.requestUrl parameters:params success:^(id responseObj) {
        if ([responseObj isKindOfClass:[NSDictionary class]]) {
            NSDictionary *responseDict = responseObj;
            NSString *nextCursor = responseDict[@"next_cursor"];
            if (nextCursor) { // page api
                self.bottomID = [nextCursor longLongValue];
            }
            NSArray *arrayData = responseDict[self.dataKey];
            arrayData = arrayData.count ? arrayData : nil;
            [weakSelf requestDidFinishLoadGapWithData:arrayData];
        } else if ([responseObj count]) {
            [weakSelf requestDidFinishLoadGapWithData:responseObj];
        } else {
            [weakSelf requestDidFinishLoadMoreWithData:nil];
        }
    } failure:^(NSError *error) {
        if (error.code == 204) {
            [weakSelf requestDidFinishLoadGapWithData:nil];
        } else {
            [weakSelf requestDidFinishLoadGapWithError:error];
        }
    }];
}

- (void)loadMore
{
    if (self.loadMoreState != T4CLoadingState_Done) {
        [self.tableView.pullToRefreshView stopAnimating];
        return;
    }
    self.loadMoreState = T4CLoadingState_Loading;
    NSMutableDictionary *params = self.requestParams.mutableCopy;
    if (self.bottomID) {
        params[@"max_id"] = @(self.bottomID - 1);
    }
    if (self.requestCount) {
        params[@"count"] = @(self.requestCount);
    }
    __weak typeof(self)weakSelf = self;
    [twitter sendGETWithUrl:self.requestUrl parameters:params success:^(id responseObj) {
        if ([responseObj isKindOfClass:[NSDictionary class]]) {
            NSDictionary *responseDict = responseObj;
            NSString *nextCursor = responseDict[@"next_cursor"];
            if (nextCursor) { // page api
                self.bottomID = [nextCursor longLongValue];
            }
            NSArray *arrayData = responseDict[self.dataKey];
            arrayData = arrayData.count ? arrayData : nil;
            [weakSelf requestDidFinishLoadMoreWithData:arrayData];
        } else if ([responseObj count]) {
            [weakSelf requestDidFinishLoadMoreWithData:responseObj];
        } else {
            [weakSelf requestDidFinishLoadMoreWithData:nil];
        }
    } failure:^(NSError *error) {
        if (error.code == 204) {
            [weakSelf requestDidFinishLoadMoreWithData:nil];
        } else {
            [weakSelf requestDidFinishLoadMoreWithError:error];
        }
    }];
}

// 数据经过解析之后，拿到数组才送到这里
- (void)requestDidFinishRefreshWithData:(NSArray *)dataArr
{
    if (dataArr.count) {
        NSDictionary *topData = dataArr.firstObject;
        long long topID = [topData[@"id"] longLongValue];
        self.topID = topID;
        
        NSDictionary *newBotData = dataArr.lastObject;
        long long newBotID = [newBotData[@"id"] longLongValue];
        
        NSDictionary *curTopData = [self.data.firstObject rawData];
        long long curTopID = [curTopData[@"id"] longLongValue];
        BOOL gapped = curTopID > 0 && newBotID > curTopID;
        BOOL inserted = self.data.count > 0;
        
        NSMutableArray *newDataArr = [NSMutableArray array];
        for (NSDictionary *rawData in dataArr) {
            if ([self filterData:rawData]) {
                [newDataArr addObject:[self createTableCellDataWithRawData:rawData]];
            }
        }
        if (gapped) {
            [newDataArr addObject:[[T4CGapCellData alloc] initWithRawData:nil dataType:kDataType_Gap]];
        }
        [newDataArr addObjectsFromArray:self.data];
        [self.data removeAllObjects];
        [self.data addObjectsFromArray:newDataArr];
        
        NSDictionary *botData = [self.data.lastObject rawData];
        self.bottomID = [botData[@"id"] longLongValue];
        
        [self.tableView reloadData];
        if (inserted) {
            [self scrollTableViewToCurrentOffsetAfterInsertNewCellCount:dataArr.count+(gapped?1:0)];
        }
        [self saveCache];
    }
    [self.tableView.pullToRefreshView stopAnimating];
}

- (void)requestDidFinishLoadGapWithData:(NSArray *)dataArr
{
    if (dataArr.count) {
        NSUInteger gapIndex = [self.data indexOfObject:self.gapCellData];
        NSIndexSet *set = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(gapIndex, dataArr.count)];
        NSMutableArray *newData = [NSMutableArray arrayWithCapacity:dataArr.count];
        for (NSDictionary *rawData in dataArr) {
            if ([self filterData:rawData]) {
                [newData addObject:[self createTableCellDataWithRawData:rawData]];
            }
        }
        [self.data insertObjects:newData atIndexes:set];
        self.gapCellData.state = T4CLoadingState_Done;
        
        [self.tableView reloadData];
        [self scrollTableViewToCurrentOffsetAfterInsertNewCellCount:dataArr.count];
        [self saveCache];
    } else {
        self.gapCellData.state = T4CLoadingState_NoMore;
        [self.tableView reloadData];
    }
}

- (void)requestDidFinishLoadMoreWithData:(NSArray *)dataArr
{
    if (dataArr.count) {
        NSDictionary *bottomData = dataArr.lastObject;
        long long bottomID = [bottomData[@"id"] longLongValue];
        
        self.bottomID = bottomID;
        for (NSDictionary *rawData in dataArr) {
            if ([self filterData:rawData]) {
                [self.data addObject:[self createTableCellDataWithRawData:rawData]];
            }
        }
        self.loadMoreState = T4CLoadingState_Done;
        
        [self.tableView reloadData];
        [self saveCache];
    } else {
        self.loadMoreState = T4CLoadingState_NoMore;
        self.tableView.infiniteScrollingView.enabled = NO;
    }
    [self.tableView.infiniteScrollingView stopAnimating];
}

// 真有错误才到这里，204不算的，一般是网络错误
- (void)requestDidFinishRefreshWithError:(NSError *)error
{
    NSLog(@"%@", error);
}

- (void)requestDidFinishLoadGapWithError:(NSError *)error
{
    self.gapCellData.state = T4CLoadingState_Error;
    NSLog(@"%@", error);
}

- (void)requestDidFinishLoadMoreWithError:(NSError *)error
{
    NSLog(@"%@", error);
    self.loadMoreState = T4CLoadingState_Error;
    self.tableView.infiniteScrollingView.enabled = NO;
}

- (void)scrollTableViewToCurrentOffsetAfterInsertNewCellCount:(NSUInteger)count
{
    if (self.data.count) {
        CGRect visibleRect = ccr(0, self.tableView.contentOffset.y+self.tableView.contentInset.top,
                                 self.tableView.width, self.tableView.height);
        NSArray *indexPathsVisibleRows = [self.tableView indexPathsForRowsInRect:visibleRect];
        NSIndexPath *firstIndexPath = indexPathsVisibleRows[0];
        NSInteger firstRow = firstIndexPath.row + count;
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:firstRow inSection:0]
                              atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
    }
}

- (T4CTableCellData *)createTableCellDataWithRawData:(NSDictionary *)rawData
{
    Class dataClass = self.cellDataTypes[[self dataTypeOfData:rawData]] ?: [T4CTableCellData class];
    T4CTableCellData *celldata = [[dataClass alloc] init];
    celldata.dataType = [self dataTypeOfData:rawData];
    celldata.rawData = rawData;
    celldata.target = self;
    return celldata;
}

- (NSString *)dataTypeOfData:(NSDictionary *)data
{
    if (data[@"text"]) {
        return kDataType_Status;
    } else if (data[@"recipient"]) {
        return kDataType_Message;
    } else if (data[@"member_count"]) {
        return kDataType_List;
    } else if (data[@"profile_image_url"]) {
        return kDataType_Person;
    } else if (data[@"status"]) {
        return kDataType_Draft;
    } else if (data[@"member_count"]) {
        return kDataType_List;
    }
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.data.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    T4CTableCellData *cellData = self.data[indexPath.row];
    return [self.cellTypes[cellData.dataType] heightForData:cellData];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    T4CTableCellData *cellData = self.data[indexPath.row];
    HSUBaseTableCell *cell = (HSUBaseTableCell *)[tableView dequeueReusableCellWithIdentifier:cellData.dataType];
    [cell setupWithData:cellData];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    T4CTableCellData *cellData = self.data[indexPath.row];
    if ([cellData.dataType isEqualToString:kDataType_Gap]) {
        T4CGapCellData *gapCellData = (T4CGapCellData *)cellData;
        [self loadGap:gapCellData];
    } else if ([cellData.dataType isEqualToString:kDataType_Status] ||
               [cellData.dataType isEqualToString:kDataType_ChatStatus]) {
        T4CStatusViewController *statusVC = [[T4CStatusViewController alloc] init];
        statusVC.status = cellData.rawData;
        [self.navigationController pushViewController:statusVC animated:YES];
    } else if ([cellData.dataType isEqualToString:kDataType_Conversation]) {
        T4CMessagesViewController *messagesVC = [[T4CMessagesViewController alloc] init];
        NSDictionary *conversation = cellData.rawData;
        messagesVC.conversation = conversation;
        NSArray *messages = conversation[@"messages"];
        for (NSDictionary *message in messages) {
            if ([message[@"sender_screen_name"] isEqualToString:MyScreenName]) {
                messagesVC.myProfile = message[@"sender"];
                messagesVC.herProfile = message[@"recipient"];
            } else {
                messagesVC.myProfile = message[@"recipient"];
                messagesVC.herProfile = message[@"sender"];
            }
            break;
        }
        [self.navigationController pushViewController:messagesVC animated:YES];
    } else if ([cellData.dataType isEqualToString:kDataType_List]) {
        T4CListTimelineViewController *listVC = [[T4CListTimelineViewController alloc] init];
        listVC.list = cellData.rawData;
        [self.navigationController pushViewController:listVC animated:YES];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (long long)gapTopIDWithGapCellData:(T4CGapCellData *)gapCellData
{
    NSInteger gapIndex = [self.data indexOfObject:gapCellData];
    if (gapIndex <= 0 || gapIndex >= self.data.count-1) {
        return 0;
    }
    
    T4CTableCellData *gapTopData = self.data[gapIndex - 1];
    long long gapTopID = [gapTopData.rawData[@"id"] longLongValue];
    return gapTopID;
}

- (long long)gapBotIDWithGapCellData:(T4CGapCellData *)gapCellData
{
    NSInteger gapIndex = [self.data indexOfObject:gapCellData];
    if (gapIndex <= 0 || gapIndex >= self.data.count-1) {
        return 0;
    }
    
    T4CTableCellData *gapBotData = self.data[gapIndex + 1];
    long long gapBotID = [gapBotData.rawData[@"id"] longLongValue];
    return gapBotID;
}

- (BOOL)filterData:(NSDictionary *)data
{
    return YES;
}

- (NSDictionary *)requestParams
{
    return @{};
}

- (NSUInteger)requestCount
{
    if ([Reachability reachabilityForInternetConnection].isReachableViaWiFi) {
        return [setting(HSUSettingPageCount) integerValue] ?: kRequestDataCountViaWifi;
    } else {
        return [setting(HSUSettingPageCountWWAN) integerValue] ?: kRequestDataCountViaWWAN;
    }
}

- (NSString *)requestUrlWithAPIFormat:(NSString *)apiFormat idString:(NSString *)idString
{
    return [NSString stringWithFormat:@"https://api.twitter.com/1.1/%@.json", [NSString stringWithFormat:apiFormat, idString]];
}

- (NSString *)requestUrlWithAPIString:(NSString *)apiString
{
    return [NSString stringWithFormat:@"https://api.twitter.com/1.1/%@.json", apiString];
}

- (NSString *)requestUrl
{
    return [self requestUrlWithAPIString:self.apiString];
}

- (void)addEventWithName:(NSString *)name target:(id)target action:(SEL)action events:(UIControlEvents)events
{
    for (uint i=0; i<self.data.count; i++) {
        HSUUIEvent *cellEvent = [[HSUUIEvent alloc] initWithName:name target:target action:action events:events];
        cellEvent.cellData = self.data[i];
        cellEvent.cellData.events[name] = cellEvent;
    }
}

- (void)saveCache
{
    if (!self.useCache) {
        return;
    }
    __weak typeof(self)weakSelf = self;
    dispatch_async(GCDBackgroundThread, ^{
        uint cacheSize = kRequestDataCountViaWifi;
        NSMutableArray *cacheDataArr = [NSMutableArray arrayWithCapacity:cacheSize];
        for (T4CTableCellData *cellData in weakSelf.data) {
            if (cacheDataArr.count < cacheSize) {
                id cacheData = cellData.cacheData;
                if (!cacheData) {
                    break;
                }
                [cacheDataArr addObject:cellData.cacheData];
            } else {
                break;
            }
        }
        [HSUCommonTools writeJSONObject:cacheDataArr toFile:weakSelf.class.description];
    });
}

- (void)_composeWithText:(NSString *)text
{
    HSUComposeViewController *composeVC = [[HSUComposeViewController alloc] init];
    composeVC.defaultText = text;
    UINavigationController *nav = [[HSUNavigationController alloc] initWithNavigationBarClass:[HSUNavigationBarLight class] toolbarClass:nil];
    nav.viewControllers = @[composeVC];
    [self.presentedViewController ?: self presentViewController:nav animated:YES completion:nil];
}

- (void)loadCache
{
    NSArray *cacheArr = [HSUCommonTools readJSONObjectFromFile:self.class.description];
    for (NSDictionary *cache in cacheArr) {
        T4CTableCellData *cellData = [[NSClassFromString(cache[@"class_name"]) alloc] init];
        cellData.rawData = cache[@"raw_data"];
        cellData.dataType = cache[@"data_type"];
        cellData.target = self;
        [self.data addObject:cellData];
    }
}

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithArguments:(NSDictionary *)arguments
{
    // User Link
    NSURL *url = [arguments objectForKey:@"url"];
    //    T4CTableCellData *cellData = [arguments objectForKey:@"cell_data"];
    if ([url.absoluteString hasPrefix:@"user://"] ||
        [url.absoluteString hasPrefix:@"tag://"]) {
        RIButtonItem *cancelItem = [RIButtonItem itemWithLabel:_("Cancel")];
        RIButtonItem *copyItem = [RIButtonItem itemWithLabel:_("Copy Content")];
        copyItem.action = ^{
            UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
            pasteboard.string = label.text;
        };
        UIActionSheet *linkActionSheet = [[UIActionSheet alloc] initWithTitle:nil cancelButtonItem:cancelItem destructiveButtonItem:nil otherButtonItems:copyItem, nil];
        [linkActionSheet showInView:self.view.window];
        return;
    }
    
    // Commen Link
    RIButtonItem *cancelItem = [RIButtonItem itemWithLabel:_("Cancel")];
    RIButtonItem *tweetLinkItem = [RIButtonItem itemWithLabel:_("Tweet Link")];
    tweetLinkItem.action = ^{
        [self _composeWithText:S(@" %@", url.absoluteString)];
    };
    RIButtonItem *copyLinkItem = [RIButtonItem itemWithLabel:_("Copy Link")];
    copyLinkItem.action = ^{
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = url.absoluteString;
    };
    RIButtonItem *mailLinkItem = [RIButtonItem itemWithLabel:_("Mail Link")];
    mailLinkItem.action = ^{
        [self.presentedViewController dismiss];
        NSString *body = S(@"<a href=\"%@\">%@</a><br><br>", url.absoluteString, url.absoluteString);
        NSString *subject = _("Link from Twitter");
        [HSUCommonTools sendMailWithSubject:subject body:body presentFromViewController:self];
    };
    
    RIButtonItem *weixinItem;
    RIButtonItem *momentsItem;
    if ([WXApi isWXAppInstalled]) {
        weixinItem = [RIButtonItem itemWithLabel:_("Weixin")];
        weixinItem.action = ^{
            [HSUActivityWeixin shareLink:url.absoluteString
                                   title:_("Share a link from Twitter")
                             description:label.text];
        };
        momentsItem = [RIButtonItem itemWithLabel:_("Weixin Moments")];
        momentsItem.action = ^{
            [HSUActivityWeixinMoments shareLink:url.absoluteString
                                          title:_("Share a link from Twitter")
                                    description:label.text];
        };
    }
    RIButtonItem *openInSafariItem = [RIButtonItem itemWithLabel:@"Safari"];
    openInSafariItem.action = ^{
        [[UIApplication sharedApplication] openURL:url];
    };
    UIActionSheet *linkActionSheet;
    if ([[OpenInChromeController sharedInstance] isChromeInstalled]) {
        RIButtonItem *openInChromeItem = [RIButtonItem itemWithLabel:@"Chrome"];
        openInChromeItem.action = ^{
            [[OpenInChromeController sharedInstance] openInChrome:url withCallbackURL:nil createNewTab:YES];
        };
        if ([WXApi isWXAppInstalled]) {
            linkActionSheet = [[UIActionSheet alloc] initWithTitle:nil cancelButtonItem:cancelItem destructiveButtonItem:nil otherButtonItems:tweetLinkItem, copyLinkItem, mailLinkItem, weixinItem, momentsItem, openInSafariItem, openInChromeItem, nil];
        } else {
            linkActionSheet = [[UIActionSheet alloc] initWithTitle:nil cancelButtonItem:cancelItem destructiveButtonItem:nil otherButtonItems:tweetLinkItem, copyLinkItem, mailLinkItem, openInSafariItem, openInChromeItem, nil];
        }
    } else {
        if ([WXApi isWXAppInstalled]) {
            linkActionSheet = [[UIActionSheet alloc] initWithTitle:nil cancelButtonItem:cancelItem destructiveButtonItem:nil otherButtonItems:tweetLinkItem, copyLinkItem, mailLinkItem, weixinItem, momentsItem, openInSafariItem, nil];
        } else {
            linkActionSheet = [[UIActionSheet alloc] initWithTitle:nil cancelButtonItem:cancelItem destructiveButtonItem:nil otherButtonItems:tweetLinkItem, copyLinkItem, mailLinkItem, openInSafariItem, nil];
        }
    }
    
    [linkActionSheet showInView:self.view.window];
}

- (void)attributedLabel:(TTTAttributedLabel *)label didReleaseLinkWithArguments:(NSDictionary *)arguments
{
    NSURL *url = [arguments objectForKey:@"url"];
    T4CStatusCellData *cellData = [arguments objectForKey:@"cell_data"];
    if ([url.absoluteString hasPrefix:@"user://"]) {
        NSString *screenName = [url.absoluteString substringFromIndex:7];
        HSUProfileViewController *profileVC = [[HSUProfileViewController alloc] initWithScreenName:screenName];
        [self.navigationController pushViewController:profileVC animated:YES];
    } else if ([url.absoluteString hasPrefix:@"tag://"]) {
        T4CTagTimelineViewController *tagVC = [[T4CTagTimelineViewController alloc] init];
        NSString *hashTag = [url.absoluteString substringFromIndex:6];
        tagVC.tag = hashTag;
        [self.navigationController pushViewController:tagVC animated:YES];
    } else {
        NSString *attr = cellData.attr;
        if ([attr isEqualToString:@"photo"]) {
            NSString *mediaURLHttps;
            NSArray *medias = cellData.rawData[@"entities"][@"media"];
            for (NSDictionary *media in medias) {
                NSString *expandedUrl = media[@"expanded_url"];
                if ([expandedUrl isEqualToString:url.absoluteString]) {
                    mediaURLHttps = media[@"media_url_https"];
                }
            }
            if (mediaURLHttps) {
                [self openPhotoURL:[NSURL URLWithString:mediaURLHttps] withCellData:cellData];
                return;
            }
        }
        [self openWebURL:url withCellData:cellData];
    }
}

- (void)openPhoto:(UIImage *)photo withCellData:(T4CTableCellData *)cellData
{
    HSUGalleryView *galleryView = [[HSUGalleryView alloc] initWithData:cellData image:photo];
    galleryView.viewController = self;
    [self.view.window addSubview:galleryView];
    [galleryView showWithAnimation:YES];
}

- (void)openPhotoURL:(NSURL *)photoURL withCellData:(T4CStatusCellData *)cellData
{
    HSUGalleryView *galleryView = [[HSUGalleryView alloc] initWithData:cellData imageURL:photoURL];
    galleryView.viewController = self;
    [self.view.window addSubview:galleryView];
    [galleryView showWithAnimation:YES];
}

- (void)openWebURL:(NSURL *)webURL withCellData:(T4CStatusCellData *)cellData
{
    if ([HSUInstagramHandler openInInstagramWithMediaID:cellData.instagramMediaID]) {
        return;
    }
    SVModalWebViewController *webViewController = [[SVModalWebViewController alloc] initWithURL:webURL];
    webViewController.modalPresentationStyle = UIModalPresentationPageSheet;
    [self presentViewController:webViewController animated:YES completion:NULL];
}

- (void)statusUpdated:(NSNotification *)notification
{
    if (notification.object == self.cellDataInNextPage.rawData ||
        [[notification.object objectForKey:@"id_str"] isEqualToString:[self.cellDataInNextPage.rawData objectForKey:@"id_str"]]) {
        
        self.cellDataInNextPage.rawData = [notification.object copy];
        [self.tableView reloadData];
    }
}

- (UIBarButtonItem *)actionBarButton
{
    if (!_actionBarButton) {
        UIButton *actionButton = [[UIButton alloc] init];
        [actionButton addTarget:self action:@selector(_actionButtonTouched) forControlEvents:UIControlEventTouchUpInside];
        if (Sys_Ver >= 7) {
            [actionButton setImage:[UIImage imageNamed:@"icn_nav_action_ios7"] forState:UIControlStateNormal];
        } else {
            [actionButton setImage:[UIImage imageNamed:@"icn_nav_action"] forState:UIControlStateNormal];
        }
        [actionButton sizeToFit];
        
        if (![[[NSUserDefaults standardUserDefaults] objectForKey:HSUActionBarTouched] boolValue]) {
            UIImage *indicatorImage = [UIImage imageNamed:@"unread_indicator"];
            UIImageView *indicator = [[UIImageView alloc] initWithImage:indicatorImage];
            [actionButton addSubview:indicator];
            indicator.leftTop = ccp(actionButton.width-10, 0);
        }
        
        _actionBarButton = [[UIBarButtonItem alloc] initWithCustomView:actionButton];
    }
    return _actionBarButton;
}

- (UIBarButtonItem *)composeBarButton
{
    if (!_composeBarButton) {
        if (Sys_Ver >= 7) {
            _composeBarButton = [[UIBarButtonItem alloc]
                                 initWithBarButtonSystemItem:UIBarButtonSystemItemCompose
                                 target:self
                                 action:@selector(_composeButtonTouched)];
        } else {
            UIButton *composeButton = [[UIButton alloc] init];
            [composeButton addTarget:self action:@selector(_composeButtonTouched) forControlEvents:UIControlEventTouchUpInside];
            [composeButton setImage:[UIImage imageNamed:@"ic_title_tweet"] forState:UIControlStateNormal];
            [composeButton sizeToFit];
            composeButton.width *= 1.4;
            _composeBarButton = [[UIBarButtonItem alloc] initWithCustomView:composeButton];
        }
    }
    return _composeBarButton;
}

- (UIBarButtonItem *)searchBarButton
{
    if (!_searchBarButton) {
        if (Sys_Ver >= 7) {
            _searchBarButton = [[UIBarButtonItem alloc]
                                initWithBarButtonSystemItem:UIBarButtonSystemItemSearch
                                target:self
                                action:@selector(_searchButtonTouched)];
        } else {
            UIButton *searchButton = [[UIButton alloc] init];
            [searchButton addTarget:self action:@selector(_searchButtonTouched) forControlEvents:UIControlEventTouchUpInside];
            [searchButton setImage:[UIImage imageNamed:@"ic_title_search"] forState:UIControlStateNormal];
            [searchButton sizeToFit];
            searchButton.width *= 1.4;
            _searchBarButton = [[UIBarButtonItem alloc] initWithCustomView:searchButton];
        }
    }
    return _searchBarButton;
}
- (void)_composeButtonTouched
{
    if (![twitter isAuthorized] || [SVProgressHUD isVisible]) {
        return;
    }
    HSUComposeViewController *composeVC = [[HSUComposeViewController alloc] init];
    UINavigationController *nav = [[HSUNavigationController alloc] initWithNavigationBarClass:[HSUNavigationBarLight class] toolbarClass:nil];
    nav.viewControllers = @[composeVC];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)_searchButtonTouched
{
    T4CSearchViewController *searchVC = [[T4CSearchViewController alloc] init];
    [self.navigationController pushViewController:searchVC animated:YES];
}

- (void)_actionButtonTouched
{
    HSUSettingsViewController *settingsVC = [[HSUSettingsViewController alloc] init];
    UINavigationController *nav = [[HSUNavigationController alloc] initWithNavigationBarClass:[HSUNavigationBarLight class] toolbarClass:nil];
    nav.modalPresentationStyle = UIModalPresentationFormSheet;
    nav.viewControllers = @[settingsVC];
    [self presentViewController:nav animated:YES completion:nil];
    
    if (![[[NSUserDefaults standardUserDefaults] objectForKey:HSUActionBarTouched] boolValue]) {
        notification_post(HSUActionBarTouchedNotification);
    }
}

- (void)showUnreadIndicator
{
    [((HSUTabController *)self.tabBarController) showUnreadIndicatorOnTabBarItem:self.navigationController.tabBarItem];
}

@end
