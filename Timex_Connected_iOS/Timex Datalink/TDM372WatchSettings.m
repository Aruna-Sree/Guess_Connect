//
//  TDM372WatchSettings.m
//  Timex
//
//  Created by Lev Verbitsky on 6/4/15.
//  Copyright (c) 2015 iDevices, LLC. All rights reserved.
//

#import "TDM372WatchSettings.h"
#import "PCCommCommands.h"
#import "iDevicesUtil.h"
#import "TDDefines.h"
#import "OTLogUtil.h"
#import "TDWatchProfile.h"

#define  FILE_FORMAT_VERSION  M372_SETTINGS_VERSION

@implementation TDM372WatchSettings

- (id) init
{
    if (self = [super init])
    {
        
    }
    
    return self;
}
- (id) init: (NSData *) inData
{
    if (self = [self init])
    {
        [self setWatchSettings: inData];
    }
    
    return self;
}
- (void) serializeIntoSettings
{
    NSString * key;
    //artf25193 : All entries made during onboarding should be present when user reaches home screen and settings.
//    NSString * key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM372_PropertyClass_UserInfo andIndex: programWatchM372_PropertyClass_UserInfo_Gender];
//    [[NSUserDefaults standardUserDefaults] setInteger: mGender forKey: key];
    
    key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM372_PropertyClass_ActivityTracking andIndex: programWatchM372_PropertyClass_ActivityTracking_SensorSensitivity];
    [[NSUserDefaults standardUserDefaults] setInteger: mSensorSensitivity forKey: key];

    // Edited by Aruna : For metro
    key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: appSettingsM372Sleeptracker_PropertyClass_Activity andIndex: appSettingsM372Sleeptracker_PropertyClass_Activity_Sensor_Sensitivity];
    [[NSUserDefaults standardUserDefaults] setInteger: mSensorSensitivity forKey: key];
    //End
    //artf25193 : All entries made during onboarding should be present when user reaches home screen and settings.
//    key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM372_PropertyClass_UserInfo andIndex: programWatchM372_PropertyClass_UserInfo_Age];
//    [[NSUserDefaults standardUserDefaults] setInteger: mAge forKey: key];
//    
//    key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM372_PropertyClass_UserInfo andIndex: programWatchM372_PropertyClass_UserInfo_Weight];
//    [[NSUserDefaults standardUserDefaults] setInteger: mWeight forKey: key];
//    
//    key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM372_PropertyClass_UserInfo andIndex: programWatchM372_PropertyClass_UserInfo_Height];
//    [[NSUserDefaults standardUserDefaults] setInteger: mHeight forKey: key];
    
//    artf25017 : M372 (iOS): The distance entered in km should remain the same as entered during onboarding or artf25193 : All entries made during onboarding should be present when user reaches home screen and settings.
//    key = [iDevicesUtil createKeyForAppSettingsPropertyWithClass: appSettingsM372_PropertyClass_Goals andIndex: appSettingsM372_PropertyClass_Goals_Steps];
//    [[NSUserDefaults standardUserDefaults] setInteger: mDailyStepGoal forKey: key];
//    
//    key = [iDevicesUtil createKeyForAppSettingsPropertyWithClass: appSettingsM372_PropertyClass_Goals andIndex: appSettingsM372_PropertyClass_Goals_Distance];
//    [[NSUserDefaults standardUserDefaults] setInteger: mDailyDistanceGoal forKey: key];
//    
//    key = [iDevicesUtil createKeyForAppSettingsPropertyWithClass: appSettingsM372_PropertyClass_Goals andIndex: appSettingsM372_PropertyClass_Goals_Calories];
//    [[NSUserDefaults standardUserDefaults] setInteger: mDailyCaloriesGoal forKey: key];
    key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: appSettingsM372Sleeptracker_PropertyClass_Activity andIndex: appSettingsM372Sleeptracker_PropertyClass_Activity_Distance_Adjustment];
    [[NSUserDefaults standardUserDefaults] setInteger: mDistanceAdjustment forKey: key];
    
    //artf25022 : M372 (iOS):Whatever units are used during onboarding should remain throughout the app without having to do a fresh install.
//    key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM372_PropertyClass_General andIndex: programWatchM372_PropertyClass_General_UnitOfMeasure];
//    [[NSUserDefaults standardUserDefaults] setInteger: mUnits forKey: key];
    
    //TestLog_Sleeptracker_Settings
//    key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: appSettingsM372Sleeptracker_PropertyClass_UserInformation andIndex: appSettingsM372Sleeptracker_PropertyClass_UserInformation_Units];
//    [[NSUserDefaults standardUserDefaults] setInteger: mUnits forKey: key];
//    
//    key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: appSettingsM372Sleeptracker_PropertyClass_UserInformation andIndex: appSettingsM372Sleeptracker_PropertyClass_UserInformation_Gender];
//    [[NSUserDefaults standardUserDefaults] setInteger: mGender forKey: key];
//    
//    key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: appSettingsM372Sleeptracker_PropertyClass_UserInformation andIndex: appSettingsM372Sleeptracker_PropertyClass_UserInformation_Weight];
//    [[NSUserDefaults standardUserDefaults] setInteger: mWeight forKey: key];
//    
//    key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: appSettingsM372Sleeptracker_PropertyClass_UserInformation andIndex: appSettingsM372Sleeptracker_PropertyClass_UserInformation_Height];
//    [[NSUserDefaults standardUserDefaults] setInteger: mHeight forKey: key];

    
    [[NSUserDefaults standardUserDefaults] synchronize];

}
- (NSData *) toByteArray
{
    Byte raw[40];
    memset(raw, 0, 40);
    
    raw[0] = FILE_FORMAT_VERSION;
    
    NSString * key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM372_PropertyClass_UserInfo andIndex: programWatchM372_PropertyClass_UserInfo_Gender];
    mGender = [[NSUserDefaults standardUserDefaults] integerForKey: key];
    raw[4] = mGender;
    
    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_Metropolitan) {
       key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: appSettingsM372Sleeptracker_PropertyClass_Activity andIndex: appSettingsM372Sleeptracker_PropertyClass_Activity_Sensor_Sensitivity];
        mSensorSensitivity = [[NSUserDefaults standardUserDefaults] integerForKey: key];
        raw[5] = mSensorSensitivity;
    } else {
        key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM372_PropertyClass_ActivityTracking andIndex: programWatchM372_PropertyClass_ActivityTracking_SensorSensitivity];
        mSensorSensitivity = [[NSUserDefaults standardUserDefaults] integerForKey: key];
        raw[5] = mSensorSensitivity;
    }
    
    key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM372_PropertyClass_UserInfo andIndex: programWatchM372_PropertyClass_UserInfo_Age];
    mAge = [[NSUserDefaults standardUserDefaults] integerForKey: key];
    raw[6] = mAge;
    
    //padding at offset 7
    
    key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM372_PropertyClass_UserInfo andIndex: programWatchM372_PropertyClass_UserInfo_Weight];
    mWeight = [[NSUserDefaults standardUserDefaults] integerForKey: key];
    NSData * ptrDataShort1 = [iDevicesUtil shortToByteArray: CFSwapInt16(mWeight)];
    Byte ptrBytesShort1[2];
    [ptrDataShort1 getBytes: ptrBytesShort1];
    memcpy(&raw[8], ptrBytesShort1, 2);
    
    key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM372_PropertyClass_UserInfo andIndex: programWatchM372_PropertyClass_UserInfo_Height];
    mHeight = [[NSUserDefaults standardUserDefaults] integerForKey: key];
    ptrDataShort1 = [iDevicesUtil shortToByteArray: CFSwapInt16(mHeight)];
    [ptrDataShort1 getBytes: ptrBytesShort1];
    memcpy(&raw[10], ptrBytesShort1, 2);

    
    
    key = [iDevicesUtil createKeyForAppSettingsPropertyWithClass: appSettingsM372_PropertyClass_Goals andIndex: appSettingsM372_PropertyClass_Goals_Steps];
    mDailyStepGoal = (int)[[NSUserDefaults standardUserDefaults] integerForKey: key];
    NSData * ptrDataShort2 = [iDevicesUtil intToByteArray: CFSwapInt32(mDailyStepGoal)];
    Byte ptrBytesShort2[4];
    [ptrDataShort2 getBytes: ptrBytesShort2];
    memcpy(&raw[12], ptrBytesShort2, 4);
    
    key = [iDevicesUtil createKeyForAppSettingsPropertyWithClass: appSettingsM372_PropertyClass_Goals andIndex: appSettingsM372_PropertyClass_Goals_Distance];
    mDailyDistanceGoal = (int)([[NSUserDefaults standardUserDefaults] doubleForKey: key] * 100);
    ptrDataShort2 = [iDevicesUtil intToByteArray: CFSwapInt32(mDailyDistanceGoal)];
    [ptrDataShort2 getBytes: ptrBytesShort2];
    memcpy(&raw[16], ptrBytesShort2, 4);
    
    key = [iDevicesUtil createKeyForAppSettingsPropertyWithClass: appSettingsM372_PropertyClass_Goals andIndex: appSettingsM372_PropertyClass_Goals_Calories];
    mDailyCaloriesGoal = (int)[[NSUserDefaults standardUserDefaults] integerForKey: key];
    ptrDataShort2 = [iDevicesUtil intToByteArray: CFSwapInt32(mDailyCaloriesGoal)];
    [ptrDataShort2 getBytes: ptrBytesShort2];
    memcpy(&raw[20], ptrBytesShort2, 4);
    
    
    
    key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: appSettingsM372Sleeptracker_PropertyClass_Activity andIndex: appSettingsM372Sleeptracker_PropertyClass_Activity_Distance_Adjustment];
    mDistanceAdjustment = [[NSUserDefaults standardUserDefaults] integerForKey: key];
    ptrDataShort1 = [iDevicesUtil shortToByteArray: CFSwapInt16(mDistanceAdjustment)];
    [ptrDataShort1 getBytes: ptrBytesShort1];
    memcpy(&raw[24], ptrBytesShort1, 2);
    
    key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM372_PropertyClass_General andIndex: programWatchM372_PropertyClass_General_UnitOfMeasure];
    mUnits = [[NSUserDefaults standardUserDefaults] integerForKey: key];
    raw[28] = mUnits;
    
    NSDate * now = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components: (NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond) fromDate: now];
    
    raw[29] = [components second];
    
    raw[30] = [components minute];
    raw[31] = [components hour];
    raw[32] = [components day];
    raw[33] = [components month];
    ptrDataShort1 = [iDevicesUtil shortToByteArray: CFSwapInt16([components year])];
    [ptrDataShort1 getBytes: ptrBytesShort1];
    memcpy(&raw[34], ptrBytesShort1, 2);

    _mChecksum = [iDevicesUtil calculateTimexM053Checksum: raw withLength: 36];
    NSData * ptrData = [iDevicesUtil intToByteArray: _mChecksum];
    Byte ptrBytes[4];
    [ptrData getBytes: ptrBytes];
    memcpy(&raw[36], ptrBytes, 4);
    
    NSData * dataContainer = [NSData dataWithBytes: raw length: 40];
    
#if DEBUG
    OTLog(@"Timex M372 outbound settings data");
    OTLog(@"raw Data:");
    [iDevicesUtil dumpData: dataContainer];
    
#endif
    return dataContainer;
}

- (int) setWatchSettings: (NSData *) inDataObject
{
    int error = -1;
    Byte inData[inDataObject.length];
    [inDataObject getBytes: inData];
    
#if DEBUG
    OTLog(@"Timex M372 inbound settings data");
    OTLog(@"raw Data:");
    [iDevicesUtil dumpData: inDataObject];
#endif
    
    mFileFormatVersion = inData[0];
    
    if ( mFileFormatVersion == FILE_FORMAT_VERSION )
    {
        error = noErr;
        
        mReserved1 = inData[1];
        mReserved2 = inData[2];
        mReserved3 = inData[3];
        
        mGender = inData[4];
        mSensorSensitivity = inData[5];
        mAge = inData[6];
        //padding at offset 7
        mWeight = *((short *)&inData[8]);
        mHeight = *((short *)&inData[10]);
        
        Byte ptrBytesInt[4];
        
        memset(ptrBytesInt, 0, 4);
        [inDataObject getBytes: ptrBytesInt range: NSMakeRange(12, 4)];
        mDailyStepGoal = [iDevicesUtil byteArrayToInt: ptrBytesInt];
        if (mDailyStepGoal > M053_MAXIMUM_STEPS_GOAL)
        {
            mDailyStepGoal = M053_MAXIMUM_STEPS_GOAL;
        }

        memset(ptrBytesInt, 0, 4);
        [inDataObject getBytes: ptrBytesInt range: NSMakeRange(16, 4)];
        mDailyDistanceGoal = [iDevicesUtil byteArrayToInt: ptrBytesInt];
        if (mDailyDistanceGoal > M053_MAXIMUM_DISTANCE_GOAL)
        {
            mDailyDistanceGoal = M053_MAXIMUM_DISTANCE_GOAL;
        }
        
        memset(ptrBytesInt, 0, 4);
        [inDataObject getBytes: ptrBytesInt range: NSMakeRange(20, 4)];
        mDailyCaloriesGoal = [iDevicesUtil byteArrayToInt: ptrBytesInt];
        if (mDailyCaloriesGoal > M053_MAXIMUM_CALORIES_GOAL)
        {
            mDailyCaloriesGoal = M053_MAXIMUM_CALORIES_GOAL;
        }
        
        mDistanceAdjustment = *((short *)&inData[24]);
        mReccommendedAdjustment = *((short *)&inData[26]);
        mUnits = inData[28];
        NSLog(@"Received units from watch:%d",mUnits);
        mSeconds = inData[29];
        mMinutes = inData[30];
        mHours = inData[31];
        mDate = inData[32];
        mMonth = inData[33];
        mYear = *((short *)&inData[34]);
    }
    
    return error;
}
@end