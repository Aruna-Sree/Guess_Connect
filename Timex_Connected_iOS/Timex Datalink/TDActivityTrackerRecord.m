//
//  TDActivityTrackerRecord.m
//  Timex
//
//  Created by Lev Verbitsky on 6/10/15.
//  Copyright (c) 2015 iDevices, LLC. All rights reserved.
//

#import "TDActivityTrackerRecord.h"

@implementation TDActivityTrackerRecord

@synthesize mYear = _mYear;
@synthesize mMonth = _mMonth;
@synthesize mDay = _mDay;
@synthesize mActivityDataSavedFlag = _mActivityDataSavedFlag;
@synthesize mTotalSteps = _mTotalSteps;
@synthesize mTotalDistance = _mTotalDistance;
@synthesize mTotalCalories = _mTotalCalories;
//@synthesize mTotalSleep = _mTotalSleep;

- (NSDate *) getActivityDate
{
    NSDate* result = nil;
    
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setYear: 2000 + _mYear]; //0 corresponds to year 2000
    [comps setMonth: _mMonth];
    [comps setDay: _mDay];
    [comps setHour: 0];
    [comps setMinute: 0];
    [comps setSecond: 0];
    
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier: NSCalendarIdentifierGregorian];
    result = [gregorian dateFromComponents: comps];
    
    return result;
}

@end
