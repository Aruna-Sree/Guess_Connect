//
//  TDNavigationItem.m
//  Timex Connected
//
//  Created by Lev Verbitsky on 6/18/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

#import "TDNavigationItem.h"

@implementation TDNavigationItem

@synthesize navigationLabel = _nanavigationLabel;
@synthesize navigationIcon = _navigationIcon;
@synthesize navigationIconSelected = _navigationIconSelected;

- (id) initWithLabel: (NSString *) label andImage: (UIImage *) image andSelectedImage:(UIImage *)selectedImage
{
    self = [super init];
    if (self)
    {
        _nanavigationLabel = label;
        _navigationIcon = image;
        _navigationIconSelected = selectedImage;
    }

    return self;
}

@end
