//
//  Resources.m
//  SleepTrackerFilesTool
//
//  Created by Diego Santiago on 3/10/16.
//  Copyright © 2016 Diego Santiago. All rights reserved.
//
#import "TDResources.h"
#import "OTLogUtil.h"
@implementation TDResources

- (void) dumpData:(NSData *)data
{
    unsigned char* bytes = (unsigned char*) [data bytes];
    OTLog(@"===================");
    for(int i = 0; i < [data length]; i++)
    {
        //NSString * op = [NSString stringWithFormat:@"%d: %X",i , bytes[i], nil];
        //OTLog(@"Data: %@", op);
    }
    OTLog(@"===================");
}
- (int) byteArrayToInt: (Byte *) b
{
    return  (b[0] & 0xFF) |
    (b[1] & 0xFF) << 8 |
    (b[2] & 0xFF) << 16 |
    (b[3] & 0xFF) << 24 |
    (b[4] & 0xFF) << 28;
}
- (NSDate *) getActivityDateYearTwo:(Byte)day month:(Byte)month year:(Byte)year
{
    NSDate* result = nil;
    
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setYear: 2000 + year]; //0 corresponds to year 2000
    [comps setMonth: month];
    [comps setDay: day];
    [comps setHour: 0];
    [comps setMinute: 0];
    [comps setSecond: 0];
    
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier: NSCalendarIdentifierGregorian];
    result = [gregorian dateFromComponents: comps];
    
    return result;
}
- (NSDate *) getActivityDate:(Byte)day month:(Byte)month year:(Byte)year
{
    NSDate* result = nil;
    
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setYear: 1900 + year]; //0 corresponds to year 2000
    [comps setMonth: month];
    [comps setDay: day];
    [comps setHour: 0];
    [comps setMinute: 0];
    [comps setSecond: 0];
    
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier: NSCalendarIdentifierGregorian];
    result = [gregorian dateFromComponents: comps];
    
    return result;
}
- (NSDate *) getActivityDateDetail:(Byte)day month:(Byte)month year:(Byte)year hour:(Byte)hour minute:(Byte)minute
{
    NSDate* result = nil;
    
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setYear: 1900 + year]; //0 corresponds to year 2000
    [comps setMonth: month];
    [comps setDay: day];
    [comps setHour: hour];
    [comps setMinute: minute];
    [comps setSecond: 0];
    
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier: NSCalendarIdentifierGregorian];
    result = [gregorian dateFromComponents: comps];
    
    return result;
}
@end
