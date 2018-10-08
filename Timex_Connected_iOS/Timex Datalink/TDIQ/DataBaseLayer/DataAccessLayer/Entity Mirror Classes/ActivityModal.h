//
//  Activity_Mock.h
//  Timex
//
//

#import <Foundation/Foundation.h>
#import "SleepEventsModal.h"
#import "HourActivityModal.h"
@interface ActivityModal : NSObject
@property (nonatomic, retain) NSNumber *calories;
@property (nonatomic, retain) NSDate *date;
@property (nonatomic, retain) NSNumber *distance;
@property (nonatomic, retain) NSString *segments;
@property (nonatomic, retain) NSNumber *sleep;
@property (nonatomic, retain) NSNumber *steps;
@property (nonatomic, retain) NSString *watchID;
@property (nonatomic, retain) NSSet<SleepEventsModal *> *sleepEvents;
@property (nonatomic, retain) NSSet <HourActivityModal *> *hourActivities;
@end
