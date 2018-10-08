//
//  TDM328WatchSettingsUserDefaults.h
//  timex
//
//  Created by Varahala Babu on 14/07/16.
//  Copyright © 2016 iDevices, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TDM329WatchSettings.h"
#import "iDevicesUtil.h"
#import "TDDefines.h"

@interface TDM329WatchSettingsUserDefaults : NSObject
{
    
}
+(void)setDailyStepGoal:(NSInteger)value;
+(void)setDailyDistanceGoal:(double)value;
+(void)setDailyCaloriesGoal:(NSInteger)value;
+(void)setDailySleepGoal:(double)value;
+(void)setBedHour:(NSInteger)value;
+(void)setBedMin:(NSInteger)value;
+(void)setAwakeHour:(NSInteger)value;
+(void)setAwakeMin:(NSInteger)value;
+(void)setTrackSleep:(NSInteger)value;
+(void)setSensorSensitivity:(NSInteger)value;
+(void)setDistanceAdjustment:(NSInteger)value;
+(void)setSyncNeeded:(NSInteger)value;
+(void)setTZPrimaryOffset1:(NSInteger)value;
+(void)setTZPrimaryDSTOffset1:(NSInteger)value;
+(void)setTZPrimaryOffset2:(NSInteger)value;
+(void)setTZPrimaryDSTOffset2:(NSInteger)value;
+(void)setTZPrimaryOffset3:(NSInteger)value;
+(void)setTZPrimaryDSTOffset3:(NSInteger)value;
+(void)setTZPrimaryName1:(NSString*)value;
+(void)setTZPrimaryName2:(NSString*)value;
+(void)setTZPrimaryName3:(NSString*)value;
+(void)setTZPrimaryDSTiOSName2:(NSString*)value;
+(void)setTZPrimaryDSTiOSName3:(NSString*)value;
+(void)setAutoSynchMode:(NSInteger)value;
+(void)setAutoSyncNotification:(NSInteger)value;
+(void)setAutoSyncPeriod:(NSInteger)value;
+(void)setAutoSyncTimes1_Hour:(NSInteger)value;
+(void)setAutoSyncTimes1_Minute:(NSInteger)value;
+(void)setAutoSyncTimes1_TimeEnabled:(NSInteger)value;
+(void)setAutoSyncTimes2_Hour:(NSInteger)value;
+(void)setAutoSyncTimes2_Minute:(NSInteger)value;
+(void)setAutoSyncTimes2_TimeEnabled:(NSInteger)value;
+(void)setAutoSyncTimes3_Hour:(NSInteger)value;
+(void)setAutoSyncTimes3_Minute:(NSInteger)value;
+(void)setAutoSyncTimes3_TimeEnabled:(NSInteger)value;
+(void)setAutoSyncTimes4_Hour:(NSInteger)value;
+(void)setAutoSyncTimes4_Minute:(NSInteger)value;
+(void)setAutoSyncTimes4_TimeEnabled:(NSInteger)value;
+(void)setUnits:(NSInteger)value;
+(void)setDisplaySubDial:(NSInteger)value;
+(void)setAlarmHour:(NSInteger)value;
+(void)setAlarmMin:(NSInteger)value;
+(void)setAlarmFrequency:(NSInteger)value;
+(void)setAlarmStatus:(NSInteger)value;
/*
+(void)setWatchdogResets:(NSInteger)value;
+(void)setPowerOnResets:(NSInteger)value;
+(void)setLowPowerResets:(NSInteger)value;
+(void)setSystemResets:(NSInteger)value;
+(void)setCurrentWatchdogResets:(NSInteger)value;
+(void)setCurrentPowerOnResets:(NSInteger)value;
+(void)setCurrentLowPowerResets:(NSInteger)value;
+(void)setCurrentSystemResets:(NSInteger)value;
+(void)setNumberOfCalibrations:(NSInteger)value;
+(void)isResetWarning:(NSInteger)value;
+(void)setNumOfWarnings:(NSInteger)value;
+(void)setWarningTriggered:(NSInteger)value;
+(void)setStoredNames:(NSArray*)values;
 */
+(void)setBatteryVolt:(float)values;
+(void)setTimerTemp:(NSInteger)values;
+(void)setPB4DisplayFunction:(NSInteger)value;
+(void)setMidnightLocation:(NSInteger)value;
+(NSInteger)dailyStepsGoal;
+(NSInteger)dialyDistanceGoal;
+(NSInteger)dailyCaloriesGoal;
+(NSInteger)bedHour;
+(NSInteger)bedMin;
+(NSInteger)awakeHour;
+(NSInteger)awakeMin;
+(NSInteger)trackSleep;
+(NSInteger)sensorSensitivity;
+(NSInteger)distanceAdjustment;
+(NSInteger)syncNeeded;
+(NSInteger)TZPrimaryOffset1;
+(NSInteger)TZPrimaryDSTOffset1;
+(NSInteger)TZPrimaryOffset2;
+(NSInteger)TZPrimaryDSTOffset2;
+(NSInteger)TZPrimaryOffset3;
+(NSInteger)TZPrimaryDSTOffset3;
+(NSString*)TZPrimaryName1;
+(NSString*)TZPrimaryName2;
+(NSString*)TZPrimaryName3;
+(NSString*)TZPrimaryDSTiOSName2;
+(NSString*)TZPrimaryDSTiOSName3;
+(NSInteger)autoSyncMode;
+(NSInteger)autoSyncNotification;
+(NSInteger)autoSyncPeriod;
+(NSInteger)autoSyncTimes1_Hour;
+(NSInteger)autoSyncTimes1_Minute;
+(NSInteger)autoSyncTimes1_TimeEnabled;
+(NSInteger)autoSyncTimes2_Hour;
+(NSInteger)autoSyncTimes2_Minute;
+(NSInteger)autoSyncTimes2_TimeEnabled;
+(NSInteger)autoSyncTimes3_Hour;
+(NSInteger)autoSyncTimes3_Minute;
+(NSInteger)autoSyncTimes3_TimeEnabled;
+(NSInteger)autoSyncTimes4_Hour;
+(NSInteger)autoSyncTimes4_Minute;
+(NSInteger)autoSyncTimes4_TimeEnabled;
+(NSInteger)units;
+(NSInteger)displaySubDial;
+(NSInteger)alarmHour;
+(NSInteger)alarmMin;
+(NSInteger)alarmFrequency;
+(NSInteger)alarmStatus;
+(NSInteger)PB4DisplayFunction;
+(NSInteger)midnightLocation;
/*
+(NSInteger)watchdogResets;
+(NSInteger)powerOnResets;
+(NSInteger)lowPowerResets;
+(NSInteger)systemResets;
+(NSInteger)currentWatchdogResets;
+(NSInteger)currentPowerOnResets;
+(NSInteger)currentLowPowerResets;
+(NSInteger)currentSystemResets;
+(NSInteger)numberOfCalibrations;
+(NSInteger)resetWarning;
+(NSInteger)numOfWarnings;
+(NSInteger)warningTriggered;
+(NSArray*)storedNames;
 */
+(float)batteryVolt;
+(NSInteger)timerTemp;
+(void)setUserAlarm:(NSDate*)date;
+(NSDate*)userAlarm;
+(void)setTimerHour:(NSInteger)value;
+(void)setTimerMin:(NSInteger)value;
+(void)setTimerSec:(NSInteger)value;
+(void)setTimerAction:(NSInteger)value;
+(void)setTimerStatus:(NSInteger)value;
+(NSInteger)timerHour;
+(NSInteger)timerMin;
+(NSInteger)timerSec;
+(NSInteger)timerAction;
+(NSInteger)timerStatus;
+(void)setSecondHandMode:(NSInteger)value;
+(NSInteger)secondHandMode;
+(void)removeSecondHandMode;
+(void)removeM329WatchSettings;
//+(void)removeResets;

+(NSString*)getUnitsStringFormate:(typeM329Units)units;
+ (NSString *)getSensitivityStringFormat:(typeM329Sensitivity)goalType;
+ (NSString *)getGenderStringFormat:(typeM329Gender)gender;
+ (NSString *)getWeekDayName:(typeM329AlarmFrequency)day;
@end
