//
//  HSUSearchPersonDataSource.h
//  Tweet4China
//
//  Created by Jason Hsu on 10/20/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUPersonListDataSource.h"

@interface HSUSearchPersonDataSource : HSUPersonListDataSource

@property (nonatomic, strong) NSString *keyword;

@end
