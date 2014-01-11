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
#import "HSUMiniBrowser.h"
#import "HSUStatusViewController.h"
#import "HSUProfileViewController.h"
#import "HSUProfileDataSource.h"
#import <TTTAttributedLabel/TTTAttributedLabel.h>
#import "NSDate+Additions.h"
#import "HSUStatusCell.h"

@interface HSUTweetsViewController ()

@property (nonatomic, weak) UIViewController *modelVC;

@end

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
            [TWENGINE destroyStatus:id_str success:^(id responseObj) {
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
                [TWENGINE dealWithError:error errTitle:_(@"Delete retweet failed")];
            }];
        } else {
            if ([status[@"retweeted_count"] integerValue] <= 200) {
                __weak typeof(self)weakSelf = self;
                [TWENGINE getRetweetsForStatus:id_str count:200 success:^(id responseObj) {
                    BOOL found = NO;
                    NSArray *tweets = responseObj;
                    for (NSDictionary *tweet in tweets) {
                        if ([tweet[@"user"][@"screen_name"] isEqualToString:MyScreenName]) {
                            NSString *id_str = tweet[@"id_str"];
                            [TWENGINE destroyStatus:id_str success:^(id responseObj) {
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
                                [TWENGINE dealWithError:error errTitle:_(@"Delete retweet failed")];
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
                    [TWENGINE dealWithError:error errTitle:_(@"Delete retweet failed")];
                }];
            } else {
                __weak typeof(self)weakSelf = self;
                [TWENGINE getUserTimelineWithScreenName:MyScreenName sinceID:nil count:200 success:^(id responseObj) {
                    BOOL found = NO;
                    NSArray *tweets = responseObj;
                    for (NSDictionary *tweet in tweets) {
                        if ([tweet[@"retweeted_status"][@"id_str"] isEqualToString:id_str]) {
                            NSString *id_str = tweet[@"id_str"];
                            [TWENGINE destroyStatus:id_str success:^(id responseObj) {
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
                                [TWENGINE dealWithError:error errTitle:_(@"Delete retweet failed")];
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
                    [TWENGINE dealWithError:error errTitle:_(@"Delete retweet failed")];
                }];
            }
        }
    } else {
        NSString *id_str = status[@"id_str"];
        __weak typeof(self)weakSelf = self;
        [TWENGINE sendRetweetWithStatusID:id_str success:^(id responseObj) {
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
            [TWENGINE dealWithError:error errTitle:_(@"Retweet failed")];
        }];
    }
}

- (void)favorite:(HSUTableCellData *)cellData {
    NSDictionary *rawData = cellData.rawData;
    if (rawData[@"retweeted_status"]) {
        rawData = rawData[@"retweeted_status"];
    }
    
    NSString *id_str = rawData[@"id_str"];
    BOOL favorited = [rawData[@"favorited"] boolValue];
    
    if (favorited) {
        __weak typeof(self)weakSelf = self;
        [TWENGINE unMarkStatus:id_str success:^(id responseObj) {
            NSMutableDictionary *newRawData = [rawData mutableCopy];
            newRawData[@"favorited"] = @(!favorited);
            cellData.rawData = newRawData;
            notification_post_with_object(HSUStatusUpdatedNotification, newRawData);
            [weakSelf.dataSource saveCache];
            [weakSelf.tableView reloadData];
        } failure:^(NSError *error) {
            [TWENGINE dealWithError:error errTitle:_(@"Delete Favorite failed")];
        }];
    } else {
        __weak typeof(self)weakSelf = self;
        [TWENGINE markStatus:id_str success:^(id responseObj) {
            NSMutableDictionary *newRawData = [rawData mutableCopy];
            newRawData[@"favorited"] = @(!favorited);
            notification_post_with_object(HSUStatusUpdatedNotification, newRawData);
            cellData.rawData = newRawData;
            [weakSelf.dataSource saveCache];
            [weakSelf.tableView reloadData];
        } failure:^(NSError *error) {
            [TWENGINE dealWithError:error errTitle:_(@"Favorite Tweet failed")];
        }];
    }
}

- (void)delete:(HSUTableCellData *)cellData
{
    RIButtonItem *cancelItem = [RIButtonItem itemWithLabel:_(@"Cancel")];
    cancelItem.action = ^{
        [self.tableView reloadData];
    };
    RIButtonItem *deleteItem = [RIButtonItem itemWithLabel:_(@"Delete Tweet")];
    deleteItem.action = ^{
        NSDictionary *rawData = cellData.rawData;
        NSString *id_str = rawData[@"id_str"];
        
        __weak typeof(self)weakSelf = self;
        [TWENGINE destroyStatus:id_str success:^(id responseObj) {
            [weakSelf.dataSource removeCellData:cellData];
            [weakSelf.dataSource saveCache];
            [weakSelf.tableView reloadData];
            notification_post_with_object(HSUStatusDidDelete, id_str);
        } failure:^(NSError *error) {
            [TWENGINE dealWithError:error errTitle:_(@"Delete Tweet failed")];
        }];
    };
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil cancelButtonItem:cancelItem destructiveButtonItem:deleteItem otherButtonItems:nil, nil];
    [actionSheet showInView:self.view.window];
}

- (void)more:(HSUTableCellData *)cellData {
    NSDictionary *rawData = cellData.rawData;
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil cancelButtonItem:nil destructiveButtonItem:nil otherButtonItems:nil];
    uint count = 0;
    
    NSArray *urls = rawData[@"entities"][@"urls"];
    NSArray *medias = rawData[@"entities"][@"media"];
    if (medias && medias.count) {
        urls = [urls arrayByAddingObjectsFromArray:medias];
    }
    
    if (urls && urls.count) { // has link
        RIButtonItem *tweetLinkItem = [RIButtonItem itemWithLabel:_(@"Tweet Link")];
        tweetLinkItem.action = ^{
            if (urls.count == 1) {
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
                
                RIButtonItem *cancelItem = [RIButtonItem itemWithLabel:_(@"Cancel")];
                [selectLinkActionSheet addButtonItem:cancelItem];
                
                [selectLinkActionSheet setCancelButtonIndex:urls.count];
                [selectLinkActionSheet showInView:self.view.window];
            }
        };
        [actionSheet addButtonItem:tweetLinkItem];
        count ++;
        
        RIButtonItem *copyLinkItem = [RIButtonItem itemWithLabel:_(@"Copy Link")];
        copyLinkItem.action = ^{
            if (urls.count == 1) {
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
                
                RIButtonItem *cancelItem = [RIButtonItem itemWithLabel:_(@"Cancel")];
                [selectLinkActionSheet addButtonItem:cancelItem];
                
                [selectLinkActionSheet setCancelButtonIndex:urls.count];
                [selectLinkActionSheet showInView:self.view.window];
            }
        };
        [actionSheet addButtonItem:copyLinkItem];
        count ++;
        
        RIButtonItem *mailLinkItem = [RIButtonItem itemWithLabel:_(@"Mail Link")];
        mailLinkItem.action = ^{
            if (urls.count == 1) {
                NSString *link = [urls objectAtIndex:0][@"expanded_url"];
                NSString *subject = _(@"Link from Twitter");
                NSString *body = S(@"<a href=\"%@\">%@</a>", link, link);
                [HSUCommonTools sendMailWithSubject:subject body:body presentFromViewController:self];
            } else {
                UIActionSheet *selectLinkActionSheet = [[UIActionSheet alloc] initWithTitle:nil cancelButtonItem:nil destructiveButtonItem:nil otherButtonItems:nil, nil];
                for (NSDictionary *urlDict in urls) {
                    NSString *displayUrl = urlDict[@"display_url"];
                    NSString *expendedUrl = urlDict[@"expanded_url"];
                    RIButtonItem *buttonItem = [RIButtonItem itemWithLabel:displayUrl];
                    buttonItem.action = ^{
                        NSString *subject = _(@"Link from Twitter");
                        NSString *body = S(@"<a href=\"%@\">%@</a>", expendedUrl, displayUrl);
                        [HSUCommonTools sendMailWithSubject:subject body:body presentFromViewController:self];
                    };
                    [selectLinkActionSheet addButtonItem:buttonItem];
                }
                
                RIButtonItem *cancelItem = [RIButtonItem itemWithLabel:_(@"Cancel")];
                [selectLinkActionSheet addButtonItem:cancelItem];
                
                [selectLinkActionSheet setCancelButtonIndex:urls.count];
                [selectLinkActionSheet showInView:self.view.window];
            }
        };
        [actionSheet addButtonItem:mailLinkItem];
        count ++;
    }
    
    NSString *id_str = rawData[@"id_str"];
    NSString *link = S(@"https://twitter.com/rtfocus/status/%@", id_str);
    
    RIButtonItem *copyLinkToTweetItem = [RIButtonItem itemWithLabel:_(@"Copy link to Tweet")];
    copyLinkToTweetItem.action = ^{
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = link;
    };
    [actionSheet addButtonItem:copyLinkToTweetItem];
    count ++;
    
    RIButtonItem *mailTweetItem = [RIButtonItem itemWithLabel:_(@"Mail Tweet")];
    mailTweetItem.action = ^{
        [TWENGINE oembedStatus:id_str success:^(id responseObj) {
            notification_post(kNotification_HSUStatusCell_OtherCellSwiped);
            NSString *subject = _(@"Link from Twitter");
            [HSUCommonTools sendMailWithSubject:subject
                                           body:responseObj[@"html"]
                      presentFromViewController:self];
        } failure:^(NSError *error) {
            notification_post(kNotification_HSUStatusCell_OtherCellSwiped);
            [TWENGINE dealWithError:error errTitle:_(@"Fetch HTML failed")];
        }];
    };
    [actionSheet addButtonItem:mailTweetItem];
    count ++;
    
    RIButtonItem *RTItem = [RIButtonItem itemWithLabel:_(@"RT")];
    RTItem.action = ^{
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
    
    RIButtonItem *cancelItem = [RIButtonItem itemWithLabel:_(@"Cancel")];
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
    [self.modelVC ?: self presentViewController:nav animated:YES completion:nil];
}

#pragma mark - attributtedLabel delegate
- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithArguments:(NSDictionary *)arguments
{
    // User Link
    NSURL *url = [arguments objectForKey:@"url"];
    //    HSUTableCellData *cellData = [arguments objectForKey:@"cell_data"];
    if ([url.absoluteString hasPrefix:@"user://"] ||
        [url.absoluteString hasPrefix:@"tag://"]) {
        RIButtonItem *cancelItem = [RIButtonItem itemWithLabel:_(@"Cancel")];
        RIButtonItem *copyItem = [RIButtonItem itemWithLabel:_(@"Copy Content")];
        copyItem.action = ^{
            UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
            pasteboard.string = label.text;
        };
        UIActionSheet *linkActionSheet = [[UIActionSheet alloc] initWithTitle:nil cancelButtonItem:cancelItem destructiveButtonItem:nil otherButtonItems:copyItem, nil];
        [linkActionSheet showInView:self.view.window];
        return;
    }
    
    // Commen Link
    RIButtonItem *cancelItem = [RIButtonItem itemWithLabel:_(@"Cancel")];
    RIButtonItem *tweetLinkItem = [RIButtonItem itemWithLabel:_(@"Tweet Link")];
    tweetLinkItem.action = ^{
        [self _composeWithText:S(@" %@", url.absoluteString)];
    };
    RIButtonItem *copyLinkItem = [RIButtonItem itemWithLabel:_(@"Copy Link")];
    copyLinkItem.action = ^{
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = url.absoluteString;
    };
    RIButtonItem *mailLinkItem = [RIButtonItem itemWithLabel:_(@"Mail Link")];
    mailLinkItem.action = ^{
        NSString *body = S(@"<a href=\"%@\">%@</a><br><br>", url.absoluteString, url.absoluteString);
        NSString *subject = _(@"Link from Twitter");
        [HSUCommonTools sendMailWithSubject:subject body:body presentFromViewController:self];
    };
    RIButtonItem *openInSafariItem = [RIButtonItem itemWithLabel:_(@"Open in Safari")];
    openInSafariItem.action = ^{
        [[UIApplication sharedApplication] openURL:url];
    };
    UIActionSheet *linkActionSheet = [[UIActionSheet alloc] initWithTitle:nil cancelButtonItem:cancelItem destructiveButtonItem:nil otherButtonItems:tweetLinkItem, copyLinkItem, mailLinkItem, openInSafariItem, nil];
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
        return;
    }
    if ([url.absoluteString hasPrefix:@"tag://"]) {
        // Push Tag ViewController
        return;
    }
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
    UINavigationController *nav = [[HSUNavigationController alloc] initWithNavigationBarClass:[HSUNavigationBarLight class] toolbarClass:nil];
    HSUMiniBrowser *miniBrowser = [[HSUMiniBrowser alloc] initWithURL:webURL cellData:cellData];
    miniBrowser.viewController = self;
    nav.viewControllers = @[miniBrowser];
    [self presentViewController:nav animated:YES completion:nil];
    self.modelVC = miniBrowser;
}

- (void)statusUpdated:(NSNotification *)notification
{
    if (notification.object == self.cellDataInNextPage.rawData ||
        [[notification.object objectForKey:@"id_str"] isEqualToString:[self.cellDataInNextPage.rawData objectForKey:@"id_str"]]) {
        
        self.cellDataInNextPage.rawData = [notification.object copy];
        [self.tableView reloadData];
    }
}

@end
