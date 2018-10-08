//
//  TDM372WatchActivity.m
//  Timex
//
//  Created by Lev Verbitsky on 6/8/15.
//  Copyright (c) 2015 iDevices, LLC. All rights reserved.
//

#import "TDM372WatchActivity.h"
#import "iDevicesUtil.h"
#import "TimexWatchDB.h"
#import "TDActivityTrackerRecord.h"
#import "OTLogUtil.h"
#import "TDWatchProfile.h"

#import "DBManager.h"
#import "ActivityModal.h"
#import "DBModule.h"

@interface TDM372WatchActivity()
{
    Byte activitiesNumber;
    NSMutableArray * mActivities;
    uint32_t  checksum;
}
@end

@implementation TDM372WatchActivity

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
        [self readActivities: inData];
    }
    
    return self;
}

- (int) readActivities: (NSData *) inDataObject
{
    int error = noErr;
    Byte inData[inDataObject.length];
    [inDataObject getBytes: inData];
    
#if DEBUG
    OTLog(@"Watch Activities Info received");
    OTLog(@"raw Data : \n%@",inDataObject);
#endif
 
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"YYYY-MM-dd"];
    
    Byte ptrBytesInt[4];
    activitiesNumber = inData[0];
    
    memset(ptrBytesInt, 0, 4);
    [inDataObject getBytes: ptrBytesInt range: NSMakeRange((int)inDataObject.length-4, 4)];
    checksum = [iDevicesUtil byteArrayToIntRevesre:ptrBytesInt];
    OTLog(@"---------------------------------------------");
    OTLog(@"Activity");
    OTLog(@"LastbytesCheckSum:%ld",checksum);
    OTLog(@"FullDatachecksum:%ld",[iDevicesUtil calculateChecksum:inData withLength:(int)inDataObject.length-6]); // this one is correct
    OTLog(@"---------------------------------------------");

    int offsetFromStart = 1;
    for ( int i = 0; i < activitiesNumber; i++ )
    {
        TDActivityTrackerRecord * newActivity = [[TDActivityTrackerRecord alloc] init];
        
        newActivity.mDay = inData[offsetFromStart];
        offsetFromStart++;
        newActivity.mMonth = inData[offsetFromStart];
        offsetFromStart++;
        newActivity.mYear = inData[offsetFromStart];
        offsetFromStart++;
        newActivity.mActivityDataSavedFlag = inData[offsetFromStart];
        offsetFromStart++;
        
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
        
        NSDate * newDate = [newActivity getActivityDate];
#if DEBUG
        OTLog(@"Date: %@", [formatter stringFromDate: newDate]);
        OTLog(@"Total steps: %d", newActivity.mTotalSteps);
        OTLog(@"Total distance: %d", newActivity.mTotalDistance);
        OTLog(@"Total calories: %d", newActivity.mTotalCalories);
#endif
        NSDate *today = [iDevicesUtil todayDateAtMidnight];
        NSCalendar *gregorian = [NSCalendar currentCalendar];
        [gregorian setTimeZone:[NSTimeZone systemTimeZone]];
        NSDate *past7day = [gregorian dateByAddingUnit:NSCalendarUnitDay value:-7 toDate:today options:nil];
        OTLog(@"Today : %@", today);
        OTLog(@"Past7th day : %@",past7day);
        if ([iDevicesUtil date:newDate isBetweenDate:past7day andDate:today]) {
            OTLog(@"Need to add activities");
            [mActivities addObject: newActivity];
        } else {
            OTLog(@"Corrupted data");
        }
    }
    
    memset(ptrBytesInt, 0, 4);
    return error;
}

- (void) recordActivityData {
    NSMutableArray *dbModalObjsArray = [[NSMutableArray alloc] init];
    for (TDActivityTrackerRecord * newActivity in mActivities) {
        NSDate * newDate = [newActivity getActivityDate];
        if ([newDate compare:[NSDate date]] == NSOrderedAscending || [newDate compare:[NSDate date]] == NSOrderedSame)
        {
            DBActivity *activity = (DBActivity*)[[DBModule sharedInstance]getEntity:@"DBActivity" columnName:@"date" value:newDate];
            if (activity != nil) {
                OTLog(@"Updating existing activity record");
                OTLog(@"Previous Steps : %f",[activity.steps doubleValue]);
                OTLog(@"Previous distance : %f",[activity.distance doubleValue]);
                OTLog(@"Previous Calories : %f",[activity.calories doubleValue]);
                activity.steps = [NSNumber numberWithDouble:(long)[newActivity mTotalSteps]];
                activity.distance = [NSNumber numberWithDouble:(long)[newActivity mTotalDistance]];
                activity.calories = [NSNumber numberWithDouble:(long)[newActivity mTotalCalories]];
                OTLog(@"New Steps : %f",[activity.steps doubleValue]);
                OTLog(@"New distance : %f",[activity.distance doubleValue]);
                OTLog(@"New Calories : %f",[activity.calories doubleValue]);
            } else {
                ActivityModal *modal  = [[ActivityModal alloc] init];
                modal.date = newDate;
                modal.steps = [NSNumber numberWithDouble:(long)[newActivity mTotalSteps]];
                modal.distance = [NSNumber numberWithDouble:(long)[newActivity mTotalDistance]];
                modal.calories = [NSNumber numberWithDouble:(long)[newActivity mTotalCalories]];
                modal.sleep = [NSNumber numberWithDouble:0];
                activity = [DBManager addOrUpdateActivity:modal];
            }
            [dbModalObjsArray addObject:activity];
        }
    }
    if (dbModalObjsArray.count > 0) {
        [[DBModule sharedInstance] saveContext];
    }
}

@end
