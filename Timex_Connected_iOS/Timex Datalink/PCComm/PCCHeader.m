//
//  PCCHeader.m
//  Timex Connected
//
//  Created by Lev Verbitsky on 1/20/14.
//  Copyright (c) 2014 iDevices, LLC. All rights reserved.
//

#import "PCCHeader.h"
#import "PCCommCommands.h"

const int HEADER_SIZE = 8;
const Byte Rsvd = 0;

@implementation PCCHeader

@synthesize Command = _Command;
@synthesize PacketNumber = _PacketNumber;
@synthesize PacketLength = _PacketLength;
@synthesize linkAddress = _linkAddress;
@synthesize Info = _Info;
@synthesize Source = _Source;

- (id) init
{
    if (self = [super init])
    {
        _linkAddress = [[PCCLinkAddress alloc] init: PCC_LINKADDRESS_BLE];
		_PacketLength = 0;
		_PacketNumber = 0;
		_Source = [[PCCPacketSource alloc] init: 0];
		_Command = [[PCCCommand alloc] init: Unrecognized ];
		_Info = [[PCCCommandInfo alloc] init: 0];
    }
    
    return self;
}

+ (Byte) size
{
    return HEADER_SIZE;
}

- (NSData *) get
{
    Byte header[HEADER_SIZE];
    
    header[0] = (Byte)([_linkAddress Get] >> 8);
    header[1] = (Byte)[_linkAddress Get];
    header[2] = _PacketLength;
    header[3] = _PacketNumber;
    header[4] = [_Source Get];
    header[5] = [_Command Get];
    header[6] = [_Info Get];
    header[7] = Rsvd;
    
    return [NSData dataWithBytes: header length: HEADER_SIZE];
}
- (void)  set: (NSData *)  inData
{
    Byte header[HEADER_SIZE];
    [inData getBytes: header length: HEADER_SIZE];
    
    short address = 0;
    if ( inData.length >= HEADER_SIZE )
    {
        address = (short)(header[1] << 8 | header[0]);
        [_linkAddress Set: (char)address ];
        _PacketLength = header[2];
        _PacketNumber = header[3];
        [_Source Set : header[4]];
        [_Command Set: header[5]];
        [_Info Set: header[6]];
    }
}
@end