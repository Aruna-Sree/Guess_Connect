//
//  TDM328WatchSettingsUserDefaults.m
//  timex
//
//  Created by Varahala Babu on 14/07/16.
//  Copyright © 2016 iDevices, LLC. All rights reserved.
//

#import "TDM329WatchSettingsUserDefaults.h"
#import "TDDefines.h"


@implementation TDM329WatchSettingsUserDefaults

+(void)setDailyStepGoal:(NSInteger)value{
    NSString *stepsKey = [iDevicesUtil createKeyForAppSettingsPropertyWithClass: appSettingsM329_PropertyClass_Goals
                                                                       andIndex: appSettingsM329_PropertyClass_Goals_Steps];
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:stepsKey];
}
+(NSInteger)dailyStepsGoal{
    
    NSString *stepsKey = [iDevicesUtil createKeyForAppSettingsPropertyWithClass: appSettingsM329_PropertyClass_Goals
                                                                       andIndex: appSettingsM329_PropertyClass_Goals_Steps];
    return [[NSUserDefaults standardUserDefaults]integerForKey:stepsKey];
}
+(void)removeDailyStepsGoal{
    NSString *stepsKey = [iDevicesUtil createKeyForAppSettingsPropertyWithClass: appSettingsM329_PropertyClass_Goals
                                                                       andIndex: appSettingsM329_PropertyClass_Goals_Steps];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:stepsKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:stepsKey];
}
+(void)setDailyDistanceGoal:(double)value{
    NSString *distanceKey = [iDevicesUtil createKeyForAppSettingsPropertyWithClass: appSettingsM329_PropertyClass_Goals
                                                                          andIndex: appSettingsM329_PropertyClass_Goals_Distance];
    [[NSUserDefaults standardUserDefaults] setDouble:value forKey:distanceKey];
}
+(NSInteger)dialyDistanceGoal{
    NSString *distanceKey = [iDevicesUtil createKeyForAppSettingsPropertyWithClass: appSettingsM329_PropertyClass_Goals
                                                                          andIndex: appSettingsM329_PropertyClass_Goals_Distance];
    return [[NSUserDefaults standardUserDefaults]integerForKey:distanceKey];
    
}
+(void)removeDailyDistanceGoal{
    NSString *distanceKey = [iDevicesUtil createKeyForAppSettingsPropertyWithClass: appSettingsM329_PropertyClass_Goals
                                                                          andIndex: appSettingsM329_PropertyClass_Goals_Distance];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:distanceKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:distanceKey];
}
+(void)setDailyCaloriesGoal:(NSInteger)value{
    NSString * caloriesKey = [iDevicesUtil createKeyForAppSettingsPropertyWithClass: appSettingsM329_PropertyClass_Goals
                                                                           andIndex: appSettingsM329_PropertyClass_Goals_Calories];
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:caloriesKey];
}
+(NSInteger)dailyCaloriesGoal{
    NSString * caloriesKey = [iDevicesUtil createKeyForAppSettingsPropertyWithClass: appSettingsM329_PropertyClass_Goals andIndex: appSettingsM328_PropertyClass_Goals_Calories];
    return [[NSUserDefaults standardUserDefaults]integerForKey:caloriesKey];
}
+(void)removeDailyCaloriesGoal{
    NSString * caloriesKey = [iDevicesUtil createKeyForAppSettingsPropertyWithClass: appSettingsM329_PropertyClass_Goals
                                                                           andIndex: appSettingsM329_PropertyClass_Goals_Calories];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:caloriesKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:caloriesKey];
}
+(void)setDailySleepGoal:(double)value{
    NSString * sleepKey = [iDevicesUtil createKeyForAppSettingsPropertyWithClass: appSettingsM329_PropertyClass_Goals
                                                                        andIndex: appSettingsM329_PropertyClass_Goals_Sleep];
    [[NSUserDefaults standardUserDefaults] setDouble:value forKey:sleepKey];
}
+(double)dailySleepGoal{
    NSString * sleepKey = [iDevicesUtil createKeyForAppSettingsPropertyWithClass: appSettingsM329_PropertyClass_Goals
                                                                        andIndex: appSettingsM329_PropertyClass_Goals_Sleep];
    return [[NSUserDefaults standardUserDefaults]doubleForKey:sleepKey];
}

+(void)removeDailySleepGoal{
     NSString * sleepKey = [iDevicesUtil createKeyForAppSettingsPropertyWithClass: appSettingsM329_PropertyClass_Goals
                                                                         andIndex: appSettingsM329_PropertyClass_Goals_Sleep];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:sleepKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:sleepKey];
}

+(void)setBedHour:(NSInteger)value{
    NSString *bedHourKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_ActivityTracking
                                                                          andIndex: programWatchM329_PropertyClass_ActivityTracking_BedHour];
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:bedHourKey];
}

+(NSInteger)bedHour{
    NSString *bedHourKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_ActivityTracking
                                                                          andIndex: programWatchM329_PropertyClass_ActivityTracking_BedHour];
    return [[NSUserDefaults standardUserDefaults]integerForKey:bedHourKey];
}

+(void)setBedMin:(NSInteger)value{
    NSString *bedMinKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_ActivityTracking
                                                                         andIndex: programWatchM329_PropertyClass_ActivityTracking_BedMinute];
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:bedMinKey];
}

+(NSInteger)bedMin{
    NSString *bedMinKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_ActivityTracking
                                                                         andIndex: programWatchM329_PropertyClass_ActivityTracking_BedMinute];
    return [[NSUserDefaults standardUserDefaults]integerForKey:bedMinKey];
}

+(void)removeBedHour{
    NSString *hourKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_ActivityTracking
                                                                       andIndex: programWatchM329_PropertyClass_ActivityTracking_BedHour];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:hourKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey: hourKey];
}
+(void)removeBedMin{
    NSString *minKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_ActivityTracking
                                                                      andIndex: programWatchM329_PropertyClass_ActivityTracking_BedMinute];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:minKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey: minKey];
}

+(void)setAwakeHour:(NSInteger)value{
    NSString *awakeHourKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_ActivityTracking
                                                                            andIndex: programWatchM329_PropertyClass_ActivityTracking_AwakeHour];
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:awakeHourKey];
}

+(NSInteger)awakeHour{
    NSString *awakeHourKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_ActivityTracking
                                                                            andIndex: programWatchM329_PropertyClass_ActivityTracking_AwakeHour];
    return [[NSUserDefaults standardUserDefaults]integerForKey:awakeHourKey];
}

+(void)setAwakeMin:(NSInteger)value{
    NSString *awakeMinKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_ActivityTracking
                                                                           andIndex: programWatchM329_PropertyClass_ActivityTracking_AwakeMinute];
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:awakeMinKey];
}

+(NSInteger)awakeMin{
    NSString *awakeMinKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_ActivityTracking
                                                                           andIndex: programWatchM329_PropertyClass_ActivityTracking_AwakeMinute];
    return [[NSUserDefaults standardUserDefaults]integerForKey:awakeMinKey];
}

+(void)removeAwakeHour{
    NSString *hourKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_ActivityTracking
                                                                       andIndex: programWatchM329_PropertyClass_ActivityTracking_AwakeHour];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:hourKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey: hourKey];
}
+(void)removeAwakeMin{
    NSString *minKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_ActivityTracking
                                                                      andIndex: programWatchM329_PropertyClass_ActivityTracking_AwakeMinute];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:minKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey: minKey];
}

+(void)setTrackSleep:(NSInteger)value{
    NSString *trackSleepKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_ActivityTracking
                                                                             andIndex: programWatchM329_PropertyClass_ActivityTracking_SleepTracking];
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:trackSleepKey];
}

+(NSInteger)trackSleep{
    NSString *trackSleepKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_ActivityTracking
                                                                             andIndex: programWatchM329_PropertyClass_ActivityTracking_SleepTracking];
    return [[NSUserDefaults standardUserDefaults]integerForKey:trackSleepKey];
}

+(void)removeTrackSleep{
    NSString *trackSleepKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_ActivityTracking
                                                                             andIndex: programWatchM329_PropertyClass_ActivityTracking_SleepTracking];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:trackSleepKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey: trackSleepKey];
}

+(void)setSensorSensitivity:(NSInteger)value{
    NSString *sensorKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_ActivityTracking
                                                                         andIndex: programWatchM329_PropertyClass_ActivityTracking_SensorSensitivity];
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:sensorKey];
}
+(NSInteger)sensorSensitivity{
    
    NSString *sensorKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_ActivityTracking
                                                                         andIndex: programWatchM329_PropertyClass_ActivityTracking_SensorSensitivity];
    
    return [[NSUserDefaults standardUserDefaults]integerForKey:sensorKey];
}
+(void)removeSensorSensitivity{
     NSString *sensorKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_ActivityTracking
                                                                          andIndex: programWatchM329_PropertyClass_ActivityTracking_SensorSensitivity];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:sensorKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:sensorKey];
}
+(void)setDistanceAdjustment:(NSInteger)value{
    NSString * distanceAdjustmentKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_ActivityTracking
                                                                                      andIndex: programWatchM329_PropertyClass_ActivityTracking_DistanceAdjustment];
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:distanceAdjustmentKey];
}
+(NSInteger)distanceAdjustment{
    NSString * distanceAdjustmentKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_ActivityTracking
                                                                                      andIndex: programWatchM329_PropertyClass_ActivityTracking_DistanceAdjustment];
    return [[NSUserDefaults standardUserDefaults]integerForKey:distanceAdjustmentKey];
    
}
+(void)removeDistanceAdjustment{
    NSString * distanceAdjustmentKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_ActivityTracking
                                                                                      andIndex: programWatchM329_PropertyClass_ActivityTracking_DistanceAdjustment];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:distanceAdjustmentKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:distanceAdjustmentKey];
}

+(void)setSyncNeeded:(NSInteger)value{
    NSString * syncNeededKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_General
                                                                              andIndex: programWatchM329_PropertyClass_General_SyncNeeded];
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:syncNeededKey];
}

+(NSInteger)syncNeeded{
    NSString * syncNeededKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_General
                                                                              andIndex: programWatchM329_PropertyClass_General_SyncNeeded];
    return [[NSUserDefaults standardUserDefaults]integerForKey:syncNeededKey];
}

+(void)removeSyncNeeded{
    NSString * syncNeededKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_General
                                                                              andIndex: programWatchM329_PropertyClass_General_SyncNeeded];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:syncNeededKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:syncNeededKey];
}
+(void)setTZPrimaryOffset1:(NSInteger)value{
    NSString * TZPrimaryOffsetKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                              andIndex: programWatchM329_PropertyClass_TZPrimeayOffset1];
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:TZPrimaryOffsetKey];
}

+(NSInteger)TZPrimaryOffset1{
    NSString * TZPrimaryOffsetKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                   andIndex: programWatchM329_PropertyClass_TZPrimeayOffset1];
    return [[NSUserDefaults standardUserDefaults]integerForKey:TZPrimaryOffsetKey];
}

+(void)removeTZPrimaryOffset1{
    NSString * TZPrimaryOffsetKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                   andIndex: programWatchM329_PropertyClass_TZPrimeayOffset1];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:TZPrimaryOffsetKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:TZPrimaryOffsetKey];
}
+(void)setTZPrimaryDSTOffset1:(NSInteger)value{
    NSString * TZPrimaryDSTOffsetKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                   andIndex: programWatchM329_PropertyClass_TZPrimaryDSTOffset1];
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:TZPrimaryDSTOffsetKey];
}

+(NSInteger)TZPrimaryDSTOffset1{
    NSString * TZPrimaryDSTOffsetKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                   andIndex: programWatchM329_PropertyClass_TZPrimaryDSTOffset1];
    return [[NSUserDefaults standardUserDefaults]integerForKey:TZPrimaryDSTOffsetKey];
}

+(void)removeTZPrimaryDSTOffset1{
    NSString * TZPrimaryDSTOffsetKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                   andIndex: programWatchM329_PropertyClass_TZPrimaryDSTOffset1];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:TZPrimaryDSTOffsetKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:TZPrimaryDSTOffsetKey];
}
+(void)setTZPrimaryOffset2:(NSInteger)value{
    NSString * TZPrimaryOffsetKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo andIndex: programWatchM329_PropertyClass_TZPrimeayOffset2];
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:TZPrimaryOffsetKey];
    
    //To use in Widgets
    NSUserDefaults *shared = [[NSUserDefaults alloc] initWithSuiteName:TIMEX_GROUP_IDENTIFIER];
    [shared setInteger:value forKey:TZPrimaryOffsetKey];
    [shared synchronize];
    
}

+(NSInteger)TZPrimaryOffset2{
    NSString * TZPrimaryOffsetKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                   andIndex: programWatchM329_PropertyClass_TZPrimeayOffset2];
    //To use in Widgets
    NSUserDefaults *shared = [[NSUserDefaults alloc] initWithSuiteName:TIMEX_GROUP_IDENTIFIER];
    [shared setInteger:[[NSUserDefaults standardUserDefaults]integerForKey:TZPrimaryOffsetKey] forKey:TZPrimaryOffsetKey];
    [shared synchronize];
    return [[NSUserDefaults standardUserDefaults]integerForKey:TZPrimaryOffsetKey];
}

+(void)removeTZPrimaryOffset2{
    NSString * TZPrimaryOffsetKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                   andIndex: programWatchM329_PropertyClass_TZPrimeayOffset2];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:TZPrimaryOffsetKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:TZPrimaryOffsetKey];
    
    //To use in Widgets
    NSUserDefaults *shared = [[NSUserDefaults alloc] initWithSuiteName:TIMEX_GROUP_IDENTIFIER];
    [shared setObject:[NSNumber numberWithInteger:0] forKey:TZPrimaryOffsetKey];
    [shared removeObjectForKey:TZPrimaryOffsetKey];
    [shared synchronize];
}
+(void)setTZPrimaryDSTOffset2:(NSInteger)value{
    NSString * TZPrimaryDSTOffsetKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                      andIndex: programWatchM329_PropertyClass_TZPrimaryDSTOffset2];
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:TZPrimaryDSTOffsetKey];
}

+(NSInteger)TZPrimaryDSTOffset2{
    NSString * TZPrimaryDSTOffsetKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                      andIndex: programWatchM329_PropertyClass_TZPrimaryDSTOffset2];
    return [[NSUserDefaults standardUserDefaults]integerForKey:TZPrimaryDSTOffsetKey];
}

+(void)removeTZPrimaryDSTOffset2{
    NSString * TZPrimaryDSTOffsetKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                      andIndex: programWatchM329_PropertyClass_TZPrimaryDSTOffset2];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:TZPrimaryDSTOffsetKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:TZPrimaryDSTOffsetKey];
}
+(void)setTZPrimaryOffset3:(NSInteger)value{
    NSString * TZPrimaryOffsetKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                   andIndex: programWatchM329_PropertyClass_TZPrimeayOffset3];
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:TZPrimaryOffsetKey];
    
    //To use in Widgets
    NSUserDefaults *shared = [[NSUserDefaults alloc] initWithSuiteName:TIMEX_GROUP_IDENTIFIER];
    [shared setInteger:value forKey:TZPrimaryOffsetKey];
    [shared synchronize];
}

+(NSInteger)TZPrimaryOffset3{
    NSString * TZPrimaryOffsetKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                   andIndex: programWatchM329_PropertyClass_TZPrimeayOffset3];
    //To use in Widgets
    NSUserDefaults *shared = [[NSUserDefaults alloc] initWithSuiteName:TIMEX_GROUP_IDENTIFIER];
    [shared setInteger:[[NSUserDefaults standardUserDefaults]integerForKey:TZPrimaryOffsetKey] forKey:TZPrimaryOffsetKey];
    [shared synchronize];
    return [[NSUserDefaults standardUserDefaults]integerForKey:TZPrimaryOffsetKey];
}

+(void)removeTZPrimaryOffset3{
    NSString * TZPrimaryOffsetKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                   andIndex: programWatchM329_PropertyClass_TZPrimeayOffset3];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:TZPrimaryOffsetKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:TZPrimaryOffsetKey];
    
    //To use in Widgets
    NSUserDefaults *shared = [[NSUserDefaults alloc] initWithSuiteName:TIMEX_GROUP_IDENTIFIER];
    [shared setObject:[NSNumber numberWithInteger:0] forKey:TZPrimaryOffsetKey];
    [shared removeObjectForKey: TZPrimaryOffsetKey];
    [shared synchronize];
}
+(void)setTZPrimaryDSTOffset3:(NSInteger)value{
    NSString * TZPrimaryDSTOffsetKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                      andIndex: programWatchM329_PropertyClass_TZPrimaryDSTOffset3];
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:TZPrimaryDSTOffsetKey];
}

+(NSInteger)TZPrimaryDSTOffset3{
    NSString * TZPrimaryDSTOffsetKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                      andIndex: programWatchM329_PropertyClass_TZPrimaryDSTOffset3];
    return [[NSUserDefaults standardUserDefaults]integerForKey:TZPrimaryDSTOffsetKey];
}

+(void)removeTZPrimaryDSTOffset3{
    NSString * TZPrimaryDSTOffsetKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                      andIndex: programWatchM329_PropertyClass_TZPrimaryDSTOffset3];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:TZPrimaryDSTOffsetKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:TZPrimaryDSTOffsetKey];
}
+(void)setTZPrimaryName1:(NSString*)value{
    NSString * TZPrimaryNameKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                 andIndex: programWatchM329_PropertyClass_TZPrimaryName1];
    [[NSUserDefaults standardUserDefaults] setObject:value forKey:TZPrimaryNameKey];
}

+(NSString*)TZPrimaryName1{
    NSString * TZPrimaryNameKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                 andIndex: programWatchM329_PropertyClass_TZPrimaryName1];
    return [[NSUserDefaults standardUserDefaults]objectForKey:TZPrimaryNameKey];
}

+(void)removeTZPrimaryName1{
    NSString * TZPrimaryNameKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                 andIndex: programWatchM329_PropertyClass_TZPrimaryName1];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:TZPrimaryNameKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:TZPrimaryNameKey];
}
+(void)setTZPrimaryName2:(NSString*)value{
    NSString * TZPrimaryNameKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                 andIndex: programWatchM329_PropertyClass_TZPrimaryName2];
    [[NSUserDefaults standardUserDefaults] setObject:value forKey:TZPrimaryNameKey];
    
    //To use in Widgets
    NSUserDefaults *shared = [[NSUserDefaults alloc] initWithSuiteName:TIMEX_GROUP_IDENTIFIER];
    [shared setObject:value forKey:TZPrimaryNameKey];
    [shared synchronize];
}

+(NSString*)TZPrimaryName2{
    NSString * TZPrimaryNameKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                 andIndex: programWatchM329_PropertyClass_TZPrimaryName2];
    //To use in Widgets
    NSUserDefaults *shared = [[NSUserDefaults alloc] initWithSuiteName:TIMEX_GROUP_IDENTIFIER];
    [shared setObject:[[NSUserDefaults standardUserDefaults]objectForKey:TZPrimaryNameKey] forKey:TZPrimaryNameKey];
    [shared synchronize];
    return [[NSUserDefaults standardUserDefaults]objectForKey:TZPrimaryNameKey];
}

+(void)removeTZPrimaryName2{
    NSString * TZPrimaryNameKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                 andIndex: programWatchM329_PropertyClass_TZPrimaryName2];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:TZPrimaryNameKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:TZPrimaryNameKey];
    
    //To use in Widgets
    NSUserDefaults *shared = [[NSUserDefaults alloc] initWithSuiteName:TIMEX_GROUP_IDENTIFIER];
    [shared removeObjectForKey: TZPrimaryNameKey];
    [shared synchronize];
}
+(void)setTZPrimaryName3:(NSString*)value{
    NSString * TZPrimaryNameKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                 andIndex: programWatchM329_PropertyClass_TZPrimaryName3];
    [[NSUserDefaults standardUserDefaults] setObject:value forKey:TZPrimaryNameKey];
    
    //To use in Widgets
    NSUserDefaults *shared = [[NSUserDefaults alloc] initWithSuiteName:TIMEX_GROUP_IDENTIFIER];
    [shared setObject:value forKey:TZPrimaryNameKey];
    [shared synchronize];
}

+(NSString*)TZPrimaryName3{
    NSString * TZPrimaryNameKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                 andIndex: programWatchM329_PropertyClass_TZPrimaryName3];
    //To use in Widgets
    NSUserDefaults *shared = [[NSUserDefaults alloc] initWithSuiteName:TIMEX_GROUP_IDENTIFIER];
    [shared setObject:[[NSUserDefaults standardUserDefaults]objectForKey:TZPrimaryNameKey] forKey:TZPrimaryNameKey];
    [shared synchronize];
    return [[NSUserDefaults standardUserDefaults]objectForKey:TZPrimaryNameKey];
}

+(void)removeTZPrimaryName3{
    NSString * TZPrimaryNameKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                 andIndex: programWatchM329_PropertyClass_TZPrimaryName3];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:TZPrimaryNameKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:TZPrimaryNameKey];
    
    //To use in Widgets
    NSUserDefaults *shared = [[NSUserDefaults alloc] initWithSuiteName:TIMEX_GROUP_IDENTIFIER];
    [shared removeObjectForKey: TZPrimaryNameKey];
    [shared synchronize];
}
+(void)setTZPrimaryDSTiOSName2:(NSString*)value{
    NSString * TZPrimaryNameKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                 andIndex: programWatchM329_PropertyClass_TZPrimaryDSTiOSName2];
    [[NSUserDefaults standardUserDefaults] setObject:value forKey:TZPrimaryNameKey];
    
    //To use in Widgets
    NSUserDefaults *shared = [[NSUserDefaults alloc] initWithSuiteName:TIMEX_GROUP_IDENTIFIER];
    [shared setObject:value forKey:TZPrimaryNameKey];
    [shared synchronize];
}

+(NSString*)TZPrimaryDSTiOSName2{
    NSString * TZPrimaryNameKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                 andIndex: programWatchM329_PropertyClass_TZPrimaryDSTiOSName2];
    //To use in Widgets
    NSUserDefaults *shared = [[NSUserDefaults alloc] initWithSuiteName:TIMEX_GROUP_IDENTIFIER];
    [shared setObject:[[NSUserDefaults standardUserDefaults]objectForKey:TZPrimaryNameKey] forKey:TZPrimaryNameKey];
    [shared synchronize];
    return [[NSUserDefaults standardUserDefaults]objectForKey:TZPrimaryNameKey];
}

+(void)removeTZPrimaryDSTiOSName2{
    NSString * TZPrimaryNameKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                 andIndex: programWatchM329_PropertyClass_TZPrimaryDSTiOSName2];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:TZPrimaryNameKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:TZPrimaryNameKey];
    
    //To use in Widgets
    NSUserDefaults *shared = [[NSUserDefaults alloc] initWithSuiteName:TIMEX_GROUP_IDENTIFIER];
    [shared removeObjectForKey: TZPrimaryNameKey];
    [shared synchronize];
}
+(void)setTZPrimaryDSTiOSName3:(NSString*)value{
    NSString * TZPrimaryNameKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                 andIndex: programWatchM329_PropertyClass_TZPrimaryDSTiOSName2];
    [[NSUserDefaults standardUserDefaults] setObject:value forKey:TZPrimaryNameKey];
    
    //To use in Widgets
    NSUserDefaults *shared = [[NSUserDefaults alloc] initWithSuiteName:TIMEX_GROUP_IDENTIFIER];
    [shared setObject:value forKey:TZPrimaryNameKey];
    [shared synchronize];
}

+(NSString*)TZPrimaryDSTiOSName3{
    NSString * TZPrimaryNameKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                 andIndex: programWatchM329_PropertyClass_TZPrimaryDSTiOSName2];
    //To use in Widgets
    NSUserDefaults *shared = [[NSUserDefaults alloc] initWithSuiteName:TIMEX_GROUP_IDENTIFIER];
    [shared setObject:[[NSUserDefaults standardUserDefaults]objectForKey:TZPrimaryNameKey] forKey:TZPrimaryNameKey];
    [shared synchronize];
    return [[NSUserDefaults standardUserDefaults]objectForKey:TZPrimaryNameKey];
}

+(void)removeTZPrimaryDSTiOSName3{
    NSString * TZPrimaryNameKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                 andIndex: programWatchM329_PropertyClass_TZPrimaryDSTiOSName2];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:TZPrimaryNameKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:TZPrimaryNameKey];
    
    //To use in Widgets
    NSUserDefaults *shared = [[NSUserDefaults alloc] initWithSuiteName:TIMEX_GROUP_IDENTIFIER];
    [shared removeObjectForKey: TZPrimaryNameKey];
    [shared synchronize];
}
+(void)setAutoSynchMode:(NSInteger)value{
    NSString * autoSyncModeKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                andIndex: programWatchM329_PropertyClass_AutoSynchMode];
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:autoSyncModeKey];
}

+(NSInteger)autoSyncMode{
    NSString * autoSyncModeKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                andIndex: programWatchM329_PropertyClass_AutoSynchMode];
    return [[NSUserDefaults standardUserDefaults]integerForKey:autoSyncModeKey];
}

+(void)removeAutoSyncMode{
    NSString * autoSyncModeKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                andIndex: programWatchM329_PropertyClass_AutoSynchMode];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:autoSyncModeKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:autoSyncModeKey];
}

+(void)setAutoSyncNotification:(NSInteger)value{
    NSString * autoSyncNotificationKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                        andIndex: programWatchM329_PropertyClass_AutoSyncNotification];
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:autoSyncNotificationKey];
}

+(NSInteger)autoSyncNotification{
    NSString * autoSyncNotificationKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                        andIndex: programWatchM329_PropertyClass_AutoSyncNotification];
    return [[NSUserDefaults standardUserDefaults]integerForKey:autoSyncNotificationKey];
}

+(void)removeAutoSyncNotification{
    NSString * autoSyncNotificationKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                        andIndex: programWatchM329_PropertyClass_AutoSyncNotification];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:autoSyncNotificationKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:autoSyncNotificationKey];
}

+(void)setAutoSyncPeriod:(NSInteger)value{
    NSString * autoSyncPeriodKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                  andIndex: programWatchM329_PropertyClass_AutoSyncPeriod];
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:autoSyncPeriodKey];
}

+(NSInteger)autoSyncPeriod{
    NSString * autoSyncPeriodKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                  andIndex: programWatchM329_PropertyClass_AutoSyncPeriod];
    return [[NSUserDefaults standardUserDefaults]integerForKey:autoSyncPeriodKey];
}

+(void)removeAutoSyncPeriod{
    NSString * autoSyncPeriodKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                  andIndex: programWatchM329_PropertyClass_AutoSyncPeriod];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:autoSyncPeriodKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:autoSyncPeriodKey];
}

+(void)setAutoSyncTimes1_Hour:(NSInteger)value{
    NSString * autoSyncTimes1_HoursKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                        andIndex: programWatchM329_PropertyClass_AutoSyncTimes1_Hours];
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:autoSyncTimes1_HoursKey];
}

+(NSInteger)autoSyncTimes1_Hour{
    NSString * autoSyncTimes1_HoursKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                        andIndex: programWatchM329_PropertyClass_AutoSyncTimes1_Hours];
    return [[NSUserDefaults standardUserDefaults]integerForKey:autoSyncTimes1_HoursKey];
}

+(void)removeAutoSyncTimes1_Hour{
    NSString * autoSyncTimes1_HoursKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                        andIndex: programWatchM329_PropertyClass_AutoSyncTimes1_Hours];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:autoSyncTimes1_HoursKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:autoSyncTimes1_HoursKey];
}

+(void)setAutoSyncTimes1_Minute:(NSInteger)value{
    NSString * autoSyncTimes1_MinutesKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                          andIndex: programWatchM329_PropertyClass_AutoSyncTimes1_Minutes];
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:autoSyncTimes1_MinutesKey];
}

+(NSInteger)autoSyncTimes1_Minute{
    NSString * autoSyncTimes1_MinutesKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                          andIndex: programWatchM329_PropertyClass_AutoSyncTimes1_Minutes];
    return [[NSUserDefaults standardUserDefaults]integerForKey:autoSyncTimes1_MinutesKey];
}

+(void)removeAutoSyncTimes1_Minute{
    NSString * autoSyncTimes1_MinutesKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                          andIndex: programWatchM329_PropertyClass_AutoSyncTimes1_Minutes];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:autoSyncTimes1_MinutesKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:autoSyncTimes1_MinutesKey];
}

+(void)setAutoSyncTimes1_TimeEnabled:(NSInteger)value{
    NSString * autoSyncTimes1_TimeEnabledKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                              andIndex: programWatchM329_PropertyClass_AutoSyncTimes1_TimeEnabled];
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:autoSyncTimes1_TimeEnabledKey];
}

+(NSInteger)autoSyncTimes1_TimeEnabled{
    NSString * autoSyncTimes1_TimeEnabledKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                              andIndex: programWatchM329_PropertyClass_AutoSyncTimes1_TimeEnabled];
    return [[NSUserDefaults standardUserDefaults]integerForKey:autoSyncTimes1_TimeEnabledKey];
}

+(void)removeAutoSyncTimes1_TimeEnabled{
    NSString * autoSyncTimes1_TimeEnabledKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                              andIndex: programWatchM329_PropertyClass_AutoSyncTimes1_TimeEnabled];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:autoSyncTimes1_TimeEnabledKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:autoSyncTimes1_TimeEnabledKey];
}
+(void)setAutoSyncTimes2_Hour:(NSInteger)value{
    NSString * autoSyncTimes2_HoursKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                        andIndex: programWatchM329_PropertyClass_AutoSyncTimes2_Hours];
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:autoSyncTimes2_HoursKey];
}

+(NSInteger)autoSyncTimes2_Hour{
    NSString * autoSyncTimes2_HoursKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                        andIndex: programWatchM329_PropertyClass_AutoSyncTimes2_Hours];
    return [[NSUserDefaults standardUserDefaults]integerForKey:autoSyncTimes2_HoursKey];
}

+(void)removeAutoSyncTimes2_Hour{
    NSString * autoSyncTimes2_HoursKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                        andIndex: programWatchM329_PropertyClass_AutoSyncTimes2_Hours];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:autoSyncTimes2_HoursKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:autoSyncTimes2_HoursKey];
}

+(void)setAutoSyncTimes2_Minute:(NSInteger)value{
    NSString * autoSyncTimes2_MinutesKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                          andIndex: programWatchM329_PropertyClass_AutoSyncTimes2_Minutes];
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:autoSyncTimes2_MinutesKey];
}

+(NSInteger)autoSyncTimes2_Minute{
    NSString * autoSyncTimes2_MinutesKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                          andIndex: programWatchM329_PropertyClass_AutoSyncTimes2_Minutes];
    return [[NSUserDefaults standardUserDefaults]integerForKey:autoSyncTimes2_MinutesKey];
}

+(void)removeAutoSyncTimes2_Minute{
    NSString * autoSyncTimes2_MinutesKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                          andIndex: programWatchM329_PropertyClass_AutoSyncTimes2_Minutes];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:autoSyncTimes2_MinutesKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:autoSyncTimes2_MinutesKey];
}

+(void)setAutoSyncTimes2_TimeEnabled:(NSInteger)value{
    NSString * autoSyncTimes2_TimeEnabledKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                              andIndex: programWatchM329_PropertyClass_AutoSyncTimes2_TimeEnabled];
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:autoSyncTimes2_TimeEnabledKey];
}

+(NSInteger)autoSyncTimes2_TimeEnabled{
    NSString * autoSyncTimes2_TimeEnabledKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                              andIndex: programWatchM329_PropertyClass_AutoSyncTimes2_TimeEnabled];
    return [[NSUserDefaults standardUserDefaults]integerForKey:autoSyncTimes2_TimeEnabledKey];
}

+(void)removeAutoSyncTimes2_TimeEnabled{
    NSString * autoSyncTimes2_TimeEnabledKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                              andIndex: programWatchM329_PropertyClass_AutoSyncTimes2_TimeEnabled];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:autoSyncTimes2_TimeEnabledKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:autoSyncTimes2_TimeEnabledKey];
}
+(void)setAutoSyncTimes3_Hour:(NSInteger)value{
    NSString * autoSyncTimes3_HoursKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                        andIndex: programWatchM329_PropertyClass_AutoSyncTimes3_Hours];
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:autoSyncTimes3_HoursKey];
}

+(NSInteger)autoSyncTimes3_Hour{
    NSString * autoSyncTimes3_HoursKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                        andIndex: programWatchM329_PropertyClass_AutoSyncTimes3_Hours];
    return [[NSUserDefaults standardUserDefaults]integerForKey:autoSyncTimes3_HoursKey];
}

+(void)removeAutoSyncTimes3_Hour{
    NSString * autoSyncTimes3_HoursKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                        andIndex: programWatchM329_PropertyClass_AutoSyncTimes3_Hours];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:autoSyncTimes3_HoursKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:autoSyncTimes3_HoursKey];
}

+(void)setAutoSyncTimes3_Minute:(NSInteger)value{
    NSString * autoSyncTimes3_MinutesKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                          andIndex: programWatchM329_PropertyClass_AutoSyncTimes3_Minutes];
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:autoSyncTimes3_MinutesKey];
}

+(NSInteger)autoSyncTimes3_Minute{
    NSString * autoSyncTimes3_MinutesKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                          andIndex: programWatchM329_PropertyClass_AutoSyncTimes3_Minutes];
    return [[NSUserDefaults standardUserDefaults]integerForKey:autoSyncTimes3_MinutesKey];
}

+(void)removeAutoSyncTimes3_Minute{
    NSString * autoSyncTimes3_MinutesKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                          andIndex: programWatchM329_PropertyClass_AutoSyncTimes3_Minutes];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:autoSyncTimes3_MinutesKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:autoSyncTimes3_MinutesKey];
}

+(void)setAutoSyncTimes3_TimeEnabled:(NSInteger)value{
    NSString * autoSyncTimes3_TimeEnabledKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                              andIndex: programWatchM329_PropertyClass_AutoSyncTimes3_TimeEnabled];
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:autoSyncTimes3_TimeEnabledKey];
}

+(NSInteger)autoSyncTimes3_TimeEnabled{
    NSString * autoSyncTimes3_TimeEnabledKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                              andIndex: programWatchM329_PropertyClass_AutoSyncTimes3_TimeEnabled];
    return [[NSUserDefaults standardUserDefaults]integerForKey:autoSyncTimes3_TimeEnabledKey];
}

+(void)removeAutoSyncTimes3_TimeEnabled{
    NSString * autoSyncTimes3_TimeEnabledKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                              andIndex: programWatchM329_PropertyClass_AutoSyncTimes3_TimeEnabled];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:autoSyncTimes3_TimeEnabledKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:autoSyncTimes3_TimeEnabledKey];
}
+(void)setAutoSyncTimes4_Hour:(NSInteger)value{
    NSString * autoSyncTimes4_HoursKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                        andIndex: programWatchM329_PropertyClass_AutoSyncTimes4_Hours];
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:autoSyncTimes4_HoursKey];
}

+(NSInteger)autoSyncTimes4_Hour{
    NSString * autoSyncTimes4_HoursKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                        andIndex: programWatchM329_PropertyClass_AutoSyncTimes4_Hours];
    return [[NSUserDefaults standardUserDefaults]integerForKey:autoSyncTimes4_HoursKey];
}

+(void)removeAutoSyncTimes4_Hour{
    NSString * autoSyncTimes4_HoursKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                        andIndex: programWatchM329_PropertyClass_AutoSyncTimes4_Hours];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:autoSyncTimes4_HoursKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:autoSyncTimes4_HoursKey];
}

+(void)setAutoSyncTimes4_Minute:(NSInteger)value{
    NSString * autoSyncTimes4_MinutesKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                          andIndex: programWatchM329_PropertyClass_AutoSyncTimes4_Minutes];
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:autoSyncTimes4_MinutesKey];
}

+(NSInteger)autoSyncTimes4_Minute{
    NSString * autoSyncTimes4_MinutesKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                          andIndex: programWatchM329_PropertyClass_AutoSyncTimes4_Minutes];
    return [[NSUserDefaults standardUserDefaults]integerForKey:autoSyncTimes4_MinutesKey];
}

+(void)removeAutoSyncTimes4_Minute{
    NSString * autoSyncTimes4_MinutesKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                          andIndex: programWatchM329_PropertyClass_AutoSyncTimes4_Minutes];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:autoSyncTimes4_MinutesKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:autoSyncTimes4_MinutesKey];
}

+(void)setAutoSyncTimes4_TimeEnabled:(NSInteger)value{
    NSString * autoSyncTimes4_TimeEnabledKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                              andIndex: programWatchM329_PropertyClass_AutoSyncTimes4_TimeEnabled];
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:autoSyncTimes4_TimeEnabledKey];
}

+(NSInteger)autoSyncTimes4_TimeEnabled{
    NSString * autoSyncTimes4_TimeEnabledKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                              andIndex: programWatchM329_PropertyClass_AutoSyncTimes4_TimeEnabled];
    return [[NSUserDefaults standardUserDefaults]integerForKey:autoSyncTimes4_TimeEnabledKey];
}

+(void)removeAutoSyncTimes4_TimeEnabled{
    NSString * autoSyncTimes4_TimeEnabledKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                              andIndex: programWatchM329_PropertyClass_AutoSyncTimes4_TimeEnabled];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:autoSyncTimes4_TimeEnabledKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:autoSyncTimes4_TimeEnabledKey];
}


+(void)setUnits:(NSInteger)value {
    
    NSString * unitsKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_General
                                                                         andIndex: programWatchM329_PropertyClass_General_UnitOfMeasure];
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:unitsKey];
}
+(NSInteger)units {
    
    NSString * unitsKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_General
                                                                         andIndex: programWatchM329_PropertyClass_General_UnitOfMeasure];
    return [[NSUserDefaults standardUserDefaults]integerForKey:unitsKey];
}
+(void)removeUnits {
    NSString * unitsKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_General
                                                                         andIndex: programWatchM329_PropertyClass_General_UnitOfMeasure];
     [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:unitsKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:unitsKey];
}

+(void)setDisplaySubDial:(NSInteger)value{
    NSString * subDialKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                           andIndex: programWatchM329_PropertyClass_ActivityDisplaySubdial];
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:subDialKey];
}
+(NSInteger)displaySubDial{
    NSString * subDialKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                           andIndex: programWatchM329_PropertyClass_ActivityDisplaySubdial];
    return [[NSUserDefaults standardUserDefaults]integerForKey:subDialKey];
}

+(void)removeDisplaySubDial{
    NSString * subDialKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                           andIndex: programWatchM329_PropertyClass_ActivityDisplaySubdial];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:subDialKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:subDialKey];
}

+(void)setAlarmHour:(NSInteger)value{
    NSString * alarmHour = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                          andIndex: programWatchM329_PropertyClass_AlarmHour];
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:alarmHour];
}
+(void)setAlarmMin:(NSInteger)value{
    NSString * alarmMin = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                         andIndex: programWatchM329_PropertyClass_AlarmMinute];
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:alarmMin];
}

+(void)setAlarmFrequency:(NSInteger)value{
    NSString * alarmFrequency = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                               andIndex: programWatchM329_PropertyClass_AlarmFrequency];
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:alarmFrequency];
}
+(void)setAlarmStatus:(NSInteger)value{
    NSString * alarmStatus = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                            andIndex: programWatchM329_PropertyClass_AlarmStatus];
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:alarmStatus];
}
+(NSInteger)alarmHour{
    NSString * alarmHour = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                          andIndex: programWatchM329_PropertyClass_AlarmHour];
    return [[NSUserDefaults standardUserDefaults] integerForKey: alarmHour];
}
+(NSInteger)alarmMin{
     NSString * alarmMin = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                          andIndex: programWatchM329_PropertyClass_AlarmMinute];
    return [[NSUserDefaults standardUserDefaults] integerForKey: alarmMin];
}
+(NSInteger)alarmFrequency{
     NSString * alarmFrequency = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                andIndex: programWatchM329_PropertyClass_AlarmFrequency];
    return [[NSUserDefaults standardUserDefaults] integerForKey: alarmFrequency];
}
+(NSInteger)alarmStatus{
     NSString * alarmStatus = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                             andIndex: programWatchM329_PropertyClass_AlarmStatus];
    return [[NSUserDefaults standardUserDefaults] integerForKey: alarmStatus];
}
+(void)setUserAlarm:(NSDate*)date{
    [[NSUserDefaults standardUserDefaults] setObject:date forKey:USER_ALARM];
}
+(NSDate*)userAlarm{
    return [[NSUserDefaults standardUserDefaults] objectForKey:USER_ALARM];
}
+(void)removeAlarmHour{
   NSString * alarmHour = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                         andIndex: programWatchM329_PropertyClass_AlarmHour];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:alarmHour];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:alarmHour];
}
+(void)removeAlarmMin{
    NSString * alarmMinute = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                            andIndex: programWatchM329_PropertyClass_AlarmMinute];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:alarmMinute];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:alarmMinute];
}
+(void)removeAlarmFrequency{
    NSString * alarmFrequency = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                               andIndex: programWatchM329_PropertyClass_AlarmFrequency];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:alarmFrequency];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:alarmFrequency];
}
+(void)removeAlarmStatus{
    NSString * alarmStatus = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                            andIndex: programWatchM329_PropertyClass_AlarmStatus];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:alarmStatus];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:alarmStatus];
}
+(void)removeUserAlarm{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:USER_ALARM];
}
+(void)setTimerHour:(NSInteger)value{
    NSString *hourKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                       andIndex: programWatchM329_PropertyClass_TimerHour];
     [[NSUserDefaults standardUserDefaults] setInteger:value forKey:hourKey];
}
+(void)setTimerMin:(NSInteger)value{
     NSString *minKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                       andIndex: programWatchM329_PropertyClass_TimerMinute];
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:minKey];
}
+(void)setTimerSec:(NSInteger)value{
     NSString *secKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                       andIndex: programWatchM329_PropertyClass_TimerSeconds];
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:secKey];
    
}
+(void)setTimerAction:(NSInteger)value{
     NSString *actionKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                          andIndex: programWatchM329_PropertyClass_TimerAction];
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:actionKey];
    
}
+(void)setTimerStatus:(NSInteger)value{
     NSString *statusKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                          andIndex: programWatchM329_PropertyClass_TimerEnable];
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:statusKey];
    
}
+(NSInteger)timerHour{
     NSString *hourKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                        andIndex: programWatchM329_PropertyClass_TimerHour];
    return [[NSUserDefaults standardUserDefaults] integerForKey: hourKey];
}
+(NSInteger)timerMin{
    NSString *minKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                      andIndex: programWatchM329_PropertyClass_TimerMinute];
    return [[NSUserDefaults standardUserDefaults] integerForKey: minKey];
}
+(NSInteger)timerSec{
    NSString *secKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                      andIndex: programWatchM329_PropertyClass_TimerSeconds];
    return [[NSUserDefaults standardUserDefaults] integerForKey: secKey];
}
+(NSInteger)timerAction{
     NSString *actionKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                          andIndex: programWatchM329_PropertyClass_TimerAction];
    return [[NSUserDefaults standardUserDefaults] integerForKey: actionKey];
}
+(NSInteger)timerStatus{
    NSString *statusKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                         andIndex: programWatchM329_PropertyClass_TimerEnable];
    return [[NSUserDefaults standardUserDefaults] integerForKey: statusKey];
}

+(void)removeTimerHour{
    NSString *hourKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                       andIndex: programWatchM329_PropertyClass_TimerHour];
     [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:hourKey];
     [[NSUserDefaults standardUserDefaults] removeObjectForKey: hourKey];
}
+(void)removeTimerMin{
    NSString *minKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                      andIndex: programWatchM329_PropertyClass_TimerMinute];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:minKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey: minKey];
}
+(void)removeTimerSec{
    NSString *secKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                      andIndex: programWatchM329_PropertyClass_TimerSeconds];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:secKey];
     [[NSUserDefaults standardUserDefaults] removeObjectForKey: secKey];
}
+(void)removeTimerAction{
    NSString *actionKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                         andIndex: programWatchM329_PropertyClass_TimerAction];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:actionKey];
     [[NSUserDefaults standardUserDefaults] removeObjectForKey: actionKey];
}
+(void)removeTimerStatus{
    NSString *statusKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                         andIndex: programWatchM329_PropertyClass_TimerEnable];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:statusKey];
     [[NSUserDefaults standardUserDefaults] removeObjectForKey: statusKey];
}
+(void)setSecondHandMode:(NSInteger)value{
    NSString *handModekey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                           andIndex: programWatchM329_PropertyClass_SecondHandMode];
      [[NSUserDefaults standardUserDefaults] setInteger:value forKey:handModekey];
    //To use in Widgets
    NSUserDefaults *shared = [[NSUserDefaults alloc] initWithSuiteName:TIMEX_GROUP_IDENTIFIER];
    [shared setInteger:value forKey:handModekey];
    [shared synchronize];
}
+(NSInteger)secondHandMode{
    NSString *handModekey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                           andIndex: programWatchM329_PropertyClass_SecondHandMode];
    //To use in Widgets
    NSUserDefaults *shared = [[NSUserDefaults alloc] initWithSuiteName:TIMEX_GROUP_IDENTIFIER];
    [shared setInteger:[[NSUserDefaults standardUserDefaults] integerForKey:handModekey] forKey:handModekey];
    [shared synchronize];
    return [[NSUserDefaults standardUserDefaults] integerForKey: handModekey];
}
+(void)removeSecondHandMode{
    NSString *handModekey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                           andIndex: programWatchM329_PropertyClass_SecondHandMode];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:handModekey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey: handModekey];
    
    //To use in Widgets
    NSUserDefaults *shared = [[NSUserDefaults alloc] initWithSuiteName:TIMEX_GROUP_IDENTIFIER];
    [shared setObject:[NSNumber numberWithInteger:0] forKey:handModekey];
    [shared removeObjectForKey: handModekey];
    [shared synchronize];
}
+(void)setPB4DisplayFunction:(NSInteger)value{
    NSString *PB4DisplayFunctionkey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                     andIndex: programWatchM329_PropertyClass_PB4DisplayFunction];
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:PB4DisplayFunctionkey];
}
+(NSInteger)PB4DisplayFunction{
    NSString *PB4DisplayFunctionkey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                     andIndex: programWatchM329_PropertyClass_PB4DisplayFunction];
    return [[NSUserDefaults standardUserDefaults] integerForKey: PB4DisplayFunctionkey];
}
+(void)removePB4DisplayFunction{
    NSString *PB4DisplayFunctionkey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                     andIndex: programWatchM329_PropertyClass_PB4DisplayFunction];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:PB4DisplayFunctionkey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey: PB4DisplayFunctionkey];
}
+(void)setMidnightLocation:(NSInteger)value{
    NSString *midnightLocationkey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                   andIndex: programWatchM329_PropertyClass_MidnightLocation];
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:midnightLocationkey];
}
+(NSInteger)midnightLocation{
    NSString *midnightLocationkey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                   andIndex: programWatchM329_PropertyClass_MidnightLocation];
    return [[NSUserDefaults standardUserDefaults] integerForKey: midnightLocationkey];
}
+(void)removeMidnightLocation{
    NSString *midnightLocationkey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                                   andIndex: programWatchM329_PropertyClass_MidnightLocation];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:midnightLocationkey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey: midnightLocationkey];
}
/*
+(void)setWatchdogResets:(NSInteger)value{
    NSString *watchdogkey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: SYSBLOCK_WatchInfo andIndex: SYSBLOCK_WatchdogResets];
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:watchdogkey];
}
+(NSInteger)watchdogResets{
    NSString *watchdogkey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: SYSBLOCK_WatchInfo andIndex: SYSBLOCK_WatchdogResets];
    return [[NSUserDefaults standardUserDefaults] integerForKey: watchdogkey];
}
+(void)removeWatchdogResets{
    NSString *watchdogkey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: SYSBLOCK_WatchInfo andIndex: SYSBLOCK_WatchdogResets];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:watchdogkey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey: watchdogkey];
}
+(void)setPowerOnResets:(NSInteger)value{
    NSString *poweronkey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: SYSBLOCK_WatchInfo andIndex: SYSBLOCK_PowerOnResets];
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:poweronkey];
}
+(NSInteger)powerOnResets{
    NSString *poweronkey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: SYSBLOCK_WatchInfo andIndex: SYSBLOCK_PowerOnResets];
    return [[NSUserDefaults standardUserDefaults] integerForKey: poweronkey];
}
+(void)removePowerOnResets{
    NSString *poweronkey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: SYSBLOCK_WatchInfo andIndex: SYSBLOCK_PowerOnResets];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:poweronkey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey: poweronkey];
}
+(void)setLowPowerResets:(NSInteger)value{
    NSString *lowpowerkey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: SYSBLOCK_WatchInfo andIndex: SYSBLOCK_LowPowerResets];
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:lowpowerkey];
}
+(NSInteger)lowPowerResets{
    NSString *lowpowerkey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: SYSBLOCK_WatchInfo andIndex: SYSBLOCK_LowPowerResets];
    return [[NSUserDefaults standardUserDefaults] integerForKey: lowpowerkey];
}
+(void)removeLowPowerResets{
    NSString *lowpowerkey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: SYSBLOCK_WatchInfo andIndex: SYSBLOCK_LowPowerResets];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:lowpowerkey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey: lowpowerkey];
}
+(void)setSystemResets:(NSInteger)value{
    NSString *systemkey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: SYSBLOCK_WatchInfo andIndex: SYSBLOCK_SystemResets];
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:systemkey];
}
+(NSInteger)systemResets{
    NSString *systemkey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: SYSBLOCK_WatchInfo andIndex: SYSBLOCK_SystemResets];
    return [[NSUserDefaults standardUserDefaults] integerForKey: systemkey];
}
+(void)removeSystemResets{
    NSString *systemkey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: SYSBLOCK_WatchInfo andIndex: SYSBLOCK_SystemResets];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:systemkey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey: systemkey];
}
+(void)setCurrentWatchdogResets:(NSInteger)value{
    NSString *watchdogkey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: SYSBLOCK_WatchInfo andIndex: SYSBLOCK_CurrentWatchdogResets];
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:watchdogkey];
}
+(NSInteger)currentWatchdogResets{
    NSString *watchdogkey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: SYSBLOCK_WatchInfo andIndex: SYSBLOCK_CurrentWatchdogResets];
    return [[NSUserDefaults standardUserDefaults] integerForKey: watchdogkey];
}
+(void)removeCurrentWatchdogResets{
    NSString *watchdogkey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: SYSBLOCK_WatchInfo andIndex: SYSBLOCK_CurrentWatchdogResets];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:watchdogkey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey: watchdogkey];
}
+(void)setCurrentPowerOnResets:(NSInteger)value{
    NSString *poweronkey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: SYSBLOCK_WatchInfo andIndex: SYSBLOCK_CurrentPowerOnResets];
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:poweronkey];
}
+(NSInteger)currentPowerOnResets{
    NSString *poweronkey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: SYSBLOCK_WatchInfo andIndex: SYSBLOCK_CurrentPowerOnResets];
    return [[NSUserDefaults standardUserDefaults] integerForKey: poweronkey];
}
+(void)removeCurrentPowerOnResets{
    NSString *poweronkey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: SYSBLOCK_WatchInfo andIndex: SYSBLOCK_CurrentPowerOnResets];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:poweronkey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey: poweronkey];
}
+(void)setCurrentLowPowerResets:(NSInteger)value{
    NSString *lowpowerkey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: SYSBLOCK_WatchInfo andIndex: SYSBLOCK_CurrentLowPowerResets];
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:lowpowerkey];
}
+(NSInteger)currentLowPowerResets{
    NSString *lowpowerkey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: SYSBLOCK_WatchInfo andIndex: SYSBLOCK_CurrentLowPowerResets];
    return [[NSUserDefaults standardUserDefaults] integerForKey: lowpowerkey];
}
+(void)removeCurrentLowPowerResets{
    NSString *lowpowerkey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: SYSBLOCK_WatchInfo andIndex: SYSBLOCK_CurrentLowPowerResets];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:lowpowerkey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey: lowpowerkey];
}
+(void)setCurrentSystemResets:(NSInteger)value{
    NSString *systemkey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: SYSBLOCK_WatchInfo andIndex: SYSBLOCK_CurrentSystemResets];
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:systemkey];
}
+(NSInteger)currentSystemResets{
    NSString *systemkey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: SYSBLOCK_WatchInfo andIndex: SYSBLOCK_CurrentSystemResets];
    return [[NSUserDefaults standardUserDefaults] integerForKey: systemkey];
}
+(void)removeCurrentSystemResets{
    NSString *systemkey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: SYSBLOCK_WatchInfo andIndex: SYSBLOCK_CurrentSystemResets];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:systemkey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey: systemkey];
}
+(void)setNumberOfCalibrations:(NSInteger)value{
    NSString *numberOfCalibrationskey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: SYSBLOCK_WatchInfo andIndex: SYSBLOCK_NumberOfCalibrations];
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:numberOfCalibrationskey];
}
+(NSInteger)numberOfCalibrations{
    NSString *numberOfCalibrationskey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: SYSBLOCK_WatchInfo andIndex: SYSBLOCK_NumberOfCalibrations];
    return [[NSUserDefaults standardUserDefaults] integerForKey: numberOfCalibrationskey];
}
+(void)removeNumberOfCalibrations{
    NSString *numberOfCalibrationskey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: SYSBLOCK_WatchInfo andIndex: SYSBLOCK_NumberOfCalibrations];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:numberOfCalibrationskey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey: numberOfCalibrationskey];
}
+(void)isResetWarning:(NSInteger)value{
    NSString *resetWarningkey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: SYSBLOCK_WatchInfo andIndex: SYSBLOCK_ResetWarning];
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:resetWarningkey];
}
+(NSInteger)resetWarning{
    NSString *resetWarningkey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: SYSBLOCK_WatchInfo andIndex: SYSBLOCK_ResetWarning];
    return [[NSUserDefaults standardUserDefaults] integerForKey: resetWarningkey];
}
+(void)removeResetWarning{
    NSString *resetWarningkey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: SYSBLOCK_WatchInfo andIndex: SYSBLOCK_ResetWarning];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:resetWarningkey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey: resetWarningkey];
}
+(void)setNumOfWarnings:(NSInteger)value{
    NSString *numOfWarningskey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: SYSBLOCK_WatchInfo andIndex: SYSBLOCK_NumOfWarnings];
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:numOfWarningskey];
}
+(NSInteger)numOfWarnings{
    NSString *numOfWarningskey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: SYSBLOCK_WatchInfo andIndex: SYSBLOCK_NumOfWarnings];
    return [[NSUserDefaults standardUserDefaults] integerForKey: numOfWarningskey];
}
+(void)removeNumOfWarnings{
    NSString *numOfWarningskey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: SYSBLOCK_WatchInfo andIndex: SYSBLOCK_NumOfWarnings];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:numOfWarningskey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey: numOfWarningskey];
}
+(void)setWarningTriggered:(NSInteger)value{
    NSString *warningTriggeredkey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: SYSBLOCK_WatchInfo andIndex: SYSBLOCK_WarningTriggered];
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:warningTriggeredkey];
}
+(NSInteger)warningTriggered{
    NSString *warningTriggeredkey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: SYSBLOCK_WatchInfo andIndex: SYSBLOCK_WarningTriggered];
    return [[NSUserDefaults standardUserDefaults] integerForKey: warningTriggeredkey];
}
+(void)removeWarningTriggered{
    NSString *warningTriggeredkey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: SYSBLOCK_WatchInfo andIndex: SYSBLOCK_WarningTriggered];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:warningTriggeredkey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey: warningTriggeredkey];
}
+(void)setStoredNames:(NSArray*)values{
    NSString *storedNameskey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: SYSBLOCK_WatchInfo andIndex: SYSBLOCK_StoredNames];
    [[NSUserDefaults standardUserDefaults] setObject:values forKey:storedNameskey];
}
+(NSArray*)storedNames{
    NSString *storedNameskey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: SYSBLOCK_WatchInfo andIndex: SYSBLOCK_StoredNames];
    return [[NSUserDefaults standardUserDefaults] objectForKey: storedNameskey];
}
+(void)removeStoredNames{
    NSString *storedNameskey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: SYSBLOCK_WatchInfo andIndex: SYSBLOCK_StoredNames];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:storedNameskey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey: storedNameskey];
}
 */
+(void)setBatteryVolt:(float)values{
    NSString *batteryVoltkey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                              andIndex: programWatchM329_PropertyClass_batteryVolt];
    [[NSUserDefaults standardUserDefaults] setFloat:values forKey:batteryVoltkey];
}
+(float)batteryVolt{
    NSString *batteryVoltkey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                              andIndex: programWatchM329_PropertyClass_batteryVolt];
    return [[NSUserDefaults standardUserDefaults] floatForKey: batteryVoltkey];
}
+(void)removeBatteryVolt{
    NSString *batteryVoltkey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                              andIndex: programWatchM329_PropertyClass_batteryVolt];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:batteryVoltkey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey: batteryVoltkey];
}
+(void)setTimerTemp:(NSInteger)values{
    NSString *timerTempkey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                            andIndex: programWatchM329_PropertyClass_timerTemp];
    [[NSUserDefaults standardUserDefaults] setInteger:values forKey:timerTempkey];
}
+(NSInteger)timerTemp{
    NSString *timerTempkey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                            andIndex: programWatchM329_PropertyClass_timerTemp];
    return [[NSUserDefaults standardUserDefaults] integerForKey:timerTempkey];
}
+(void)removeTimerTemp{
    NSString *timerTempkey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM329_PropertyClass_WatchInfo
                                                                            andIndex: programWatchM329_PropertyClass_timerTemp];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:timerTempkey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:timerTempkey];
}
+(NSString*)getUnitsStringFormate:(typeM329Units)units{
    switch (units) {
        case M329_IMPERIAL:
            return @"Imperial";
            break;
        case M329_METRIC:
            return @"Metric";
            break;
        default:
            break;
    }

}
+ (NSString *)getSensitivityStringFormat:(typeM329Sensitivity)goalType {
   
    switch (goalType) {
        case M329_LOW:
            return @"Low";
            break;
        case M329_MEDIUM:
            return @"Medium";
            break;
        case M329_HIGH:
            return @"High";
            break;
        default:
            break;
    }
}
+ (NSString *)getGenderStringFormat:(typeM329Gender)gender {
    switch (gender) {
        case M329_MALE:
            return @"Male";
            break;
        case M329_FEMALE:
            return @"Female";
            break;
        default:
            break;
    }
}

+ (NSString *)getWeekDayName:(typeM329AlarmFrequency)day {
    switch (day) {
            
        case M329_SUNDAY_ALARM:
            return @"Sunday";
            break;
        case M329_MONDAY_ALARM:
            return @"Monday";
            break;
        case M329_TUESDAY_ALARM:
            return @"Tuesday";
            break;
        case M329_WEDNESDAY_ALARM:
            return @"Wednesday";
            break;
        case M329_THURSDAY_ALARM:
            return @"Thursday";
            break;
        case M329_FRIDAY_ALARM:
            return @"Friday";
            break;
        case M329_SATURDAY_ALARM:
            return @"Saturday";
            break;
        case M329_WEEKDAY_ALARM:
            return @"Weekdays";
            break;
        case M329_WEEKEND_ALARM:
            return @"Weekends";
            break;
        case M329_DAILY_ALARM:
            return @"EveryDay";
            break;
        default:
            break;
    }
}

+(void)removeM329WatchSettings
{
    [self removeUnits];
    [self removeDailySleepGoal];
    [self removeDailyStepsGoal];
    [self removeDailyCaloriesGoal];
    [self removeDailyDistanceGoal];
    [self removeBedHour];
    [self removeBedMin];
    [self removeAwakeHour];
    [self removeAwakeMin];
    [self removeTrackSleep];
    [self removeSensorSensitivity];
    [self removeDistanceAdjustment];
    [self removeSyncNeeded];
    [self removeAutoSyncMode];
    [self removeAutoSyncPeriod];
    [self removeAutoSyncTimes1_Hour];
    [self removeAutoSyncTimes1_Minute];
    [self removeAutoSyncTimes1_TimeEnabled];
    [self removeAutoSyncTimes2_Hour];
    [self removeAutoSyncTimes2_Minute];
    [self removeAutoSyncTimes2_TimeEnabled];
    [self removeAutoSyncTimes3_Hour];
    [self removeAutoSyncTimes3_Minute];
    [self removeAutoSyncTimes3_TimeEnabled];
    [self removeAutoSyncTimes4_Hour];
    [self removeAutoSyncTimes4_Minute];
    [self removeAutoSyncTimes4_TimeEnabled];
    [self removeDisplaySubDial];
    [self removeAlarmHour];
    [self removeAlarmMin];
    [self removeAlarmStatus];
    [self removeAlarmFrequency];
    [self removeUserAlarm];
    [self removeSecondHandMode];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
/*
+(void)removeResets
{
    [self removeResetWarning];
    [self removeWatchdogResets];
    [self removePowerOnResets];
    [self removeLowPowerResets];
    [self removeSystemResets];
    [self removeNumberOfCalibrations];
    [self removeNumOfWarnings];
    [self removeWarningTriggered];
}
 */
@end
