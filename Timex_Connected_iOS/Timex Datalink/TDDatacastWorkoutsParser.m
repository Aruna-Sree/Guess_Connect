//
//  TDDatacastWorkoutsParser.m
//  Timex Connected
//
//  Created by Lev Verbitsky on 1/27/14.
//  Copyright (c) 2014 iDevices, LLC. All rights reserved.
//

#import "TDDatacastWorkoutsParser.h"
#import "TDWorkoutData.h"
#import "TDWatchProfile.h"
#import "iDevicesUtil.h"
#import "TDWorkoutData+Writeable.h"
#import "TDFlurryDataPacket.h"

#define SIZE_BYTES  280
#define MAXIMUM_NUMBER_OF_LAPS 50
#define TOTAL_INTERVALS_SUPPORTED 2

@implementation WorkoutHeader

@synthesize mWorkoutType = _mWorkoutType;
@synthesize mYear = _mYear;
@synthesize mMonth = _mMonth;
@synthesize mDay = _mDay;
@synthesize mHour = _mHour;
@synthesize mMinute = _mMinute;
@synthesize mSecond = _mSecond;
@synthesize mActivityTimeMS = _mActivityTimeMS;

@end

@implementation Interval

@synthesize mEnabled = _mEnabled;
@synthesize mLabel = _mLabel;
@synthesize mDurationMS = _mDurationMS;

@end

@implementation Timer

@synthesize mRepetitions = _mRepetitions;
@synthesize mIntervals = _mIntervals;
@synthesize mScheduledRepetitions = _mScheduledRepetitions;

@end

@implementation ChronoLap

@synthesize mLapTimeMS = _mLapTimeMS;
@synthesize mLapNumber = _mLapNumber;

@end

@implementation Lap

@synthesize mNumberOfLaps = _mNumberOfLaps;
@synthesize mBestLap = _mBestLap;
@synthesize mBestLapTime = _mBestLapTime;
@synthesize mAverageLapTime = _mAverageLapTime;
@synthesize mChronoLaps = _mChronoLaps;

@end

@implementation WorkoutParser

@synthesize mHeader = _mHeader;
@synthesize mTimers = _mTimers;
@synthesize mLaps = _mLaps;

- (id) init
{
    if (self = [super init])
    {
        _mHeader = [[WorkoutHeader alloc] init];
    }
    return self;
}

@end

@implementation TDDatacastWorkoutsParser


@synthesize mVersion = _mVersion;
@synthesize mValidWorkouts = _mValidWorkouts;
@synthesize mChecksum = _mChecksum;
@synthesize mWorkouts = _mWorkouts;

- (id) init: (NSData *) inData
{
    if (self = [super init])
    {
        _mValidWorkouts = 0;
        _mWorkouts = [[NSMutableArray alloc] init];
        
        WorkoutParser * workout = nil;
        Byte workoutType = 0;
        int offset = 0;
        
        if ( nil != inData )
        {
            Byte inDataBuffer[inData.length];
            [inData getBytes: inDataBuffer];
            
            _mVersion = inDataBuffer[0];
            _mValidWorkouts = inDataBuffer[1];
            
            // Interval Timers or Laps
            for ( int i = 0; i < _mValidWorkouts; i++ )
            {
                workout = [[WorkoutParser alloc] init];
                
                offset = (i * SIZE_BYTES) + 4;
                workoutType = inDataBuffer[ offset ];
                
                if ( [self isValid: workoutType] )
                {
                    workout.mHeader.mWorkoutType = inDataBuffer[offset] & 0x1;
                    workout.mHeader.mYear = inDataBuffer[offset + 4];
                    workout.mHeader.mMonth = inDataBuffer[offset + 5];
                    workout.mHeader.mDay = inDataBuffer[offset + 6];
                    workout.mHeader.mHour = inDataBuffer[offset + 8];
                    workout.mHeader.mMinute = inDataBuffer[offset + 9];
                    workout.mHeader.mSecond = inDataBuffer[offset + 10];
                    workout.mHeader.mActivityTimeMS = *((int *)&inDataBuffer[offset + 12]);
                    switch ( [self getWorkoutType: workoutType] )
                    {
                        case TDWorkoutData_WorkoutTypeChrono:
                            workout.mLaps = [self setLap: inDataBuffer andOffset: offset + 16];
                            break;
                        case TDWorkoutData_WorkoutTypeTimer:
                            workout.mTimers = [self setTimer: inDataBuffer andOffset: offset + 16];
                            break;
                    }
                }
                
                [_mWorkouts addObject: workout];
            }
            
            NSInteger checksumLocation = inData.length - 4;
            _mChecksum = *((int *)&inDataBuffer[checksumLocation]);
        }
    }
    
    return self;
}

- (NSArray *) serializeToDB
{
    NSMutableArray * newWorkouts = nil;
    
    for (int i = 0; i < [_mWorkouts count]; i++)
    {
        WorkoutParser * workout = [_mWorkouts objectAtIndex: i];
        TDWorkoutData * newData = [[TDWorkoutData alloc] init];
        
        NSDate * newDate = [self getDateFrom: workout];
        
        [newData setWorkoutDate: newDate];
        [newData setWorkoutType: (TDWorkoutData_WorkoutType)workout.mHeader.mWorkoutType];
        [newData setWorkoutDuration: [NSNumber numberWithDouble: workout.mHeader.mActivityTimeMS]];
        
        if (workout.mHeader.mWorkoutType == TDWorkoutData_WorkoutTypeChrono)
        {
            [newData setNumberOfScheduledRepeats: 0]; //set just in case
            [newData setRecordedNumberOfLaps: workout.mLaps.mNumberOfLaps];
            
            NSInteger numberOfRecordedLaps = [workout.mLaps.mChronoLaps count];
            
            for (NSInteger j = 0; j < numberOfRecordedLaps; j++)
            {
                ChronoLap * chronoLap = [workout.mLaps.mChronoLaps objectAtIndex: j];
                long lapTimeMS = chronoLap.mLapTimeMS;
                
                NSNumber * lapTime =  [[NSNumber alloc] initWithDouble: lapTimeMS];
                
                [newData addLapData: lapTime withType: programWatch_PropertyClass_IntervalTimer_LabelRun];
            }
        }
        else if (workout.mHeader.mWorkoutType == TDWorkoutData_WorkoutTypeTimer)
        {
            Timer * myTimer = workout.mTimers;
            
            [newData setNumberOfScheduledRepeats: myTimer.mScheduledRepetitions];
            [newData setRecordedNumberOfLaps: 0];
            
            int repetitions = myTimer.mRepetitions;
            for (int j = 0; j < repetitions; j++)
            {
                for (int i = 0; i < [myTimer.mIntervals count]; i++)
                {
                    Interval * currentInterval = [myTimer.mIntervals objectAtIndex: i];
                    NSNumber * lapTime =  [[NSNumber alloc] initWithDouble: currentInterval.mDurationMS];
                    NSInteger type = currentInterval.mLabel;

                    if (currentInterval.mEnabled == TRUE)
                    {
                        [newData addLapData: lapTime withType: type];
                    }
                }
            }
        }
        
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

- (NSDate *) getDateFrom: (WorkoutParser *) workout
{
    NSDate* result = nil;
    
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setYear: 2000 + workout.mHeader.mYear]; //0 corresponds to year 2000
    [comps setMonth: workout.mHeader.mMonth];
    [comps setDay: workout.mHeader.mDay];
    [comps setHour: workout.mHeader.mHour];
    [comps setMinute: workout.mHeader.mMinute];
    [comps setSecond: workout.mHeader.mSecond];
    
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier: NSCalendarIdentifierGregorian];
    result = [gregorian dateFromComponents: comps];
    
    return result;
}

- (Lap *) setLap: ( Byte *) inData andOffset: (int) offset
{
    Lap * lap = [[Lap alloc] init];
    
    lap.mNumberOfLaps = inData[ offset ];
    lap.mBestLap = inData[ offset + 1 ];
    
    lap.mBestLapTime = *((int *)&inData[offset + 4]);
    lap.mAverageLapTime = *((int *)&inData[offset + 8]);
    
    lap.mChronoLaps = [[NSMutableArray alloc] initWithCapacity: lap.mNumberOfLaps];
    int stop = lap.mNumberOfLaps > MAXIMUM_NUMBER_OF_LAPS ? MAXIMUM_NUMBER_OF_LAPS : lap.mNumberOfLaps;
    
    for ( int i = 0; i < stop; i++ )
    {
        ChronoLap * newChronoLap = [[ChronoLap alloc] init];
        newChronoLap.mLapTimeMS = *((int *)&inData[(i * 5) + (offset + 12)]);
        newChronoLap.mLapNumber = inData[ (i * 5) + (offset + 16) ];
        
        [lap.mChronoLaps addObject: newChronoLap];
    }
    
    return lap;
}
- (Timer *) setTimer: ( Byte *) inData andOffset: (int) offset
{
    Timer * timer = [[Timer alloc] init];
    
    timer.mRepetitions = inData[ offset ];
    
    timer.mIntervals = [[NSMutableArray alloc] initWithCapacity: TOTAL_INTERVALS_SUPPORTED];
    for ( int i = 0; i < TOTAL_INTERVALS_SUPPORTED; i++ )
    {
        Interval * newInterval = [[Interval alloc] init];
        newInterval.mEnabled = inData[ offset + 4 + i ];
        newInterval.mLabel = inData[ offset + 10 + i ];
        newInterval.mDurationMS = *((int *)&inData[offset+20+(i*4)]);
        
        [timer.mIntervals addObject: newInterval];
    }
    
    timer.mScheduledRepetitions = inData[ offset+ 16 ];
    
    return timer;
}

- (int) getWorkoutType: (Byte) inType
{
    return inType & 0x1;
}

- (BOOL) isValid: (Byte) inType
{
    return !((inType & 0x2) == 0);
}
@end
