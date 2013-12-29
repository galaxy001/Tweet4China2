//
//  UIImageView+Addition.h
//  Tweet4China
//
//  Created by Jason Hsu on 3/15/13.
//  Copyright (c) 2013 Jason Hsu <support@tuoxie.me>. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImageView (Additions)

@property (nonatomic, copy, readwrite) NSString *imageName;

+ (id)viewNamed:(NSString *)name;
+ (id)viewStrechedNamed:(NSString *)name;

@end
