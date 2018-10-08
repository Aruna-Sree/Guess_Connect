//
//  ActRecord.m
//  SleepTrackerFilesTool
//
//  Created by Diego Santiago on 3/4/16.
//  Copyright © 2016 Diego Santiago. All rights reserved.
//
/**
 * The file return by the original M372 firmware giving steps,distance,and calories for up to 8 days.
 *
 * From the spec:
 *
 * The Daily Activity database can accommodate up to 8 daily activity records,
 * for a maximum size of 101 bytes, including its header and checksum field.
 * It is formatted as follows:
 *
 *  Daily Activity Header 1/0x0000 Number of daily activity records stored
 *  Daily Activity Records 96/0x0001
 *  Daily Activity Checksum 4/0x0061 Two’s Complement of the sum of all data elements in locations 0x0000
 *
 * Holds up to 8 daily activity records:
 *
 * A Daily Activity record is a fixed 12-byte long data.
 *
 *   1 byte - Daily activity day (1 – 31)
 *   1 byte - Daily activity month (1 – 12)
 *   2 bytes - Daily activity year (0 – 99) for Year 2000 – 2099
 *   1 byte - status: 1 - OK, 0 – Activity Statistical data not saved (other bits reserved)
 *   3 bytes - Daily activity steps (0 – 99,999)
 *   2 bytes - Daily activity distance in kilometers with 2-digit decimal. Divide by 100 to
 *              get actual value. (0 – 99.99 kilometers, stored as 0 – 9999)
 *   3 bytes -  Daily activity calories in kilocalorie unit with 1-digit decimal. Divide by 10 to
 *              get actual value. (0 – 9,999.0, stored as 0 – 99990)
 ***/

#import "TDM372DailyActivityFile.h"
#import "TDResources.h"
#import "OTLogUtil.h"
@interface TDM372DailyActivityFile()
{
    //Byte activitiesNumber;
    NSMutableArray * mActivities;
    int  activitiesChecksum;
}
@end

@implementation TDM372DailyActivityFile

@synthesize mYear = _mYear;
@synthesize mMonth = _mMonth;
@synthesize mDay = _mDay;
@synthesize mActivityDataSavedFlag = _mActivityDataSavedFlag;
@synthesize mTotalSteps = _mTotalSteps;
@synthesize mTotalDistance = _mTotalDistance;
@synthesize mTotalCalories = _mTotalCalories;

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


- (void) readActivities: (NSData *) inDataObject
{
    if (inDataObject != nil)
    {
        TDResources *rec = [[TDResources alloc]init];
        NSMutableDictionary *result = [[NSMutableDictionary alloc]init];
        if (result.count > 0)
            [result removeAllObjects];
        
        Byte activitiesNumber;
        Byte inData[inDataObject.length];
        [inDataObject getBytes: inData];
        
#if DEBUG
        OTLog(@"Watch Activities Info received");
        OTLog(@"raw Data: \n%@",inDataObject);
#endif        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"YYYY-MM-dd"];
        
        Byte ptrBytesInt[4];
        activitiesNumber = inData[0];
        
        int offsetFromStart = 1;
        for ( int i = 0; i < activitiesNumber; i++ )
        {
            
            _mDay = inData[offsetFromStart];
            offsetFromStart++;
            _mMonth = inData[offsetFromStart];
            offsetFromStart++;
            _mYear = inData[offsetFromStart];
            offsetFromStart++;
            _mActivityDataSavedFlag = inData[offsetFromStart];
            offsetFromStart++;
            
            memset(ptrBytesInt, 0, 4);
            [inDataObject getBytes: ptrBytesInt range: NSMakeRange(offsetFromStart, 3)];
            _mTotalSteps = [rec byteArrayToInt: ptrBytesInt];
            offsetFromStart += 3;
            
            _mTotalDistance = *((short *)&inData[offsetFromStart]);
            offsetFromStart += 2;
            
            memset(ptrBytesInt, 0, 4);
            [inDataObject getBytes: ptrBytesInt range: NSMakeRange(offsetFromStart, 3)];
            _mTotalCalories = [rec byteArrayToInt: ptrBytesInt];
            offsetFromStart += 3;
            
#if DEBUG
            NSDate * newDate = [rec getActivityDateYearTwo:_mDay month:_mMonth year:_mYear];
            NSString *tempOne = [NSString stringWithFormat:@"%@",[formatter stringFromDate:newDate]];
            NSString *tempTwo = [NSString stringWithFormat:@"Steps:%d",_mTotalSteps];
            NSString *tempThr = [NSString stringWithFormat:@"Distance:%d",_mTotalDistance];
            NSString *tempFou = [NSString stringWithFormat:@"Calories:%.2f",(_mTotalCalories / 10.f)];
            NSArray *tempArrayData = [NSArray arrayWithObjects:tempTwo,tempThr,tempFou,nil];
            
            [result setObject:tempArrayData forKey:tempOne];
#endif
        }
        memset(ptrBytesInt, 0, 4);
        
        //OTLog(@"TestLogMoreData: %@",[NSString stringWithFormat:@"%@",result]);
        
    }
}

@end
