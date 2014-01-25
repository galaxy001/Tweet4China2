//
//  HSULoadMoreCell.m
//  Tweet4China
//
//  Created by Jason Hsu on 3/23/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSULoadMoreCell.h"

@implementation HSULoadMoreCell
{
    UIImageView *icon;
    UIActivityIndicatorView *spinner;
    UILabel *title;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = kWhiteColor;
        
        icon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ic_inset_larry"]];
        [self.contentView addSubview:icon];
        
        spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [self.contentView addSubview:spinner];
        
        title = [[UILabel alloc] init];
        [self.contentView addSubview:title];
        [title sizeToFit];
        // todo: set title styles
        
        if (IPAD) {
            self.cornerLeftBottom.hidden = NO;
            self.cornerRightBottom.hidden = NO;
        }
    }
    return self;
}

- (void)setupWithData:(T4CTableCellData *)data
{
    NSInteger status = [data.rawData[@"status"] integerValue];
    if (status == kLoadMoreCellStatus_Done) {
        icon.hidden = NO;
        [spinner stopAnimating]; spinner.hidden = YES;
        title.hidden = YES;
    } else if (status == kLoadMoreCellStatus_Loading) {
        icon.hidden = YES;
        spinner.hidden = NO; [spinner startAnimating];
        title.hidden = YES;
    } else if (status == kLoadMoreCellStatus_Error) {
        icon.hidden = YES;
        title.hidden = NO;
        [spinner stopAnimating]; spinner.hidden = YES;
    } else if (status == kLoadMoreCellStatus_NoMore) {
        icon.hidden = NO;
        [spinner stopAnimating]; spinner.hidden = YES;
        title.hidden = YES;
    }
}

+ (CGFloat)heightForData:(T4CTableCellData *)data
{
    return kLoadMoreCellHeight;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    icon.center = self.contentView.boundsCenter;
    spinner.center = self.contentView.boundsCenter;
    title.center = self.contentView.boundsCenter;
    self.cornerLeftBottom.bottom = self.contentView.height;
    self.cornerRightBottom.rightBottom = ccp(self.contentView.width, self.contentView.height);
}

@end
