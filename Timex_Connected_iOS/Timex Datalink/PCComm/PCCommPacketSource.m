//
//  PCCommPacketSource.m
//  Timex Connected
//
//  Created by Lev Verbitsky on 1/20/14.
//  Copyright (c) 2014 iDevices, LLC. All rights reserved.
//

#import "PCCommPacketSource.h"

extern const  Byte Watch    = 0x01;
extern const  Byte External = 0x02;

@implementation PCCommPacketSource

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
