//
//  HSUStatusView.m
//  Tweet4China
//
//  Created by Jason Hsu on 4/27/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "HSUStatusView.h"
#import "GTMNSString+HTML.h"
#import <AFNetworking/AFNetworking.h>
#import "HSUAttributedLabel.h"
#import "NSDate+Additions.h"

#define ambient_H 14
#define info_H 16
#define margin_W 10
#define avatar_S 48
#define ambient_S 20
#define textAL_LHM 1.3
#define padding_S 10

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
    TTTAttributedLabel *textAL;
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
        
        self.style = style;
        
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
        
        textAL = [[HSUAttributedLabel alloc] initWithFrame:CGRectZero];
        [self addSubview:textAL];
        
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
    if (iOS_Ver < 7) {
        ambientL.highlightedTextColor = kWhiteColor;
    }
    ambientL.backgroundColor = kClearColor;
    
    nameL.textColor = kBlackColor;
    nameL.font = [UIFont boldSystemFontOfSize:14];
    if (iOS_Ver < 7) {
        nameL.highlightedTextColor = kWhiteColor;
    }
    nameL.backgroundColor = kClearColor;
    
    avatarB.layer.cornerRadius = 5;
    avatarB.layer.masksToBounds = YES;
    avatarB.backgroundColor = bw(229);
    
    screenNameL.textColor = kGrayColor;
    screenNameL.font = [UIFont systemFontOfSize:12];
    if (iOS_Ver < 7) {
        screenNameL.highlightedTextColor = kWhiteColor;
    }
    screenNameL.backgroundColor = kClearColor;
    
    timeL.textColor = kGrayColor;
    timeL.font = [UIFont systemFontOfSize:12];
    if (iOS_Ver < 7) {
        timeL.highlightedTextColor = kWhiteColor;
    }
    timeL.backgroundColor = kClearColor;
    
    textAL.textColor = rgb(38, 38, 38);
    textAL.font = [UIFont systemFontOfSize:[GlobalSettings[HSUSettingTextSize] integerValue]];
    textAL.backgroundColor = kClearColor;
    if (iOS_Ver < 7) {
        textAL.highlightedTextColor = kWhiteColor;
    }
    textAL.lineBreakMode = NSLineBreakByWordWrapping;
    textAL.numberOfLines = 0;
    textAL.linkAttributes = @{(NSString *)kCTUnderlineStyleAttributeName: @(NO),
                              (NSString *)kCTForegroundColorAttributeName: (id)cgrgb(30, 98, 164)};
    textAL.activeLinkAttributes = @{(NSString *)kTTTBackgroundFillColorAttributeName: (id)cgrgb(215, 230, 242),
                                    (NSString *)kTTTBackgroundCornerRadiusAttributeName: @(2)};
    textAL.verticalAlignment = TTTAttributedLabelVerticalAlignmentTop;
    textAL.lineHeightMultiple = textAL_LHM;
    
    if (self.style == HSUStatusViewStyle_Default) {
        avatarB.frame = ccr(0, 0, avatar_S, avatar_S);
    } else if (self.style == HSUStatusViewStyle_Gallery) {
        attrI.hidden = YES;
        ambientL.textColor = kWhiteColor;
        nameL.textColor = kWhiteColor;
        screenNameL.textColor = kWhiteColor;
        timeL.textColor = kWhiteColor;
        textAL.textColor = kWhiteColor;
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
    
    infoArea.frame = ccr(ambientL.left, avatarB.top, cw-ambientL.left, info_H);
    textAL.frame = ccr(ambientL.left, infoArea.bottom, infoArea.width, [self.data.renderData[@"text_height"] floatValue] + 3);
    
    [timeL sizeToFit];
    timeL.frame = ccr(infoArea.width-timeL.width, -1, timeL.width, timeL.height);
    
    [attrI sizeToFit];
    attrI.frame = ccr(timeL.left-attrI.width-3, -1, attrI.width, attrI.height);
    
    [nameL sizeToFit];
    nameL.frame = ccr(0, -3, MIN(attrI.left-3, nameL.width), nameL.height);
    
    [screenNameL sizeToFit];
    screenNameL.frame = ccr(nameL.right+3, -1, attrI.left-nameL.right, screenNameL.height);
    
    self.imagePreviewButton.frame = ccr(textAL.left, textAL.bottom+5, textAL.width, textAL.width/2);
}

- (void)setupWithData:(HSUTableCellData *)cellData
{
    self.data = cellData;
    
    NSDictionary *rawData = cellData.rawData;
    
    // ambient
    NSDictionary *retweetedStatus = rawData[@"retweeted_status"];
    ambientI.hidden = NO;
    if (retweetedStatus) {
        ambientI.imageName = retweeted_R;
        NSString *ambientText = [NSString stringWithFormat:@"%@ retweeted", rawData[@"user"][@"name"]];
        ambientL.text = ambientText;
        ambientArea.hidden = NO;
    } else {
        ambientI.imageName = nil;
        ambientL.text = nil;
        ambientArea.hidden = YES;
        ambientArea.bounds = CGRectZero;
    }
    
    NSDictionary *entities = rawData[@"entities"];
    
    // info
    NSString *avatarUrl = nil;
    if (retweetedStatus) {
        avatarUrl = rawData[@"retweeted_status"][@"user"][@"profile_image_url_https"];
        nameL.text = rawData[@"retweeted_status"][@"user"][@"name"];
        screenNameL.text = [NSString stringWithFormat:@"@%@", rawData[@"retweeted_status"][@"user"][@"screen_name"]];
    } else {
        avatarUrl = rawData[@"user"][@"profile_image_url_https"];
        nameL.text = rawData[@"user"][@"name"];
        screenNameL.text = [NSString stringWithFormat:@"@%@", rawData[@"user"][@"screen_name"]];
    }
    avatarUrl = [avatarUrl stringByReplacingOccurrencesOfString:@"normal" withString:@"bigger"];
    [avatarB setImageWithUrlStr:avatarUrl
                       forState:UIControlStateNormal
                    placeHolder:nil];
    
    NSDictionary *geo = rawData[@"geo"];
    NSDictionary *place = rawData[@"place"];
    
    // attr
    attrI.imageName = nil;
    NSString *attrName = nil;
    if ([rawData[@"in_reply_to_status_id_str"] length]) {
        attrName = @"convo";
    }
    if (!attrName && entities) {
        NSArray *medias = entities[@"media"];
        NSArray *urls = entities[@"urls"];
        if (medias.count) {
            NSDictionary *media = medias[0];
            NSString *type = media[@"type"];
            if ([type isEqualToString:@"photo"]) {
                attrName = @"photo";
                self.data.renderData[@"photo_url"] = media[@"media_url_https"];
                self.data.renderData[@"photo_size"] = media[@"sizes"][@"large"];
                
            }
        } else if (urls.count) {
            for (NSDictionary *urlDict in urls) {
                NSString *expandedUrl = urlDict[@"expanded_url"];
                attrName = [self _attrForUrl:expandedUrl];
                if (attrName) {
                    break;
                }
            }
        }
    }
    if (!attrName && ([geo isKindOfClass:[NSDictionary class]] ||
                      [place isKindOfClass:[NSDictionary class]])) {
        attrName = @"geo";
    }
    
    self.imagePreviewButton.hidden = YES;
    if (attrName) {
        attrI.imageName = S(@"ic_tweet_attr_%@_default", attrName);
        self.data.renderData[@"attr"] = attrName;
        
        if ([attrName isEqualToString:@"photo"] && [GlobalSettings[HSUSettingPhotoPreview] boolValue]) {
            self.imagePreviewButton.hidden = NO;
            [self.imagePreviewButton setImageWithUrlStr:self.data.renderData[@"photo_url"]
                                               forState:UIControlStateNormal
                                            placeHolder:nil];
        }
    } else {
        attrI.imageName = nil;
        [self.data.renderData removeObjectForKey:@"attr"];
    }
    
    // time
    NSDate *createdDate = [TWENGINE getDateFromTwitterCreatedAt:rawData[@"created_at"]];
    timeL.text = createdDate.twitterDisplay;
    
    // text
    NSString *text = [(retweetedStatus ?: rawData)[@"text"] gtm_stringByUnescapingFromHTML];
    textAL.text = text;
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
                if (url && url.length && displayUrl && displayUrl.length) {
                    if ([attrName isEqualToString:@"photo"] && [GlobalSettings[HSUSettingPhotoPreview] boolValue] && ![expandedUrl hasPrefix:@"http://instagram.com"] && ![expandedUrl hasPrefix:@"http://instagr.am"]) {
                        text = [text stringByReplacingOccurrencesOfString:url withString:@""];
                    } else {
                        text = [text stringByReplacingOccurrencesOfString:url withString:displayUrl];
                    }
                }
            }
            textAL.text = text;
            if (self.style == HSUStatusViewStyle_Default) {
                for (NSDictionary *urlDict in urlDicts) {
                    NSString *url = urlDict[@"url"];
                    NSString *displayUrl = urlDict[@"display_url"];
                    NSString *expanedUrl = urlDict[@"expanded_url"];
                    if (url && url.length && displayUrl && displayUrl.length && expanedUrl && expanedUrl.length) {
                        NSRange range = [text rangeOfString:displayUrl];
                        [textAL addLinkToURL:[NSURL URLWithString:expanedUrl] withRange:range];
                    }
                }
            }
        }
    }
    textAL.delegate = self;
}

- (NSString *)_attrForUrl:(NSString *)url
{
    if ([url hasPrefix:@"http://4sq.com"] ||
        [url hasPrefix:@"http://youtube.com"]) {
        
        return @"summary";
        
    } else if ([url hasPrefix:@"http://youtube.com"] ||
               [url hasPrefix:@"http://snpy.tv"]) {
        
        return @"video";
        
    } else if ([GlobalSettings[HSUSettingPhotoPreview] boolValue] &&
               ([url hasPrefix:@"http://instagram.com"] || [url hasPrefix:@"http://instagr.am"])) {
        
        NSString *instagramAPIUrl = S(@"http://api.instagram.com/oembed?url=%@", url);
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:instagramAPIUrl]];
        self.data.renderData[@"instagram_url"] = instagramAPIUrl;
        AFHTTPRequestOperation *instagramer = [AFJSONRequestOperation
                                               JSONRequestOperationWithRequest:request
                                               success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON)
        {
            if ([JSON isKindOfClass:[NSDictionary class]]) {
                NSString *imageUrl = JSON[@"url"];
                if ([imageUrl hasSuffix:@".mp4"]) {
                    self.data.renderData[@"video_url"] = imageUrl;
                    self.data.renderData[@"video_size"] = @{@"w": JSON[@"width"], @"h": JSON[@"height"]};
                } else {
                    self.data.renderData[@"photo_url"] = imageUrl;
                    self.data.renderData[@"photo_size"] = @{@"w": JSON[@"width"], @"h": JSON[@"height"]};
                    self.imagePreviewButton.hidden = NO;
                    [self.imagePreviewButton setImageWithUrlStr:imageUrl
                                                       forState:UIControlStateNormal
                                                    placeHolder:nil];
                }
            }
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
            
        }];
        [instagramer start];
        return @"photo";
    }
    return nil;
}

+ (CGFloat)_textHeightWithCellData:(HSUTableCellData *)data constraintWidth:(CGFloat)constraintWidth attrName:(NSString *)attrName
{
    NSDictionary *status = data.rawData;
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
                if (url && url.length && displayUrl && displayUrl.length) {
                    if ([attrName isEqualToString:@"photo"] && [GlobalSettings[HSUSettingPhotoPreview] boolValue] && ![expandedUrl hasPrefix:@"http://instagram.com"] && ![expandedUrl hasPrefix:@"http://instagr.am"]) {
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
        textAL.backgroundColor = kClearColor;
        textAL.textColor = rgb(38, 38, 38);
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
    
    CGFloat textHeight = [testSizeLabel sizeThatFits:ccs(constraintWidth, 0)].height;
    data.renderData[@"text_height"] = @(textHeight);
    return textHeight;
}

+ (CGFloat)heightForData:(HSUTableCellData *)data constraintWidth:(CGFloat)constraintWidth
{
    NSDictionary *rawData = data.rawData;
    
    CGFloat height = 0;
    CGFloat leftHeight = 0;
    
    if (rawData[@"retweeted_status"]) {
        height += ambient_H; // add ambient
        leftHeight += ambient_H;
    }
    height += info_H; // add info
    
    NSDictionary *entities = rawData[@"entities"];
    NSString *attrName = nil;
    if (entities) {
        NSArray *medias = entities[@"media"];
        NSArray *urls = entities[@"urls"];
        if (medias.count) {
            NSDictionary *media = medias[0];
            NSString *type = media[@"type"];
            if ([type isEqualToString:@"photo"]) {
                attrName = @"photo";
            }
        } else if (urls.count) {
            for (NSDictionary *urlDict in urls) {
                NSString *expandedUrl = urlDict[@"expanded_url"];
                if ([expandedUrl hasPrefix:@"http://instagram.com"] || [expandedUrl hasPrefix:@"http://instagr.am"]) {
                    attrName = @"photo";
                    break;
                }
            }
        }
    }
    if ([attrName isEqualToString:@"photo"] && [GlobalSettings[HSUSettingPhotoPreview] boolValue]) {
        if (IPHONE) {
            height += 120 + 10;
        } else {
            height += 150 + 10; // todo
        }
    }
    
    height += [self _textHeightWithCellData:data constraintWidth:constraintWidth-avatar_S-padding_S attrName:attrName] + padding_S;
    
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
    id delegate = self.data.renderData[@"delegate"];
    [delegate performSelector:@selector(attributedLabel:didSelectLinkWithArguments:) withObject:label withObject:@{@"url": url, @"cell_data": self.data}];
}

- (void)attributedLabel:(TTTAttributedLabel *)label didReleaseLinkWithURL:(NSURL *)url
{
    if (!url) {
        return;
    }
    id delegate = self.data.renderData[@"delegate"];
    [delegate performSelector:@selector(attributedLabel:didReleaseLinkWithArguments:) withObject:label withObject:@{@"url": url, @"cell_data": self.data}];
}

#pragma mark -
#pragma actions
- (void)imageButtonTouched
{
    if ([self.imagePreviewButton imageForState:UIControlStateNormal]) {
        id delegate = self.data.renderData[@"delegate"];
        [delegate performSelector:@selector(openPhoto:withCellData:)
                       withObject:[self.imagePreviewButton imageForState:UIControlStateNormal]
                       withObject:self.data];
    }
}

- (void)settingsUpdated:(NSNotification *)notification
{
    [self _setupStyle];
}

@end
