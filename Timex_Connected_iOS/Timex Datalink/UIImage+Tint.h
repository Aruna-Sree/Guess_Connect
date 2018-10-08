//
//  UIImage+Tint.h
//  Wahooo
//
//  Created by Michael Nannini on 7/8/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Tint)

-(UIImage*) imageWithTint:(UIColor*)tint;

-(UIImage*) maskWithTint:(UIColor*)tint;

@end

