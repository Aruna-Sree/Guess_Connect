//
//  TDM328WatchSettings.h
//  timex
//
//  Created by Revanth T on 07/07/16.
//  Copyright © 2016 iDevices, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifndef M328_SETTINGS_DEFS_H_
#define M328_SETTINGS_DEFS_H_

#define M328_SETTINGS_FILE_NAME				("M328S003.SET")
#define M328_SETTINGS_FILE_NAME_GENERIC 	("M328Sxxx.SET")
#define M328_FIRMWARE_FILE_NAME				("M328F001.BIN")
#define M328_CODEPLUG_FILE_NAME             ("M328C001.BIN")
#define M328_ACTLIB_FILE_NAME               ("M328A001.BIN")

#define M328_SLEEP_NUMBER_OF_DAYS               (8)
#define M328_SLEEP_ACTIGRAPHY_BASE_FILE_NAME    ("M328Ax01.SLP")
#define M328_SLEEP_ACTIVITY_BASE_FILE_NAME      ("M328Rx01.SLP")
#define M328_SLEEP_KEY_FILE_NAME                ("M328K001.SLP")
#define M328_SLEEP_SUMMARY_FILE_NAME            ("M328S002.SLP")
#endif /* M328_SETTINGS_DEFS_H_*/

typedef enum
{
    M328_MALE = 0,
    M328_FEMALE = 1
}typeM328Gender;

typedef enum
{
    M328_LOW = 0,
    M328_MEDIUM = 1,
    M328_HIGH = 2
}typeM328Sensitivity;

typedef enum
{
    M328_IMPERIAL = 0,
    M328_METRIC = 1
}typeM328Units;

typedef enum
{
    M328_TIME_NOT_SET_BY_PHONE = 0,
    M328_TIME_SET_BY_PHONE = 1
}typeM328PhoneTimeSetStatus;

typedef enum
{
    M328_MIN_AGE = 5,
    M328_MAX_AGE = 99
    
}typeM328AgeRange;

typedef enum
{
    M328_MIN_WEIGHT = 200,
    M328_MAX_WEIGHT = 2000
}typeM328WeightRange;

typedef enum
{
    M328_MIN_HEIGHT = 102,
    M328_MAX_HEIGHT = 218
}typeM328HeightRange;

typedef enum
{
    M328_MAX_STEPS = 99999,
    M328_MAX_DISTANCE = 9999,
    M328_MAX_CALORIE = 99990
}typeM328GoalRanges;

typedef enum
{
    M328_MIN_ADJUSTMENT = -25,
    M328_MAX_ADJUSTMENT = 25
}typeM328AdjustmentRange;

typedef enum
{
    M328_DAILY_ALARM		= 0,
    M328_WEEKDAY_ALARM	= 1,
    M328_WEEKEND_ALARM	= 2,
    M328_MONDAY_ALARM	= 3,
    M328_TUESDAY_ALARM 	= 4,
    M328_WEDNESDAY_ALARM = 5,
    M328_THURSDAY_ALARM	= 6,
    M328_FRIDAY_ALARM 	= 7,
    M328_SATURDAY_ALARM	= 8,
    M328_SUNDAY_ALARM	= 9
}typeM328AlarmFrequency;

typedef enum
{
    M328_ALARM_DISARMED	= 0,
    M328_ALARM_ARMED 	= 1,		// Sticky
    M328_ALARM_ARMED_1	= 2			// One Shot
}typeM328AlarmStatus;

typedef enum
{
    M328_STEPS_PERC_GOAL		= 0,
    M328_DISTANCE_PERC_GOAL		= 1,
    M328_CALORIES_PERC_GOAL		= 2,
    M328_STEPS					= 3,
    M328_DISTANCE				= 4,
    M328_CALORIES				= 5
}typeM328ActivityDisplay;

typedef enum
{
    M328_ACTIVITY_OFF		= 0,
    M328_ACTIVITY_ON		= 1
}typeM328ActivityEnable;

typedef enum
{
    M328_NO_DISPLAY				= 0,
    M328_DISPLAY_SECONDS		= 1,
    M328_DISPLAY_DATE			= 2,
    M328_DISPLAY_STEPS			= 3,
    M328_DISPLAY_DISTANCE		= 4,
    M328_DISPLAY_CALORIES		= 5
}typeM328SecondHandOperation;

typedef enum
{
    M328_AUTO_SYNCH_OFF				= 0,
    M328_AUTO_SYNCH_USE_TIMES		= 1,
    M328_AUTO_SYNCH_USE_PERIOD		= 2
}typeM328AutoSynchMode;

typedef enum
{
    M328_AUTO_SYNCH_DISABLED			= 0,
    M328_AUTO_SYNCH_ENABLED			= 1
}typeM328AutoSynchEnable;

typedef enum
{
    M328_DO_NOT_DISTURB_OFF		= 0,
    M328_DO_NOT_DISTURB_ON		= 1
}typeM328DoNotDisturbEnable;

typedef enum
{
    M328_TIMER_RESET,
    M328_TIMER_STOPPED,
    M328_TIMER_RUNNING,
    M328_TIMER_EXPIRED
}typeM328countdownTimerStatus;

typedef enum
{
    M328_TIMER_OFF,
    M328_TIMER__RUN,
}typeM328countdownTimerEnable;

typedef enum
{
    M328_TIMER_DISARMED	= 0,
    M328_TIMER_STOPATEND	= 1,
    M328_TIMER_REPEAT	= 2
}typeM328TimerAction;

typedef enum
{
    M328_TIMER_OK,
    M328_TIMER_BAD_TIME,
    M328_TIMER_BAD_ACTION,
    M328_TIMER_BAD_NUMBER
}typeM328countdownTimerSetError;

typedef struct
{
    uint8_t		TimerHour;						// 0-23
    uint8_t		TimerMinute;					// 0-59
    uint8_t		TimerSeconds;					// 0-59
    uint8_t		TimerAction;					// 1 = Stop at end
    // 2 = Repeat at End
    uint8_t		TimerEnable;					// 0 = Stop
    // 1 = Run
}typeM328TimerDefinitions;
// Settings DEFAULT values
#define 	M328_Default_FileVersionNumber              3
#define		M328_Default_Gender                         M328_MALE
#define		M328_Default_AccelSensitivity               M328_MEDIUM
#define		M328_Default_Age                            35		// Age, years
#define		M328_Default_WeightKg                       750		// Userís weight in kilograms with 1-digit decimal. Divide by 10 to get actual value.
#define		M328_Default_HeightM                        165		// Userís height in meters with 2-digit decimal. Divide by 100 to get actual value
#define		M328_Default_DailyStepGoal                  6000	// Daily step goal(0 ñ 99,999)
#define		M328_Default_DailyDistanceGoal              411		// Daily distance goal in kilometres with 2-digit decimal. Divide by 100 to get actual value.
#define		M328_Default_DailyCalorieGoal               18230	// Daily calorie goal in kilocalorie unit with 1-digit decimal. Divide by 10 to get actual value
#define		M328_Default_DistanceAdjustment             0		// Distance Calibration, +/- 25%, 1% granularity (-25 to 25)
#define		M328_Default_RecommendedDistanceAdjustment	0// Not Used - Recommended Distance Calibration,

#define		M328_Default_Units                          M328_IMPERIAL		// 0 = Imperial, 1 = Metric
#define		M328_Default_Seconds                        0		// 00-59
#define		M328_Default_Minutes                        0		// 00-59
#define		M328_Default_Hours                          0		// 00-23
#define		M328_Default_Date                           1		// 1-31
#define		M328_Default_Month                          1		// 1-12
#define		M328_Default_Year                           2015	// 2000-2099

#define		M328_Default_ActivityEnable			M328_ACTIVITY_OFF
#define		M328_Default_DisplaySubdial			M328_STEPS_PERC_GOAL

#define		M328_Default_Alarm_Hr				12
#define		M328_Default_Alarm_Min				00
#define		M328_Default_Alarm_Freq				M328_DAILY_ALARM
#define		M328_Default_Alarm_Status			M328_ALARM_DISARMED

#define		M328_Default_Timer_Hr				00
#define		M328_Default_Timer_Min				05
#define		M328_Default_Timer_Sec				00
#define		M328_Default_Timer_Action			M328_TIMER_STOPATEND
#define		M328_Default_Timer_Status			M328_TIMER_OFF

#define 	M328_Default_TZ_Offset				0
#define 	M328_Default_TZ_DST					0

#define		M328_Default_DeclinationAdjustment	0

#define		M328_Default_Seconds_Operation		M328_DISPLAY_SECONDS

#define		M328_Default_AutoSynchMode			M328_AUTO_SYNCH_OFF
#define		M328_Default_AutoSynchPeriod			(60*60*6)		// Every 6 Hours
#define		M328_Default_AutoSynchTimeHour		(0)				// 00:00:00
#define		M328_Default_AutoSynchEnable			M328_AUTO_SYNCH_DISABLED
#define		M328_Default_DoNotDisturbStartHour	(22)
#define		M328_Default_DoNotDisturbEndHour		(8)
#define		M328_Default_DoNotDisturbEnable		M328_DO_NOT_DISTURB_OFF



@interface TDM328WatchSettings : NSObject
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
    
}
@property (nonatomic, readonly) int mChecksum;

- (id) init;
- (id) init: (NSData *) inData;
- (void) serializeIntoSettings;
- (NSData *) toByteArray;

@end
