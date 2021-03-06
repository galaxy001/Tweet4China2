//
//  HSUStatusView.m
//  Tweet4China
//
//  Created by Jason Hsu on 4/27/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUStatusView.h"
#import "GTMNSString+HTML.h"
#import <AFNetworking/AFNetworking.h>
#import "HSUAttributedLabel.h"
#import "NSDate+Additions.h"
#import "HSUThirdPartyMediaCache.h"
#import "HSUInstagramHandler.h"

#define ambient_H 14
#define info_H 16
#define margin_W 10
#define avatar_S 48
#define ambient_S 20
#define textAL_LHM 1.3
#define padding_S 10
#define PhotoPreviewMaxWidth 530

#define retweeted_R @"ic_ambient_retweet"

@implementation HSUStatusView
{
    UIView *ambientArea;
    UIImageView *ambientI;
    UILabel *ambientL;
    UIButton *avatarB;
    UIView *infoArea;
    UILabel *nameL;
    UILabel *screenNameL;
    UIImageView *attrI; // photo/video/geo/summary/audio/convo
    UILabel *timeL;
}

@synthesize avatarB;

- (void)dealloc
{
    notification_remove_observer(self);
}

- (id)initWithFrame:(CGRect)frame style:(HSUStatusViewStyle)style
{
    self = [super initWithFrame:frame];
    if (self) {
        notification_add_observer(HSUSettingsUpdatedNotification, self, @selector(settingsUpdated:));
        
        _style = style;
        
        ambientArea = [[UIView alloc] init];
        [self addSubview:ambientArea];
        
        infoArea = [[UIView alloc] init];
        [self addSubview:infoArea];
        
        ambientI = [[UIImageView alloc] init];
        [ambientArea addSubview:ambientI];
        
        ambientL = [[UILabel alloc] init];
        [ambientArea addSubview:ambientL];
        
        avatarB = [[UIButton alloc] init];
        [self addSubview:avatarB];
        
        nameL = [[UILabel alloc] init];
        [infoArea addSubview:nameL];
        
        screenNameL = [[UILabel alloc] init];
        [infoArea addSubview:screenNameL];
        
        attrI = [[UIImageView alloc] init];
        [infoArea addSubview:attrI];
        
        timeL = [[UILabel alloc] init];
        [infoArea addSubview:timeL];
        
        HSUAttributedLabel *textAL = [[HSUAttributedLabel alloc] initWithFrame:CGRectZero];
        [self addSubview:textAL];
        self.textAL = textAL;
        
        UIButton *imagePreviewButton = [[UIButton alloc] init];
        [self addSubview:imagePreviewButton];
        self.imagePreviewButton = imagePreviewButton;
        [imagePreviewButton addTarget:self action:@selector(imageButtonTouched) forControlEvents:UIControlEventTouchUpInside];
        
        [self _setupStyle];
    }
    return self;
}

- (void)_setupStyle
{
    ambientL.textColor = kGrayColor;
    ambientL.font = [UIFont systemFontOfSize:13];
    if (Sys_Ver < 7) {
        ambientL.highlightedTextColor = kWhiteColor;
    }
    ambientL.backgroundColor = kClearColor;
    
    nameL.textColor = kBlackColor;
    nameL.font = [UIFont boldSystemFontOfSize:14];
    if (Sys_Ver < 7) {
        nameL.highlightedTextColor = kWhiteColor;
    }
    nameL.backgroundColor = kClearColor;
    
    avatarB.layer.masksToBounds = YES;
    avatarB.backgroundColor = bw(229);
    
    screenNameL.textColor = kGrayColor;
    screenNameL.font = [UIFont systemFontOfSize:12];
    if (Sys_Ver < 7) {
        screenNameL.highlightedTextColor = kWhiteColor;
    }
    screenNameL.backgroundColor = kClearColor;
    
    timeL.textColor = kGrayColor;
    timeL.font = [UIFont systemFontOfSize:12];
    if (Sys_Ver < 7) {
        timeL.highlightedTextColor = kWhiteColor;
    }
    timeL.backgroundColor = kClearColor;
    
    self.textAL.font = [UIFont systemFontOfSize:[setting(HSUSettingTextSize) integerValue]];
    self.textAL.backgroundColor = kClearColor;
    self.textAL.textColor = kBlackColor;
    if (Sys_Ver < 7) {
        self.textAL.highlightedTextColor = kWhiteColor;
    }
    self.textAL.lineBreakMode = NSLineBreakByWordWrapping;
    self.textAL.numberOfLines = 0;
    self.textAL.linkAttributes = @{(NSString *)kCTUnderlineStyleAttributeName: @(NO),
                              (NSString *)kCTForegroundColorAttributeName: (id)cgrgb(30, 98, 164)};
    self.textAL.activeLinkAttributes = @{(NSString *)kTTTBackgroundFillColorAttributeName: (id)cgrgb(215, 230, 242),
                                    (NSString *)kTTTBackgroundCornerRadiusAttributeName: @(2)};
    self.textAL.verticalAlignment = TTTAttributedLabelVerticalAlignmentTop;
    self.textAL.lineHeightMultiple = textAL_LHM;
    
    if (self.style == HSUStatusViewStyle_Default) {
        avatarB.frame = ccr(0, 0, avatar_S, avatar_S);
    } else if (self.style == HSUStatusViewStyle_Gallery) {
        attrI.hidden = YES;
        ambientL.textColor = kWhiteColor;
        nameL.textColor = kWhiteColor;
        screenNameL.textColor = kWhiteColor;
        timeL.textColor = kWhiteColor;
        self.textAL.textColor = kWhiteColor;
        avatarB.frame = ccr(0, 0, avatar_S, avatar_S);
    } else if (self.style == HSUStatusViewStyle_Light) {
        attrI.hidden = YES;
        avatarB.frame = ccr(0, 0, avatar_S, avatar_S);
    } else if (self.style == HSUStatusViewStyle_Chat) {
        avatarB.frame = ccr(avatar_S-32, 0, 32, 32);
        attrI.hidden = YES;
    }
    self.imagePreviewButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.imagePreviewButton.backgroundColor = rgb(225, 232, 227);
    self.imagePreviewButton.layer.cornerRadius = 3;
    self.imagePreviewButton.clipsToBounds = YES;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // set frames
    CGFloat cw = self.width;
    ambientArea.frame = ccr(0, 0, cw, ambient_S);
    ambientI.frame = ccr(avatar_S-ambient_S, (ambient_H-ambient_S)/2, ambient_S, ambient_S);
    ambientL.frame = ccr(avatar_S+padding_S, 0, cw-ambientI.right-padding_S, ambient_H);
    
    if (!ambientArea.hidden) {
        avatarB.frame = ccr(avatarB.left, ambientArea.bottom, avatarB.width, avatarB.height);
    } else {
        avatarB.frame = ccr(avatarB.left, 0, avatarB.width, avatarB.height);
    }
    [avatarB makeCornerRadius];
    
    infoArea.frame = ccr(ambientL.left, avatarB.top, cw-ambientL.left, info_H);
    self.textAL.frame = ccr(ambientL.left, infoArea.bottom, infoArea.width, self.data.textHeight + 3);
    
    [timeL sizeToFit];
    timeL.frame = ccr(infoArea.width-timeL.width, -1, timeL.width, timeL.height);
    
    [attrI sizeToFit];
    attrI.frame = ccr(timeL.left-attrI.width-3, -1, attrI.width, attrI.height);
    
    [nameL sizeToFit];
    nameL.frame = ccr(0, -3, MIN(attrI.left-12, nameL.width), nameL.height);
    
    [screenNameL sizeToFit];
    screenNameL.frame = ccr(nameL.right+3, -1, attrI.left-nameL.right-2, screenNameL.height);
    
    self.imagePreviewButton.frame = ccr(self.textAL.left, self.textAL.bottom+5, MIN(self.textAL.width, PhotoPreviewMaxWidth), MIN(self.textAL.width, PhotoPreviewMaxWidth)/2);
}

- (void)setupWithData:(T4CStatusCellData *)cellData
{
    self.data = cellData;
    
    // ambient
    NSDictionary *retweetedStatus = cellData.rawData[@"retweeted_status"];
    ambientI.hidden = NO;
    if (retweetedStatus) {
        ambientI.imageName = retweeted_R;
        NSString *ambientText = S(@"%@ retweeted", cellData.rawData[@"user"][@"name"]);
        ambientL.text = ambientText;
        ambientArea.hidden = NO;
    } else {
        ambientI.imageName = nil;
        ambientL.text = nil;
        ambientArea.hidden = YES;
        ambientArea.bounds = CGRectZero;
    }
    
    NSDictionary *entities = cellData.mainStatus[@"entities"];
    
    // info
    NSString *avatarUrl = nil;
    avatarUrl = cellData.mainStatus[@"user"][@"profile_image_url_https"];
    nameL.text = cellData.mainStatus[@"user"][@"name"];
    screenNameL.text = S(@"@%@", cellData.mainStatus[@"user"][@"screen_name"]);
    avatarUrl = [avatarUrl stringByReplacingOccurrencesOfString:@"normal" withString:@"bigger"];
    [avatarB setImageWithUrlStr:avatarUrl
                       forState:UIControlStateNormal
                    placeHolder:nil];
    
    NSDictionary *geo = cellData.mainStatus[@"geo"];
    NSDictionary *place = cellData.mainStatus[@"place"];
    
    // attr
    attrI.imageName = nil;
    if (!self.data.attr || (self.data.hasPhoto && !self.data.photoUrl)) {
        if ([cellData.mainStatus[@"in_reply_to_status_id_str"] length]) {
            self.data.attr = @"convo";
        }
        if (entities) {
            NSArray *medias = entities[@"media"];
            NSArray *urls = entities[@"urls"];
            if (medias.count) {
                NSDictionary *media = medias[0];
                NSString *type = media[@"type"];
                if ([type isEqualToString:@"photo"]) {
                    if (!self.data.attr) {
                        self.data.attr = @"photo";
                    }
                    self.data.hasPhoto = YES;
                    self.data.photoUrl = media[@"media_url_https"];
                }
            } else if (urls.count) {
                for (NSDictionary *urlDict in urls) {
                    NSString *expandedUrl = urlDict[@"expanded_url"];
                    NSString *aName = [self _attrForUrl:expandedUrl];
                    if (!self.data.attr) {
                        if (aName) {
                            self.data.attr = aName;
                        }
                    }
                    if ([aName isEqualToString:@"photo"]) {
                        self.data.hasPhoto = YES;
                    }
                    if (aName) {
                        break;
                    }
                }
            }
        }
        if (!self.data.attr && ([geo isKindOfClass:[NSDictionary class]] ||
                                                    [place isKindOfClass:[NSDictionary class]])) {
            if ([geo isKindOfClass:[NSDictionary class]]) {
                if (![geo[@"coordinates"] isEqualToArray:@[@0, @0]]) {
                    self.data.attr = @"geo";
                }
            } else if ([place isKindOfClass:[NSDictionary class]]) {
                self.data.attr = @"geo";
            }
        }
        
        if (!self.data.attr) {
            self.data.attr = @"";
        }
    }
    
    if ([self.data.attr length]) {
        attrI.imageName = S(@"ic_tweet_attr_%@_default", self.data.attr);
    } else {
        attrI.imageName = nil;
    }
    self.imagePreviewButton.hidden = YES;
    if (self.data.hasPhoto && boolSetting(HSUSettingPhotoPreview)) {
        self.imagePreviewButton.hidden = NO;
        self.imagePreviewButton.backgroundColor = rgb(225, 232, 227);
        [self.imagePreviewButton setImageWithUrlStr:[HSUCommonTools smallTwitterImageUrlStr:self.data.photoUrl]
                                           forState:UIControlStateNormal
                                        placeHolder:nil
                                            success:^
        {
            self.imagePreviewButton.backgroundColor = kClearColor;
        } failure:^
        {
            
        }];
    }
    
    // time
    NSDate *createdDate = [twitter getDateFromTwitterCreatedAt:cellData.mainStatus[@"created_at"]];
    timeL.text = createdDate.twitterDisplay;
    
    // text
    NSString *text = [cellData.mainStatus[@"text"] gtm_stringByUnescapingFromHTML];
    self.textAL.text = text;
    if (entities) {
        NSMutableArray *urlDicts = [NSMutableArray array];
        NSArray *urls = entities[@"urls"];
        NSArray *medias = entities[@"media"];
        if (urls && urls.count) {
            [urlDicts addObjectsFromArray:urls];
        }
        if (medias && medias.count) {
            [urlDicts addObjectsFromArray:medias];
        }
        if (urlDicts && urlDicts.count) {
            for (NSDictionary *urlDict in urlDicts) {
                NSString *url = urlDict[@"url"];
                NSString *displayUrl = urlDict[@"display_url"];
                NSString *expandedUrl = urlDict[@"expanded_url"];
                NSString *mediaUrlHttps = urlDict[@"media_url_https"];
                if (url && url.length && displayUrl && displayUrl.length) {
                    if ([self.data.attr isEqualToString:@"photo"]
                        && boolSetting(HSUSettingPhotoPreview)
                        && ![HSUInstagramHandler isInstagramLink:expandedUrl]
                        && [self.data.photoUrl isEqualToString:mediaUrlHttps]
                        ) {
                        text = [text stringByReplacingOccurrencesOfString:url withString:@""];
                    } else {
                        text = [text stringByReplacingOccurrencesOfString:url withString:displayUrl];
                    }
                }
            }
            self.textAL.text = text;
            if (self.style == HSUStatusViewStyle_Default) {
                for (NSDictionary *urlDict in urlDicts) {
                    NSString *url = urlDict[@"url"];
                    NSString *displayUrl = urlDict[@"display_url"];
                    NSString *expanedUrl = urlDict[@"expanded_url"];
                    if (url && url.length && displayUrl && displayUrl.length && expanedUrl && expanedUrl.length) {
                        NSRange range = [text rangeOfString:displayUrl];
                        [self.textAL addLinkToURL:[NSURL URLWithString:expanedUrl] withRange:range];
                    }
                }
            }
        }
    }
    self.textAL.delegate = self;
}

- (NSString *)_attrForUrl:(NSString *)url
{
    if ([url hasPrefix:@"http://4sq.com"] ||
        [url hasPrefix:@"http://youtube.com"]) {
        
        return @"summary";
        
    } else if ([url hasPrefix:@"http://youtube.com"] ||
               [url hasPrefix:@"http://snpy.tv"]) {
        
        return @"video";
        
    } else if (boolSetting(HSUSettingPhotoPreview) &&
               [HSUInstagramHandler isInstagramLink:url]) {
        
        if ([url hasSuffix:@"_v/"]) {
            return @"video";
        }
        
        NSString *mediaUrl = self.data.photoUrl;
        if (mediaUrl) {
            self.imagePreviewButton.hidden = NO;
            [self.imagePreviewButton setImageWithUrlStr:mediaUrl
                                               forState:UIControlStateNormal
                                            placeHolder:nil];
        } else if ((mediaUrl = [HSUThirdPartyMediaCache mediaForWebUrl:url][@"url"])) {
            self.data.photoUrl = mediaUrl;
            self.data.thirdPartyMediaID = [HSUThirdPartyMediaCache mediaForWebUrl:url][@"media_id"];
            self.imagePreviewButton.hidden = NO;
            [self.imagePreviewButton setImageWithUrlStr:mediaUrl
                                               forState:UIControlStateNormal
                                            placeHolder:nil];
        } else {
            NSString *instagramAPIUrl = [HSUInstagramHandler apiUrlStringWithLink:url];
            self.data.thirdPartyMediaUrl = instagramAPIUrl;
            NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:instagramAPIUrl]];
            __weak typeof(self) weakSelf = self;
            AFHTTPRequestOperation *instagramer = [AFJSONRequestOperation
                                                   JSONRequestOperationWithRequest:request
                                                   success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON)
            {
                if ([JSON isKindOfClass:[NSDictionary class]]) {
                    if ([instagramAPIUrl isEqualToString:weakSelf.data.thirdPartyMediaUrl]) {
                        [HSUThirdPartyMediaCache setMedia:JSON forWebUrl:url];
                        weakSelf.data.thirdPartyMediaID = JSON[@"media_id"];
                        NSString *imageUrl = JSON[@"url"];
                        if ([imageUrl hasSuffix:@".mp4"]) {
                            weakSelf.data.videoUrl = imageUrl;
                        } else {
                            weakSelf.data.photoUrl = imageUrl;
                            weakSelf.imagePreviewButton.hidden = NO;
                            [weakSelf.imagePreviewButton setImageWithUrlStr:imageUrl
                                                                   forState:UIControlStateNormal
                                                                placeHolder:nil];
                        }
                    }
                }
            } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                
            }];
            [instagramer start];
        }
        return @"photo";
    }
    return nil;
}

+ (CGFloat)_textHeightWithCellData:(T4CStatusCellData *)data constraintWidth:(CGFloat)constraintWidth attrName:(NSString *)attrName photoUrl:(NSString *)photoUrl
{
    NSDictionary *status = data.mainStatus;
    NSString *text = [status[@"text"] gtm_stringByUnescapingFromHTML];
    NSDictionary *entities = status[@"entities"];
    if (entities) {
        NSMutableArray *urlDicts = [NSMutableArray array];
        NSArray *urls = entities[@"urls"];
        NSArray *medias = entities[@"media"];
        if (urls.count) {
            [urlDicts addObjectsFromArray:urls];
        }
        if (medias.count) {
            [urlDicts addObjectsFromArray:medias];
        }
        if (urlDicts.count) {
            for (NSDictionary *urlDict in urlDicts) {
                NSString *url = urlDict[@"url"];
                NSString *displayUrl = urlDict[@"display_url"];
                NSString *expandedUrl = urlDict[@"expanded_url"];
                NSString *mediaUrlHttps = urlDict[@"media_url_https"];
                if (url && url.length && displayUrl && displayUrl.length) {
                    if ([attrName isEqualToString:@"photo"]
                        && boolSetting(HSUSettingPhotoPreview)
                        && ![HSUInstagramHandler isInstagramLink:expandedUrl]
                        && [photoUrl isEqualToString:mediaUrlHttps]
                        ) {
                        text = [text stringByReplacingOccurrencesOfString:url withString:@""];
                    } else {
                        text = [text stringByReplacingOccurrencesOfString:url withString:displayUrl];
                    }
                }
            }
        }
    }
    
    static TTTAttributedLabel *testSizeLabel = nil;
    if (!statusViewTestLabelInited || testSizeLabel) {
        statusViewTestLabelInited = YES;
        TTTAttributedLabel *textAL = [[HSUAttributedLabel alloc] initWithFrame:CGRectZero];
        textAL.font = [UIFont systemFontOfSize:[GlobalSettings[HSUSettingTextSize] integerValue]];
        textAL.lineBreakMode = NSLineBreakByWordWrapping;
        textAL.numberOfLines = 0;
        textAL.linkAttributes = @{(NSString *)kCTUnderlineStyleAttributeName: @(NO),
                                  (NSString *)kCTForegroundColorAttributeName: (id)cgrgb(30, 98, 164)};
        textAL.activeLinkAttributes = @{(NSString *)kTTTBackgroundFillColorAttributeName: (id)cgrgb(215, 230, 242),
                                        (NSString *)kTTTBackgroundCornerRadiusAttributeName: @(2)};
        textAL.verticalAlignment = TTTAttributedLabelVerticalAlignmentTop;
        textAL.lineHeightMultiple = textAL_LHM;
        
        testSizeLabel = textAL;
    }
    testSizeLabel.text = text;
    
    constraintWidth = IPHONE ? 232 : 538;
    CGFloat textHeight = [testSizeLabel sizeThatFits:ccs(constraintWidth, 0)].height;
    data.textHeight = textHeight;
    return textHeight;
}

+ (CGFloat)heightForData:(T4CStatusCellData *)data constraintWidth:(CGFloat)constraintWidth
{
    CGFloat height = 0;
    CGFloat leftHeight = 0;
    
    if (data.rawData[@"retweeted_status"]) {
        height += ambient_H; // add ambient
        leftHeight += ambient_H;
    }
    height += info_H; // add info
    
    NSDictionary *rawData = data.mainStatus;
    NSDictionary *entities = rawData[@"entities"];
    NSString *attrName = nil;
    NSString *photoUrl = nil;
    if (entities) {
        NSArray *medias = entities[@"media"];
        NSArray *urls = entities[@"urls"];
        if (medias.count) {
            NSDictionary *media = medias[0];
            NSString *type = media[@"type"];
            if ([type isEqualToString:@"photo"]) {
                attrName = @"photo";
                photoUrl = media[@"media_url_https"];
            }
        } else if (urls.count) {
            for (NSDictionary *urlDict in urls) {
                NSString *expandedUrl = urlDict[@"expanded_url"];
                if (([HSUInstagramHandler isInstagramLink:expandedUrl])
                    && ![expandedUrl hasSuffix:@"_v/"]) {
                    attrName = @"photo";
                    break;
                }
            }
        }
    }
    if ([attrName isEqualToString:@"photo"] && boolSetting(HSUSettingPhotoPreview)) {
        if (IPHONE) {
            height += 120 + 20;
        } else {
            height += PhotoPreviewMaxWidth/2 + 20;
        }
    }
    
    height += [self _textHeightWithCellData:data constraintWidth:constraintWidth-avatar_S-padding_S attrName:attrName photoUrl:photoUrl] + padding_S + 6;
    
    leftHeight += avatar_S; // add avatar
    
    CGFloat cellHeight = MAX(height, leftHeight);
    cellHeight = floorf(cellHeight);
    
    return cellHeight;
}

#pragma mark - 
#pragma attributtedLabel delegate
- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url
{
    if (!url) {
        return ;
    }
    id delegate = self.data.target;
    [delegate performSelector:@selector(attributedLabel:didSelectLinkWithArguments:) withObject:label withObject:@{@"url": url, @"cell_data": self.data}];
}

- (void)attributedLabel:(TTTAttributedLabel *)label didReleaseLinkWithURL:(NSURL *)url
{
    if (!url) {
        return;
    }
    id delegate = self.data.target;
    [delegate performSelector:@selector(attributedLabel:didReleaseLinkWithArguments:) withObject:label withObject:@{@"url": url, @"cell_data": self.data}];
}

- (void)attributedLabelDidLongPressed:(TTTAttributedLabel *)label
{
    [self.data more];
}

#pragma mark -
#pragma actions
- (void)imageButtonTouched
{
    UIImage *prevImage = [self.imagePreviewButton imageForState:UIControlStateNormal];
    if (prevImage) {
        if ([setting(HSUSettingShowOriginalImage) boolValue]) {
            [self.data photoButtonTouched:self.imagePreviewButton
                         originalImageURL:[NSURL URLWithString:self.data.photoUrl]];
        } else {
            [self.data photoButtonTouched:self.imagePreviewButton];
        }
    }
}

- (void)settingsUpdated:(NSNotification *)notification
{
    [self _setupStyle];
}

- (void)setStyle:(HSUStatusViewStyle)style
{
    _style = style;
    [self _setupStyle];
}

@end
