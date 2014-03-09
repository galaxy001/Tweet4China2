//
//  T4CLoadingRepliedStatusCell.m
//  Tweet4China
//
//  Created by Jason Hsu on 14-2-2.
//  Copyright (c) 2014年 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "T4CLoadingRepliedStatusCell.h"

@interface T4CLoadingRepliedStatusCell ()

@property (nonatomic, weak) UIActivityIndicatorView *loadingSpinner;
@property (nonatomic, weak) UILabel *titleLabel;

@end

@implementation T4CLoadingRepliedStatusCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        UIActivityIndicatorView *loadingSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [self.contentView addSubview:loadingSpinner];
        self.loadingSpinner = loadingSpinner;
        
        UILabel *titleLabel = [[UILabel alloc] init];
        [self.contentView addSubview:titleLabel];
        self.titleLabel = titleLabel;
        titleLabel.backgroundColor = kClearColor;
        titleLabel.font = [UIFont systemFontOfSize:12];
        
        self.backgroundColor = bw(245);
    }
    return self;
}

- (void)setupWithData:(T4CTableCellData *)data
{
    [super setupWithData:data];
    
    [self.loadingSpinner startAnimating];
    
    NSString *sname = data.rawData[@"in_reply_to_screen_name"];
    NSString *title = S(@"In reply to @%@", sname);
    self.titleLabel.text = title;
    [self.titleLabel sizeToFit];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.titleLabel.leftBottom = ccp(10, self.contentView.height-10);
    self.loadingSpinner.topCenter = ccp(self.width/2,  10);
}

+ (CGFloat)heightForData:(T4CTableCellData *)data
{
    return 66;
}

@end
