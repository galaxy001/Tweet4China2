//
//  HSUSearchTweetsDataSource.h
//  Tweet4China
//
//  Created by Jason Hsu on 14-1-12.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUTweetsDataSource.h"

@interface HSUSearchTweetsDataSource : HSUTweetsDataSource

@property (nonatomic, copy) NSString *lastStatusID;
@property (nonatomic, copy) NSString *keyword;

@end
