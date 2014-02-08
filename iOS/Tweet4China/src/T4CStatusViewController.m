//
//  T4CStatusDetailViewController.m
//  Tweet4China
//
//  Created by Jason Hsu on 14-2-2.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "T4CStatusViewController.h"
#import "T4CStatusCellData.h"
#import "T4CLoadingRepliedStatusCell.h"
#import <TTTAttributedLabel/TTTAttributedLabel.h>
#import "HSUComposeViewController.h"
#import "HPGrowingTextView.h"

@interface T4CStatusViewController ()

@property (nonatomic, strong) T4CTableCellData *loadingReplyCellData;
@property (nonatomic, readonly) NSDictionary *mainStatus; // self.status or self.status.retweeted_status
@property (nonatomic, weak) T4CTableCellData *mainCellData;

@end

@implementation T4CStatusViewController

- (id)init
{
    self = [super init];
    if (self) {
        self.useCache = NO;
        self.pullToRefresh = NO;
        self.infiniteScrolling = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItem = self.composeBarButton;
    
    if ([self.mainStatus[@"in_reply_to_status_id"] longLongValue]) {
        self.loadingReplyCellData =
        [[T4CTableCellData alloc] initWithRawData:self.mainStatus
                                         dataType:kDataType_LoadingReply];
        [self.data addObject:self.loadingReplyCellData];
    }
    T4CStatusCellData *cellData = [[T4CStatusCellData alloc] initWithRawData:self.status
                                                                    dataType:kDataType_MainStatus];
    cellData.target = self;
    [self.data addObject:cellData];
    self.mainCellData = cellData;
    
    [self updateStatus];
    [self loadInReplyStatus];
    [self loadReplies];
}

- (void)updateStatus
{
    __weak typeof(self)weakSelf = self;
    [twitter getDetailsForStatus:self.status[@"id_str"]
                         success:^(id responseObj)
     {
         if ([responseObj isKindOfClass:[NSDictionary class]]) {
             
             T4CStatusCellData *statusCellData = [[T4CStatusCellData alloc] initWithRawData:responseObj
                                                                                   dataType:kDataType_MainStatus];
             statusCellData.target = weakSelf;
             [weakSelf.data replaceObjectAtIndex:[weakSelf.data indexOfObject:weakSelf.mainCellData] withObject:statusCellData];
             weakSelf.mainCellData = statusCellData;
             notification_post_with_object(HSUStatusUpdatedNotification, responseObj);
             [weakSelf.tableView reloadData];
         }
     } failure:^(NSError *error)
     {
     }];
}

- (void)loadInReplyStatus
{
    // TODO: use cache
    if (self.refreshState != T4CLoadingState_Done) {
        return;
    }
    
    NSDictionary *status = [self.data.firstObject rawData];
    if (![status[@"in_reply_to_status_id"] longLongValue]) {
        self.refreshState = T4CLoadingState_NoMore;
        return;
    }
    
    self.refreshState = T4CLoadingState_Loading;
    __weak typeof(self)weakSelf = self;
    [twitter getDetailsForStatus:status[@"in_reply_to_status_id"]
                         success:^(id responseObj)
    {
        if ([responseObj isKindOfClass:[NSDictionary class]]) {
            
            NSUInteger count = 1;
            if (weakSelf.loadingReplyCellData) {
                [weakSelf.data removeObject:self.loadingReplyCellData];
                weakSelf.loadingReplyCellData = nil;
                count --;
            }
            
            T4CStatusCellData *statusCellData = [[T4CStatusCellData alloc] initWithRawData:responseObj
                                                                                  dataType:kDataType_ChatStatus];
            statusCellData.target = self;
            [weakSelf.data insertObject:statusCellData atIndex:0];
            [weakSelf.tableView reloadData];
            [weakSelf scrollTableViewToCurrentOffsetAfterInsertNewCellCount:1];
            weakSelf.refreshState = T4CLoadingState_Done;
        }
    } failure:^(NSError *error)
    {
        if (error.code == 204) {
            weakSelf.refreshState = T4CLoadingState_NoMore;
        } else {
            weakSelf.refreshState = T4CLoadingState_Error;
        }
    }];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView.contentOffset.y < 10 - scrollView.contentInset.top) {
        [self loadInReplyStatus];
    }
}

- (void)loadReplies
{
    self.loadMoreState = T4CLoadingState_Loading;
    NSString *keyword = S(@"@%@", self.mainStatus[@"user"][@"screen_name"]);
    __weak typeof(self)weakSelf = self;
    [twitter searchTweetsWithKeyword:keyword
                             sinceID:self.mainStatus[@"id"]
                               count:20
                             success:^(id responseObj)
    {
        if ([responseObj isKindOfClass:[NSDictionary class]]) {
            
            weakSelf.loadMoreState = T4CLoadingState_Done;
            NSArray *tweets = ((NSDictionary *)responseObj)[@"statuses"];
            NSUInteger newTweetsCount = 0;
            for (NSDictionary *tweet in tweets) {
                if ([tweet[@"in_reply_to_status_id"] isEqual:weakSelf.mainStatus[@"id"]]) {
                    T4CStatusCellData *cellData = [[T4CStatusCellData alloc] initWithRawData:tweet
                                                                                    dataType:kDataType_ChatStatus];
                    cellData.target = self;
                    [weakSelf.data addObject:cellData];
                    newTweetsCount += 1;
                }
            }
            
            if (newTweetsCount) {
                [weakSelf.tableView reloadData];
            }
        }
    } failure:^(NSError *error)
    {
        if (error.code == 204) {
            weakSelf.loadMoreState = T4CLoadingState_NoMore;
        } else {
            weakSelf.loadMoreState = T4CLoadingState_Error;
        }
    }];
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

- (void)_composeButtonTouched
{
    HSUComposeViewController *composeVC = [[HSUComposeViewController alloc] init];
    NSMutableString *defaultText = [[NSMutableString alloc] init];
    NSString *authorScreenName = self.mainStatus[@"user"][@"screen_name"];
    composeVC.defaultTitle = S(@"Reply @%@", authorScreenName);
    NSString *statusId = self.mainStatus[@"id_str"];
    composeVC.inReplyToStatusId = statusId;
    NSArray *userMentions = self.mainStatus[@"entities"][@"user_mentions"];
#ifdef DEBUG
    [defaultText appendString:@"客服推: "];
#endif
    if (userMentions && userMentions.count) {
        [defaultText appendFormat:@"@%@ ", authorScreenName];
        uint start = defaultText.length;
        if (self.status[@"retweeted_status"]) {
            [defaultText appendFormat:@"@%@ ", self.status[@"user"][@"screen_name"]];
            start = defaultText.length;
        }
        for (NSDictionary *userMention in userMentions) {
            NSString *screenName = userMention[@"screen_name"];
            [defaultText appendFormat:@"@%@ ", screenName];
        }
        uint length = defaultText.length - start;
        composeVC.defaultSelectedRange = NSMakeRange(start, length);
    } else {
        [defaultText appendFormat:@"@%@ ", authorScreenName];
        if (self.status[@"retweeted_status"]) {
            [defaultText appendFormat:@"@%@ ", self.status[@"user"][@"screen_name"]];
        }
        composeVC.defaultSelectedRange = NSMakeRange(defaultText.length, 0);
    }
    composeVC.defaultText = defaultText;
    UINavigationController *nav = [[HSUNavigationController alloc] initWithNavigationBarClass:[HSUNavigationBarLight class] toolbarClass:nil];
    nav.viewControllers = @[composeVC];
    [self presentViewController:nav animated:YES completion:nil];
}

- (NSString *)textViewPlaceHolder
{
    NSMutableString *placeHolder = [NSMutableString stringWithString:_("Reply to ")];
    NSString *name = self.mainStatus[@"user"][@"name"];
    [placeHolder appendFormat:@"%@, ", name];
    if (self.status[@"retweeted_status"]) {
        [placeHolder appendFormat:@"%@, ", self.status[@"user"][@"name"]];
    }
    NSArray *userMentions = self.status[@"entities"][@"user_mentions"];
    for (NSDictionary *userMention in userMentions) {
        NSString *name = userMention[@"name"];
        [placeHolder appendFormat:@"%@, ", name];
    }
    return [placeHolder substringToIndex:placeHolder.length-2];
}

- (NSString *)sendButtonTitle
{
    return _("Reply");
}

- (NSDictionary *)mainStatus
{
    return self.status[@"retweeted_status"] ?: self.status;
}

- (NSString *)textViewDefaultText
{
    NSMutableString *placeHolder = [NSMutableString string];
    NSString *name = self.mainStatus[@"user"][@"screen_name"];
    [placeHolder appendFormat:@"@%@ ", name];
    if (self.status[@"retweeted_status"]) {
        [placeHolder appendFormat:@"@%@ ", self.status[@"user"][@"screen_name"]];
    }
    NSArray *userMentions = self.status[@"entities"][@"user_mentions"];
    for (NSDictionary *userMention in userMentions) {
        NSString *name = userMention[@"screen_name"];
        [placeHolder appendFormat:@"@%@ ", name];
    }
    return placeHolder;
}

- (void)_sendButtonTouched
{
    if (self.textView.hasText) {
        NSDictionary *draft = [[HSUDraftManager shared]
                               saveDraftWithDraftID:nil
                               title:S(@"%@ %@", _("Reply to"), self.mainStatus[@"user"][@"name"])
                               status:self.textView.text
                               imageData:nil
                               reply:self.mainStatus[@"id_str"]
                               locationXY:CLLocationCoordinate2DMake(0, 0)
                               placeId:nil];
        [[HSUDraftManager shared] sendDraft:draft success:^(id responseObj) {
            [[HSUDraftManager shared] removeDraft:draft];
        } failure:^(NSError *error) {
            if (error.code == 204) {
                [[HSUDraftManager shared] removeDraft:draft];
                [SVProgressHUD showErrorWithStatus:_("Duplicated status")];
                return ;
            }
            if (!shadowsocksStarted) {
                [[HSUAppDelegate shared] startShadowsocks];
            }
            [[HSUDraftManager shared] activeDraft:draft];
            RIButtonItem *cancelItem = [RIButtonItem itemWithLabel:_("Cancel")];
            RIButtonItem *draftsItem = [RIButtonItem itemWithLabel:_("Drafts")];
            draftsItem.action = ^{
                [[HSUDraftManager shared] presentDraftsViewController];
            };
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:_("Tweet not sent")
                                                            message:error.userInfo[@"message"]
                                                   cancelButtonItem:cancelItem otherButtonItems:draftsItem, nil];
            dispatch_async(GCDMainThread, ^{
                [alert show];
            });
        }];
        
        [self.navigationController popViewControllerAnimated:YES];
    }
}

@end
