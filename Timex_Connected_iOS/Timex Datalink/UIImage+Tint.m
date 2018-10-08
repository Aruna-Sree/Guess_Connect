//
//  UIImage+Tint.m
//  Wahooo
//
//  Created by Michael Nannini on 7/8/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

#import "UIImage+Tint.h"
#import <CoreGraphics/CoreGraphics.h>

@implementation UIImage (Tint)

-(UIImage*) imageWithTint:(UIColor*)tint
{
    CGSize size = self.size;
    
    UIGraphicsBeginImageContextWithOptions(size, NO, self.scale);
    
    CGContextRef gc = UIGraphicsGetCurrentContext();
    
    CGContextTranslateCTM(gc, 0, size.height);
    
    CGContextScaleCTM(gc, 1, -1);


    
    // kCGBlendModeMuliply: R = S * D
    // Color of image muliplied with tint color

    
    // Need to draw Image twice, once for the alpha channel and once for the color
    CGContextDrawImage(gc, CGRectMake(0, 0, size.width, size.height), self.CGImage);

    // kCGBlendModeSourceIn: R = S * Da
    // Fills the opaque portion of the image with the tint color
    CGContextSetBlendMode(gc, kCGBlendModeSourceIn);
    
    [tint setFill];
    
    CGContextFillRect(gc, CGRectMake(0, 0, size.width, size.height));
    
    // kCGBlendModeMuliply: R = S * D
    // Color of image muliplied with tint color
    CGContextSetBlendMode(gc, kCGBlendModeMultiply);
    
    CGContextDrawImage(gc, CGRectMake(0, 0, size.width, size.height), self.CGImage);
    
    UIImage* outImage = UIGraphicsGetImageFromCurrentImageContext();
    //[UIImage imageWithCGImage:UIGraphicsGetImageFromCurrentImageContext().CGImage scale:self.scale orientation:UIImageOrientationUp] ;
    
    UIGraphicsEndImageContext();
    
    return outImage;
}

// Similar to imageWithTint only just the alpha is used to create a solid masked color
-(UIImage*) maskWithTint:(UIColor*)tint
{
    CGSize size = self.size;
    
    UIGraphicsBeginImageContextWithOptions(size, NO, self.scale);
    
    CGContextRef gc = UIGraphicsGetCurrentContext();
    
    CGContextTranslateCTM(gc, 0, size.height);
    
    CGContextScaleCTM(gc, 1, -1);
    
    // kCGBlendModeMuliply: R = S * D
    // Color of image muliplied with tint color
    
    
    // Need to draw Image twice, once for the alpha channel and once for the color
    CGContextDrawImage(gc, CGRectMake(0, 0, size.width, size.height), self.CGImage);
    
    // kCGBlendModeSourceIn: R = S * Da
    // Fills the opaque portion of the image with the tint color
    CGContextSetBlendMode(gc, kCGBlendModeSourceIn);
    
    [tint setFill];
    
    CGContextFillRect(gc, CGRectMake(0, 0, size.width, size.height));
    
    UIImage* outImage = UIGraphicsGetImageFromCurrentImageContext();
    //[UIImage imageWithCGImage:UIGraphicsGetImageFromCurrentImageContext().CGImage scale:self.scale orientation:UIImageOrientationUp] ;
    
    UIGraphicsEndImageContext();
    
    return outImage;
}

@end
