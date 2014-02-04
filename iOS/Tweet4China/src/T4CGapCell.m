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

@property (nonatomic, weak) UILabel *errorLabel;
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
        
        UILabel *errorLabel = [[UILabel alloc] init];
        [self.contentView addSubview:errorLabel];
        self.errorLabel = errorLabel;
        errorLabel.font = [UIFont systemFontOfSize:14];
        errorLabel.backgroundColor = kClearColor;
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
        self.errorLabel.text = _("Load Failed");
        [self.errorLabel sizeToFit];
        self.errorLabel.hidden = NO;
    } else {
        self.errorLabel.hidden = YES;
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.errorLabel.center = self.boundsCenter;
    self.loadingSpinner.center = self.boundsCenter;
}

+ (CGFloat)heightForData:(T4CTableCellData *)data
{
    return 51;
}

@end
