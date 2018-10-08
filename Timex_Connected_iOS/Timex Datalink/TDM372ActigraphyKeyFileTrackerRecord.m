//
//  M372ActigraphyKeyFileTrackerRecord.m
//  Timex
//
//  Created by Diego Santiago on 3/22/16.
//  Copyright © 2016 iDevices, LLC. All rights reserved.
//

#import "TDM372ActigraphyKeyFileTrackerRecord.h"

@implementation TDM372ActigraphyKeyFileTrackerRecord


@synthesize mKeyRecords     = _mKeyRecords;

@synthesize mDay    = _mDay;
@synthesize mMonth  = _mMonth;
@synthesize mYear   = _mYear;

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
@end
