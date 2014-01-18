//
//  HSUTweetsViewController.m
//  Tweet4China
//
//  Created by Jason Hsu on 5/3/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUTweetsViewController.h"
#import "HSUComposeViewController.h"
#import "HSUNavigationBarLight.h"
#import "HSUGalleryView.h"
#import "HSUStatusViewController.h"
#import "HSUProfileViewController.h"
#import "HSUProfileDataSource.h"
#import <TTTAttributedLabel/TTTAttributedLabel.h>
#import "NSDate+Additions.h"
#import "HSUStatusCell.h"
#import "HSUSearchTweetsDataSource.h"
#import "OpenInChromeController.h"
#import <SVWebViewController/SVModalWebViewController.h>
#import <FHSTwitterEngine/NSString+URLEncoding.h>
#import <AFNetworking/AFNetworking.h>

@implementation HSUTweetsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    notification_add_observer(HSUGalleryViewDidAppear, self, @selector(galleryViewDidAppear));
    notification_add_observer(HSUGalleryViewDidDisappear, self, @selector(galleryViewDidDisappear));
    notification_add_observer(HSUStatusUpdatedNotification, self, @selector(statusUpdated:));
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

- (void)preprocessDataSourceForRender:(HSUBaseDataSource *)dataSource
{
    [dataSource addEventWithName:@"reply" target:self action:@selector(reply:) events:UIControlEventTouchUpInside];
    [dataSource addEventWithName:@"retweet" target:self action:@selector(retweet:) events:UIControlEventTouchUpInside];
    [dataSource addEventWithName:@"favorite" target:self action:@selector(favorite:) events:UIControlEventTouchUpInside];
    [dataSource addEventWithName:@"more" target:self action:@selector(more:) events:UIControlEventTouchUpInside];
    [dataSource addEventWithName:@"delete" target:self action:@selector(delete:) events:UIControlEventTouchUpInside];
    [dataSource addEventWithName:@"touchAvatar" target:self action:@selector(touchAvatar:) events:UIControlEventTouchUpInside];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    HSUTableCellData *data = [self.dataSource dataAtIndexPath:indexPath];
    if ([data.dataType isEqualToString:kDataType_DefaultStatus]) {
        self.cellDataInNextPage = data;
        HSUStatusViewController *statusVC = [[HSUStatusViewController alloc] initWithStatus:data.rawData];
        [self.navigationController pushViewController:statusVC animated:YES];
        return;
    }
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
}

#pragma mark - Common actions
- (void)reply:(HSUTableCellData *)cellData {
    [Flurry logEvent:S(@"reply in %@", [self.class description])];
    NSDictionary *rawData = cellData.rawData;
    NSString *screen_name = rawData[@"user"][@"screen_name"];
    NSString *id_str = rawData[@"id_str"];
    
    HSUComposeViewController *composeVC = [[HSUComposeViewController alloc] init];
    composeVC.defaultText = S(@" @%@ ", screen_name);
    composeVC.inReplyToStatusId = id_str;
    UINavigationController *nav = [[HSUNavigationController alloc] initWithNavigationBarClass:[HSUNavigationBarLight class] toolbarClass:nil];
    nav.viewControllers = @[composeVC];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)retweet:(HSUTableCellData *)cellData {
    [Flurry logEvent:S(@"retweet in %@", [self.class description])];
    NSDictionary *status = cellData.rawData;
    BOOL isRetweetedStatus = NO;
    if (status[@"retweeted_status"]) {
        status = status[@"retweeted_status"];
        isRetweetedStatus = YES;
    }
    
    BOOL retweeted = [status[@"retweeted"] boolValue]; // retweeted by me
    
    if (retweeted) {
        NSString *id_str = status[@"id_str"];
        if (isRetweetedStatus) {
            id_str = cellData.rawData[@"id_str"];
            __weak typeof(self)weakSelf = self;
            [twitter destroyStatus:id_str success:^(id responseObj) {
                NSMutableDictionary *newStatus = [status mutableCopy];
                newStatus[@"retweeted"] = @(!retweeted);
                if (isRetweetedStatus) {
                    NSMutableDictionary *newRawData = [cellData.rawData mutableCopy];
                    newRawData[@"retweeted_status"] = newStatus;
                    cellData.rawData = newRawData;
                } else {
                    cellData.rawData = newStatus;
                }
                notification_post_with_object(HSUStatusUpdatedNotification, cellData.rawData);
                [weakSelf.dataSource saveCache];
                notification_post(kNotification_HSUStatusCell_OtherCellSwiped);
                [weakSelf.tableView reloadData];
            } failure:^(NSError *error) {
                notification_post(kNotification_HSUStatusCell_OtherCellSwiped);
                [twitter dealWithError:error errTitle:_("Delete retweet failed")];
            }];
        } else {
            if ([status[@"retweeted_count"] integerValue] <= 200) {
                __weak typeof(self)weakSelf = self;
                [twitter getRetweetsForStatus:id_str count:200 success:^(id responseObj) {
                    BOOL found = NO;
                    NSArray *tweets = responseObj;
                    for (NSDictionary *tweet in tweets) {
                        if ([tweet[@"user"][@"screen_name"] isEqualToString:MyScreenName]) {
                            NSString *id_str = tweet[@"id_str"];
                            [twitter destroyStatus:id_str success:^(id responseObj) {
                                NSMutableDictionary *newStatus = [status mutableCopy];
                                newStatus[@"retweeted"] = @(!retweeted);
                                if (isRetweetedStatus) {
                                    NSMutableDictionary *newRawData = [cellData.rawData mutableCopy];
                                    newRawData[@"retweeted_status"] = newStatus;
                                    cellData.rawData = newRawData;
                                } else {
                                    cellData.rawData = newStatus;
                                }
                                notification_post_with_object(HSUStatusUpdatedNotification, cellData.rawData);
                                [weakSelf.dataSource saveCache];
                                notification_post(kNotification_HSUStatusCell_OtherCellSwiped);
                                [weakSelf.tableView reloadData];
                            } failure:^(NSError *error) {
                                notification_post(kNotification_HSUStatusCell_OtherCellSwiped);
                                [twitter dealWithError:error errTitle:_("Delete retweet failed")];
                            }];
                            found = YES;
                            break;
                        }
                    }
                    if (!found) {
                        notification_post(kNotification_HSUStatusCell_OtherCellSwiped);
                    }
                } failure:^(NSError *error) {
                    notification_post(kNotification_HSUStatusCell_OtherCellSwiped);
                    [twitter dealWithError:error errTitle:_("Delete retweet failed")];
                }];
            } else {
                __weak typeof(self)weakSelf = self;
                [twitter getUserTimelineWithScreenName:MyScreenName sinceID:nil count:200 success:^(id responseObj) {
                    BOOL found = NO;
                    NSArray *tweets = responseObj;
                    for (NSDictionary *tweet in tweets) {
                        if ([tweet[@"retweeted_status"][@"id_str"] isEqualToString:id_str]) {
                            NSString *id_str = tweet[@"id_str"];
                            [twitter destroyStatus:id_str success:^(id responseObj) {
                                NSMutableDictionary *newStatus = [status mutableCopy];
                                newStatus[@"retweeted"] = @(!retweeted);
                                if (isRetweetedStatus) {
                                    NSMutableDictionary *newRawData = [cellData.rawData mutableCopy];
                                    newRawData[@"retweeted_status"] = newStatus;
                                    cellData.rawData = newRawData;
                                } else {
                                    cellData.rawData = newStatus;
                                }
                                notification_post_with_object(HSUStatusUpdatedNotification, cellData.rawData);
                                [weakSelf.dataSource saveCache];
                                notification_post(kNotification_HSUStatusCell_OtherCellSwiped);
                                [weakSelf.tableView reloadData];
                            } failure:^(NSError *error) {
                                notification_post(kNotification_HSUStatusCell_OtherCellSwiped);
                                [twitter dealWithError:error errTitle:_("Delete retweet failed")];
                            }];
                            found = YES;
                            break;
                        }
                    }
                    if (!found) {
                        notification_post(kNotification_HSUStatusCell_OtherCellSwiped);
                    }
                } failure:^(NSError *error) {
                    notification_post(kNotification_HSUStatusCell_OtherCellSwiped);
                    [twitter dealWithError:error errTitle:_("Delete retweet failed")];
                }];
            }
        }
    } else {
        NSString *id_str = status[@"id_str"];
        __weak typeof(self)weakSelf = self;
        [twitter sendRetweetWithStatusID:id_str success:^(id responseObj) {
            NSMutableDictionary *newStatus = [status mutableCopy];
            newStatus[@"retweeted"] = @(!retweeted);
            if (isRetweetedStatus) {
                NSMutableDictionary *newRawData = [cellData.rawData mutableCopy];
                newRawData[@"retweeted_status"] = newStatus;
                cellData.rawData = newRawData;
            } else {
                cellData.rawData = newStatus;
            }
            notification_post_with_object(HSUStatusUpdatedNotification, cellData.rawData);
            [weakSelf.dataSource saveCache];
            notification_post(kNotification_HSUStatusCell_OtherCellSwiped);
            [weakSelf.tableView reloadData];
        } failure:^(NSError *error) {
            notification_post(kNotification_HSUStatusCell_OtherCellSwiped);
            [twitter dealWithError:error errTitle:_("Retweet failed")];
        }];
    }
}

- (void)favorite:(HSUTableCellData *)cellData {
    [Flurry logEvent:S(@"favorite in %@", [self.class description])];
    NSDictionary *rawData = cellData.rawData;
    if (rawData[@"retweeted_status"]) {
        rawData = rawData[@"retweeted_status"];
    }
    
    NSString *id_str = rawData[@"id_str"];
    BOOL favorited = [rawData[@"favorited"] boolValue];
    
    if (favorited) {
        __weak typeof(self)weakSelf = self;
        [twitter unMarkStatus:id_str success:^(id responseObj) {
            NSMutableDictionary *newRawData = [rawData mutableCopy];
            newRawData[@"favorited"] = @(!favorited);
            cellData.rawData = newRawData;
            notification_post_with_object(HSUStatusUpdatedNotification, newRawData);
            [weakSelf.dataSource saveCache];
            [weakSelf.tableView reloadData];
        } failure:^(NSError *error) {
            [twitter dealWithError:error errTitle:_("Delete Favorite failed")];
        }];
    } else {
        __weak typeof(self)weakSelf = self;
        [twitter markStatus:id_str success:^(id responseObj) {
            NSMutableDictionary *newRawData = [rawData mutableCopy];
            newRawData[@"favorited"] = @(!favorited);
            notification_post_with_object(HSUStatusUpdatedNotification, newRawData);
            cellData.rawData = newRawData;
            [weakSelf.dataSource saveCache];
            [weakSelf.tableView reloadData];
        } failure:^(NSError *error) {
            [twitter dealWithError:error errTitle:_("Favorite Tweet failed")];
        }];
    }
}

- (void)delete:(HSUTableCellData *)cellData
{
    [Flurry logEvent:S(@"delete in %@", [self.class description])];
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
            [weakSelf.dataSource removeCellData:cellData];
            [weakSelf.dataSource saveCache];
            [weakSelf.tableView reloadData];
            notification_post_with_object(HSUStatusDidDelete, id_str);
        } failure:^(NSError *error) {
            [twitter dealWithError:error errTitle:_("Delete Tweet failed")];
        }];
    };
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil cancelButtonItem:cancelItem destructiveButtonItem:deleteItem otherButtonItems:nil, nil];
    [actionSheet showInView:self.view.window];
}

- (void)more:(HSUTableCellData *)cellData {
    [Flurry logEvent:S(@"more in %@", [self.class description])];
    NSDictionary *rawData = cellData.rawData;
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil cancelButtonItem:nil destructiveButtonItem:nil otherButtonItems:nil];
    uint count = 0;
    
    NSArray *urls = rawData[@"entities"][@"urls"];
    NSArray *medias = rawData[@"entities"][@"media"];
    if (medias && medias.count) {
        urls = [urls arrayByAddingObjectsFromArray:medias];
    }
    
    if (urls && urls.count) { // has link
        RIButtonItem *tweetLinkItem = [RIButtonItem itemWithLabel:_("Tweet Link")];
        tweetLinkItem.action = ^{
            [Flurry logEvent:S(@"tweet link in %@", [self.class description])];
            if ([self.presentedViewController isKindOfClass:[SVModalWebViewController class]] || urls.count == 1) {
                NSString *link = [urls objectAtIndex:0][@"expanded_url"];
                [self _composeWithText:S(@" %@", link)];
            } else {
                UIActionSheet *selectLinkActionSheet = [[UIActionSheet alloc] initWithTitle:nil cancelButtonItem:nil destructiveButtonItem:nil otherButtonItems:nil, nil];
                for (NSDictionary *urlDict in urls) {
                    NSString *displayUrl = urlDict[@"display_url"];
                    NSString *expendedUrl = urlDict[@"expanded_url"];
                    RIButtonItem *buttonItem = [RIButtonItem itemWithLabel:displayUrl];
                    buttonItem.action = ^{
                        [self _composeWithText:S(@" %@", expendedUrl)];
                    };
                    [selectLinkActionSheet addButtonItem:buttonItem];
                }
                
                RIButtonItem *cancelItem = [RIButtonItem itemWithLabel:_("Cancel")];
                [selectLinkActionSheet addButtonItem:cancelItem];
                
                [selectLinkActionSheet setCancelButtonIndex:urls.count];
                [selectLinkActionSheet showInView:self.view.window];
            }
        };
        [actionSheet addButtonItem:tweetLinkItem];
        count ++;
        
        RIButtonItem *copyLinkItem = [RIButtonItem itemWithLabel:_("Copy Link")];
        copyLinkItem.action = ^{
            [Flurry logEvent:S(@"copy link in %@", [self.class description])];
            if ([self.presentedViewController isKindOfClass:[SVModalWebViewController class]] || urls.count == 1) {
                NSString *link = [urls objectAtIndex:0][@"expanded_url"];
                UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                pasteboard.string = link;
            } else {
                UIActionSheet *selectLinkActionSheet = [[UIActionSheet alloc] initWithTitle:nil cancelButtonItem:nil destructiveButtonItem:nil otherButtonItems:nil, nil];
                for (NSDictionary *urlDict in urls) {
                    NSString *displayUrl = urlDict[@"display_url"];
                    NSString *expendedUrl = urlDict[@"expanded_url"];
                    RIButtonItem *buttonItem = [RIButtonItem itemWithLabel:displayUrl];
                    buttonItem.action = ^{
                        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                        pasteboard.string = expendedUrl;
                    };
                    [selectLinkActionSheet addButtonItem:buttonItem];
                }
                
                RIButtonItem *cancelItem = [RIButtonItem itemWithLabel:_("Cancel")];
                [selectLinkActionSheet addButtonItem:cancelItem];
                
                [selectLinkActionSheet setCancelButtonIndex:urls.count];
                [selectLinkActionSheet showInView:self.view.window];
            }
        };
        [actionSheet addButtonItem:copyLinkItem];
        count ++;
        
        RIButtonItem *mailLinkItem = [RIButtonItem itemWithLabel:_("Mail Link")];
        mailLinkItem.action = ^{
            [Flurry logEvent:S(@"mail link in %@", [self.class description])];
            if ([self.presentedViewController isKindOfClass:[SVModalWebViewController class]] || urls.count == 1) {
                NSString *link = [urls objectAtIndex:0][@"expanded_url"];
                NSString *subject = _("Link from Twitter");
                NSString *body = S(@"<a href=\"%@\">%@</a>", link, link);
                [HSUCommonTools sendMailWithSubject:subject body:body presentFromViewController:self];
            } else {
                UIActionSheet *selectLinkActionSheet = [[UIActionSheet alloc] initWithTitle:nil cancelButtonItem:nil destructiveButtonItem:nil otherButtonItems:nil, nil];
                for (NSDictionary *urlDict in urls) {
                    NSString *displayUrl = urlDict[@"display_url"];
                    NSString *expendedUrl = urlDict[@"expanded_url"];
                    RIButtonItem *buttonItem = [RIButtonItem itemWithLabel:displayUrl];
                    buttonItem.action = ^{
                        NSString *subject = _("Link from Twitter");
                        NSString *body = S(@"<a href=\"%@\">%@</a>", expendedUrl, displayUrl);
                        [HSUCommonTools sendMailWithSubject:subject body:body presentFromViewController:self];
                    };
                    [selectLinkActionSheet addButtonItem:buttonItem];
                }
                
                RIButtonItem *cancelItem = [RIButtonItem itemWithLabel:_("Cancel")];
                [selectLinkActionSheet addButtonItem:cancelItem];
                
                [selectLinkActionSheet setCancelButtonIndex:urls.count];
                [selectLinkActionSheet showInView:self.view.window];
            }
        };
        [actionSheet addButtonItem:mailLinkItem];
        count ++;
        
        RIButtonItem *openInSafariItem = [RIButtonItem itemWithLabel:_("Open in Safari")];
        openInSafariItem.action = ^{
            [Flurry logEvent:S(@"open in safari in %@", [self.class description])];
            if ([self.presentedViewController isKindOfClass:[SVModalWebViewController class]] || urls.count == 1) {
                NSString *link = [urls objectAtIndex:0][@"expanded_url"];
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:link]];
            } else {
                UIActionSheet *selectLinkActionSheet = [[UIActionSheet alloc] initWithTitle:nil cancelButtonItem:nil destructiveButtonItem:nil otherButtonItems:nil, nil];
                for (NSDictionary *urlDict in urls) {
                    NSString *displayUrl = urlDict[@"display_url"];
                    NSString *expendedUrl = urlDict[@"expanded_url"];
                    RIButtonItem *buttonItem = [RIButtonItem itemWithLabel:displayUrl];
                    buttonItem.action = ^{
                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:expendedUrl]];
                    };
                    [selectLinkActionSheet addButtonItem:buttonItem];
                }
                
                RIButtonItem *cancelItem = [RIButtonItem itemWithLabel:_("Cancel")];
                [selectLinkActionSheet addButtonItem:cancelItem];
                
                [selectLinkActionSheet setCancelButtonIndex:urls.count];
                [selectLinkActionSheet showInView:self.view.window];
            }
        };
        [actionSheet addButtonItem:openInSafariItem];
        count ++;
        
        if ([[OpenInChromeController sharedInstance] isChromeInstalled]) {
            RIButtonItem *openInChromeItem = [RIButtonItem itemWithLabel:_("Open in Chrome")];
            openInChromeItem.action = ^{
                [Flurry logEvent:S(@"open in chrome in %@", [self.class description])];
                if ([self.presentedViewController isKindOfClass:[SVModalWebViewController class]] || urls.count == 1) {
                    NSString *link = [urls objectAtIndex:0][@"expanded_url"];
                    [[OpenInChromeController sharedInstance] openInChrome:[NSURL URLWithString:link] withCallbackURL:nil createNewTab:YES];
                } else {
                    UIActionSheet *selectLinkActionSheet = [[UIActionSheet alloc] initWithTitle:nil cancelButtonItem:nil destructiveButtonItem:nil otherButtonItems:nil, nil];
                    for (NSDictionary *urlDict in urls) {
                        NSString *displayUrl = urlDict[@"display_url"];
                        NSString *expendedUrl = urlDict[@"expanded_url"];
                        RIButtonItem *buttonItem = [RIButtonItem itemWithLabel:displayUrl];
                        buttonItem.action = ^{
                            [[OpenInChromeController sharedInstance] openInChrome:[NSURL URLWithString:expendedUrl] withCallbackURL:nil createNewTab:YES];
                        };
                        [selectLinkActionSheet addButtonItem:buttonItem];
                    }
                    
                    RIButtonItem *cancelItem = [RIButtonItem itemWithLabel:_("Cancel")];
                    [selectLinkActionSheet addButtonItem:cancelItem];
                    
                    [selectLinkActionSheet setCancelButtonIndex:urls.count];
                    [selectLinkActionSheet showInView:self.view.window];
                }
            };
            [actionSheet addButtonItem:openInChromeItem];
            count ++;
        }
    }
    
    NSString *id_str = rawData[@"id_str"];
    NSString *link = S(@"https://twitter.com/rtfocus/status/%@", id_str);
    
    RIButtonItem *copyLinkToTweetItem = [RIButtonItem itemWithLabel:_("Copy Link of Tweet")];
    copyLinkToTweetItem.action = ^{
        [Flurry logEvent:S(@"copy Link of tweet in %@", [self.class description])];
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = link;
    };
    [actionSheet addButtonItem:copyLinkToTweetItem];
    count ++;
    
    RIButtonItem *mailTweetItem = [RIButtonItem itemWithLabel:_("Mail Tweet")];
    mailTweetItem.action = ^{
        [Flurry logEvent:S(@"mail tweet in %@", [self.class description])];
        [twitter oembedStatus:id_str success:^(id responseObj) {
            notification_post(kNotification_HSUStatusCell_OtherCellSwiped);
            NSString *subject = _("Link from Twitter");
            [HSUCommonTools sendMailWithSubject:subject
                                           body:responseObj[@"html"]
                      presentFromViewController:self];
        } failure:^(NSError *error) {
            notification_post(kNotification_HSUStatusCell_OtherCellSwiped);
            [twitter dealWithError:error errTitle:_("Fetch HTML failed")];
        }];
    };
    [actionSheet addButtonItem:mailTweetItem];
    count ++;
    
    RIButtonItem *translateItem = [RIButtonItem itemWithLabel:_("Translate to Chinese")];
    translateItem.action = ^{
        [SVProgressHUD showWithStatus:_("Translating")];
        dispatch_async(GCDBackgroundThread, ^{
            NSString *text = rawData[@"retweeted_status"][@"text"] ?: rawData[@"text"];
            text = [[text stringRemovedEmoji] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if (text.length) {
                text = [text URLEncodedString];
                NSString *url = S(@"http://fanyi.youdao.com/openapi.do?keyfrom=Tweet4China&key=955554580&type=data&doctype=json&version=1.1&q=%@", text);
                NSMutableURLRequest *request = [[NSURLRequest requestWithURL:[NSURL URLWithString:url]] mutableCopy];
                [request setTimeoutInterval:30];
                AFJSONRequestOperation *op = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                    
                    if ([JSON isKindOfClass:[NSDictionary class]]) {
                        NSDictionary *youdaoDict = JSON;
                        NSString *youdaoResult = youdaoDict[@"translation"];
                        if ([youdaoResult isKindOfClass:[NSArray class]]) {
                            NSString *chineseText = [(NSArray *)youdaoResult firstObject];
                            if (chineseText) {
                                [SVProgressHUD dismiss];
                                dispatch_async(GCDMainThread, ^{
                                    RIButtonItem *cancelItem = [RIButtonItem itemWithLabel:_("OK")];
                                    RIButtonItem *copyItem = [RIButtonItem itemWithLabel:_("Copy")];
                                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:chineseText cancelButtonItem:cancelItem otherButtonItems:copyItem, nil];
                                    [alert show];
                                    copyItem.action = ^{
                                        [UIPasteboard generalPasteboard].string = chineseText;
                                    };
                                });
                                return ;
                            }
                        }
                    }
                    [SVProgressHUD showErrorWithStatus:_("Translate failed")];
                } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                    [SVProgressHUD showErrorWithStatus:_("Translate failed")];
                }];
                [op start];
            } else {
                [SVProgressHUD showErrorWithStatus:_("No word can be translated")];
            }
        });
    };
    [actionSheet addButtonItem:translateItem];
    count ++;
    
    RIButtonItem *RTItem = [RIButtonItem itemWithLabel:_("RT")];
    RTItem.action = ^{
        [Flurry logEvent:S(@"RT in %@", [self.class description])];
        HSUComposeViewController *composeVC = [[HSUComposeViewController alloc] init];
        NSString *authorScreenName = rawData[@"user"][@"screen_name"];
        NSString *text = rawData[@"text"];
        composeVC.defaultText = S(@" RT @%@: %@", authorScreenName, text);
        UINavigationController *nav = [[HSUNavigationController alloc] initWithNavigationBarClass:[HSUNavigationBarLight class] toolbarClass:nil];
        nav.viewControllers = @[composeVC];
        [self presentViewController:nav animated:YES completion:nil];
    };
    [actionSheet addButtonItem:RTItem];
    count ++;
    
    RIButtonItem *cancelItem = [RIButtonItem itemWithLabel:_("Cancel")];
    [actionSheet addButtonItem:cancelItem];
    
    [actionSheet setCancelButtonIndex:count];
    [actionSheet showInView:[UIApplication sharedApplication].keyWindow];
}

- (void)touchAvatar:(HSUTableCellData *)cellData
{
    NSString *screenName = cellData.rawData[@"retweeted_status"][@"user"][@"screen_name"] ?: cellData.rawData[@"user"][@"screen_name"];
    HSUProfileViewController *profileVC = [[HSUProfileViewController alloc] initWithScreenName:screenName];
    profileVC.profile = cellData.rawData[@"retweeted_status"][@"user"] ?: cellData.rawData[@"user"];
    [self.navigationController pushViewController:profileVC animated:YES];
}

- (void)_composeWithText:(NSString *)text
{
    HSUComposeViewController *composeVC = [[HSUComposeViewController alloc] init];
    composeVC.defaultText = text;
    UINavigationController *nav = [[HSUNavigationController alloc] initWithNavigationBarClass:[HSUNavigationBarLight class] toolbarClass:nil];
    nav.viewControllers = @[composeVC];
    [self.presentedViewController ?: self presentViewController:nav animated:YES completion:nil];
}

#pragma mark - attributtedLabel delegate
- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithArguments:(NSDictionary *)arguments
{
    // User Link
    NSURL *url = [arguments objectForKey:@"url"];
    //    HSUTableCellData *cellData = [arguments objectForKey:@"cell_data"];
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
    RIButtonItem *openInSafariItem = [RIButtonItem itemWithLabel:_("Open in Safari")];
    openInSafariItem.action = ^{
        [[UIApplication sharedApplication] openURL:url];
    };
    UIActionSheet *linkActionSheet;
    if ([[OpenInChromeController sharedInstance] isChromeInstalled]) {
        RIButtonItem *openInChromeItem = [RIButtonItem itemWithLabel:_("Open in Chrome")];
        openInChromeItem.action = ^{
            [[OpenInChromeController sharedInstance] openInChrome:url withCallbackURL:nil createNewTab:YES];
        };
        linkActionSheet = [[UIActionSheet alloc] initWithTitle:nil cancelButtonItem:cancelItem destructiveButtonItem:nil otherButtonItems:tweetLinkItem, copyLinkItem, mailLinkItem, openInSafariItem, openInChromeItem, nil];
    } else {
        linkActionSheet = [[UIActionSheet alloc] initWithTitle:nil cancelButtonItem:cancelItem destructiveButtonItem:nil otherButtonItems:tweetLinkItem, copyLinkItem, mailLinkItem, openInSafariItem, nil];
    }
    
    [linkActionSheet showInView:self.view.window];
}

- (void)attributedLabel:(TTTAttributedLabel *)label didReleaseLinkWithArguments:(NSDictionary *)arguments
{
    NSURL *url = [arguments objectForKey:@"url"];
    HSUTableCellData *cellData = [arguments objectForKey:@"cell_data"];
    if ([url.absoluteString hasPrefix:@"user://"]) {
        NSString *screenName = [url.absoluteString substringFromIndex:7];
        HSUProfileViewController *profileVC = [[HSUProfileViewController alloc] initWithScreenName:screenName];
        [self.navigationController pushViewController:profileVC animated:YES];
    } else if ([url.absoluteString hasPrefix:@"tag://"]) {
        NSString *hashTag = [url.absoluteString substringFromIndex:6];
        HSUSearchTweetsDataSource *searchDataSource = [[HSUSearchTweetsDataSource alloc] init];
        searchDataSource.keyword = S(@"#%@", hashTag);
        HSUTweetsViewController *tweetsVC = [[HSUTweetsViewController alloc] initWithDataSource:searchDataSource];
        [self.navigationController pushViewController:tweetsVC animated:YES];
        [searchDataSource refresh];
    } else {
        NSString *attr = cellData.renderData[@"attr"];
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

- (void)openPhoto:(UIImage *)photo withCellData:(HSUTableCellData *)cellData
{
    HSUGalleryView *galleryView = [[HSUGalleryView alloc] initWithData:cellData image:photo];
    galleryView.viewController = self;
    [self.view.window addSubview:galleryView];
    [galleryView showWithAnimation:YES];
}

- (void)openPhotoURL:(NSURL *)photoURL withCellData:(HSUTableCellData *)cellData
{
    HSUGalleryView *galleryView = [[HSUGalleryView alloc] initWithData:cellData imageURL:photoURL];
    galleryView.viewController = self;
    [self.view.window addSubview:galleryView];
    [galleryView showWithAnimation:YES];
}

- (void)openWebURL:(NSURL *)webURL withCellData:(HSUTableCellData *)cellData
{
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

- (BOOL)prefersStatusBarHidden
{
    return self.statusBarHidden;
}

@end
