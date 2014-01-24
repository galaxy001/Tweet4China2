//
//  HSUStatusViewController.m
//  Tweet4China
//
//  Created by Jason Hsu on 3/10/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUStatusViewController.h"
#import "HSUStatusDataSource.h"
#import "HSUMainStatusCell.h"
#import "HSUComposeViewController.h"
#import "HSUGalleryView.h"
#import "HSUNavigationBarLight.h"
#import "HSUProfileViewController.h"
#import <TTTAttributedLabel/TTTAttributedLabel.h>
#import "HSUTabController.h"
#import "HSUiPadTabController.h"
#import "HSURetweetersDataSource.h"
#import "HSUPersonListViewController.h"
#import <SVWebViewController/SVModalWebViewController.h>

@interface HSUStatusViewController ()

@property (nonatomic, strong) NSDictionary *mainStatus;

@property (nonatomic, weak) UIView *replyBar;
@property (nonatomic, weak) UITextField *replyTextField;
@property (nonatomic, weak) UILabel *replyCountLabel;
@property (nonatomic, weak) UIButton *replyButton;

@end

@implementation HSUStatusViewController

- (id)initWithStatus:(NSDictionary *)status
{
    self = [super init];
    if (self) {
        self.mainStatus = status;
        self.dataSourceClass = [HSUStatusDataSource class];
        self.useRefreshControl = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    self.navigationItem.rightBarButtonItems = @[self.composeBarButton];
    self.navigationItem.leftBarButtonItems = @[self.actionBarButton];
    
    self.dataSource = [[self.dataSourceClass alloc] initWithDelegate:self status:self.mainStatus];
    
    NSString *name = self.mainStatus[@"in_reply_to_screen_name"];
    if (name.length) {
        if ([name isEqualToString:MyScreenName]) {
            name = _("Me");
        } else {
            name = S(@"@%@", name);
        }
        self.navigationItem.title = S(@"%@ %@", _("Reply to"), name);
    }
    
    [super viewDidLoad];
    
    [self.tableView registerClass:[HSUMainStatusCell class] forCellReuseIdentifier:kDataType_MainStatus];
    
//    UIView *replyBar = [[UIView alloc] init];
//    self.replyBar = replyBar;
//    [self.view addSubview:replyBar];
//    
//    UITextField *replyTextField = [[UITextField alloc] init];
//    self.replyTextField = replyTextField;
//    [replyBar addSubview:replyTextField];
//    
//    UILabel *replayCountLabel = [[UILabel alloc] init];
//    self.replyCountLabel = replayCountLabel;
//    [replyBar addSubview:replayCountLabel];
//    
//    UIButton *replyButton = [[UIButton alloc] init];
//    self.replyButton = replyButton;
//    [replyBar addSubview:replyButton];
    
    notification_add_observer(HSUGalleryViewDidAppear, self, @selector(galleryViewDidAppear));
    notification_add_observer(HSUGalleryViewDidDisappear, self, @selector(galleryViewDidDisappear));
    
//    [self.dataSource refresh];
    [self.dataSource loadMore];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self resetTableViewHeight];
    self.navigationItem.rightBarButtonItem.title = _("Reply");
}

- (void)preprocessDataSourceForRender:(HSUBaseDataSource *)dataSource
{
    [super preprocessDataSourceForRender:dataSource];
    
    [dataSource addEventWithName:@"retweets" target:self action:@selector(retweets:) events:UIControlEventTouchUpInside];
    [dataSource addEventWithName:@"favorites" target:self action:@selector(favorites:) events:UIControlEventTouchUpInside];
}

- (void)galleryViewDidAppear
{
    self.statusBarHidden = YES;
#ifdef __IPHONE_7_0
    [self setNeedsStatusBarAppearanceUpdate];
#endif
}

- (void)galleryViewDidDisappear
{
    self.statusBarHidden = NO;
#ifdef __IPHONE_7_0
    [self setNeedsStatusBarAppearanceUpdate];
#endif
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView.contentOffset.y < 10 - scrollView.contentInset.top) {
        [self.dataSource refresh];
    }
}

- (void)dataSource:(HSUBaseDataSource *)dataSource insertRowsFromIndex:(NSUInteger)fromIndex length:(NSUInteger)length
{
    for (HSUTableCellData *cellData in self.dataSource.allData) {
        cellData.delegate = self;
    }
    
    [self.tableView reloadData];
    
    if (fromIndex == 0) {
        CGRect visibleRect = ccr(0, self.tableView.contentOffset.y+self.tableView.contentInset.top, self.tableView.width, self.tableView.height);
        NSArray *indexPathsVisibleRows = [self.tableView indexPathsForRowsInRect:visibleRect];
        NSIndexPath *firstIndexPath = indexPathsVisibleRows[0];
        NSInteger firstRow = firstIndexPath.row;
        if (fromIndex == 0) { // refresh
            firstRow += length;
        }
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:firstRow inSection:0]
                              atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
    [self resetTableViewHeight];
    
    [((HSUTabController *)self.tabBarController) hideUnreadIndicatorOnTabBarItem:self.navigationController.tabBarItem]; // for iPhone
    [((HSUiPadTabController *)self.tabController) hideUnreadIndicatorOnViewController:self.navigationController]; // for iPad
}

- (void)dataSource:(HSUBaseDataSource *)dataSource didFinishRefreshWithError:(NSError *)error
{
    if (error) {
        L(error);
    } else {
        [self.tableView reloadData];
        
    }
}

- (void)resetTableViewHeight
{
    CGFloat height = 0;
    for (HSUTableCellData *cellData in self.dataSource.data) {
        if (cellData.rawData != self.mainStatus && height == 0) {
            continue;
        }
        height += [cellData.renderData[@"height"] floatValue];
    }
    height = MIN(height + self.tableView.contentInset.top + tabbar_height, self.view.height);
    self.tableView.contentInset = edi(self.tableView.contentInset.top, 0, self.view.height-height+tabbar_height, 0);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    HSUTableCellData *data = [self.dataSource dataAtIndexPath:indexPath];
    if ([data.dataType isEqualToString:kDataType_ChatStatus]) {
        HSUStatusViewController *statusVC = [[HSUStatusViewController alloc] initWithStatus:data.rawData];
        [self.navigationController pushViewController:statusVC animated:YES];
        return;
    }
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
}

- (void)_composeButtonTouched
{
    HSUComposeViewController *composeVC = [[HSUComposeViewController alloc] init];
    NSMutableString *defaultText = [[NSMutableString alloc] init];
    HSUTableCellData *mainStatus = [self.dataSource dataAtIndex:0];
    NSString *authorScreenName = mainStatus.rawData[@"user"][@"screen_name"];
    composeVC.defaultTitle = S(@"Reply @%@", authorScreenName);
    NSString *statusId = mainStatus.rawData[@"id_str"];
    composeVC.inReplyToStatusId = statusId;
    NSArray *userMentions = mainStatus.rawData[@"entities"][@"user_mentions"];
#ifdef DEBUG
    [defaultText appendString:@"我是T4C客服: "];
#endif
    if (userMentions && userMentions.count) {
        [defaultText appendFormat:@"@%@ ", authorScreenName];
        for (NSDictionary *userMention in userMentions) {
            NSString *screenName = userMention[@"screen_name"];
            [defaultText appendFormat:@"@%@ ", screenName];
        }
        uint start = authorScreenName.length + 2;
#ifdef DEBUG
        start += 9;
#endif
        uint length = defaultText.length - authorScreenName.length - 2;
        composeVC.defaultSelectedRange = NSMakeRange(start, length);
    } else {
        [defaultText appendFormat:@"@%@ ", authorScreenName];
        composeVC.defaultSelectedRange = NSMakeRange(defaultText.length, 0);
    }
    composeVC.defaultText = defaultText;
    UINavigationController *nav = [[HSUNavigationController alloc] initWithNavigationBarClass:[HSUNavigationBarLight class] toolbarClass:nil];
    nav.viewControllers = @[composeVC];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)attributedLabelDidLongPressed:(TTTAttributedLabel *)label
{
    label.backgroundColor = rgb(215, 230, 242);
    RIButtonItem *cancelItem = [RIButtonItem itemWithLabel:_("Cancel")];
    cancelItem.action = ^{
        label.backgroundColor = kClearColor;
    };
    RIButtonItem *copyItem = [RIButtonItem itemWithLabel:_("Copy Content")];
    copyItem.action = ^{
        label.backgroundColor = kClearColor;
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = self.mainStatus[@"text"];
    };
    UIActionSheet *linkActionSheet = [[UIActionSheet alloc] initWithTitle:nil cancelButtonItem:cancelItem destructiveButtonItem:nil otherButtonItems:copyItem, nil];
    [linkActionSheet showInView:self.view.window];
}

- (void)tappedPhoto:(NSString *)imageUrl withCellData:(HSUTableCellData *)cellData
{
    [self openPhotoURL:[NSURL URLWithString:imageUrl] withCellData:cellData];
}

- (void)delete:(HSUTableCellData *)cellData
{
    RIButtonItem *cancelItem = [RIButtonItem itemWithLabel:_("Cancel")];
    cancelItem.action = ^{
        [self.tableView reloadData];
    };
    RIButtonItem *deleteItem = [RIButtonItem itemWithLabel:_("Delete Tweet")];
    deleteItem.action = ^{
        NSDictionary *rawData = cellData.rawData;
        NSString *id_str = rawData[@"id_str"];
        
        __weak typeof(self)weakSelf = self;
        [twitter destroyStatus:id_str success:^(id responseObj) {
            [weakSelf.navigationController popViewControllerAnimated:YES];
            notification_post_with_object(HSUStatusDidDelete, id_str);
        } failure:^(NSError *error) {
            [twitter dealWithError:error errTitle:_("Delete Tweet failed")];
        }];
    };
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil cancelButtonItem:cancelItem destructiveButtonItem:deleteItem otherButtonItems:nil, nil];
    [actionSheet showInView:self.view.window];
}

- (void)retweets:(HSUTableCellData *)cellData
{
    HSURetweetersDataSource *dataSource = [[HSURetweetersDataSource alloc] init];
    dataSource.statusID = cellData.rawData[@"id_str"];
    HSUPersonListViewController *retweetersVC = [[HSUPersonListViewController alloc] initWithDataSource:dataSource];
    [self.navigationController pushViewController:retweetersVC animated:YES];
    [dataSource refresh];
}

- (void)favorites:(HSUTableCellData *)cellData
{
    NSString *statusID = cellData.rawData[@"id_str"];
    SVModalWebViewController *webVC = [[SVModalWebViewController alloc] initWithAddress:S(@"http://favstar.fm/t/%@", statusID)];
    webVC.modalPresentationStyle = UIModalPresentationPageSheet;
    [self presentViewController:webVC animated:YES completion:nil];
}

@end
