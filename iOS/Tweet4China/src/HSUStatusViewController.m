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
#import "HSUMiniBrowser.h"
#import "HSUNavigationBarLight.h"
#import "HSUProfileViewController.h"
#import "TTTAttributedLabel.h"

@interface HSUStatusViewController ()

@property (nonatomic, strong) NSDictionary *mainStatus;

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
    self.dataSource = [[self.dataSourceClass alloc] initWithDelegate:self status:self.mainStatus];
    
    [super viewDidLoad];
    
    for (HSUTableCellData *cellData in self.dataSource.allData) {
        cellData.renderData[@"photo_tap_delegate"] = self;
    }
    
    [self.tableView registerClass:[HSUMainStatusCell class] forCellReuseIdentifier:kDataType_MainStatus];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(galleryViewDidAppear)
     name:HSUGalleryViewDidAppear
     object:nil];
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(galleryViewDidDisappear)
     name:HSUGalleryViewDidDisappear
     object:nil];
    
    [self.dataSource loadMore];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)galleryViewDidAppear
{
    self.statusBarHidden = YES;
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)galleryViewDidDisappear
{
    self.statusBarHidden = NO;
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)dataSource:(HSUBaseDataSource *)dataSource didFinishRefreshWithError:(NSError *)error
{
    if (error) {
        L(error);
    } else {
        [self.tableView reloadData];
    }
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
    composeVC.defaultTitle = S(@"Reply to @%@", authorScreenName);
    NSString *statusId = mainStatus.rawData[@"id_str"];
    composeVC.inReplyToStatusId = statusId;
    NSArray *userMentions = mainStatus.rawData[@"entities"][@"user_mentions"];
    if (userMentions && userMentions.count) {
        [defaultText appendFormat:@"@%@ ", authorScreenName];
        for (NSDictionary *userMention in userMentions) {
            NSString *screenName = userMention[@"screen_name"];
            [defaultText appendFormat:@"@%@ ", screenName];
        }
        uint start = authorScreenName.length + 2;
        uint length = defaultText.length - authorScreenName.length - 2;
        composeVC.defaultSelectedRange = NSMakeRange(start, length);
    } else {
        [defaultText appendFormat:@" @%@ ", authorScreenName];
    }
    composeVC.defaultText = defaultText;
    UINavigationController *nav = [[UINavigationController alloc] initWithNavigationBarClass:[HSUNavigationBarLight class] toolbarClass:nil];
    nav.viewControllers = @[composeVC];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)attributedLabelDidLongPressed:(TTTAttributedLabel *)label
{
    label.backgroundColor = rgb(215, 230, 242);
    RIButtonItem *cancelItem = [RIButtonItem itemWithLabel:@"Cancel"];
    cancelItem.action = ^{
        label.backgroundColor = kClearColor;
    };
    RIButtonItem *copyItem = [RIButtonItem itemWithLabel:@"Copy Content"];
    copyItem.action = ^{
        label.backgroundColor = kClearColor;
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = label.text;
    };
    UIActionSheet *linkActionSheet = [[UIActionSheet alloc] initWithTitle:nil cancelButtonItem:cancelItem destructiveButtonItem:nil otherButtonItems:copyItem, nil];
    [linkActionSheet showInView:self.view.window];
}

- (void)tappedPhoto:(NSString *)imageUrl withCellData:(HSUTableCellData *)cellData
{
    [self openPhotoURL:[NSURL URLWithString:imageUrl] withCellData:cellData];
}

- (void)openPhoto:(UIImage *)photo withCellData:(HSUTableCellData *)cellData
{
    HSUGalleryView *galleryView = [[HSUGalleryView alloc] initWithData:cellData image:photo];
    [self.view.window addSubview:galleryView];
    [galleryView showWithAnimation:YES];
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)openPhotoURL:(NSURL *)photoURL withCellData:(HSUTableCellData *)cellData
{
    HSUGalleryView *galleryView = [[HSUGalleryView alloc] initWithData:cellData imageURL:photoURL];
    [self.view.window addSubview:galleryView];
    [galleryView showWithAnimation:YES];
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)openWebURL:(NSURL *)webURL withCellData:(HSUTableCellData *)cellData
{
    UINavigationController *nav = [[UINavigationController alloc] initWithNavigationBarClass:[HSUNavigationBarLight class] toolbarClass:nil];
    HSUMiniBrowser *miniBrowser = [[HSUMiniBrowser alloc] initWithURL:webURL cellData:cellData];
    nav.viewControllers = @[miniBrowser];
    [self presentViewController:nav animated:YES completion:nil];
}

@end
