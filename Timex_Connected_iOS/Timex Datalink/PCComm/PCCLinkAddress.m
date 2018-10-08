//
//  PCCLinkAddress.m
//  Timex Connected
//
//  Created by Lev Verbitsky on 1/20/14.
//  Copyright (c) 2014 iDevices, LLC. All rights reserved.
//

#import "PCCLinkAddress.h"

@implementation PCCLinkAddress

@synthesize value = _value;

- (id) init: (int) inValue
{
    if (self = [super init])
    {
        [self Set: inValue];
    }
    
    return self;
}

@end
