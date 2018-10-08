//
//  TDM328WatchSettings.m
//  timex
//
//  Created by Revanth T on 07/07/16.
//  Copyright © 2016 iDevices, LLC. All rights reserved.
//

#import "TDM329WatchSettings.h"
#import "TDM328WatchSettings.h"
#import "iDevicesUtil.h"
#import "TDDefines.h"
#import "PCCommCommands.h"
#import "OTLogUtil.h"
#define  FILE_FORMAT_VERSION  M329_SETTINGS_VERSION

@implementation TDM329WatchSettings

- (id) init
{
    if (self = [super init])
    {
        OTLog(@"TDM329WatchSettings init");
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
    NSString * key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_ActivityTracking
                                                                    andIndex: programWatchM329_PropertyClass_ActivityTracking_SensorSensitivity];
    [[NSUserDefaults standardUserDefaults] setInteger: mSensorSensitivity forKey: key];
  
    key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_ActivityTracking
                                                         andIndex: programWatchM329_PropertyClass_ActivityTracking_DistanceAdjustment];
    [[NSUserDefaults standardUserDefaults] setInteger: mDistanceAdjustment forKey: key];
}

- (NSData *) toByteArray
{
    OTLog(@"toByteArray Timex M329");
    Byte raw[90];
    memset(raw, 0, 90);
    
    raw[0] = FILE_FORMAT_VERSION;
    
    NSString * key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM328_PropertyClass_UserInfo
                                                                    andIndex: programWatchM328_PropertyClass_UserInfo_Gender];
    NSInteger value = [[NSUserDefaults standardUserDefaults] integerForKey: key];
    mGender = ( value == 0 )? M328_Default_Gender : value;
    raw[4] = mGender;
    
    key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_ActivityTracking
                                                         andIndex: programWatchM329_PropertyClass_ActivityTracking_SensorSensitivity];
    mSensorSensitivity = ([[NSUserDefaults standardUserDefaults] integerForKey: key] == 1 )? M328_Default_AccelSensitivity : [[NSUserDefaults standardUserDefaults] integerForKey: key] ;
    raw[5] = mSensorSensitivity;
    
    key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM328_PropertyClass_UserInfo
                                                         andIndex: programWatchM328_PropertyClass_UserInfo_Age];
    mAge = ([[NSUserDefaults standardUserDefaults] integerForKey: key] == 0 )? M328_Default_Age : [[NSUserDefaults standardUserDefaults] integerForKey: key] ;
    raw[6] = mAge;
    
    key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM328_PropertyClass_UserInfo
                                                         andIndex: programWatchM328_PropertyClass_UserInfo_Weight];
    mWeight = ([[NSUserDefaults standardUserDefaults] integerForKey: key] == 0 )? M328_Default_WeightKg : [[NSUserDefaults standardUserDefaults] integerForKey: key] ;
    
    NSData * ptrDataShort1 = [iDevicesUtil shortToByteArray: CFSwapInt16(mWeight)];
    Byte ptrBytesShort1[2];
    [ptrDataShort1 getBytes: ptrBytesShort1];
    memcpy(&raw[7], ptrBytesShort1, 2);
    
    key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM328_PropertyClass_UserInfo
                                                         andIndex: programWatchM328_PropertyClass_UserInfo_Height];
    mHeight = ([[NSUserDefaults standardUserDefaults] integerForKey: key] == 0 )? M328_Default_HeightM : [[NSUserDefaults standardUserDefaults] integerForKey: key] ;
    
    ptrDataShort1 = [iDevicesUtil shortToByteArray: CFSwapInt16(mHeight)];
    [ptrDataShort1 getBytes: ptrBytesShort1];
    memcpy(&raw[9], ptrBytesShort1, 2);
    
    
    
    key = [iDevicesUtil createKeyForAppSettingsPropertyWithClass: appSettingsM329_PropertyClass_Goals
                                                        andIndex: appSettingsM329_PropertyClass_Goals_Steps];
    mDailyStepGoal = (int)(([[NSUserDefaults standardUserDefaults] integerForKey: key] == 0 )? M328_Default_DailyStepGoal : [[NSUserDefaults standardUserDefaults] integerForKey: key] );
    NSData * ptrDataShort2 = [iDevicesUtil intToByteArray: CFSwapInt32(mDailyStepGoal)];
    Byte ptrBytesShort2[4];
    [ptrDataShort2 getBytes: ptrBytesShort2];
    memcpy(&raw[11], ptrBytesShort2, 4);
    
    // Scott told to send distance always in KM
    key = [iDevicesUtil createKeyForAppSettingsPropertyWithClass: appSettingsM329_PropertyClass_Goals
                                                        andIndex: appSettingsM329_PropertyClass_Goals_Distance];
//    if ([[NSUserDefaults standardUserDefaults] integerForKey: key] != 0) {
//        int distance = (int)[[NSUserDefaults standardUserDefaults] integerForKey: key]; // miles
//        CGFloat distanceMiles = (CGFloat)distance/100.0f;
//        CGFloat distanceKM = [iDevicesUtil convertMilesToKilometers:distanceMiles];
//        mDailyDistanceGoal = distanceKM*100;
//    } else {
//        mDailyDistanceGoal = M328_Default_DailyDistanceGoal;
//    }
    mDailyDistanceGoal = (int)([[NSUserDefaults standardUserDefaults] doubleForKey: key] * 100);
    mDailyDistanceGoal = (mDailyDistanceGoal == 0)?M328_Default_DailyDistanceGoal:mDailyDistanceGoal;
    
    ptrDataShort2 = [iDevicesUtil intToByteArray: CFSwapInt32(mDailyDistanceGoal)];
    [ptrDataShort2 getBytes: ptrBytesShort2];
    memcpy(&raw[15], ptrBytesShort2, 4);
    
    key = [iDevicesUtil createKeyForAppSettingsPropertyWithClass: appSettingsM329_PropertyClass_Goals
                                                        andIndex: appSettingsM329_PropertyClass_Goals_Calories];
    mDailyCaloriesGoal = (int)(([[NSUserDefaults standardUserDefaults] integerForKey: key] == 0 )? M328_Default_DailyCalorieGoal : [[NSUserDefaults standardUserDefaults] integerForKey: key] );
    
    ptrDataShort2 = [iDevicesUtil intToByteArray: CFSwapInt32(mDailyCaloriesGoal)];
    [ptrDataShort2 getBytes: ptrBytesShort2];
    memcpy(&raw[19], ptrBytesShort2, 4);
    
    
    
    key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_ActivityTracking
                                                         andIndex: programWatchM329_PropertyClass_ActivityTracking_DistanceAdjustment];
    mDistanceAdjustment = ([[NSUserDefaults standardUserDefaults] integerForKey: key] == 0 )? M328_Default_DistanceAdjustment : [[NSUserDefaults standardUserDefaults] integerForKey: key];
    
    ptrDataShort1 = [iDevicesUtil shortToByteArray: CFSwapInt16(mDistanceAdjustment)];
    [ptrDataShort1 getBytes: ptrBytesShort1];
    memcpy(&raw[23], ptrBytesShort1, 2);
    
    key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_General
                                                         andIndex: programWatchM329_PropertyClass_General_UnitOfMeasure];
    mUnits = ([[NSUserDefaults standardUserDefaults] integerForKey: key] == 0 )? M328_Default_Units : [[NSUserDefaults standardUserDefaults] integerForKey: key];
    raw[27] = mUnits;
    
    NSDate * now = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components: (NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond) fromDate: now];
    
    raw[28] = [components second];
    
    raw[29] = [components minute];
    raw[30] = [components hour];
    raw[31] = [components day];
    raw[32] = [components month];
    ptrDataShort1 = [iDevicesUtil shortToByteArray: CFSwapInt16([components year])];
    [ptrDataShort1 getBytes: ptrBytesShort1];
    memcpy(&raw[33], ptrBytesShort1, 2);
    
    // Activity is always ON.
    mActivityEnable = M328_ACTIVITY_ON;
    raw[35] = mActivityEnable;
    
    key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                         andIndex: programWatchM329_PropertyClass_ActivityDisplaySubdial];
    mActivityDisplaySubdial = ([[NSUserDefaults standardUserDefaults] integerForKey: key] == 0 )? M329_Default_DisplaySubdial : [[NSUserDefaults standardUserDefaults] integerForKey: key];
    raw[36] = mActivityDisplaySubdial;
    
    //Alarm[1]
    key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                         andIndex: programWatchM329_PropertyClass_AlarmHour];
    mAlarmHour = ([[NSUserDefaults standardUserDefaults] integerForKey: key] == 0 )? M328_Default_Alarm_Hr : [[NSUserDefaults standardUserDefaults] integerForKey: key];
    raw[37] = mAlarmHour;
    
    key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                         andIndex: programWatchM329_PropertyClass_AlarmMinute];
    mAlarmMinute = ([[NSUserDefaults standardUserDefaults] integerForKey: key] == 0 )? M328_Default_Alarm_Min : [[NSUserDefaults standardUserDefaults] integerForKey: key];
    raw[38] = mAlarmMinute;
    
    key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                         andIndex: programWatchM329_PropertyClass_AlarmFrequency];
    mAlarmFrequency = ([[NSUserDefaults standardUserDefaults] integerForKey: key] == 0 )? M328_Default_Alarm_Freq : [[NSUserDefaults standardUserDefaults] integerForKey: key];
    raw[39] = mAlarmFrequency;
    
    key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                         andIndex: programWatchM329_PropertyClass_AlarmStatus];
    mAlarmStatus = ([[NSUserDefaults standardUserDefaults] integerForKey: key] == 0 )? M328_Default_Alarm_Status : [[NSUserDefaults standardUserDefaults] integerForKey: key];
    raw[40] = mAlarmStatus;
    
    //Timer[1]
    key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                         andIndex: programWatchM329_PropertyClass_TimerHour];
    mTimerHour = ([[NSUserDefaults standardUserDefaults] integerForKey: key] == 0 )? M328_Default_Timer_Hr : [[NSUserDefaults standardUserDefaults] integerForKey: key];
    raw[41] = mTimerHour;
    
    key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                         andIndex: programWatchM329_PropertyClass_TimerMinute];
    mTimerMinute = ([[NSUserDefaults standardUserDefaults] integerForKey: key] == 0 )? M328_Default_Timer_Min : [[NSUserDefaults standardUserDefaults] integerForKey: key];
    raw[42] = mTimerMinute;
    
    key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                         andIndex: programWatchM329_PropertyClass_TimerSeconds];
    mTimerSeconds = ([[NSUserDefaults standardUserDefaults] integerForKey: key] == 0 )? M328_Default_Timer_Sec : [[NSUserDefaults standardUserDefaults] integerForKey: key];
    raw[43] = mTimerSeconds;
    
    key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                         andIndex: programWatchM329_PropertyClass_TimerAction];
    mTimerAction = ([[NSUserDefaults standardUserDefaults] integerForKey: key] == 0 )? M328_Default_Timer_Action : [[NSUserDefaults standardUserDefaults] integerForKey: key];
    raw[44] = mTimerAction;
    
    key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                         andIndex: programWatchM329_PropertyClass_TimerEnable];
    mTimerEnable = ([[NSUserDefaults standardUserDefaults] integerForKey: key] == 0 )? M328_Default_Timer_Status : [[NSUserDefaults standardUserDefaults] integerForKey: key];
    raw[45] = mTimerEnable;
    
    key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                         andIndex: programWatchM329_PropertyClass_TZPrimeayOffset1];
    mTZPrimeayOffset1 = ([[NSUserDefaults standardUserDefaults] integerForKey: key] == 0 )? M329_Default_TZPrimaryOffset : [[NSUserDefaults standardUserDefaults] integerForKey: key];
    raw[46] = mTZPrimeayOffset1;
    
    key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                         andIndex: programWatchM329_PropertyClass_TZPrimaryDSTOffset1];
    mTZPrimaryDSTOffset1 = ([[NSUserDefaults standardUserDefaults] integerForKey: key] == 0 )? M329_Default_TZPrimaryDSTOffset : [[NSUserDefaults standardUserDefaults] integerForKey: key];
    raw[47] = mTZPrimaryDSTOffset1;
    
    key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                         andIndex: programWatchM329_PropertyClass_TZPrimeayOffset2];
    mTZPrimeayOffset2 = ([[NSUserDefaults standardUserDefaults] integerForKey: key] == 0 )? M329_Default_TZPrimaryOffset : [[NSUserDefaults standardUserDefaults] integerForKey: key];
    raw[48] = mTZPrimeayOffset2;
    
    key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                         andIndex: programWatchM329_PropertyClass_TZPrimaryDSTOffset2];
    mTZPrimaryDSTOffset2 = ([[NSUserDefaults standardUserDefaults] integerForKey: key] == 0 )? M329_Default_TZPrimaryDSTOffset : [[NSUserDefaults standardUserDefaults] integerForKey: key];
    raw[49] = mTZPrimaryDSTOffset2;
    
    key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                         andIndex: programWatchM329_PropertyClass_TZPrimeayOffset3];
    mTZPrimeayOffset3 = ([[NSUserDefaults standardUserDefaults] integerForKey: key] == 0 )? M329_Default_TZPrimaryOffset : [[NSUserDefaults standardUserDefaults] integerForKey: key];
    raw[50] = mTZPrimeayOffset3;
    
    key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                         andIndex: programWatchM329_PropertyClass_TZPrimaryDSTOffset3];
    mTZPrimaryDSTOffset3 = ([[NSUserDefaults standardUserDefaults] integerForKey: key] == 0 )? M329_Default_TZPrimaryDSTOffset : [[NSUserDefaults standardUserDefaults] integerForKey: key];
    raw[51] = mTZPrimaryDSTOffset3;
    
    key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                         andIndex: programWatchM329_PropertyClass_SecondHandMode];
    mSecondHandMode = ([[NSUserDefaults standardUserDefaults] integerForKey: key] == 0 )? M328_Default_Seconds_Operation : [[NSUserDefaults standardUserDefaults] integerForKey: key];
    raw[54] = mSecondHandMode;
    
    key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                         andIndex: programWatchM329_PropertyClass_AutoSynchMode];
    mAutoSynchMode = ([[NSUserDefaults standardUserDefaults] integerForKey: key] == 0 )? M328_Default_AutoSynchMode : [[NSUserDefaults standardUserDefaults] integerForKey: key];
    raw[55] = mAutoSynchMode;
    
    key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                         andIndex: programWatchM329_PropertyClass_AutoSyncPeriod];
    mAutoSyncPeriod = ([[NSUserDefaults standardUserDefaults] integerForKey: key] == 0 )? M328_Default_AutoSynchPeriod : (int)[[NSUserDefaults standardUserDefaults] integerForKey: key];
    ptrDataShort2 = [iDevicesUtil intToByteArray: CFSwapInt32(mAutoSyncPeriod)];
    [ptrDataShort2 getBytes: ptrBytesShort2];
    memcpy(&raw[56], ptrBytesShort2, 4);
    
    key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                         andIndex: programWatchM329_PropertyClass_AutoSyncTimes1_Seconds];
    mAutoSyncSeconds1 = ([[NSUserDefaults standardUserDefaults] integerForKey: key] == 0 )? M328_Default_AutoSynchTimeHour : [[NSUserDefaults standardUserDefaults] integerForKey: key];
    raw[60] = mAutoSyncSeconds1;
    
    key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                         andIndex: programWatchM329_PropertyClass_AutoSyncTimes1_Minutes];
    mAutoSyncMinutes1 = ([[NSUserDefaults standardUserDefaults] integerForKey: key] == 0 )? M328_Default_AutoSynchTimeHour : [[NSUserDefaults standardUserDefaults] integerForKey: key];
    raw[61] = mAutoSyncMinutes1;
    
    key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                         andIndex: programWatchM329_PropertyClass_AutoSyncTimes1_Hours];
    mAutoSyncHours1 = ([[NSUserDefaults standardUserDefaults] integerForKey: key] == 0 )? M328_Default_AutoSynchTimeHour : [[NSUserDefaults standardUserDefaults] integerForKey: key];
    raw[62] = mAutoSyncHours1;
    
    key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                         andIndex: programWatchM329_PropertyClass_AutoSyncTimes1_TimeEnabled];
    mAutoSyncTimeEnabled1 = ([[NSUserDefaults standardUserDefaults] integerForKey: key] == 0 )? M328_Default_AutoSynchEnable : [[NSUserDefaults standardUserDefaults] integerForKey: key];
    raw[63] = mAutoSyncTimeEnabled1;
    
    key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                         andIndex: programWatchM329_PropertyClass_AutoSyncTimes2_Seconds];
    mAutoSyncSeconds2 = ([[NSUserDefaults standardUserDefaults] integerForKey: key] == 0 )? M328_Default_AutoSynchTimeHour : [[NSUserDefaults standardUserDefaults] integerForKey: key];
    raw[64] = mAutoSyncSeconds2;
    
    key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                         andIndex: programWatchM329_PropertyClass_AutoSyncTimes2_Minutes];
    mAutoSyncMinutes2 = ([[NSUserDefaults standardUserDefaults] integerForKey: key] == 0 )? M328_Default_AutoSynchTimeHour : [[NSUserDefaults standardUserDefaults] integerForKey: key];
    raw[65] = mAutoSyncMinutes2;
    
    key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                         andIndex: programWatchM329_PropertyClass_AutoSyncTimes2_Hours];
    mAutoSyncHours2 = ([[NSUserDefaults standardUserDefaults] integerForKey: key] == 0 )? M328_Default_AutoSynchTimeHour : [[NSUserDefaults standardUserDefaults] integerForKey: key];
    raw[66] = mAutoSyncHours2;
    
    key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                         andIndex: programWatchM329_PropertyClass_AutoSyncTimes2_TimeEnabled];
    mAutoSyncTimeEnabled2 = ([[NSUserDefaults standardUserDefaults] integerForKey: key] == 0 )? M328_Default_AutoSynchEnable : [[NSUserDefaults standardUserDefaults] integerForKey: key];
    raw[67] = mAutoSyncTimeEnabled2;
    
    key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                         andIndex: programWatchM329_PropertyClass_AutoSyncTimes3_Seconds];
    mAutoSyncSeconds3 = ([[NSUserDefaults standardUserDefaults] integerForKey: key] == 0 )? M328_Default_AutoSynchTimeHour : [[NSUserDefaults standardUserDefaults] integerForKey: key];
    raw[68] = mAutoSyncSeconds3;
    
    key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                         andIndex: programWatchM329_PropertyClass_AutoSyncTimes3_Minutes];
    mAutoSyncMinutes3 = ([[NSUserDefaults standardUserDefaults] integerForKey: key] == 0 )? M328_Default_AutoSynchTimeHour : [[NSUserDefaults standardUserDefaults] integerForKey: key];
    raw[69] = mAutoSyncMinutes3;
    
    key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                         andIndex: programWatchM329_PropertyClass_AutoSyncTimes3_Hours];
    mAutoSyncHours3 = ([[NSUserDefaults standardUserDefaults] integerForKey: key] == 0 )? M328_Default_AutoSynchTimeHour : [[NSUserDefaults standardUserDefaults] integerForKey: key];
    raw[70] = mAutoSyncHours3;
    
    key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                         andIndex: programWatchM329_PropertyClass_AutoSyncTimes3_TimeEnabled];
    mAutoSyncTimeEnabled3 = ([[NSUserDefaults standardUserDefaults] integerForKey: key] == 0 )? M328_Default_AutoSynchEnable : [[NSUserDefaults standardUserDefaults] integerForKey: key];
    raw[71] = mAutoSyncTimeEnabled3;
    
    key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                         andIndex: programWatchM329_PropertyClass_AutoSyncTimes4_Seconds];
    mAutoSyncSeconds4 = ([[NSUserDefaults standardUserDefaults] integerForKey: key] == 0 )? M328_Default_AutoSynchTimeHour : [[NSUserDefaults standardUserDefaults] integerForKey: key];
    raw[72] = mAutoSyncSeconds4;
    
    key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                         andIndex: programWatchM329_PropertyClass_AutoSyncTimes4_Minutes];
    mAutoSyncMinutes4 = ([[NSUserDefaults standardUserDefaults] integerForKey: key] == 0 )? M328_Default_AutoSynchTimeHour : [[NSUserDefaults standardUserDefaults] integerForKey: key];
    raw[73] = mAutoSyncMinutes4;
    
    key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                         andIndex: programWatchM329_PropertyClass_AutoSyncTimes4_Hours];
    mAutoSyncHours4 = ([[NSUserDefaults standardUserDefaults] integerForKey: key] == 0 )? M328_Default_AutoSynchTimeHour : [[NSUserDefaults standardUserDefaults] integerForKey: key];
    raw[74] = mAutoSyncHours4;
    
    key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                         andIndex: programWatchM329_PropertyClass_AutoSyncTimes4_TimeEnabled];
    mAutoSyncTimeEnabled4 = ([[NSUserDefaults standardUserDefaults] integerForKey: key] == 0 )? M328_Default_AutoSynchEnable : [[NSUserDefaults standardUserDefaults] integerForKey: key];
    raw[75] = mAutoSyncTimeEnabled4;
    
    key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                         andIndex: programWatchM329_PropertyClass_PB4DisplayFunction];
    mPB4DisplayFunction = ([[NSUserDefaults standardUserDefaults] integerForKey: key] == 0 )? M329_Default_PB4DisplayFunction : [[NSUserDefaults standardUserDefaults] integerForKey: key];
    raw[83] = mPB4DisplayFunction;
    
    key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                         andIndex: programWatchM329_PropertyClass_MidnightLocation];
    mMidnightLocation = ([[NSUserDefaults standardUserDefaults] integerForKey: key] == 0 )? M329_Default_MidnightLocation : [[NSUserDefaults standardUserDefaults] integerForKey: key];
    ptrDataShort1 = [iDevicesUtil shortToByteArray: CFSwapInt16(mMidnightLocation)];
    [ptrDataShort1 getBytes: ptrBytesShort1 length:2];
    memcpy(&raw[84], ptrBytesShort1, 2);
    
    _mChecksum = [iDevicesUtil calculateTimexM053Checksum: raw withLength: 86];
    NSData * ptrData = [iDevicesUtil intToByteArray: _mChecksum];
    Byte ptrBytes[4];
    [ptrData getBytes: ptrBytes length:4];
    memcpy(&raw[86], ptrBytes, 4);
    
    NSData * dataContainer = [NSData dataWithBytes: raw length: 90];
    
//#if DEBUG
    OTLog(@"toByteArray Timex M329 outbound settings data");
    OTLog(@"raw Data:");
    //Getting memory issue here
    [iDevicesUtil dumpData: dataContainer];
//#endif
    return dataContainer;
}

- (int) setWatchSettings: (NSData *) inDataObject
{
    int error = -1;
    Byte inData[inDataObject.length];
    [inDataObject getBytes: inData];
    
#if DEBUG
    OTLog(@"setWatchSettings Timex M329 inbound settings data");
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
        mWeight = *((short *)&inData[7]);
        mHeight = *((short *)&inData[9]);
        
        Byte ptrBytesInt[4];
        
        memset(ptrBytesInt, 0, 4);
        [inDataObject getBytes: ptrBytesInt range: NSMakeRange(11, 4)];
        mDailyStepGoal = [iDevicesUtil byteArrayToInt: ptrBytesInt];
        if (mDailyStepGoal > M053_MAXIMUM_STEPS_GOAL)
        {
            mDailyStepGoal = M053_MAXIMUM_STEPS_GOAL;
        }
        
        memset(ptrBytesInt, 0, 4);
        [inDataObject getBytes: ptrBytesInt range: NSMakeRange(15, 4)];
        mDailyDistanceGoal = [iDevicesUtil byteArrayToInt: ptrBytesInt];
        if (mDailyDistanceGoal > M053_MAXIMUM_DISTANCE_GOAL)
        {
            mDailyDistanceGoal = M053_MAXIMUM_DISTANCE_GOAL;
        }
        
        memset(ptrBytesInt, 0, 4);
        [inDataObject getBytes: ptrBytesInt range: NSMakeRange(19, 4)];
        mDailyCaloriesGoal = [iDevicesUtil byteArrayToInt: ptrBytesInt];
        if (mDailyCaloriesGoal > M053_MAXIMUM_CALORIES_GOAL)
        {
            mDailyCaloriesGoal = M053_MAXIMUM_CALORIES_GOAL;
        }
        
        mDistanceAdjustment = *((short *)&inData[23]);
        mReccommendedAdjustment = *((short *)&inData[25]);
        mUnits = inData[27];
        mSeconds = inData[28];
        mMinutes = inData[29];
        mHours = inData[30];
        mDate = inData[31];
        mMonth = inData[32];
        mYear = *((short *)&inData[33]);
        mActivityEnable = inData[35];
        mActivityDisplaySubdial = M329_Default_DisplaySubdial;
        
        mAlarmHour = inData[37];
        mAlarmMinute = inData[38];
        mAlarmFrequency = inData[39];
        mAlarmStatus = inData[40];
        
        mTimerHour = inData[41];
        mTimerMinute = inData[42];
        mTimerSeconds = inData[43];
        mTimerAction = inData[44];
        mTimerEnable = inData[45];
        
        mTZPrimeayOffset1 = inData[46];
        mTZPrimaryDSTOffset1 = inData[47];
        
        mTZPrimeayOffset2 = inData[48];
        mTZPrimaryDSTOffset2 = inData[49];
        
        mTZPrimeayOffset3 = inData[50];
        mTZPrimaryDSTOffset3 = inData[51];
        
        mDeclinationAdjustment = *((short *)&inData[52]);
        mSecondHandMode = inData[54];
        mAutoSynchMode = inData[55];
        
        memset(ptrBytesInt, 0, 4);
        [inDataObject getBytes: ptrBytesInt range: NSMakeRange(56, 4)];
        mAutoSyncPeriod = [iDevicesUtil byteArrayToInt: ptrBytesInt];
        if (mAutoSyncPeriod > M053_MAXIMUM_CALORIES_GOAL)
        {
            mAutoSyncPeriod = M053_MAXIMUM_CALORIES_GOAL;
        }
        
        mAutoSyncSeconds1 = inData[60];
        mAutoSyncMinutes1 = inData[61];
        mAutoSyncHours1  = inData[62];
        mAutoSyncTimeEnabled1 = inData[63];
        
        mAutoSyncSeconds2 = inData[64];
        mAutoSyncMinutes2 = inData[65];
        mAutoSyncHours2 = inData[66];
        mAutoSyncTimeEnabled2 = inData[67];
        
        mAutoSyncSeconds3 = inData[68];
        mAutoSyncMinutes3 = inData[69];
        mAutoSyncHours3 = inData[70];
        mAutoSyncTimeEnabled3 = inData[71];
        
        mAutoSyncSeconds4 = inData[72];
        mAutoSyncMinutes4 = inData[73];
        mAutoSyncHours4 = inData[74];
        mAutoSyncTimeEnabled4 = inData[75];
        
        mDoNotDisturbStartSeconds = inData[76];
        mDoNotDisturbStartMinutes = inData[77];
        mDoNotDisturbStartHours = inData[78];
        
        mDoNotDisturbEndSeconds = inData[79];
        mDoNotDisturbEndMinutes = inData[80];
        mDoNotDisturbEndHours = inData[81];
        
        mDoNotDisturbEnable = inData[82];
        
        mPB4DisplayFunction = inData[83];
        mMidnightLocation = *((short *)&inData[84]);
        
    }
    
    return error;
}
@end
