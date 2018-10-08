//
//  PCCommExtendedFirmwareVersionInfo.h
//  Timex
//
//  Created by Lev Verbitsky on 7/31/15.
//  Copyright (c) 2015 iDevices, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#define PCCOMM_SIZE_EXTENDED_VERSION_INFO 34

enum TDM372FirmwareUpgradeInfoType
{
    TDM372FirmwareUpgradeInfoType_Firmware = 0,
    TDM372FirmwareUpgradeInfoType_Codeplug,
    TDM372FirmwareUpgradeInfoType_Activity,
    TDM372FirmwareUpgradeInfoType_Radio,
    
    TDM372FirmwareUpgradeInfoType_Uninitialized
};

@interface TDM372FirmwareUpgradeInfo : NSObject

@property (nonatomic) TDM372FirmwareUpgradeInfoType type;
@property (nonatomic, strong) NSString * uri;
@property (nonatomic) NSInteger version;
@property (nonatomic) BOOL downloaded;
@property (nonatomic, strong) NSString * pathToDownloadedFile;
@property (nonatomic) BOOL processed;
@property (nonatomic) BOOL upgradeRequired;
@property (nonatomic, strong) NSString * filename;

@end

@interface PCCommExtendedFirmwareVersionInfo : NSObject

@property (nonatomic) Byte  ACK;
@property (nonatomic) Byte  number;
@property (nonatomic, strong) NSString * mVersion1;
@property (nonatomic, strong) NSString * mVersion2;
@property (nonatomic, strong) NSString * mVersion3;
@property (nonatomic, strong) NSString * mVersion4;

- (id) init: (NSData *) data;


@end
