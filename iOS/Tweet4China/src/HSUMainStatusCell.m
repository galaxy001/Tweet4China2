//
//  HSUStatusDetailCell.m
//  Tweet4China
//
//  Created by Jason Hsu on 4/18/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUMainStatusCell.h"
#import "HSUStatusCell.h"
#import "NSDate+Additions.h"
#import <FHSTwitterEngine/FHSTwitterEngine.h>
#import "GTMNSString+HTML.h"
#import <FHSTwitterEngine/NSString+URLEncoding.h>
#import "HSUStatusActionView.h"
#import <AFNetworking/AFNetworking.h>
#import "HSUAttributedLabel.h"
#import "HSUInstagramMediaCache.h"

#define ambient_H 14
#define info_H 16
#define textAL_font_S 18
#define margin_W 10
#define padding_S 10
#define avatar_S 48
#define ambient_S 20
#define textAL_LHM 1.2
#define actionV_H 44
#define avatar_text_Distance 15
#define text_time_Distance 7
#define time_summary_Distance 30
#define retweet_favorite_pannel_H 45

#define retweeted_R @"ic_ambient_retweet"

@interface HSUMainStatusCell ()

@property (nonatomic, weak) UIActivityIndicatorView *imgLoadSpinner;

@end

@implementation HSUMainStatusCell
{
    UIView *contentArea;
    UIView *ambientArea;
    UIImageView *ambientI;
    UILabel *ambientL;
    UIButton *avatarB;
    UILabel *nameL;
    UILabel *screenNameL;
    UILabel *timePlaceL;
    TTTAttributedLabel *textAL;
    UILabel *viaLabel;
    UIButton *sourceButton;
    
    UIView *actionSeperatorV;
    HSUStatusActionView *actionV;
    
    UIImageView *imageView;
    
    UIView *retweetFavoriteCountSeperatorV;
    UILabel *retweetCountL;
    UIButton *retweetsButton;
    UILabel *favoriteCountL;
    UIButton *favoritesButton;
    UIView *retweetFavoritePannel;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = kWhiteColor;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        contentArea = [[UIView alloc] init];
        [self.contentView addSubview:contentArea];
        
        ambientArea = [[UIView alloc] init];
        [contentArea addSubview:ambientArea];
        
        ambientI = [[UIImageView alloc] init];
        [ambientArea addSubview:ambientI];
        
        ambientL = [[UILabel alloc] init];
        [ambientArea addSubview:ambientL];
        ambientL.font = [UIFont systemFontOfSize:13];
        ambientL.textColor = [UIColor grayColor];
        ambientL.highlightedTextColor = kWhiteColor;
        ambientL.backgroundColor = kClearColor;
        
        avatarB = [[UIButton alloc] init];
        [contentArea addSubview:avatarB];
        avatarB.layer.masksToBounds = YES;
        avatarB.backgroundColor = bw(229);
        
        nameL = [[UILabel alloc] init];
        [contentArea addSubview:nameL];
        nameL.font = [UIFont boldSystemFontOfSize:14];
        nameL.textColor = kBlackColor;
        nameL.highlightedTextColor = kWhiteColor;
        nameL.backgroundColor = kClearColor;
        
        screenNameL = [[UILabel alloc] init];
        [contentArea addSubview:screenNameL];
        screenNameL.font = [UIFont systemFontOfSize:12];
        screenNameL.textColor = kGrayColor;
        screenNameL.highlightedTextColor = kWhiteColor;
        screenNameL.backgroundColor = kClearColor;
        
        timePlaceL = [[UILabel alloc] init];
        [contentArea addSubview:timePlaceL];
        timePlaceL.font = [UIFont systemFontOfSize:12];
        timePlaceL.textColor = kGrayColor;
        timePlaceL.highlightedTextColor = kWhiteColor;
        timePlaceL.backgroundColor = kClearColor;
        
        textAL = [[HSUAttributedLabel alloc] initWithFrame:CGRectZero];
        [contentArea addSubview:textAL];
        textAL.font = [UIFont fontWithName:@"Georgia" size:MAX(textAL_font_S, [GlobalSettings[HSUSettingTextSize] integerValue])];
        textAL.backgroundColor = kClearColor;
        textAL.textColor = rgb(38, 38, 38);
        textAL.highlightedTextColor = kWhiteColor;
        textAL.lineBreakMode = NSLineBreakByWordWrapping;
        textAL.numberOfLines = 0;
        textAL.linkAttributes = @{(NSString *)kCTUnderlineStyleAttributeName: @(NO),
                                  (NSString *)kCTForegroundColorAttributeName: (id)cgrgb(30, 98, 164)};
        textAL.activeLinkAttributes = @{(NSString *)kTTTBackgroundFillColorAttributeName: (id)cgrgb(215, 230, 242),
                                        (NSString *)kTTTBackgroundCornerRadiusAttributeName: @(2)};
        textAL.verticalAlignment = TTTAttributedLabelVerticalAlignmentTop;
        textAL.lineHeightMultiple = textAL_LHM;
        
        imageView = [[UIImageView alloc] init];
        imageView.backgroundColor = bw(229);
        [contentArea addSubview:imageView];
        
        UITapGestureRecognizer *tapPhotoGesture = [[UITapGestureRecognizer alloc] init];
        [tapPhotoGesture addTarget:self action:@selector(_firePhotoTap:)];
        [imageView addGestureRecognizer:tapPhotoGesture];
        imageView.userInteractionEnabled = YES;
        
        UIActivityIndicatorView *imgLoadSpinner = GRAY_INDICATOR;
        [imageView addSubview:imgLoadSpinner];
        self.imgLoadSpinner = imgLoadSpinner;
        
        retweetFavoritePannel = [[UIView alloc] init];
        [contentArea addSubview:retweetFavoritePannel];
        retweetFavoritePannel.hidden = YES;
        
        retweetFavoriteCountSeperatorV = [[UIView alloc] init];
        [retweetFavoritePannel addSubview:retweetFavoriteCountSeperatorV];
        retweetFavoriteCountSeperatorV.backgroundColor = bw(226);
        
        retweetCountL = [[UILabel alloc] init];
        [retweetFavoritePannel addSubview:retweetCountL];
        retweetCountL.font = [UIFont boldSystemFontOfSize:12];
        retweetCountL.textColor = kBlackColor;
        retweetCountL.hidden = YES;
        
        retweetsButton = [[UIButton alloc] init];
        [retweetFavoritePannel addSubview:retweetsButton];
        retweetsButton.titleLabel.font = [UIFont systemFontOfSize:12];
        [retweetsButton setTitleColor:kGrayColor forState:UIControlStateNormal];
        retweetsButton.hidden = YES;
        
        favoriteCountL = [[UILabel alloc] init];
        [retweetFavoritePannel addSubview:favoriteCountL];
        favoriteCountL.font = [UIFont boldSystemFontOfSize:12];
        favoriteCountL.textColor = kBlackColor;
        favoriteCountL.hidden = YES;
        
        favoritesButton = [[UIButton alloc] init];
        [retweetFavoritePannel addSubview:favoritesButton];
        favoritesButton.titleLabel.font = [UIFont systemFontOfSize:12];
        [favoritesButton setTitleColor:kGrayColor forState:UIControlStateNormal];
        favoritesButton.hidden = YES;
        
        viaLabel = [[UILabel alloc] init];
        [retweetFavoritePannel addSubview:viaLabel];
        viaLabel.font = [UIFont systemFontOfSize:12];
        viaLabel.textColor = kBlackColor;
        viaLabel.text = @"via";
        [viaLabel sizeToFit];
        
        sourceButton = [[UIButton alloc] init];
        [retweetFavoritePannel addSubview:sourceButton];
        [sourceButton setTitleColor:kGrayColor forState:UIControlStateNormal];
        [sourceButton setTitleColor:kBlackColor forState:UIControlStateHighlighted];
        sourceButton.titleLabel.font = [UIFont systemFontOfSize:12];
        [sourceButton setTapTarget:self action:@selector(_sourceButtonTouched)];
        
        // action buttons
        actionSeperatorV = [[UIView alloc] init];
        actionSeperatorV.backgroundColor = bw(226);
        [contentArea addSubview:actionSeperatorV];
        
        // set frames
        contentArea.frame = ccr(padding_S, padding_S, self.contentView.width-padding_S*4, 0);
        CGFloat cw = contentArea.width;
        ambientArea.frame = ccr(0, 0, cw, ambient_H);
        ambientI.frame = ccr(avatar_S-ambient_S, (ambient_H-ambient_S)/2, ambient_S, ambient_S);
        ambientL.frame = ccr(avatar_S+padding_S, 0, cw-ambientI.right-padding_S, ambient_H);
        avatarB.frame = ccr(0, 0, avatar_S, avatar_S);
        textAL.frame = ccr(avatarB.left, 0, cw, 0);
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [avatarB makeCornerRadius];
    contentArea.frame = ccr(padding_S, padding_S, self.contentView.width-padding_S*4, self.contentView.height-padding_S-actionV_H);
    
    ambientArea.frame = ccr(0, 0, contentArea.width, ambient_S);
    
    avatarB.leftTop = ccp(avatarB.left, ambientArea.hidden ? 0 : ambientArea.bottom);
    
    [nameL sizeToFit];
    nameL.leftTop = ccp(avatarB.right+padding_S, avatarB.top+7);
    
    [screenNameL sizeToFit];
    screenNameL.leftTop = ccp(nameL.left, nameL.bottom+3);
    
    textAL.frame = ccr(textAL.left, avatarB.bottom+avatar_text_Distance, contentArea.width, self.data.textHeight);
    
    [timePlaceL sizeToFit];
    timePlaceL.leftTop = ccp(textAL.left, textAL.bottom+text_time_Distance);
    
    imageView.top = timePlaceL.bottom + time_summary_Distance;
    
    actionV.frame = ccr(0, 0, self.contentView.width, actionV_H);
    actionV.bottom = self.contentView.height;
    
    actionSeperatorV.frame = ccr(0, contentArea.height-1, contentArea.width, 1);
    
    retweetFavoritePannel.frame = ccr(0, actionSeperatorV.top-retweet_favorite_pannel_H, contentArea.width, retweet_favorite_pannel_H);
    retweetFavoritePannel.backgroundColor = kClearColor;
    retweetFavoriteCountSeperatorV.frame = ccr(0, 0, retweetFavoritePannel.width, 1);
    retweetCountL.leftCenter = ccp(retweetCountL.left, retweetFavoritePannel.height/2);
    retweetsButton.leftCenter = ccp(retweetsButton.left, retweetFavoritePannel.height/2);
    favoriteCountL.leftCenter = ccp(favoriteCountL.left, retweetFavoritePannel.height/2);
    favoritesButton.leftCenter = ccp(favoritesButton.left, retweetFavoritePannel.height/2);
    
    if (sourceButton.superview == contentArea) {
        sourceButton.rightCenter = ccp(contentArea.width, timePlaceL.center.y);
    } else if (sourceButton.superview == retweetFavoritePannel) {
        sourceButton.rightCenter = ccp(retweetFavoritePannel.width, retweetFavoritePannel.height/2);
    }
    viaLabel.rightCenter = sourceButton.leftCenter;
    viaLabel.left -= 3;
}

- (void)setupWithData:(T4CStatusCellData *)data
{
    [super setupWithData:data];
    
    actionV = [[HSUStatusActionView alloc] initWithStatus:data.mainStatus
                                                    style:HSUStatusActionViewStyle_Default];
    [self.contentView addSubview:actionV];
    
    // ambient
    ambientI.hidden = NO;
    NSDictionary *retweetedStatus = self.data.rawData[@"retweeted_status"];
    if (retweetedStatus) {
        ambientI.imageName = retweeted_R;
        NSString *ambientText = [NSString stringWithFormat:@"%@ retweeted", self.data.rawData[@"user"][@"name"]];
        ambientL.text = ambientText;
        ambientArea.hidden = NO;
    } else {
        ambientI.imageName = nil;
        ambientL.text = nil;
        ambientArea.hidden = YES;
        ambientArea.bounds = CGRectZero;
    }
    
    NSDictionary *entities = self.data.mainStatus[@"entities"];
    
    // info
    NSString *avatarUrl = nil;
    avatarUrl = self.data.mainStatus[@"user"][@"profile_image_url_https"];
    nameL.text = self.data.mainStatus[@"user"][@"name"];
    screenNameL.text = S(@"@%@", self.data.mainStatus[@"user"][@"screen_name"]);
    avatarUrl = [avatarUrl stringByReplacingOccurrencesOfString:@"normal" withString:@"bigger"];
    [avatarB setImageWithUrlStr:avatarUrl forState:UIControlStateNormal placeHolder:nil];
    
    // time
    NSDate *createdDate = [twitter getDateFromTwitterCreatedAt:self.data.mainStatus[@"created_at"]];
    timePlaceL.text = createdDate.standardTwitterDisplay;
    
    NSInteger retweetCount = [self.data.mainStatus[@"retweet_count"] integerValue];
    NSInteger favoriteCount = [self.data.mainStatus[@"favorite_count"] integerValue];
    if ((retweetCount && favoriteCount) || (!retweetCount && !favoriteCount)) {
        [contentArea addSubview:viaLabel];
        [contentArea addSubview:sourceButton];
    }
    
    viaLabel.hidden = NO;
    sourceButton.hidden = NO;
    
    // place
    NSDictionary *placeInfo = self.data.mainStatus[@"place"];
    NSDictionary *geoInfo = self.data.mainStatus[@"geo"];
    
    if ([placeInfo isKindOfClass:[NSDictionary class]]) {
        NSString *place = [NSString stringWithFormat:@"from %@", placeInfo[@"full_name"]];
        NSString *timeText = [[twitter getDateFromTwitterCreatedAt:self.data.mainStatus[@"created_at"]] standardTwitterDisplay];
        timePlaceL.text = [NSString stringWithFormat:@"%@ %@", timeText, place];
        [timePlaceL sizeToFit];
        viaLabel.hidden = YES;
        sourceButton.hidden = YES;
    } else if ([geoInfo isKindOfClass:[NSDictionary class]]) {
        if ([geoInfo[@"type"] isEqualToString:@"Point"]) {
            NSArray *coordinates = geoInfo[@"coordinates"];
            if (coordinates.count == 2) {
                CLLocationDirection latitude = [coordinates[0] doubleValue];
                CLLocationDirection longitude = [coordinates[1] doubleValue];
                NSString *place = S(@"%.3f, %.3f", [geoInfo[@"coordinates"][0] doubleValue], [geoInfo[@"coordinates"][1] doubleValue]);
                NSString *timeText = [[twitter getDateFromTwitterCreatedAt:self.data.mainStatus[@"created_at"]] standardTwitterDisplay];
                timePlaceL.text = [NSString stringWithFormat:@"%@ %@: %@", timeText, _("Coordinate"), place];
                
                CLLocation *location = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
                CLGeocoder *geoCoder = [[CLGeocoder alloc] init];
                __weak typeof(self)weakSelf = self;
                [geoCoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
                    for (CLPlacemark * placemark in placemarks) {
                        NSString *timeText = [[twitter getDateFromTwitterCreatedAt:weakSelf.data.mainStatus[@"created_at"]] standardTwitterDisplay];
                        timePlaceL.text = [NSString stringWithFormat:@"%@ %@", timeText, placemark.name];
                        [timePlaceL sizeToFit];
                        viaLabel.hidden = YES;
                        sourceButton.hidden = YES;
                        break;
                    }
                }];
            }
        }
    }
    
    // attr
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
                if (([expandedUrl hasPrefix:@"http://instagram.com"] || [expandedUrl hasPrefix:@"http://instagr.am"])
                     && ![expandedUrl hasSuffix:@"_v/"]) {
                    attrName = @"photo";
                    break;
                }
            }
        }
    }
    
    // source
    NSString *sourceHTML = self.data.mainStatus[@"source"];
    if (sourceHTML) {
        if ([sourceHTML rangeOfString:@"<a"].location != NSNotFound) {
            NSRange r1 = [sourceHTML rangeOfString:@"\">"];
            NSRange r2 = [sourceHTML rangeOfString:@"</a>"];
            if (r1.location != NSNotFound && r2.location != NSNotFound) {
                int n1 = r1.location + 2;
                int n2 = r2.location;
                if (n1 > 0 && n2 > 0 && n1 < n2) {
                    NSString *source = [sourceHTML substringWithRange:NSMakeRange(n1, n2-n1)];
                    [sourceButton setTitle:source forState:UIControlStateNormal];
                    [sourceButton sizeToFit];
                }
            }
        } else {
            [sourceButton setTitle:sourceHTML forState:UIControlStateNormal];
            [sourceButton sizeToFit];
        }
    }
    
    // text
    NSString *text = [self.data.mainStatus[@"text"] gtm_stringByUnescapingFromHTML];
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
                    if ([attrName isEqualToString:@"photo"] && ![expandedUrl hasPrefix:@"http://instagram.com"] && ![expandedUrl hasPrefix:@"http://instagr.am"]) {
                        text = [text stringByReplacingOccurrencesOfString:url withString:@""];
                    } else {
                        text = [text stringByReplacingOccurrencesOfString:url withString:displayUrl];
                    }
                }
            }
            textAL.text = text;
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
        
        NSArray *userMentions = entities[@"user_mentions"];
        if (userMentions && userMentions.count) {
            for (NSDictionary *userMention in userMentions) {
                NSString *screenName = userMention[@"screen_name"];
                NSString *userUrl = S(@"user://%@", screenName);
                NSRange range = [text rangeOfString:S(@"@%@", screenName)];
                [textAL addLinkToURL:[NSURL URLWithString:userUrl] withRange:range];
            }
        }
        
        NSArray *hashTags = entities[@"hashtags"];
        if (hashTags && hashTags.count) {
            for (NSDictionary *hashTag in hashTags) {
                NSString *tag = hashTag[@"text"];
                NSString *userUrl = S(@"tag://%@", tag.URLEncodedString);
                NSRange range = [text rangeOfString:S(@"#%@", tag)];
                [textAL addLinkToURL:[NSURL URLWithString:userUrl] withRange:range];
            }
        }
    }
    textAL.delegate = self;
    
    if ([data.attr isEqualToString:@"photo"]) {
        imageView.width = data.photoFitWidth;
        imageView.height = data.photoFitHeight;
        self.imgLoadSpinner.center = imageView.boundsCenter;
        NSString *photoUrl = data.photoUrl;
        if (photoUrl) {
            if (boolSetting(HSUSettingShowOriginalImage)) {
                [self _downloadPhotoWithURL:[NSURL URLWithString:data.photoUrl]];
            } else {
                [self _downloadPhotoWithURL:[NSURL URLWithString:[HSUCommonTools smallTwitterImageUrlStr:data.photoUrl]]];
            }
        } else {
            NSString *instagramUrl = data.instagramUrl;
            if (instagramUrl) {
                NSString *mediaUrl = self.data.photoUrl;
                if (mediaUrl) {
                    [self _downloadPhotoWithURL:[NSURL URLWithString:mediaUrl]];
                } else if ((mediaUrl = [HSUInstagramMediaCache mediaForWebUrl:instagramUrl][@"url"])) {
                    self.data.photoUrl = mediaUrl;
                    data.instagramMediaID = [HSUInstagramMediaCache mediaForWebUrl:instagramUrl][@"media_id"];
                    [self _downloadPhotoWithURL:[NSURL URLWithString:mediaUrl]];
                } else {
                    __weak typeof(self) weakSelf = self;
                    NSString *instagramAPIUrl = S(@"http://api.instagram.com/oembed?url=%@", instagramUrl);
                    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:instagramAPIUrl]];
                    AFHTTPRequestOperation *instagramer = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                        if ([JSON isKindOfClass:[NSDictionary class]] && [JSON[@"type"] isEqualToString:@"photo"]) {
                            [HSUInstagramMediaCache setMedia:JSON forWebUrl:instagramUrl];
                            NSString *imageUrl = JSON[@"url"];
                            data.photoUrl = imageUrl;
                            data.instagramMediaID = JSON[@"media_id"];
                            [weakSelf _downloadPhotoWithURL:[NSURL URLWithString:imageUrl]];
                        } else {
                            [weakSelf.imgLoadSpinner stopAnimating];
                        }
                    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                        [weakSelf.imgLoadSpinner stopAnimating];
                    }];
                    [instagramer start];
                    [self.imgLoadSpinner startAnimating];
                }
            } else {
                [self.imgLoadSpinner stopAnimating];
            }
        }
    }
    
    // retweets & favorites
    CGFloat favoriteLeft = 0;
    if (retweetCount) {
        retweetFavoritePannel.hidden = NO;
        retweetCountL.hidden = NO;
        retweetCountL.text = S(@"%d", retweetCount);
        [retweetCountL sizeToFit];
        retweetsButton.hidden = NO;
        [retweetsButton setTitle:retweetCount > 1 ? _("RETWEETS")
                                                  : _("RETWEET") forState:UIControlStateNormal];
        [retweetsButton sizeToFit];
        retweetsButton.left = retweetCountL.right + 3;
        
        favoriteLeft += retweetsButton.right + 10;
    }
    if (favoriteCount) {
        retweetFavoritePannel.hidden = NO;
        favoriteCountL.hidden = NO;
        favoriteCountL.text = S(@"%d", favoriteCount);
        [favoriteCountL sizeToFit];
        favoritesButton.hidden = NO;
        [favoritesButton setTitle:favoriteCount > 1 ? _("FAVORITES")
                                                    : _("FAVORITE") forState:UIControlStateNormal];
        [favoritesButton sizeToFit];
        favoriteCountL.left = favoriteLeft;
        favoritesButton.left = favoriteCountL.right + 3;
    }
    
    // set action events
    [self setupTapEventOnButton:actionV.replayB name:@"reply"];
    [self setupTapEventOnButton:actionV.rtB name:@"rt"];
    [self setupTapEventOnButton:actionV.retweetB name:@"retweet"];
    [self setupTapEventOnButton:actionV.favoriteB name:@"favorite"];
    [self setupTapEventOnButton:actionV.moreB name:@"more"];
    [self setupTapEventOnButton:actionV.deleteB name:@"delete"];
    [self setupTapEventOnButton:retweetsButton name:@"retweets"];
    [self setupTapEventOnButton:favoritesButton name:@"favorites"];
    [self setupTapEventOnButton:avatarB name:@"touchAvatar"];
}

+ (CGFloat)_textHeightWithCellData:(T4CStatusCellData *)data
{
    NSDictionary *status = data.mainStatus;
    NSString *text = [status[@"text"] gtm_stringByUnescapingFromHTML];
    NSDictionary *entities = status[@"entities"];
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
    if (entities) {
        NSArray *urls = entities[@"urls"];
        NSArray *medias = entities[@"media"];
        if (medias && medias.count) {
            urls = [urls arrayByAddingObjectsFromArray:medias];
        }
        if (urls && urls.count) {
            for (NSDictionary *urlDict in urls) {
                NSString *url = urlDict[@"url"];
                NSString *displayUrl = urlDict[@"display_url"];
                NSString *expandedUrl = urlDict[@"expanded_url"];
                if (url && url.length && displayUrl && displayUrl.length) {
                    if ([attrName isEqualToString:@"photo"] && ![expandedUrl hasPrefix:@"http://instagram.com"] && ![expandedUrl hasPrefix:@"http://instagr.am"]) {
                        text = [text stringByReplacingOccurrencesOfString:url withString:@""];
                    } else {
                        text = [text stringByReplacingOccurrencesOfString:url withString:displayUrl];
                    }
                }
            }
        }
    }
    
    static TTTAttributedLabel *testSizeLabel = nil;
    if (!mainStatusViewTestLabelInited || testSizeLabel) {
        mainStatusViewTestLabelInited = YES;
        TTTAttributedLabel *textAL = [[HSUAttributedLabel alloc] initWithFrame:CGRectZero];
        textAL.font = [UIFont fontWithName:@"Georgia" size:MAX(textAL_font_S, [GlobalSettings[HSUSettingTextSize] integerValue])];
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
    
    CGFloat cellWidth = IPHONE ? 280 : 586;
    CGFloat textHeight = [testSizeLabel sizeThatFits:ccs(cellWidth, 0)].height + 3;
    data.textHeight = textHeight;
    return textHeight;
}

+ (CGFloat)heightForData:(T4CStatusCellData *)data
{
    if (data.cellHeight) {
        return data.cellHeight;
    }
    
    CGFloat height = 0;
    
    height += padding_S; // add padding top
    
    if (data.rawData[@"retweeted_status"]) {
        height += ambient_H; // add ambient
    }
    
    // avatar
    height += avatar_S;
    height += avatar_text_Distance;
    
    // text height
    height += [self _textHeightWithCellData:data];
    height += text_time_Distance;
    
    // timeL height
    height += 20;
    height += text_time_Distance;
    
    // photo height
    [self _parseSummary:data];
    CGFloat summaryWidth = data.photoWidth;
    CGFloat summaryHeight = data.photoHeight;
    if (summaryHeight) {
        height += time_summary_Distance;
        CGFloat contentWidth = [HSUCommonTools winWidth] - padding_S * 2 - kIPADMainViewPadding * 2;
        if (summaryWidth > contentWidth) {
            summaryHeight = summaryHeight * contentWidth / summaryWidth;
            summaryWidth = contentWidth;
        } else if (IPHONE) {
            summaryWidth /= 2;
            summaryHeight /= 2;
        }
        height += summaryHeight;
        data.photoFitWidth = summaryWidth;
        data.photoFitHeight = summaryHeight;
    }
    
    NSInteger retweetCount = [data.mainStatus[@"retweet_count"] integerValue];
    NSInteger favoriteCount = [data.mainStatus[@"favorite_count"] integerValue];
    if (retweetCount + favoriteCount) {
        height += retweet_favorite_pannel_H;
    }
    
    // actionV height
    height += actionV_H + 1;
    
    // as integer
    height = floorf(height);
    
    data.cellHeight = height;
    
    return height;
}

- (TTTAttributedLabel *)contentLabel
{
    return textAL;
}

#pragma mark - attributtedLabel delegate
- (void)attributedLabelDidLongPressed:(TTTAttributedLabel *)label
{
    id delegate = self.data.target;
    [delegate performSelector:@selector(attributedLabelDidLongPressed:) withObject:label];
}

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url
{
    if (!url) {
        return ;
    }
    [self.data attributedLabel:label didSelectLinkWithArguments:@{@"url": url, @"cell_data": self.data}];
}

- (void)attributedLabel:(TTTAttributedLabel *)label didReleaseLinkWithURL:(NSURL *)url
{
    if (!url) {
        return;
    }
    [self.data attributedLabel:label didReleaseLinkWithArguments:@{@"url": url, @"cell_data": self.data}];
}

- (void)_downloadPhotoWithURL:(NSURL *)photoURL
{
    [self.imgLoadSpinner startAnimating];
    __weak typeof(self)weakSelf = self;
    [imageView setImageWithUrlStr:photoURL.absoluteString placeHolder:nil success:^{
        [weakSelf.imgLoadSpinner stopAnimating];
    } failure:^{
        [weakSelf.imgLoadSpinner stopAnimating];
    }];
}

+ (void)_parseSummary:(T4CStatusCellData *)data
{
    NSDictionary *entities = data.mainStatus[@"entities"];
    NSArray *urls = entities[@"urls"];
    NSArray *medias = entities[@"media"];
    NSString *attrName = nil;
    if (medias && medias.count) {
        NSDictionary *media = medias[0];
        NSString *type = media[@"type"];
        if ([type isEqualToString:@"photo"]) {
            attrName = @"photo";
            data.photoUrl = media[@"media_url_https"];
            data.photoWidth = [media[@"sizes"][@"large"][@"w"] floatValue];
            data.photoHeight = [media[@"sizes"][@"large"][@"h"] floatValue];
        }
    } else if (urls && urls.count) {
        for (NSDictionary *urlDict in urls) {
            NSString *expandedUrl = urlDict[@"expanded_url"];
            if ([expandedUrl hasPrefix:@"http://4sq.com"] ||
                [expandedUrl hasPrefix:@"http://youtube.com"]) {
                attrName = @"summary";
            } else if ([expandedUrl hasPrefix:@"http://youtube.com"] ||
                       [expandedUrl hasPrefix:@"http://snpy.tv"]) {
                attrName = @"video";
            } else if ([expandedUrl hasPrefix:@"http://instagram.com"] || [expandedUrl hasPrefix:@"http://instagr.am"]) {
                data.instagramUrl = expandedUrl;
                data.photoWidth = 612;
                data.photoHeight = 612;
                attrName = @"photo";
            }
            if (attrName) {
                break;
            }
        }
    }
    
    if (attrName) {
        data.attr = attrName;
    }
}

- (void)_firePhotoTap:(UITapGestureRecognizer *)tap
{
    if (tap.state == UIGestureRecognizerStateEnded && imageView.image) {
        [self.data photoButtonTouched:imageView];
    }
}

- (void)_sourceButtonTouched
{
    NSString *sourceHTML = self.data.mainStatus[@"source"];
    if (sourceHTML) {
        NSRange r1 = [sourceHTML rangeOfString:@"href=\"http"];
        NSRange r2 = [sourceHTML rangeOfString:@"\" rel="];
        if (r1.location != NSNotFound && r2.location != NSNotFound) {
            int n1 = r1.location + 6;
            int n2 = r2.location;
            if (n1 > 0 && n2 > 0 && n1 < n2) {
                NSString *url = [sourceHTML substringWithRange:NSMakeRange(n1, n2-n1)];
                NSURL *URL = [NSURL URLWithString:url];
                if (URL) {
                    [[UIApplication sharedApplication] openURL:URL];
                }
            }
        }
    }
    
}

@end
