//
//  HSUStatusDetailCell.h
//  Tweet4China
//
//  Created by Jason Hsu on 4/18/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUBaseTableCell.h"
#import <TTTAttributedLabel/TTTAttributedLabel.h>
#import "T4CStatusCellData.h"

@interface HSUMainStatusCell : HSUBaseTableCell <TTTAttributedLabelDelegate>

@property (nonatomic, strong) T4CStatusCellData *data;

@end
