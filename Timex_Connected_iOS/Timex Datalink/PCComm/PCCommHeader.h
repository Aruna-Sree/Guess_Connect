//
//  PCCommHeader.h
//  Timex Connected
//
//  Created by Lev Verbitsky on 1/20/14.
//  Copyright (c) 2014 iDevices, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PCCommCommand.h"
#import "PCCommCmdInfo.h"
#import "PCCommPacketSource.h"

enum PCCommLink
{
    USB = 0,
    NFC,
    Bluetooth,
    BluetoothBLE
};

@interface PCCommHeader : NSObject

@property (nonatomic, getter = getLinkAddress, setter = setLinkAddress:) PCCommLink linkAddress;
@property (nonatomic, getter = getPacketLength, setter = setPacketLength:) Byte packetLength;
@property (nonatomic, getter = getPacketNumber, setter = setPacketNumber:) Byte packetNumber;
@property (nonatomic, strong, getter = GetSource, setter = setSource:) PCCommPacketSource * source;
@property (nonatomic, strong, getter = GetCommand, setter = setCommand:) PCCommCommand * command;
@property (nonatomic, strong, getter = GetInfo, setter = setInfo:) PCCommCmdInfo * info;
@property (nonatomic, readonly, getter = GetReserved) Byte reserved;
@end
