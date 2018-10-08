//
//  M372ActigraphyStepFile.m
//  SleepTrackerFilesTool
//
//  Created by Diego Santiago on 3/11/16.
//  Copyright © 2016 Diego Santiago. All rights reserved.
//
/**
 * From the Spec:
 *
 * This file will store the current Steps, Distance, and Calories provided at the end of specified
 * time period (currently 1 Hour). A new file will be created at the Midnight Rollover. Each file
 * will contain one day’s worth of data, so there will be 24 records consisting of Steps, Distance,
 * and Calories in each file. The Epoch Counts data will be initialized to 0xFF at the creation
 * and re-initialization of a file. The file will also contain the date the file was generated.
 * File names will be in the format M372R0xx.SLP, M372R1xx.SLP, M372R2xx.SLP…M372R7xx.SLP. Each
 * file will represent a 24 hour period (Midnight to Midnight). xx represents the revision number
 * of the file.
 *
 //        typedef struct
 //        {
 //            uint16_t MaxNumberRecords;  // Maximum number of records in the file
 //            uint16_t RecordPeriod;      // Number of seconds between records
 //            uint8_t Date;               // (1 - 31)
 //            uint8_t Month;              // (1 - 12)
 //            uint8_t Year;               // (0 – 99, offset from 2000)
 //            uint8_t Validity;           // 0 is invalid
 //            uint8_t         Reserved[NUM_RESERVED_ACT_STEPS];  // 3 Reserved
 //            ActigraphyStepsRecord_t Record[MAX_NUM_ACTIGRAPHY_STEPS_RECORDS]; //24 Records
 //            uint32_t Checksum;
 //        } ActigraphyStepsFile_t;
 //
 // Each step record is structured as follows:
 //
 //   typedef struct
 //        {
 //            uint32_t Steps : 24; // (0 - 99,9999)
 //            uint16_t Distance; // (99.99 kilometers stores as ( 0 - 9999)
 //            uint32_t Calories : 24; // (0 - 9999.0 stored as 0 - 99990)
 //        } ActigraphyStepsRecord_t;
 ***/

#import "TDM372ActigraphyStepFile.h"
#import "TDResources.h"
#import "TDActigraphyStepTrackerRecord.h"

#import "OTLogUtil.h"
#import "DBManager.h"
#import "DBModule.h"
#import "DBActivity+CoreDataClass.h"
#import "HourActivityModal.h"
#import "DBHourActivity+CoreDataClass.h"
#import "iDevicesUtil.h"

@interface TDM372ActigraphyStepFile()
{
    Byte activitiesNumber;
    NSMutableArray * mActivities;
    double previousSteps;
    double previousDistance;
    double previousCalories;
}
@end

@implementation TDM372ActigraphyStepFile
- (id) init
{
    if (self = [super init])
    {
        mActivities = [[NSMutableArray alloc] init];
    }
    
    return self;
}
- (id) init: (NSData *) inData
{
    if (self = [self init])
    {
        [self readActStepFile: inData];
    }
    
    return self;
}


- (int ) readActStepFile: (NSData *) inDataObject
{
    int error = noErr;
    
    TDResources *rec = [[TDResources alloc]init];
    NSMutableDictionary *result = [[NSMutableDictionary alloc]init];
    if (result.count > 0)
        [result removeAllObjects];
    
    Byte inData[inDataObject.length];
    [inDataObject getBytes: inData];
    
#if DEBUG
    OTLog(@"Watch Activities Info received");
    OTLog(@"raw Data: \n%@", inDataObject);
#endif
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"YYYY-MM-dd"];
    
    Byte ptrBytesInt[4];
    activitiesNumber = inData[0];
    
    ///Get date first
    _mDay = inData[4];
    _mMonth = inData[5];
    _mYear = inData[6];
    NSDate * newDate = [rec getActivityDateYearTwo:_mDay month:_mMonth year:_mYear];
    
    NSDate *today = [iDevicesUtil todayDateAtMidnight];
    NSCalendar *gregorian = [NSCalendar currentCalendar];
    [gregorian setTimeZone:[NSTimeZone systemTimeZone]];
    NSDate *past7day = [gregorian dateByAddingUnit:NSCalendarUnitDay value:-7 toDate:today options:nil];
    if (![iDevicesUtil date:newDate isBetweenDate:past7day andDate:today]) {
        return error;
    }
    
    _mStatus = inData[7];
    
    if (_mStatus != 0)
    {
        int offsetFromStart = 11;
        for ( int i = 0; i <= activitiesNumber - 1; i++ )
        {
            TDActigraphyStepTrackerRecord * newActivity = [[TDActigraphyStepTrackerRecord alloc] init];
            memset(ptrBytesInt, 0, 4);
            [inDataObject getBytes: ptrBytesInt range: NSMakeRange(offsetFromStart, 3)];
            newActivity.mTotalSteps = [iDevicesUtil byteArrayToInt: ptrBytesInt];
            offsetFromStart += 3;
            
            newActivity.mTotalDistance = *((short *)&inData[offsetFromStart]);
            offsetFromStart += 2;
            
            memset(ptrBytesInt, 0, 4);
            [inDataObject getBytes: ptrBytesInt range: NSMakeRange(offsetFromStart, 3)];
            newActivity.mTotalCalories = [iDevicesUtil byteArrayToInt: ptrBytesInt];
            offsetFromStart += 3;
            
            newActivity.mTimeId = [NSString stringWithFormat:@"%02i",(i)];
            newActivity.date = newDate;
#if DEBUG
            OTLog(@"==============================");
            OTLog(@"Date: %@", [formatter stringFromDate: newActivity.date]);
            OTLog(@"Total steps: %d", newActivity.mTotalSteps);
            OTLog(@"Total distance: %d", newActivity.mTotalDistance);
            OTLog(@"Total calories: %d", newActivity.mTotalCalories);
            OTLog(@"Time : %@", newActivity.mTimeId);
#endif
            [mActivities addObject: newActivity];
        }
        [self addOrUpdateHourActivities];
    }
    return error;
}

- (void)addOrUpdateHourActivities {
    previousSteps = 0.0;
    previousDistance = 0.0;
    previousCalories = 0.0;
    for (TDActigraphyStepTrackerRecord * newActivity in mActivities)
    {
        NSDate *activityDate = newActivity.date;
        DBActivity *activity = (DBActivity*)[[DBModule sharedInstance]getEntity:@"DBActivity" columnName:@"date" value:activityDate];
        if (activity != nil) {
            OTLog(@"Updating Activity");
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(%K==%@) AND (timeID==%@)",@"date",activityDate,newActivity.mTimeId];
            DBHourActivity *hourActivity = (DBHourActivity *)[[DBModule sharedInstance] getEntity:@"DBHourActivity" withPredicate:predicate];
            double currentSteps = MAX(((long)[newActivity mTotalSteps] - previousSteps),0.0);
            double currentDistance = MAX(((long)[newActivity mTotalDistance] - previousDistance),0.0);
            double currentCalories = MAX(((long)[newActivity mTotalCalories] - previousCalories),0.0);
            
            if (hourActivity != nil) {
                OTLog(@"Updating HourActivity");
                hourActivity.date = activityDate;
                hourActivity.timeID = newActivity.mTimeId;
                hourActivity.steps = [NSNumber numberWithDouble:currentSteps];
                hourActivity.distance = [NSNumber numberWithDouble:currentDistance];
                hourActivity.calories = [NSNumber numberWithDouble:currentCalories];
            } else {
                OTLog(@"Creating HourActivity");
                HourActivityModal *modal = [[HourActivityModal alloc] init];
                modal.date = activityDate;
                modal.timeID = newActivity.mTimeId;
                modal.steps = [NSNumber numberWithDouble:currentSteps];
                modal.distance = [NSNumber numberWithDouble:currentDistance];
                modal.calories = [NSNumber numberWithDouble:currentCalories];
                hourActivity = [DBManager addOrUpdateHourActivity:modal];
            }
            NSMutableSet *hourActivitiesSet = [activity.hourActivities mutableCopy];
            [hourActivitiesSet addObject:hourActivity];
            activity.hourActivities = hourActivitiesSet;
            previousSteps = (long)[newActivity mTotalSteps];
            previousDistance = (long)[newActivity mTotalDistance];
            previousCalories = (long)[newActivity mTotalCalories];
        }
    }
    [[DBModule sharedInstance] saveContext];
}
@end
