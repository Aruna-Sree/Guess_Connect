//
//  iDevicesUtil.h
//  Timex Connected
//
//  Created by Mark Daigle on 6/5/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <EventKit/EventKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "TDDevice.h"
#import "TDRootViewController.h"
#import "PeripheralDevice.h"
#import "PCCOMMDefines.h"


@class TDWorkoutData;

#define MAXIMUM_NUMBER_OF_INTERVAL_TIMER_REPEATS 99
extern NSString* const kCONNECTED_DEVICE_UUID_PREF_NAME;

//-------------------------------------------->
typedef NS_OPTIONS(NSUInteger, TimexUploadServicesOptions)
{
    TimexUploadServicesOptions_RunKeeper          = 1 <<  0,
    TimexUploadServicesOptions_MapMyFitness       = 1 <<  1,
    TimexUploadServicesOptions_DailyMile          = 1 <<  2,
    TimexUploadServicesOptions_Strava             = 1 <<  3,
    TimexUploadServicesOptions_TrainingPeaks      = 1 <<  4,
};

#define TOTAL_UPLOAD_SITES_OPTIONS 5
//<---------------------------------------------

enum timexDatalinkWatchStyle
{
    timexDatalinkWatchStyle_Unselected = 0,
    timexDatalinkWatchStyle_ActivityTracker,
    timexDatalinkWatchStyle_M054,
    timexDatalinkWatchStyle_Metropolitan,
    timexDatalinkWatchStyle_IQ,
    timexDatalinkWatchStyle_IQTravel,
    timexDatalinkWatchStyle_LAST,
    timexDatalinkWatchStyle_NEW
};
enum UserTableColumnType {
    cBirthdate =1,
    cDistanceAdjustment,
    cGender,
    cGoalType,
    cHeight,
    cName,
    cSensorType,
    cUnits,
    cWatchRegistered,
    cWeight,
    cLastname,
    cEmail,
    cZipcode,
    cReceiveProductInfo
};
enum RegistartionProgressValues {
    setupComplete = 1,
    callibrateWatch,
    updateFirmware,
    setupWatch,
    configureSubDial,
    settingGoals,
    weight,
    height,
    birthdate,
    nameandsex
};

enum GoalType {
    Normal = 0,
    Pretty ,
    Very,
    Custom
};
enum SensorType {
    Low = 1,
    Medium,
    High
};
enum WeekDay {
    Sunday = 1,
    Monday ,
    Tuesday,
    WednesDay,
    Thursday,
    Friday,
    Saturday,
    Weekdays,
    Weekends,
    EveryDay
};

enum SettingType {
    Setting_Name = 1,
    Setting_Gender,
    Setting_Age,
    Setting_Height,
    Setting_Weight,
    Setting_Units,
    Setting_Goals,
    Setting_Sensitivity,
    Setting_Distance,
    Setting_SleepTime,
    Setting_AwakeTime,
    Setting_TrackSleep,
    Setting_SyncTime,
    Setting_IntervalRepeats,
    Setting_TimeZoneTimeFormat,
    Setting_TimeZoneDateFormat,
    Setting_ChangeWatch
};

enum General_Gender {
     General_Gender_Male = 0,
    General_Gender_Female
   
};

enum General_Units {
    General_Units_Imperial = 1,
    General_Units_Metric
};

enum Hand_Type {
    Hand_Hour = QA_MOTOR_2,
    Hand_Minute = QA_MOTOR_1,
    Hand_Second = QA_TOD_MOTOR,
    Hand_SubDial = QA_MOTOR_3
};

enum Sync_SuccessStatus {
    Searching =1,
    DeviceFound,
    BatteryGood,
    SynchronizingData,
    SyncCompleted,
    Canceled
};
enum programWatch_PropertyClass
{
    programWatch_PropertyClass_TimeOfDay = 0,
    programWatch_PropertyClass_Alarm,
    programWatch_PropertyClass_IntervalTimer,
    programWatch_PropertyClass_Notifications,
    programWatch_PropertyClass_DoNotDisturb,
    programWatch_PropertyClass_General,
    programWatch_PropertyClass_LAST
};

enum programWatchM053_PropertyClass
{
    programWatchM053_PropertyClass_UserInfo = 0,
    programWatchM053_PropertyClass_ActivityTracking,
    programWatchM053_PropertyClass_TimeOfDay,
    programWatchM053_PropertyClass_Timer,
    programWatchM053_PropertyClass_IntervalTimer,
    programWatchM053_PropertyClass_Alarm,
    programWatchM053_PropertyClass_General,
    programWatchM053_PropertyClass_LAST
};

enum programWatchM372_PropertyClass
{
    programWatchM372_PropertyClass_UserInfo = 0,
    programWatchM372_PropertyClass_ActivityTracking,
    programWatchM372_PropertyClass_General,
    programWatchM372_PropertyClass_LAST
};

enum appSettings_PropertyClass
{
    appSettings_PropertyClass_General = 0,
    appSettings_PropertyClass_Workouts,
    appSettings_PropertyClass_UploadSites,
    appSettings_PropertyClass_PhoneFinder,
    appSettings_PropertyClass_Advanced,
    appSettings_PropertyClass_LAST
};

enum appSettingsM053_PropertyClass
{
    appSettingsM053_PropertyClass_General = appSettings_PropertyClass_General,
    appSettingsM053_PropertyClass_Workouts,
    appSettingsM053_PropertyClass_Calendar,
    appSettingsM053_PropertyClass_UploadSites,
    appSettingsM053_PropertyClass_Goals,
    appSettingsM053_PropertyClass_Advanced,
    appSettingsM053_PropertyClass_LAST
};

enum appSettingsM372_PropertyClass
{
    appSettingsM372_PropertyClass_General = appSettings_PropertyClass_General,
    appSettingsM372_PropertyClass_Goals,
    appSettingsM372_PropertyClass_Advanced,
    appSettingsM372_PropertyClass_LAST
};
enum appSettings_PropertyClass_Workouts_SortTypeEnum
{
    appSettings_PropertyClass_Workouts_SortType_BestLap = 0,
    appSettings_PropertyClass_Workouts_SortType_AverageLap,
    appSettings_PropertyClass_Workouts_SortType_WorkoutDate,
    appSettings_PropertyClass_Workouts_SortType_NumberOfLaps,
    appSettings_PropertyClass_Workouts_SortType_TotalWorkoutTime,
    appSettings_PropertyClass_Workouts_SortType_WorkoutType,
    appSettings_PropertyClass_Workouts_SortType_LAST
};

enum appSettings_PropertyClass_Workouts_StoreHistoryEnum
{
    appSettings_PropertyClass_Workouts_StoreHistory_OneMonth = 0,
    appSettings_PropertyClass_Workouts_StoreHistory_SixMonths,
    appSettings_PropertyClass_Workouts_StoreHistory_OneYear,
    appSettings_PropertyClass_Workouts_StoreHistory_TwoYears,
    appSettings_PropertyClass_Workouts_StoreHistory_All,
    appSettings_PropertyClass_Workouts_StoreHistory_LAST
};

enum appSettingsM053_PropertyClass_Workouts_LapSplitDisplayEnum
{
    appSettingsM053_PropertyClass_Workouts_LapSplit = 0,
    appSettingsM053_PropertyClass_Workouts_SplitLap,
    appSettingsM053_PropertyClass_Workouts_LapSplitDisplayLAST
};

enum appSettings_PropertyClass_GeneralEnum
{
    appSettings_PropertyClass_General_WatchName = 0,
    appSettings_PropertyClass_General_SocialMediaAllowImages,
    appSettings_PropertyClass_General_ConnectToDevices,
    appSettings_PropertyClass_General_SelectCalendars,
    appSettings_PropertyClass_General_LAST
};

enum appSettingsM053_PropertyClass_GeneralEnum
{
    appSettingsM053_PropertyClass_General_WatchName = 0,
    appSettingsM053_PropertyClass_General_SocialMediaAllowImages,
    appSettingsM053_PropertyClass_General_LAST
};

enum appSettingsM372_PropertyClass_GeneralEnum
{
    appSettingsM372_PropertyClass_General_WatchName = 0,
    appSettingsM372_PropertyClass_General_LAST
};

enum appSettings_PropertyClass_WorkoutsEnum
{
    appSettings_PropertyClass_Workouts_SortType = 0,
    appSettings_PropertyClass_Workouts_StoreHistory,
    appSettings_PropertyClass_Workouts_DeleteAfterSync,
    appSettings_PropertyClass_Workouts_LAST
};

enum appSettingsM053_PropertyClass_WorkoutsEnum
{
    appSettingsM053_PropertyClass_Workouts_SortType = 0,
    appSettingsM053_PropertyClass_Workouts_StoreHistory,
    appSettingsM053_PropertyClass_Workouts_DisplayFormat,
    appSettingsM053_PropertyClass_Workouts_DeleteAfterSync,
    appSettingsM053_PropertyClass_Workouts_LAST
};

enum appSettingsM053_PropertyClass_CalendarEnum
{
    appSettingsM053_PropertyClass_CalendarSyncForOnlineAccess = 0,
    appSettingsM053_PropertyClass_CalendarResetAllExcluded,
    appSettingsM053_PropertyClass_CalendarResetCustomAlarms,
    appSettingsM053_PropertyClass_CalendarSelectCalendars,
    appSettingsM053_PropertyClass_Calendar_LAST
};

enum appSettingsM053_PropertyClass_GoalsEnum
{
    appSettingsM053_PropertyClass_Goals_Steps = 0,
    appSettingsM053_PropertyClass_Goals_Distance,
    appSettingsM053_PropertyClass_Goals_Calories,
    appSettingsM053_PropertyClass_Goals_LAST
};

enum appSettingsM372_PropertyClass_GoalsEnum
{
    appSettingsM372_PropertyClass_Goals_Steps = 0,
    appSettingsM372_PropertyClass_Goals_Distance,
    appSettingsM372_PropertyClass_Goals_Calories,
    appSettingsM372_PropertyClass_Goals_Sleep,
    appSettingsM372_PropertyClass_Goals_LAST
};


enum appSettings_PropertyClass_PhoneFinderEnum
{
    appSettings_PropertyClass_PhoneFinder_PhoneFinderCurrentRingtone = 0,
    appSettings_PropertyClass_PhoneFinder_LAST
};

enum appSettings_PropertyClass_PhoneFinderTimexRingtoneEnum
{
    appSettings_PropertyClass_PhoneFinderTimexRingtoneTone1 = 0,
    appSettings_PropertyClass_PhoneFinderTimexRingtoneTone2,
    appSettings_PropertyClass_PhoneFinderTimexRingtoneTone3,
    appSettings_PropertyClass_PhoneFinderTimexRingtone_LAST
};

#define DEFAULT_TIMEX_RINGTONE_SETTING appSettings_PropertyClass_PhoneFinderTimexRingtoneTone3

enum appSettings_PropertyClass_AdvancedEnum
{
    appSettings_PropertyClass_Advanced_CheckFirmware = 0,
    appSettings_PropertyClass_Advanced_ForgetWatch,
    appSettings_PropertyClass_Advanced_LAST
};

enum appSettingsM053_PropertyClass_AdvancedEnum
{
    appSettingsM053_PropertyClass_Advanced_ForgetWatch = 0,
    appSettingsM053_PropertyClass_Advanced_LAST
};

enum appSettingsM372_PropertyClass_AdvancedEnum
{
    appSettingsM372_PropertyClass_Advanced_CheckFirmware = 0,
    appSettingsM372_PropertyClass_Advanced_ResetWatch,
    appSettingsM372_PropertyClass_Advanced_ForgetWatch,
    appSettingsM372_PropertyClass_Advanced_LAST
};

enum programWatch_PropertyClass_TimeOfDayEnum
{
    programWatch_PropertyClass_TimeOfDay_HomeTimeLabel = 0,
    programWatch_PropertyClass_TimeOfDay_HomeTimeTimeFormat,
    programWatch_PropertyClass_TimeOfDay_HomeTimeDateFormat,
    programWatch_PropertyClass_TimeOfDay_AwayTimeLabel,
    programWatch_PropertyClass_TimeOfDay_AwayTimeFollowPhone,
    programWatch_PropertyClass_TimeOfDay_AwayTimeTimeZone,
    programWatch_PropertyClass_TimeOfDay_AwayTimeTimeFormat,
    programWatch_PropertyClass_TimeOfDay_AwayTimeDateFormat,
    programWatch_PropertyClass_TimeOfDay_LAST
};

enum programWatchM053_PropertyClass_UserInfoEnum
{
    programWatchM053_PropertyClass_UserInfo_Age = 0,
    programWatchM053_PropertyClass_UserInfo_Height,
    programWatchM053_PropertyClass_UserInfo_Weight,
    programWatchM053_PropertyClass_UserInfo_Gender,
    programWatchM053_PropertyClass_UserInfo_LAST
};

enum programWatchM372_PropertyClass_UserInfoEnum
{
    programWatchM372_PropertyClass_UserInfo_Age = 0,
    programWatchM372_PropertyClass_UserInfo_Height,
    programWatchM372_PropertyClass_UserInfo_Weight,
    programWatchM372_PropertyClass_UserInfo_Gender,
    programWatchM372_PropertyClass_UserInfo_LAST
};

enum programWatchM053_PropertyClass_ActivityTrackingEnum
{
    programWatchM053_PropertyClass_ActivityTracking_SensorStatus = 0,
    programWatchM053_PropertyClass_ActivityTracking_SensorSensitivity,
    programWatchM053_PropertyClass_ActivityTracking_GoalsStatus,
    programWatchM053_PropertyClass_ActivityTracking_LAST
};

enum programWatchM372_PropertyClass_ActivityTrackingEnum
{
    programWatchM372_PropertyClass_ActivityTracking_SensorSensitivity = 0,
    programWatchM372_PropertyClass_ActivityTracking_DistanceAdjustment,
    programWatchM372_PropertyClass_ActivityTracking_LAST
};

enum programWatchM053_PropertyClass_GoalsStatusEnum
{
    programWatchM053_PropertyClass_GoalsStatus_Off = 0,
    programWatchM053_PropertyClass_GoalsStatus_Steps,
    programWatchM053_PropertyClass_GoalsStatus_Distance,
    programWatchM053_PropertyClass_GoalsStatus_Calories,
    programWatchM053_PropertyClass_GoalsStatus_LAST
};

enum programWatchM053_PropertyClass_TimeOfDayEnum
{
    programWatchM053_PropertyClass_TimeOfDay_HomeTimeLabel = 0,
    programWatchM053_PropertyClass_TimeOfDay_HomeTimeTimeFormat,
    programWatchM053_PropertyClass_TimeOfDay_HomeTimeDateFormat,
    programWatchM053_PropertyClass_TimeOfDay_AwayTimeLabel,
    programWatchM053_PropertyClass_TimeOfDay_AwayTimeFollowPhone,
    programWatchM053_PropertyClass_TimeOfDay_AwayTimeTimeZone,
    programWatchM053_PropertyClass_TimeOfDay_AwayTimeTimeFormat,
    programWatchM053_PropertyClass_TimeOfDay_AwayTimeDateFormat,
    programWatchM053_PropertyClass_TimeOfDay_LAST
};

enum programWatchM372_PropertyClass_TimeOfDayEnum
{
    programWatchM372_PropertyClass_TimeOfDay_HomeTimeLabel = 0,
    programWatchM372_PropertyClass_TimeOfDay_HomeTimeTimeFormat,
    programWatchM372_PropertyClass_TimeOfDay_HomeTimeDateFormat,
    programWatchM372_PropertyClass_TimeOfDay_AwayTimeLabel,
    programWatchM372_PropertyClass_TimeOfDay_AwayTimeFollowPhone,
    programWatchM372_PropertyClass_TimeOfDay_AwayTimeTimeZone,
    programWatchM372_PropertyClass_TimeOfDay_AwayTimeTimeFormat,
    programWatchM372_PropertyClass_TimeOfDay_AwayTimeDateFormat,
    programWatchM372_PropertyClass_TimeOfDay_LAST
};

enum programWatch_PropertyClass_GeneralEnum
{
    programWatch_PropertyClass_General_HourlyChime = 0,
    programWatch_PropertyClass_General_ButtonBeep,
    programWatch_PropertyClass_General_LightMode,
    programWatch_PropertyClass_General_TapForce,
    programWatch_PropertyClass_General_DisplayTextColor,
    programWatch_PropertyClass_General_Language,
    programWatch_PropertyClass_General_DisplaySecondsUpdate,
    programWatch_PropertyClass_General_LAST
};

enum programWatchM053_PropertyClass_GeneralEnum
{
    programWatchM053_PropertyClass_General_HourlyChime = 0,
    programWatchM053_PropertyClass_General_ButtonBeep,
    programWatchM053_PropertyClass_General_LightMode,
    programWatchM053_PropertyClass_General_UnitOfMeasure,
    programWatchM053_PropertyClass_General_LAST
};

enum programWatchM372_PropertyClass_GeneralEnum
{
    programWatchM372_PropertyClass_General_UnitOfMeasure = 0,
    programWatchM372_PropertyClass_General_LAST
};
enum programWatch_PropertyClass_IntervalTimerEnum
{
    programWatch_PropertyClass_IntervalTimer_IT1_OnOff = 0,
    programWatch_PropertyClass_IntervalTimer_IT1_Time,
    programWatch_PropertyClass_IntervalTimer_IT1_label,
    programWatch_PropertyClass_IntervalTimer_IT2_OnOff,
    programWatch_PropertyClass_IntervalTimer_IT2_Time,
    programWatch_PropertyClass_IntervalTimer_IT2_label,
    programWatch_PropertyClass_IntervalTimer_IntervalRepeats,
    programWatch_PropertyClass_IntervalTimer_IntervalAlert,
    programWatch_PropertyClass_IntervalTimer_LAST
};

enum programWatchM053_PropertyClass_IntervalTimerEnum
{
    programWatchM053_PropertyClass_IntervalTimer_IT1_Time = 0,
    programWatchM053_PropertyClass_IntervalTimer_IT2_Time,
    programWatchM053_PropertyClass_IntervalTimer_ActionAtEnd,
    programWatchM053_PropertyClass_IntervalTimer_LAST
};

enum programWatch_PropertyClass_AlarmEnum
{
    programWatch_PropertyClass_Alarm_A1_Status = 0,
    programWatch_PropertyClass_Alarm_A1_Time,
    programWatch_PropertyClass_Alarm_A1_Frequency,
    programWatch_PropertyClass_Alarm_A2_Status,
    programWatch_PropertyClass_Alarm_A2_Time,
    programWatch_PropertyClass_Alarm_A2_Frequency,
    programWatch_PropertyClass_Alarm_A3_Status,
    programWatch_PropertyClass_Alarm_A3_Time,
    programWatch_PropertyClass_Alarm_A3_Frequency,
    programWatch_PropertyClass_Alarm_Alert,
    programWatch_PropertyClass_Alarm_LAST
};

enum programWatchM053_PropertyClass_AlarmEnum
{
    programWatchM053_PropertyClass_Alarm_A1_Status = 0,
    programWatchM053_PropertyClass_Alarm_A1_Time,
    programWatchM053_PropertyClass_Alarm_A1_Frequency,
    programWatchM053_PropertyClass_Alarm_A2_Status,
    programWatchM053_PropertyClass_Alarm_A2_Time,
    programWatchM053_PropertyClass_Alarm_A2_Frequency,
    programWatchM053_PropertyClass_Alarm_A3_Status,
    programWatchM053_PropertyClass_Alarm_A3_Time,
    programWatchM053_PropertyClass_Alarm_A3_Frequency,
    programWatchM053_PropertyClass_Alarm_LAST
};

enum programWatch_PropertyClass_DNDEnum
{
    programWatch_PropertyClass_DND_DNDStatus = 0,
    programWatch_PropertyClass_DND_DNDStart,
    programWatch_PropertyClass_DND_DNDEnd,
    programWatch_PropertyClass_DND_LAST
};

enum programWatchM053_PropertyClass_TimerEnum
{
    programWatchM053_PropertyClass_Timer_Time = 0,
    programWatchM053_PropertyClass_Timer_ActionAtEnd,
    programWatchM053_PropertyClass_Timer_LAST
};

enum programWatch_PropertyClass_NotificationsEnum
{
    programWatch_PropertyClass_Notifications_All = 0,
    programWatch_PropertyClass_Notifications_Alert,
    programWatch_PropertyClass_Notifications_LAST
};

enum programWatch_PropertyClass_TimeOfDay_FollowPhoneTimeEnum
{
    programWatch_PropertyClass_TimeOfDay_FollowPhoneTimeFollowPhone = 0,
    programWatch_PropertyClass_TimeOfDay_FollowPhoneTimeFollowTimeZone,
    programWatch_PropertyClass_TimeOfDay_FollowPhoneTimeManual,
    programWatch_PropertyClass_TimeOfDay_FollowPhoneTimeLAST
};

enum programWatch_PropertyClass_TimeOfDay_TZTimeFormatEnum
{
    programWatch_PropertyClass_TimeOfDay_TZTimeFormat12HR = 0,
    programWatch_PropertyClass_TimeOfDay_TZTimeFormat24HR,
    programWatch_PropertyClass_TimeOfDay_TZTimeFormatLAST
};

enum programWatch_PropertyClass_TimeOfDay_TZDateFormatEnum
{
    programWatch_PropertyClass_TimeOfDay_TZDateFormatMMMDD = 0,
    programWatch_PropertyClass_TimeOfDay_TZDateFormatMMDDYY,
    programWatch_PropertyClass_TimeOfDay_TZDateFormatDDMMYY,
    programWatch_PropertyClass_TimeOfDay_TZDateFormatYYYYMMDD,
    programWatch_PropertyClass_TimeOfDay_TZDateFormatLAST
};

enum programWatch_PropertyClass_TimeOfDay_TZOtherDateFormatEnum
{
    programWatch_PropertyClass_TimeOfDay_TZOtherDateFormatMMDDYY = 0,
    programWatch_PropertyClass_TimeOfDay_TZOtherDateFormatDDMMYY,
    programWatch_PropertyClass_TimeOfDay_TZOtherDateFormatLAST
};

enum programWatchM053_PropertyClass_TimeOfDay_TZDateFormatEnum
{
    programWatchM053_PropertyClass_TimeOfDay_TZDateFormatMMDD = 0,
    programWatchM053_PropertyClass_TimeOfDay_TZDateFormatDDMM,
    programWatchM053_PropertyClass_TimeOfDay_TZDateFormatLAST
};

enum programWatchM372_PropertyClass_TimeOfDay_TZDateFormatEnum
{
    programWatchM372_PropertyClass_TimeOfDay_TZDateFormatMMDD = 0,
    programWatchM372_PropertyClass_TimeOfDay_TZDateFormatDDMM,
    programWatchM372_PropertyClass_TimeOfDay_TZDateFormatLAST
};

enum programWatchActivityTracker_PropertyClass_UserInfo_GenderEnum
{
    programWatchActivityTracker_PropertyClass_UserInfo_Gender_Male = 0,
    programWatchActivityTracker_PropertyClass_UserInfo_Gender_Female,
    programWatchActivityTracker_PropertyClass_UserInfo_Gender_LAST
};

enum programWatchActivityTracker_PropertyClass_General_UnitsEnum
{
    programWatchActivityTracker_PropertyClass_General_Units_Imperial = 0,
    programWatchActivityTracker_PropertyClass_General_Units_Metric,
    programWatchActivityTracker_PropertyClass_General_Units_LAST
};

enum programWatchM053_PropertyClass_Activity_SensorSensitivityEnum
{
    programWatchM053_PropertyClass_Activity_SensorSensitivityLow = 0,
    programWatchM053_PropertyClass_Activity_SensorSensitivityMedium,
    programWatchM053_PropertyClass_Activity_SensorSensitivityHigh,
    programWatchM053_PropertyClass_Activity_SensorSensitivityLAST
};

enum programWatchM372_PropertyClass_Activity_SensorSensitivityEnum
{
    programWatchM372_PropertyClass_Activity_SensorSensitivityLow = 0,
    programWatchM372_PropertyClass_Activity_SensorSensitivityMedium,
    programWatchM372_PropertyClass_Activity_SensorSensitivityHigh,
    programWatchM372_PropertyClass_Activity_SensorSensitivityLAST
};

enum programWatch_PropertyClass_IntervalTimer_LabelEnum
{
    programWatch_PropertyClass_IntervalTimer_LabelFast = 0,
    programWatch_PropertyClass_IntervalTimer_LabelSlow,
    programWatch_PropertyClass_IntervalTimer_LabelEasy,
    programWatch_PropertyClass_IntervalTimer_LabelHard,
    programWatch_PropertyClass_IntervalTimer_LabelRun,
    programWatch_PropertyClass_IntervalTimer_LabelWalk,
    programWatch_PropertyClass_IntervalTimer_LabelLift,
    programWatch_PropertyClass_IntervalTimer_LabelRest,
    programWatch_PropertyClass_IntervalTimer_LabelSwim,
    programWatch_PropertyClass_IntervalTimer_LabelBike,
    programWatch_PropertyClass_IntervalTimer_LabelMax,
    programWatch_PropertyClass_IntervalTimer_LabelGo,
    programWatch_PropertyClass_IntervalTimer_LabelLAST
};

enum programWatch_PropertyClass_Alarm_FrequencyEnum
{
    programWatch_PropertyClass_Alarm_Frequency_Once = 0,
    programWatch_PropertyClass_Alarm_Frequency_Daily,
    programWatch_PropertyClass_Alarm_Frequency_Weekdays,
    programWatch_PropertyClass_Alarm_Frequency_Weekends,
    programWatch_PropertyClass_Alarm_Frequency_Monday,
    programWatch_PropertyClass_Alarm_Frequency_Tuesday,
    programWatch_PropertyClass_Alarm_Frequency_Wednesday,
    programWatch_PropertyClass_Alarm_Frequency_Thursday,
    programWatch_PropertyClass_Alarm_Frequency_Friday,
    programWatch_PropertyClass_Alarm_Frequency_Saturday,
    programWatch_PropertyClass_Alarm_Frequency_Sunday,
    programWatch_PropertyClass_Alarm_Frequency_LAST
};

enum programWatchM053_PropertyClass_Alarm_FrequencyEnum
{
    programWatchM053_PropertyClass_Alarm_Frequency_Daily = 0,
    programWatchM053_PropertyClass_Alarm_Frequency_Weekdays,
    programWatchM053_PropertyClass_Alarm_Frequency_Weekends,
    programWatchM053_PropertyClass_Alarm_Frequency_Monday,
    programWatchM053_PropertyClass_Alarm_Frequency_Tuesday,
    programWatchM053_PropertyClass_Alarm_Frequency_Wednesday,
    programWatchM053_PropertyClass_Alarm_Frequency_Thursday,
    programWatchM053_PropertyClass_Alarm_Frequency_Friday,
    programWatchM053_PropertyClass_Alarm_Frequency_Saturday,
    programWatchM053_PropertyClass_Alarm_Frequency_Sunday,
    programWatchM053_PropertyClass_Alarm_Frequency_LAST
};

enum programWatchM372_PropertyClass_Alarm_FrequencyEnum
{
    programWatchM372_PropertyClass_Alarm_Frequency_Daily = 0,
    programWatchM372_PropertyClass_Alarm_Frequency_Weekdays,
    programWatchM372_PropertyClass_Alarm_Frequency_Weekends,
    programWatchM372_PropertyClass_Alarm_Frequency_Monday,
    programWatchM372_PropertyClass_Alarm_Frequency_Tuesday,
    programWatchM372_PropertyClass_Alarm_Frequency_Wednesday,
    programWatchM372_PropertyClass_Alarm_Frequency_Thursday,
    programWatchM372_PropertyClass_Alarm_Frequency_Friday,
    programWatchM372_PropertyClass_Alarm_Frequency_Saturday,
    programWatchM372_PropertyClass_Alarm_Frequency_Sunday,
    programWatchM372_PropertyClass_Alarm_Frequency_LAST
};

enum programWatch_PropertyClass_Alarm_AlertEnum
{
    programWatch_PropertyClass_Alarm_AlertAudible = 0,
    programWatch_PropertyClass_Alarm_AlertVibrate,
    programWatch_PropertyClass_Alarm_AlertBoth,
    programWatch_PropertyClass_Alarm_AlertLAST
};

enum programWatch_PropertyClass_Notifications_AlertEnum
{
    programWatch_PropertyClass_Notifications_AlertAudible = 0,
    programWatch_PropertyClass_Notifications_AlertVibrate,
    programWatch_PropertyClass_Notifications_AlertBoth,
    programWatch_PropertyClass_Notifications_AlertNone,
    programWatch_PropertyClass_Notifications_AlertLAST
};

enum programWatch_PropertyClass_General_LightModeEnum
{
    programWatch_PropertyClass_General_LightModeManual = 0,
    programWatch_PropertyClass_General_LightModeNightMode,
    programWatch_PropertyClass_General_LightModeAlwaysOn,
    programWatch_PropertyClass_General_LightModeLAST
};

enum programWatch_PropertyClass_General_TapForceEnum
{
    programWatch_PropertyClass_General_TapForceLight = 0,
    programWatch_PropertyClass_General_TapForceMedium,
    programWatch_PropertyClass_General_TapForceHard,
    programWatch_PropertyClass_General_TapForce_LAST
};

enum programWatch_PropertyClass_General_TextColorEnum
{
    programWatch_PropertyClass_General_TextColorWhite = 0,
    programWatch_PropertyClass_General_TextColorBlack,
    programWatch_PropertyClass_General_TextColor_LAST
};

enum programWatch_PropertyClass_General_LanguageEnum
{
    programWatch_PropertyClass_General_LanguageEnglish = 0,
    programWatch_PropertyClass_General_LanguageSpanish,
    programWatch_PropertyClass_General_LanguageFrench,
    programWatch_PropertyClass_General_LanguageGerman,
    programWatch_PropertyClass_General_LanguagePortuguese,
    programWatch_PropertyClass_General_LanguageItalian,
    programWatch_PropertyClass_General_LanguageDutch,
    programWatch_PropertyClass_General_Language_LAST
};

enum programWatchM053_PropertyClass_IntervalTimers_ActionAtEndEnum
{
    programWatchM053_PropertyClass_IntervalTimers_ActionAtEnd_Stop = 0,
    programWatchM053_PropertyClass_IntervalTimers_ActionAtEnd_Repeat,
    programWatchM053_PropertyClass_IntervalTimers_ActionAtEnd_LAST
};

enum programWatchM372_PropertyClass_IntervalTimers_ActionAtEndEnum
{
    programWatchM372_PropertyClass_IntervalTimers_ActionAtEnd_Stop = 0,
    programWatchM372_PropertyClass_IntervalTimers_ActionAtEnd_Repeat,
    programWatchM372_PropertyClass_IntervalTimers_ActionAtEnd_LAST
};

enum uploadSites_PropertyClass_settingTypeEnum
{
    uploadSites_PropertyClass_settingType_isAutoUpload = 0
};


enum cell_swipeState
{
    cell_swipeState_normal = 0,
    cell_animationInProgress,
    cell_swipeState_collapsed
};


enum calendar_alarmTimeOptions
{
    calendar_alarmTimeOptions_Now = 0,
    calendar_alarmTimeOptions_15min,
    calendar_alarmTimeOptions_30min,
    calendar_alarmTimeOptions_60min,
    calendar_alarmTimeOptions_120min,
    calendar_alarmTimeOptions_LAST
};

enum activityTracker_Chart_GoalLineOptions
{
    activityTracker_Chart_GoalLineOptions_Goal = 0,
    activityTracker_Chart_GoalLineOptions_WeeklyAverage,
    activityTracker_Chart_GoalLineOptions_MonthlyAverage,
    activityTracker_Chart_GoalLineOptions_YearlyAverage,
    activityTracker_Chart_GoalLineOptions_AllTimeAverage,
    activityTracker_Chart_GoalLineOptions_LAST
};

enum activityTracking_CellsEnum
{
    activityTracking_Cells_Switcher = 0,
    activityTracking_Cells_Steps,
    activityTracking_Cells_Calories,
    activityTracking_Cells_Distance,
    activityTracking_Cells_Sleep,//TestLog_SleepTrackerImplementation
    activityTracking_CellsEnum_LAST
};

enum activityTrackingSleepTracker_CellsEnum
{
    activityTrackingSleepTracker_Cells_Steps   = 0,
    activityTrackingSleepTracker_Cells_Distance,
    activityTrackingSleepTracker_Cells_Calories,
    activityTrackingSleepTracker_Cells_Sleep,//TestLog_SleepTrackerImplementation
    //activityTrackingSleepTracker_Cells_Switcher,
    activityTrackingSleepTracker_CellsEnum_LAST
};

//TestLog_Sleeptracker
enum appSettingsM372Sleeptracker_PropertyClass
{
    appSettingsM372Sleeptracker_PropertyClass_UserInformation = 0,
    appSettingsM372Sleeptracker_PropertyClass_Activity,
    appSettingsM372Sleeptracker_PropertyClass_Advanced,
    appSettingsM372Sleeptracker_PropertyClass_LAST
};
enum appSettingsM372Sleeptracker_PropertyClass_UserInformation
{
    appSettingsM372Sleeptracker_PropertyClass_UserInformation_User_Name = 0,
    appSettingsM372Sleeptracker_PropertyClass_UserInformation_BirthDate,
    appSettingsM372Sleeptracker_PropertyClass_UserInformation_Height,
    appSettingsM372Sleeptracker_PropertyClass_UserInformation_Weight,
    appSettingsM372Sleeptracker_PropertyClass_UserInformation_Gender,
    appSettingsM372Sleeptracker_PropertyClass_UserInformation_Units,
    appSettingsM372Sleeptracker_PropertyClass_UserInformation_BedTime,
    appSettingsM372Sleeptracker_PropertyClass_UserInformation_AwakeTime,
    appSettingsM372Sleeptracker_PropertyClass_UserInformation_LAST
};
enum appSettingsM372Sleeptracker_PropertyClass_SleepEnum
{
    appSettingsM372_PropertyClass_ActivityTracking_BedHour,
    appSettingsM372_PropertyClass_ActivityTracking_BedMinute,
    appSettingsM372_PropertyClass_ActivityTracking_AwakeHour,
    appSettingsM372_PropertyClass_ActivityTracking_AwakeMinute,
};
enum appSettingsM372Sleeptracker_PropertyClass_TrackSleepEnum
{
    appSettingsM372_PropertyClass_ActivityTracking_AllDay = 0,
    appSettingsM372_PropertyClass_ActivityTracking_DuringBedTime,
    appSettingsM372_PropertyClass_ActivityTracking_LAST,
};
enum appSettingsM372Sleeptracker_PropertyClass_Activity
{
    appSettingsM372Sleeptracker_PropertyClass_Activity_Steps = 0,
    appSettingsM372Sleeptracker_PropertyClass_Activity_Distance,
    appSettingsM372Sleeptracker_PropertyClass_Activity_Calories,
    appSettingsM372Sleeptracker_PropertyClass_Activity_Sleep,
    appSettingsM372Sleeptracker_PropertyClass_Activity_Sensor_Sensitivity,
    appSettingsM372Sleeptracker_PropertyClass_Activity_Distance_Adjustment,
    appSettingsM372Sleeptracker_PropertyClass_Activity_TrackSleep,
    appSettingsM372Sleeptracker_PropertyClass_Activity_LAST
};

enum appSettingsM372Sleeptracker_PropertyClass_Activity_New
{
    appSettingsM372Sleeptracker_PropertyClass_Activity_New_Sensor_Sensitivity = 0,
    appSettingsM372Sleeptracker_PropertyClass_Activity_New_Distance_Adjustment,
    appSettingsM372Sleeptracker_PropertyClass_Activity_New_TrackSleep,
    appSettingsM372Sleeptracker_PropertyClass_Activity_New_LAST
};

enum appSettingsM372Sleeptracker_PropertyClass_AdvancedEnum
{
    appSettingsM372Sleeptracker_PropertyClass_Advanced_AlignHands = 0,
    appSettingsM372Sleeptracker_PropertyClass_Advanced_CheckFirmware,
    appSettingsM372Sleeptracker_PropertyClass_Advanced_Remove_Watch,
    appSettingsM372Sleeptracker_PropertyClass_Advanced_Factory_Reset,
    appSettingsM372Sleeptracker_PropertyClass_Advanced_LAST
};

enum programWatchActivityTrackerSleep_PropertyClass_General_UnitsEnum
{
    programWatchActivityTrackerSleep_PropertyClass_General_Units_Imperial = 0,
    programWatchActivityTrackerSleep_PropertyClass_General_Units_Metric,
    programWatchActivityTrackerSleep_PropertyClass_General_Units_LAST
};

enum programWatchM372Sleep_PropertyClass_Activity_SensorSensitivityEnum
{
    programWatchM372Sleep_PropertyClass_Activity_SensorSensitivityLow = 0,
    programWatchM372Sleep_PropertyClass_Activity_SensorSensitivityMedium,
    programWatchM372Sleep_PropertyClass_Activity_SensorSensitivityHigh,
    programWatchM372Sleep_PropertyClass_Activity_SensorSensitivityLAST
};


enum syncActionsEnum
{
    syncActionsEnum_Unselected = 0,
    syncActionsEnum_WatchOverPhone,
    syncActionsEnum_PhoneOverWatch
};


enum programWatchM328_PropertyClass
{
    programWatchM328_PropertyClass_UserInfo = 0,
    programWatchM328_PropertyClass_ActivityTracking,
    programWatchM328_PropertyClass_General,
    programWatchM328_PropertyClass_Activity,
    programWatchM328_PropertyClass_ActivityDisplay,
    programWatchM328_PropertyClass_AutoSynchPeriod,
    programWatchM328_PropertyClass_DeclanationAdjustment,
    programWatchM328_PropertyClass_WatchInfo,
    SYSBLOCK_WatchInfo,
    programWatchM328_PropertyClass_LAST
};
enum programWatchM328_PropertyClass_DeclanationAdjustment
{
    programWatchM328_PropertyClass_DeclanationAdjustment_Default = 0,
    
};
enum programWatchM328_PropertyClass_AutoSynchPeriod
{
    programWatchM328_PropertyClass_AutoSynchPeriod_Default = 1,
    
};
enum programWatchM328_PropertyClass_Activity
{
    programWatchM328_PropertyClass_ActivityEnabled = 0,
    programWatchM328_PropertyClass_ActivityDisabled
};

enum programWatchM328_PropertyClass_ActivityDisplay
{
    programWatchM328_PropertyClass_ActivityDisplay_stepGoal = 0,
    programWatchM328_PropertyClass_ActivityDisplay_distanceGoal,
    programWatchM328_PropertyClass_ActivityDisplay_caloriesGoal,
    programWatchM328_PropertyClass_ActivityDisplay_Steps,
    programWatchM328_PropertyClass_ActivityDisplay_Distance,
    programWatchM328_PropertyClass_ActivityDisplay_Calories
};

enum appSettingsM328_PropertyClass
{
    appSettingsM328_PropertyClass_General = appSettings_PropertyClass_General,
    appSettingsM328_PropertyClass_Goals,
    appSettingsM328_PropertyClass_Advanced,
    appSettingsM328_PropertyClass_LAST
};

enum appSettingsM328_PropertyClass_GoalsEnum
{
    appSettingsM328_PropertyClass_Goals_Steps = 0,
    appSettingsM328_PropertyClass_Goals_Distance,
    appSettingsM328_PropertyClass_Goals_Calories,
    appSettingsM328_PropertyClass_Goals_Sleep,
    appSettingsM328_PropertyClass_Goals_LAST
};

enum programWatchM328_PropertyClass_UserInfoEnum
{
    programWatchM328_PropertyClass_UserInfo_Age = 0,
    programWatchM328_PropertyClass_UserInfo_Height,
    programWatchM328_PropertyClass_UserInfo_Weight,
    programWatchM328_PropertyClass_UserInfo_Gender,
    programWatchM328_PropertyClass_UserInfo_Name,
    programWatchM328_PropertyClass_UserInfo_DOB,
    programWatchM328_PropertyClass_UserInfo_Goal_Type,
    programWatchM328_PropertyClass_UserInfo_LAST
};

enum programWatchM328_PropertyClass_ActivityTrackingEnum
{
    programWatchM328_PropertyClass_ActivityTracking_SensorSensitivity = 0,
    programWatchM328_PropertyClass_ActivityTracking_DistanceAdjustment,
    programWatchM328_PropertyClass_ActivityTracking_BedHour,
    programWatchM328_PropertyClass_ActivityTracking_BedMinute,
    programWatchM328_PropertyClass_ActivityTracking_AwakeHour,
    programWatchM328_PropertyClass_ActivityTracking_AwakeMinute,
    programWatchM328_PropertyClass_ActivityTracking_SleepTracking,
    programWatchM328_PropertyClass_ActivityTracking_LAST
};

enum programWatchM328_PropertyClass_GeneralEnum
{
    programWatchM328_PropertyClass_General_UnitOfMeasure = 0,
    programWatchM328_PropertyClass_General_SyncNeeded,
    programWatchM328_PropertyClass_General_LAST
};

enum programWatchM328_PropertyClass_WatchInfoEnum
{
    programWatchM328_PropertyClass_ActivityEnable = 0,
    programWatchM328_PropertyClass_ActivityDisplaySubdial,
    programWatchM328_PropertyClass_AlarmHour,
    programWatchM328_PropertyClass_AlarmMinute,
    programWatchM328_PropertyClass_AlarmFrequency,
    programWatchM328_PropertyClass_AlarmStatus,
    programWatchM328_PropertyClass_TimerHour,
    programWatchM328_PropertyClass_TimerMinute,
    programWatchM328_PropertyClass_TimerSeconds,
    programWatchM328_PropertyClass_TimerAction,
    programWatchM328_PropertyClass_TimerEnable,
    programWatchM328_PropertyClass_TZPrimeayOffset1,
    programWatchM328_PropertyClass_TZPrimaryDSTOffset1,
    programWatchM328_PropertyClass_TZPrimeayOffset2,
    programWatchM328_PropertyClass_TZPrimaryDSTOffset2,
    programWatchM328_PropertyClass_SecondHandMode,
    programWatchM328_PropertyClass_AutoSynchMode,
    programWatchM328_PropertyClass_AutoSyncPeriod,
    programWatchM328_PropertyClass_AutoSyncTimes1_Seconds,
    programWatchM328_PropertyClass_AutoSyncTimes1_Minutes,
    programWatchM328_PropertyClass_AutoSyncTimes1_Hours,
    programWatchM328_PropertyClass_AutoSyncTimes1_TimeEnabled,
    programWatchM328_PropertyClass_AutoSyncTimes2_Seconds,
    programWatchM328_PropertyClass_AutoSyncTimes2_Minutes,
    programWatchM328_PropertyClass_AutoSyncTimes2_Hours,
    programWatchM328_PropertyClass_AutoSyncTimes2_TimeEnabled,
    programWatchM328_PropertyClass_AutoSyncTimes3_Seconds,
    programWatchM328_PropertyClass_AutoSyncTimes3_Minutes,
    programWatchM328_PropertyClass_AutoSyncTimes3_Hours,
    programWatchM328_PropertyClass_AutoSyncTimes3_TimeEnabled,
    programWatchM328_PropertyClass_AutoSyncTimes4_Seconds,
    programWatchM328_PropertyClass_AutoSyncTimes4_Minutes,
    programWatchM328_PropertyClass_AutoSyncTimes4_Hours,
    programWatchM328_PropertyClass_AutoSyncTimes4_TimeEnabled,
    programWatchM328_PropertyClass_DoNotDisturbStartSeconds,
    programWatchM328_PropertyClass_DoNotDisturbStartMinutes,
    programWatchM328_PropertyClass_DoNotDisturbStartHours,
    programWatchM328_PropertyClass_DoNotDisturbEndSeconds,
    programWatchM328_PropertyClass_DoNotDisturbEndMinutes,
    programWatchM328_PropertyClass_DoNotDisturbEndHours,
    programWatchM328_PropertyClass_DoNotDisturbEnable,
    programWatchM328_PropertyClass_AutoSyncNotification,
    programWatchM328_PropertyClass_batteryVolt,
    programWatchM328_PropertyClass_timerTemp,
    programWatchM328_PropertyClass_WatchInfo_LAST
};

enum SYSBLOCK_WatchInfoEnum
{
    SYSBLOCK_Checksum,
    SYSBLOCK_BootLoaderState,
    SYSBLOCK_ModelNumber,
    SYSBLOCK_Revision,
    SYSBLOCK_BoardSerialNumber,
    SYSBLOCK_BootLoaderRevision,
    SYSBLOCK_SystemHealthRevision,
    SYSBLOCK_WatchdogResets,
    SYSBLOCK_PowerOnResets,
    SYSBLOCK_LowPowerResets,
    SYSBLOCK_SystemResets,
    SYSBLOCK_NumberOfCalibrations,
    SYSBLOCK_ResetWarning,
    SYSBLOCK_NumOfWarnings,
    SYSBLOCK_StoredNames,
    SYSBLOCK_CurrentWatchdogResets,
    SYSBLOCK_CurrentPowerOnResets,
    SYSBLOCK_CurrentLowPowerResets,
    SYSBLOCK_CurrentSystemResets,
    SYSBLOCK_WarningTriggered,
    SYSBLOCK_LAST
};

enum programWatchM329_PropertyClass
{
    programWatchM329_PropertyClass_UserInfo = 0,
    programWatchM329_PropertyClass_ActivityTracking,
    programWatchM329_PropertyClass_General,
    programWatchM329_PropertyClass_Activity,
    programWatchM329_PropertyClass_ActivityDisplay,
    programWatchM329_PropertyClass_AutoSynchPeriod,
    programWatchM329_PropertyClass_DeclanationAdjustment,
    programWatchM329_PropertyClass_WatchInfo,
    programWatchM329_PropertyClass_LAST
};
enum programWatchM329_PropertyClass_DeclanationAdjustment
{
    programWatchM329_PropertyClass_DeclanationAdjustment_Default = 0,
    
};
enum programWatchM329_PropertyClass_AutoSynchPeriod
{
    programWatchM329_PropertyClass_AutoSynchPeriod_Default = 1,
    
};
enum programWatchM329_PropertyClass_Activity
{
    programWatchM329_PropertyClass_ActivityEnabled = 0,
    programWatchM329_PropertyClass_ActivityDisabled
};

/*
enum programWatchM329_PropertyClass_ActivityDisplay
{
    programWatchM329_PropertyClass_ActivityDisplay_stepGoal = 0,
    programWatchM329_PropertyClass_ActivityDisplay_distanceGoal,
    programWatchM329_PropertyClass_ActivityDisplay_caloriesGoal,
    programWatchM329_PropertyClass_ActivityDisplay_Steps,
    programWatchM329_PropertyClass_ActivityDisplay_Distance,
    programWatchM329_PropertyClass_ActivityDisplay_Calories
};
 */

enum appSettingsM329_PropertyClass
{
    appSettingsM329_PropertyClass_General = appSettings_PropertyClass_General,
    appSettingsM329_PropertyClass_Goals,
    appSettingsM329_PropertyClass_Advanced,
    appSettingsM329_PropertyClass_LAST
};

enum appSettingsM329_PropertyClass_GoalsEnum
{
    appSettingsM329_PropertyClass_Goals_Steps = 0,
    appSettingsM329_PropertyClass_Goals_Distance,
    appSettingsM329_PropertyClass_Goals_Calories,
    appSettingsM329_PropertyClass_Goals_Sleep,
    appSettingsM329_PropertyClass_Goals_LAST
};

enum programWatchM329_PropertyClass_ActivityTrackingEnum
{
    programWatchM329_PropertyClass_ActivityTracking_SensorSensitivity = 0,
    programWatchM329_PropertyClass_ActivityTracking_DistanceAdjustment,
    programWatchM329_PropertyClass_ActivityTracking_BedHour,
    programWatchM329_PropertyClass_ActivityTracking_BedMinute,
    programWatchM329_PropertyClass_ActivityTracking_AwakeHour,
    programWatchM329_PropertyClass_ActivityTracking_AwakeMinute,
    programWatchM329_PropertyClass_ActivityTracking_SleepTracking,
    programWatchM329_PropertyClass_ActivityTracking_LAST
};

enum programWatchM329_PropertyClass_GeneralEnum
{
    programWatchM329_PropertyClass_General_UnitOfMeasure = 0,
    programWatchM329_PropertyClass_General_SyncNeeded,
    programWatchM329_PropertyClass_General_LAST
};

enum programWatchM329_PropertyClass_WatchInfoEnum
{
    programWatchM329_PropertyClass_ActivityEnable = 0,
    programWatchM329_PropertyClass_ActivityDisplaySubdial,
    programWatchM329_PropertyClass_AlarmHour,
    programWatchM329_PropertyClass_AlarmMinute,
    programWatchM329_PropertyClass_AlarmFrequency,
    programWatchM329_PropertyClass_AlarmStatus,
    programWatchM329_PropertyClass_TimerHour,
    programWatchM329_PropertyClass_TimerMinute,
    programWatchM329_PropertyClass_TimerSeconds,
    programWatchM329_PropertyClass_TimerAction,
    programWatchM329_PropertyClass_TimerEnable,
    programWatchM329_PropertyClass_TZPrimeayOffset1,
    programWatchM329_PropertyClass_TZPrimaryDSTOffset1,
    programWatchM329_PropertyClass_TZPrimeayOffset2,
    programWatchM329_PropertyClass_TZPrimaryDSTOffset2,
    programWatchM329_PropertyClass_TZPrimeayOffset3,
    programWatchM329_PropertyClass_TZPrimaryDSTOffset3,
    programWatchM329_PropertyClass_TZPrimaryName1,
    programWatchM329_PropertyClass_TZPrimaryName2,
    programWatchM329_PropertyClass_TZPrimaryName3,
    programWatchM329_PropertyClass_SecondHandMode,
    programWatchM329_PropertyClass_AutoSynchMode,
    programWatchM329_PropertyClass_AutoSyncPeriod,
    programWatchM329_PropertyClass_AutoSyncTimes1_Seconds,
    programWatchM329_PropertyClass_AutoSyncTimes1_Minutes,
    programWatchM329_PropertyClass_AutoSyncTimes1_Hours,
    programWatchM329_PropertyClass_AutoSyncTimes1_TimeEnabled,
    programWatchM329_PropertyClass_AutoSyncTimes2_Seconds,
    programWatchM329_PropertyClass_AutoSyncTimes2_Minutes,
    programWatchM329_PropertyClass_AutoSyncTimes2_Hours,
    programWatchM329_PropertyClass_AutoSyncTimes2_TimeEnabled,
    programWatchM329_PropertyClass_AutoSyncTimes3_Seconds,
    programWatchM329_PropertyClass_AutoSyncTimes3_Minutes,
    programWatchM329_PropertyClass_AutoSyncTimes3_Hours,
    programWatchM329_PropertyClass_AutoSyncTimes3_TimeEnabled,
    programWatchM329_PropertyClass_AutoSyncTimes4_Seconds,
    programWatchM329_PropertyClass_AutoSyncTimes4_Minutes,
    programWatchM329_PropertyClass_AutoSyncTimes4_Hours,
    programWatchM329_PropertyClass_AutoSyncTimes4_TimeEnabled,
    programWatchM329_PropertyClass_DoNotDisturbStartSeconds,
    programWatchM329_PropertyClass_DoNotDisturbStartMinutes,
    programWatchM329_PropertyClass_DoNotDisturbStartHours,
    programWatchM329_PropertyClass_DoNotDisturbEndSeconds,
    programWatchM329_PropertyClass_DoNotDisturbEndMinutes,
    programWatchM329_PropertyClass_DoNotDisturbEndHours,
    programWatchM329_PropertyClass_DoNotDisturbEnable,
    programWatchM329_PropertyClass_AutoSyncNotification,
    programWatchM329_PropertyClass_batteryVolt,
    programWatchM329_PropertyClass_timerTemp,
    programWatchM329_PropertyClass_PB4DisplayFunction,
    programWatchM329_PropertyClass_MidnightLocation,
    programWatchM329_PropertyClass_TZPrimaryDSTiOSName2,
    programWatchM329_PropertyClass_TZPrimaryDSTiOSName3,
    programWatchM329_PropertyClass_WatchInfo_LAST
};

@interface iDevicesUtil : NSObject

+ (CGFloat) device_window_height;
+ (CGFloat) device_window_width;


//[UIScreen mainScreen] contains status bar as well, if you want to retrieve the frame for your application (excluding status bar) you should use
+ (CGFloat) window_height;  
+ (CGFloat) window_width;

+ (NSString *)getViewControllerToPush:(Class)aClass;
+ (UIButton *) getNavBarButtonBasedOnText: (NSString *) text;
+ (int) getRandomInRangeFrom:(int) min To:(int)max;
+ (NSString *)stringFromTimeInterval:(NSTimeInterval)interval;
+ (NSString *)stringFromTimeIntervalNoMilliseconds:(NSTimeInterval)interval;
+ (NSInteger) daysBetweenThis:(NSDate *)dt1 andThat:(NSDate *)dt2;

+(NSString *) getUserAppUnitMode;
+(void) saveUserAppUnitMode:(NSString *)mode;

+(NSString *) getAppWideFontName;
+(NSString *) getAppWideBoldFontName;
+(NSString *) getAppWideMediumFontName;

+ (NSString*) appVersionString;

+ (NSString*) convertTimexModuleStringToProductName: (NSString *) module;
+ (NSString*) convertWatchStyleToProductName: (timexDatalinkWatchStyle) module;
+ (BOOL) isCurrentTimeFormat24HR;

+ (BOOL) isActivityTrackerUnitsOfMeasureImperial;
+ (float) convertCentimetersToInches: (float) centimeters;
+ (float) convertInchesToCentimeters: (float) inches;
+ (float) convertKilogramsToPounds: (float) kilos;
+ (float) convertPoundsToKilograms: (float) pounds;
+ (double) convertKilometersToMiles: (double) kilos;
+ (double) convertMilesToKilometers: (double) miles;

+(BOOL) checkForActiveProfilePresence;
+(timexDatalinkWatchStyle) getActiveWatchProfileStyle;

+(BOOL) isSocialMediaImageSharingAllowed;

+(NSString *) createKeyForWatchControlPropertyWithClass: (NSInteger) propClass andIndex: (NSInteger) index;
+(NSString *) createKeyForAppSettingsPropertyWithClass: (NSInteger) propClass andIndex: (NSInteger) index;
+(NSString *) createKeyForUploadSiteSetting: (TimexUploadServicesOptions) propClass andIndex: (uploadSites_PropertyClass_settingTypeEnum) index;
+ (NSString *) convertUnitsOfMeasureSettingToString: (programWatchActivityTracker_PropertyClass_General_UnitsEnum) setting;
+ (NSString *) convertUnitsOfMeasureSettingToStringSleep:(programWatchActivityTrackerSleep_PropertyClass_General_UnitsEnum) setting;//TestLog_SleepTracker
+ (NSString *) convertM372TrackSleepSettingToString: (appSettingsM372Sleeptracker_PropertyClass_TrackSleepEnum)setting;
+ (NSString *) convertUserGenderSettingToString: (programWatchActivityTracker_PropertyClass_UserInfo_GenderEnum) setting;
+ (NSString *) convertIntervalTimerLabelSettingToString: (programWatch_PropertyClass_IntervalTimer_LabelEnum)setting;
+ (NSString *) convertTimeOfDayWatchTimeSyncSettingToString: (programWatch_PropertyClass_TimeOfDay_FollowPhoneTimeEnum) setting;
+ (NSString *) convertTimeOfDayTimeZoneTimeFormatSettingToString: (programWatch_PropertyClass_TimeOfDay_TZTimeFormatEnum) setting;
+ (NSString *) convertTimeOfDayTimeZoneDateFormatSettingToString: (programWatch_PropertyClass_TimeOfDay_TZDateFormatEnum) setting;
+ (NSString *) convertTimeOfDayTimeZoneOtherDateFormatSettingToString: (programWatch_PropertyClass_TimeOfDay_TZOtherDateFormatEnum) setting;
+ (NSString *) convertM053TimeOfDayTimeZoneDateFormatSettingToString: (programWatchM053_PropertyClass_TimeOfDay_TZDateFormatEnum) setting;
+ (NSString *) convertM053GoalsStatusSettingToString: (programWatchM053_PropertyClass_GoalsStatusEnum) setting;
+ (NSString *) convertM053SensorSensitivitySettingToString: (programWatchM053_PropertyClass_Activity_SensorSensitivityEnum)setting;
+ (NSString *) convertM372TimeOfDayTimeZoneDateFormatSettingToString: (programWatchM372_PropertyClass_TimeOfDay_TZDateFormatEnum) setting;
+ (NSString *) convertM372SensorSensitivitySettingToString: (programWatchM372_PropertyClass_Activity_SensorSensitivityEnum)setting;
+ (NSString *) convertAlarmFrequencySettingToString: (programWatch_PropertyClass_Alarm_FrequencyEnum) setting;
+ (NSString *) convertAlarmFrequencySettingM053ToString: (programWatchM053_PropertyClass_Alarm_FrequencyEnum) setting;
+ (NSString *) convertIntervalTimerActionAtEndM053ToString: (programWatchM053_PropertyClass_IntervalTimers_ActionAtEndEnum) setting;
+ (NSString *) convertAlarmFrequencySettingM372ToString: (programWatchM372_PropertyClass_Alarm_FrequencyEnum) setting;
+ (NSString *) convertIntervalTimerActionAtEndM372ToString: (programWatchM372_PropertyClass_IntervalTimers_ActionAtEndEnum) setting;
+ (NSString *) convertAlarmAlertSettingToString: (programWatch_PropertyClass_Alarm_AlertEnum) setting;
+ (NSString *) convertNotificationsAlertSettingToString: (programWatch_PropertyClass_Notifications_AlertEnum) setting;
+ (NSString *) convertSortTypeSettingToString: (appSettings_PropertyClass_Workouts_SortTypeEnum) setting;
+ (NSString *) convertStoreHistorySettingToString: (appSettings_PropertyClass_Workouts_StoreHistoryEnum) setting;
+ (NSString *) convertLapSplitDisplayFormatSettingToString: (appSettingsM053_PropertyClass_Workouts_LapSplitDisplayEnum) setting;
+ (NSString *) convertUploadSiteSettingToString: (TimexUploadServicesOptions) setting;
+ (NSURL *)    getURLforUploadSiteSetting: (TimexUploadServicesOptions) setting;
+ (NSString *) convertAlarmTimeSettingToString: (calendar_alarmTimeOptions) setting;
+ (NSString *) convertTimexRingtoneSettingToString: (appSettings_PropertyClass_PhoneFinderTimexRingtoneEnum) setting;
+ (NSString *) convertTimexRingtoneSettingToLocalizedString: (appSettings_PropertyClass_PhoneFinderTimexRingtoneEnum) setting;
+ (NSString *) convertGeneralLightModeSettingToString: (programWatch_PropertyClass_General_LightModeEnum)setting;
+ (NSString *) convertGeneralTapForceSettingToString: (programWatch_PropertyClass_General_TapForceEnum)setting;
+ (NSString *) convertGeneralTextColorSettingToString: (programWatch_PropertyClass_General_TextColorEnum)setting;
+ (NSString *) convertGeneralLanguageSettingToString: (programWatch_PropertyClass_General_LanguageEnum)setting;

+ (NSString *) convertActivityTrackerGoalLineOptionToString: (activityTracker_Chart_GoalLineOptions) setting forMetric: (activityTracking_CellsEnum) metricType;
    
+ (void) UpdateCustomAlarmTimeForEvent: (EKEvent *) wantsNewAlarm withAlarmIndex: (calendar_alarmTimeOptions) idx;
+ (void) AddExcludedCalendarEvent: (EKEvent *) excludedEvent;

+ (const char *)centralManagerStateToString: (int)state;
+ (const char *)UUIDToString:(CFUUIDRef)UUID;
+ (const char *)CBUUIDToString:(CBUUID *) UUID;
+ (int)compareCBUUID:(CBUUID *) UUID1 UUID2:(CBUUID *)UUID2;
+ (CBService *)findServiceFromUUID:(CBUUID *)UUID p:(CBPeripheral *)p;
+ (CBCharacteristic *)findCharacteristicFromUUID:(CBUUID *)UUID service:(CBService*)service;
+ (NSArray *) getDeviceFeatureDataForDevice:(NSString*) deviceTypeStr;
+ (NSDictionary *) getFeatureData:(NSString*) featureTypeStr;
+ (BOOL) shouldIncludeDerivedData;
+ (BOOL) isDerivedFeatureType: (NSString *) fType;
+ (NSString*) generateGUID;
+ (NSData *)convertOutgoingCommandsToNSData:(TDDeviceCommands) commandsSet;
+ (NSData *) convertOutgoingDateToData:(NSDate *) date;
+ (TDRootViewController *) launchAppWebViewerWithURL: (NSURL *) url forViewController: (UIViewController *) vc isEula:(BOOL)eula;

+ (NSTimeInterval) getSecondsValueForAlarmSetting: (calendar_alarmTimeOptions) setting;
+ (calendar_alarmTimeOptions) getEventAlarmTime: (EKEvent *) eventToProcess;
+ (NSTimeInterval) getEventAlarmTimeInSeconds: (EKEvent *) eventToProcess;

+ (programWatchM053_PropertyClass_Activity_SensorSensitivityEnum) getM053CurrentSensorSensitivity;
+ (programWatchM372_PropertyClass_Activity_SensorSensitivityEnum) getM372CurrentSensorSensitivity;
+ (BOOL) isSensorEnabled;
+ (BOOL) areStepsEnabled;
+ (BOOL) isDistanceEnabled;
+ (BOOL) areCaloriesEnabled;
+ (NSInteger) getAverageStepsSince: (NSTimeInterval) since toDate: (NSTimeInterval) to;
+ (NSInteger) getAverageCaloriesSince: (NSTimeInterval) since toDate: (NSTimeInterval) to;
+ (NSInteger) getAverageDistanceSince: (NSTimeInterval) since toDate: (NSTimeInterval) to;
+ (NSInteger) getTodaysStepsCount;

+ (NSInteger) getStepsCountForDay;//TestLog

+ (NSInteger) getTodaysCaloriesCount;
+ (NSInteger) getTodaysDistance;
+ (NSInteger) calculateNumberOfDaysBetweenDate: (NSDate *) startDate andDate: (NSDate *) endDate;
+ (NSArray *) getStepsDataSinceDate: (NSTimeInterval) since toDate: (NSTimeInterval) to;
+ (NSArray *) getCaloriesDataSinceDate: (NSTimeInterval) since toDate: (NSTimeInterval) to;
+ (NSArray *) getDistanceDataSinceDate: (NSTimeInterval) since toDate: (NSTimeInterval) to;
+ (NSInteger) getStepsSinceDate: (NSTimeInterval) since toDate: (NSTimeInterval) to;
+ (NSInteger) getCaloriesSinceDate: (NSTimeInterval) since toDate: (NSTimeInterval) to;
+ (NSInteger) getDistanceSinceDate: (NSTimeInterval) since toDate: (NSTimeInterval) to;
+ (NSInteger) getStepsPercentage: (NSInteger) steps forRangeFrom: (NSTimeInterval) rangeStart to: (NSTimeInterval) rangeEnd;
+ (NSInteger) getCaloriesPercentage: (NSInteger) calories forRangeFrom: (NSTimeInterval) rangeStart to: (NSTimeInterval) rangeEnd;
+ (NSInteger) getDistancePercentage: (NSInteger) distance forRangeFrom: (NSTimeInterval) rangeStart to: (NSTimeInterval) rangeEnd;
+ (NSInteger) getNumberOfActivityRecordsSinceDate: (NSTimeInterval) since toDate: (NSTimeInterval) to;
+ (NSInteger) getDistanceForWorkout: (TDWorkoutData *) workout;

+ (BOOL) isOtherTimeSetToTimeZone;
+ (BOOL) isAlarm1Enabled;
+ (BOOL) isAlarm2Enabled;
+ (BOOL) isAlarm3Enabled;
+ (BOOL) isInterval1Enabled;
+ (BOOL) isInterval2Enabled;
+ (BOOL) isNotificationsEnabled;
+ (BOOL) isDNDEnabled;

+ (BOOL) IsValidEmail:(NSString *)checkString;
+ (BOOL) hasInternetConnectivity;

+ (void) generateDummyWorkouts: (NSInteger) howMany spanInDays: (NSInteger) howManyDays maximumNumberOfLaps: (NSInteger) lapsNumber;
+ (void) generateDummyActivityData: (NSInteger) howManyDays;

+ (int) calculateTimexCRC32: (Byte *) inBytes withLength: (int) inLen;
+ (int) calculateTimexM053Checksum: (Byte *) inBytes withLength: (int) inLen;
+ (UInt32) calculateChecksum: (Byte *) bytes withLength: (int) length;

+ (PeripheralDevice *) getConnectedTimexDevice;
+ (NSData *) longToByteArray: (long) i;
+ (NSData *) intToByteArray: (int) i;
+ (NSData *) shortToByteArray: (short) i;
+ (int) byteArrayToInt: (Byte *) b;
+ (long) byteArrayToLong: (Byte *) b;
+ (short) byteArrayToShort: (Byte *) b;
+ (int) byteArrayToIntRevesre: (Byte *) b;

+(void) dumpData:(NSData *)data;
+(void) logFlurryEvent:(NSString *)event withParameters:(NSDictionary*)params isTimedEvent: (BOOL) isTimed;
+(void) endTimedFlurryEvent:(NSString *)event withParameters:(NSDictionary*)params;

+(NSDateFormatter *) getDateFormatter: (BOOL) twoLines;

+ (NSDate *) todayDateAtMidnight;
+ (UIColor *) getM053ActivityColorBasedOnPercentage: (NSInteger) percentage;
+ (NSString *) getDefaultSocialMediaPostingString: (TDWorkoutData *) workoutToShare;

+ (UIImage *)imageWithColor:(UIColor *)color;

+ (UIColor *) getTimexRedColor;
//diegoSantaigo_SleepTracker
+ (programWatchM372Sleep_PropertyClass_Activity_SensorSensitivityEnum) getM372CurrentSensorSensitivitySleep;
+ (NSString *) convertM372SensorSensitivitySettingToStringSleep:(programWatchM372Sleep_PropertyClass_Activity_SensorSensitivityEnum)setting
;
+ (NSString *) appVersionStringSleepTracker;
+ (UIImageView *)getNavigationTitle;
+ (UIButton *)getBackButton;
+(NSDate *)getWeekStartDate:(NSDate *)date;

+ (NSDate *)getWeekEndDate:(NSDate *)date;
+ (NSDate *)getFirstDateOfPreviousMonth:(NSDate *)date;
+ (NSDate *)getFirstDateOfNextMonth:(NSDate *)date;
+ (NSDate *)getFirstDateInMonth:(NSDate *)date;
+ (NSDate *)getFirstDateInYear:(NSDate *)date;
+ (NSDate *)getLastDateInMonth:(NSDate *)date;
+ (NSDate *)getLastDateInYear:(NSDate *)date;
+ (NSDate *)getFirstDateOfPreviousYear:(NSDate *)date;
+ (NSDate *)getFirstDateOfNextYear:(NSDate *)date;
+ (NSDate *) yesterdayDateAtMidnight;
+ (UIImage *)imageFromColor:(UIColor *)color;
+ (NSString *) getAppWideItalicFontName;
+ (CGFloat)getProgressBarValueBasedOnRegistrationEnum:(enum RegistartionProgressValues)enumValue ;
+ (NSAttributedString *)getAttributedStrWithText:(NSString *)textStr highLightStr:(NSString *)highLightStr;
+ (UIColor *) getActivityColorBasedOnPercentage: (CGFloat) percentage andType:(NSString *)activityType;
+ (void)showProgressHUDInView:(UIView *)view withText:(NSString *)text;
+ (void)removeProgressHUDInView:(UIView *)view;
+ (NSString *)getSettingType:(enum SettingType)type;
+ (NSString *)getGenderInStringFormat:(enum General_Gender)gender;
+ (NSString *)getUnitsInStringFormat:(enum General_Units)units;
+ (NSString *)getSensorSensitivityStringFormat:(enum SensorType)goalType;
+ (NSString *)convertInchToFeet:(float)inch;
+ (NSString *)convertCMToMeters:(NSInteger)cms;
+ (int)getCurrentLocaleUnitSystem;

+ (NSDate *) onlyDateFormat:(NSDate *)date;
+ (NSString *)convertMinutesToStringHHMMFormat:(NSTimeInterval)totalTimeIntr;
+ (NSString *)convertMinutesToStringHHDecimalFormat:(NSTimeInterval)totalTimeIntr;
+ (NSTimeInterval)getTimeIntervalInDateFormatOnly:(NSDate *)date;

+ (NSDate *) getDateAtFirstMinute:(NSDate *)dateselected;
+ (NSDate *) getDateAtLastMinute:(NSDate *)dateselected;
+ (BOOL)isMetricSystem;

+(NSArray *)convertEpochStringToSegments:(NSString*)epochString;
+(NSDate *)getPreviousDate:(NSDate *)date;
+ (NSString *)getGoalTypeStringFormat:(GoalType)goalType;
+(void)setNavigationTitle:(NSString *)title forViewController:(UIViewController *)viewController;
+ (BOOL) isSystemTimeFormat24Hr;
+ (void)displayEULADetailsFromViewController:(UIViewController *)vc;
+ (BOOL)date:(NSDate*)date isBetweenDate:(NSDate*)beginDate andDate:(NSDate*)endDate;
+ (NSDate *)getHourDate:(NSDate *)selectedDate withSelectedTime:(NSString *)selectedTime;
+ (NSNumber *)getHourFromDate:(NSDate *)date;
+ (NSString *)getFirstLetterofTheDay:(NSDate *)date;
+ (NSInteger)getDayCountBetweenDates:(NSDate *)startDate enddate:(NSDate *)endDate;
+ (NSInteger)getWeekCountBetweenDates:(NSDate *)startDate enddate:(NSDate *)endDate;
+ (NSInteger)getMonthCountBetweenDates:(NSDate *)startDate enddate:(NSDate *)endDate;
+ (NSInteger)getYearCountBetweenDates:(NSDate *)startDate enddate:(NSDate *)endDate;
+ (NSComparisonResult)compareDateOnly:(NSDate *)firstDate AndEndDate:(NSDate *)secondDate;
+ (NSString *)getTimeFromHrValue:(int)hour formatInNewLine:(BOOL)formatInNewLine;
+ (NSString *)getWatchID;
@end
