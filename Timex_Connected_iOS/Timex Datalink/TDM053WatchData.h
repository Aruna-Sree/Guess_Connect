//
//  TDM053WatchData.h
//  Timex Connected
//
//  Created by Lev Verbitsky on 5/15/14.
//  Copyright (c) 2014 iDevices, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TDDatacastApptsParser.h"

@interface TDM053TimeZone : NSObject
@property (nonatomic) Byte minute;
@property (nonatomic) Byte hour;
@property (nonatomic) Byte day;
@property (nonatomic) Byte month;
@property (nonatomic) Byte year;
@end

@interface TDM053Interval : NSObject
@property (nonatomic) Byte seconds;
@property (nonatomic) Byte minutes;
@property (nonatomic) Byte hours;
@end

@interface TDM053WorkoutHeader : NSObject

@property (nonatomic) Byte mMinute;
@property (nonatomic) Byte mHour;
@property (nonatomic) Byte mYear;
@property (nonatomic) Byte mMonth;
@property (nonatomic) Byte mDay;
@property (nonatomic) Byte mNumberOfLaps;
@property (nonatomic) Byte mActivityDataSavedFlag;
@property (nonatomic) Byte mTotalTimeHour;
@property (nonatomic) Byte mTotalTimeMinute;
@property (nonatomic) Byte mTotalTimeSecond;
@property (nonatomic) Byte mTotalTimeHundredth;
@property (nonatomic) Byte mReserved1;
@property (nonatomic) unsigned int   mTotalSteps;
@property (nonatomic) unsigned short mTotalDistance;
@property (nonatomic) unsigned int   mTotalCalories;
@property (nonatomic) int mReserved2;
@end

@interface TDM053Lap : NSObject

@property (nonatomic) Byte mHours;
@property (nonatomic) Byte mMinutes;
@property (nonatomic) Byte mSeconds;
@property (nonatomic) Byte mHundredths;
@property (nonatomic) unsigned int   mTotalSteps;
@property (nonatomic) unsigned short mTotalDistance;
@property (nonatomic) unsigned int   mTotalCalories;

- (long) getDurationInMS;
@end

@interface TDM053IntervalRecord : NSObject

@property (nonatomic) Byte mMinute;
@property (nonatomic) Byte mHour;
@property (nonatomic) Byte mDay;
@property (nonatomic) Byte mMonth;
@property (nonatomic) Byte mYear;
@property (nonatomic) Byte mRepetitions;
@property (nonatomic) Byte mRepetitionsFlags;
@property (nonatomic) unsigned int   mTotalSteps;
@property (nonatomic) unsigned short mTotalDistance;
@property (nonatomic) unsigned int   mTotalCalories;
@property (nonatomic) Byte mTotalHours;
@property (nonatomic) Byte mTotalMinutes;
@property (nonatomic) Byte mTotalSeconds;

- (NSDate *) getWorkoutDate;
- (long) getDurationInMS;
@end

@interface TDM053WorkoutParser : NSObject

@property (nonatomic, strong) TDM053WorkoutHeader * mHeader;
@property (nonatomic, strong) NSMutableArray *  mLaps;

- (NSDate *) getWorkoutDate;
@end

@interface TDM053WatchData : NSObject

@property (nonatomic, readonly) int mChecksum;

- (id) init;
- (id) init: (NSData *) inData;
- (NSArray *) serializeToDB;
- (void) serializeIntoSettings;
- (void) recordActivityData;

- (NSData *) settingsAndApptsToByteArray: (TDDatacastApptsParser *) apptsParser;
- (NSData *) currentTimeAndSetupSettingsToByteArray;
@end
