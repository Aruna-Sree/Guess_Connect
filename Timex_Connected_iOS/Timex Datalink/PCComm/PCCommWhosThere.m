//
//  PCCommWhosThere.m
//  Timex Connected
//
//  Created by Lev Verbitsky on 1/22/14.
//  Copyright (c) 2014 iDevices, LLC. All rights reserved.
//

#import "PCCommWhosThere.h"
#import "iDevicesUtil.h"
#import "OTLogUtil.h"

@implementation PCCommWhosThere

@synthesize mModeStatus = _mModeStatus;
@synthesize mXLinkMajorRev = _mXLinkMajorRev;
@synthesize mXLinkMinorRev = _mXLinkMinorRev;
@synthesize mXLinkBuildNum = _mXLinkBuildNum;
@synthesize mMajorRev = _mMajorRev;
@synthesize mMinorRev = _mMinorRev;
@synthesize mMajorPlatform = _mMajorPlatform;
@synthesize mMinorPlatform = _mMinorPlatform;
@synthesize mRevision2 = _mRevision2;
@synthesize mRevision = _mRevision;
@synthesize mModelNumber = _mModelNumber;
@synthesize mProductRev = _mProductRev;
@synthesize mGPSRev = _mGPSRev;
@synthesize mSerialNumber = _mSerialNumber;

- (id) init: (NSData *) data
{
    if (self = [super init])
    {        
        Byte four[5];
        Byte eight[9];
        
        Byte inData[[data length]];
        [data getBytes: inData];
                
        if ([data length] >= PCCOMM_SIZE_WHOSTHERE )
        {
            _mModeStatus = inData[0];
            _mXLinkMajorRev = inData[5];
            _mXLinkMinorRev = inData[6];
            _mXLinkBuildNum = inData[7];
            _mMajorRev = inData[8];
            _mMinorRev = inData[9];
            _mMajorPlatform = inData[10];
            _mMinorPlatform = inData[11];
            _mRevision2 = inData[12];
            _mRevision = inData[13];
            
            memcpy(four, &inData[16], 4);
            four[4] = nil;
            
            _mModelNumber = [NSString stringWithUTF8String: (const char *)&four[0]];
            
            memcpy(four, &inData[20], 4);
            four[4] = nil;
            
            _mProductRev = [NSString stringWithUTF8String: (const char *)&four[0]];
            
            _mGPSRev = * (long *)&inData[32];
            
            memcpy(eight, &inData[40], 8);
            eight[8] = nil;
            _mSerialNumber = [NSString stringWithFormat:@"Serial: %02X%02X%02X%02X%02X%02X%02X%02X", eight[0], eight[1], eight[2], eight[3], eight[4], eight[5], eight[6], eight[7]];
            
            OTLog([NSString stringWithFormat:@"WATCH REVISION: %@,%@", _mModelNumber, _mProductRev]);
            OTLog([NSString stringWithFormat:@"GPS Rev: %ld", _mGPSRev]);
            OTLog([NSString stringWithFormat:@"Serial Number: %@", _mSerialNumber]);
        }
    }
    return self;
}

@end
