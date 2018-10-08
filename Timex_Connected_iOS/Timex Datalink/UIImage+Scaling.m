//
//  UIImage+Scaling.m
//  Timex Connected
//
//  Created by Lev Verbitsky on 8/29/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

#import "UIImage+Scaling.h"

@implementation UIImage (Scaling)

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize
{
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    return newImage;
}
@end
