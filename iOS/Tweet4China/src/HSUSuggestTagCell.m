//
// Created by jason on 4/5/13.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "HSUSuggestTagCell.h"


@implementation HSUSuggestTagCell {
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
#ifdef __IPHONE_7_0
        self.separatorInset = edi(0, 0, 0, 0);
#endif
    }
    return self;
}

@end