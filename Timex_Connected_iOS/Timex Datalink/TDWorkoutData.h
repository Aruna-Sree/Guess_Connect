//
//  TDWorkoutData.h
//  Timex Connected
//
//  Created by Lev Verbitsky on 6/19/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "iDevicesUtil.h"

enum TDWorkoutData_WorkoutType
{
    TDWorkoutData_WorkoutTypeChrono = 0,
    TDWorkoutData_WorkoutTypeTimer
};

@interface TDLap : NSObject

@property (nonatomic, strong) NSNumber * lapTime;
@property (nonatomic, strong) NSNumber * lapType;

@end

@interface TDWorkoutData : NSObject
{
    NSInteger                   mKey;
    NSInteger                   watchProfileID;
    TDWorkoutData_WorkoutType   workoutType;
    NSString                    * workoutDescription;
    NSDate                      * workoutDate;
    NSNumber                    * workoutDuration;
    NSInteger                   numberOfScheduledRepeats;
    NSInteger                   recordedNumberOfLaps;
    
    NSMutableArray              * lapsData;
    
    //speed optimization things
    NSNumber                    * cachedAverageLap;
    NSNumber                    * cachedBestLap;
    NSInteger                    isDeleted;
}

@property (nonatomic) NSInteger  mKey;
@property (nonatomic) NSInteger watchProfileID;
@property (nonatomic, readonly) NSInteger numberOfScheduledRepeats;
@property (nonatomic, readonly) NSInteger recordedNumberOfLaps;
@property (nonatomic, readonly) TDWorkoutData_WorkoutType workoutType;
@property (nonatomic, strong, readonly) NSString * workoutDescription;
@property (nonatomic, strong, readonly) NSDate * workoutDate;
@property (nonatomic, strong, readonly) NSNumber * workoutDuration;
@property (nonatomic, strong) NSMutableArray * lapsData;
@property (nonatomic) NSInteger isDeleted;
- (id)init;
- (BOOL)isEqual:(id)object;

- (id)initWithWatchID: (NSInteger) watchID;
- (NSInteger) load : (NSInteger) rowID;
- (void) destroy;
- (void) commitChangesToDatabase;

- (void) addLapData: (NSNumber *) duration withType: (NSInteger) type;
- (void) setWorkoutName: (NSString *) newDescription;

- (NSInteger) getNumberOfLaps;
- (NSInteger) getBestLapIndex;
- (NSNumber *) getAverageLap;
- (NSNumber *) getBestLap;
- (NSNumber *) getWorkoutDuration;
- (NSNumber *) getWorkoutDurationThroughData;
- (NSInteger) getNumberOfLapTypes;
- (NSInteger) getLapTypeForIndex: (NSInteger) index;
- (NSNumber *) getLapTimeForIndex: (NSInteger) index;
- (NSNumber *) getSplitTimeForIndex: (NSInteger) index;

- (NSString *) getDefaultWorkoutName;
- (NSString *) getDefaultWorkoutName_Formatted;
- (NSInteger) getWorkoutUploadedCount;
- (void) MarkWorkoutAsUploadedToSite: (TimexUploadServicesOptions) flag at: (NSDate *) uploadTime;
- (NSArray *) getUploadDataForWorkout;

- (NSString *) convertToPWXformat;

- (BOOL) hasDefaultName;
@end
