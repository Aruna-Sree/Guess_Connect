//
//  NSDate+JSON.m
//  RunKeeper-iOS
//
//  Created by Reid van Melle on 11-09-15.
//  Copyright 2011 Brierwood Design Co-operative. All rights reserved.
//

#import "NSDate+JSON.h"


@implementation NSDate (JSON)

/// "Sat, 1 Jan 2011 00:00:00"
- (id)proxyForJson {
    time_t time = [self timeIntervalSince1970];
    struct tm timeStruct;
    localtime_r(&time, &timeStruct);
    char buffer[80];
    strftime(buffer, 80, "%a, %d %b %Y %H:%M:%S", &timeStruct);
    return [NSString stringWithCString:buffer encoding:NSASCIIStringEncoding];
}

- (id)proxyForJsonInISO8601
{
    time_t time = [self timeIntervalSince1970];
    struct tm timeStruct;
    localtime_r(&time, &timeStruct);
    char buffer[80];
    strftime(buffer, 80, "%Y-%m-%dT%H:%M:%SZ", &timeStruct);
    return [NSString stringWithCString:buffer encoding:NSASCIIStringEncoding]; //2011-01-11T03:54:43Z
}

-(id)proxyForJsonInISO8601GMT
{
    time_t time = [self timeIntervalSince1970];
    struct tm timeStruct;
    gmtime_r(&time, &timeStruct);
    char buffer[80];
    strftime(buffer, 80, "%Y-%m-%dT%H:%M:%SZ", &timeStruct);
    return [NSString stringWithCString:buffer encoding:NSASCIIStringEncoding];
}

- (id)proxyForJsonInISO8601_DateOnly
{
    time_t time = [self timeIntervalSince1970];
    struct tm timeStruct;
    localtime_r(&time, &timeStruct);
    char buffer[80];
    strftime(buffer, 80, "%Y-%m-%d", &timeStruct);
    return [NSString stringWithCString:buffer encoding:NSASCIIStringEncoding];
}
- (id)proxyForJsonInISO8601_TimeOnly
{
    time_t time = [self timeIntervalSince1970];
    struct tm timeStruct;
    localtime_r(&time, &timeStruct);
    char buffer[80];
    strftime(buffer, 80, "%H:%M:%S", &timeStruct);
    return [NSString stringWithCString:buffer encoding:NSASCIIStringEncoding];
}

+ (NSDate*)dateFromJSONDate:(NSString*)string
{
    if (!string) {
        return nil;
    }
    
    struct tm tm;
    time_t t;
    
    strptime([string cStringUsingEncoding:NSUTF8StringEncoding], "%a, %d %b %Y %H:%M:%S", &tm);
    tm.tm_isdst = -1;
    t = mktime(&tm);
    
    return [NSDate dateWithTimeIntervalSince1970:t + [[NSTimeZone localTimeZone] secondsFromGMT]];
}

@end
