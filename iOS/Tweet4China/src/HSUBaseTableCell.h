//
//  HSUBaseTableCell.h
//  Tweet4China
//
//  Created by Jason Hsu on 3/10/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import <UIKit/UIKit.h>

@class T4CTableCellData;
@interface HSUBaseTableCell : UITableViewCell

@property (nonatomic, strong) T4CTableCellData *data;

@property (nonatomic, weak) UIImageView *cornerLeftTop;
@property (nonatomic, weak) UIImageView *cornerRightTop;
@property (nonatomic, weak) UIImageView *cornerLeftBottom;
@property (nonatomic, weak) UIImageView *cornerRightBottom;

- (void)setupWithData:(T4CTableCellData *)data;
+ (CGFloat)heightForData:(T4CTableCellData *)data;
- (void)setupControl:(UIControl *)control forKey:(NSString *)key;
- (void)setupControl:(UIControl *)control forKey:(NSString *)key cleanOldEvents:(BOOL)clean;

@end
