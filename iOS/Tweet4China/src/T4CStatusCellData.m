//
//  T4CStatusCellData.m
//  Tweet4China
//
//  Created by Jason Hsu on 14-1-25.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "T4CStatusCellData.h"
#import "HSUProfileViewController.h"
#import "HSUComposeViewController.h"
#import "T4CTableViewController.h"
#import <SVWebViewController/SVModalWebViewController.h>
#import "OpenInChromeController.h"
#import <FHSTwitterEngine/NSString+URLEncoding.h>
#import <AFNetworking/AFNetworking.h>
#import "T4CRetweetersViewController.h"
#import "HSUGalleryView.h"
#import "HSUAttributedLabel.h"
#import "HSUActivityWeixin.h"
#import "HSUActivityWeixinMoments.h"
#import "T4CTagTimelineViewController.h"
#import "HSUInstagramHandler.h"

@implementation T4CStatusCellData

- (void)touchAvatar
{
    NSDictionary *status = self.mainStatus;
    HSUProfileViewController *profileVC = [[HSUProfileViewController alloc] initWithScreenName:status[@"user"][@"screen_name"]];
    profileVC.profile = status[@"user"];
    UIViewController *viewController = self.target;
    [viewController.navigationController pushViewController:profileVC animated:YES];
}

- (void)reply
{
    [Flurry logEvent:S(@"reply in %@", [self.tableVC.class description])];
    
    NSString *text = S(@"@%@ ", self.mainStatus[@"user"][@"screen_name"]);
    NSRange range = NSMakeRange(text.length, 0);
    NSString *idStr = self.mainStatus[@"id_str"];
    [HSUCommonTools postTweetWithMessage:text image:nil selectedRange:range inReplyToStatusId:idStr];
    notification_post(HSUStatusShowActionsNotification);
}

- (void)rt
{
    [Flurry logEvent:S(@"RT in %@", [self.tableVC.class description])];
    
    NSString *authorScreenName = self.rawData[@"user"][@"screen_name"];
    NSString *text = self.rawData[@"text"];
    NSString *rtText = S(@" RT @%@: %@", authorScreenName, text);
    [HSUCommonTools postTweetWithMessage:rtText];
    notification_post(HSUStatusShowActionsNotification);
}

- (void)retweet
{
    [Flurry logEvent:S(@"retweet in %@", [self.tableVC.class description])];
    
    NSDictionary *status = self.rawData;
    BOOL isRetweetedStatus = NO;
    if (status[@"retweeted_status"]) {
        status = status[@"retweeted_status"];
        isRetweetedStatus = YES;
    }
    
    BOOL retweeted = [status[@"retweeted"] boolValue]; // retweeted by me
    
    if (retweeted) {
        NSString *id_str = status[@"id_str"];
        if (isRetweetedStatus) {
            id_str = self.rawData[@"id_str"];
            __weak typeof(self)weakSelf = self;
            [twitter destroyStatus:id_str success:^(id responseObj) {
                NSMutableDictionary *newStatus = [status mutableCopy];
                newStatus[@"retweeted"] = @(!retweeted);
                notification_post_with_object(HSUStatusUpdatedNotification, newStatus);
                notification_post_with_object(HSUStatusDidDeleteNotification, id_str);
                notification_post(HSUStatusShowActionsNotification);
                [weakSelf.tableVC.tableView reloadData];
            } failure:^(NSError *error) {
                notification_post(HSUStatusShowActionsNotification);
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
                                notification_post_with_object(HSUStatusUpdatedNotification, newStatus);
                                notification_post(HSUStatusShowActionsNotification);
                                [weakSelf.tableVC.tableView reloadData];
                            } failure:^(NSError *error) {
                                notification_post(HSUStatusShowActionsNotification);
                                [twitter dealWithError:error errTitle:_("Delete retweet failed")];
                            }];
                            found = YES;
                            break;
                        }
                    }
                    if (!found) {
                        notification_post(HSUStatusShowActionsNotification);
                    }
                } failure:^(NSError *error) {
                    notification_post(HSUStatusShowActionsNotification);
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
                                notification_post_with_object(HSUStatusUpdatedNotification, newStatus);
                                notification_post(HSUStatusShowActionsNotification);
                                [weakSelf.tableVC.tableView reloadData];
                            } failure:^(NSError *error) {
                                notification_post(HSUStatusShowActionsNotification);
                                [twitter dealWithError:error errTitle:_("Delete retweet failed")];
                            }];
                            found = YES;
                            break;
                        }
                    }
                    if (!found) {
                        notification_post(HSUStatusShowActionsNotification);
                    }
                } failure:^(NSError *error) {
                    notification_post(HSUStatusShowActionsNotification);
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
                NSMutableDictionary *newRawData = [weakSelf.rawData mutableCopy];
                newRawData[@"retweeted_status"] = newStatus;
                notification_post_with_object(HSUStatusUpdatedNotification, newRawData);
            } else {
                notification_post_with_object(HSUStatusUpdatedNotification, newStatus);
            }
            notification_post(HSUStatusShowActionsNotification);
            [weakSelf.tableVC.tableView reloadData];
        } failure:^(NSError *error) {
            notification_post(HSUStatusShowActionsNotification);
            [twitter dealWithError:error errTitle:_("Retweet failed")];
        }];
    }
}

- (void)favorite
{
    [Flurry logEvent:S(@"favorite in %@", [self.tableVC.class description])];
    
    NSDictionary *rawData = self.mainStatus;
    
    NSString *id_str = rawData[@"id_str"];
    BOOL favorited = [rawData[@"favorited"] boolValue];
    
    if (favorited) {
        __weak typeof(self)weakSelf = self;
        [twitter unMarkStatus:id_str success:^(id responseObj) {
            NSMutableDictionary *newRawData = [rawData mutableCopy];
            newRawData[@"favorited"] = @(!favorited);
            notification_post_with_object(HSUStatusUpdatedNotification, newRawData);
            [weakSelf.tableVC.tableView reloadData];
        } failure:^(NSError *error) {
            [twitter dealWithError:error errTitle:_("Delete Favorite failed")];
        }];
    } else {
        __weak typeof(self)weakSelf = self;
        [twitter markStatus:id_str success:^(id responseObj) {
            NSMutableDictionary *newRawData = [rawData mutableCopy];
            newRawData[@"favorited"] = @(!favorited);
            notification_post_with_object(HSUStatusUpdatedNotification, newRawData);
            weakSelf.rawData = newRawData;
            [weakSelf.tableVC.tableView reloadData];
        } failure:^(NSError *error) {
            [twitter dealWithError:error errTitle:_("Favorite Tweet failed")];
        }];
    }
}

- (void)delete
{
    [Flurry logEvent:S(@"delete in %@", [self.tableVC.class description])];
    
    RIButtonItem *cancelItem = [RIButtonItem itemWithLabel:_("Cancel")];
    __weak typeof(self)weakSelf = self;
    cancelItem.action = ^{
        [weakSelf.tableVC.tableView reloadData];
    };
    RIButtonItem *deleteItem = [RIButtonItem itemWithLabel:_("Delete Tweet")];
    deleteItem.action = ^{
        NSDictionary *rawData = weakSelf.rawData;
        NSString *sid = rawData[@"id"];
        
        [SVProgressHUD showWithStatus:nil];
        [twitter destroyStatus:sid success:^(id responseObj) {
            [SVProgressHUD dismiss];
            if ([weakSelf.dataType isEqualToString:kDataType_MainStatus]) {
                [weakSelf.tableVC.navigationController popViewControllerAnimated:YES];
            } else {
                [weakSelf.tableVC.data removeObject:weakSelf];
                [weakSelf.tableVC.tableView reloadData];
            }
            notification_post_with_object(HSUStatusDidDeleteNotification, sid);
        } failure:^(NSError *error) {
            if (error.code == 204) {
                [SVProgressHUD dismiss];
                if ([weakSelf.dataType isEqualToString:kDataType_MainStatus]) {
                    [weakSelf.tableVC.navigationController popViewControllerAnimated:YES];
                } else {
                    [weakSelf.tableVC.data removeObject:weakSelf];
                    [weakSelf.tableVC.tableView reloadData];
                }
                notification_post_with_object(HSUStatusDidDeleteNotification, sid);
            } else {
                [SVProgressHUD showErrorWithStatus:_("Delete Tweet failed")];
            }
        }];
    };
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil cancelButtonItem:cancelItem destructiveButtonItem:deleteItem otherButtonItems:nil, nil];
    [actionSheet showInView:self.tableVC.view.window];
}

- (void)more
{
    [Flurry logEvent:S(@"more in %@", [self.tableVC.class description])];
    
    NSDictionary *rawData = self.rawData;
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil cancelButtonItem:nil destructiveButtonItem:nil otherButtonItems:nil];
    uint count = 0;
    
    NSArray *urls = rawData[@"entities"][@"urls"];
    NSArray *medias = rawData[@"entities"][@"media"];
    if (medias && medias.count) {
        urls = [urls arrayByAddingObjectsFromArray:medias];
    }
    
    if (urls && urls.count) { // has link
        RIButtonItem *tweetLinkItem = [RIButtonItem itemWithLabel:_("Tweet Link")];
        __weak typeof(self)weakSelf = self;
        tweetLinkItem.action = ^{
            weakSelf.showingMore = NO;
            [Flurry logEvent:S(@"tweet link in %@", [weakSelf.tableVC.class description])];
            
            if ([weakSelf.tableVC.presentedViewController isKindOfClass:[SVModalWebViewController class]] || urls.count == 1) {
                NSString *link = [urls objectAtIndex:0][@"expanded_url"];
                [HSUCommonTools postTweetWithMessage:S(@" %@", link)];
            } else {
                UIActionSheet *selectLinkActionSheet = [[UIActionSheet alloc] initWithTitle:nil cancelButtonItem:nil destructiveButtonItem:nil otherButtonItems:nil, nil];
                for (NSDictionary *urlDict in urls) {
                    NSString *displayUrl = urlDict[@"display_url"];
                    NSString *expendedUrl = urlDict[@"expanded_url"];
                    RIButtonItem *buttonItem = [RIButtonItem itemWithLabel:displayUrl];
                    buttonItem.action = ^{
                        [HSUCommonTools postTweetWithMessage:S(@" %@", expendedUrl)];
                    };
                    [selectLinkActionSheet addButtonItem:buttonItem];
                }
                
                RIButtonItem *cancelItem = [RIButtonItem itemWithLabel:_("Cancel")];
                [selectLinkActionSheet addButtonItem:cancelItem];
                
                [selectLinkActionSheet setCancelButtonIndex:urls.count];
                [selectLinkActionSheet showInView:self.tableVC.view.window];
            }
        };
        [actionSheet addButtonItem:tweetLinkItem];
        count ++;
        
        RIButtonItem *copyLinkItem = [RIButtonItem itemWithLabel:_("Copy Link")];
        copyLinkItem.action = ^{
            weakSelf.showingMore = NO;
            [Flurry logEvent:S(@"copy link in %@", [weakSelf.tableVC.class description])];
            
            if ([weakSelf.tableVC.presentedViewController isKindOfClass:[SVModalWebViewController class]] || urls.count == 1) {
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
                [selectLinkActionSheet showInView:self.tableVC.view.window];
            }
        };
        [actionSheet addButtonItem:copyLinkItem];
        count ++;
        
        RIButtonItem *mailLinkItem = [RIButtonItem itemWithLabel:_("Mail Link")];
        mailLinkItem.action = ^{
            weakSelf.showingMore = NO;
            [Flurry logEvent:S(@"mail link in %@", [weakSelf.tableVC.class description])];
            
            if ([weakSelf.tableVC.presentedViewController isKindOfClass:[SVModalWebViewController class]] || urls.count == 1) {
                NSString *link = [urls objectAtIndex:0][@"expanded_url"];
                NSString *subject = _("Link from Twitter");
                NSString *body = S(@"<a href=\"%@\">%@</a>", link, link);
                [HSUCommonTools sendMailWithSubject:subject body:body presentFromViewController:weakSelf.tableVC];
            } else {
                UIActionSheet *selectLinkActionSheet = [[UIActionSheet alloc] initWithTitle:nil cancelButtonItem:nil destructiveButtonItem:nil otherButtonItems:nil, nil];
                for (NSDictionary *urlDict in urls) {
                    NSString *displayUrl = urlDict[@"display_url"];
                    NSString *expendedUrl = urlDict[@"expanded_url"];
                    RIButtonItem *buttonItem = [RIButtonItem itemWithLabel:displayUrl];
                    buttonItem.action = ^{
                        NSString *subject = _("Link from Twitter");
                        NSString *body = S(@"<a href=\"%@\">%@</a>", expendedUrl, displayUrl);
                        [HSUCommonTools sendMailWithSubject:subject body:body presentFromViewController:weakSelf.tableVC];
                    };
                    [selectLinkActionSheet addButtonItem:buttonItem];
                }
                
                RIButtonItem *cancelItem = [RIButtonItem itemWithLabel:_("Cancel")];
                [selectLinkActionSheet addButtonItem:cancelItem];
                
                [selectLinkActionSheet setCancelButtonIndex:urls.count];
                [selectLinkActionSheet showInView:weakSelf.tableVC.view.window];
            }
        };
        [actionSheet addButtonItem:mailLinkItem];
        count ++;
        
        RIButtonItem *openInSafariItem = [RIButtonItem itemWithLabel:_("Open in Safari")];
        openInSafariItem.action = ^{
            weakSelf.showingMore = NO;
            [Flurry logEvent:S(@"open in safari in %@", [weakSelf.tableVC.class description])];
            
            if ([weakSelf.tableVC.presentedViewController isKindOfClass:[SVModalWebViewController class]] || urls.count == 1) {
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
                [selectLinkActionSheet showInView:weakSelf.tableVC.view.window];
            }
        };
        [actionSheet addButtonItem:openInSafariItem];
        count ++;
        
        if ([[OpenInChromeController sharedInstance] isChromeInstalled]) {
            RIButtonItem *openInChromeItem = [RIButtonItem itemWithLabel:_("Open in Chrome")];
            openInChromeItem.action = ^{
                weakSelf.showingMore = NO;
                [Flurry logEvent:S(@"open in chrome in %@", [weakSelf.tableVC.class description])];
                
                if ([weakSelf.tableVC.presentedViewController isKindOfClass:[SVModalWebViewController class]] || urls.count == 1) {
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
                    [selectLinkActionSheet showInView:weakSelf.tableVC.view.window];
                }
            };
            [actionSheet addButtonItem:openInChromeItem];
            count ++;
        }
    }
    
    NSString *id_str = rawData[@"id_str"];
    NSString *link = S(@"https://twitter.com/rtfocus/status/%@", id_str);
    
    __weak typeof(self)weakSelf = self;
    RIButtonItem *copyLinkToTweetItem = [RIButtonItem itemWithLabel:_("Copy Link of Tweet")];
    copyLinkToTweetItem.action = ^{
        weakSelf.showingMore = NO;
        [Flurry logEvent:S(@"copy Link of tweet in %@", [self.tableVC.class description])];
        
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = link;
    };
    [actionSheet addButtonItem:copyLinkToTweetItem];
    count ++;
    
    RIButtonItem *mailTweetItem = [RIButtonItem itemWithLabel:_("Mail Tweet")];
    mailTweetItem.action = ^{
        weakSelf.showingMore = NO;
        [Flurry logEvent:S(@"mail tweet in %@", [weakSelf.tableVC.class description])];
        
        [twitter oembedStatus:id_str success:^(id responseObj) {
            notification_post(HSUStatusShowActionsNotification);
            NSString *subject = _("Link from Twitter");
            [HSUCommonTools sendMailWithSubject:subject
                                           body:responseObj[@"html"]
                      presentFromViewController:weakSelf.tableVC];
        } failure:^(NSError *error) {
            notification_post(HSUStatusShowActionsNotification);
            [twitter dealWithError:error errTitle:_("Fetch HTML failed")];
        }];
    };
    [actionSheet addButtonItem:mailTweetItem];
    count ++;
    
    RIButtonItem *translateItem = [RIButtonItem itemWithLabel:_("Translate by Youdao")];
    translateItem.action = ^{
        weakSelf.showingMore = NO;
        [SVProgressHUD showWithStatus:_("Translating")];
        dispatch_async(GCDBackgroundThread, ^{
            NSString *text = weakSelf.mainStatus[@"text"];
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
    
    RIButtonItem *cancelItem = [RIButtonItem itemWithLabel:_("Cancel")];
    [actionSheet addButtonItem:cancelItem];
    cancelItem.action = ^{
        weakSelf.showingMore = NO;
    };
    
    [actionSheet setCancelButtonIndex:count];
    [actionSheet showInView:[UIApplication sharedApplication].keyWindow];
    
    notification_post(HSUStatusShowActionsNotification);
    
    self.showingMore = YES;
    [self.tableVC.tableView reloadData];
}

- (void)retweets
{
    T4CRetweetersViewController *retweetersVC = [[T4CRetweetersViewController alloc] init];
    NSDictionary *status = self.mainStatus;
    retweetersVC.statusID = [status[@"id"] longLongValue];
    [self.tableVC.navigationController pushViewController:retweetersVC animated:YES];
}

- (void)favorites
{
    NSString *statusID = self.rawData[@"id_str"];
    SVModalWebViewController *webVC = [[SVModalWebViewController alloc] initWithAddress:S(@"http://favstar.fm/t/%@", statusID)];
    webVC.modalPresentationStyle = UIModalPresentationPageSheet;
    [self.tableVC presentViewController:webVC animated:YES completion:nil];
}

- (void)openPhotoURL:(NSURL *)photoURL
{
    HSUGalleryView *galleryView = [[HSUGalleryView alloc] initWithData:self imageURL:photoURL];
    [self.tableVC.view.window addSubview:galleryView];
    [galleryView showWithAnimation:YES];
}

- (void)photoButtonTouched:(UIView *)photoView
{
    [self photoButtonTouched:photoView originalImageURL:nil];
}

- (void)photoButtonTouched:(UIView *)photoView originalImageURL:(NSURL *)originalImageURL
{
    HSUGalleryView *galleryView = [[HSUGalleryView alloc] initStartPhotoView:photoView
                                                            originalImageURL:originalImageURL];
    [self.tableVC.view.window addSubview:galleryView];
    [galleryView showWithAnimation:YES];
}

- (void)openWebURL:(NSURL *)webURL withCellData:(T4CStatusCellData *)cellData
{
    if ([HSUInstagramHandler openInInstagramWithMediaID:cellData.instagramMediaID]) {
        return;
    }
    SVModalWebViewController *webViewController = [[SVModalWebViewController alloc] initWithURL:webURL];
    webViewController.modalPresentationStyle = UIModalPresentationPageSheet;
    [self.tableVC presentViewController:webViewController animated:YES completion:NULL];
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
        [linkActionSheet showInView:[UIApplication sharedApplication].keyWindow];
        return;
    }
    
    // Commen Link
    RIButtonItem *cancelItem = [RIButtonItem itemWithLabel:_("Cancel")];
    RIButtonItem *tweetLinkItem = [RIButtonItem itemWithLabel:_("Tweet Link")];
    tweetLinkItem.action = ^{
        [HSUCommonTools postTweetWithMessage:S(@" %@", url.absoluteString)];
    };
    RIButtonItem *copyLinkItem = [RIButtonItem itemWithLabel:_("Copy Link")];
    copyLinkItem.action = ^{
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = url.absoluteString;
    };
    RIButtonItem *mailLinkItem = [RIButtonItem itemWithLabel:_("Mail Link")];
    __weak typeof(self)weakSelf = self;
    mailLinkItem.action = ^{
        [weakSelf.tableVC.presentedViewController dismiss];
        NSString *body = S(@"<a href=\"%@\">%@</a><br><br>", url.absoluteString, url.absoluteString);
        NSString *subject = _("Link from Twitter");
        [HSUCommonTools sendMailWithSubject:subject body:body presentFromViewController:weakSelf.tableVC];
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
    
    [linkActionSheet showInView:[UIApplication sharedApplication].keyWindow];
}

- (void)attributedLabel:(TTTAttributedLabel *)label didReleaseLinkWithArguments:(NSDictionary *)arguments
{
    NSURL *url = [arguments objectForKey:@"url"];
    T4CStatusCellData *cellData = [arguments objectForKey:@"cell_data"];
    __weak typeof(self)weakSelf = self;
    if ([url.absoluteString hasPrefix:@"user://"]) {
        NSString *screenName = [url.absoluteString substringFromIndex:7];
        HSUProfileViewController *profileVC = [[HSUProfileViewController alloc] initWithScreenName:screenName];
        [self.tableVC.navigationController pushViewController:profileVC animated:YES];
    } else if ([url.absoluteString hasPrefix:@"tag://"]) {
        NSString *hashTag = [url.absoluteString substringFromIndex:6];
        T4CTagTimelineViewController *tagVC = [[T4CTagTimelineViewController alloc] init];
        tagVC.tag = hashTag;
        [weakSelf.tableVC.navigationController pushViewController:tagVC animated:YES];
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
                [self openPhotoURL:[NSURL URLWithString:mediaURLHttps]];
                return;
            }
        }
        [self openWebURL:url withCellData:cellData];
    }
}

- (NSDictionary *)mainStatus
{
    return self.rawData[@"retweeted_status"] ?: self.rawData;
}

@end
