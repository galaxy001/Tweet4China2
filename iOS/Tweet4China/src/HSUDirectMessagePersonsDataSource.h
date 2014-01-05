//
//  HSUDirectMessagePersonsDataSource.h
//  Tweet4China
//
//  Created by Jason Hsu on 14-1-5.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUSearchPersonDataSource.h"

@interface HSUDirectMessagePersonsDataSource : HSUSearchPersonDataSource

@property (nonatomic, strong) NSMutableArray *friends;

@end
