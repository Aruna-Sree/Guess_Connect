//
//  TDDatacastWatchSettings.h
//  Timex Connected
//
//  Created by Lev Verbitsky on 1/21/14.
//  Copyright (c) 2014 iDevices, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TDDatacastInterval : NSObject
    @property (nonatomic) BOOL enable;
    @property (nonatomic) Byte label;
    @property (nonatomic) NSInteger interval;
@end

@interface TDDatacastAlarm : NSObject
    @property (nonatomic) Byte enable;
    @property (nonatomic) Byte hour;
    @property (nonatomic) Byte minute;
    @property (nonatomic) Byte repeatPattern;
@end

@interface TDDatacastDND : NSObject
    @property (nonatomic) Byte hourStart;
    @property (nonatomic) Byte minuteStart;
    @property (nonatomic) Byte hourEnd;
    @property (nonatomic) Byte minuteEnd;
@end

@interface TDDatacastWatchSettings : NSObject
{
    Byte            mFileFormatVersion;
    NSMutableArray  *  mIntervals;
    
    Byte            mIntervalRepetitions;
    Byte            mVibrateIntervalAlert;
    Byte            mAudibleIntervalAlert;
    Byte            mGeneralSettings;
    short           mHomeTimeZoneOffset;
    short           mAwayTimeZoneOffset;
    Byte            mLanguage;
    Byte            mDateTimeFormat;
    NSMutableArray *  mAlarms;
    Byte            mVibrateAlarmAlert;
    Byte            mAudibleAlarmAlert;
    TDDatacastDND  *  mDND;
    Byte            mVibrateNotificationAlert;
    Byte            mAudibleNotificationAlert;
    Byte            mNotificationEnable;
    int             mChecksum;
}

@property (nonatomic, readonly) int mChecksum;

- (id) init;
- (id) init: (NSData *) inData;
- (void) serializeIntoSettings;
- (NSData *) toByteArray;
@end
