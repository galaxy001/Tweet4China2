//
//  T4CTableCellData.m
//  Tweet4China
//
//  Created by Jason Hsu on 14-1-15.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "T4CTableCellData.h"

@implementation T4CTableCellData

- (id)initWithRawData:(NSDictionary *)rawData dataType:(NSString *)dataType
{
    self = [self init];
    if (self) {
        self.dataType = dataType;
        self.rawData = rawData;
    }
    return self;
}

- (id)initWithCacheData:(NSDictionary *)cacheData
{
    self = [self init];
    if (self) {
        self.dataType = cacheData[@"data_type"];
        if ([self.dataType isEqualToString:@"Status"]) {
            self.dataType = @"DefaultStatus";
        }
        self.rawData = cacheData[@"raw_data"];
    }
    return self;
}

- (NSDictionary *)cacheData
{
    if (self.rawData) {
        return @{@"data_type": self.dataType, @"raw_data": self.rawData, @"class_name": self.class.description};
    }
    return nil;
}

@end
