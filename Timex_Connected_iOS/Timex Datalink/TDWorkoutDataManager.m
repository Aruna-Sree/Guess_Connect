//
//  TDWorkoutDataManager.m
//  Timex Connected
//
//  Created by Lev Verbitsky on 6/19/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

#import "TDWorkoutDataManager.h"
#import "iDevicesUtil.h"

@implementation TDWorkoutDataManager

@synthesize workouts, currentSortType, validWorkouts;

- (id)init
{
	if (self = [super init])
	{
        workouts = [[NSMutableArray alloc] init];
        
        //read the current sort type from the settings
        
        NSString * key = [iDevicesUtil createKeyForAppSettingsPropertyWithClass: appSettings_PropertyClass_Workouts andIndex: appSettings_PropertyClass_Workouts_SortType];
        
        NSInteger setting = 0;
        if ([[NSUserDefaults standardUserDefaults] objectForKey: key] != nil)
            setting = [[NSUserDefaults standardUserDefaults] integerForKey: key];
        else
        {
            setting = appSettings_PropertyClass_Workouts_SortType_WorkoutDate;
            [[NSUserDefaults standardUserDefaults] setInteger: setting forKey: key];
        }
        
        currentSortType = (appSettings_PropertyClass_Workouts_SortTypeEnum) setting;
    }
    
    return self;
}
- (void) addWorkout: (TDWorkoutData *) obj resortWorkouts: (BOOL) resortFlag
{
    [workouts addObject: obj];
    
    if (resortFlag == TRUE)
    {
        [self resortWorkoutsByCurrentSortType];
    }
}

- (void) resortWorkoutsByCurrentSortType
{
   [self resortWorkoutsBy: currentSortType]; 
}

- (void) removeWorkout: (TDWorkoutData *) obj
{
    obj.isDeleted = 1;
//    [obj destroy]; // Not removing from DB just maintaing deletion flag
//    [workouts removeObject: obj];
}
- (void) clearData
{
    [workouts removeAllObjects];
}

- (void) resortWorkoutsBy: (appSettings_PropertyClass_Workouts_SortTypeEnum) sortMethod
{
    currentSortType = sortMethod;
    
    NSArray * newArray = nil;
    if (sortMethod == appSettings_PropertyClass_Workouts_SortType_WorkoutDate)
    {
        newArray = [workouts sortedArrayUsingComparator:^NSComparisonResult(id a, id b)
                    {
                        NSDate *first = [(TDWorkoutData *)a workoutDate];
                        NSDate *second = [(TDWorkoutData *)b workoutDate];
                        if (first != nil && second != nil)
                            return [second compare: first];
                        else
                            return NSOrderedSame;
                    }];
    }
    else if (sortMethod == appSettings_PropertyClass_Workouts_SortType_BestLap)
    {
        newArray = [workouts sortedArrayUsingComparator:^NSComparisonResult(id a, id b)
                    {
                        NSNumber *first = [(TDWorkoutData *)a getBestLap];
                        NSNumber *second = [(TDWorkoutData *)b getBestLap];
                        if (first != nil && second != nil)
                            return [first compare:second];
                        else
                            return NSOrderedSame;
                    }];
    }
    else if (sortMethod == appSettings_PropertyClass_Workouts_SortType_AverageLap)
    {
        newArray = [workouts sortedArrayUsingComparator:^NSComparisonResult(id a, id b)
                    {
                        NSNumber *first = [(TDWorkoutData *)a getAverageLap];
                        NSNumber *second = [(TDWorkoutData *)b getAverageLap];
                        if (first != nil && second != nil)
                            return [first compare:second];
                        else
                            return NSOrderedSame;
                    }];
    }
    else if (sortMethod == appSettings_PropertyClass_Workouts_SortType_NumberOfLaps)
    {
        newArray = [workouts sortedArrayUsingComparator:^NSComparisonResult(id a, id b)
                    {
                        NSNumber *first = [NSNumber numberWithInteger: [(TDWorkoutData *)a getNumberOfLaps]];
                        NSNumber *second = [NSNumber numberWithInteger: [(TDWorkoutData *)b getNumberOfLaps]];
                        if (first != nil && second != nil)
                            return [second compare: first];
                        else
                            return NSOrderedSame;
                    }];
    }
    else if (sortMethod == appSettings_PropertyClass_Workouts_SortType_TotalWorkoutTime)
    {
        newArray = [workouts sortedArrayUsingComparator:^NSComparisonResult(id a, id b)
                    {
                        NSNumber *first = [(TDWorkoutData *)a getWorkoutDuration];
                        NSNumber *second = [(TDWorkoutData *)b getWorkoutDuration];
                        if (first != nil && second != nil)
                            return [first compare:second];
                        else
                            return NSOrderedSame;
                    }];
    }
    else if (sortMethod == appSettings_PropertyClass_Workouts_SortType_WorkoutType)
    {
        newArray = [workouts sortedArrayUsingComparator:^NSComparisonResult(id a, id b)
                    {
                        NSNumber *first = [NSNumber numberWithInteger: [(TDWorkoutData *)a workoutType]];
                        NSNumber *second = [NSNumber numberWithInteger: [(TDWorkoutData *)b workoutType]];
                        if (first != nil && second != nil)
                            return [first compare:second];
                        else
                            return NSOrderedSame;
                    }];
    }
    workouts = [[NSMutableArray alloc] initWithArray: newArray];
}

- (TDWorkoutData *) getWorkoutOnDate: (NSDate *) date
{
    NSUInteger idx = NSNotFound;
    
    idx = [workouts indexOfObjectPassingTest:
           ^ BOOL (TDWorkoutData* wrk, NSUInteger idx, BOOL *stop)
           {
               return [[wrk workoutDate] compare: date] == NSOrderedSame;
           }];
    
    return idx != NSNotFound ? [workouts objectAtIndex: idx] : NULL;
}

- (NSArray *) getWorkoutsFrom: (NSDate *) dateStart to: (NSDate *) dateEnd
{
    NSIndexSet * whatWeNeed = [workouts indexesOfObjectsPassingTest:
                  ^ BOOL (TDWorkoutData* wrk, NSUInteger idx, BOOL *stop)
                  {
                      if ([[wrk workoutDate] compare: dateStart] == NSOrderedAscending)
                          return NO;
                      
                      if ([[wrk workoutDate] compare: dateEnd] == NSOrderedDescending)
                          return NO;
                      
                      return YES;
                  }];
    
    return [workouts objectsAtIndexes: whatWeNeed];
}

- (TDWorkoutData *) getWorkoutByID: (NSInteger) wID
{
    NSUInteger idx = NSNotFound;
    
    idx = [workouts indexOfObjectPassingTest:
                      ^ BOOL (TDWorkoutData* wrk, NSUInteger idx, BOOL *stop)
                      {
                          return [wrk mKey] == wID;
                      }];
    
    return idx != NSNotFound ? [workouts objectAtIndex: idx] : NULL;
}
- (TDWorkoutData *) getWorkoutAtIndex: (NSInteger) index
{
    return [workouts objectAtIndex: index];
}

- (NSMutableArray *) getValidWorkouts {
    self.validWorkouts = [self.workouts mutableCopy];
    for (TDWorkoutData *workout in self.workouts) {
        if (workout.isDeleted == 1) {
            [self.validWorkouts removeObject:workout];
        }
    }
    return self.validWorkouts;
}
@end
