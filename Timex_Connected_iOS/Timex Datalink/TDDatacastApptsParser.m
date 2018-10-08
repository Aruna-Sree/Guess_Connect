//
//  TDDatacastApptsParser.m
//  Timex Connected
//
//  Created by Lev Verbitsky on 2/3/14.
//  Copyright (c) 2014 iDevices, LLC. All rights reserved.
//

#import "TDDatacastApptsParser.h"
#import "TimexWatchDB.h"
#import "iDevicesUtil.h"
#import "PCCommCommands.h"
#import "TDWatchProfile.h"

#define CALENDAR_USER_SETTING_SELECTED_CALENDARS @"CAL_SELECTED_EKCALS"
#define  FILE_FORMAT_VERSION  APPOINTMENTS_VERSION

@implementation TDDatacastApptsParser
{
    NSInteger _maxNumberOfEvents;
}

@synthesize eventsList = _eventsList;
@synthesize eventStore = _eventStore;
@synthesize mLastChecksum = _mLastChecksum;

- (id) init: (NSInteger) maxNumberOfCalEvents
{
    if (self = [super init])
    {
        _mLastChecksum = 0;
        _eventStore = [[EKEventStore alloc] init];
        _eventsList  = [[NSMutableArray alloc] init];
        
        if (maxNumberOfCalEvents == 0 || maxNumberOfCalEvents == INT_MAX)
            _maxNumberOfEvents = INT_MAX;
        else
            _maxNumberOfEvents = maxNumberOfCalEvents;
    }
    return self;
}

- (void) reloadCalendarData: (void (^)(void))completionCode
{
    BOOL needsToRequestAccessToEventStore = NO; // iOS 5 behavior
    __weak TDDatacastApptsParser * weakSelf = self;
    [_eventsList removeAllObjects];
    
    if ([[EKEventStore class] respondsToSelector:@selector(authorizationStatusForEntityType:)])
    {
        needsToRequestAccessToEventStore = ([EKEventStore authorizationStatusForEntityType: EKEntityTypeEvent] == EKAuthorizationStatusNotDetermined);
    }
    
    if (needsToRequestAccessToEventStore)
    {
        [_eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error)
         {
             TDDatacastApptsParser * strongSelf = weakSelf;
             if (granted)
             {
                 dispatch_async(dispatch_get_main_queue(), ^
                                {
                                    
                                    [strongSelf fetchEventsInTheFuture: NULL];
                                    [strongSelf removeExcludedEventsFromArray];
                                    
                                    completionCode();
                                });
             }
         }];
    }
    else
    {
        [self fetchEventsInTheFuture: NULL];
        [self removeExcludedEventsFromArray];
        
        completionCode();
    }
}

- (void) fetchEventsInTheFuture: (EKCalendarChooser *) chooser
{
    NSDate *startDate = [NSDate date];
    
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier: NSCalendarIdentifierGregorian];
    NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
    [offsetComponents setYear: 1];
    NSDate * endDate = [gregorian dateByAddingComponents: offsetComponents toDate: startDate options: 0];
    
    // Create the predicate. Pass it the default calendar.
    NSMutableArray * calendarArray = nil;
    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    
    if (chooser == NULL)
    {
        calendarArray = [self fetchSelectedCalendars];
    }
    else
    {
        calendarArray = [NSMutableArray arrayWithArray: [[chooser selectedCalendars] allObjects]];
        
        NSMutableArray * calIDs = [[NSMutableArray alloc] init];
        for (NSInteger i = 0; i < [calendarArray count]; i++)
        {
            EKCalendar * calendar = [calendarArray objectAtIndex: i];
            [calIDs addObject: [calendar calendarIdentifier]];
        }
        
        [userDefaults setObject: calIDs forKey: CALENDAR_USER_SETTING_SELECTED_CALENDARS];
        [userDefaults synchronize];
    }
    
    if (calendarArray != NULL && [calendarArray count] > 0)
    {
        NSPredicate *predicate = [_eventStore predicateForEventsWithStartDate:startDate endDate:endDate calendars: calendarArray];
        
        if (_maxNumberOfEvents == INT_MAX)
        {
            [_eventsList addObjectsFromArray: [_eventStore eventsMatchingPredicate:predicate]];
        }
        else
        {
            [_eventStore enumerateEventsMatchingPredicate:predicate usingBlock:^(EKEvent *event, BOOL *stop)
             {
                 if (event)
                 {
                     [_eventsList addObject: event];
                 }
                 if ([_eventsList count] ==_maxNumberOfEvents)
                 {
                     *stop = YES;
                 }
             }];
        }
    }
}

- (NSMutableArray *)fetchSelectedCalendars
{
    NSMutableArray * calendarArray = nil;
    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray * chosenCalendars = nil;
    
    chosenCalendars = [userDefaults objectForKey: CALENDAR_USER_SETTING_SELECTED_CALENDARS];
    
    if (chosenCalendars == NULL)
    {
        if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_M054)
        {
            calendarArray = (NSMutableArray *)[_eventStore calendarsForEntityType: EKEntityTypeEvent];
        }
        else
        {
            //Per discussion with Chirayu on 01/16/2015, the following was decided:
            
            //By default, none of the calendars will be selected which, effectively, means that the user will not get any appointments and pre-notifications on the watch unless he/she specifically enables calendars for synchronization.
            //Once enabled, the selected calendar's appointments will be synchronized at every sync.
            calendarArray  = [[NSMutableArray alloc] init];
        }
    }
    else
    {
        calendarArray  = [[NSMutableArray alloc] init];
        for (NSInteger i = 0; i < [chosenCalendars count]; i++)
        {
            EKCalendar * calendar = [_eventStore calendarWithIdentifier: [chosenCalendars objectAtIndex: i]];
            if (calendar)
            {
                [calendarArray addObject: calendar];
            }
        }
    }
    
    return calendarArray;
}

- (void) removeExcludedEventsFromArray
{
    NSInteger i = 0;
    
    for (i = 0; i < [_eventsList count]; i++)
    {
        EKEvent * event = [_eventsList objectAtIndex: i];
        NSString * uniqueID = [event eventIdentifier];
        NSDate * eventDate = [event startDate];
        NSTimeInterval eventDateInterval = [eventDate timeIntervalSince1970];
        NSString * expression = [NSString stringWithFormat:@"SELECT EventKey FROM ExcludedCalendarEvents WHERE EventKey = '%@' AND EventDate = %f;", uniqueID, eventDateInterval];
        
        TimexDatalink::IDBQuery * query = [[TimexWatchDB sharedInstance] createQuery : expression];
        if (query && query->getRowCount() > 0)
        {
            [_eventsList removeObject: event];
            i--;
        }
        
        if (query)
        {
            delete query;
        }
    }
}

- (void) getEventsFromCalendarChooser: (EKCalendarChooser *)calendarChooser andCompletionCode: (void (^)(void))completionCode
{
    [_eventsList removeAllObjects];
    [self fetchEventsInTheFuture: calendarChooser];
    [self removeExcludedEventsFromArray];
    
    completionCode();
}

- (NSData *)  toByteArray
{
    Byte raw[APPTS_FILE_DATA_SIZE];
    memset(&raw[0], 0, APPTS_FILE_DATA_SIZE);
    
    raw[0] = FILE_FORMAT_VERSION;
    
    Byte total = _eventsList.count > MAX_NUMBER_APPTS_TO_SEND_DATACAST ? MAX_NUMBER_APPTS_TO_SEND_DATACAST : _eventsList.count;
    raw[1] = total;
    
    for (int i = 0; i < total; i++)
    {
        Byte appt[INDIVIDUAL_APPT_DATA_SIZE];
        memset(&appt[0], 0, INDIVIDUAL_APPT_DATA_SIZE);
        
        EKEvent * data = [_eventsList objectAtIndex: i];
        
        NSDate * apptDate = [data startDate];
        NSDateComponents * components = [[NSCalendar currentCalendar] components: NSCalendarUnitMinute | NSCalendarUnitHour | NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate: apptDate];
        appt[0] = components.year - 2000;
        appt[1] = components.month;
        appt[2] = components.day;
        appt[3] = 0;//reserved
        
        if (data.title)
        {
            memcpy(&appt[4], [data.title UTF8String], MIN(strlen([data.title UTF8String]), 64));
        }
        
        appt[68] = components.hour;
        appt[69] = components.minute;
        appt[70] = 0; //start time seconds
        appt[71] = 0;//reserved
        
        NSDate * endDate = [data endDate];
        NSDateComponents * componentsEnd = [[NSCalendar currentCalendar] components: NSCalendarUnitMinute | NSCalendarUnitHour | NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate: endDate];
        
        appt[72] = componentsEnd.hour;
        appt[73] = componentsEnd.minute;
        appt[74] = 0;//end time seconds
        appt[75] = 0;//reserved
        
        if (data.location)
        {
            memcpy(&appt[76], [data.location UTF8String], MIN(strlen([data.location UTF8String]), 32));
        }
        
        //now, set the pre-notification (alarm)
        
        NSTimeInterval secs = 0.0;
        //for Datacast, no matching of any sort required...
        secs = [iDevicesUtil getEventAlarmTimeInSeconds: data];
        
        if (secs <= 0 && secs != DBL_MAX)
        {
            //this is "proper" alarm, which takes place prior to the start time of the event. Use the absolute value of this:
            secs = fabs(secs);
            
            //the maximum for Datacast is 31 days, 23 hours, 59 minutes.
            double fifty_nine_minutes = 60 * 59;
            double twenty_three_hours = 23 * 60 * 60;
            double thirty_one_days = 31 * 24 * 60 * 60;
            NSTimeInterval max_cutoff = thirty_one_days + twenty_three_hours + fifty_nine_minutes;
            
            if (secs > max_cutoff)
                secs = max_cutoff;
        }
        else if (secs > 0 && secs != DBL_MAX)
        {
            //as of Cinco de Mayo of 2014, the only way we could get an alarm that starts after the start time of the event is if in the Calendar settings the default
            //for Birthdays/All Day events is set to "9AM of the Day of the event" There is no other way to set the alarm to be after the start of the event.
            //Per Timex Request, modify the start time of the appointment to be at the time of the alarm:
            
            if (secs <= 86400) //86400 is number of seconds per day
            {
                NSDate * alarmFiringTime = [NSDate dateWithTimeInterval: secs sinceDate: apptDate];
                NSDateComponents * components = [[NSCalendar currentCalendar] components: NSCalendarUnitMinute | NSCalendarUnitHour | NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate: alarmFiringTime];
                appt[0] = components.year - 2000;
                appt[1] = components.month;
                appt[2] = components.day;
                appt[68] = components.hour;
                appt[69] = components.minute;
            }
            secs = 0;
        }
        
        int days = (secs == DBL_MAX) ? 0xFF : ((int)secs) / 86400;
        
        int reminder = secs - (days * 86400);
        int hour = (secs == DBL_MAX) ? 0xFF : reminder / 3600;
        
        int reminderMinutes = reminder - (hour * 3600);
        int minute = (secs == DBL_MAX) ? 0xFF : reminderMinutes / 60;
        
        appt[108] = (Byte)days; //days
        appt[109] = (Byte)hour; //hour
        appt[110] = (Byte)minute; //minute
        
        appt[111] = 0;//reserved
        appt[112] = componentsEnd.year - 2000;
        appt[113] = componentsEnd.month;
        appt[114] = componentsEnd.day;
        appt[115] = 0;//reserved
        
        memcpy(&raw[4 + i * INDIVIDUAL_APPT_DATA_SIZE], appt, INDIVIDUAL_APPT_DATA_SIZE);
    }
    
    _mLastChecksum = [iDevicesUtil calculateTimexCRC32: raw withLength: APPTS_FILE_DATA_SIZE - 4];
    
    NSData * ptrData = [iDevicesUtil intToByteArray: _mLastChecksum];
    Byte ptrBytes[4];
    [ptrData getBytes: ptrBytes];
    memcpy(&raw[APPTS_FILE_DATA_SIZE - 4], ptrBytes, 4);
    
    NSData * dataContainer = [NSData dataWithBytes: raw length: APPTS_FILE_DATA_SIZE];
    return dataContainer;
}

- (NSData *) toM053ByteArray
{
    Byte raw[APPTS_M053_FILE_DATA_SIZE];
    memset(&raw[0], 0, APPTS_M053_FILE_DATA_SIZE);
    
    Byte total = _eventsList.count > MAX_NUMBER_APPTS_TO_SEND_CONNECT1_5 ? MAX_NUMBER_APPTS_TO_SEND_CONNECT1_5 : _eventsList.count;
    raw[0] = total;
    
    for (int i = 0; i < total; i++)
    {
        Byte appt[INDIVIDUAL_M053_APPT_DATA_SIZE];
        memset(&appt[0], 0, INDIVIDUAL_M053_APPT_DATA_SIZE);
        
        EKEvent * data = [_eventsList objectAtIndex: i];
        
        NSDate * apptDate = [data startDate];
        NSDateComponents * components = [[NSCalendar currentCalendar] components: NSCalendarUnitMinute | NSCalendarUnitHour | NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate: apptDate];
        appt[0] = components.minute;
        appt[1] = components.hour;
        appt[2] = components.day;
        appt[3] = components.month;
        appt[4] = components.year - 2000;
        
        NSTimeInterval secs = 0.0;
        calendar_alarmTimeOptions alarmTime = [iDevicesUtil getEventAlarmTime: data];
        secs = [iDevicesUtil getSecondsValueForAlarmSetting: alarmTime];
        appt[5] = secs / 60;
        
        memcpy(&raw[1 + i * INDIVIDUAL_M053_APPT_DATA_SIZE], appt, INDIVIDUAL_M053_APPT_DATA_SIZE);
    }
    
    int checksumM053 = [iDevicesUtil calculateTimexM053Checksum: raw withLength: APPTS_M053_FILE_DATA_SIZE - 4];
    
    NSData * ptrData = [iDevicesUtil intToByteArray: checksumM053];
    Byte ptrBytes[4];
    [ptrData getBytes: ptrBytes];
    memcpy(&raw[APPTS_M053_FILE_DATA_SIZE - 4], ptrBytes, 4);
    
    NSData * dataContainer = [NSData dataWithBytes: raw length: APPTS_M053_FILE_DATA_SIZE];
    return dataContainer;
}

@end
