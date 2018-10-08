//
//  UIImage+Scaling.h
//  Timex Connected
//
//  Created by Lev Verbitsky on 8/29/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Scaling)

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize;

@end
