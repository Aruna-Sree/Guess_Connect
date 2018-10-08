//
//  TDM053WatchData.m
//  Timex Connected
//
//  Created by Lev Verbitsky on 5/15/14.
//  Copyright (c) 2014 iDevices, LLC. All rights reserved.
//

#import "TDM053WatchData.h"
#import "TDDatacastWatchSettings.h"
#import "TDWorkoutDataM053.h"
#import "TDWatchProfile.h"
#import "iDevicesUtil.h"
#import "TDWatchProfile.h"
#import "TDWorkoutData+Writeable.h"
#import "TDFlurryDataPacket.h"
#import "TimexWatchDB.h"
#import "TDDefines.h"
#import "TDActivityTrackerRecord.h"

#define SETTINGS_DATA_SIZE              57
#define CHRONO_DATA_SIZE                632
#define ACTIVITY_DATA_SIZE              101
#define INTERVAL_TIMER_DATA_SIZE        96
#define FILE_DATA_SIZE                  SETTINGS_DATA_SIZE + APPTS_M053_FILE_DATA_SIZE + CHRONO_DATA_SIZE + ACTIVITY_DATA_SIZE + INTERVAL_TIMER_DATA_SIZE

#define DESCRIPTOR_HEADER_SIZE          0x80
#define DATA_FRESHNESS_OFFSET           0x80 - DESCRIPTOR_HEADER_SIZE
#define DATA_GENERAL_SETTINGS_OFFSET    0x81 - DESCRIPTOR_HEADER_SIZE
#define SECONDS_VALUE_OFFSET            0x82 - DESCRIPTOR_HEADER_SIZE
#define TZ1_MINUTES_VALUE_OFFSET        0x83 - DESCRIPTOR_HEADER_SIZE
#define TZ1_HOURS_VALUE_OFFSET          0x84 - DESCRIPTOR_HEADER_SIZE
#define TZ1_DAYS_VALUE_OFFSET           0x85 - DESCRIPTOR_HEADER_SIZE
#define TZ1_MONTHS_VALUE_OFFSET         0x86 - DESCRIPTOR_HEADER_SIZE
#define TZ1_YEARS_VALUE_OFFSET          0x87 - DESCRIPTOR_HEADER_SIZE
#define TZ2_MINUTES_VALUE_OFFSET        0x88 - DESCRIPTOR_HEADER_SIZE
#define TZ2_HOURS_VALUE_OFFSET          0x89 - DESCRIPTOR_HEADER_SIZE
#define TZ2_DAYS_VALUE_OFFSET           0x8A - DESCRIPTOR_HEADER_SIZE
#define TZ2_MONTHS_VALUE_OFFSET         0x8B - DESCRIPTOR_HEADER_SIZE
#define TZ2_YEARS_VALUE_OFFSET          0x8C - DESCRIPTOR_HEADER_SIZE
#define ACTIVITY_STATUS_FLAG_OFFSET     0x8D - DESCRIPTOR_HEADER_SIZE
#define CHRONO_SETTINGS_OFFSET          0x8E - DESCRIPTOR_HEADER_SIZE
#define TIMER_HOUR_OFFSET               0x8F - DESCRIPTOR_HEADER_SIZE
#define TIMER_MINUTE_OFFSET             0x90 - DESCRIPTOR_HEADER_SIZE
#define TIMER_SECONDS_OFFSET            0x91 - DESCRIPTOR_HEADER_SIZE
#define TIMER_ACTION_AT_END_OFFSET      0x92 - DESCRIPTOR_HEADER_SIZE
#define INTERVAL_TIMER_1_HOURS_OFFSET   0x93 - DESCRIPTOR_HEADER_SIZE
#define INTERVAL_TIMER_1_MINS_OFFSET    0x94 - DESCRIPTOR_HEADER_SIZE
#define INTERVAL_TIMER_1_SECS_OFFSET    0x95 - DESCRIPTOR_HEADER_SIZE
#define INTERVAL_TIMER_2_HOURS_OFFSET   0x96 - DESCRIPTOR_HEADER_SIZE
#define INTERVAL_TIMER_2_MINS_OFFSET    0x97 - DESCRIPTOR_HEADER_SIZE
#define INTERVAL_TIMER_2_SECS_OFFSET    0x98 - DESCRIPTOR_HEADER_SIZE
#define INT_TIMER_ACTION_AT_END_OFFSET  0x99 - DESCRIPTOR_HEADER_SIZE
#define ALARM1_HOUR_OOFSET              0x9A - DESCRIPTOR_HEADER_SIZE
#define ALARM1_MINUTE_OFFSET            0x9B - DESCRIPTOR_HEADER_SIZE
#define ALARM1_FREQUENCY_OFFSET         0x9C - DESCRIPTOR_HEADER_SIZE
#define ALARM1_STATUS_OFFSET            0x9D - DESCRIPTOR_HEADER_SIZE
#define ALARM2_HOUR_OOFSET              0x9E - DESCRIPTOR_HEADER_SIZE
#define ALARM2_MINUTE_OFFSET            0x9F - DESCRIPTOR_HEADER_SIZE
#define ALARM2_FREQUENCY_OFFSET         0xA0 - DESCRIPTOR_HEADER_SIZE
#define ALARM2_STATUS_OFFSET            0xA1 - DESCRIPTOR_HEADER_SIZE
#define ALARM3_HOUR_OOFSET              0xA2 - DESCRIPTOR_HEADER_SIZE
#define ALARM3_MINUTE_OFFSET            0xA3 - DESCRIPTOR_HEADER_SIZE
#define ALARM3_FREQUENCY_OFFSET         0xA4 - DESCRIPTOR_HEADER_SIZE
#define ALARM3_STATUS_OFFSET            0xA5 - DESCRIPTOR_HEADER_SIZE
#define USER_AGE_OFFSET                 0xA6 - DESCRIPTOR_HEADER_SIZE
#define USER_WEIGHT_OFFSET              0xA7 - DESCRIPTOR_HEADER_SIZE
#define USER_HEIGHT_OFFSET              0xA9 - DESCRIPTOR_HEADER_SIZE
#define DAILY_STEP_GOAL_OFFSET          0xAA - DESCRIPTOR_HEADER_SIZE
#define DAILY_DISTANCE_GOAL_OFFSET      0xAD - DESCRIPTOR_HEADER_SIZE
#define DAILY_CALORIE_GOAL_OFFSET       0xAF - DESCRIPTOR_HEADER_SIZE
#define DATA_GENERAL2_SETTINGS_OFFSET   0xB2 - DESCRIPTOR_HEADER_SIZE
#define DATA_GENERAL3_SETTINGS_OFFSET   0xB3 - DESCRIPTOR_HEADER_SIZE
#define WATCH_BOND_FLAGS_OFFSET         0xB4 - DESCRIPTOR_HEADER_SIZE
#define SETTINGS_CHECKSUM_OFFSET        0xB5 - DESCRIPTOR_HEADER_SIZE

#define WORKOUT_TYPE_OFFSET             SETTINGS_DATA_SIZE + APPTS_M053_FILE_DATA_SIZE
#define WORKOUTS_NUMBER_OFFSET          WORKOUT_TYPE_OFFSET + 1
#define CHRONO_RECORDS_SIZE             WORKOUT_TYPE_OFFSET + 2
#define CHRONOS_OFFSET                  WORKOUT_TYPE_OFFSET + 4
#define CHRONOS_CHECKSUM_OFFSET         WORKOUT_TYPE_OFFSET + CHRONO_DATA_SIZE - 4

#define ACTIVITIES_NUMBER_OFFSET        WORKOUT_TYPE_OFFSET + CHRONO_DATA_SIZE
#define ACTIVITIES_OFFSET               ACTIVITIES_NUMBER_OFFSET + 1
#define ACTIVITIES_CHECKSUM_OFFSET      ACTIVITIES_NUMBER_OFFSET + ACTIVITY_DATA_SIZE - 4

#define INTERVALS_NUMBER_OFFSET         ACTIVITIES_NUMBER_OFFSET + ACTIVITY_DATA_SIZE
#define INTERVALS_RECORDS_SIZE_OFFSET   INTERVALS_NUMBER_OFFSET + 1
#define INTERVALS_OFFSET                INTERVALS_NUMBER_OFFSET + 2
#define INTERVALS_CHECKSUM_OFFSET       INTERVALS_NUMBER_OFFSET + INTERVAL_TIMER_DATA_SIZE - 4

#define kSyncModeIsShownWatchSettingKey @"kSyncModeIsShownWatchSettingKey"
#define kNFCStatusWatchSettingKey @"kNFCStatusWatchSettingKey"

@implementation TDM053TimeZone
@synthesize minute = _minute;
@synthesize hour = _hour;
@synthesize day = _day;
@synthesize month = _month;
@synthesize year = _year;
@end

@implementation TDM053Interval
@synthesize seconds = _seconds;
@synthesize minutes = _minutes;
@synthesize hours = _hours;
@end

@implementation  TDM053WorkoutHeader

@synthesize mMinute = _mMinute;
@synthesize mHour = _mHour;
@synthesize mYear = _mYear;
@synthesize mMonth = _mMonth;
@synthesize mDay = _mDay;
@synthesize mNumberOfLaps = _mNumberOfLaps;
@synthesize mActivityDataSavedFlag = _mActivityDataSavedFlag;
@synthesize mTotalTimeHour = _mTotalTimeHour;
@synthesize mTotalTimeMinute = _mTotalTimeMinute;
@synthesize mTotalTimeSecond = _mTotalTimeSecond;
@synthesize mTotalTimeHundredth = _mTotalTimeHundredth;
@synthesize mReserved1 = _mReserved1;
@synthesize mTotalSteps = _mTotalSteps;
@synthesize mTotalDistance = _mTotalDistance;
@synthesize mTotalCalories = _mTotalCalories;
@synthesize mReserved2 = _mReserved2;
@end

@implementation  TDM053Lap

@synthesize mHours = _mHours;
@synthesize mMinutes = _mMinutes;
@synthesize mSeconds = _mSeconds;
@synthesize mHundredths = _mHundredths;
@synthesize mTotalSteps = _mTotalSteps;
@synthesize mTotalDistance = _mTotalDistance;
@synthesize mTotalCalories = _mTotalCalories;

- (long) getDurationInMS
{
    long result = 0;
    
    result = _mHours * 3600 * 1000;
    result += _mMinutes * 60 * 1000;
    result += _mSeconds * 1000;
    result += _mHundredths * 10;
    
    return result;
}

@end

@implementation  TDM053IntervalRecord

@synthesize mMinute = _mMinute;
@synthesize mHour = _mHour;
@synthesize mDay = _mDay;
@synthesize mMonth = _mMonth;
@synthesize mYear = _mYear;
@synthesize mRepetitions = _mRepetitions;
@synthesize mRepetitionsFlags = _mRepetitionsFlags;
@synthesize mTotalSteps = _mTotalSteps;
@synthesize mTotalDistance = _mTotalDistance;
@synthesize mTotalCalories = _mTotalCalories;
@synthesize mTotalHours = _mTotalHours;
@synthesize mTotalMinutes = _mTotalMinutes;
@synthesize mTotalSeconds = _mTotalSeconds;

- (NSDate *) getWorkoutDate
{
    NSDate* result = nil;
    
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setYear: 2000 + _mYear]; //0 corresponds to year 2000
    [comps setMonth: _mMonth];
    [comps setDay: _mDay];
    [comps setHour: _mHour];
    [comps setMinute: _mMinute];
    [comps setSecond: 0];
    
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier: NSCalendarIdentifierGregorian];
    result = [gregorian dateFromComponents: comps];
    
    return result;
}

- (long) getDurationInMS
{
    long result = 0;
    
    result = _mTotalHours * 3600 * 1000;
    result += _mTotalMinutes * 60 * 1000;
    result += _mTotalSeconds * 1000;
    
    return result;
}

@end

@implementation  TDM053WorkoutParser

@synthesize mHeader = _mHeader;
@synthesize mLaps = _mLaps;

- (NSDate *) getWorkoutDate
{
    NSDate* result = nil;
    
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setYear: 2000 + _mHeader.mYear]; //0 corresponds to year 2000
    [comps setMonth: _mHeader.mMonth];
    [comps setDay: _mHeader.mDay];
    [comps setHour: _mHeader.mHour];
    [comps setMinute: _mHeader.mMinute];
    [comps setSecond: 0];
    
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier: NSCalendarIdentifierGregorian];
    result = [gregorian dateFromComponents: comps];
    
    return result;
}
@end

@interface TDM053WatchData()
{
    Byte dataFreshnessFlags;
    Byte generalSettingsFlag;
    Byte generalSettings2Flag;
    Byte generalSettings3Flag;
    Byte secondsValue;
    NSMutableArray  *  mTimeZones;
    Byte activityStatusFlag;
    Byte chronoSettingsFlags;
    Byte timer_seconds;
    Byte timer_minutes;
    Byte timer_hours;
    Byte timer_actionAtEnd;
    NSMutableArray  *  mIntervals;
    Byte int_timer_actionAtEnd;
    NSMutableArray  *  mAlarms;
    Byte userAge;
    short userWeight;
    Byte  userHeight;
    int   dailyStepGoal;
    short dailyDistanceGoal;
    int   dailyCalorieGoal;
    
    Byte watchBondFlags;
    int  settingsChecksum;
    
    Byte  workoutsType;
    Byte  workoutsNumber;
    short chronoRecordsSize;
    NSMutableArray * mWorkouts;
    int  chronosChecksum;
    
    Byte activitiesNumber;
    NSMutableArray * mActivities;
    int  activitiesChecksum;
    
    Byte intervalsNumber;
    Byte intervalsRecSize;
    NSMutableArray * mIntervalTimers;
    int  intevalsChecksum;
}
@end

@implementation TDM053WatchData

- (id) init
{
    if (self = [super init])
    {
        mTimeZones = [[NSMutableArray alloc] init];
        for (int i = 0; i < 2; i++)
        {
            TDM053TimeZone * newInt = [[TDM053TimeZone alloc] init];
            [mTimeZones addObject: newInt];
        }
        
        mIntervals = [[NSMutableArray alloc] init];
        for (int i = 0; i < 2; i++)
        {
            TDM053Interval * newInt = [[TDM053Interval alloc] init];
            [mIntervals addObject: newInt];
        }
        
        mAlarms = [[NSMutableArray alloc] init];
        for (int i = 0; i < 3; i++)
        {
            TDDatacastAlarm * newAlarm = [[TDDatacastAlarm alloc] init];
            [mAlarms addObject: newAlarm];
        }
        
        mWorkouts = [[NSMutableArray alloc] init];
        
        mActivities = [[NSMutableArray alloc] init];
        
        mIntervalTimers = [[NSMutableArray alloc] init];
        
        //read from settings
        [self populateObjectWithSettingsOnPhone];
    }
    
    return self;
}

- (id) init: (NSData *) inData
{
    if (self = [self init])
    {        
        [self setWatchData: inData];
    }
    
    return self;
}

- (int) setWatchData: (NSData *) inDataObject
{
    int error = noErr;
    Byte inData[inDataObject.length];
    [inDataObject getBytes: inData];
        
    dataFreshnessFlags = inData[DATA_FRESHNESS_OFFSET];
    generalSettingsFlag = inData[DATA_GENERAL_SETTINGS_OFFSET];
    secondsValue = inData[SECONDS_VALUE_OFFSET];
    
    ((TDM053TimeZone *)[mTimeZones objectAtIndex: 0]).minute = inData[TZ1_MINUTES_VALUE_OFFSET];
    ((TDM053TimeZone *)[mTimeZones objectAtIndex: 0]).hour = inData[TZ1_HOURS_VALUE_OFFSET];
    ((TDM053TimeZone *)[mTimeZones objectAtIndex: 0]).day = inData[TZ1_DAYS_VALUE_OFFSET];
    ((TDM053TimeZone *)[mTimeZones objectAtIndex: 0]).month = inData[TZ1_MONTHS_VALUE_OFFSET];
    ((TDM053TimeZone *)[mTimeZones objectAtIndex: 0]).year = inData[TZ1_YEARS_VALUE_OFFSET];
    
    ((TDM053TimeZone *)[mTimeZones objectAtIndex: 1]).minute = inData[TZ2_MINUTES_VALUE_OFFSET];
    ((TDM053TimeZone *)[mTimeZones objectAtIndex: 1]).hour = inData[TZ2_HOURS_VALUE_OFFSET];
    ((TDM053TimeZone *)[mTimeZones objectAtIndex: 1]).day = inData[TZ2_DAYS_VALUE_OFFSET];
    ((TDM053TimeZone *)[mTimeZones objectAtIndex: 1]).month = inData[TZ2_MONTHS_VALUE_OFFSET];
    ((TDM053TimeZone *)[mTimeZones objectAtIndex: 1]).year = inData[TZ2_YEARS_VALUE_OFFSET];
    
    activityStatusFlag = inData[ACTIVITY_STATUS_FLAG_OFFSET];
    chronoSettingsFlags = inData[CHRONO_SETTINGS_OFFSET];
    
    timer_hours = inData[TIMER_HOUR_OFFSET];
    timer_minutes = inData[TIMER_MINUTE_OFFSET];
    timer_seconds = inData[TIMER_SECONDS_OFFSET];
    timer_actionAtEnd = inData[TIMER_ACTION_AT_END_OFFSET];
    
    ((TDM053Interval *)[mIntervals objectAtIndex: 0]).seconds = inData[INTERVAL_TIMER_1_SECS_OFFSET];
    ((TDM053Interval *)[mIntervals objectAtIndex: 0]).minutes = inData[INTERVAL_TIMER_1_MINS_OFFSET];
    ((TDM053Interval *)[mIntervals objectAtIndex: 0]).hours = inData[INTERVAL_TIMER_1_HOURS_OFFSET];
    
    ((TDM053Interval *)[mIntervals objectAtIndex: 1]).seconds = inData[INTERVAL_TIMER_2_SECS_OFFSET];
    ((TDM053Interval *)[mIntervals objectAtIndex: 1]).minutes = inData[INTERVAL_TIMER_2_MINS_OFFSET];
    ((TDM053Interval *)[mIntervals objectAtIndex: 1]).hours = inData[INTERVAL_TIMER_2_HOURS_OFFSET];
    
     int_timer_actionAtEnd = inData[INT_TIMER_ACTION_AT_END_OFFSET];
    
    ((TDDatacastAlarm *)[mAlarms objectAtIndex: 0]).enable = inData[ALARM1_STATUS_OFFSET];
    ((TDDatacastAlarm *)[mAlarms objectAtIndex: 1]).enable = inData[ALARM2_STATUS_OFFSET];
    ((TDDatacastAlarm *)[mAlarms objectAtIndex: 2]).enable = inData[ALARM3_STATUS_OFFSET];
    ((TDDatacastAlarm *)[mAlarms objectAtIndex: 0]).hour = inData[ALARM1_HOUR_OOFSET];
    ((TDDatacastAlarm *)[mAlarms objectAtIndex: 0]).minute = inData[ALARM1_MINUTE_OFFSET];
    ((TDDatacastAlarm *)[mAlarms objectAtIndex: 0]).repeatPattern = inData[ALARM1_FREQUENCY_OFFSET];
    ((TDDatacastAlarm *)[mAlarms objectAtIndex: 1]).hour = inData[ALARM2_HOUR_OOFSET];
    ((TDDatacastAlarm *)[mAlarms objectAtIndex: 1]).minute = inData[ALARM2_MINUTE_OFFSET];
    ((TDDatacastAlarm *)[mAlarms objectAtIndex: 1]).repeatPattern = inData[ALARM2_FREQUENCY_OFFSET];
    ((TDDatacastAlarm *)[mAlarms objectAtIndex: 2]).hour = inData[ALARM3_HOUR_OOFSET];
    ((TDDatacastAlarm *)[mAlarms objectAtIndex: 2]).minute = inData[ALARM3_MINUTE_OFFSET];
    ((TDDatacastAlarm *)[mAlarms objectAtIndex: 2]).repeatPattern = inData[ALARM3_FREQUENCY_OFFSET];
    
    userAge = inData[USER_AGE_OFFSET];
    
    userWeight = *((short *)&inData[USER_WEIGHT_OFFSET]);
    
    userHeight = inData[USER_HEIGHT_OFFSET];
    
    Byte ptrBytesInt[4];
    
    memset(ptrBytesInt, 0, 4);
    [inDataObject getBytes: ptrBytesInt range: NSMakeRange(DAILY_STEP_GOAL_OFFSET, 3)];
    dailyStepGoal = [iDevicesUtil byteArrayToInt: ptrBytesInt];
    
    dailyDistanceGoal = *((short *)&inData[DAILY_DISTANCE_GOAL_OFFSET]);
    
    memset(ptrBytesInt, 0, 4);
    [inDataObject getBytes: ptrBytesInt range: NSMakeRange(DAILY_CALORIE_GOAL_OFFSET, 3)];
    dailyCalorieGoal = [iDevicesUtil byteArrayToInt: ptrBytesInt];
    
    generalSettings2Flag = inData[DATA_GENERAL2_SETTINGS_OFFSET];
    generalSettings3Flag = inData[DATA_GENERAL3_SETTINGS_OFFSET];
    
    watchBondFlags = inData[WATCH_BOND_FLAGS_OFFSET];
    
    memset(ptrBytesInt, 0, 4);
    [inDataObject getBytes: ptrBytesInt range: NSMakeRange(SETTINGS_CHECKSUM_OFFSET, 4)];
    settingsChecksum = [iDevicesUtil byteArrayToInt: ptrBytesInt];
    
    //now reads chronos;
    workoutsType = inData[WORKOUT_TYPE_OFFSET];
    workoutsNumber = inData[WORKOUTS_NUMBER_OFFSET];
    chronoRecordsSize = inData[CHRONO_RECORDS_SIZE];
    
    // Interval Timers or Laps
    int offsetFromStart = CHRONOS_OFFSET;
    for ( int i = 0; i < workoutsNumber; i++ )
    {
        TDM053WorkoutParser * newWorkout = [[TDM053WorkoutParser alloc] init];
        
        TDM053WorkoutHeader * newHeader = [[TDM053WorkoutHeader alloc] init];
        newHeader.mMinute = inData[offsetFromStart];
        offsetFromStart++;
        newHeader.mHour = inData[offsetFromStart];
        offsetFromStart++;
        newHeader.mDay = inData[offsetFromStart];
        offsetFromStart++;
        newHeader.mMonth = inData[offsetFromStart];
        offsetFromStart++;
        newHeader.mYear = inData[offsetFromStart];
        offsetFromStart++;
        newHeader.mNumberOfLaps = inData[offsetFromStart];
        offsetFromStart++;
        newHeader.mActivityDataSavedFlag = inData[offsetFromStart];
        offsetFromStart++;
        newHeader.mTotalTimeHour = inData[offsetFromStart];
        offsetFromStart++;
        newHeader.mTotalTimeMinute = inData[offsetFromStart];
        offsetFromStart++;
        newHeader.mTotalTimeSecond = inData[offsetFromStart];
        offsetFromStart++;
        newHeader.mTotalTimeHundredth = inData[offsetFromStart];
        offsetFromStart++;
        newHeader.mReserved1 = inData[offsetFromStart];
        offsetFromStart++;
        
        memset(ptrBytesInt, 0, 4);
        [inDataObject getBytes: ptrBytesInt range: NSMakeRange(offsetFromStart, 3)];
        newHeader.mTotalSteps = [iDevicesUtil byteArrayToInt: ptrBytesInt];
        offsetFromStart += 3;
        
        newHeader.mTotalDistance = *((short *)&inData[offsetFromStart]);
        offsetFromStart += 2;
        
        memset(ptrBytesInt, 0, 4);
        [inDataObject getBytes: ptrBytesInt range: NSMakeRange(offsetFromStart, 3)];
        newHeader.mTotalCalories = [iDevicesUtil byteArrayToInt: ptrBytesInt];
        offsetFromStart += 3;
        
        memset(ptrBytesInt, 0, 4);
        [inDataObject getBytes: ptrBytesInt range: NSMakeRange(offsetFromStart, 3)];
        newHeader.mReserved2 = [iDevicesUtil byteArrayToInt: ptrBytesInt];
        offsetFromStart += 4;
        
        newWorkout.mHeader = newHeader;
        
        newWorkout.mLaps = [[NSMutableArray alloc] init];
        for (int x = 0; x < newWorkout.mHeader.mNumberOfLaps; x++)
        {
            TDM053Lap * newLap = [[TDM053Lap alloc] init];
            
            newLap.mHours = inData[offsetFromStart];
            offsetFromStart++;
            newLap.mMinutes = inData[offsetFromStart];
            offsetFromStart++;
            newLap.mSeconds = inData[offsetFromStart];
            offsetFromStart++;
            newLap.mHundredths = inData[offsetFromStart];
            offsetFromStart++;
            
            memset(ptrBytesInt, 0, 4);
            [inDataObject getBytes: ptrBytesInt range: NSMakeRange(offsetFromStart, 3)];
            newLap.mTotalSteps = [iDevicesUtil byteArrayToInt: ptrBytesInt];
            offsetFromStart += 3;
            
            newLap.mTotalDistance = *((short *)&inData[offsetFromStart]);
            offsetFromStart += 2;
            
            memset(ptrBytesInt, 0, 4);
            [inDataObject getBytes: ptrBytesInt range: NSMakeRange(offsetFromStart, 3)];
            newLap.mTotalCalories = [iDevicesUtil byteArrayToInt: ptrBytesInt];
            offsetFromStart += 3;
            
            [newWorkout.mLaps addObject: newLap];
        }
        
        [mWorkouts addObject: newWorkout];
    }
    
    memset(ptrBytesInt, 0, 4);
    [inDataObject getBytes: ptrBytesInt range: NSMakeRange(CHRONOS_CHECKSUM_OFFSET, 4)];
    chronosChecksum = [iDevicesUtil byteArrayToInt: ptrBytesInt];
    
    //now reads activities:
    activitiesNumber = inData[ACTIVITIES_NUMBER_OFFSET];
    
    offsetFromStart = ACTIVITIES_OFFSET;
    for ( int i = 0; i < activitiesNumber; i++ )
    {
        TDActivityTrackerRecord * newActivity = [[TDActivityTrackerRecord alloc] init];
        
        newActivity.mDay = inData[offsetFromStart];
        offsetFromStart++;
        newActivity.mMonth = inData[offsetFromStart];
        offsetFromStart++;
        newActivity.mYear = inData[offsetFromStart];
        offsetFromStart++;
        newActivity.mActivityDataSavedFlag = inData[offsetFromStart];
        offsetFromStart++;
        
        memset(ptrBytesInt, 0, 4);
        [inDataObject getBytes: ptrBytesInt range: NSMakeRange(offsetFromStart, 3)];
        newActivity.mTotalSteps = [iDevicesUtil byteArrayToInt: ptrBytesInt];
        offsetFromStart += 3;
        
        newActivity.mTotalDistance = *((short *)&inData[offsetFromStart]);
        offsetFromStart += 2;
        
        memset(ptrBytesInt, 0, 4);
        [inDataObject getBytes: ptrBytesInt range: NSMakeRange(offsetFromStart, 3)];
        newActivity.mTotalCalories = [iDevicesUtil byteArrayToInt: ptrBytesInt];
        offsetFromStart += 3;
        
        [mActivities addObject: newActivity];
    }
    
    memset(ptrBytesInt, 0, 4);
    [inDataObject getBytes: ptrBytesInt range: NSMakeRange(ACTIVITIES_CHECKSUM_OFFSET, 4)];
    activitiesChecksum = [iDevicesUtil byteArrayToInt: ptrBytesInt];
    
    //now reads intervals:
    intervalsNumber = inData[INTERVALS_NUMBER_OFFSET];
    intervalsRecSize = inData[INTERVALS_RECORDS_SIZE_OFFSET];
    offsetFromStart = INTERVALS_OFFSET;
    for ( int i = 0; i < intervalsNumber; i++ )
    {
        TDM053IntervalRecord * newInterval = [[TDM053IntervalRecord alloc] init];
        
        newInterval.mMinute = inData[offsetFromStart];
        offsetFromStart++;
        newInterval.mHour = inData[offsetFromStart];
        offsetFromStart++;
        newInterval.mDay = inData[offsetFromStart];
        offsetFromStart++;
        newInterval.mMonth = inData[offsetFromStart];
        offsetFromStart++;
        newInterval.mYear = inData[offsetFromStart];
        offsetFromStart++;
        newInterval.mRepetitions = inData[offsetFromStart];
        offsetFromStart++;
        newInterval.mRepetitionsFlags = inData[offsetFromStart];
        offsetFromStart++;
        
        memset(ptrBytesInt, 0, 4);
        [inDataObject getBytes: ptrBytesInt range: NSMakeRange(offsetFromStart, 3)];
        newInterval.mTotalSteps = [iDevicesUtil byteArrayToInt: ptrBytesInt];
        offsetFromStart += 3;
        
        newInterval.mTotalDistance = *((short *)&inData[offsetFromStart]);
        offsetFromStart += 2;
        
        memset(ptrBytesInt, 0, 4);
        [inDataObject getBytes: ptrBytesInt range: NSMakeRange(offsetFromStart, 3)];
        newInterval.mTotalCalories = [iDevicesUtil byteArrayToInt: ptrBytesInt];
        offsetFromStart += 3;
        
        newInterval.mTotalHours = inData[offsetFromStart];
        offsetFromStart++;
        newInterval.mTotalMinutes = inData[offsetFromStart];
        offsetFromStart++;
        newInterval.mTotalSeconds = inData[offsetFromStart];
        offsetFromStart++;
        
        [mIntervalTimers addObject: newInterval];
    }
    
    memset(ptrBytesInt, 0, 4);
    [inDataObject getBytes: ptrBytesInt range: NSMakeRange(INTERVALS_CHECKSUM_OFFSET, 4)];
    intevalsChecksum = [iDevicesUtil byteArrayToInt: ptrBytesInt];
    
    
    return error;
}

- (void) recordActivityData
{
    for (TDActivityTrackerRecord * newActivity in mActivities)
    {
        NSDate * newDate = [newActivity getActivityDate];
        NSTimeInterval since1970 = [newDate timeIntervalSince1970];
        //first, see if there are activities in the database on the same date
        NSString * deleteActivityExpression = [NSString stringWithFormat:@"DELETE FROM ActivityData WHERE WorkoutID IS NULL AND LapID IS NULL AND ActivityDate = %f;", since1970];
        TimexDatalink::IDBQuery * activityDeleteQuery = [[TimexWatchDB sharedInstance] createQuery : deleteActivityExpression];
        if (activityDeleteQuery)
            delete activityDeleteQuery;
        
        //now that this is done, we can continue adding this data into the DB
        NSString * expressionNewActivity = [NSString stringWithFormat: @"INSERT INTO ActivityData ('ActivityDate', 'ActivitySteps', 'ActivityDistance', 'ActivityCalories', 'WorkoutID', 'LapID') VALUES (%f, %ld,'%ld', %ld, NULL, NULL);", since1970, (long)[newActivity mTotalSteps], (long)[newActivity mTotalDistance], (long)[newActivity mTotalCalories]];
        
        TimexDatalink::IDBQuery * queryNewActivity = [[TimexWatchDB sharedInstance] createQuery : expressionNewActivity];
        if (queryNewActivity)
        {
            delete queryNewActivity;
        }
    }
}

- (NSArray *) serializeToDB
{
    NSMutableArray * newWorkouts = nil;
    
    if ([iDevicesUtil checkForActiveProfilePresence] == FALSE)
    {
        //this will eliminate the bug when we were writing another profile for the watch when tehre already was one there in the DB (inactive)
        [[TDWatchProfile sharedInstance] checkForInactiveProfileMatchingSelectedWatchStyle];
    }
    
    for (int i = 0; i < [mWorkouts count]; i++)
    {
        TDM053WorkoutParser * workout = [mWorkouts objectAtIndex: i];
        TDWorkoutDataActivityTracker * newData = [[TDWorkoutDataActivityTracker alloc] init];
        
        newData.totalCalories = workout.mHeader.mTotalCalories;
        newData.totalSteps = workout.mHeader.mTotalSteps;
        newData.totalDistance = workout.mHeader.mTotalDistance;
        
        NSDate * newDate = [workout getWorkoutDate];
        
        [newData setWorkoutDate: newDate];
        [newData setWorkoutType: TDWorkoutData_WorkoutTypeChrono];
        
        [newData setNumberOfScheduledRepeats: 0]; //set just in case
        [newData setRecordedNumberOfLaps: [workout.mLaps count]];
            
        NSInteger numberOfRecordedLaps = [workout.mLaps count];
        double totalDurationMS = 0.0;
        
        for (int j = 0; j < numberOfRecordedLaps; j++)
        {
            TDM053Lap * chronoLap = [workout.mLaps objectAtIndex: j];
            long splitDataMS = [chronoLap getDurationInMS];
            long lapTimeMS = splitDataMS - totalDurationMS;
            totalDurationMS = splitDataMS;
            
            NSNumber * lapTime =  [[NSNumber alloc] initWithDouble: lapTimeMS];
            
            [newData addLapData: lapTime withType: programWatch_PropertyClass_IntervalTimer_LabelRun withSteps: chronoLap.mTotalSteps andDistance: chronoLap.mTotalDistance andCalories: chronoLap.mTotalCalories];
        }
        
        [newData setWorkoutDuration: [NSNumber numberWithDouble: totalDurationMS]];
  
        
        if ([[[TDWatchProfile sharedInstance] workoutManager] getWorkoutOnDate: newDate] == nil)
        {
            [[[TDWatchProfile sharedInstance] workoutManager] addWorkout: newData resortWorkouts: FALSE]; //will be resorted at the end, for speed
            
            if (newWorkouts == nil)
            {
                newWorkouts = [[NSMutableArray alloc] init];
            }
            [newWorkouts addObject: newData];
        }
    }
    
    for (int i = 0; i < [mIntervalTimers count]; i++)
    {
        TDM053IntervalRecord * workoutInterval = [mIntervalTimers objectAtIndex: i];
        TDWorkoutDataActivityTracker * newData = [[TDWorkoutDataActivityTracker alloc] init];
        
        newData.totalCalories = workoutInterval.mTotalCalories;
        newData.totalSteps = workoutInterval.mTotalSteps;
        newData.totalDistance = workoutInterval.mTotalDistance;
        
        NSDate * newDate = [workoutInterval getWorkoutDate];
        
        [newData setWorkoutDate: newDate];
        [newData setWorkoutType: TDWorkoutData_WorkoutTypeTimer];
        
        if ([self doesWorkoutContain100orMoreRepeats: workoutInterval])
        {
            [newData setNumberOfScheduledRepeats: M053_INTERVAL_TIMER_WORKOUTS_MORE_THEN_99_REPEATS];
        }
        else
        {
            [newData setNumberOfScheduledRepeats: workoutInterval.mRepetitions];
        }
        [newData setRecordedNumberOfLaps: 0]; //set just in case
        
        double totalDurationMS = [workoutInterval getDurationInMS];
        [newData setWorkoutDuration: [NSNumber numberWithDouble: totalDurationMS]];
        
        if ([[[TDWatchProfile sharedInstance] workoutManager] getWorkoutOnDate: newDate] == nil)
        {
            [[[TDWatchProfile sharedInstance] workoutManager] addWorkout: newData resortWorkouts: FALSE]; //will be resorted at the end, for speed
            
            if (newWorkouts == nil)
            {
                newWorkouts = [[NSMutableArray alloc] init];
            }
            [newWorkouts addObject: newData];
        }
    }
    
    [[[TDWatchProfile sharedInstance] workoutManager] resortWorkoutsByCurrentSortType];
    [[TDWatchProfile sharedInstance] commitChangesToDatabase];
    
    TDFlurryDataPacket * dictFlurry = [[TDFlurryDataPacket alloc] initWithValue: [NSNumber numberWithInteger: newWorkouts == nil ? 0 : [newWorkouts count]] forKey: @"Number_Read"];
    [iDevicesUtil logFlurryEvent: @"WORKOUTS_READ" withParameters:dictFlurry isTimedEvent:NO];
    
    return newWorkouts;
}

- (NSData *) currentTimeAndSetupSettingsToByteArray
{
    Byte raw[SETTINGS_DATA_SIZE];
    memset(raw, 0, SETTINGS_DATA_SIZE);
    
    dataFreshnessFlags = 0x33; //00100001b
    
    NSDate * now = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components: (NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond) fromDate: now];
    
    raw[SECONDS_VALUE_OFFSET] = [components second];
    
    raw[TZ1_MINUTES_VALUE_OFFSET] = [components minute];
    raw[TZ1_HOURS_VALUE_OFFSET] = [components hour];
    raw[TZ1_DAYS_VALUE_OFFSET] = [components day];
    raw[TZ1_MONTHS_VALUE_OFFSET] = [components month];
    raw[TZ1_YEARS_VALUE_OFFSET] = [components year] - 2000;
    
    raw[TZ2_MINUTES_VALUE_OFFSET] = [components minute];
    raw[TZ2_HOURS_VALUE_OFFSET] = [components hour];
    raw[TZ2_DAYS_VALUE_OFFSET] = [components day];
    raw[TZ2_MONTHS_VALUE_OFFSET] = [components month];
    raw[TZ2_YEARS_VALUE_OFFSET] = [components year] - 2000;
    
    raw[USER_AGE_OFFSET] = userAge;
    
    NSData * ptrDataShort1 = [iDevicesUtil shortToByteArray: CFSwapInt16(userWeight)];
    Byte ptrBytesShort1[2];
    [ptrDataShort1 getBytes: ptrBytesShort1];
    memcpy(&raw[USER_WEIGHT_OFFSET], ptrBytesShort1, 2);
    
    raw[USER_HEIGHT_OFFSET] = userHeight;
    
    ptrDataShort1 = [iDevicesUtil intToByteArray: CFSwapInt32(dailyStepGoal)];
    Byte ptrBytesInt[4];
    memset(ptrBytesInt, 0, 4);
    [ptrDataShort1 getBytes: ptrBytesInt];
    memcpy(&raw[DAILY_STEP_GOAL_OFFSET], ptrBytesInt, 3);
    
    ptrDataShort1 = [iDevicesUtil shortToByteArray: CFSwapInt16(dailyDistanceGoal)];
    [ptrDataShort1 getBytes: ptrBytesShort1];
    memcpy(&raw[DAILY_DISTANCE_GOAL_OFFSET], ptrBytesShort1, 2);
    
    ptrDataShort1 = [iDevicesUtil intToByteArray: CFSwapInt32(dailyCalorieGoal)];
    [ptrDataShort1 getBytes: ptrBytesInt];
    memcpy(&raw[DAILY_CALORIE_GOAL_OFFSET], ptrBytesInt, 3);
    
    raw[DATA_GENERAL2_SETTINGS_OFFSET] = generalSettings2Flag;
    raw[DATA_GENERAL3_SETTINGS_OFFSET] = generalSettings3Flag;
    
    raw[DATA_FRESHNESS_OFFSET] = dataFreshnessFlags;
    
    settingsChecksum = [iDevicesUtil calculateTimexM053Checksum: raw withLength: SETTINGS_DATA_SIZE - 4];
    NSData * ptrData = [iDevicesUtil intToByteArray: settingsChecksum];
    Byte ptrBytes[4];
    [ptrData getBytes: ptrBytes];
    memcpy(&raw[SETTINGS_CHECKSUM_OFFSET], ptrBytes, 4);
    
    NSData * dataContainer = [NSData dataWithBytes: raw length: SETTINGS_DATA_SIZE];
    
    return dataContainer;
}
- (NSData *) settingsAndApptsToByteArray: (TDDatacastApptsParser *) apptsParser
{
    Byte raw[SETTINGS_DATA_SIZE];
    memset(raw, 0, SETTINGS_DATA_SIZE);
    
    dataFreshnessFlags = 0xFF; //11111111b
    
    raw[DATA_FRESHNESS_OFFSET] = dataFreshnessFlags;
    raw[DATA_GENERAL_SETTINGS_OFFSET] = generalSettingsFlag;
    
    NSDate * now = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components: (NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond) fromDate: now];
    
    raw[SECONDS_VALUE_OFFSET] = [components second];
    
    raw[TZ1_MINUTES_VALUE_OFFSET] = [components minute];
    raw[TZ1_HOURS_VALUE_OFFSET] = [components hour];
    raw[TZ1_DAYS_VALUE_OFFSET] = [components day];
    raw[TZ1_MONTHS_VALUE_OFFSET] = [components month];
    raw[TZ1_YEARS_VALUE_OFFSET] = [components year] - 2000;
    
    NSString * key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM053_PropertyClass_TimeOfDay andIndex: programWatchM053_PropertyClass_TimeOfDay_AwayTimeFollowPhone];
    if ([[NSUserDefaults standardUserDefaults] integerForKey: key] == programWatch_PropertyClass_TimeOfDay_FollowPhoneTimeFollowTimeZone)
    {
        NSInteger tzOffset = 0;
        NSString * key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM053_PropertyClass_TimeOfDay andIndex: programWatchM053_PropertyClass_TimeOfDay_AwayTimeTimeZone];
        if ([[NSUserDefaults standardUserDefaults] objectForKey: key] != nil)
        {
            NSString * tzName = [[NSUserDefaults standardUserDefaults] objectForKey: key];
            NSTimeZone * currentZone = [NSTimeZone timeZoneWithName: tzName];
            if (currentZone)
            {
                NSTimeZone * phoneZone = [NSTimeZone systemTimeZone];
                NSInteger phoneZoneOffset = [phoneZone secondsFromGMT];
                tzOffset = [currentZone secondsFromGMT] - phoneZoneOffset;
                now = [NSDate dateWithTimeIntervalSinceNow: tzOffset];
                components = [calendar components: (NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond) fromDate: now];
            }
        }
        
        raw[TZ2_MINUTES_VALUE_OFFSET] = [components minute];
        raw[TZ2_HOURS_VALUE_OFFSET] = [components hour];
        raw[TZ2_DAYS_VALUE_OFFSET] = [components day];
        raw[TZ2_MONTHS_VALUE_OFFSET] = [components month];
        raw[TZ2_YEARS_VALUE_OFFSET] = [components year] - 2000;
    }
    else
    {
        raw[TZ2_MINUTES_VALUE_OFFSET] = [components minute];
        raw[TZ2_HOURS_VALUE_OFFSET] = [components hour];
        raw[TZ2_DAYS_VALUE_OFFSET] = [components day];
        raw[TZ2_MONTHS_VALUE_OFFSET] = [components month];
        raw[TZ2_YEARS_VALUE_OFFSET] = [components year] - 2000;
    }
    
    raw[ACTIVITY_STATUS_FLAG_OFFSET] = activityStatusFlag;
    raw[CHRONO_SETTINGS_OFFSET] = chronoSettingsFlags;
    
    raw[TIMER_HOUR_OFFSET] = timer_hours;
    raw[TIMER_MINUTE_OFFSET] = timer_minutes;
    raw[TIMER_SECONDS_OFFSET] = timer_seconds;
    raw[TIMER_ACTION_AT_END_OFFSET] = timer_actionAtEnd;
    
    raw[INTERVAL_TIMER_1_SECS_OFFSET] = ((TDM053Interval *)[mIntervals objectAtIndex: 0]).seconds;
    raw[INTERVAL_TIMER_1_MINS_OFFSET] = ((TDM053Interval *)[mIntervals objectAtIndex: 0]).minutes;
    raw[INTERVAL_TIMER_1_HOURS_OFFSET] = ((TDM053Interval *)[mIntervals objectAtIndex: 0]).hours;
    
    raw[INTERVAL_TIMER_2_SECS_OFFSET] = ((TDM053Interval *)[mIntervals objectAtIndex: 1]).seconds;
    raw[INTERVAL_TIMER_2_MINS_OFFSET] = ((TDM053Interval *)[mIntervals objectAtIndex: 1]).minutes;
    raw[INTERVAL_TIMER_2_HOURS_OFFSET] = ((TDM053Interval *)[mIntervals objectAtIndex: 1]).hours;
    
    raw[INT_TIMER_ACTION_AT_END_OFFSET] = int_timer_actionAtEnd;
    
    raw[ALARM1_STATUS_OFFSET] = ((TDDatacastAlarm *)[mAlarms objectAtIndex: 0]).enable;
    raw[ALARM2_STATUS_OFFSET] = ((TDDatacastAlarm *)[mAlarms objectAtIndex: 1]).enable;
    raw[ALARM3_STATUS_OFFSET] = ((TDDatacastAlarm *)[mAlarms objectAtIndex: 2]).enable;
    raw[ALARM1_HOUR_OOFSET] = ((TDDatacastAlarm *)[mAlarms objectAtIndex: 0]).hour;
    raw[ALARM1_MINUTE_OFFSET] = ((TDDatacastAlarm *)[mAlarms objectAtIndex: 0]).minute;
    raw[ALARM1_FREQUENCY_OFFSET] = ((TDDatacastAlarm *)[mAlarms objectAtIndex: 0]).repeatPattern;
    raw[ALARM2_HOUR_OOFSET] = ((TDDatacastAlarm *)[mAlarms objectAtIndex: 1]).hour;
    raw[ALARM2_MINUTE_OFFSET] = ((TDDatacastAlarm *)[mAlarms objectAtIndex: 1]).minute;
    raw[ALARM2_FREQUENCY_OFFSET] = ((TDDatacastAlarm *)[mAlarms objectAtIndex: 1]).repeatPattern;
    raw[ALARM3_HOUR_OOFSET] = ((TDDatacastAlarm *)[mAlarms objectAtIndex: 2]).hour;
    raw[ALARM3_MINUTE_OFFSET] = ((TDDatacastAlarm *)[mAlarms objectAtIndex: 2]).minute;
    raw[ALARM3_FREQUENCY_OFFSET] = ((TDDatacastAlarm *)[mAlarms objectAtIndex: 2]).repeatPattern;
    
    raw[USER_AGE_OFFSET] = userAge;
    
    NSData * ptrDataShort1 = [iDevicesUtil shortToByteArray: CFSwapInt16(userWeight)];
    Byte ptrBytesShort1[2];
    [ptrDataShort1 getBytes: ptrBytesShort1];
    memcpy(&raw[USER_WEIGHT_OFFSET], ptrBytesShort1, 2);
    
    raw[USER_HEIGHT_OFFSET] = userHeight;
    
    ptrDataShort1 = [iDevicesUtil intToByteArray: CFSwapInt32(dailyStepGoal)];
    Byte ptrBytesInt[4];
    memset(ptrBytesInt, 0, 4);
    [ptrDataShort1 getBytes: ptrBytesInt];
    memcpy(&raw[DAILY_STEP_GOAL_OFFSET], ptrBytesInt, 3);
    
    ptrDataShort1 = [iDevicesUtil shortToByteArray: CFSwapInt16(dailyDistanceGoal)];
    [ptrDataShort1 getBytes: ptrBytesShort1];
    memcpy(&raw[DAILY_DISTANCE_GOAL_OFFSET], ptrBytesShort1, 2);
    
    ptrDataShort1 = [iDevicesUtil intToByteArray: CFSwapInt32(dailyCalorieGoal)];
    [ptrDataShort1 getBytes: ptrBytesInt];
    memcpy(&raw[DAILY_CALORIE_GOAL_OFFSET], ptrBytesInt, 3);
    
    raw[DATA_GENERAL2_SETTINGS_OFFSET] = generalSettings2Flag;
    raw[DATA_GENERAL3_SETTINGS_OFFSET] = generalSettings3Flag;
    
    raw[WATCH_BOND_FLAGS_OFFSET] = watchBondFlags;
    settingsChecksum = [iDevicesUtil calculateTimexM053Checksum: raw withLength: SETTINGS_DATA_SIZE - 4];
    NSData * ptrData = [iDevicesUtil intToByteArray: settingsChecksum];
    Byte ptrBytes[4];
    [ptrData getBytes: ptrBytes];
    memcpy(&raw[SETTINGS_CHECKSUM_OFFSET], ptrBytes, 4);
    
    NSData * apptsData = [apptsParser toM053ByteArray];
    Byte rawAppts[APPTS_M053_FILE_DATA_SIZE];
    [apptsData getBytes: rawAppts];
    
    Byte total[SETTINGS_DATA_SIZE + APPTS_M053_FILE_DATA_SIZE];
    memcpy(&total[0], &raw[0], SETTINGS_DATA_SIZE);
    memcpy(&total[SETTINGS_DATA_SIZE], &rawAppts[0], APPTS_M053_FILE_DATA_SIZE);
    
    NSData * dataContainer = [NSData dataWithBytes: total length: SETTINGS_DATA_SIZE + APPTS_M053_FILE_DATA_SIZE];
    
    return dataContainer;
}

- (void) populateObjectWithSettingsOnPhone
{
    Byte bitField = 0;
    
    // General
    bitField = (Byte)([self GetBoolPropertyForClass: programWatchM053_PropertyClass_TimeOfDay andIndex: programWatchM053_PropertyClass_TimeOfDay_HomeTimeTimeFormat] ? 0x1 : 0);
    bitField |= (Byte)([self GetBoolPropertyForClass: programWatchM053_PropertyClass_TimeOfDay andIndex: programWatchM053_PropertyClass_TimeOfDay_HomeTimeDateFormat] ? 0x2 : 0);
    bitField |= (Byte)([self GetBoolPropertyForClass: programWatchM053_PropertyClass_TimeOfDay andIndex: programWatchM053_PropertyClass_TimeOfDay_AwayTimeTimeFormat] ? 0x4 : 0);
    bitField |= (Byte)([self GetBoolPropertyForClass: programWatchM053_PropertyClass_TimeOfDay andIndex: programWatchM053_PropertyClass_TimeOfDay_AwayTimeDateFormat] ? 0x8 : 0);
    bitField |= (Byte)([self GetBoolPropertyForClass: programWatchM053_PropertyClass_General andIndex: programWatchM053_PropertyClass_General_LightMode] ? 0x10 : 0);
    
    //Primary Time is hardcoded to "Zone 1", which is 0
    bitField |= 0;

    generalSettingsFlag = bitField;
    
    // General 2
//    bitField = 0;
    bitField = (Byte)([self GetBoolPropertyForClass: programWatchM053_PropertyClass_General andIndex: programWatchM053_PropertyClass_General_HourlyChime] == 1 ? 1 : 0);
    bitField |= (Byte)([self GetBoolPropertyForClass: programWatchM053_PropertyClass_General andIndex: programWatchM053_PropertyClass_General_ButtonBeep] ? 0x2 : 0);
    bitField |= (Byte)([self GetBoolPropertyForClass: programWatchM053_PropertyClass_ActivityTracking andIndex: programWatchM053_PropertyClass_ActivityTracking_SensorStatus] ? 0x4 : 0);
    generalSettings2Flag = bitField;
    

    // General 3
//    bitField = 0;
    BOOL flag = [[NSUserDefaults standardUserDefaults] boolForKey: kSyncModeIsShownWatchSettingKey];
    bitField = (Byte)(flag ? 1 : 0);
    flag = [[NSUserDefaults standardUserDefaults] boolForKey: kNFCStatusWatchSettingKey];
    bitField |= (Byte)(flag ? 0x2 : 0);
    bitField |= (Byte)([self GetBoolPropertyForClass: programWatchM053_PropertyClass_General andIndex: programWatchM053_PropertyClass_General_UnitOfMeasure] ? 0x4 : 0);
    bitField |= (Byte)([self GetBoolPropertyForClass: programWatchM053_PropertyClass_UserInfo andIndex: programWatchM053_PropertyClass_UserInfo_Gender] ? 0x8 : 0);
    
    programWatchM053_PropertyClass_Activity_SensorSensitivityEnum currentSensitivity = [iDevicesUtil getM053CurrentSensorSensitivity];
    if (currentSensitivity == programWatchM053_PropertyClass_Activity_SensorSensitivityLow)
        bitField |= (Byte)0;
    else if (currentSensitivity == programWatchM053_PropertyClass_Activity_SensorSensitivityMedium)
        bitField |= (Byte)0x10;
    else if (currentSensitivity == programWatchM053_PropertyClass_Activity_SensorSensitivityHigh)
        bitField |= (Byte)0x20;
    
    BOOL statusSteps, statusDistance, statusCalories;
    statusSteps = [iDevicesUtil areStepsEnabled];
    statusDistance = [iDevicesUtil isDistanceEnabled];
    statusCalories = [iDevicesUtil areCaloriesEnabled];
    if (!statusSteps && !statusDistance && !statusCalories)
        bitField |= (Byte)0;
    else if (statusSteps && !statusDistance && !statusCalories)
        bitField |= (Byte)0x40;
    else if (!statusSteps && statusDistance && !statusCalories)
        bitField |= (Byte)0x80;
    else if (!statusSteps && !statusDistance && statusCalories)
        bitField |= (Byte)0xC0;
    
    generalSettings3Flag = bitField;
    
    // Alarms
    ((TDDatacastAlarm *)[mAlarms objectAtIndex: 0]).enable = (Byte)([self GetIntPropertyForClass: programWatchM053_PropertyClass_Alarm andIndex: programWatchM053_PropertyClass_Alarm_A1_Status] ? 1 : 0);
    ((TDDatacastAlarm *)[mAlarms objectAtIndex: 1]).enable = (Byte)([self GetIntPropertyForClass: programWatchM053_PropertyClass_Alarm andIndex: programWatchM053_PropertyClass_Alarm_A2_Status] ? 1 : 0);
    ((TDDatacastAlarm *)[mAlarms objectAtIndex: 2]).enable = (Byte)([self GetIntPropertyForClass: programWatchM053_PropertyClass_Alarm andIndex: programWatchM053_PropertyClass_Alarm_A3_Status] ? 1 : 0);
    
    ((TDDatacastAlarm *)[mAlarms objectAtIndex: 0]).repeatPattern = [self GetIntPropertyForClass: programWatchM053_PropertyClass_Alarm andIndex: programWatchM053_PropertyClass_Alarm_A1_Frequency];
    ((TDDatacastAlarm *)[mAlarms objectAtIndex: 1]).repeatPattern = [self GetIntPropertyForClass: programWatchM053_PropertyClass_Alarm andIndex: programWatchM053_PropertyClass_Alarm_A2_Frequency];
    ((TDDatacastAlarm *)[mAlarms objectAtIndex: 2]).repeatPattern = [self GetIntPropertyForClass: programWatchM053_PropertyClass_Alarm andIndex: programWatchM053_PropertyClass_Alarm_A3_Frequency];
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate * date1 = [self GetDatePropertyForClass: programWatchM053_PropertyClass_Alarm andIndex: programWatchM053_PropertyClass_Alarm_A1_Time];
    if (date1)
    {
        NSDateComponents *components = [calendar components:(NSCalendarUnitHour | NSCalendarUnitMinute) fromDate: date1];
        ((TDDatacastAlarm *)[mAlarms objectAtIndex: 0]).hour = [components hour];
        ((TDDatacastAlarm *)[mAlarms objectAtIndex: 0]).minute = [components minute];
    }
    
    NSDate * date2 = [self GetDatePropertyForClass: programWatchM053_PropertyClass_Alarm andIndex: programWatchM053_PropertyClass_Alarm_A2_Time];
    if (date2)
    {
        NSDateComponents *components = [calendar components:(NSCalendarUnitHour | NSCalendarUnitMinute) fromDate: date2];
        ((TDDatacastAlarm *)[mAlarms objectAtIndex: 1]).hour = [components hour];
        ((TDDatacastAlarm *)[mAlarms objectAtIndex: 1]).minute = [components minute];
    }
    
    NSDate * date3 = [self GetDatePropertyForClass: programWatchM053_PropertyClass_Alarm andIndex: programWatchM053_PropertyClass_Alarm_A3_Time];
    if (date3)
    {
        NSDateComponents *components = [calendar components:(NSCalendarUnitHour | NSCalendarUnitMinute) fromDate: date3];
        ((TDDatacastAlarm *)[mAlarms objectAtIndex: 2]).hour = [components hour];
        ((TDDatacastAlarm *)[mAlarms objectAtIndex: 2]).minute = [components minute];
    }
    
    //Interval Timers
    int_timer_actionAtEnd = [self GetIntPropertyForClass: programWatchM053_PropertyClass_IntervalTimer andIndex: programWatchM053_PropertyClass_IntervalTimer_ActionAtEnd];
    TDM053Interval * int1 = [self GetIntervalForClass: programWatchM053_PropertyClass_IntervalTimer andIndex: programWatchM053_PropertyClass_IntervalTimer_IT1_Time];
    if (int1)
    {
        [mIntervals replaceObjectAtIndex: 0 withObject: int1];
    }
    
    TDM053Interval * int2 = [self GetIntervalForClass: programWatchM053_PropertyClass_IntervalTimer andIndex: programWatchM053_PropertyClass_IntervalTimer_IT2_Time];
    if (int2)
    {
        [mIntervals replaceObjectAtIndex: 1 withObject: int2];
    }
    
    //Timer
    timer_actionAtEnd = [self GetIntPropertyForClass: programWatchM053_PropertyClass_Timer andIndex: programWatchM053_PropertyClass_Timer_ActionAtEnd];
    TDM053Interval * timerDate = [self GetIntervalForClass: programWatchM053_PropertyClass_Timer andIndex: programWatchM053_PropertyClass_Timer_Time];
    if (timerDate)
    {
        timer_hours = [timerDate hours];
        timer_minutes = [timerDate minutes];
        timer_seconds = [timerDate seconds];
    }
    
    //User Info
    userAge = [self GetIntPropertyForClass: programWatchM053_PropertyClass_UserInfo andIndex: programWatchM053_PropertyClass_UserInfo_Age];
    userHeight = [self GetIntPropertyForClass: programWatchM053_PropertyClass_UserInfo andIndex: programWatchM053_PropertyClass_UserInfo_Height];
    userWeight = [self GetIntPropertyForClass: programWatchM053_PropertyClass_UserInfo andIndex: programWatchM053_PropertyClass_UserInfo_Weight];
    
    dailyStepGoal = (int)[self GetIntAppSettingPropertyForClass: appSettingsM053_PropertyClass_Goals andIndex: appSettingsM053_PropertyClass_Goals_Steps];
    dailyDistanceGoal = [self GetIntAppSettingPropertyForClass: appSettingsM053_PropertyClass_Goals andIndex: appSettingsM053_PropertyClass_Goals_Distance];
    dailyCalorieGoal = (int)[self GetIntAppSettingPropertyForClass: appSettingsM053_PropertyClass_Goals andIndex: appSettingsM053_PropertyClass_Goals_Calories];
    
    //Chrono settings
//    bitField = 0;
    bitField = (Byte)([self GetIntAppSettingPropertyForClass: appSettingsM053_PropertyClass_Workouts andIndex: appSettingsM053_PropertyClass_Workouts_DisplayFormat] == appSettingsM053_PropertyClass_Workouts_SplitLap ? 1 : 0);
    bitField |= (Byte)([self GetIntAppSettingPropertyForClass: appSettingsM053_PropertyClass_Workouts andIndex: appSettingsM053_PropertyClass_Workouts_DeleteAfterSync] ? 0x2 : 0);
    chronoSettingsFlags = bitField;
}

- (void) serializeIntoSettings
{
    //General
    [self SetBoolProperty: [self getHourlyChime] forClass: programWatchM053_PropertyClass_General andIndex: programWatchM053_PropertyClass_General_HourlyChime];
    [self SetBoolProperty: [self getButtonBeep] forClass: programWatchM053_PropertyClass_General andIndex: programWatchM053_PropertyClass_General_ButtonBeep];
    [self SetBoolProperty: [self getLightActivationMode] forClass: programWatchM053_PropertyClass_General andIndex: programWatchM053_PropertyClass_General_LightMode];
    //Primary Time property is ignored
    
    // Time of Day
    [self SetBoolProperty: [self getHomeDateFormat] forClass: programWatchM053_PropertyClass_TimeOfDay andIndex: programWatchM053_PropertyClass_TimeOfDay_HomeTimeDateFormat];
    [self SetBoolProperty: [self getHomeTimeFormat] forClass: programWatchM053_PropertyClass_TimeOfDay andIndex: programWatchM053_PropertyClass_TimeOfDay_HomeTimeTimeFormat];
    [self SetBoolProperty: [self getAwayDateFormat] forClass: programWatchM053_PropertyClass_TimeOfDay andIndex: programWatchM053_PropertyClass_TimeOfDay_AwayTimeDateFormat];
    [self SetBoolProperty: [self getAwayTimeFormat] forClass: programWatchM053_PropertyClass_TimeOfDay andIndex: programWatchM053_PropertyClass_TimeOfDay_AwayTimeTimeFormat];
    
    BOOL flag = [self getSyncModeShowStatus];
    [[NSUserDefaults standardUserDefaults] setBool: flag forKey: kSyncModeIsShownWatchSettingKey];
    flag = [self getNFCStatus];
    [[NSUserDefaults standardUserDefaults] setBool: flag forKey: kNFCStatusWatchSettingKey];
    
    [self SetBoolProperty: [self getUnitOfMeasure] forClass: programWatchM053_PropertyClass_General andIndex: programWatchM053_PropertyClass_General_UnitOfMeasure];
    [self SetBoolProperty: [self getGender] forClass: programWatchM053_PropertyClass_UserInfo andIndex: programWatchM053_PropertyClass_UserInfo_Gender];
    
    // Alarms
    [self SetBoolProperty: ((TDDatacastAlarm *)[mAlarms objectAtIndex: 0]).enable forClass: programWatchM053_PropertyClass_Alarm andIndex: programWatchM053_PropertyClass_Alarm_A1_Status];
    [self SetBoolProperty: ((TDDatacastAlarm *)[mAlarms objectAtIndex: 1]).enable forClass: programWatchM053_PropertyClass_Alarm andIndex: programWatchM053_PropertyClass_Alarm_A2_Status];
    [self SetBoolProperty: ((TDDatacastAlarm *)[mAlarms objectAtIndex: 2]).enable forClass: programWatchM053_PropertyClass_Alarm andIndex: programWatchM053_PropertyClass_Alarm_A3_Status];
    
    [self SetDateProperty: [self getDateFrom: (TDDatacastAlarm *)[mAlarms objectAtIndex: 0]] forClass: programWatchM053_PropertyClass_Alarm andIndex: programWatchM053_PropertyClass_Alarm_A1_Time];
    [self SetDateProperty: [self getDateFrom: (TDDatacastAlarm *)[mAlarms objectAtIndex: 1]] forClass: programWatchM053_PropertyClass_Alarm andIndex: programWatchM053_PropertyClass_Alarm_A2_Time];
    [self SetDateProperty: [self getDateFrom: (TDDatacastAlarm *)[mAlarms objectAtIndex: 2]] forClass: programWatchM053_PropertyClass_Alarm andIndex: programWatchM053_PropertyClass_Alarm_A3_Time];
    
    [self SetIntProperty: ((TDDatacastAlarm *)[mAlarms objectAtIndex: 0]).repeatPattern forClass: programWatchM053_PropertyClass_Alarm andIndex: programWatchM053_PropertyClass_Alarm_A1_Frequency];
    [self SetIntProperty: ((TDDatacastAlarm *)[mAlarms objectAtIndex: 1]).repeatPattern forClass: programWatchM053_PropertyClass_Alarm andIndex: programWatchM053_PropertyClass_Alarm_A2_Frequency];
    [self SetIntProperty: ((TDDatacastAlarm *)[mAlarms objectAtIndex: 2]).repeatPattern forClass: programWatchM053_PropertyClass_Alarm andIndex: programWatchM053_PropertyClass_Alarm_A3_Frequency];
    
    // Intervals
    [self SetDatePropertyFromInterval: (TDM053Interval *)[mIntervals objectAtIndex: 0] forClass: programWatchM053_PropertyClass_IntervalTimer andIndex: programWatchM053_PropertyClass_IntervalTimer_IT1_Time];
    [self SetDatePropertyFromInterval: (TDM053Interval *)[mIntervals objectAtIndex: 1] forClass: programWatchM053_PropertyClass_IntervalTimer andIndex: programWatchM053_PropertyClass_IntervalTimer_IT2_Time];
    [self SetIntProperty: int_timer_actionAtEnd forClass: programWatchM053_PropertyClass_IntervalTimer andIndex: programWatchM053_PropertyClass_IntervalTimer_ActionAtEnd];
    
    //Timer
    [self SetDatePropertyForTimer];
    [self SetIntProperty: timer_actionAtEnd forClass: programWatchM053_PropertyClass_Timer andIndex: programWatchM053_PropertyClass_Timer_ActionAtEnd];
    
    //User Data
    [self SetIntProperty: userAge forClass: programWatchM053_PropertyClass_UserInfo andIndex: programWatchM053_PropertyClass_UserInfo_Age];
    [self SetIntProperty: userHeight forClass: programWatchM053_PropertyClass_UserInfo andIndex: programWatchM053_PropertyClass_UserInfo_Height];
    [self SetIntProperty: userWeight forClass: programWatchM053_PropertyClass_UserInfo andIndex: programWatchM053_PropertyClass_UserInfo_Weight];
    
    [self SetIntAppSettingProperty: dailyStepGoal forClass: appSettingsM053_PropertyClass_Goals andIndex: appSettingsM053_PropertyClass_Goals_Steps];
    [self SetIntAppSettingProperty: dailyDistanceGoal forClass: appSettingsM053_PropertyClass_Goals andIndex: appSettingsM053_PropertyClass_Goals_Distance];
    [self SetIntAppSettingProperty: dailyCalorieGoal forClass: appSettingsM053_PropertyClass_Goals andIndex: appSettingsM053_PropertyClass_Goals_Calories];
    
    [self SetBoolProperty: [self getActivitySensorStatus] forClass: programWatchM053_PropertyClass_ActivityTracking andIndex: programWatchM053_PropertyClass_ActivityTracking_SensorStatus];
    [self SetIntProperty: [self getSensorSensitivity] forClass: programWatchM053_PropertyClass_ActivityTracking andIndex: programWatchM053_PropertyClass_ActivityTracking_SensorSensitivity];
    
    if ([self getStepsStatus])
        [self SetIntProperty: programWatchM053_PropertyClass_GoalsStatus_Steps forClass: programWatchM053_PropertyClass_ActivityTracking andIndex: programWatchM053_PropertyClass_ActivityTracking_GoalsStatus];
    else if ([self getDistanceStatus])
        [self SetIntProperty: programWatchM053_PropertyClass_GoalsStatus_Distance forClass: programWatchM053_PropertyClass_ActivityTracking andIndex: programWatchM053_PropertyClass_ActivityTracking_GoalsStatus];
    else if ([self getCaloriesStatus])
        [self SetIntProperty: programWatchM053_PropertyClass_GoalsStatus_Calories forClass: programWatchM053_PropertyClass_ActivityTracking andIndex: programWatchM053_PropertyClass_ActivityTracking_GoalsStatus];
    else
        [self SetIntProperty: programWatchM053_PropertyClass_GoalsStatus_Off forClass: programWatchM053_PropertyClass_ActivityTracking andIndex: programWatchM053_PropertyClass_ActivityTracking_GoalsStatus];
    
    //Chrono settings
    [self SetIntAppSettingProperty: [self getLapSplitWorkoutFormat] forClass: appSettingsM053_PropertyClass_Workouts andIndex: appSettingsM053_PropertyClass_Workouts_DisplayFormat];

    [self SetIntAppSettingProperty: [self getClearWorkoutRequestSetting] forClass: appSettingsM053_PropertyClass_Workouts andIndex: appSettingsM053_PropertyClass_Workouts_DeleteAfterSync];
}

- (void) SetDatePropertyForTimer
{
    NSDateComponents * components = [[NSDateComponents alloc] init];
    
    components.second = timer_seconds;
    components.minute = timer_minutes;
    components.hour = timer_hours;
    
    NSMutableData *data= [NSMutableData data];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData: data];
    
    [archiver encodeObject: components];
    [archiver finishEncoding];
    
    NSString * key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM053_PropertyClass_Timer andIndex: programWatchM053_PropertyClass_Timer_Time];
    [[NSUserDefaults standardUserDefaults] setObject: data forKey: key];
}
- (void) SetDatePropertyFromInterval: (TDM053Interval *) interval forClass: (programWatchM053_PropertyClass) classId andIndex: (NSInteger) idx
{
    NSDateComponents * components = [[NSDateComponents alloc] init];
    
    components.second = interval.seconds;
    components.minute = interval.minutes;
    components.hour = interval.hours;
    
    NSMutableData *data= [NSMutableData data];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData: data];
    
    [archiver encodeObject: components];
    [archiver finishEncoding];
    
    NSString * key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: classId andIndex: idx];
    [[NSUserDefaults standardUserDefaults] setObject: data forKey: key];
}
- (TDM053Interval *) GetIntervalForClass: (programWatchM053_PropertyClass) classId andIndex: (NSInteger) idx
{
    NSString * key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: classId andIndex: idx];
    NSMutableData * setting = [[NSUserDefaults standardUserDefaults] objectForKey: key];
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData: setting];
    NSDateComponents *decoded = [unarchiver decodeObject];
    [unarchiver finishDecoding];
    
    TDM053Interval * newInt = [[TDM053Interval alloc] init];
    newInt.hours = decoded.hour;
    newInt.minutes = decoded.minute;
    newInt.seconds = decoded.second;
    
    return newInt;
}
- (void) SetBoolProperty: (BOOL) flag forClass: (programWatchM053_PropertyClass) classId andIndex: (NSInteger) idx
{
    NSString * key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: classId andIndex: idx];
    [[NSUserDefaults standardUserDefaults] setBool: flag forKey: key];
}
- (void) SetDateProperty: (NSDate *) value forClass: (programWatchM053_PropertyClass) classId andIndex: (NSInteger) idx
{
    NSString * key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: classId andIndex: idx];
    [[NSUserDefaults standardUserDefaults] setObject: value forKey: key];
}
- (void) SetIntProperty: (NSInteger) value forClass: (programWatchM053_PropertyClass) classId andIndex: (NSInteger) idx
{
    NSString * key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: classId andIndex: idx];
    [[NSUserDefaults standardUserDefaults] setInteger: value forKey: key];
}
- (void) SetIntAppSettingProperty: (NSInteger) value forClass: (appSettingsM053_PropertyClass) classId andIndex: (NSInteger) idx
{
    NSString * key = [iDevicesUtil createKeyForAppSettingsPropertyWithClass: classId andIndex: idx];
    [[NSUserDefaults standardUserDefaults] setInteger: value forKey: key];
}
- (BOOL) GetBoolPropertyForClass: (programWatchM053_PropertyClass) classId andIndex: (NSInteger) idx
{
    BOOL flag = FALSE;
    NSString * key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: classId andIndex: idx];
    if ([[NSUserDefaults standardUserDefaults] objectForKey: key] != nil)
    {
        flag = [[NSUserDefaults standardUserDefaults] boolForKey: key];
    }
    return flag;
}
- (NSInteger) GetIntPropertyForClass: (programWatchM053_PropertyClass) classId andIndex: (NSInteger) idx
{
    NSInteger result = 0;
    
    NSString * key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: classId andIndex: idx];
    if ([[NSUserDefaults standardUserDefaults] objectForKey: key] != nil)
    {
        result = [[NSUserDefaults standardUserDefaults] integerForKey: key];
    }
    return result;
}
- (NSInteger) GetIntAppSettingPropertyForClass: (appSettingsM053_PropertyClass) classId andIndex: (NSInteger) idx
{
    NSInteger result = 0;
    
    NSString * key = [iDevicesUtil createKeyForAppSettingsPropertyWithClass: classId andIndex: idx];
    if ([[NSUserDefaults standardUserDefaults] objectForKey: key] != nil)
    {
        result = [[NSUserDefaults standardUserDefaults] integerForKey: key];
    }
    return result;
}
- (NSDate *) GetDatePropertyForClass: (programWatchM053_PropertyClass) classId andIndex: (NSInteger) idx
{
    NSDate * result = nil;
    
    NSString * key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: classId andIndex: idx];
    if ([[NSUserDefaults standardUserDefaults] objectForKey: key] != nil)
    {
        result = [[NSUserDefaults standardUserDefaults] objectForKey: key];
    }
    
    return result;
}

- (int) getHourlyChime
{
    return generalSettings2Flag & 0x1;
}
- (int) getButtonBeep
{
    return (generalSettings2Flag & 0x2) >> 1;
}
- (int) getActivitySensorStatus
{
    return (generalSettings2Flag & 0x4) >> 2;
}


- (int) getHomeTimeFormat
{
    return generalSettingsFlag & 0x1;
}
- (int) getHomeDateFormat
{
    return (generalSettingsFlag & 0x2) >> 1;
}
- (int) getAwayTimeFormat
{
    return (generalSettingsFlag & 0x4) >> 2;
}
- (int) getAwayDateFormat
{
    return (generalSettingsFlag & 0x8) >> 3;
}
- (int) getLightActivationMode
{
    return (generalSettingsFlag & 0x10) >> 4;
}

- (int) getSyncModeShowStatus
{
    return generalSettings3Flag & 0x1;
}
- (int) getNFCStatus
{
    return (generalSettings3Flag & 0x2) >> 1;
}
- (int) getUnitOfMeasure
{
    return (generalSettings3Flag & 0x4) >> 2;
}
- (int) getGender
{
    return (generalSettings3Flag & 0x8) >> 3;
}
- (int) getLapSplitWorkoutFormat
{
    return chronoSettingsFlags & 0x1;
}
- (int) getClearWorkoutRequestSetting
{
    return (chronoSettingsFlags & 0x2) >> 1;
}
- (int) getSensorSensitivity
{
    int status1 = (generalSettings3Flag & 0x10) >> 4;
    int status2 = (generalSettings3Flag & 0x20) >> 5;
    
    if (!status1 && !status2)
        return programWatchM053_PropertyClass_Activity_SensorSensitivityLow;
    else if (status1 && !status2)
        return programWatchM053_PropertyClass_Activity_SensorSensitivityMedium;
    else if (!status1 && status2)
        return programWatchM053_PropertyClass_Activity_SensorSensitivityHigh;
    
    return programWatchM053_PropertyClass_Activity_SensorSensitivityLow;
}
- (BOOL) getStepsStatus
{
    int status1 = (generalSettings3Flag & 0x40) >> 6;
    int status2 = (generalSettings3Flag & 0x80) >> 7;
    
    if (status1 && !status2)
        return TRUE;
    else
        return FALSE;
}
- (BOOL) getDistanceStatus
{
    int status1 = (generalSettings3Flag & 0x40) >> 6;
    int status2 = (generalSettings3Flag & 0x80) >> 7;
    
    if (!status1 && status2)
        return TRUE;
    else
        return FALSE;
}
- (BOOL) getCaloriesStatus
{
    int status1 = (generalSettings3Flag & 0x40) >> 6;
    int status2 = (generalSettings3Flag & 0x80) >> 7;
    
    if (status1 && status2)
        return TRUE;
    else
        return FALSE;
}

- (BOOL) doesWorkoutContain100orMoreRepeats: (TDM053IntervalRecord *) record
{
    BOOL retValue = FALSE;
    
    retValue = (record.mRepetitionsFlags & 0x2) >> 1;
    
    return retValue;
}

- (NSDate *) getDateFrom: (TDDatacastAlarm *) alarm
{
    NSDate* result = nil;
    
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setMinute: alarm.minute];
    [comps setHour: alarm.hour];
    [comps setSecond: 0];
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier: NSCalendarIdentifierGregorian];
    result = [gregorian dateFromComponents: comps];
    
    return result;
}
@end
