//
//  TDWorkoutDataM053.m
//  Timex
//
//  Created by Lev Verbitsky on 10/6/14.
//  Copyright (c) 2014 iDevices, LLC. All rights reserved.
//

#import "TDWorkoutDataM053.h"
#import "TimexWatchDB.h"
#import "TDXMLWriter.h"

@implementation  TDLapActivityTracker

@synthesize mKey = _mKey;
@synthesize totalSteps = _totalSteps;
@synthesize totalDistance = _totalDistance;
@synthesize totalCalories = _totalCalories;

@end

@implementation TDWorkoutDataActivityTracker

@synthesize totalSteps = _totalSteps;
@synthesize totalDistance = _totalDistance;
@synthesize totalCalories = _totalCalories;

- (void) destroy
{
    for (int i = 0; i < [self getNumberOfLaps]; i++)
    {
        TDLapActivityTracker * lapToProcess = [lapsData objectAtIndex: i];
        
        NSString * deleteLapActivityExpression = [NSString stringWithFormat:@"DELETE FROM ActivityData WHERE LapID = %ld;", (long)lapToProcess.mKey];
        TimexDatalink::IDBQuery * lapActivityDeleteQuery = [[TimexWatchDB sharedInstance] createQuery : deleteLapActivityExpression];
        if (lapActivityDeleteQuery)
            delete lapActivityDeleteQuery;
    }
    
    NSString * deleteWorkoutActivityExpression = [NSString stringWithFormat:@"DELETE FROM ActivityData WHERE WorkoutID = %ld;", (long)mKey];
    TimexDatalink::IDBQuery * workoutActivityDeleteQuery = [[TimexWatchDB sharedInstance] createQuery : deleteWorkoutActivityExpression];
    if (workoutActivityDeleteQuery)
        delete workoutActivityDeleteQuery;
    
    [super destroy];
}

- (NSInteger) load : (NSInteger) rowID
{
    int result = kLoadResult_NotOK;
    
    NSString * expression = [NSString stringWithFormat:@"SELECT Workouts.WorkoutType, Workouts.WorkoutDescription, Workouts.WorkoutScheduledRepeats, Workouts.WorkoutTotalLaps, Workouts.WorkoutDate, Workouts.WorkoutDuration, Workouts.WatchID, WorkoutLaps.rowID, WorkoutLaps.WorkoutID, WorkoutLaps.LapTime, WorkoutLaps.LapTypeID, ActivityData.ActivitySteps, ActivityData.ActivityDistance, ActivityData.ActivityCalories FROM Workouts LEFT OUTER JOIN WorkoutLaps ON Workouts.rowID = WorkoutLaps.WorkoutID LEFT OUTER JOIN ActivityData ON Workouts.rowID = ActivityData.WorkoutID WHERE Workouts.rowID = %ld;", (long)rowID];
    
    TimexDatalink::IDBQuery * query = [[TimexWatchDB sharedInstance] createQuery : expression];
    
    if (query)
    {
        if (query->getRowCount() > 0)
        {
            mKey = rowID;
            
            _totalSteps = query->getIntColumnForRow(0, @"ActivitySteps");
            _totalDistance = query->getIntColumnForRow(0, @"ActivityDistance");
            _totalCalories = query->getIntColumnForRow(0, @"ActivityCalories");
            
            workoutDescription = query->getStringColumnForRow(0, @"WorkoutDescription");
            
            workoutType = (TDWorkoutData_WorkoutType)query->getIntColumnForRow(0, @"WorkoutType");
            
            if (workoutType == TDWorkoutData_WorkoutTypeTimer)
                numberOfScheduledRepeats = query->getIntColumnForRow(0, @"WorkoutScheduledRepeats");
            else
                numberOfScheduledRepeats = 0;
            
            if (workoutType == TDWorkoutData_WorkoutTypeChrono)
                recordedNumberOfLaps = query->getIntColumnForRow(0, @"WorkoutTotalLaps");
            else
                recordedNumberOfLaps = 0;
            
            NSTimeInterval timesince1970 = query->getDoubleColumnForRow(0, @"WorkoutDate");
            workoutDate = [[NSDate alloc] initWithTimeIntervalSince1970: timesince1970];
            
            workoutDuration = [NSNumber numberWithDouble: query->getDoubleColumnForRow(0, @"WorkoutDuration")];
            
            watchProfileID = query->getIntColumnForRow(0, @"WatchID");
            
            //process the laps data
            for (int x = 0; x < query->getRowCount(); x++)
            {
                //it is possible to have a workout with NO laps at all... for example, if the user has Interval Workout and never completed an interval. In this case,
                //our query will still be valid, but the values from the WorkoutLaps table will be NULLS... we need to skip any such row since it is invalid
                if ([query->getColumnForRow(x, @"LapTime") isKindOfClass:[NSNull class]] && [query->getColumnForRow(x, @"LapTypeID") isKindOfClass:[NSNull class]])
                {
                    continue;
                }
                
                TDLapActivityTracker * newLapData = [[TDLapActivityTracker alloc] init];
                newLapData.mKey = query->getIntColumnForRow(x, @"rowID");
                [newLapData setLapTime: [NSNumber numberWithDouble: query->getDoubleColumnForRow(x, @"LapTime")]];
                [newLapData setLapType: [NSNumber numberWithInteger: query->getIntColumnForRow(x, @"LapTypeID")]];
                
                NSString * expressionLapsActivity = [NSString stringWithFormat:@"SELECT ActivitySteps, ActivityDistance, ActivityCalories FROM ActivityData WHERE LapID = %ld;", (long)newLapData.mKey];
                TimexDatalink::IDBQuery * queryActivityForLap = [[TimexWatchDB sharedInstance] createQuery : expressionLapsActivity];
                if (queryActivityForLap)
                {
                    newLapData.totalSteps = queryActivityForLap->getIntColumnForRow(0, @"ActivitySteps");
                    newLapData.totalDistance = queryActivityForLap->getIntColumnForRow(0, @"ActivityDistance");
                    newLapData.totalCalories = queryActivityForLap->getIntColumnForRow(0, @"ActivityCalories");
                    
                    delete queryActivityForLap;
                }
                
                [lapsData addObject: newLapData];
            }
            
            result = kLoadResult_OK;
        }
        
        delete query;
    }
    
    return result;
}

- (void) addLapData: (NSNumber *) duration withType: (NSInteger) type withSteps: (NSInteger) steps andDistance: (NSInteger) distance andCalories: (NSInteger) calories
{
    TDLapActivityTracker * newLap = [[TDLapActivityTracker alloc] init];
    newLap.lapType = [NSNumber numberWithInteger: type];
    
    newLap.lapTime = duration;
    newLap.totalSteps = steps;
    newLap.totalDistance = distance;
    newLap.totalCalories = calories;
    
    [lapsData addObject: newLap];
    
    //all cached values need to be recalcualted
    cachedAverageLap = NULL;
    cachedBestLap = NULL;
}

- (void) commitChangesToDatabase
{
    if (![self workoutDescription])
    {
        workoutDescription = [self getDefaultWorkoutName];
    }
    
    if (mKey != KEY_UNKNOWN)
    {
        NSString * expression = [NSString stringWithFormat:@"UPDATE Workouts SET WorkoutType = %d, WorkoutDescription = '%@', WorkoutScheduledRepeats = %ld, WorkoutTotalLaps = %ld, WorkoutDate = %f, WorkoutDuration = %f, WatchID = %ld WHERE rowID = %ld;", [self workoutType], [[self workoutDescription] stringByReplacingOccurrencesOfString: @"'" withString: @"''"], (long)[self numberOfScheduledRepeats], (long)[self recordedNumberOfLaps], [[self workoutDate] timeIntervalSince1970], [[self workoutDuration] doubleValue], (long)watchProfileID, (long)mKey];
        
        TimexDatalink::IDBQuery * query = [[TimexWatchDB sharedInstance] createQuery : expression];
        if (query)
        {
            delete query;
        }
    }
    else
    {
        NSTimeInterval since1970 = [[self workoutDate] timeIntervalSince1970];
        NSString * expressionNew = [NSString stringWithFormat:@"INSERT INTO Workouts ('WorkoutType', 'WorkoutDescription', 'WorkoutScheduledRepeats', 'WorkoutTotalLaps','WorkoutDate', 'WorkoutDuration', 'WatchID') VALUES (%d,'%@', %ld, %ld, %f, %f, %ld);", [self workoutType], [[self workoutDescription] stringByReplacingOccurrencesOfString: @"'" withString: @"''"], (long)[self numberOfScheduledRepeats], (long)[self recordedNumberOfLaps], since1970, [[self workoutDuration] doubleValue], (long)watchProfileID];
        TimexDatalink::IDBQuery * query = [[TimexWatchDB sharedInstance] createQuery : expressionNew];
        if (query)
        {
            TimexDatalink::IDBQuery * queryID = [[TimexWatchDB sharedInstance] createQuery : @"SELECT last_insert_rowid();"];
            if (queryID)
            {
                mKey = queryID->getUIntColumnForRow(0, (uint)0);
                delete queryID;
                
                //add activity information to the appropriate table:
                NSString * expressionNewWorkoutActivity = [NSString stringWithFormat: @"INSERT INTO ActivityData ('ActivityDate', 'ActivitySteps', 'ActivityDistance', 'ActivityCalories', 'WorkoutID', 'LapID') VALUES (%f, %ld,'%ld', %ld, %ld, NULL);", since1970, (long)[self totalSteps], (long)[self totalDistance], (long)[self totalCalories], (long)mKey];
                
                TimexDatalink::IDBQuery * queryNewWorkoutActivity = [[TimexWatchDB sharedInstance] createQuery : expressionNewWorkoutActivity];
                if (queryNewWorkoutActivity)
                {
                    delete queryNewWorkoutActivity;
                    
                    //add laps to the appropriate tables:
                    NSInteger i = 0;
                    for (i = 0; i < [self getNumberOfLaps]; i++)
                    {
                        TDLapActivityTracker * lapToProcess = [lapsData objectAtIndex: i];
                        NSString * expressionNewLap = [NSString stringWithFormat:@"INSERT INTO WorkoutLaps ('WorkoutID', 'LapTime', 'LapTypeID') VALUES (%ld, %f, %ld);", (long)mKey, [lapToProcess.lapTime doubleValue], (long)[lapToProcess.lapType integerValue]];
                        
                        TimexDatalink::IDBQuery * queryLaps = [[TimexWatchDB sharedInstance] createQuery : expressionNewLap];
                        if (queryLaps)
                        {
                            TimexDatalink::IDBQuery * queryIDLap = [[TimexWatchDB sharedInstance] createQuery : @"SELECT last_insert_rowid();"];
                            if (queryID)
                            {
                                lapToProcess.mKey = queryIDLap->getUIntColumnForRow(0, (uint)0);
                                delete queryIDLap;
                            
                                NSString * expressionNewLapActivity = [NSString stringWithFormat: @"INSERT INTO ActivityData ('ActivityDate', 'ActivitySteps', 'ActivityDistance', 'ActivityCalories', 'WorkoutID', 'LapID') VALUES (%f, %ld,'%ld', %ld, NULL, %ld);", since1970, (long)[lapToProcess totalSteps], (long)[lapToProcess totalDistance], (long)[lapToProcess totalCalories], (long)lapToProcess.mKey];
                            
                                TimexDatalink::IDBQuery * queryNewLapActivity = [[TimexWatchDB sharedInstance] createQuery : expressionNewLapActivity];
                                if (queryNewLapActivity)
                                {
                                    delete queryNewLapActivity;
                                }
                            }
                            
                            delete queryLaps;
                        }
                    }
                }
            }
            
            delete query;
        }
    }
}

- (void) writeWorkoutSummaryData: (XMLWriter *) writer
{
    [writer writeStartElement:@"summarydata"];
    [writer writeStartElement:@"beginning"];
    [writer writeCharacters: @"0.00"];
    [writer writeEndElement];
    
    [writer writeStartElement:@"duration"];
    NSNumber * durationInMilliseconds = [self getWorkoutDuration];
    NSNumber * durationInSeconds = [NSNumber numberWithDouble: [durationInMilliseconds doubleValue] / 1000];
    [writer writeCharacters: [durationInSeconds stringValue]];
    [writer writeEndElement];
    
    [writer writeStartElement:@"durationstopped"];
    [writer writeCharacters: @"0.00"];
    [writer writeEndElement];
    
    NSInteger distanceInKilometers = [self totalDistance]; //From the Timex M053 spec: Total distance in kilometres with 2-digit decimal. Divide by 100 to get actual value.
    NSInteger distanceInMeters = distanceInKilometers * 10;
    if (distanceInMeters != 0)
    {
        NSNumber * distance = nil;
        distance = [NSNumber numberWithInteger: distanceInMeters];
        [writer writeStartElement:@"dist"];
        [writer writeCharacters: [distance stringValue]];
        [writer writeEndElement];
    }
    
    [writer writeEndElement];
}

@end
