//
//  TDWorkoutData+Writeable.m
//  Timex Connected
//
//  Created by Lev Verbitsky on 3/25/14.
//  Copyright (c) 2014 iDevices, LLC. All rights reserved.
//

#import "TDWorkoutData+Writeable.h"

@implementation TDWorkoutData (Writeable)

-(void) setNumberOfScheduledRepeats: (NSInteger)num
{
    numberOfScheduledRepeats = num;
}
-(void) setRecordedNumberOfLaps: (NSInteger)num
{
    recordedNumberOfLaps = num;
}
-(void) setWorkoutType: (TDWorkoutData_WorkoutType) type
{
    workoutType = type;
}
-(void) setWorkoutDate: (NSDate *) date
{
    workoutDate = date;
}
-(void) setWorkoutDuration: (NSNumber *) duration
{
    workoutDuration = duration;
}

@end
