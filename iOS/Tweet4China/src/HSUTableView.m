//
//  HSUTableView.m
//  Tweet4China
//
//  Created by Jason Hsu on 14-1-3.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUTableView.h"

@implementation HSUTableView

- (void)setContentSize:(CGSize)contentSize {
    // I don't want move the table view during its initial loading of content.
    if (!CGSizeEqualToSize(self.contentSize, CGSizeZero)) {
        if (self.offsetLocked) {
            if (contentSize.height > self.contentSize.height) {
                CGPoint offset = self.contentOffset;
                offset.y += (contentSize.height - self.contentSize.height);
                self.contentOffset = offset;
            }
        }
    }
    [super setContentSize:contentSize];
}

@end
