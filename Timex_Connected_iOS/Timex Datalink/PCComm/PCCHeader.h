//
//  PCCHeader.h
//  Timex Connected
//
//  Created by Lev Verbitsky on 1/20/14.
//  Copyright (c) 2014 iDevices, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PCCLinkAddress.h"
#import "PCCommandInfo.h"
#import "PCCCommand.h"
#import "PCCPacketSource.h"

@interface PCCHeader : NSObject

@property (nonatomic, strong)   PCCCommand * Command;
@property (nonatomic)           Byte PacketNumber;
@property (nonatomic)           Byte PacketLength;
@property (nonatomic, strong)   PCCLinkAddress * linkAddress;
@property (nonatomic, strong)   PCCCommandInfo  * Info;
@property (nonatomic, strong)   PCCPacketSource * Source;

+ (Byte) size;
- (NSData *) get;
- (void)  set: (NSData *)  inData;
@end
