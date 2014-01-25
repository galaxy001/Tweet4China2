//
//  HSUTweetsViewController.h
//  Tweet4China
//
//  Created by Jason Hsu on 5/3/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import "HSUBaseViewController.h"

@interface HSUTweetsViewController : HSUBaseViewController

@property (nonatomic, weak) T4CTableCellData *cellDataInNextPage;

- (void)reply:(T4CTableCellData *)cellData;
- (void)retweet:(T4CTableCellData *)cellData;
- (void)favorite:(T4CTableCellData *)cellData;
- (void)more:(T4CTableCellData *)cellData;

- (void)openPhoto:(UIImage *)photo withCellData:(T4CTableCellData *)cellData;
- (void)openPhotoURL:(NSURL *)photoURL withCellData:(T4CTableCellData *)cellData;
- (void)openWebURL:(NSURL *)webURL withCellData:(T4CTableCellData *)cellData;

@end
