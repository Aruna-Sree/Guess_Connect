//
//  PCCCommandPacket.h
//  Timex Connected
//
//  Created by Lev Verbitsky on 1/20/14.
//  Copyright (c) 2014 iDevices, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PCCHeader.h"

@interface PCCCommandPacket : NSObject

@property (nonatomic, strong, getter = getHeader) PCCHeader   * mHeader;
@property (nonatomic, strong, getter = getPayload)NSData      * mPayload;

- (NSData *) get;
- (void) setSubCmd: (Byte) cmd;
- (void) setStartSector: (char ) start;
- (void) setEndSector: (char ) end;
- (void) setChecksum: (int) checksum;

@end
