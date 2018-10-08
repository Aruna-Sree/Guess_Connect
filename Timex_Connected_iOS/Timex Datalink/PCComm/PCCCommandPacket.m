//
//  PCCCommandPacket.m
//  Timex Connected
//
//  Created by Lev Verbitsky on 1/20/14.
//  Copyright (c) 2014 iDevices, LLC. All rights reserved.
//

#import "PCCCommandPacket.h"
#import "iDevicesUtil.h"

extern const  int PAYLOAD_SIZE = 54;

@implementation PCCCommandPacket

@synthesize mHeader = _mHeader;
@synthesize mPayload = _mPayload;

- (id) init
{
    if (self = [super init])
    {
        _mHeader = [[PCCHeader alloc] init];
        
        Byte payload[PAYLOAD_SIZE];
        memset(payload, 0, PAYLOAD_SIZE);
        _mPayload = [[NSData alloc] initWithBytes: payload length: PAYLOAD_SIZE];
    }
    
    return self;
}

- (NSData *) get
{
    NSMutableData *concatenatedData = [NSMutableData dataWithData: [_mHeader get]];
    [concatenatedData appendData: _mPayload];
    
    return concatenatedData;
}
- (void) set: (NSData *) inData
{
    if ( nil != inData )
    {
        [_mHeader set: inData];
        
        NSRange payloadRange = NSMakeRange ([PCCHeader size], PAYLOAD_SIZE);
        _mPayload = [[NSData alloc] subdataWithRange: payloadRange];
    }
}

- (void) setSubCmd: (Byte) cmd
{
    Byte payload[PAYLOAD_SIZE];
    [_mPayload getBytes: payload length: PAYLOAD_SIZE];
    
    payload[0] = cmd;

    _mPayload = [NSData dataWithBytes: payload length: PAYLOAD_SIZE];
}

- (void) setStartSector: (char ) start
{
    Byte payload[PAYLOAD_SIZE];
    [_mPayload getBytes: payload length: PAYLOAD_SIZE];
    
    payload[1] = (Byte)(start >> 8);
    payload[2] = (Byte)start;
    
    _mPayload = [NSData dataWithBytes: payload length: PAYLOAD_SIZE];
}
- (void) setEndSector: (char ) end
{
    Byte payload[PAYLOAD_SIZE];
    [_mPayload getBytes: payload length: PAYLOAD_SIZE];
    
    payload[3] = (Byte)(end >> 8);
    payload[4] = (Byte)end;
    
    _mPayload = [NSData dataWithBytes: payload length: PAYLOAD_SIZE];
}
- (void) setChecksum: (int) checksum
{
    NSData * checksumData = [iDevicesUtil intToByteArray: checksum];
    Byte checksumBytes[4];
    [checksumData getBytes: checksumBytes length: 4];
    
    Byte payload[PAYLOAD_SIZE];
    [_mPayload getBytes: payload length: PAYLOAD_SIZE];
    
    payload[1] = checksumBytes[0];
    payload[2] = checksumBytes[1];
    payload[3] = checksumBytes[2];
    payload[4] = checksumBytes[3];
    
    _mPayload = [NSData dataWithBytes: payload length: PAYLOAD_SIZE];
}

@end
