//
//  HSUListPersonsDataSource.h
//  Tweet4China
//
//  Created by Jason Hsu on 2013/12/2.
//  Copyright (c) 2013年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUPersonListDataSource.h"

@interface HSUListMembersDataSource : HSUPersonListDataSource

@property (nonatomic, strong) NSDictionary *list;

- (instancetype)initWithList:(NSDictionary *)list;

@end
