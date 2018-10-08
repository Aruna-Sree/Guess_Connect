//
//  TDDatacastWatchSettings.m
//  Timex Connected
//
//  Created by Lev Verbitsky on 1/21/14.
//  Copyright (c) 2014 iDevices, LLC. All rights reserved.
//

#import "TDDatacastWatchSettings.h"
#import "PCCommCommands.h"
#import "iDevicesUtil.h"

@implementation TDDatacastInterval
    @synthesize enable = _enable;
    @synthesize label = _label;
    @synthesize interval = _interval;
@end

@implementation TDDatacastAlarm
    @synthesize enable = _enable;
    @synthesize hour = _hour;
    @synthesize minute = _minute;
    @synthesize repeatPattern = _repeatPattern;
@end

@implementation TDDatacastDND
    @synthesize hourStart = _hourStart;
    @synthesize minuteStart = _minuteStart;
    @synthesize hourEnd = _hourEnd;
    @synthesize minuteEnd = _minuteEnd;
@end


#define  FILE_FORMAT_VERSION  SETTINGS_VERSION
#define  FILE_DATA_SIZE                     132
#define  INTERVAL1_ENABLE_OFFSET            12
#define  INTERVAL2_ENABLE_OFFSET            13
#define  INTERVAL1_LABEL_OFFSET             18
#define  INTERVAL2_LABEL_OFFSET             19
#define  INTERVAL_REPEATS_OFFSET            24
#define  INTERVAL_VIBRATING_ALERTS_OFFSET   25
#define  INTERVAL_AUDIBLE_ALERTS_OFFSET     26
#define  INTERVAL1_DURATION_OFFSET          28
#define  INTERVAL2_DURATION_OFFSET          32
#define  GENERAL_PREFS_OFFSET               52
#define  LANGUAGE_PREF_OFFSET               53
#define  DATE_FORMAT_OFFSET                 60
#define  HOME_TIMEZONE_OFFSET               62
#define  AWAY_TIMEZONE_OFFSET               64
#define  ALARM_ENABLE_OFFSET                68
#define  ALARM_VIBRATING_ALERT_OFFSET       69
#define  ALARM_AUDIBLE_ALERT_OFFSET         70
#define  ALARM1_HOUR_OFFSET                 72
#define  ALARM1_MINUTE_OFFSET               73
#define  ALARM1_REPEATPATTERN_OFFSET        74
#define  ALARM2_HOUR_OFFSET                 75
#define  ALARM2_MINUTE_OFFSET               76
#define  ALARM2_REPEATPATTERN_OFFSET        77
#define  ALARM3_HOUR_OFFSET                 78
#define  ALARM3_MINUTE_OFFSET               79
#define  ALARM3_REPEATPATTERN_OFFSET        80
#define  DND_ENABLE_OFFSET                  96
#define  DND_HOUR_START_OFFSET              97
#define  DND_MINUTE_START_OFFSET            98
#define  DND_HOUR_STOP_OFFSET               99
#define  DND_MINUTE_STOP_OFFSET             100
#define  DND_VIBRATING_ALARM_OFFSET         101
#define  DND_AUDIBLE_ALARM_OFFSET           102


@implementation TDDatacastWatchSettings

@synthesize mChecksum;

- (id) init
    {
        if (self = [super init])
        {
            mFileFormatVersion = FILE_FORMAT_VERSION;
            mGeneralSettings = 0;
            
            mIntervals = [[NSMutableArray alloc] init];
            for (int i = 0; i < 2; i++)
            {
                TDDatacastInterval * newInt = [[TDDatacastInterval alloc] init];
                [mIntervals addObject: newInt];
            }
            
            mAlarms = [[NSMutableArray alloc] init];
            for (int i = 0; i < 3; i++)
            {
                TDDatacastAlarm * newAlarm = [[TDDatacastAlarm alloc] init];
                [mAlarms addObject: newAlarm];
            }
            
            mDND = [[TDDatacastDND alloc] init];
            
            //read from settings
            [self populateObjectWithSettingsOnPhone];
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

- (void) populateObjectWithSettingsOnPhone
{
    // General
    Byte bitField = 0;
    
    bitField = (Byte)([self GetBoolPropertyForClass: programWatch_PropertyClass_General andIndex: programWatch_PropertyClass_General_DisplayTextColor] == 1 ? 1 : 0);
    bitField |= (Byte)([self GetBoolPropertyForClass: programWatch_PropertyClass_General andIndex: programWatch_PropertyClass_General_ButtonBeep] ? 0x2 : 0);
    bitField |= (Byte)([self GetBoolPropertyForClass: programWatch_PropertyClass_General andIndex: programWatch_PropertyClass_General_HourlyChime] ? 0x4 : 0);
    switch( [self GetIntPropertyForClass: programWatch_PropertyClass_General andIndex: programWatch_PropertyClass_General_LightMode])
    {
        case programWatch_PropertyClass_General_LightModeManual: // tap only
            break;
        case programWatch_PropertyClass_General_LightModeNightMode: // night mode
            bitField |= 0x8;
            break;
        case programWatch_PropertyClass_General_LightModeAlwaysOn: // always on
            bitField |= 0x10;
            break;
    }
    
    switch( [self GetIntPropertyForClass: programWatch_PropertyClass_General andIndex: programWatch_PropertyClass_General_TapForce])
    {
        case programWatch_PropertyClass_General_TapForceLight:
            break;
        case programWatch_PropertyClass_General_TapForceMedium:
            bitField |= 0x20;
            break;
        case programWatch_PropertyClass_General_TapForceHard:
            bitField |= 0x40;
            break;
    }
    mGeneralSettings = bitField;
    mLanguage = (Byte)[self GetIntPropertyForClass: programWatch_PropertyClass_General andIndex: programWatch_PropertyClass_General_Language];
    
    // Time of Day
//    bitField = 0;
    bitField = (Byte)([self GetIntPropertyForClass: programWatch_PropertyClass_TimeOfDay andIndex: programWatch_PropertyClass_TimeOfDay_HomeTimeTimeFormat]);
    switch( [self GetIntPropertyForClass: programWatch_PropertyClass_TimeOfDay andIndex: programWatch_PropertyClass_TimeOfDay_HomeTimeDateFormat])
    {
        case programWatch_PropertyClass_TimeOfDay_TZDateFormatMMMDD:
            break;
        case programWatch_PropertyClass_TimeOfDay_TZDateFormatMMDDYY:
            bitField |= 0x2;
            break;
        case programWatch_PropertyClass_TimeOfDay_TZDateFormatDDMMYY:
            bitField |= 0x4;
            break;
        case programWatch_PropertyClass_TimeOfDay_TZDateFormatYYYYMMDD:
            bitField |= 0x6;
            break;
    }
    if ( [self GetIntPropertyForClass: programWatch_PropertyClass_TimeOfDay andIndex: programWatch_PropertyClass_TimeOfDay_AwayTimeTimeFormat] == programWatch_PropertyClass_TimeOfDay_TZTimeFormat24HR )
    {
        bitField |= 0x8;
    }
    
    switch( [self GetIntPropertyForClass: programWatch_PropertyClass_TimeOfDay andIndex: programWatch_PropertyClass_TimeOfDay_AwayTimeDateFormat])
    {
        case programWatch_PropertyClass_TimeOfDay_TZOtherDateFormatMMDDYY:
            bitField |= 0x10;
            break;
        case programWatch_PropertyClass_TimeOfDay_TZOtherDateFormatDDMMYY:
            bitField |= 0x20;
            break;
    }

    
    //Follow Home Time is hardcoded for Datacast
    bitField |= 0x40;
    
    if ( [self GetIntPropertyForClass: programWatch_PropertyClass_General andIndex: programWatch_PropertyClass_General_DisplaySecondsUpdate] == TRUE )
    {
        bitField |= 0x80;
    }
    mDateTimeFormat = bitField;
    
    //Time zones
    mHomeTimeZoneOffset = 0x7FFF;
    
    NSInteger awayTimeSetting = [self GetIntPropertyForClass: programWatch_PropertyClass_TimeOfDay andIndex: programWatch_PropertyClass_TimeOfDay_AwayTimeFollowPhone];
    if (awayTimeSetting == programWatch_PropertyClass_TimeOfDay_FollowPhoneTimeFollowPhone)
        mAwayTimeZoneOffset = 0x7FFF;
    else if (awayTimeSetting == programWatch_PropertyClass_TimeOfDay_FollowPhoneTimeManual)
        mAwayTimeZoneOffset = 0x8000;
    else
        mAwayTimeZoneOffset = [self GetTimeZoneOffsetInMinutesForClass: programWatch_PropertyClass_TimeOfDay andIndex: programWatch_PropertyClass_TimeOfDay_AwayTimeTimeZone];
    
    // Alarms
    ((TDDatacastAlarm *)[mAlarms objectAtIndex: 0]).enable = (Byte)([self GetIntPropertyForClass: programWatch_PropertyClass_Alarm andIndex: programWatch_PropertyClass_Alarm_A1_Status] ? 1 : 0);
    ((TDDatacastAlarm *)[mAlarms objectAtIndex: 1]).enable = (Byte)([self GetIntPropertyForClass: programWatch_PropertyClass_Alarm andIndex: programWatch_PropertyClass_Alarm_A2_Status] ? 1 : 0);
    ((TDDatacastAlarm *)[mAlarms objectAtIndex: 2]).enable = (Byte)([self GetIntPropertyForClass: programWatch_PropertyClass_Alarm andIndex: programWatch_PropertyClass_Alarm_A3_Status] ? 1 : 0);
    
    ((TDDatacastAlarm *)[mAlarms objectAtIndex: 0]).repeatPattern = [self GetIntPropertyForClass: programWatch_PropertyClass_Alarm andIndex: programWatch_PropertyClass_Alarm_A1_Frequency];
    ((TDDatacastAlarm *)[mAlarms objectAtIndex: 1]).repeatPattern = [self GetIntPropertyForClass: programWatch_PropertyClass_Alarm andIndex: programWatch_PropertyClass_Alarm_A2_Frequency];
    ((TDDatacastAlarm *)[mAlarms objectAtIndex: 2]).repeatPattern = [self GetIntPropertyForClass: programWatch_PropertyClass_Alarm andIndex: programWatch_PropertyClass_Alarm_A3_Frequency];
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    NSDate * date1 = [self GetDatePropertyForClass: programWatch_PropertyClass_Alarm andIndex: programWatch_PropertyClass_Alarm_A1_Time];
    if (date1)
    {
        NSDateComponents *components = [calendar components:(NSCalendarUnitHour | NSCalendarUnitMinute) fromDate: date1];
        ((TDDatacastAlarm *)[mAlarms objectAtIndex: 0]).hour = [components hour];
        ((TDDatacastAlarm *)[mAlarms objectAtIndex: 0]).minute = [components minute];
    }
    
    NSDate * date2 = [self GetDatePropertyForClass: programWatch_PropertyClass_Alarm andIndex: programWatch_PropertyClass_Alarm_A2_Time];
    if (date2)
    {
        NSDateComponents *components2 = [calendar components:(NSCalendarUnitHour | NSCalendarUnitMinute) fromDate: date2];
        ((TDDatacastAlarm *)[mAlarms objectAtIndex: 1]).hour = [components2 hour];
        ((TDDatacastAlarm *)[mAlarms objectAtIndex: 1]).minute = [components2 minute];
    }
    
    NSDate * date3 = [self GetDatePropertyForClass: programWatch_PropertyClass_Alarm andIndex: programWatch_PropertyClass_Alarm_A3_Time];
    if (date3)
    {
        NSDateComponents *components3 = [calendar components:(NSCalendarUnitHour | NSCalendarUnitMinute) fromDate: date3];
        ((TDDatacastAlarm *)[mAlarms objectAtIndex: 2]).hour = [components3 hour];
        ((TDDatacastAlarm *)[mAlarms objectAtIndex: 2]).minute = [components3 minute];
    }
    
    NSInteger alertStatus = [self GetIntPropertyForClass: programWatch_PropertyClass_Alarm andIndex: programWatch_PropertyClass_Alarm_Alert];
    mAudibleAlarmAlert = (alertStatus == programWatch_PropertyClass_Alarm_AlertBoth || alertStatus == programWatch_PropertyClass_Alarm_AlertAudible) ? 1 : 0;
    mVibrateAlarmAlert = (alertStatus == programWatch_PropertyClass_Alarm_AlertBoth || alertStatus == programWatch_PropertyClass_Alarm_AlertVibrate) ? 1 : 0;
    
    
    //Intervals
    ((TDDatacastInterval *)[mIntervals objectAtIndex: 0]).enable = (Byte)([self GetIntPropertyForClass: programWatch_PropertyClass_IntervalTimer andIndex: programWatch_PropertyClass_IntervalTimer_IT1_OnOff] ? 1 : 0);
    ((TDDatacastInterval *)[mIntervals objectAtIndex: 1]).enable = (Byte)([self GetIntPropertyForClass: programWatch_PropertyClass_IntervalTimer andIndex: programWatch_PropertyClass_IntervalTimer_IT2_OnOff] ? 1 : 0);
    
    ((TDDatacastInterval *)[mIntervals objectAtIndex: 0]).label = [self GetIntPropertyForClass: programWatch_PropertyClass_IntervalTimer andIndex: programWatch_PropertyClass_IntervalTimer_IT1_label];
    ((TDDatacastInterval *)[mIntervals objectAtIndex: 1]).label = [self GetIntPropertyForClass: programWatch_PropertyClass_IntervalTimer andIndex: programWatch_PropertyClass_IntervalTimer_IT2_label];
    
    ((TDDatacastInterval *)[mIntervals objectAtIndex: 0]).interval = [self GetIntervalFromDatePropertyForClass: programWatch_PropertyClass_IntervalTimer andIndex: programWatch_PropertyClass_IntervalTimer_IT1_Time];
    ((TDDatacastInterval *)[mIntervals objectAtIndex: 1]).interval = [self GetIntervalFromDatePropertyForClass: programWatch_PropertyClass_IntervalTimer andIndex: programWatch_PropertyClass_IntervalTimer_IT2_Time];
    
    mIntervalRepetitions = (Byte)[self GetIntPropertyForClass: programWatch_PropertyClass_IntervalTimer andIndex: programWatch_PropertyClass_IntervalTimer_IntervalRepeats];
    
    alertStatus = [self GetIntPropertyForClass: programWatch_PropertyClass_IntervalTimer andIndex: programWatch_PropertyClass_IntervalTimer_IntervalAlert];
    mAudibleIntervalAlert = (alertStatus == programWatch_PropertyClass_Alarm_AlertBoth || alertStatus == programWatch_PropertyClass_Alarm_AlertAudible) ? 1 : 0;
    mVibrateIntervalAlert = (alertStatus == programWatch_PropertyClass_Alarm_AlertBoth || alertStatus == programWatch_PropertyClass_Alarm_AlertVibrate) ? 1 : 0;
    
    //Notifications
    alertStatus = [self GetIntPropertyForClass: programWatch_PropertyClass_Notifications andIndex: programWatch_PropertyClass_Notifications_Alert];
    mAudibleNotificationAlert = (alertStatus == programWatch_PropertyClass_Alarm_AlertBoth || alertStatus == programWatch_PropertyClass_Alarm_AlertAudible) ? 1 : 0;
    mVibrateNotificationAlert = (alertStatus == programWatch_PropertyClass_Alarm_AlertBoth || alertStatus == programWatch_PropertyClass_Alarm_AlertVibrate) ? 1 : 0;
    
   NSDate * dateDNDStart = [self GetDatePropertyForClass: programWatch_PropertyClass_DoNotDisturb andIndex: programWatch_PropertyClass_DND_DNDStart];
    if (dateDNDStart)
    {
        NSDateComponents *components = [calendar components:(NSCalendarUnitHour | NSCalendarUnitMinute) fromDate: dateDNDStart];
        mDND.hourStart = [components hour];
        mDND.minuteStart = [components minute];
    }
    
    NSDate * dateDNDEnd = [self GetDatePropertyForClass: programWatch_PropertyClass_DoNotDisturb andIndex: programWatch_PropertyClass_DND_DNDEnd];
    if (dateDNDEnd)
    {
        NSDateComponents *components = [calendar components:(NSCalendarUnitHour | NSCalendarUnitMinute) fromDate: dateDNDEnd];
        mDND.hourEnd = [components hour];
        mDND.minuteEnd = [components minute];
    }
    
    bitField = 0;
    if ([self GetBoolPropertyForClass: programWatch_PropertyClass_DoNotDisturb andIndex: programWatch_PropertyClass_DND_DNDStatus] == TRUE)
    {
        bitField |= 0x2;
    }
    
    if ([self GetBoolPropertyForClass: programWatch_PropertyClass_Notifications andIndex: programWatch_PropertyClass_Notifications_All])
    {
        bitField |= 0x1;
    }
    
    mNotificationEnable = bitField;
}

- (int) setWatchSettings: (NSData *) inDataObject
{
    int error = -1;
    Byte inData[inDataObject.length];
    [inDataObject getBytes: inData];
    
    mFileFormatVersion = inData[0];
    
    if ( mFileFormatVersion == FILE_FORMAT_VERSION )
    {
        error = noErr;
        
        ((TDDatacastInterval *)[mIntervals objectAtIndex: 0]).enable = inData[INTERVAL1_ENABLE_OFFSET];
        ((TDDatacastInterval *)[mIntervals objectAtIndex: 1]).enable = inData[INTERVAL2_ENABLE_OFFSET];
        ((TDDatacastInterval *)[mIntervals objectAtIndex: 0]).label = inData[INTERVAL1_LABEL_OFFSET];
        ((TDDatacastInterval *)[mIntervals objectAtIndex: 1]).label = inData[INTERVAL2_LABEL_OFFSET];
        mIntervalRepetitions = inData[INTERVAL_REPEATS_OFFSET];
        mVibrateIntervalAlert = inData[INTERVAL_VIBRATING_ALERTS_OFFSET];
        mAudibleIntervalAlert = inData[INTERVAL_AUDIBLE_ALERTS_OFFSET];
        ((TDDatacastInterval *)[mIntervals objectAtIndex: 0]).interval = *((int *)&inData[INTERVAL1_DURATION_OFFSET]);
        ((TDDatacastInterval *)[mIntervals objectAtIndex: 1]).interval = *((int *)&inData[INTERVAL2_DURATION_OFFSET]);
    
        mGeneralSettings = inData[GENERAL_PREFS_OFFSET];
        mLanguage = inData[LANGUAGE_PREF_OFFSET];
        mDateTimeFormat = inData[DATE_FORMAT_OFFSET];
        
        mHomeTimeZoneOffset = *((short *)&inData[HOME_TIMEZONE_OFFSET]);
        mAwayTimeZoneOffset = *((short *)&inData[AWAY_TIMEZONE_OFFSET]);
        
        ((TDDatacastAlarm *)[mAlarms objectAtIndex: 0]).enable = (Byte)(inData[ALARM_ENABLE_OFFSET] & 0x1);
        ((TDDatacastAlarm *)[mAlarms objectAtIndex: 1]).enable = (Byte)(inData[ALARM_ENABLE_OFFSET] & 0x2);
        ((TDDatacastAlarm *)[mAlarms objectAtIndex: 2]).enable = (Byte)(inData[ALARM_ENABLE_OFFSET] & 0x4);
        mVibrateAlarmAlert = inData[ALARM_VIBRATING_ALERT_OFFSET];
        mAudibleAlarmAlert = inData[ALARM_AUDIBLE_ALERT_OFFSET];
        ((TDDatacastAlarm *)[mAlarms objectAtIndex: 0]).hour = inData[ALARM1_HOUR_OFFSET];
        ((TDDatacastAlarm *)[mAlarms objectAtIndex: 0]).minute = inData[ALARM1_MINUTE_OFFSET];
        ((TDDatacastAlarm *)[mAlarms objectAtIndex: 0]).repeatPattern = inData[ALARM1_REPEATPATTERN_OFFSET];
        ((TDDatacastAlarm *)[mAlarms objectAtIndex: 1]).hour = inData[ALARM2_HOUR_OFFSET];
        ((TDDatacastAlarm *)[mAlarms objectAtIndex: 1]).minute = inData[ALARM2_MINUTE_OFFSET];
        ((TDDatacastAlarm *)[mAlarms objectAtIndex: 1]).repeatPattern = inData[ALARM2_REPEATPATTERN_OFFSET];
        ((TDDatacastAlarm *)[mAlarms objectAtIndex: 2]).hour = inData[ALARM3_HOUR_OFFSET];
        ((TDDatacastAlarm *)[mAlarms objectAtIndex: 2]).minute = inData[ALARM3_MINUTE_OFFSET];
        ((TDDatacastAlarm *)[mAlarms objectAtIndex: 2]).repeatPattern = inData[ALARM3_REPEATPATTERN_OFFSET];
        
        mNotificationEnable = inData[DND_ENABLE_OFFSET];
        
        mDND.hourStart = inData[DND_HOUR_START_OFFSET];
        mDND.minuteStart = inData[DND_MINUTE_START_OFFSET];
        mDND.hourEnd = inData[DND_HOUR_STOP_OFFSET];
        mDND.minuteEnd = inData[DND_MINUTE_STOP_OFFSET];
        mVibrateNotificationAlert = inData[DND_VIBRATING_ALARM_OFFSET];
        mAudibleNotificationAlert = inData[DND_AUDIBLE_ALARM_OFFSET];
        mChecksum = *((int *)&inData[FILE_DATA_SIZE - 4]);
    }
    
    return error;
}

- (void) serializeIntoSettings
{
    //General
    [self SetBoolProperty: [self getTextColor] forClass: programWatch_PropertyClass_General andIndex: programWatch_PropertyClass_General_DisplayTextColor];
    [self SetBoolProperty: [self getButtonBeep] forClass: programWatch_PropertyClass_General andIndex: programWatch_PropertyClass_General_ButtonBeep];
    [self SetBoolProperty: [self getHourlyChime] forClass: programWatch_PropertyClass_General andIndex: programWatch_PropertyClass_General_HourlyChime];
    [self SetIntProperty: [self getLightActivationMode] forClass: programWatch_PropertyClass_General andIndex: programWatch_PropertyClass_General_LightMode];
    [self SetIntProperty: [self getTapForceThreshold] forClass: programWatch_PropertyClass_General andIndex: programWatch_PropertyClass_General_TapForce];
    
    [self SetIntProperty: mLanguage forClass: programWatch_PropertyClass_General andIndex: programWatch_PropertyClass_General_Language];
    [self SetIntProperty: [self getDisplaySecondsUpdateSetting] forClass: programWatch_PropertyClass_General andIndex: programWatch_PropertyClass_General_DisplaySecondsUpdate];
    
    // Time of Day
    
    [self SetIntProperty: [self getHomeDateFormat] forClass: programWatch_PropertyClass_TimeOfDay andIndex: programWatch_PropertyClass_TimeOfDay_HomeTimeDateFormat];
    [self SetIntProperty: [self getHomeTimeFormat] forClass: programWatch_PropertyClass_TimeOfDay andIndex: programWatch_PropertyClass_TimeOfDay_HomeTimeTimeFormat];
    [self SetIntProperty: [self getAwayTimeFormat] forClass: programWatch_PropertyClass_TimeOfDay andIndex: programWatch_PropertyClass_TimeOfDay_AwayTimeTimeFormat];
    [self SetIntProperty: [self getAwayDateFormat] forClass: programWatch_PropertyClass_TimeOfDay andIndex: programWatch_PropertyClass_TimeOfDay_AwayTimeDateFormat];
        
    if (mAwayTimeZoneOffset >= -1000 && mAwayTimeZoneOffset <= 1000)
    {
        [self SetIntProperty: programWatch_PropertyClass_TimeOfDay_FollowPhoneTimeFollowTimeZone forClass: programWatch_PropertyClass_TimeOfDay andIndex: programWatch_PropertyClass_TimeOfDay_AwayTimeFollowPhone];
        
        NSTimeZone * awayZone = [NSTimeZone timeZoneForSecondsFromGMT: mAwayTimeZoneOffset * 60];
        NSString * key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatch_PropertyClass_TimeOfDay andIndex: programWatch_PropertyClass_TimeOfDay_AwayTimeTimeZone];
        NSString * currentlySetAwayZoneName = [[NSUserDefaults standardUserDefaults] objectForKey: key];
        NSTimeZone * currentlySetAwayZone = [NSTimeZone timeZoneWithName: currentlySetAwayZoneName];
        
        if (currentlySetAwayZone == nil || [currentlySetAwayZone secondsFromGMT] != [awayZone secondsFromGMT])
        {
            NSString * currentTZ = [self matchTimeZoneToExistingTimeZoneName: awayZone];
            if (currentTZ != nil)
                [[NSUserDefaults standardUserDefaults] setValue: currentTZ forKey: key];
        }
    }
    else if (mAwayTimeZoneOffset == 0x7FFF)
    {
        //follow phone time
        [self SetIntProperty: programWatch_PropertyClass_TimeOfDay_FollowPhoneTimeFollowPhone forClass: programWatch_PropertyClass_TimeOfDay andIndex: programWatch_PropertyClass_TimeOfDay_AwayTimeFollowPhone];
    }
    else if (mAwayTimeZoneOffset == (short)0x8000)
    {
        //manual
        [self SetIntProperty: programWatch_PropertyClass_TimeOfDay_FollowPhoneTimeManual forClass: programWatch_PropertyClass_TimeOfDay andIndex: programWatch_PropertyClass_TimeOfDay_AwayTimeFollowPhone];
    }
    
    // Alarms
    [self SetBoolProperty: ((TDDatacastAlarm *)[mAlarms objectAtIndex: 0]).enable forClass: programWatch_PropertyClass_Alarm andIndex: programWatch_PropertyClass_Alarm_A1_Status];
    [self SetBoolProperty: ((TDDatacastAlarm *)[mAlarms objectAtIndex: 1]).enable forClass: programWatch_PropertyClass_Alarm andIndex: programWatch_PropertyClass_Alarm_A2_Status];
    [self SetBoolProperty: ((TDDatacastAlarm *)[mAlarms objectAtIndex: 2]).enable forClass: programWatch_PropertyClass_Alarm andIndex: programWatch_PropertyClass_Alarm_A3_Status];
    
    [self SetIntProperty: ((TDDatacastAlarm *)[mAlarms objectAtIndex: 0]).repeatPattern forClass: programWatch_PropertyClass_Alarm andIndex: programWatch_PropertyClass_Alarm_A1_Frequency];
    [self SetIntProperty: ((TDDatacastAlarm *)[mAlarms objectAtIndex: 1]).repeatPattern forClass: programWatch_PropertyClass_Alarm andIndex: programWatch_PropertyClass_Alarm_A2_Frequency];
    [self SetIntProperty: ((TDDatacastAlarm *)[mAlarms objectAtIndex: 2]).repeatPattern forClass: programWatch_PropertyClass_Alarm andIndex: programWatch_PropertyClass_Alarm_A3_Frequency];
    
    [self SetDateProperty: [self getDateFrom: (TDDatacastAlarm *)[mAlarms objectAtIndex: 0]] forClass: programWatch_PropertyClass_Alarm andIndex: programWatch_PropertyClass_Alarm_A1_Time];
    [self SetDateProperty: [self getDateFrom: (TDDatacastAlarm *)[mAlarms objectAtIndex: 1]] forClass: programWatch_PropertyClass_Alarm andIndex: programWatch_PropertyClass_Alarm_A2_Time];
    [self SetDateProperty: [self getDateFrom: (TDDatacastAlarm *)[mAlarms objectAtIndex: 2]] forClass: programWatch_PropertyClass_Alarm andIndex: programWatch_PropertyClass_Alarm_A3_Time];
    
    [self SetIntProperty: [self getAlarmAlert] forClass: programWatch_PropertyClass_Alarm andIndex: programWatch_PropertyClass_Alarm_Alert];
    
    // Intervals
    [self SetIntProperty: [self getIntervalAlert] forClass: programWatch_PropertyClass_IntervalTimer andIndex: programWatch_PropertyClass_IntervalTimer_IntervalAlert];
    [self SetIntProperty: mIntervalRepetitions forClass: programWatch_PropertyClass_IntervalTimer andIndex: programWatch_PropertyClass_IntervalTimer_IntervalRepeats];
    
    [self SetBoolProperty: ((TDDatacastInterval *)[mIntervals objectAtIndex: 0]).enable forClass: programWatch_PropertyClass_IntervalTimer andIndex: programWatch_PropertyClass_IntervalTimer_IT1_OnOff];
    [self SetBoolProperty: ((TDDatacastInterval *)[mIntervals objectAtIndex: 1]).enable forClass: programWatch_PropertyClass_IntervalTimer andIndex: programWatch_PropertyClass_IntervalTimer_IT2_OnOff];
    
    [self SetIntProperty: ((TDDatacastInterval *)[mIntervals objectAtIndex: 0]).label forClass: programWatch_PropertyClass_IntervalTimer andIndex: programWatch_PropertyClass_IntervalTimer_IT1_label];
    [self SetIntProperty: ((TDDatacastInterval *)[mIntervals objectAtIndex: 1]).label forClass: programWatch_PropertyClass_IntervalTimer andIndex: programWatch_PropertyClass_IntervalTimer_IT2_label];
    
    [self SetDatePropertyFromInterval: ((TDDatacastInterval *)[mIntervals objectAtIndex: 0]).interval  forClass: programWatch_PropertyClass_IntervalTimer andIndex: programWatch_PropertyClass_IntervalTimer_IT1_Time];
    [self SetDatePropertyFromInterval: ((TDDatacastInterval *)[mIntervals objectAtIndex: 1]).interval  forClass: programWatch_PropertyClass_IntervalTimer andIndex: programWatch_PropertyClass_IntervalTimer_IT2_Time];
    
    //Notifications
    [self SetIntProperty: [self getNotificationAlert] forClass: programWatch_PropertyClass_Notifications andIndex: programWatch_PropertyClass_Notifications_Alert];
    
    BOOL dndStatus = (mNotificationEnable & 0x02);
    [self SetBoolProperty:dndStatus  forClass: programWatch_PropertyClass_DoNotDisturb andIndex: programWatch_PropertyClass_DND_DNDStatus];
    
    [self SetDateProperty: [self getStartDateFromDND: mDND] forClass: programWatch_PropertyClass_DoNotDisturb andIndex: programWatch_PropertyClass_DND_DNDStart];
    [self SetDateProperty: [self getEndDateFromDND: mDND] forClass: programWatch_PropertyClass_DoNotDisturb andIndex: programWatch_PropertyClass_DND_DNDEnd];
    
    BOOL allNotificationsStatus = (mNotificationEnable & 0x01);
    [self SetBoolProperty: allNotificationsStatus forClass: programWatch_PropertyClass_Notifications andIndex: programWatch_PropertyClass_Notifications_All];
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

- (NSDate *) getStartDateFromDND: (TDDatacastDND *) dnd
{
    NSDate* result = nil;
    
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setMinute: dnd.minuteStart];
    [comps setHour: dnd.hourStart];

    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier: NSCalendarIdentifierGregorian];
    result = [gregorian dateFromComponents: comps];
    
    return result;
}

- (NSDate *) getEndDateFromDND: (TDDatacastDND *) dnd
{
    NSDate* result = nil;
    
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setMinute: dnd.minuteEnd];
    [comps setHour: dnd.hourEnd];
    
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier: NSCalendarIdentifierGregorian];
    result = [gregorian dateFromComponents: comps];
    
    return result;
}

- (NSData *) toByteArray
{
    Byte raw[FILE_DATA_SIZE];
    int i;
    Byte bitField = 0;
    
    memset(raw, 0, FILE_DATA_SIZE);
    raw[0] = FILE_FORMAT_VERSION;
    
    for ( i = 0; i < 2; i++ )
    {
        raw[i+INTERVAL1_ENABLE_OFFSET] = ((TDDatacastInterval *)[mIntervals objectAtIndex: i]).enable;
        raw[i+INTERVAL1_LABEL_OFFSET] = ((TDDatacastInterval *)[mIntervals objectAtIndex: i]).label;
    }
    
    raw[INTERVAL_REPEATS_OFFSET] = mIntervalRepetitions;
    raw[INTERVAL_VIBRATING_ALERTS_OFFSET] = mVibrateIntervalAlert;
    raw[INTERVAL_AUDIBLE_ALERTS_OFFSET] = mAudibleIntervalAlert;
    
    NSData * ptrDataInt1 = [iDevicesUtil intToByteArray: CFSwapInt32((int)((TDDatacastInterval *)[mIntervals objectAtIndex: 0]).interval)];
    Byte ptrBytesInt1[4];
    [ptrDataInt1 getBytes: ptrBytesInt1];
    memcpy(&raw[INTERVAL1_DURATION_OFFSET], ptrBytesInt1, 4);
    
    NSData * ptrDataInt2 = [iDevicesUtil intToByteArray: CFSwapInt32((int)((TDDatacastInterval *)[mIntervals objectAtIndex: 1]).interval)];
    Byte ptrBytesInt2[4];
    [ptrDataInt2 getBytes: ptrBytesInt2];
    memcpy(&raw[INTERVAL2_DURATION_OFFSET], ptrBytesInt2, 4);
    
    raw[GENERAL_PREFS_OFFSET] = mGeneralSettings;
    raw[LANGUAGE_PREF_OFFSET] = mLanguage;
    
    raw[DATE_FORMAT_OFFSET] = mDateTimeFormat;
    
    NSData * ptrDataShort1 = [iDevicesUtil shortToByteArray: CFSwapInt16(mHomeTimeZoneOffset)];
    Byte ptrBytesShort1[2];
    [ptrDataShort1 getBytes: ptrBytesShort1];
    memcpy(&raw[HOME_TIMEZONE_OFFSET], ptrBytesShort1, 2);
    
    NSData * ptrDataShort2 = [iDevicesUtil shortToByteArray: CFSwapInt16(mAwayTimeZoneOffset)];
    Byte ptrBytesShort2[2];
    [ptrDataShort2 getBytes: ptrBytesShort2];
    memcpy(&raw[AWAY_TIMEZONE_OFFSET], ptrBytesShort2, 2);
    
    
    
    bitField = 0;
    if ( 1 == ((TDDatacastAlarm *)[mAlarms objectAtIndex: 0]).enable )
    {
        bitField = 1;
    }
    if ( 1 == ((TDDatacastAlarm *)[mAlarms objectAtIndex: 1]).enable )
    {
        bitField |= 0x2;
    }
    if ( 1 == ((TDDatacastAlarm *)[mAlarms objectAtIndex: 2]).enable )
    {
        bitField |= 0x4;
    }
    raw[ALARM_ENABLE_OFFSET] = bitField;
    raw[ALARM_VIBRATING_ALERT_OFFSET] = mVibrateAlarmAlert;
    raw[ALARM_AUDIBLE_ALERT_OFFSET] = mAudibleAlarmAlert;
    raw[ALARM1_HOUR_OFFSET] = ((TDDatacastAlarm *)[mAlarms objectAtIndex: 0]).hour;
    raw[ALARM1_MINUTE_OFFSET] = ((TDDatacastAlarm *)[mAlarms objectAtIndex: 0]).minute;
    raw[ALARM1_REPEATPATTERN_OFFSET] = ((TDDatacastAlarm *)[mAlarms objectAtIndex: 0]).repeatPattern;
    raw[ALARM2_HOUR_OFFSET] = ((TDDatacastAlarm *)[mAlarms objectAtIndex: 1]).hour;
    raw[ALARM2_MINUTE_OFFSET] = ((TDDatacastAlarm *)[mAlarms objectAtIndex: 1]).minute;
    raw[ALARM2_REPEATPATTERN_OFFSET] = ((TDDatacastAlarm *)[mAlarms objectAtIndex: 1]).repeatPattern;
    raw[ALARM3_HOUR_OFFSET] = ((TDDatacastAlarm *)[mAlarms objectAtIndex: 2]).hour;
    raw[ALARM3_MINUTE_OFFSET] = ((TDDatacastAlarm *)[mAlarms objectAtIndex: 2]).minute;
    raw[ALARM3_REPEATPATTERN_OFFSET] = ((TDDatacastAlarm *)[mAlarms objectAtIndex: 2]).repeatPattern;
    raw[DND_ENABLE_OFFSET] = mNotificationEnable;
    raw[DND_HOUR_START_OFFSET] = mDND.hourStart;
    raw[DND_MINUTE_START_OFFSET] = mDND.minuteStart;
    raw[DND_HOUR_STOP_OFFSET] = mDND.hourEnd;
    raw[DND_MINUTE_STOP_OFFSET] = mDND.minuteEnd;
    raw[DND_VIBRATING_ALARM_OFFSET] = mVibrateNotificationAlert;
    raw[DND_AUDIBLE_ALARM_OFFSET] = mAudibleNotificationAlert;
    
    mChecksum = [iDevicesUtil calculateTimexCRC32: raw withLength: FILE_DATA_SIZE - 4];
    
    NSData * ptrData = [iDevicesUtil intToByteArray: mChecksum];
    Byte ptrBytes[4];
    [ptrData getBytes: ptrBytes];
    memcpy(&raw[FILE_DATA_SIZE - 4], ptrBytes, 4);
    
    NSData * dataContainer = [NSData dataWithBytes: raw length: FILE_DATA_SIZE];
    return dataContainer;
}

- (int) getTextColor
{
    return mGeneralSettings & 0x1;
}
- (int) getButtonBeep
{
    return (mGeneralSettings & 0x2) >> 1;
}
- (int) getHourlyChime
{
    return (mGeneralSettings & 0x4) >> 2;
}
- (int) getLightActivationMode
{
    return (mGeneralSettings & 0x18) >> 3;
}
- (int) getTapForceThreshold
{
    return (mGeneralSettings & 0x60) >> 5;
}
- (int) getHomeTimeFormat
{
    return mDateTimeFormat & 0x1;
}
- (int) getHomeDateFormat
{
    return (mDateTimeFormat & 0x6) >> 1;
}
- (int) getAwayTimeFormat
{
    return (mDateTimeFormat & 0x8) >> 3;
}
- (int) getAwayDateFormat
{
    int value = (mDateTimeFormat & 0x30) >> 4;
    
    //Other Time only supports a couple of Date formats, so we need to map them here...
    
    if (value == programWatch_PropertyClass_TimeOfDay_TZDateFormatMMDDYY)
    {
        return programWatch_PropertyClass_TimeOfDay_TZOtherDateFormatMMDDYY;
    }
    else if (value == programWatch_PropertyClass_TimeOfDay_TZDateFormatDDMMYY)
    {
        return programWatch_PropertyClass_TimeOfDay_TZOtherDateFormatDDMMYY;
    }
    
    return 0;
}
- (int) getActiveTimeZone
{
    return (mDateTimeFormat & 0x40) >> 6;
}
- (int) getDisplaySecondsUpdateSetting
{
    return (mDateTimeFormat & 0x80) >> 7;
}

- (int) getAlarmAlert
{
    int alert = 0;
    
    if ( mVibrateAlarmAlert == 1 && mAudibleAlarmAlert == 1 )
    {
        alert = programWatch_PropertyClass_Alarm_AlertBoth;
    }
    else if ( mVibrateAlarmAlert == 1 )
    {
        alert = programWatch_PropertyClass_Alarm_AlertVibrate;
    }
    else if ( mAudibleAlarmAlert == 1 )
    {
        alert = programWatch_PropertyClass_Alarm_AlertAudible;
    }
    return alert;
}
- (int) getIntervalAlert
{
    int alert = 0;
    
    if ( mVibrateIntervalAlert == 1 && mAudibleIntervalAlert == 1 )
    {
        alert = programWatch_PropertyClass_Alarm_AlertBoth;
    }
    else if ( mVibrateIntervalAlert == 1 )
    {
        alert = programWatch_PropertyClass_Alarm_AlertVibrate;
    }
    else if ( mAudibleIntervalAlert == 1 )
    {
        alert = programWatch_PropertyClass_Alarm_AlertAudible;
    }
    return alert;
}
- (int) getNotificationAlert
{
    int alert = 0;
    
    if ( mVibrateNotificationAlert == 1 && mAudibleNotificationAlert == 1 )
    {
        alert = programWatch_PropertyClass_Notifications_AlertBoth;
    }
    else if ( mVibrateNotificationAlert == 1 )
    {
        alert = programWatch_PropertyClass_Notifications_AlertVibrate;
    }
    else if ( mAudibleNotificationAlert == 1 )
    {
        alert = programWatch_PropertyClass_Notifications_AlertAudible;
    }
    else
    {
        alert = programWatch_PropertyClass_Notifications_AlertNone;
    }
    return alert;
}
- (int) getAlarmRepeatPattern: (int) inRepeatPattern
{
    int pattern = 0;
    for ( int i = 0; i < 8; i++ )
    {
        if ( ((inRepeatPattern >> i) & 1) == 1 )
        {
            pattern = i;
            break;
        }
    }
    return pattern;
}

- (BOOL) GetBoolPropertyForClass: (programWatch_PropertyClass) classId andIndex: (NSInteger) idx
{
    BOOL flag = FALSE;
    NSString * key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: classId andIndex: idx];
    if ([[NSUserDefaults standardUserDefaults] objectForKey: key] != nil)
    {
        flag = [[NSUserDefaults standardUserDefaults] boolForKey: key];
    }
    return flag;
}

- (void) SetBoolProperty: (BOOL) flag forClass: (programWatch_PropertyClass) classId andIndex: (NSInteger) idx
{
    NSString * key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: classId andIndex: idx];
    [[NSUserDefaults standardUserDefaults] setBool: flag forKey: key];
}

- (NSInteger) GetIntPropertyForClass: (programWatch_PropertyClass) classId andIndex: (NSInteger) idx
{
    NSInteger result = 0;
    
    NSString * key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: classId andIndex: idx];
    if ([[NSUserDefaults standardUserDefaults] objectForKey: key] != nil)
    {
        result = [[NSUserDefaults standardUserDefaults] integerForKey: key];
    }
    return result;
}

- (void) SetIntProperty: (NSInteger) value forClass: (programWatch_PropertyClass) classId andIndex: (NSInteger) idx
{
    NSString * key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: classId andIndex: idx];
    [[NSUserDefaults standardUserDefaults] setInteger: value forKey: key];
}

- (NSDate *) GetDatePropertyForClass: (programWatch_PropertyClass) classId andIndex: (NSInteger) idx
{
    NSDate * result = nil;
    
    NSString * key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: classId andIndex: idx];
    if ([[NSUserDefaults standardUserDefaults] objectForKey: key] != nil)
    {
        result = [[NSUserDefaults standardUserDefaults] objectForKey: key];
    }
    
    return result;
}

- (void) SetDateProperty: (NSDate *) value forClass: (programWatch_PropertyClass) classId andIndex: (NSInteger) idx
{
    NSString * key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: classId andIndex: idx];
    [[NSUserDefaults standardUserDefaults] setObject: value forKey: key];
}

- (NSInteger) GetIntervalFromDatePropertyForClass: (programWatch_PropertyClass) classId andIndex: (NSInteger) idx
{
    NSString * key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: classId andIndex: idx];
    NSMutableData * setting = [[NSUserDefaults standardUserDefaults] objectForKey: key];
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData: setting];
    NSDateComponents *decoded = [unarchiver decodeObject];
    [unarchiver finishDecoding];
    
    NSInteger value = (decoded.hour * 1000 * 60 * 60) + (decoded.minute * 60 * 1000) + (decoded.second * 1000);
    
    return value;
}

- (void) SetDatePropertyFromInterval: (NSInteger) intervalInMS forClass: (programWatch_PropertyClass) classId andIndex: (NSInteger) idx
{
    NSDateComponents * components = [[NSDateComponents alloc] init];
    
    components.second = (intervalInMS % 60000) / 1000;
    components.minute = (intervalInMS / 60000) % 60;
    components.hour = (intervalInMS / 3600000);

    
    NSMutableData *data= [NSMutableData data];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData: data];
    
    [archiver encodeObject: components];
    [archiver finishEncoding];
    
    NSString * key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: classId andIndex: idx];
    [[NSUserDefaults standardUserDefaults] setObject: data forKey: key];
}

- (short) GetTimeZoneOffsetInMinutesForClass: (programWatch_PropertyClass) classId andIndex: (NSInteger) idx
{
    short returnValue = 0;
    
    NSString * key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: classId andIndex: idx];
    if ([[NSUserDefaults standardUserDefaults] objectForKey: key] != nil)
    {
        NSString * tzName = [[NSUserDefaults standardUserDefaults] objectForKey: key];
        NSTimeZone * currentZone = [NSTimeZone timeZoneWithName: tzName];
        if (currentZone)
        {
            NSInteger secs = [currentZone secondsFromGMT];
            returnValue = secs/60;
        }
    }
    
    return returnValue;
}

- (NSString *) matchTimeZoneToExistingTimeZoneName: (NSTimeZone *) zoneToMatch
{
    NSString * zoneName = nil;
    NSArray * tempTimeZoneList = [NSTimeZone knownTimeZoneNames];
    for (NSString * tzName in tempTimeZoneList)
    {
        NSTimeZone * currentZone = [NSTimeZone timeZoneWithName: tzName];
        if (currentZone != nil)
        {
            if ([zoneToMatch secondsFromGMT] == [currentZone secondsFromGMT])
            {
                zoneName = [currentZone name];
                break;
            }
        }
    }
    
    return zoneName;
}
@end

