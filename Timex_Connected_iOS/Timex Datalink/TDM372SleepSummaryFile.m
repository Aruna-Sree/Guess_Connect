//
//  M372SleepSummaryFile.m
//  Timex
//
//  Created by Diego Santiago on 3/10/16.
//  Copyright © 2016 iDevices, LLC. All rights reserved.
//
/**
 * From the spec:
 * This file will contain the Sleep Summary Data returned by xmActive at the end of a Sleep
 * Event/Sleep Session. The file name will be of the format M372Sxxx.SLP
 * This file will consist of a list of records (40 as of now), and will be treated as a circular
 * buffer. Each Record will have its own date and timestamp, and will contain the Sleep Summary
 * data, which consists of start date and time, end time, duration of sleep, etc.
 *
 //    typedef struct
 //        {
 //           uint8_t MaxRecordNumber;              // (0 - 255)
 //            uint8_t NextRecordIndex;             // (0 - 255)
 //            uint8_t         reserved[2];        //  documentation is wrong, pad is 3 bytes.
 //            SummaryRecord_t SummaryRecord[40];  // (1 – 255)
 //            uint32_t checksum;                  // (0 – 0xFFFFFFFF)
 //        }SleepSummary_t ;
 //
 // Each record is formatted as follows:
 //
 //    typedef struct
 //        {
 //            uint8_t Date; // (1 - 31)
 //            uint8_t Month; // (1 - 12)
 //            uint8_t Year; // (0 - 255)
 //            uint8_t StartMinute; // (0 - 59)
 //            uint8_t StartHour; // (0 - 23)
 //            uint8_t EndHour; // (0 - 59)
 //            uint8_t EndMinute; // (0 - 23)
 //            uint8_t EndDate; // (1 - 31)
 //            uint8_t EndMonth; // (1 - 12)
 //            uint8_t EndYear; // (0 - 99)
 //            uint8_t SleepOffset; // (0 - 120)
 //            uint16_t Duration; // (0 - 65535)
 //            uint8_t Validity; // 0 is invalid
 //        }SummaryRecord_t ;
 
 ***/
#import "iDevicesUtil.h"
#import "TDM372SleepSummaryFile.h"
#import "TDM372SleepSummaryTrackerRecord.h"
#import "OTLogUtil.h"
#import "TDWatchProfile.h"
#import "DBManager.h"
#import "DBModule.h"
#import "SleepEventsModal.h"
#import "DBSleepEvents.h"
#import "DBActivity+CoreDataClass.h"
#import "ActivityModal.h"
#import "TDDefines.h"
@interface TDM372SleepSummaryFile()
{
    Byte activitiesNumber;
    NSMutableArray * mActivities;
    uint32_t  checksum;
    
    
    NSMutableArray *resultArrayBig;
}
@end
@implementation TDM372SleepSummaryFile
- (id) init
{
    if (self = [super init])
    {
        mActivities = [[NSMutableArray alloc] init];
    }
    
    return self;
}
//@synthesize mMaxRecordNumber    = _mMaxRecordNumber;
//@synthesize mNextRecordIndex    = _mNextRecordIndex;
//@synthesize mSumaryrecords      = _mSumaryrecords;
//
//
//@synthesize mDay    = _mDay;
//@synthesize mMonth  = _mMonth;
//@synthesize mYear   = _mYear;
//
//@synthesize mStartMinute    = _mStartMinute;
//@synthesize mStartHour      = _mStartHour;
//@synthesize mEndHour        = _mEndHour;
//@synthesize mEndMinute      = _mEndMinute;
//@synthesize mEndDate        = _mEndDate;
//@synthesize mEndMonth       = _mEndMonth;
//@synthesize mEndYear        = _mEndYear;
//@synthesize mSleepOffSet    = _mSleepOffSet;
//@synthesize mDuration       = _mDuration;


- (id) init: (NSData *) inData
{
    if (self = [self init])
    {
        [self readSleepActivities: inData];
    }
    
    return self;
}

- (int ) readSleepActivities: (NSData *) inDataObject
{
    OTLog(@"read sleep activities");
    int error = noErr;
    NSMutableDictionary *activityDict = [[NSMutableDictionary alloc]init];
    if (activityDict.count >0)
        [activityDict removeAllObjects];
    
    NSMutableDictionary *result = [[NSMutableDictionary alloc]init];
    if (result.count > 0)
        [result removeAllObjects];
    
    
    resultArrayBig = [[NSMutableArray alloc]init];
    if (resultArrayBig.count > 0)
        [resultArrayBig removeAllObjects];
    
    Byte inData[inDataObject.length];
    [inDataObject getBytes: inData];
#if DEBUG
    OTLog(@"Sleep summary Info received");
    OTLog(@"raw Data:");
    [iDevicesUtil dumpData: inDataObject];
#endif
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    [formatter setDateFormat:@"YYYYDDD"];
    
    NSDateFormatter *formatterNoKey = [[NSDateFormatter alloc]init];
    [formatterNoKey setDateFormat:@"yyyy-MM-dd/HH:mm:ss"];
    
    
    Byte ptrBytesInt[4];
    activitiesNumber = inData[0];
    
    memset(ptrBytesInt, 0, 4);
    [inDataObject getBytes: ptrBytesInt range: NSMakeRange((int)inDataObject.length-4, 4)];
    checksum = [iDevicesUtil byteArrayToIntRevesre:ptrBytesInt];
    OTLog(@"---------------------------------------------");
    OTLog(@"SleepSummary");
    OTLog(@"LastbytesCheckSum:%ld",checksum);
    OTLog(@"FullDatachecksum:%ld",[iDevicesUtil calculateChecksum:inData withLength:(int)inDataObject.length-6]); // this one is correct
    OTLog(@"---------------------------------------------");

    OTLog(@"Sleep Summary File Data");
    OTLog(@"MaxRecordNumber: %d",activitiesNumber);
    OTLog(@"NextRecordIndex: %d",inData[1]);
    
    int offsetFromStart = 5;
    for ( int i = 0; i < activitiesNumber; i++ )
    {
        TDM372SleepSummaryTrackerRecord *newActivity =[[TDM372SleepSummaryTrackerRecord alloc]init];
        
        newActivity.mDay = inData[offsetFromStart];
        offsetFromStart++;
        newActivity.mMonth = inData[offsetFromStart];
        offsetFromStart++;
        newActivity.mYear = inData[offsetFromStart];
        offsetFromStart++;
        
        newActivity.mStartMinute = inData[offsetFromStart];
        offsetFromStart++;
        
        newActivity.mStartHour = inData[offsetFromStart];
        offsetFromStart++;
        
        newActivity.mEndHour = inData[offsetFromStart];
        offsetFromStart++;
        
        newActivity.mEndMinute = inData[offsetFromStart];
        offsetFromStart++;
        
        newActivity.mEndDate = inData[offsetFromStart];
        offsetFromStart++;
        
        newActivity.mEndMonth = inData[offsetFromStart];
        offsetFromStart++;
        
        newActivity.mEndYear = inData[offsetFromStart];
        offsetFromStart++;
        
        newActivity.mSleepOffSet = inData[offsetFromStart];
        offsetFromStart++;
        
        newActivity.mDuration = *((short *)&inData[offsetFromStart]);
        offsetFromStart += 2;
        
        newActivity.mStatus = inData[offsetFromStart];
        offsetFromStart++;
        
        
        OTLog(@"------------------------");
        OTLog(@"Record %d Start: %d/%d/%d %d:%d",i,newActivity.mDay,newActivity.mMonth,1900+newActivity.mYear,newActivity.mStartHour,newActivity.mStartMinute);
        OTLog(@"Record %d End: %d/%d/%d %d:%d",i,newActivity.mEndDate,newActivity.mEndMonth,1900+newActivity.mYear,newActivity.mEndHour,newActivity.mEndMinute);
        OTLog(@"Record %d SleepOffset: %d",i,newActivity.mSleepOffSet);
        OTLog(@"Record %d Duration: %d",i,newActivity.mDuration);
        OTLog(@"Record %d Validity: %d",i,newActivity.mStatus);
        
        if (newActivity.mStatus != 0) {
            NSDate *keyPath = [newActivity getActivityDate];
            //OTLog([NSString stringWithFormat:@" sleep keypath %@",keyPath]);
            
            NSDate *newDate = [newActivity getActivityDateDetailStart];
            //OTLog([NSString stringWithFormat:@" sleep newDate %@",newDate]);
            
            NSDate *endDate = [newActivity getActivityDateDetailEnd];
            //OTLog([NSString stringWithFormat:@" sleep endDate %@",endDate]);
            
            NSDate *today = [iDevicesUtil todayDateAtMidnight];
            NSCalendar *gregorian = [NSCalendar currentCalendar];
            [gregorian setTimeZone:[NSTimeZone systemTimeZone]];
            NSDate *past7day = [gregorian dateByAddingUnit:NSCalendarUnitDay value:-7 toDate:today options:nil];
            OTLog(@"Today : %@", today);
            OTLog(@"Past7th day : %@",past7day);
            if ([iDevicesUtil date:keyPath isBetweenDate:past7day andDate:today]) {
                OTLog(@"Need to add sleep summary records");
                [mActivities addObject: newActivity];
            } else {
                OTLog(@"Corrupted sleep summary data");
            }
            
            NSString *tempStartDate =[NSString stringWithFormat:@"%@",[formatterNoKey stringFromDate:newDate]];
            NSString *tempEndDate =[NSString stringWithFormat:@"%@",[formatterNoKey stringFromDate:endDate]];
            NSString *tempDuration =[NSString stringWithFormat:@"%.2f hrs",(newActivity.mDuration * 60000) /3600000.0 ];
            //NSString *tempSleepOffSet =[NSString stringWithFormat:@"%i",newActivity.mSleepOffSet];
            NSString *tempSleepOffSet = [NSString stringWithFormat:@"%i",newActivity.mStatus];
            NSString *tempDayOfActivity =[NSString stringWithFormat:@"%@",[formatter stringFromDate:keyPath]];
            
            //NSArray *tempArray = [NSArray arrayWithObjects:tempStartDate,tempEndDate,tempDuration,tempSleepOffSet, nil];
            NSArray *tempArray = [NSArray arrayWithObjects: tempStartDate,tempEndDate,tempDuration,tempSleepOffSet, nil];
            [resultArrayBig addObject:tempArray];
            
            if ([result  allKeys].count >0) {
                bool dataExisted = false;
                for (int i = 0; i < [result allKeys].count; i++) {
                    NSString *tempString = [NSString stringWithFormat:@"%@",[[result allKeys] objectAtIndex:i]];
                    //OTLog([NSString stringWithFormat:@"tempString %@",tempString]);
                    if ([tempString isEqualToString:tempDayOfActivity]) {
                        dataExisted = true;
                        break;
                    }
                }
                if(dataExisted) {
                    [activityDict setObject:tempArray forKey:tempStartDate];
                    
                }
                else {
                    [activityDict removeAllObjects];
                    [activityDict setObject:tempArray forKey:tempStartDate];
                }
            } else {
                [activityDict setObject:tempArray forKey:tempStartDate];
            }
            [result setObject:activityDict forKey:tempDayOfActivity];
        } else {
            NSDate *keyPath = [newActivity getActivityDate];
            //OTLog([NSString stringWithFormat:@"keyPath %@",keyPath]);
            
            NSString *tempDayOfActivity =[NSString stringWithFormat:@"%@",[formatter stringFromDate:keyPath]];
            
            ///Check If result has all the days ///
            NSArray *allKeysREsult = [result allKeys];
            BOOL addDayWithNoEvents = false;
            for (int y = 0 ; y < allKeysREsult.count; y++) {
                NSString *tempString = [NSString stringWithFormat:@"%@",[allKeysREsult objectAtIndex:y]];
                //OTLog([NSString stringWithFormat:@"tempString %@",tempString]);
                if ([tempDayOfActivity isEqualToString:tempString]) {
                    addDayWithNoEvents = true;
                    break;
                }
            }
            if (!addDayWithNoEvents) {
                [result setObject:@"" forKey:tempDayOfActivity];
            }
        }
    }
    
    memset(ptrBytesInt, 0, 4);
    
    
    OTLog(@"TestLogSummaryResultTotal: %@",result);
    OTLog(@"TestLogresultArrayBig: %@",resultArrayBig);
    
    NSDate   *dateToday = [NSDate date];
    NSString *tempTodaySystem =[NSString stringWithFormat:@"%@",[formatter stringFromDate:dateToday]];
    bool dateExists = false;
    OTLog([NSString stringWithFormat:@"tempTodaySystem %@",tempTodaySystem]);
    NSArray *tempArrayDayEpochs = [result allKeys];
    if (tempArrayDayEpochs.count > 0)
    {
        for (int y = 0; y < tempArrayDayEpochs.count;y++)
        {
            NSString *tempDayInArray = [tempArrayDayEpochs objectAtIndex:y];
            if ([tempDayInArray isEqualToString:tempTodaySystem])
            {
                dateExists = true;
                break;
            }
        }
    }
    
    if (!dateExists)
    {
        NSMutableArray *resultWithToday = [tempArrayDayEpochs mutableCopy];
        [resultWithToday addObject:tempTodaySystem];
        tempArrayDayEpochs = [NSMutableArray arrayWithArray:resultWithToday];
        
    }
    
    tempArrayDayEpochs = [tempArrayDayEpochs sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    NSMutableArray *tempMutableArray = [tempArrayDayEpochs mutableCopy];
    OTLog(@"tempMutableArray: %@",tempMutableArray);
    
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *fromAllEpochs = [defaults objectForKey:@ALL_THE_DATA_IN_EPOCHS];
    OTLog(@"fromAlLEPochs: %@",fromAllEpochs);
    
    NSMutableDictionary *newEpochs = [[NSMutableDictionary alloc]init];
    [defaults setObject:@"1" forKey:M372_SLEEP_REFRESH_MIGRATION];
    NSString * key =@FIRST_SYNC;
//    [defaults removeObjectForKey:@FIRST_SYNC];
    if ([defaults objectForKey: key] == nil)
    {
        newEpochs = fromAllEpochs;
    }
    else {
        for (int i= 0; i < tempMutableArray.count; i ++)
        {
            OTLog(@"TestLogTest: %@",[tempMutableArray objectAtIndex:i]);
            NSObject *tempString =[fromAllEpochs objectForKey:[tempMutableArray objectAtIndex:i]];
            OTLog(@"TempString:%@",tempString);
            if (tempString != nil)
            {
                OTLog(@"TestLogNewEpochsXS: %@",tempMutableArray);
                OTLog(@"TestLogNewEpochsSX: %@",fromAllEpochs);
                [newEpochs setObject:[fromAllEpochs objectForKey:[tempMutableArray objectAtIndex:i]] forKey:[tempMutableArray objectAtIndex:i]];
            }
//            else
//                [tempMutableArray removeObjectAtIndex:i]; // because of this logic some objects are removing from tempMutableArray if previous object key is nil
//            
        }
    }
    OTLog(@"New Epocks: %@",newEpochs);
    OTLog(@"New Epocks Keys: %@",[newEpochs allValues]);
    /////////////
    [defaults removeObjectForKey:@ALL_THE_DATA_IN_EPOCHS];
    [defaults removeObjectForKey:@"fakeEpochs"];
    //[defaults removeObjectForKey:@"fakeEpochsDays"];
    
    [defaults setObject:newEpochs forKey:@ALL_THE_DATA_IN_EPOCHS];
    [defaults setObject:[newEpochs allValues] forKey:@"fakeEpochs"];
    //[defaults setObject:[newEpochs allKeys] forKey:@"fakeEpochsDays"];
    
    
    
    [defaults synchronize];
    /////////////
    
    OTLog(@"TestLogData: %@",[NSString stringWithFormat:@"%@",result]);
    
    NSMutableSet *updateActivityDates = [NSMutableSet set];
    for (TDM372SleepSummaryTrackerRecord * newActivity in mActivities)
    {
        NSDate *keyPath = [newActivity getActivityEndDate];
        DBActivity *activity = (DBActivity*)[[DBModule sharedInstance]getEntity:@"DBActivity" columnName:@"date" value:keyPath];
        if (activity != nil) {
            OTLog(@"Updating Activity");
            OTLog(@"Activity Segments: %@",activity.segments);
            NSDate *startDate = [newActivity getActivityDateDetailStart];
            
            DBSleepEvents *sleepEvent = (DBSleepEvents *)[[DBModule sharedInstance] getEntity:@"DBSleepEvents" columnName:@"startDateEndDateString" value:[self getUniqueValueFromStartDate:startDate endDate:[newActivity getActivityDateDetailEnd]]];
            
            if (sleepEvent == nil)
            {
                OTLog(@"found nill sleepEvent");
                sleepEvent = (DBSleepEvents *)[[DBModule sharedInstance] getEntity:@"DBSleepEvents" columnName:@"startDate" value:startDate];
                sleepEvent.startDateEndDateString = [self getUniqueValueFromStartDate:sleepEvent.startDate endDate:sleepEvent.endDate];
            }
            
            if (sleepEvent != nil && [sleepEvent.startDateEndDateString isEqualToString:[self getUniqueValueFromStartDate:startDate endDate:[newActivity getActivityDateDetailEnd]]]) {
                
                if ([sleepEvent.isEdited boolValue] == NO) {
                    OTLog(@"Updating SleepEvent");
                    sleepEvent.date = keyPath;
                    sleepEvent.duration = [NSNumber numberWithDouble:((newActivity.mDuration * 60000) /3600000.0)];
                    sleepEvent.endDate = [newActivity getActivityDateDetailEnd];
                    if (sleepEvent.eventValid == nil)
                        sleepEvent.eventValid = @"1";
                    sleepEvent.startDate = startDate;
                    sleepEvent.twoDaysEvent = @1;
                }
                
            } else {
                OTLog(@"Creating SleepEvent");
                SleepEventsModal *modal = [[SleepEventsModal alloc] init];
                modal.date = keyPath;
                modal.duration = [NSNumber numberWithDouble:((newActivity.mDuration * 60000) /3600000.0)];
                modal.endDate = [newActivity getActivityDateDetailEnd];
                modal.eventValid = @"1";
                modal.startDate = startDate;
                modal.twoDaysEvent = @1;
                modal.startDateEndDateString = [self getUniqueValueFromStartDate:startDate endDate:[newActivity getActivityDateDetailEnd]];
                sleepEvent = [DBManager addOrUpdateSleepEvent:modal];
            }
            NSMutableSet *sleepEvntsSet = [activity.sleepEvents mutableCopy];
            [sleepEvntsSet addObject:sleepEvent];
            activity.sleepEvents = sleepEvntsSet;
        } else {
            OTLog(@"New Activity Created");
            activity = [self addorUpdateActivity:keyPath SleepSummaryTrackerRecord:newActivity];
        }
        [updateActivityDates addObject:activity];
    }
    [[DBModule sharedInstance] saveContext];
//    for (DBActivity *activity in updateActivityDates) {
//        [self updateActivitySleepTotal:activity];
//    }
    return error;
}

- (DBActivity *)addorUpdateActivity:(NSDate *)date SleepSummaryTrackerRecord:(TDM372SleepSummaryTrackerRecord *)newActivity {
    ActivityModal *activityModel = [[ActivityModal alloc]init];
    activityModel.date = date;
    activityModel.distance = [NSNumber numberWithInt:0];
    activityModel.steps = [NSNumber numberWithInt:0];
    activityModel.calories = [NSNumber numberWithInt:0];
    activityModel.segments = @"";
    DBActivity *activity = [DBManager addOrUpdateActivity:activityModel];
    
    NSDate *startDate = [newActivity getActivityDateDetailStart];
    SleepEventsModal *modal = [[SleepEventsModal alloc] init];
    modal.date = date;
    modal.duration = [NSNumber numberWithDouble:((newActivity.mDuration * 60000) /3600000.0)];
    modal.endDate = [newActivity getActivityDateDetailEnd];
    modal.eventValid = @"1";
    modal.startDate = startDate;
    modal.twoDaysEvent = @1;
    modal.segmentsByEvent = @"";
    modal.startDateEndDateString = [self getUniqueValueFromStartDate:startDate endDate:[newActivity getActivityDateDetailEnd]];
    DBSleepEvents *sleepEvent = [DBManager addOrUpdateSleepEvent:modal];
    
    activity.sleepEvents = [NSMutableSet setWithObjects:sleepEvent, nil];
    return activity;
    
}

-(NSString *)getUniqueValueFromStartDate:(NSDate *)startDate endDate:(NSDate *)endDate
{
    return [NSString stringWithFormat:@"%@\t\t%@", startDate, endDate];
}


@end
