//
//  DBManager.m
//

#import "DBManager.h"
#import "DBModule.h"
#import "iDevicesUtil.h"
#import "OTLogUtil.h"

@implementation DBManager

+ (void) addOrUpdateActivityEntities:(NSArray *)activityMockArr {
    for(NSObject* item in activityMockArr) {
        ActivityModal *activity = (ActivityModal *)item;
        [[DBModule sharedInstance] addOrUpdateRowInEntity:@"DBActivity" mockObject:activity key:@"date" value:activity.date];
    }
}

+ (DBActivity *) addOrUpdateActivity:(ActivityModal *)activityMock {
    DBActivity *activity = (DBActivity *)[[DBModule sharedInstance] addOrUpdateRowInEntity:@"DBActivity" mockObject:activityMock key:@"date" value:activityMock.date];
    return activity;
}

+ (DBHourActivity *) addOrUpdateHourActivity:(HourActivityModal *)activityHrMock {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(%K==%@) AND (timeID==%@)",@"date",activityHrMock.date,activityHrMock.timeID];
    DBHourActivity *activity = (DBHourActivity *)[[DBModule sharedInstance] addOrUpdateRowInEntity:@"DBHourActivity" mockObject:activityHrMock predicate:predicate];
    return activity;
}

// But same date has two events also. Need to check
+ (void) addOrUpdateSleepEventsArray:(NSArray *)sleepEventsMockArr {
    for(NSObject* item in sleepEventsMockArr) {
        SleepEventsModal *sleep = (SleepEventsModal *)item;
        if (sleep.startDateEndDateString != nil) {
            [[DBModule sharedInstance] addOrUpdateRowInEntity:@"DBSleepEvents" mockObject:sleep key:@"startDateEndDateString" value:sleep.startDateEndDateString];
        } else {
            [[DBModule sharedInstance] addOrUpdateRowInEntity:@"DBSleepEvents" mockObject:sleep key:nil value:nil];
        }
    }
}

// But same date has two events also. Need to check
+ (DBSleepEvents *) addOrUpdateSleepEvent:(SleepEventsModal *)item {
    
    if (item.startDateEndDateString != nil) {
       return  (DBSleepEvents *)[[DBModule sharedInstance] addOrUpdateRowInEntity:@"DBSleepEvents" mockObject:item key:@"startDateEndDateString" value:item.startDateEndDateString];
    } else {
       return (DBSleepEvents *) [[DBModule sharedInstance] addOrUpdateRowInEntity:@"DBSleepEvents" mockObject:item key:nil value:nil];
    }
}

+(void) deleteAll{
    //removing data in all tables
    [[DBModule sharedInstance] deleteAllRecordsInEntity:@"DBActivity"];
    [[DBModule sharedInstance] deleteAllRecordsInEntity:@"DBSleepEvents"];
}

+ (void)saveTotalSleep:(DBActivity *)activity {
    double sleepHrs = 0;
    for (DBSleepEvents *sleepEvent in activity.sleepEvents.allObjects) {
        if (sleepEvent.duration.doubleValue > 0 && sleepEvent.segmentsByEvent != nil && sleepEvent.segmentsByEvent.length > 0 && [sleepEvent.eventValid boolValue] && [self sameCharsInString:sleepEvent.segmentsByEvent] == NO) {
            sleepHrs += sleepEvent.duration.doubleValue;
        }
    }
//    for (DBSleepEvents *sleepEvent in activity.sleepEvents.allObjects) {
//        if ([sleepEvent.eventValid boolValue] && sleepEvent.segmentsByEvent != nil && sleepEvent.segmentsByEvent.length > 0) {
//            sleepHrs += sleepEvent.duration.doubleValue;
//        }
//    }
    activity.sleep = [NSNumber numberWithDouble:sleepHrs];
}

+(BOOL)sameCharsInString:(NSString *)str {
    if ([str length] == 0 ) return YES;
    int length = (int)[str length];
    return [[str stringByReplacingOccurrencesOfString:@"F" withString:@""] length] == length ? NO : YES;
}

@end
