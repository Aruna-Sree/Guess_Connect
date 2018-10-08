//
//  TDDatacastFirmwareUpgradeInfo.h
//  Timex Connected
//
//  Created by Lev Verbitsky on 2/13/14.
//  Copyright (c) 2014 iDevices, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

enum TDDatacastFirmwareUpgradeInfoType
{
    TDDatacastFirmwareUpgradeInfoType_Firmware = 0,
    TDDatacastFirmwareUpgradeInfoType_Codeplug,
    TDDatacastFirmwareUpgradeInfoType_Language
};

@interface TDDatacastFirmwareUpgradeInfo : NSObject

@property (nonatomic) TDDatacastFirmwareUpgradeInfoType type;
@property (nonatomic, strong) NSString * uri;
@property (nonatomic) NSInteger version;
@property (nonatomic) BOOL downloaded;
@property (nonatomic, strong) NSString * pathToDownloadedFile;
@end
