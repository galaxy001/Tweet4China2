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

- (void)setupWithData:(T4CStatusCellData *)data
{
    NSDictionary *rawData = data.rawData;
    if (!data.photoUrl) {
        NSDictionary *entities = rawData[@"entities"];
        if (entities) {
            NSArray *medias = entities[@"media"];
            NSArray *urls = entities[@"urls"];
            if (medias.count) {
                NSDictionary *media = medias[0];
                NSString *type = media[@"type"];
                if ([type isEqualToString:@"photo"]) {
                    self.data.hasPhoto = YES;
                    self.data.photoUrl = media[@"media_url_https"];
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
        
        NSString *mediaUrl = self.data.photoUrl;
        if (mediaUrl) {
            self.data.photoUrl = mediaUrl;
            [self.photoView setImageWithUrlStr:mediaUrl placeHolder:nil];
            return mediaUrl;
        } else if ((mediaUrl = [HSUInstagramMediaCache mediaForWebUrl:url][@"url"])) {
            self.data.photoUrl = mediaUrl;
            self.data.instagramMediaID = [HSUInstagramMediaCache mediaForWebUrl:url][@"media_id"];
            [self.photoView setImageWithUrlStr:mediaUrl placeHolder:nil];
            return mediaUrl;
        } else {
            NSString *instagramAPIUrl = S(@"http://api.instagram.com/oembed?url=%@", url);
            self.data.instagramUrl = instagramAPIUrl;
            NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:instagramAPIUrl]];
            __weak typeof(self) weakSelf = self;
            AFHTTPRequestOperation *instagramer = [AFJSONRequestOperation
                                                   JSONRequestOperationWithRequest:request
                                                   success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON)
            {
                if ([JSON isKindOfClass:[NSDictionary class]]) {
                    NSString *imageUrl = JSON[@"url"];
                    if ([instagramAPIUrl isEqualToString:weakSelf.data.instagramUrl]) {
                        [HSUInstagramMediaCache setMedia:JSON forWebUrl:url];
                        weakSelf.data.instagramMediaID = JSON[@"media_id"];
                        if ([imageUrl hasSuffix:@".mp4"]) {
                            weakSelf.data.videoUrl = imageUrl;
                        } else {
                            weakSelf.data.photoUrl = imageUrl;
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
