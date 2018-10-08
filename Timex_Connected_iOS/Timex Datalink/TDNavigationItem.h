//
//  TDNavigationItem.h
//  Timex Connected
//
//  Created by Lev Verbitsky on 6/18/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TDNavigationItem : NSObject

@property (nonatomic, strong) NSString * navigationLabel;
@property (nonatomic, strong) UIImage  * navigationIcon;
@property (nonatomic, strong) UIImage  * navigationIconSelected;

- (id) initWithLabel: (NSString *) label andImage: (UIImage *) image andSelectedImage: (UIImage *) selectedImage;

@end
