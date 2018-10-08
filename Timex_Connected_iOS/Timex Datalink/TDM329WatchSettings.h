//
//  TDM328WatchSettings.h
//  timex
//
//  Created by Revanth T on 07/07/16.
//  Copyright © 2016 iDevices, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifndef M329_SETTINGS_DEFS_H_
#define M329_SETTINGS_DEFS_H_

#define M329_SETTINGS_FILE_NAME				("M329S004.SET")
#define M329_SETTINGS_FILE_NAME_GENERIC 	("M329Sxxx.SET")
#define M329_FIRMWARE_FILE_NAME				("M329F001.BIN")
#define M329_CODEPLUG_FILE_NAME             ("M329C001.BIN")
#define M329_ACTLIB_FILE_NAME               ("M329A001.BIN")

#define M329_SLEEP_NUMBER_OF_DAYS               (8)
#define M329_SLEEP_ACTIGRAPHY_BASE_FILE_NAME    ("M329Ax01.SLP")
#define M329_SLEEP_ACTIVITY_BASE_FILE_NAME      ("M329Rx01.SLP")
#define M329_SLEEP_KEY_FILE_NAME                ("M329K001.SLP")
#define M329_SLEEP_SUMMARY_FILE_NAME            ("M329S002.SLP")
#endif /* M329_SETTINGS_DEFS_H_*/

typedef enum
{
    M329_MALE = 0,
    M329_FEMALE = 1
}typeM329Gender;

typedef enum
{
    M329_LOW = 0,
    M329_MEDIUM = 1,
    M329_HIGH = 2
}typeM329Sensitivity;

typedef enum
{
    M329_IMPERIAL = 0,
    M329_METRIC = 1
}typeM329Units;

typedef enum
{
    M329_TIME_NOT_SET_BY_PHONE = 0,
    M329_TIME_SET_BY_PHONE = 1
}typeM329PhoneTimeSetStatus;

typedef enum
{
    M329_MIN_AGE = 5,
    M329_MAX_AGE = 99
    
}typeM329AgeRange;

typedef enum
{
    M329_MIN_WEIGHT = 200,
    M329_MAX_WEIGHT = 2000
}typeM329WeightRange;

typedef enum
{
    M329_MIN_HEIGHT = 102,
    M329_MAX_HEIGHT = 218
}typeM329HeightRange;

typedef enum
{
    M329_MAX_STEPS = 99999,
    M329_MAX_DISTANCE = 9999,
    M329_MAX_CALORIE = 99990
}typeM329GoalRanges;

typedef enum
{
    M329_MIN_ADJUSTMENT = -25,
    M329_MAX_ADJUSTMENT = 25
}typeM329AdjustmentRange;

typedef enum
{
    M329_MIN_TZ_OFFSET = -48,
    M329_MAX_TZ_OFFSET = 58
}typeM329TimeZoneOffsetRange;

typedef enum
{
    M329_DAILY_ALARM		= 0,
    M329_WEEKDAY_ALARM	= 1,
    M329_WEEKEND_ALARM	= 2,
    M329_MONDAY_ALARM	= 3,
    M329_TUESDAY_ALARM 	= 4,
    M329_WEDNESDAY_ALARM = 5,
    M329_THURSDAY_ALARM	= 6,
    M329_FRIDAY_ALARM 	= 7,
    M329_SATURDAY_ALARM	= 8,
    M329_SUNDAY_ALARM	= 9
}typeM329AlarmFrequency;

typedef enum
{
    M329_ALARM_DISARMED	= 0,
    M329_ALARM_ARMED 	= 1,		// Sticky
    M329_ALARM_ARMED_1	= 2			// One Shot
}typeM329AlarmStatus;

typedef enum
{
    M329_STEPS_PERC_GOAL			= 0,
    M329_DISTANCE_PERC_GOAL		= 1,
    M329_CALORIES_PERC_GOAL		= 2,
    M329_STEPS					= 3,
    M329_DISTANCE				= 4,
    M329_CALORIES				= 5,
    TZ2_24HOURTIME              = 6,
    TZ1_24HOURTIME              = 7	// Unsupported
    
}typeM329ActivityDisplay;

typedef enum
{
    M329_ACTIVITY_OFF		= 0,
    M329_ACTIVITY_ON		= 1
}typeM329ActivityEnable;

typedef enum
{
    M329_NO_DISPLAY				= 0,
    M329_DISPLAY_SECONDS		= 1,
    M329_DISPLAY_DATE			= 2,
    M329_DISPLAY_STEPS			= 3,
    M329_DISPLAY_DISTANCE		= 4,
    M329_DISPLAY_CALORIES		= 5,
    DISPLAY_GMT                 = 6,
    DISPLAY_TZ3                 = 7
    
}typeM329SecondHandOperation;

typedef enum
{
    M329_AUTO_SYNCH_OFF				= 0,
    M329_AUTO_SYNCH_USE_TIMES		= 1,
    M329_AUTO_SYNCH_USE_PERIOD		= 2
}typeM329AutoSynchMode;

typedef enum
{
    M329_AUTO_SYNCH_DISABLED		= 0,
    M329_AUTO_SYNCH_ENABLED			= 1
}typeM329AutoSynchEnable;

typedef enum
{
    M329_DO_NOT_DISTURB_OFF		= 0,
    M329_DO_NOT_DISTURB_ON		= 1
}typeM329DoNotDisturbEnable;

typedef enum
{
    STEPS_PERC_GOAL_PB4         = 0,
    DISTANCE_PERC_GOAL_PB4      = 1,
    CALORIES_PERC_GOAL_PB4      = 2,
    STEPS_PB4                   = 3,
    DISTANCE_PB4                = 4,
    CALORIES_PB4                = 5,
    SECOND_TIMEZONE_PB4         = 6,
    GMT_TIME_PB4                = 7,
    THIRD_TIMEZONE_PB4          = 8
} typeM329PB4DisplayFunction;


typedef enum
{
    M329_TIMER_RESET,
    M329_TIMER_STOPPED,
    M329_TIMER_RUNNING,
    M329_TIMER_EXPIRED
}typeM329countdownTimerStatus;

typedef enum
{
    M329_TIMER_OFF,
    M329_TIMER__RUN,
}typeM329countdownTimerEnable;

typedef enum
{
    M329_TIMER_DISARMED	= 0,
    M329_TIMER_STOPATEND	= 1,
    M329_TIMER_REPEAT	= 2
}typeM329TimerAction;

typedef enum
{
    M329_TIMER_OK,
    M329_TIMER_BAD_TIME,
    M329_TIMER_BAD_ACTION,
    M329_TIMER_BAD_NUMBER
}typeM329countdownTimerSetError;

typedef struct
{
    uint8_t		TimerHour;						// 0-23
    uint8_t		TimerMinute;					// 0-59
    uint8_t		TimerSeconds;					// 0-59
    uint8_t		TimerAction;					// 1 = Stop at end
    // 2 = Repeat at End
    uint8_t		TimerEnable;					// 0 = Stop
    // 1 = Run
}typeM329TimerDefinitions;
// Settings DEFAULT values

#define     M329_SETTINGS_VERSION               4
#define     M329_Default_DisplaySubdial         TZ2_24HOURTIME
#define     M329_Default_TZPrimaryOffset        0
#define     M329_Default_TZPrimaryDSTOffset     0
#define     M329_Default_PB4DisplayFunction     STEPS_PB4
#define     M329_Default_MidnightLocation       0


@interface TDM329WatchSettings : NSObject
{
    Byte            mFileFormatVersion;
    Byte            mReserved1;
    Byte            mReserved2;
    Byte            mReserved3;
    
    Byte            mGender;
    Byte            mSensorSensitivity;
    Byte            mAge;
    short            mWeight;
    short            mHeight;
    
    int           mDailyStepGoal;
    int           mDailyDistanceGoal;
    int           mDailyCaloriesGoal;
    
    short           mDistanceAdjustment;
    short           mReccommendedAdjustment;
    Byte            mUnits;
    Byte            mSeconds;
    Byte            mMinutes;
    Byte            mHours;
    Byte            mDate;
    Byte            mMonth;
    short            mYear;
    
    Byte            mActivityEnable;
    Byte            mActivityDisplaySubdial;
    
    //Alert Structure
    Byte            mAlarmHour;
    Byte            mAlarmMinute;
    Byte            mAlarmFrequency;
    Byte            mAlarmStatus;
    
    //Timer Structure
    Byte            mTimerHour;
    Byte            mTimerMinute;
    Byte            mTimerSeconds;
    Byte            mTimerAction;
    Byte            mTimerEnable;
    
    //TimeZoone Structure
    Byte            mTZPrimeayOffset1;
    Byte            mTZPrimaryDSTOffset1;
    
    Byte            mTZPrimeayOffset2;
    Byte            mTZPrimaryDSTOffset2;
    
    Byte            mTZPrimeayOffset3;
    Byte            mTZPrimaryDSTOffset3;
    
    short            mDeclinationAdjustment;
    Byte             mSecondHandMode;
    Byte            mAutoSynchMode;
    int             mAutoSyncPeriod;
    
    //AutoSyncTime Structure
    Byte            mAutoSyncSeconds1;
    Byte            mAutoSyncMinutes1;
    Byte            mAutoSyncHours1;
    Byte            mAutoSyncTimeEnabled1;
    
    //AutoSyncTime Structure
    Byte            mAutoSyncSeconds2;
    Byte            mAutoSyncMinutes2;
    Byte            mAutoSyncHours2;
    Byte            mAutoSyncTimeEnabled2;
    
    //AutoSyncTime Structure
    Byte            mAutoSyncSeconds3;
    Byte            mAutoSyncMinutes3;
    Byte            mAutoSyncHours3;
    Byte            mAutoSyncTimeEnabled3;
    
    //AutoSyncTime Structure
    Byte            mAutoSyncSeconds4;
    Byte            mAutoSyncMinutes4;
    Byte            mAutoSyncHours4;
    Byte            mAutoSyncTimeEnabled4;
    
    //DoNotDisturbStart Structure
    Byte            mDoNotDisturbStartSeconds;
    Byte            mDoNotDisturbStartMinutes;
    Byte            mDoNotDisturbStartHours;

    //DoNotDisturbEnd Structure
    Byte            mDoNotDisturbEndSeconds;
    Byte            mDoNotDisturbEndMinutes;
    Byte            mDoNotDisturbEndHours;
    
    Byte            mDoNotDisturbEnable;
    
    Byte            mPB4DisplayFunction;             // typePB4isplayFunction
    short           mMidnightLocation;               // Where Midnight is located on the Subdial
}
@property (nonatomic, readonly) int mChecksum;

- (id) init;
- (id) init: (NSData *) inData;
- (void) serializeIntoSettings;
- (NSData *) toByteArray;

@end
