//
//  HSUWebBrowserTabCell.m
//  Tweet4China
//
//  Created by Jason Hsu on 14-1-10.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUWebBrowserTabCell.h"

@implementation HSUWebBrowserTabCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        UIButton *favoriteButton = [[UIButton alloc] init];
        self.favoriteButton = favoriteButton;
        [favoriteButton setImage:[UIImage imageNamed:@"btn_bookmark"] forState:UIControlStateNormal];
        [favoriteButton setImage:[UIImage imageNamed:@"btn_bookmark_selected"] forState:UIControlStateSelected];
        [favoriteButton sizeToFit];
        [self.contentView addSubview:favoriteButton];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.favoriteButton.leftCenter = ccp(15, self.height/2);
    self.textLabel.left = self.favoriteButton.right + 10;
}

@end
