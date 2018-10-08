//
//  SYSBLOCKSettings.m
//  timex
//
//  Created by Nick Graff on 10/14/16.
//  Copyright © 2016 iDevices, LLC. All rights reserved.
//

#import "SYSBLOCKSettings.h"
#import "OTLogUtil.h"
#import "iDevicesUtil.h"

@implementation SYSBLOCKSettings

- (id) init: (NSData *) inData
{
    if (self = [self init])
    {
        [self readActivities: inData];
    }
    
    return self;
}

- (int) readActivities: (NSData *) inDataObject
{
    int error = noErr;
    Byte raw[40];
    [inDataObject getBytes: raw length:40];
    
#if DEBUG
    OTLog(@"SYSBLOCK Info received");
    OTLog(@"raw Data:");
    [iDevicesUtil dumpData: inDataObject];
#endif
    
    Byte ptrBytesShort2[4];
    memset(ptrBytesShort2, 0, 4);
    [inDataObject getBytes: ptrBytesShort2 range:NSMakeRange(0, 4)];
    sChecksum = [iDevicesUtil byteArrayToInt: ptrBytesShort2];
    NSString *key = [iDevicesUtil createKeyForAppSettingsPropertyWithClass: SYSBLOCK_WatchInfo andIndex: SYSBLOCK_Checksum];
    [[NSUserDefaults standardUserDefaults] setInteger:sChecksum forKey: key];
    
    memset(ptrBytesShort2, 0, 4);
    [inDataObject getBytes: ptrBytesShort2 range:NSMakeRange(4, 4)];
    sBootLoaderState = [iDevicesUtil byteArrayToInt: ptrBytesShort2];
    key = [iDevicesUtil createKeyForAppSettingsPropertyWithClass: SYSBLOCK_WatchInfo andIndex: SYSBLOCK_BootLoaderState];
    [[NSUserDefaults standardUserDefaults] setInteger:sBootLoaderState forKey: key];
    
    Byte ptrBytesShort3[8];
    memset(ptrBytesShort3, 0, 8);
    [inDataObject getBytes: ptrBytesShort3 range:NSMakeRange(8, 8)];
    sModelNumber = [iDevicesUtil byteArrayToLong: ptrBytesShort3];
    key = [iDevicesUtil createKeyForAppSettingsPropertyWithClass: SYSBLOCK_WatchInfo andIndex: SYSBLOCK_ModelNumber];
    [[NSUserDefaults standardUserDefaults] setInteger:sModelNumber forKey: key];
    
    Byte ptrBytesShort1[2];
    memset(ptrBytesShort1, 0, 2);
    [inDataObject getBytes: ptrBytesShort1 range:NSMakeRange(16, 2)];
    sRevision = [iDevicesUtil byteArrayToShort: ptrBytesShort1];
    key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: SYSBLOCK_WatchInfo andIndex: SYSBLOCK_Revision];
    [[NSUserDefaults standardUserDefaults] setInteger:sRevision forKey: key];
    
    memset(ptrBytesShort3, 0, 8);
    [inDataObject getBytes: ptrBytesShort3 range:NSMakeRange(18, 8)];
    sBoardSerialNumber = [iDevicesUtil byteArrayToLong: ptrBytesShort3];
    key = [iDevicesUtil createKeyForAppSettingsPropertyWithClass: SYSBLOCK_WatchInfo andIndex: SYSBLOCK_BoardSerialNumber];
    [[NSUserDefaults standardUserDefaults] setInteger:sBoardSerialNumber forKey: key];
    
    memset(ptrBytesShort2, 0, 4);
    [inDataObject getBytes: ptrBytesShort2 range:NSMakeRange(26, 4)];
    sBootLoaderRevision = [iDevicesUtil byteArrayToInt: ptrBytesShort2];
    key = [iDevicesUtil createKeyForAppSettingsPropertyWithClass: SYSBLOCK_WatchInfo andIndex: SYSBLOCK_BootLoaderRevision];
    [[NSUserDefaults standardUserDefaults] setInteger:sBootLoaderRevision forKey: key];
    
    memset(ptrBytesShort1, 0, 2);
    [inDataObject getBytes: ptrBytesShort1 range:NSMakeRange(30, 2)];
    sSystemHealthRevision = [iDevicesUtil byteArrayToShort: ptrBytesShort1];
    key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: SYSBLOCK_WatchInfo andIndex: SYSBLOCK_SystemHealthRevision];
    [[NSUserDefaults standardUserDefaults] setInteger:sSystemHealthRevision forKey: key];
    
    memset(ptrBytesShort1, 0, 2);
    [inDataObject getBytes: ptrBytesShort1 range:NSMakeRange(32, 2)];
    sWatchdogResets = [iDevicesUtil byteArrayToShort: ptrBytesShort1];
    key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: SYSBLOCK_WatchInfo andIndex: SYSBLOCK_WatchdogResets];
    if (![[NSUserDefaults standardUserDefaults] integerForKey:key])
    {
        [[NSUserDefaults standardUserDefaults] setInteger:sWatchdogResets forKey: key];
    }
    NSString *key2 = [iDevicesUtil createKeyForWatchControlPropertyWithClass: SYSBLOCK_WatchInfo andIndex: SYSBLOCK_CurrentWatchdogResets];
    short currentWatchdogResets = sWatchdogResets - [[NSUserDefaults standardUserDefaults] integerForKey:key];
    if (currentWatchdogResets < 0)
    {
        currentWatchdogResets = sWatchdogResets;
    }
    NSString *keyWarning = [iDevicesUtil createKeyForWatchControlPropertyWithClass: SYSBLOCK_WatchInfo
                                                                          andIndex: SYSBLOCK_ResetWarning];
    if (currentWatchdogResets > [[NSUserDefaults standardUserDefaults] integerForKey:key2])
    {
        [[NSUserDefaults standardUserDefaults] setInteger:1
                                                   forKey:keyWarning];
    }
    [[NSUserDefaults standardUserDefaults] setInteger:currentWatchdogResets forKey: key2];
    
    memset(ptrBytesShort1, 0, 2);
    [inDataObject getBytes: ptrBytesShort1 range:NSMakeRange(34, 2)];
    sPowerOnResets = [iDevicesUtil byteArrayToShort: ptrBytesShort1];
    key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: SYSBLOCK_WatchInfo andIndex: SYSBLOCK_PowerOnResets];
    if (![[NSUserDefaults standardUserDefaults] integerForKey:key])
    {
        [[NSUserDefaults standardUserDefaults] setInteger:sPowerOnResets forKey: key];
    }
    key2 = [iDevicesUtil createKeyForWatchControlPropertyWithClass: SYSBLOCK_WatchInfo andIndex: SYSBLOCK_CurrentPowerOnResets];
    short currentPowerOnResets = sPowerOnResets - [[NSUserDefaults standardUserDefaults] integerForKey:key];
    if (currentPowerOnResets < 0)
    {
        currentPowerOnResets = sPowerOnResets;
    }
    if (currentPowerOnResets > [[NSUserDefaults standardUserDefaults] integerForKey:key2])
    {
        [[NSUserDefaults standardUserDefaults] setInteger:1
                                                   forKey:keyWarning];
    }
    [[NSUserDefaults standardUserDefaults] setInteger:currentPowerOnResets forKey: key2];
    
    memset(ptrBytesShort1, 0, 2);
    [inDataObject getBytes: ptrBytesShort1 range:NSMakeRange(36, 2)];
    sLowPowerResets = [iDevicesUtil byteArrayToShort: ptrBytesShort1];
    key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: SYSBLOCK_WatchInfo andIndex: SYSBLOCK_LowPowerResets];
    if (![[NSUserDefaults standardUserDefaults] integerForKey:key])
    {
        [[NSUserDefaults standardUserDefaults] setInteger:sLowPowerResets forKey: key];
    }
    key2 = [iDevicesUtil createKeyForWatchControlPropertyWithClass: SYSBLOCK_WatchInfo andIndex: SYSBLOCK_CurrentLowPowerResets];
    short currentLowPowerResets = sLowPowerResets - [[NSUserDefaults standardUserDefaults] integerForKey:key];
    if (currentLowPowerResets < 0)
    {
        currentLowPowerResets = sLowPowerResets;
    }
    if (currentLowPowerResets > [[NSUserDefaults standardUserDefaults] integerForKey:key2])
    {
        [[NSUserDefaults standardUserDefaults] setInteger:1
                                                   forKey:keyWarning];
    }
    [[NSUserDefaults standardUserDefaults] setInteger:currentLowPowerResets forKey: key2];
    
    memset(ptrBytesShort1, 0, 2);
    [inDataObject getBytes: ptrBytesShort1 range:NSMakeRange(38, 2)];
    sSystemResets = [iDevicesUtil byteArrayToShort: ptrBytesShort1];
    key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: SYSBLOCK_WatchInfo andIndex: SYSBLOCK_SystemResets];
    if (![[NSUserDefaults standardUserDefaults] integerForKey:key])
    {
        [[NSUserDefaults standardUserDefaults] setInteger:sSystemResets forKey: key];
    }
    key2 = [iDevicesUtil createKeyForWatchControlPropertyWithClass: SYSBLOCK_WatchInfo andIndex: SYSBLOCK_CurrentSystemResets];
    short currentSystemResets = sSystemResets - [[NSUserDefaults standardUserDefaults] integerForKey:key];
    if (currentSystemResets < 0)
    {
        currentSystemResets = sSystemResets;
    }
    [[NSUserDefaults standardUserDefaults] setInteger:currentSystemResets forKey: key2];
    
    key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: SYSBLOCK_WatchInfo andIndex: SYSBLOCK_StoredNames];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyyMMdd_HHmmss"];
    NSArray *paths = NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSArray *init = [[NSArray alloc] init];
    if ([[NSUserDefaults standardUserDefaults] objectForKey:key])
    {
        init = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    }
    
    NSMutableArray *fileArray = [[NSMutableArray alloc] initWithArray:init];
    NSError *error2 = nil;
    if (fileArray.count > 3)
    {
        NSString *string = [NSString stringWithFormat:@"%@/%@",documentsDirectory,fileArray[0]];
        [[NSFileManager defaultManager] removeItemAtPath:string error:&error2];
        [fileArray removeObjectAtIndex:0];
    }
    
    //Store .BIN in iOS Device
    NSString *stringFromDate = [formatter stringFromDate:[NSDate new]];
    NSString *fileName = [NSString stringWithFormat:@"%@_SYSBLOCK.BIN", stringFromDate];
    NSString *fileDirectory = [NSString stringWithFormat:@"%@/%@",documentsDirectory,fileName];
    [[NSFileManager defaultManager] createFileAtPath:fileDirectory
                                            contents:inDataObject
                                          attributes:nil];
    
    
    [fileArray addObject:fileName];
    [[NSUserDefaults standardUserDefaults] setObject:fileArray forKey: key];
    
    return error;
}

@end
