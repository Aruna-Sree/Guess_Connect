//
//  PCCPacket.h
//  Timex Connected
//
//  Created by Lev Verbitsky on 1/20/14.
//  Copyright (c) 2014 iDevices, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PCCCommandPacket.h"
#import "PCCResponsePacket.h"

@interface PCCPacket : NSObject


- (id) init: (Byte) cmd accessType: (Byte) extenderFileAccessType extenderFile: (NSString *) filename;
- (id) init: (Byte) cmd fileHandle: (Byte) extenderFileHandle filePointer: (int) extenderFilePointer;
- (id) init: (Byte) cmd fileHandle: (Byte) extenderFileHandle readCount: (int) readCount;
- (id) init: (Byte) cmd fileHandle: (Byte) extenderFileHandle rawData: (NSData *) rData;
- (id) initWithResponseRawData: (NSData *) rData;
- (id) init: (Byte) cmd;
- (id) init: (Byte) cmd firmwareFlag: (BOOL) fFlag codeplugFlag: (BOOL) cFlag languageFlag: (BOOL) lFlag;

@property (nonatomic, readonly) BOOL isValid;
@property (nonatomic, readonly) Byte mExtenderReadCount;
@property (nonatomic, readonly) Byte mUpdateLanguage;
@property (nonatomic, readonly) Byte mUpdateFirmware;
@property (nonatomic, readonly) Byte mUpdateCodePlug;
@property (nonatomic, readonly) int         mSubCmd;
@property (nonatomic, readonly) NSString *  mExtenderFileName;
@property (nonatomic, readonly) Byte        mExtenderFileHandle;
@property (nonatomic, readonly) int         mExtenderFilePointer;
@property (nonatomic, readonly) char mSectorStart;
@property (nonatomic, readonly) char mSectorEnd;
@property (nonatomic, readonly, getter = getChecksum) int  mChecksum;
@property (nonatomic, readonly, getter = getNumRespBytes) int mNumRespBytes;
@property (nonatomic, readonly, strong, getter = getPayload) NSData   * mPayload;
@property (nonatomic, readonly, strong, getter = getRawData) NSData   * mRawData;
@property (nonatomic, readonly, getter = getExtenderFileAccessType) Byte mExtenderFileAccessType;
@property (nonatomic, readonly, strong, getter = getResponsePacket) PCCResponsePacket * mResponse;
@property (nonatomic, readonly, strong, getter = getCommandPacket) PCCCommandPacket * mCommandPacket;
@property (nonatomic, readonly, strong) PCCCommand * mCommand;

- (void) SetLinkAddress: (PCCLinkAddress *) address;
@end
