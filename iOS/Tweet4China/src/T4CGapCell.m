//
//  T4CLoadMoreCell.m
//  Tweet4China
//
//  Created by Jason Hsu on 14-2-2.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "T4CGapCell.h"
#import "T4CGapCellData.h"

@interface T4CGapCell ()

@property (nonatomic, weak) UILabel *titleLabel;
@property (nonatomic, weak) UIActivityIndicatorView *loadingSpinner;

@end

@implementation T4CGapCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg_gap"]];
        
        UIActivityIndicatorView *loadingSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [self.contentView addSubview:loadingSpinner];
        self.loadingSpinner = loadingSpinner;
        
        UILabel *titleLabel = [[UILabel alloc] init];
        [self.contentView addSubview:titleLabel];
        self.titleLabel = titleLabel;
        titleLabel.font = [UIFont boldSystemFontOfSize:14];
        titleLabel.backgroundColor = kClearColor;
        titleLabel.textColor = bw(45);
    }
    return self;
}

- (void)setupWithData:(T4CGapCellData *)data
{
    [super setupWithData:data];
    
    if (data.state == T4CLoadingState_Loading) {
        [self.loadingSpinner startAnimating];
    } else {
        [self.loadingSpinner stopAnimating];
    }
    if (data.state == T4CLoadingState_Error) {
        self.titleLabel.text = _("Load Failed");
        [self.titleLabel sizeToFit];
        self.titleLabel.hidden = NO;
    } else if (data.state == T4CLoadingState_Done) {
        self.titleLabel.text = _("Load More");
        [self.titleLabel sizeToFit];
        self.titleLabel.hidden = NO;
    } else {
        self.titleLabel.hidden = YES;
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.titleLabel.center = self.boundsCenter;
    self.loadingSpinner.center = self.boundsCenter;
}

+ (CGFloat)heightForData:(T4CTableCellData *)data
{
    return 51;
}

@end
