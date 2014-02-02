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

//@property (nonatomic, weak) UIButton *backgroundButton;
@property (nonatomic, weak) UIActivityIndicatorView *loadingSpinner;

@end

@implementation T4CGapCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
//        UIButton *backgroundButton = [[UIButton alloc] init];
//        [backgroundButton setImage:[UIImage imageNamed:@"bg_gap"] forState:UIControlStateNormal];
//        [backgroundButton setImage:[UIImage imageNamed:@"bg_gap"] forState:UIControlStateHighlighted];
//        self.backgroundButton = backgroundButton;
//        [self.contentView addSubview:backgroundButton];
        self.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg_gap"]];
        
        UIActivityIndicatorView *loadingSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [self.contentView addSubview:loadingSpinner];
        self.loadingSpinner = loadingSpinner;
    }
    return self;
}

- (void)setupWithData:(T4CGapCellData *)data
{
    [super setupWithData:data];
    
//    [self setupControl:self.backgroundButton forKey:@"loadGap"];
    if (data.state == T4CLoadingState_Loading) {
        [self.loadingSpinner startAnimating];
    } else {
        [self.loadingSpinner stopAnimating];
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
//    self.backgroundButton.frame = self.contentView.bounds;
    self.loadingSpinner.center = self.boundsCenter;
}

+ (CGFloat)heightForData:(T4CTableCellData *)data
{
    return 51;
}

@end
