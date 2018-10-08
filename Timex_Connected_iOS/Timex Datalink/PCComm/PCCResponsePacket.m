//
//  PCCResponsePacket.m
//  Timex Connected
//
//  Created by Lev Verbitsky on 1/20/14.
//  Copyright (c) 2014 iDevices, LLC. All rights reserved.
//

#import "PCCResponsePacket.h"
#import "TDDefines.h"
#import "PCCommCommands.h"
#import "OTLogUtil.h"

extern const  int NO_ERROR = 0x0;
extern const  int NACK = 0x1;
extern const  int NULL_PACKET = -1;
extern const  int NO_RESPONSE= -2;

@implementation PCCResponsePacket

@synthesize mHeader = _mHeader;
@synthesize mPayload = _mPayload;

- (id) init
{
    if (self = [super init])
    {
        _mHeader = [[PCCHeader alloc] init];
        
        int size = PCCOMM_MAX_PACKET_LENGTH - [PCCHeader size];
        Byte payload[size];
        memset(payload, 0, size);
        _mPayload = [[NSData alloc] initWithBytes: payload length: size];
    }
    
    return self;
}

- (Byte) getDataLinkResponse
{
    int size = PCCOMM_MAX_PACKET_LENGTH - [PCCHeader size];
    Byte payload[size];
    [_mPayload getBytes: payload length: size];
    return payload[0];
}
- (Byte) getExtenderResponseCode
{
    Byte code = 0;
    Byte command = [[_mHeader Command] Get];
    OTLog([NSString stringWithFormat:@"----------command %hhu",command]);
    switch (command)
    {
        case ExtenderCmdOpen:
        case ExtenderCmdClose:
        case ExtenderCmdWrite:
        case ExtenderCmdRead:
        case ExtenderCmdSeek:
        case ExtenderCmdFileSize:
        case ExtenderCmdDelete:
        case ExtenderCmdSetSettings:
        case ExtenderCmdStartSettings:
        case ExtenderCmdEndSettings:
        case ExtenderCmdStartActivity:
        case ExtenderCmdEndActivity:
            //TestLog_SleepFiles
        case ExtenderCmdStartSleepSummary:
        case ExtenderCmdEndSleepSummary:
        case ExtenderCmdStartSleepKeyFile:
        case ExtenderCmdEndSleepKeyFile:
        case ExtenderCmdStartActigraphyFile:
        case ExtenderCmdEndActigraphyFile:
            //TestLog_SleepFiles
        case ExtenderCmdFileSessionStart:
        case ExtenderCmdFileSessionEnd:
        case ExtenderCmdStartFirmware:
        case ExtenderCmdEndFirmware:
        case ExtenderCmdCancelFirmware:
        case ExtenderCmdRestartFirmware:
        case ExtenderCmdPauseFirmware:
        case ExtenderCmdEnterBootloaderMode:
        case ExtenderCmdFactoryReset:
        case ExtenderCmdWatchReset:
        case ExtenderCmdForceBootloaderModeExit:
        case ExtenderCmdReboot:
        {
            int size = PCCOMM_MAX_PACKET_LENGTH - [PCCHeader size];
            Byte payload[size];
            [_mPayload getBytes: payload length: size];
            
            if ( NACK == payload[0] )
            {
                code = payload[2];
            }
        }
        break;
    }
    return code;
}
- (NSData *) getExtenderResponseData
{
    NSData * data = nil;
    Byte command = [[_mHeader Command] Get];
    switch( command )
    {
        case ExtenderCmdOpen:
        case ExtenderCmdClose:
        case ExtenderCmdWrite:
        case ExtenderCmdSeek:
        {
            int size = PCCOMM_MAX_PACKET_LENGTH - [PCCHeader size];
            Byte payload[size];
            [_mPayload getBytes: payload length: size];

            Byte dataByte = payload[1];
            data = [[NSData alloc] initWithBytes: &dataByte length: 1];
        }
            break;
        case ExtenderCmdRead:
        case ExtenderCmdFileSize:
        {
            if ( NO_ERROR == [self getExtenderResponseCode])
            {
                Byte payload[_mPayload.length];
                [_mPayload getBytes: payload length: _mPayload.length];
                
                Byte dataBytes[_mPayload.length-2];
                memcpy(&payload[2], dataBytes, _mPayload.length-2);
                data = [[NSData alloc] initWithBytes: dataBytes length: _mPayload.length-2];
            }
        }
            break;
    }
    return data;
}
- (NSData *) get
{
    Byte header[[PCCHeader size]];
    [[_mHeader get] getBytes: header length: [PCCHeader size]];
    
    int size = PCCOMM_MAX_PACKET_LENGTH - [PCCHeader size];
    Byte payload[size];
    [_mPayload getBytes: payload length: size];
    
    NSMutableData *concatenatedData = [NSMutableData dataWithBytes: header length: [PCCHeader size]];
    [concatenatedData appendBytes: payload length: size];
    
    return concatenatedData;
}
- (void) set: (NSData *) inData
{
    if ( nil != inData )
    {
        [_mHeader set: inData];
        
        NSInteger len = inData.length - [PCCHeader size];
        
        if (len > 0)
        {
            NSRange payloadRange = NSMakeRange ([PCCHeader size], len);
            _mPayload = [inData subdataWithRange: payloadRange];
        }
    }
}
@end
