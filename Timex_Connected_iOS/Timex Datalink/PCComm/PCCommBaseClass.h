//
//  PCCommBaseClass.h
//  Timex Connected
//
//  Created by Lev Verbitsky on 1/21/14.
//  Copyright (c) 2014 iDevices, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PCCommBaseClass : NSObject

@property (nonatomic, getter = Get, setter = Set:) Byte value;

- (id) init: (Byte) inValue;

@end
