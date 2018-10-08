//
//  PCCommChargeInfo.m
//  Timex
//
//  Created by Lev Verbitsky on 9/3/14.
//  Copyright (c) 2014 iDevices, LLC. All rights reserved.
//

#import "PCCommChargeInfo.h"
#import "iDevicesUtil.h"

@implementation PCCommChargeInfo

@synthesize ACK = _ACK;
@synthesize Handle = _Handle;
@synthesize Unused = _Unused;
@synthesize USBStatus = _USBStatus;
@synthesize current = _current;
@synthesize charge = _charge;
@synthesize temperature = _temperature;
@synthesize voltage = _voltage;


- (id) init: (NSData *) data
{
    if (self = [super init])
    {
        Byte inData[[data length]];
        [data getBytes: inData];
        
#if DEBUG
        NSLog(@"Watch Charge Info received");
        NSLog(@"raw Data:");
        [iDevicesUtil dumpData: data];
#endif
        
        if ( [data length] >= PCCOMM_SIZE_CHARGEINFO )
        {
            _ACK = inData[0];
            _Handle = inData[1];
            _Unused = inData[2];
            _USBStatus = inData[3];
            
            NSNumber * nsNumData = nil;
            nsNumData = [NSNumber numberWithFloat:*(float *)&inData[4]];
            _current = [nsNumData floatValue];
            
            nsNumData = [NSNumber numberWithFloat:*(float *)&inData[8]];
            _charge = [nsNumData floatValue];
            
            nsNumData = [NSNumber numberWithFloat:*(float *)&inData[12]];
            _temperature = [nsNumData floatValue];
            
            nsNumData = [NSNumber numberWithFloat:*(float *)&inData[16]];
            _voltage = [nsNumData floatValue];
        }
    }
    return self;
}
@end
