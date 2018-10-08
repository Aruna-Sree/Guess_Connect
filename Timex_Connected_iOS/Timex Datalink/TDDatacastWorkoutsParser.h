//
//  TDDatacastWorkoutsParser.h
//  Timex Connected
//
//  Created by Lev Verbitsky on 1/27/14.
//  Copyright (c) 2014 iDevices, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WorkoutHeader : NSObject

    @property (nonatomic) Byte mWorkoutType;
    @property (nonatomic) Byte mYear;
    @property (nonatomic) Byte mMonth;
    @property (nonatomic) Byte mDay;
    @property (nonatomic) Byte mHour;
    @property (nonatomic) Byte mMinute;
    @property (nonatomic) Byte mSecond;
    @property (nonatomic) long mActivityTimeMS;

@end

@interface Interval : NSObject

    @property (nonatomic) Byte mEnabled;
    @property (nonatomic) Byte mLabel;
    @property (nonatomic) long mDurationMS;

@end

@interface Timer : NSObject

    @property (nonatomic) Byte mRepetitions;
    @property (nonatomic, strong) NSMutableArray * mIntervals;
    @property (nonatomic) Byte mScheduledRepetitions;

@end

@interface ChronoLap : NSObject

    @property (nonatomic) long mLapTimeMS;
    @property (nonatomic) Byte mLapNumber;

@end

@interface Lap : NSObject

    @property (nonatomic) Byte mNumberOfLaps;
    @property (nonatomic) Byte mBestLap;
    @property (nonatomic) long mBestLapTime;
    @property (nonatomic) long mAverageLapTime;
    @property (nonatomic, strong) NSMutableArray * mChronoLaps;

@end

@interface WorkoutParser : NSObject

    @property (nonatomic, strong) WorkoutHeader * mHeader;
    @property (nonatomic, strong) Timer * mTimers;
    @property (nonatomic, strong) Lap *  mLaps;

@end

@interface TDDatacastWorkoutsParser : NSObject

    @property (nonatomic) Byte mVersion;
    @property (nonatomic) Byte mValidWorkouts;
    @property (nonatomic) NSInteger mChecksum;
    @property (nonatomic, strong) NSMutableArray * mWorkouts;

- (id) init: (NSData *) inData;
- (NSArray *) serializeToDB;
@end
