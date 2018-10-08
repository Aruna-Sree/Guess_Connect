//
//  PCCLinkAddress.h
//  Timex Connected
//
//  Created by Lev Verbitsky on 1/20/14.
//  Copyright (c) 2014 iDevices, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PCCommBaseClass.h"

@interface PCCLinkAddress : NSObject

@property (nonatomic, getter = Get, setter = Set:) int value;

- (id) init: (int) inValue;

@end
