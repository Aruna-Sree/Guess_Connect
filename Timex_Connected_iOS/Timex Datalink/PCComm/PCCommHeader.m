//
//  PCCommHeader.m
//  Timex Connected
//
//  Created by Lev Verbitsky on 1/20/14.
//  Copyright (c) 2014 iDevices, LLC. All rights reserved.
//

#import "PCCommHeader.h"

@implementation PCCommHeader

@synthesize linkAddress = _linkAddress;
@synthesize packetLength = _packetLength;
@synthesize packetNumber = _packetNumber;
@synthesize source = _source;
@synthesize command = _command;
@synthesize info = _info;
@synthesize reserved = _reserved;

- (id) init: (PCCommCommand *) inValue
{
    if (self = [super init])
    {
        // Initialize variables
    	_packetLength = 0;
    	_packetNumber = 0;
    	_source = [[PCCommPacketSource alloc] init:(Byte) 0];
        _command = inValue;
        _info = [[PCCommCmdInfo alloc] init:(Byte) 0];
        _reserved = 0;
    }
    
    return self;
}
@end
