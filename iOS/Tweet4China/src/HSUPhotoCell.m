//
//  HSUPhotoCell.m
//  Tweet4China
//
//  Created by Jason Hsu on 14-1-12.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUPhotoCell.h"
#import "HSUInstagramMediaCache.h"
#import <AFNetworking/AFNetworking.h>

@interface HSUPhotoCell ()

@property (nonatomic, weak) UIImageView *photoView;

@end


@implementation HSUPhotoCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        UIImageView *photoView = [[UIImageView alloc] init];
        self.photoView = photoView;
        [self.contentView addSubview:photoView];
    }
    return self;
}

- (void)setupWithData:(HSUTableCellData *)data
{
    NSDictionary *rawData = data.rawData;
    if (!data.renderData[@"photo_url"]) {
        NSDictionary *entities = rawData[@"entities"];
        if (entities) {
            NSArray *medias = entities[@"media"];
            NSArray *urls = entities[@"urls"];
            if (medias.count) {
                NSDictionary *media = medias[0];
                NSString *type = media[@"type"];
                if ([type isEqualToString:@"photo"]) {
                    self.data.renderData[@"has_photo"] = @YES;
                    self.data.renderData[@"photo_url"] = media[@"media_url_https"];
                    self.data.renderData[@"photo_size"] = media[@"sizes"][@"large"];
                }
            } else if (urls.count) {
                for (NSDictionary *urlDict in urls) {
                    NSString *expandedUrl = urlDict[@"expanded_url"];
                    [self _photoUrl:expandedUrl];
                    break;
                }
            }
        }
    }
}

- (NSString *)_photoUrl:(NSString *)url
{
    if ([url hasPrefix:@"http://4sq.com"] ||
        [url hasPrefix:@"http://youtube.com"]) {
        
        return nil;
        
    } else if ([url hasPrefix:@"http://youtube.com"] ||
               [url hasPrefix:@"http://snpy.tv"]) {
        
        return nil;
        
    } else if ([url hasPrefix:@"http://instagram.com"] || [url hasPrefix:@"http://instagr.am"]) {
        
        NSString *mediaUrl = self.data.renderData[@"photo_url"];
        if (mediaUrl) {
            self.data.renderData[@"photo_url"] = mediaUrl;
            [self.photoView setImageWithUrlStr:mediaUrl placeHolder:nil];
            return mediaUrl;
        } else if ((mediaUrl = [HSUInstagramMediaCache mediaUrlForWebUrl:url])) {
            self.data.renderData[@"photo_url"] = mediaUrl;
            [self.photoView setImageWithUrlStr:mediaUrl placeHolder:nil];
            return mediaUrl;
        } else {
            NSString *instagramAPIUrl = S(@"http://api.instagram.com/oembed?url=%@", url);
            self.data.renderData[@"instagram_url"] = instagramAPIUrl;
            NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:instagramAPIUrl]];
            __weak typeof(self) weakSelf = self;
            AFHTTPRequestOperation *instagramer = [AFJSONRequestOperation
                                                   JSONRequestOperationWithRequest:request
                                                   success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON)
            {
                if ([JSON isKindOfClass:[NSDictionary class]]) {
                    NSString *imageUrl = JSON[@"url"];
                    if ([imageUrl hasSuffix:@".mp4"]) {
                        weakSelf.data.renderData[@"video_url"] = imageUrl;
                    } else {
                        if ([instagramAPIUrl isEqualToString:weakSelf.data.renderData[@"instagram_url"]]) {
                            [HSUInstagramMediaCache setMediaUrl:imageUrl forWebUrl:url];
                            weakSelf.data.renderData[@"photo_url"] = imageUrl;
                            [weakSelf.photoView setImageWithUrlStr:imageUrl placeHolder:nil];
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

- (void)layoutSubviews
{
    
}

@end
