//
//  M372SleepSummaryTrackerRecord.m
//  Timex
//
//  Created by Diego Santiago on 3/21/16.
//  Copyright © 2016 iDevices, LLC. All rights reserved.
//

#import "TDM372SleepSummaryTrackerRecord.h"

@implementation TDM372SleepSummaryTrackerRecord
@synthesize mMaxRecordNumber    = _mMaxRecordNumber;
@synthesize mNextRecordIndex    = _mNextRecordIndex;
@synthesize mSumaryrecords      = _mSumaryrecords;


@synthesize mDay    = _mDay;
@synthesize mMonth  = _mMonth;
@synthesize mYear   = _mYear;

@synthesize mStartMinute    = _mStartMinute;
@synthesize mStartHour      = _mStartHour;
@synthesize mEndHour        = _mEndHour;
@synthesize mEndMinute      = _mEndMinute;
@synthesize mEndDate        = _mEndDate;
@synthesize mEndMonth       = _mEndMonth;
@synthesize mEndYear        = _mEndYear;
@synthesize mSleepOffSet    = _mSleepOffSet;
@synthesize mDuration       = _mDuration;

- (NSDate *) getActivityDate
{
    NSDate* result = nil;
    
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setYear: 1900 + _mYear]; //0 corresponds to year 2000
    [comps setMonth: _mMonth];
    [comps setDay: _mDay];
    [comps setHour: 0];
    [comps setMinute: 0];
    [comps setSecond: 0];
    
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier: NSCalendarIdentifierGregorian];
    result = [gregorian dateFromComponents: comps];
    
    return result;
}
- (NSDate *) getActivityDateDetailStart
{
    NSDate* result = nil;
    
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setYear: 1900 + _mYear]; //0 corresponds to year 2000
    [comps setMonth: _mMonth];
    [comps setDay: _mDay];
    [comps setHour: _mStartHour];
    [comps setMinute: _mStartMinute];
    [comps setSecond: 0];
    
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier: NSCalendarIdentifierGregorian];
    result = [gregorian dateFromComponents: comps];
    
    return result;
}

- (NSDate *) getActivityDateDetailEnd
{
    NSDate* result = nil;
    
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setYear: 1900 + _mEndYear]; //0 corresponds to year 2000
    [comps setMonth: _mEndMonth];
    [comps setDay: _mEndDate];
    [comps setHour: _mEndHour];
    [comps setMinute: _mEndMinute];
    [comps setSecond: 0];
    
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier: NSCalendarIdentifierGregorian];
    result = [gregorian dateFromComponents: comps];
    if (([result timeIntervalSinceDate:[self getActivityDateDetailStart]]/60) != self.mDuration) { // to fix artf27238, artf27233.. Some times end date not getting correctly so endDate, endYear, and endMonth are not supposed to be used. The epoch duration is added to the start date to get the correct end time for sleep events
        NSLog(@"\n\n\n=================");
        NSLog(@"SleepSummaryEnd date before : %@",result);
        result = [[self getActivityDateDetailStart] dateByAddingTimeInterval:(self.mDuration * 60)];
        NSLog(@"SleepSummaryEnd date after : %@",result);
        NSLog(@"=================\n\n\n");
    }
    return result;
}

- (NSDate *) getActivityEndDate
{
    NSDate* result = nil;
    
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setYear: 1900 + _mEndYear]; //0 corresponds to year 2000
    [comps setMonth: _mEndMonth];
    [comps setDay: _mEndDate];
    [comps setHour: 0];
    [comps setMinute: 0];
    [comps setSecond: 0];
    
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier: NSCalendarIdentifierGregorian];
    result = [gregorian dateFromComponents: comps];
    
    return result;
}

@end
