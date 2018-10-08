//
//  TDDatacastApptsParser.h
//  Timex Connected
//
//  Created by Lev Verbitsky on 2/3/14.
//  Copyright (c) 2014 iDevices, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <EventKit/EventKit.h>
#import <EventKitUI/EventKitUI.h>

#define MAX_NUMBER_APPTS_TO_SEND_DATACAST 10
#define MAX_NUMBER_APPTS_TO_SEND_CONNECT1_5 50
#define APPTS_FILE_DATA_SIZE 1168
#define INDIVIDUAL_APPT_DATA_SIZE 116
#define APPTS_M053_FILE_DATA_SIZE 305
#define INDIVIDUAL_M053_APPT_DATA_SIZE 6

@interface TDDatacastApptsParser : NSObject

@property (nonatomic, strong) EKEventStore * eventStore;
@property (nonatomic, strong) NSMutableArray * eventsList;
@property (nonatomic, readonly) int mLastChecksum;

- (id)               init: (NSInteger) maxNumberOfCalEvents;
- (void)             reloadCalendarData: (void (^)(void))completionCode;
- (void)             removeExcludedEventsFromArray;
- (NSMutableArray *) fetchSelectedCalendars;
- (NSData *)         toByteArray;
- (NSData *)         toM053ByteArray;
- (void)             getEventsFromCalendarChooser: (EKCalendarChooser *)calendarChooser andCompletionCode: (void (^)(void))completionCode;
@end