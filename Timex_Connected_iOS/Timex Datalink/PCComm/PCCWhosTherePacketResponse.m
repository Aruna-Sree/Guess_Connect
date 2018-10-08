//
//  PCCWhosTherePacketResponse.m
//  Timex Connected
//
//  Created by Lev Verbitsky on 1/20/14.
//  Copyright (c) 2014 iDevices, LLC. All rights reserved.
//

#import "PCCWhosTherePacketResponse.h"

@implementation PCCWhosTherePacketResponse

- (id) init: (Byte) inValue
{
    if (self = [super init])
    {
        Mode = [[PCCWhosTherePacketModeStatus alloc] init: xLink];
    }
    
    return self;
}
- (int) size
{
    return 1;
}
- (Byte) Get
{
    return [Mode Get];
}
- (void) Set : (Byte ) inValue
{
    [Mode Set: inValue];
}
@end
