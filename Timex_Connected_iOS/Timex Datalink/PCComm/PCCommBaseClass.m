//
//  PCCommBaseClass.m
//  Timex Connected
//
//  Created by Lev Verbitsky on 1/21/14.
//  Copyright (c) 2014 iDevices, LLC. All rights reserved.
//

#import "PCCommBaseClass.h"

@implementation PCCommBaseClass

@synthesize value = _value;

- (id) init: (Byte) inValue
{
    if (self = [super init])
    {
        [self Set: inValue];
    }
    
    return self;
}
@end