//
//  TDWorkoutData.m
//  Timex Connected
//
//  Created by Lev Verbitsky on 6/19/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

#import "TDWorkoutData.h"
#import "TimexWatchDB.h"
#import "iDevicesUtil.h"
#import "TDWorkoutDataUploadInfo.h"
#import "TDXMLWriter.h"
#import "TDWatchProfile.h"
#include "TDDefines.h"

@implementation TDLap

@synthesize lapTime = _lapTime;
@synthesize lapType = _lapType;

- (BOOL)isEqual:(id)object
{
    BOOL retValue = TRUE;
    
    if (!object || ![object isKindOfClass:[self class]])
        retValue = FALSE;
    else
    {
        if ([_lapType isEqualToNumber: [((TDLap *)object) lapType]] == FALSE)
            retValue = FALSE;
        else
        {
            if ([_lapTime isEqualToNumber: [((TDLap *)object) lapTime]] == FALSE)
                retValue = FALSE;
        }
    }
    
    return retValue;
}

@end

@implementation TDWorkoutData

@synthesize workoutType, numberOfScheduledRepeats, recordedNumberOfLaps, workoutDescription, workoutDate, workoutDuration, lapsData, watchProfileID, mKey, isDeleted;

- (id)init
{
	if (self = [super init])
	{
        mKey = KEY_UNKNOWN;
        watchProfileID = KEY_UNKNOWN;
        workoutType = TDWorkoutData_WorkoutTypeChrono;
        workoutDescription = NULL;
        workoutDate = NULL;
        workoutDuration = NULL;
        cachedAverageLap = NULL;
        cachedBestLap = NULL;
        numberOfScheduledRepeats = 0;
        recordedNumberOfLaps = 0;
        isDeleted = 0;
        lapsData = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (id)initWithWatchID: (NSInteger) watchID
{
	if (self = [super init])
	{
        mKey = KEY_UNKNOWN;
        watchProfileID = watchID;
        workoutType = TDWorkoutData_WorkoutTypeChrono;
        workoutDescription = NULL;
        workoutDate = NULL;
        workoutDuration = NULL;
        cachedAverageLap = NULL;
        cachedBestLap = NULL;
        numberOfScheduledRepeats = 0;
        recordedNumberOfLaps = 0;
        isDeleted = 0;
        lapsData = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (BOOL)isEqual:(id)object
{
    BOOL retValue = TRUE;
    
    if (!object || ![object isKindOfClass:[self class]])
        retValue = FALSE;
    else
    {
        if (watchProfileID != [((TDWorkoutData *)object) watchProfileID])
          retValue = FALSE;
        else
        {
            if (workoutType != [((TDWorkoutData *)object) workoutType])
                retValue = FALSE;
            else
            {
                if ([workoutDescription isEqualToString: [((TDWorkoutData *)object) workoutDescription]] == FALSE)
                    retValue = FALSE;
                else
                {
                    if ([workoutDate isEqualToDate: [((TDWorkoutData *)object) workoutDate]] == FALSE)
                        retValue = FALSE;
                    else
                    {
                        if ([workoutDuration isEqualToNumber: [((TDWorkoutData *)object) workoutDuration]] == FALSE)
                            retValue = FALSE;
                        else
                        {
                            if ([self getNumberOfLaps] != [((TDWorkoutData *)object) getNumberOfLaps])
                                retValue = FALSE;
                            else
                            {
                                NSInteger countOfLaps = [self getNumberOfLaps];
                                for (int x = 0; x < countOfLaps; x++)
                                {
                                    if ([[lapsData objectAtIndex: x] isEqual: [[((TDWorkoutData *)object) lapsData] objectAtIndex: x]] == FALSE)
                                    {
                                        retValue = FALSE;
                                        break;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    return retValue;
}

- (void) destroy
{
    NSString * deleteLapsExpression = [NSString stringWithFormat:@"DELETE FROM WorkoutLaps WHERE WorkoutID = %ld;", (long)mKey];
    TimexDatalink::IDBQuery * lapsDeleteQuery = [[TimexWatchDB sharedInstance] createQuery : deleteLapsExpression];
    if (lapsDeleteQuery)
        delete lapsDeleteQuery;
    
    NSString * deleteUplodsExpression = [NSString stringWithFormat:@"DELETE FROM WorkoutUploads WHERE WorkoutID = %ld;", (long)mKey];
    TimexDatalink::IDBQuery * uploadsDeleteQuery = [[TimexWatchDB sharedInstance] createQuery : deleteUplodsExpression];
    if (uploadsDeleteQuery)
        delete uploadsDeleteQuery;
    
    NSString * deleteWorkoutExpression = [NSString stringWithFormat:@"DELETE FROM Workouts WHERE rowID = %ld;", (long)mKey];
    TimexDatalink::IDBQuery * workoutDeleteQuery = [[TimexWatchDB sharedInstance] createQuery : deleteWorkoutExpression];
    if (workoutDeleteQuery)
        delete workoutDeleteQuery;
}

- (NSInteger) load : (NSInteger) rowID
{
    int result = kLoadResult_NotOK;
	
	NSString * expression = [NSString stringWithFormat:@"SELECT Workouts.WorkoutType, Workouts.WorkoutDescription, Workouts.isDeleted, Workouts.WorkoutScheduledRepeats, Workouts.WorkoutTotalLaps, Workouts.WorkoutDate, Workouts.WorkoutDuration, Workouts.WatchID, WorkoutLaps.WorkoutID, WorkoutLaps.LapTime, WorkoutLaps.LapTypeID FROM Workouts LEFT OUTER JOIN WorkoutLaps ON Workouts.rowID = WorkoutLaps.WorkoutID WHERE Workouts.rowID = %ld;", (long)rowID];
    
    TimexDatalink::IDBQuery * query = [[TimexWatchDB sharedInstance] createQuery : expression];
	
    if (query)
    {
        if (query->getRowCount() > 0)
        {
            mKey = rowID;
            
            workoutDescription = query->getStringColumnForRow(0, @"WorkoutDescription");
            
            workoutType = (TDWorkoutData_WorkoutType)query->getIntColumnForRow(0, @"WorkoutType");
            
            isDeleted = query -> getIntColumnForRow(0, @"isDeleted");
            
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
                
                TDLap * newLapData = [[TDLap alloc] init];
                [newLapData setLapTime: [NSNumber numberWithDouble: query->getDoubleColumnForRow(x, @"LapTime")]];
                [newLapData setLapType: [NSNumber numberWithInteger: query->getIntColumnForRow(x, @"LapTypeID")]];
                
                [lapsData addObject: newLapData];
            }
            
            result = kLoadResult_OK;
        }
        
        delete query;
	}
    
	return result;
}

- (NSInteger) getWorkoutUploadedCount
{
    NSInteger count = 0;
    
    NSString * expression = [NSString stringWithFormat:@"SELECT rowID FROM WorkoutUploads where WorkoutID = %ld;", (long)mKey];
    TimexDatalink::IDBQuery * query = [[TimexWatchDB sharedInstance] createQuery : expression];

    if (query)
    {
        count = query->getRowCount();
        delete query;
    }

	return count;
}

- (void) MarkWorkoutAsUploadedToSite: (TimexUploadServicesOptions) flag at: (NSDate *) uploadTime
{
    //first, query and see if this workout has been uploaded to this site already.
    NSString * expression = [NSString stringWithFormat:@"SELECT rowID FROM WorkoutUploads where WorkoutID = %ld AND UploadSite = %ld;", (long)mKey, (long)flag];
    
    TimexDatalink::IDBQuery * query = [[TimexWatchDB sharedInstance] createQuery : expression];
    
    if (query)
    {
        if (query->getRowCount() > 0)
        {
            NSInteger recToDelete = query->getIntColumnForRow(0, @"rowID");
            //delete this record as we are going to replace it with the later upload record... no need to pollute the DB
            NSString * deleteUploadRecExpression = [NSString stringWithFormat:@"DELETE FROM WorkoutUploads WHERE rowID = %ld;", (long)recToDelete];
            TimexDatalink::IDBQuery * recDeleteQuery = [[TimexWatchDB sharedInstance] createQuery : deleteUploadRecExpression];
            if (recDeleteQuery)
                delete recDeleteQuery;
        }
        delete query;
    }
    
    //make the record
    NSTimeInterval since1970 = [uploadTime timeIntervalSince1970];
    NSString * expressionNewUpload = [NSString stringWithFormat:@"INSERT INTO WorkoutUploads ('UploadSite', 'WorkoutID', 'UploadTime') VALUES (%ld, %ld, %f);", (long)flag, (long)mKey, since1970];
    
    TimexDatalink::IDBQuery * addNewUploadTimeQuery = [[TimexWatchDB sharedInstance] createQuery : expressionNewUpload];
    if (addNewUploadTimeQuery)
    {
        delete addNewUploadTimeQuery;
    }
}

- (NSArray *) getUploadDataForWorkout
{
    NSMutableArray * result = NULL;
    NSDateFormatter *formatter = [iDevicesUtil getDateFormatter: FALSE];
    
    NSString * expression = [NSString stringWithFormat:@"SELECT * FROM WorkoutUploads where WorkoutID = %ld;", (long)mKey];
    TimexDatalink::IDBQuery * query = [[TimexWatchDB sharedInstance] createQuery : expression];
    if (query)
    {
        result = [[NSMutableArray alloc] init];
        
        NSInteger numRecords = query->getRowCount();
        for (int i = 0; i < numRecords; i++)
        {
            TimexUploadServicesOptions selectedOption = (TimexUploadServicesOptions)query->getIntColumnForRow(i, @"UploadSite");
            
            NSTimeInterval timesince1970 = query->getDoubleColumnForRow(i, @"UploadTime");
            NSDate * uploadTime = [[NSDate alloc] initWithTimeIntervalSince1970: timesince1970];
            
            NSString * date = [formatter stringFromDate: uploadTime];
            
            TDWorkoutDataUploadInfo * newUploadInfo = [[TDWorkoutDataUploadInfo alloc] init];
            [newUploadInfo setUploadSite: selectedOption];
            [newUploadInfo setUploadTime: date];
         
            [result addObject: newUploadInfo];
        }
        
        delete query;
    }
    
    return result;
}

- (void) commitChangesToDatabase
{
    if (![self workoutDescription])
    {
        workoutDescription = [self getDefaultWorkoutName];
    }
    
    if (mKey != KEY_UNKNOWN)
	{
        NSString * expression = [NSString stringWithFormat:@"UPDATE Workouts SET WorkoutType = %d, isDeleted = %ld, WorkoutDescription = '%@', WorkoutScheduledRepeats = %ld, WorkoutTotalLaps = %ld, WorkoutDate = %f, WorkoutDuration = %f, WatchID = %ld WHERE rowID = %ld;", [self workoutType], (long)[self isDeleted], [[self workoutDescription] stringByReplacingOccurrencesOfString: @"'" withString: @"''"], (long)[self numberOfScheduledRepeats], (long)[self recordedNumberOfLaps], [[self workoutDate] timeIntervalSince1970], [[self workoutDuration] doubleValue], (long)watchProfileID, (long)mKey];
        
        TimexDatalink::IDBQuery * query = [[TimexWatchDB sharedInstance] createQuery : expression];
		if (query)
		{
			delete query;
            
            //now, first, delete all the existing stored data
            NSString * deleteLapsExpression = [NSString stringWithFormat:@"DELETE FROM WorkoutLaps WHERE WorkoutID = %ld;", (long)mKey];
            TimexDatalink::IDBQuery * lapsDeleteQuery = [[TimexWatchDB sharedInstance] createQuery : deleteLapsExpression];
            if (lapsDeleteQuery)
                delete lapsDeleteQuery;
            
            //add laps to the appropriate tables:
            NSInteger i = 0;
            for (i = 0; i < [self getNumberOfLaps]; i++)
            {
                TDLap * lapToProcess = [lapsData objectAtIndex: i];
                NSString * expressionNewLap = [NSString stringWithFormat:@"INSERT INTO WorkoutLaps ('WorkoutID', 'LapTime', 'LapTypeID') VALUES (%ld, %f, %ld);", (long)mKey, [lapToProcess.lapTime doubleValue], (long)[lapToProcess.lapType integerValue]];
                
                TimexDatalink::IDBQuery * queryLaps = [[TimexWatchDB sharedInstance] createQuery : expressionNewLap];
                if (queryLaps)
                {
                    delete queryLaps;
                }
            }
		}
	}
	else
	{
        NSTimeInterval since1970 = [[self workoutDate] timeIntervalSince1970];
		NSString * expressionNew = [NSString stringWithFormat:@"INSERT INTO Workouts ('WorkoutType', 'isDeleted', 'WorkoutDescription', 'WorkoutScheduledRepeats', 'WorkoutTotalLaps','WorkoutDate', 'WorkoutDuration', 'WatchID') VALUES (%d, %ld,'%@', %ld, %ld, %f, %f, %ld);", [self workoutType], (long)[self isDeleted], [[self workoutDescription] stringByReplacingOccurrencesOfString: @"'" withString: @"''"], (long)[self numberOfScheduledRepeats], (long)[self recordedNumberOfLaps], since1970, [[self workoutDuration] doubleValue], (long)watchProfileID];
		TimexDatalink::IDBQuery * query = [[TimexWatchDB sharedInstance] createQuery : expressionNew];
		if (query)
		{
			TimexDatalink::IDBQuery * queryID = [[TimexWatchDB sharedInstance] createQuery : @"SELECT last_insert_rowid();"];
			if (queryID)
			{
				mKey = queryID->getUIntColumnForRow(0, (uint)0);
				delete queryID;
                
                //add laps to the appropriate tables:
                NSInteger i = 0;
                for (i = 0; i < [self getNumberOfLaps]; i++)
                {
                    TDLap * lapToProcess = [lapsData objectAtIndex: i];
                    NSString * expressionNewLap = [NSString stringWithFormat:@"INSERT INTO WorkoutLaps ('WorkoutID', 'LapTime', 'LapTypeID') VALUES (%ld, %f, %ld);", (long)mKey, [lapToProcess.lapTime doubleValue], (long)[lapToProcess.lapType integerValue]];
                    
                    TimexDatalink::IDBQuery * queryLaps = [[TimexWatchDB sharedInstance] createQuery : expressionNewLap];
                    if (queryLaps)
                    {
                        delete queryLaps;
                    }
                }
			}
			
			delete query;
		}
	}
}

- (void) addLapData: (NSNumber *) duration withType: (NSInteger) type
{
    TDLap * newLap = [[TDLap alloc] init];
    newLap.lapType = [NSNumber numberWithInteger: type];
    
    newLap.lapTime = duration;
    [lapsData addObject: newLap];
    
    //all cached values need to be recalcualted
    cachedAverageLap = NULL;
    cachedBestLap = NULL;
}

- (NSInteger) getNumberOfLaps
{
    return [lapsData count];
}

- (NSInteger) getBestLapIndex
{
    NSInteger returnValue = -1;
    
    NSNumber * bestLap = [self getBestLap];
    
    NSArray * lapsTimesData = [lapsData valueForKeyPath: @"@unionOfObjects.lapTime"];
    for (NSNumber * lap in lapsTimesData)
    {
        if ([bestLap isEqualToNumber: lap])
        {
            returnValue = [lapsTimesData indexOfObject: lap];
            break;
        }
    }
    return returnValue;
}
- (NSNumber *) getAverageLap
{
    if (cachedAverageLap == NULL)
    {
        NSArray * lapTimes = [lapsData valueForKeyPath: @"@unionOfObjects.lapTime"];
        if (lapTimes && lapTimes.count > 0)
            cachedAverageLap = [lapTimes valueForKeyPath: @"@avg.doubleValue"];
        else
            cachedAverageLap = [NSNumber numberWithDouble: DBL_MAX]; //so it would be at the very end of the sort
    }
    
    return cachedAverageLap;
}
- (NSNumber *) getBestLap
{
    if (cachedBestLap == NULL)
    {
        NSArray * lapTimes = [lapsData valueForKeyPath: @"@unionOfObjects.lapTime"];
        if (lapTimes && lapTimes.count > 0)
            cachedBestLap = [lapTimes valueForKeyPath: @"@min.self"];
        else
            cachedBestLap = [NSNumber numberWithDouble: DBL_MAX]; ////so it would be at the very end of the sort
    }
    
    return cachedBestLap;
}

- (NSInteger) getNumberOfLapTypes
{
    NSArray * subsetArray = [lapsData valueForKeyPath: @"@distinctUnionOfObjects.lapType"];
    
    return [subsetArray count];
}
- (NSInteger) getLapTypeForIndex: (NSInteger) index
{
    TDLap * lap = [lapsData objectAtIndex: index];
    
    return [lap.lapType integerValue];
}
- (NSNumber *) getLapTimeForIndex: (NSInteger) index
{
    TDLap * lap = [lapsData objectAtIndex: index];
    
    return lap.lapTime;
}

- (NSNumber *) getSplitTimeForIndex: (NSInteger) index
{
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange: NSMakeRange(0, index + 1)];
    NSArray * subsetArray = [lapsData objectsAtIndexes:indexSet];
    return [[subsetArray valueForKeyPath: @"@unionOfObjects.lapTime"] valueForKeyPath: @"@sum.self"];
}

- (NSNumber *) getWorkoutDurationThroughData
{
    return [[lapsData valueForKeyPath: @"@unionOfObjects.lapTime"] valueForKeyPath: @"@sum.self"];

}
- (NSNumber *) getWorkoutDuration
{
    return workoutDuration;
}

- (NSString *) getDefaultWorkoutName
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"M/dd/yyyy"];
    NSString * date = [formatter stringFromDate: [self workoutDate]];
    
    [formatter setDateFormat:@"h:mm a"];
    NSString *time = [formatter stringFromDate: [self workoutDate]];
    
    NSArray * myStrings = [[NSArray alloc] initWithObjects: date, time, nil];
    
    NSString * stringFromDate = [myStrings componentsJoinedByString: @"\n"];
    
    return stringFromDate;
}

- (NSString *) getDefaultWorkoutName_Formatted
{
    NSDateFormatter *formatter = [iDevicesUtil getDateFormatter: TRUE];
    
    NSString * stringFromDate = [formatter stringFromDate: [self workoutDate]];
        
    return stringFromDate;
}

- (void) setWorkoutName: (NSString *) newDescription
{
    NSArray * words = [newDescription componentsSeparatedByCharactersInSet :[NSCharacterSet whitespaceCharacterSet]];
    NSString * newNameNoWhitespace = [words componentsJoinedByString:@""];
    
    if ([newNameNoWhitespace length] > 0)
    {
        workoutDescription = [newDescription stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
    }
    else
    {
        workoutDescription = [self getDefaultWorkoutName];
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
    [writer writeEndElement];
}

- (NSString *) convertToPWXformat
{
    XMLWriter * streamWriter = [[XMLWriter alloc] init];
    
    [streamWriter writeStartDocumentWithEncodingAndVersion: @"UTF-8" version: @"1.0"];
    
        [streamWriter writeStartElementWithNamespace: nil localName: @"pwx"];
        [streamWriter writeAttribute: @"xmlns" value: @"http://www.peaksware.com/PWX/1/0"];
        [streamWriter writeAttribute: @"xmlns:xsi" value: @"http://www.w3.org/2001/XMLSchema-instance"];
        [streamWriter writeAttribute: @"xsi:schemaLocation" value: @"http://www.peaksware.com/PWX/1/0 http://www.peaksware.com/PWX/1/0/pwx.xsd"];
        [streamWriter writeAttribute: @"version" value: @"1.0"];
        [streamWriter writeAttribute: @"creator" value: @"TimexMobileApp/1.0"];
    
            [streamWriter writeStartElement:@"workout"];
                [streamWriter writeStartElement:@"sportType"];
                [streamWriter writeCharacters: @"Run"];
                [streamWriter writeEndElement];
    
                [streamWriter writeStartElement:@"title"];
    
                if (![self hasDefaultName])
                {
                    [streamWriter writeCharacters: self.workoutDescription];
                }
                else
                {
                    [streamWriter writeCharacters: [[self getDefaultWorkoutName_Formatted] stringByReplacingOccurrencesOfString:@"\n" withString:@" "]];
                }
    
                [streamWriter writeEndElement];
    
                [streamWriter writeStartElement:@"device"];
                    [streamWriter writeStartElement:@"make"];
                    [streamWriter writeCharacters: @"Timex"];
                    [streamWriter writeEndElement];
    
                    switch ([[TDWatchProfile sharedInstance] watchStyle])
                    {
                        case timexDatalinkWatchStyle_ActivityTracker:
                            [streamWriter writeStartElement:@"model"];
                            [streamWriter writeCharacters: [iDevicesUtil convertTimexModuleStringToProductName: M053_WATCH_MODEL]];
                            [streamWriter writeEndElement];
                            break;
                        case timexDatalinkWatchStyle_M054:
                            [streamWriter writeStartElement:@"model"];
                            [streamWriter writeCharacters: [iDevicesUtil convertTimexModuleStringToProductName: M054_WATCH_MODEL]];
                            [streamWriter writeEndElement];
                        case timexDatalinkWatchStyle_Metropolitan:
                            [streamWriter writeStartElement:@"model"];
                            [streamWriter writeCharacters: [iDevicesUtil convertTimexModuleStringToProductName: M372_WATCH_MODEL]];
                            [streamWriter writeEndElement];
                            break;
                        default:
                            break;
                    }
    
                [streamWriter writeEndElement];
    
                [streamWriter writeStartElement:@"time"];
                [streamWriter writeCharacters: [self getWorkoutTimePWX]];
                [streamWriter writeEndElement];
 
                [self writeWorkoutSummaryData: streamWriter];
    
                for (int i = 0; i < [self getNumberOfLaps]; i++)
                {
                    [streamWriter writeStartElement:@"segment"];
                        [streamWriter writeStartElement:@"name"];
                        if (self.workoutType == TDWorkoutData_WorkoutTypeTimer)
                        {
                            NSInteger type = [self getLapTypeForIndex: i];
                            NSString * typeString = [iDevicesUtil convertIntervalTimerLabelSettingToString: (programWatch_PropertyClass_IntervalTimer_LabelEnum)type];
                           [streamWriter writeCharacters: typeString];
                        }
                        else
                        {
                            [streamWriter writeCharacters: [NSString stringWithFormat: @"Lap %d", i + 1]];
                        }
                        [streamWriter writeEndElement];
                    
                        [streamWriter writeStartElement:@"summarydata"];
                            [streamWriter writeStartElement:@"beginning"];
                            if (i == 0)
                                [streamWriter writeCharacters: @"0.00"];
                            else
                            {
                                NSNumber * splitInMilliseconds = [self getSplitTimeForIndex: i - 1];
                                NSNumber * splitInSeconds = [NSNumber numberWithDouble: [splitInMilliseconds doubleValue] / 1000];
                                [streamWriter writeCharacters: [splitInSeconds stringValue]];
                            }
                            [streamWriter writeEndElement];
                            
                            [streamWriter writeStartElement:@"duration"];
                            NSNumber * lapDurationInMilliseconds = [self getLapTimeForIndex: i];
                            NSNumber * lapDurationInSeconds = [NSNumber numberWithDouble: [lapDurationInMilliseconds doubleValue] / 1000];
                            [streamWriter writeCharacters: [lapDurationInSeconds stringValue]];
                            [streamWriter writeEndElement];
                    
                            [streamWriter writeStartElement:@"durationstopped"];
                            [streamWriter writeCharacters: @"0.00"];
                            [streamWriter writeEndElement];
                        [streamWriter writeEndElement];
                    [streamWriter writeEndElement];
                }
    
            [streamWriter writeEndElement];
    
        [streamWriter writeEndElement];
    [streamWriter writeEndDocument];
    
    NSString* xml = [streamWriter toString];
    return xml;
}

- (NSString *) getWorkoutTimePWX
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    NSString * date = [formatter stringFromDate: [self workoutDate]];
    
    //we need to absolutely, unequivocally make sure that the date that we are getting is in 24 hour format
    NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    [formatter setLocale: enUSPOSIXLocale];
    
    [formatter setDateFormat:@"HH:mm:ss"];
    NSString *time = [formatter stringFromDate: [self workoutDate]];
    
    NSArray * myStrings = [[NSArray alloc] initWithObjects: date, time, nil];
    
    NSString * stringFromDate = [myStrings componentsJoinedByString: @"T"];
    
    return stringFromDate;
}

- (BOOL) hasDefaultName
{
    NSString * currentDescr = [self workoutDescription];
    NSString * defaultDescr = [self getDefaultWorkoutName];

    if ([currentDescr caseInsensitiveCompare: defaultDescr] != NSOrderedSame )
        return FALSE;
    else
        return TRUE;
}
@end
