//
//  M372ActigraphyDataFile.m
//  SleepTrackerFilesTool
//
//  Created by Diego Santiago on 3/14/16.
//  Copyright © 2016 Diego Santiago. All rights reserved.
//
/**
 * From the spec:
 *
 * This file will store the Counts provided at the end of each Epoch. A new file will be created
 * at the Midnight Rollover. Each file will contain one day’s worth of data, so there will be
 * 720 Epochs in each file. The Epoch Counts data will be initialized to 0xFF at the creation
 * and re-initialization of a file. The file will also contain the date the file was generated.
 * File names will be in the format M372A0xx.SLP, M372A1xx.SLP, M372A2xx.SLP…M372A7xx.SLP.
 * Each file will represent a 24 hour period (Midnight to Midnight).  xx represents the revision
 * number of the file.
 *
 *
 *     typedef struct
 //        {
 //            uint8_t Date;   // (1 - 31)
 //            uint8_t Month;  // (1 - 12)
 //            uint8_t Year;   // (0 - 255)
 //            union
 //            {
 //                uint8_t Reg;
 //                struct
 //                {
 //                    uint8_t invalid  : 1;       //!< 1 if file is invalid
 //                    uint8_t timeChanged  : 1;   //!< 1 if time changed
 //                    uint8_t dateChanged : 1;    //!< 1 if date changed
 //                    uint8_t             : 5;
 //                }b;
 //            }status;
 //            uint8_t         reserved[3];
 //            uint8_t EpochCount[720];
 //            uint32_t checksum;
 //        }Actigraphy_t ;
 ****/

#import "TDM372ActigraphyDataFile.h"
#import "TDResources.h"
#import "TDWatchProfile.h"
#import "DBManager.h"
#import "DBModule.h"
#import "ActivityModal.h"
#import "DBActivity+CoreDataClass.h"
#import "DBSleepEvents.h"
#import "OTLogUtil.h"
#import "TDDefines.h"

@interface TDM372ActigraphyDataFile () {
    uint32_t  checksum;
}

@end
@implementation TDM372ActigraphyDataFile

@synthesize mKeyRecords = _mKeyRecords;
@synthesize mDay    = _mDay;
@synthesize mMonth  = _mMonth;
@synthesize mYear   = _mYear;

- (id) init: (NSData *) inData
{
    if (self = [self init])
    {
        [self readEpochs: inData];
            //If no more actigraphy files to read update sleep SegmentByEvent
            OTLog(@"Actigraphy Files:%d",[[[NSUserDefaults standardUserDefaults] objectForKey:@"fakeEpochs"] count]);
            if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"fakeEpochs"] count] == 0) {
                OTLog(@"Started updateAllNewSleepEventsAndActivitySleepTotal");
                [self updateAllNewSleepEventsAndActivitySleepTotal]; //
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"fakeEpochsDays"];
            }
    }
    
    return self;
}

- (int ) readEpochs: (NSData *) inDataObject
{
     int error = noErr;
    
    TDResources *rec = [[TDResources alloc]init];
    NSMutableDictionary *result = [[NSMutableDictionary alloc]init];
    if (result.count > 0)
        [result removeAllObjects];
    
    Byte inData[inDataObject.length];
    [inDataObject getBytes: inData];
    
    NSLog(@"Epochs Info received");
    [rec dumpData: inDataObject];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"YYYYDDD"];
    
    Byte ptrBytesInt[4];

    memset(ptrBytesInt, 0, 4);
    [inDataObject getBytes: ptrBytesInt range: NSMakeRange((int)inDataObject.length-4, 4)];
    checksum = [iDevicesUtil byteArrayToIntRevesre:ptrBytesInt];
    OTLog(@"---------------------------------------------");
    OTLog(@"ActigraphyData");
    OTLog(@"LastbytesCheckSum:%ld",checksum);
    OTLog(@"FullDatachecksum:%ld",[iDevicesUtil calculateChecksum:inData withLength:(int)inDataObject.length-6]); // this one is correct
    OTLog(@"---------------------------------------------");
    
    NSMutableDictionary *actigraphyFileDictionary = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *epochDictionary = [[NSMutableDictionary alloc] init];
    
    int offsetFromStart = 0;
    //Byte Offset 0
    _mDay = inData[offsetFromStart];
    offsetFromStart++;
    //Byte Offset 1
    _mMonth = inData[offsetFromStart];
    offsetFromStart++;
    //Byte Offset 2
    _mYear = inData[offsetFromStart];
    offsetFromStart++;
    //Byte Offset 3
//    _mStatus = inData[offsetFromStart];
    _mStatus = (1 == ((inData[offsetFromStart] >> 0) & 1));
    offsetFromStart += 4; //Reserved
    OTLog(@"Actigraphy Date: %d/%d/%d",_mDay,_mMonth,1900+_mYear);
    OTLog(@"Actigraphy Validity: %d",_mStatus);
    OTLog(@"Actigraphy TimeChanged: %d",(1 == ((inData[offsetFromStart] >> 1) & 1)));
    OTLog(@"Actigraphy DtatChanged: %d",(1 == ((inData[offsetFromStart] >> 2) & 1)));
    
    NSDate * date = [rec getActivityDate:_mDay month:_mMonth year:_mYear];
    //NSLog(@"TestLogNSDate: %@",date);
    
    [actigraphyFileDictionary setObject:[NSString stringWithFormat:@"%hhu", _mStatus] forKey:@"Status"];
    
    
    
    int epochCounts = 720;
    for ( int i = 0; i <= epochCounts - 1; i++ )
    {
        OTLog(@"Epoch %d:%d",i,inData[offsetFromStart]);
        [epochDictionary setObject:[NSString stringWithFormat:@"%hhu", inData[offsetFromStart]] forKey:[NSString stringWithFormat:@"%d",i]];
        offsetFromStart++;
    }
    
    //}
    
    //[actigraphyFileDictionary setObject:epochDictionary forKey:@"Epochs"];
    // Date will be the key for the main Dictionary
    [result setObject:epochDictionary forKey:[NSString stringWithFormat:@"%@",[formatter stringFromDate:date]]];
    OTLog(@"\n\n\n\nActigraphyDataFile\n%@\n\n\n\n",[NSString stringWithFormat:@"RESULT EPOCHS:%@", result]);
    
    

    /**
     conver nsdata to nsdictionary
     NSDictionary *myDictionary = (NSDictionary*) [NSKeyedUnarchiver unarchiveObjectWithData:myData];
     **/
    @autoreleasepool {
        
        [self saveEpochs:epochDictionary nsDate:date];
    }
    memset(ptrBytesInt, 0, 4);
    
    return error;
}
/////Save data according of days///// for home

- (void)saveEpochs:(NSDictionary *)epochs nsDate:(NSDate*)nsDate
{
    NSMutableString *epochString = [[NSMutableString alloc]init];
    
    for (int i =0 ; i < epochs.count; i ++)
    {
        NSString *tempStringEpoch = [NSString stringWithFormat:@"%@",[epochs objectForKey:[NSString stringWithFormat:@"%i",i]]];
        float epocValue = [tempStringEpoch floatValue];
        
        if (epocValue != 255)
        {
            if (epocValue == 0)
            {
                [epochString appendString:@"A"];
            }
            else if (epocValue >=1 && epocValue <= 9)
            {
                [epochString appendString:@"B"];
            }
            else if (epocValue >  9)
            {
                [epochString appendString:@"C"];
            }
        }
        else
            [epochString appendString:@"F"];
    }
    
    
    OTLog(@"\n\n\nDiegoMyStringDate: %@ stringEppochs: %@ quantity: %lu",nsDate,epochString,(unsigned long)epochString.length);
        DBActivity *activity = (DBActivity*)[[DBModule sharedInstance]getEntity:@"DBActivity" columnName:@"date" value:nsDate];
        if (activity != nil) {
            activity.segments = epochString;
            [self updateSleepEventsAndActivity:activity];
            NSMutableArray *newActivity = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"fakeEpochsDays"]];
            [newActivity addObject:activity.date];
            [[NSUserDefaults standardUserDefaults] setObject:newActivity forKey:@"fakeEpochsDays"];
            
        }
}

- (void)updateSleepEventsAndActivity:(DBActivity *)activity {
    NSArray *sleepEventsArry = [activity.sleepEvents allObjects];
    for (DBSleepEvents *event in sleepEventsArry) {
        OTLog(@"SleepEventFoundSegmentStr : %@ ActivityDate:%@",activity.segments,activity.date);
        [self updateSegmentByEventString:event epochString:activity.segments];
    }
}

/**
 *  Loads the sleep segment for the current sleep activity.
 *
 *  @param evnt           Sleep event
 *  @param segments       Segment string for current date (May be the start or end date)
 *  @param actigraphyDate Date for the activity
 *
 *  @return updated segment string
 */
- (void)updateSegmentByEventString:(DBSleepEvents *)evnt epochString:(NSString *)segments {
    TCSTART
    OTLog(@"updateSegmentByEventString");
    if ([evnt.startDate compare:evnt.endDate] == NSOrderedDescending) { // If sleep enddate is less than sleep start date then that is invalid record. it won't happen in real time but for safety we have to check
        evnt.segmentsByEvent = @"";
        OTLog(@"Sleep is invalid because sleep start date is greater than end date");
    } else {
        if (![[NSCalendar currentCalendar] isDate:evnt.startDate inSameDayAsDate:evnt.endDate]) { // if sleep starts in previous day and ends in next day then it would be  two days of event
            evnt.twoDaysEvent = @0;
            evnt.segmentsByEvent = @"";
            OTLog(@"Sleep is two days event");
        } else {
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"yyyy-MM-dd/HH:mm:ss"];
            
            NSDate *startDate = evnt.startDate;
            NSDate *endDate = evnt.endDate;
            
            NSString *dateStringStart = [formatter stringFromDate:startDate];
            NSString *dateStringEnd = [formatter stringFromDate:endDate];
            NSString *epochString = segments;
            
            NSDateFormatter *dateFormatter2 = [[NSDateFormatter alloc] init];
            [dateFormatter2 setDateFormat:@"yyyy-mm-dd/HH:mm:ss"];
            
            NSDate *dateFromStringStart = [dateFormatter2 dateFromString:dateStringStart];
            
            NSDate *dateFromStringEnd = [dateFormatter2 dateFromString:dateStringEnd];
            
            NSDateFormatter *hoursToMinutes = [[NSDateFormatter alloc] init];
            [hoursToMinutes setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_GB"]];
            [hoursToMinutes setDateFormat:@"HH"];
            NSDateFormatter *minutesToSum = [[NSDateFormatter alloc] init];
            [minutesToSum setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_GB"]];
            [minutesToSum setDateFormat:@"mm"];
            
            // Starting date hours and minutes
            NSString *stringHoursToMinutesStart = [hoursToMinutes stringFromDate:dateFromStringStart];
            NSString *stringMinutesTuSumStart   = [minutesToSum stringFromDate:dateFromStringStart];
            
            // Ending date hours and minutes
            NSString *stringHoursToMinutesEnd   = [hoursToMinutes stringFromDate:dateFromStringEnd];
            NSString *stringMinutesTuSumEnd     = [minutesToSum stringFromDate:dateFromStringEnd];
            
            CGFloat floatHoursStart     = [stringHoursToMinutesStart floatValue];
            CGFloat floatMinutesStart   = [stringMinutesTuSumStart floatValue];
            
            CGFloat floatHoursEnd       = [stringHoursToMinutesEnd floatValue];
            CGFloat floatMinutesEnd     = [stringMinutesTuSumEnd floatValue];
            
            CGFloat epochInit       = ((floatHoursStart * 60) + floatMinutesStart)/2;
            CGFloat epochEnd        = ((floatHoursEnd * 60) + floatMinutesEnd)/2;
            
            int resultStart = (int)floor(epochInit);
            int resultEnd = (int)floor(epochEnd);
            NSMutableString *segmentsByEvent = [[NSMutableString alloc]init];
            
            OTLog(@"StartTime:%d",resultStart);
            OTLog(@"EndTime:%d",resultEnd);
            for (int x = resultStart; x < resultEnd; x++ ) {
                NSString *theCharacter = [NSString stringWithFormat:@"%c", [epochString characterAtIndex:x]];
                [segmentsByEvent appendString:theCharacter];
            }
            evnt.segmentsByEvent = segmentsByEvent;
            evnt.duration = [NSNumber numberWithDouble:(((evnt.segmentsByEvent.length*2) * 60000) /3600000.0)]; // Some times duration from watch is getting wrong when compared to start time and end time. REf : artf25218
        }
    }
    
    OTLog(@"StartDate: %@", evnt.startDate);
    OTLog(@"EndDate: %@", evnt.endDate);
    OTLog(@"TwoDaysEvent: %@", evnt.twoDaysEvent);
    OTLog(@"SegmentsByEvent: %@", evnt.segmentsByEvent);
    OTLog(@"SleepDuration: %f",evnt.duration.floatValue);
    OTLog(@"---------------------------------------------");
    [[DBModule sharedInstance] saveContext];
    TCEND
}


- (void)updateAllNewSleepEventsAndActivitySleepTotal {
    OTLog(@"updateAllNewSleepEventsAndActivitySleepTotal");
    NSArray *daysArray = [[NSUserDefaults standardUserDefaults] objectForKey:@"fakeEpochsDays"];
    OTLog(@"Actigraphy files Data:%@",daysArray);
    for (NSDate *date in daysArray) {
        DBActivity *activity = (DBActivity*)[[DBModule sharedInstance]getEntity:@"DBActivity" columnName:@"date" value:date];
        OTLog(@"Activity Date: %@",activity.date);
        OTLog(@"SleepEvents %@",activity.sleepEvents.allObjects);
        for (DBSleepEvents *sleepEvent in activity.sleepEvents.allObjects) {
            if ([sleepEvent.twoDaysEvent intValue] == 0) { // for 0th object we don't have previous activity
                OTLog(@"TwoDaysEvent : %@",sleepEvent);
                NSDate *previousDate = [iDevicesUtil getPreviousDate:date];
                OTLog(@"Current Date: %@",date);
                OTLog(@"PreviousDate Date: %@",previousDate);
                DBActivity *previousActivity = (DBActivity*)[[DBModule sharedInstance]getEntity:@"DBActivity" columnName:@"date" value:previousDate];
                OTLog(@"previousActivity Date: %@ and Segment:%@",previousActivity.date, previousActivity.segments);
                [self updateSegmentByEventString:sleepEvent epochString:activity.segments previousEpochString:previousActivity.segments];
            }
        }
        [DBManager saveTotalSleep:activity];
    }
    [[DBModule sharedInstance] saveContext];
}

- (void)updateSegmentByEventString:(DBSleepEvents *)evnt epochString:(NSString *)segmentsByDayComplete previousEpochString:(NSString *)previousSegment {
    OTLog(@"updateSegmentByEventString");
    OTLog(@"Segments%@",segmentsByDayComplete);
    OTLog(@"PreviousSegment%@",previousSegment);
    OTLog(@"SegmentsByEvent Before %@",evnt.segmentsByEvent);
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd/HH:mm:ss"];
    
    NSDate *dateFromStringStart = evnt.startDate;
    NSDate *dateFromStringEnd = evnt.endDate;
    
    NSDateFormatter *dateFormatter2 = [[NSDateFormatter alloc] init];
    [dateFormatter2 setDateFormat:@"yyyy-mm-dd/HH:mm:ss"];
    
    OTLog(@"dateFromStringStart :%@",dateFromStringStart);
    OTLog(@"dateFromStringEnd :%@",dateFromStringEnd);
    
    NSDateFormatter *hoursToMinutes = [[NSDateFormatter alloc] init];
    [hoursToMinutes setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_GB"]];
    [hoursToMinutes setDateFormat:@"HH"];
    NSDateFormatter *minutesToSum = [[NSDateFormatter alloc] init];
    [minutesToSum setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_GB"]];
    [minutesToSum setDateFormat:@"mm"];
    
    NSString *stringHoursToMinutesStart = [hoursToMinutes stringFromDate:dateFromStringStart];
    NSString *stringMinutesTuSumStart   = [minutesToSum stringFromDate:dateFromStringStart];
    
    NSString *stringHoursToMinutesEnd   = [hoursToMinutes stringFromDate:dateFromStringEnd];
    NSString *stringMinutesTuSumEnd     = [minutesToSum stringFromDate:dateFromStringEnd];
    
    CGFloat floatHoursStart     = [stringHoursToMinutesStart floatValue];
    CGFloat floatMinutesStart   = [stringMinutesTuSumStart floatValue];
    
    CGFloat floatHoursEnd       = [stringHoursToMinutesEnd floatValue];
    CGFloat floatMinutesEnd     = [stringMinutesTuSumEnd floatValue];
    
    CGFloat epochInit       = ((floatHoursStart * 60) + floatMinutesStart)/2;
    CGFloat epochEnd        = ((floatHoursEnd * 60) + floatMinutesEnd)/2;
    
    int resultStart = (int)floor(epochInit);
    int resultEnd = (int)floor(epochEnd);
    
    NSMutableString *segmentsByEventSecond = [[NSMutableString alloc]init];
    
    for (int x = 0; x < resultEnd; x++ )
    {
        NSString *theCharacter = [NSString stringWithFormat:@"%c", [segmentsByDayComplete characterAtIndex:x]];
        [segmentsByEventSecond appendString:theCharacter];
    }

    NSMutableString *segmentsByEvent = [[NSMutableString alloc]init];
    if([previousSegment length] >= 720)
    {
        for (int x = resultStart; x < 720; x++ )
        {
            NSString *theCharacter = [NSString stringWithFormat:@"%c", [previousSegment characterAtIndex:x]];
            [segmentsByEvent appendString:theCharacter];
        }
    }
    
    OTLog(@"PreviousDaySegmentByEvent:%@",segmentsByEvent);
    OTLog(@"CurrentDaySegmentByEvent:%@",segmentsByEventSecond);
    NSString *fullEpochs = [NSString stringWithFormat:@"%@%@",segmentsByEvent,segmentsByEventSecond];
    evnt.segmentsByEvent = fullEpochs;
    evnt.duration = [NSNumber numberWithDouble:(((evnt.segmentsByEvent.length*2) * 60000) /3600000.0)]; // Some times duration from watch is getting wrong when compared to start time and end time. REf : artf25218
    OTLog(@"StartDate: %@", evnt.startDate);
    OTLog(@"EndDate: %@", evnt.endDate);
    OTLog(@"TwoDaysEvent: %@", evnt.twoDaysEvent);
    OTLog(@"SegmentsByEvent: %@", evnt.segmentsByEvent);
    OTLog(@"SleepDuration: %f",evnt.duration.floatValue);
    OTLog(@"---------------------------------------------");
    [[DBModule sharedInstance] saveContext];
}
@end
