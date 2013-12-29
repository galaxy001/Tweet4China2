//
//  HSUBaseTableCell.m
//  Tweet4China
//
//  Created by Jason Hsu on 3/10/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUBaseTableCell.h"

@implementation HSUBaseTableCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
        if (RUNNING_ON_IOS_7) {
            self.separatorInset = edi(0, 0, 0, 0);
        }
#endif
        
        if (IPAD) {
            self.width = kIPADMainViewWidth;
            self.contentView.width = self.width;
        }
    }
    return self;
}

- (void)setupControl:(UIControl *)control forKey:(NSString *)key
{
    [self setupControl:control forKey:key cleanOldEvents:YES];
}

- (void)setupControl:(UIControl *)control forKey:(NSString *)key cleanOldEvents:(BOOL)clean
{
    if (!control) {
        return;
    }
    HSUUIEvent *event = self.data.renderData[key];
    if (clean) {
        [control removeTarget:nil action:NULL forControlEvents:event.events];
    }
    [control addTarget:event action:@selector(fire:) forControlEvents:event.events];
}

- (void)setupWithData:(HSUTableCellData *)data
{
    self.data = data;
}

+ (CGFloat)heightForData:(HSUTableCellData *)data
{
    return 0;
}

@end
