//
//  T4CStatusCellData.h
//  Tweet4China
//
//  Created by Jason Hsu on 14-1-25.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "T4CTableCellData.h"

@interface T4CStatusCellData : T4CTableCellData

@property (nonatomic, copy) NSString *mode;
@property (nonatomic, assign) CGFloat textHeight;
@property (nonatomic, assign) BOOL hasPhoto;
@property (nonatomic, assign) CGFloat photoFitWidth;
@property (nonatomic, assign) CGFloat photoFitHeight;
@property (nonatomic, assign) CGFloat photoWidth;
@property (nonatomic, assign) CGFloat photoHeight;
@property (nonatomic, copy) NSString *photoUrl;
@property (nonatomic, copy) NSString *instagramUrl;
@property (nonatomic, copy) NSString *instagramMediaID;
@property (nonatomic, copy) NSString *attr;
@property (nonatomic, copy) NSString *videoUrl;

@end
