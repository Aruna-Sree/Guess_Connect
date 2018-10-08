//
//  PCCommExtendedFirmwareVersionInfo.m
//  Timex
//
//  Created by Lev Verbitsky on 7/31/15.
//  Copyright (c) 2015 iDevices, LLC. All rights reserved.
//

#import "PCCommExtendedFirmwareVersionInfo.h"

@implementation TDM372FirmwareUpgradeInfo
- (id) init
{
    if (self = [super init])
    {
        self.processed = false;
    }
    
    return self;
}
@end

@implementation PCCommExtendedFirmwareVersionInfo

- (id) init: (NSData *) data
{
    if (self = [super init])
    {
        Byte eight[9];
        
        Byte inData[[data length]];
        [data getBytes: inData];
        
        if ([data length] >= PCCOMM_SIZE_EXTENDED_VERSION_INFO )
        {
            _ACK = inData[0];
            _number = inData[1];

            memcpy(eight, &inData[2], 8);
            eight[8] = nil;
            
            _mVersion1 = [NSString stringWithUTF8String: (const char *)&eight[0]];
            
            memcpy(eight, &inData[10], 8);
            eight[8] = nil;
            
            _mVersion2 = [NSString stringWithUTF8String: (const char *)&eight[0]];
            
            memcpy(eight, &inData[18], 8);
            eight[8] = nil;
            
            _mVersion3 = [NSString stringWithUTF8String: (const char *)&eight[0]];
            
            memcpy(eight, &inData[26], 8);
            eight[8] = nil;
            
            _mVersion4 = [NSString stringWithUTF8String: (const char *)&eight[0]];
        }
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; _mVersion1 = %@;_mVersion2 = %@; _mVersion3 = %@ ; _mVersion4=%@>", [self class], self,
            _mVersion1, _mVersion2, _mVersion3,_mVersion4];
}

@end
