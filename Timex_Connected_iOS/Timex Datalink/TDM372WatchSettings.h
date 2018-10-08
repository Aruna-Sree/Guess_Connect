//
//  TDM372WatchSettings.h
//  Timex
//
//  Created by Lev Verbitsky on 6/4/15.
//  Copyright (c) 2015 iDevices, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TDM372WatchSettings : NSObject
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
}

@property (nonatomic, readonly) int mChecksum;

- (id) init;
- (id) init: (NSData *) inData;
- (void) serializeIntoSettings;
- (NSData *) toByteArray;
@end
