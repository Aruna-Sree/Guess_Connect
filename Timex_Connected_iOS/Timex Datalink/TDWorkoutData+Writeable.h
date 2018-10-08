//
//  TDWorkoutData+Writeable.h
//  Timex Connected
//
//  Created by Lev Verbitsky on 3/25/14.
//  Copyright (c) 2014 iDevices, LLC. All rights reserved.
//

#import "TDWorkoutData.h"

@interface TDWorkoutData (Writeable)

-(void) setNumberOfScheduledRepeats: (NSInteger)num;
-(void) setRecordedNumberOfLaps: (NSInteger)num;
-(void) setWorkoutType: (TDWorkoutData_WorkoutType) type;
-(void) setWorkoutDate: (NSDate *) date;
-(void) setWorkoutDuration: (NSNumber *) duration;

@end
