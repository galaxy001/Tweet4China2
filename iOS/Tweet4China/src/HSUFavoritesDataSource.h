//
//  HSUFavoritesDataSource.h
//  Tweet4China
//
//  Created by Jason Hsu on 13-9-14.
//  Copyright (c) 2013年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUTweetsDataSource.h"

@interface HSUFavoritesDataSource : HSUTweetsDataSource

@property (nonatomic, copy) NSString *screenName;
@property (nonatomic, copy) NSString *lastStatusID;

- (id)initWithScreenName:(NSString *)screenName;

@end
