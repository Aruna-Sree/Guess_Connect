//
//  TDWorkoutDataM053.h
//  Timex
//
//  Created by Lev Verbitsky on 10/6/14.
//  Copyright (c) 2014 iDevices, LLC. All rights reserved.
//

#import "TDWorkoutData.h"

@interface TDLapActivityTracker : TDLap
{
    NSInteger                   mKey;
}
@property (nonatomic) NSInteger mKey;
@property (nonatomic) NSInteger totalSteps;
@property (nonatomic) NSInteger totalDistance;
@property (nonatomic) NSInteger totalCalories;

@end

@interface TDWorkoutDataActivityTracker : TDWorkoutData


@property (nonatomic) NSInteger totalSteps;
@property (nonatomic) NSInteger totalDistance;
@property (nonatomic) NSInteger totalCalories;

- (void) addLapData: (NSNumber *) duration withType: (NSInteger) type withSteps: (NSInteger) steps andDistance: (NSInteger) distance andCalories: (NSInteger) calories;

@end
