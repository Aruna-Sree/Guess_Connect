//
//  TDWorkoutDataManager.h
//  Timex Connected
//
//  Created by Lev Verbitsky on 6/19/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TDWorkoutDataM053.h"
#import "iDevicesUtil.h"

@interface TDWorkoutDataManager : NSObject
{
    NSMutableArray                                      * workouts;
    NSMutableArray                                      * validWorkouts;
    appSettings_PropertyClass_Workouts_SortTypeEnum     currentSortType;
}

@property (nonatomic, strong) NSMutableArray * workouts;
@property (nonatomic, strong) NSMutableArray * validWorkouts;
@property (nonatomic) appSettings_PropertyClass_Workouts_SortTypeEnum currentSortType;

- (TDWorkoutData *) getWorkoutAtIndex: (NSInteger) index;
- (TDWorkoutData *) getWorkoutByID: (NSInteger) wID;
- (TDWorkoutData *) getWorkoutOnDate: (NSDate *) date;
- (NSArray *) getWorkoutsFrom: (NSDate *) dateStart to: (NSDate *) dateEnd;
- (void) addWorkout: (TDWorkoutData *) obj resortWorkouts: (BOOL) resortFlag;
- (void) removeWorkout: (TDWorkoutData *) obj;
- (void) clearData;
- (void) resortWorkoutsByCurrentSortType;
- (void) resortWorkoutsBy: (appSettings_PropertyClass_Workouts_SortTypeEnum) sortMethod;
- (NSMutableArray *) getValidWorkouts;
@end
