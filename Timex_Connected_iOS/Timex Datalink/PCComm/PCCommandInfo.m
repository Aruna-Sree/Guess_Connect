//
//  PCCommandInfo.m
//  Timex Connected
//
//  Created by Lev Verbitsky on 1/20/14.
//  Copyright (c) 2014 iDevices, LLC. All rights reserved.
//

#import "PCCommandInfo.h"

@implementation PCCCommandInfo

- (BOOL) isResponse
{
    BOOL isResponse = FALSE;
    
    isResponse = self.value & 0x01;
    
    return isResponse;
}
- (BOOL) isMultiPacket
{
    BOOL isMulti = FALSE;
    
    return (self.value & 0x2) >> 1;
    
    return isMulti;
}
- (BOOL) isNack
{
    BOOL isNack = FALSE;
    
    return (self.value & 0x8) >> 3;
    
    return isNack;
}
@end
