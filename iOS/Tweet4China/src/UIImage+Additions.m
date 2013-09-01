//
// Created by jason on 4/4/13.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "UIImage+Additions.h"


@implementation UIImage (Additions)

- (UIImage *)stretchableImageFromCenter
{
    return [self stretchableImageWithLeftCapWidth:self.size.width/2 topCapHeight:self.size.height/2];
}

- (UIImage*)scaleToWidth:(CGFloat)width
{
    if (width >= self.size.width) {
        return self;
    }
    CGSize newSize;
    newSize.width = width;
    newSize.height = self.size.height/self.size.width*newSize.width;

    UIGraphicsBeginImageContext(newSize);
    [self drawInRect:CGRectMake(0, 0, floorf(newSize.width)+1, floorf(newSize.height)+1)];
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaledImage;
}

-(UIImage *)subImageAtRect:(CGRect)rect
{
	rect = ccr(rect.origin.x*self.scale, rect.origin.y*self.scale, rect.size.width*self.scale, rect.size.height*self.scale);
    CGImageRef imageRef = CGImageCreateWithImageInRect([self CGImage], rect);
    UIImage* subImage = [UIImage imageWithCGImage:imageRef scale:self.scale orientation:self.imageOrientation];
    CGImageRelease(imageRef);
    
    return subImage;
}

@end