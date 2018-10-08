//
//  Activity+Helper.m
//  Timex
//
//  Created by Aruna Kumari Yarra on 26/08/16.
//  Copyright © 2016 iDevices, LLC. All rights reserved.
//

#import "Activity+Helper.h"
#import "ActivityModal.h"
#import "SleepEvents+Helper.h"
#import "DBModule.h"
#import "iDevicesUtil.h"

@implementation DBActivity (Helper)

- (void) saveDetailsInDB:(id)details
{
    ActivityModal *activity = (ActivityModal*)details;
    
    self.steps = activity.steps;
    self.distance = activity.distance;
    self.calories = activity.calories;
    self.sleep = activity.sleep;
    self.date = activity.date;
    self.segments = activity.segments;
    self.watchID = [iDevicesUtil getWatchID];
    
    NSMutableSet *sleepEvents = [[NSMutableSet alloc] init];
    for (SleepEventsModal *sleep in activity.sleepEvents.allObjects) {
        DBSleepEvents *event = (DBSleepEvents *)[[DBModule sharedInstance] addOrUpdateRowInEntity:@"DBSleepEvents" mockObject:sleep key:@"date" value:sleep.date];
        [sleepEvents addObject:event];
    }
    self.sleepEvents = sleepEvents;
    
    NSMutableSet *hourActivities = [[NSMutableSet alloc] init];
    for (HourActivityModal *activityHrMock in activity.hourActivities.allObjects) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(%K==%@) AND (timeID==%@)",@"date",activityHrMock.date,activityHrMock.timeID];
        DBHourActivity *activity = (DBHourActivity *)[[DBModule sharedInstance] addOrUpdateRowInEntity:@"DBHourActivity" mockObject:activityHrMock predicate:predicate];
        [hourActivities addObject:activity];
    }
    self.hourActivities = hourActivities;
    
    [[DBModule sharedInstance] saveContext];
}

- (void) updateDetailsInDB:(id)details
{
    ActivityModal *activity = (ActivityModal*)details;
    
    self.steps = activity.steps;
    self.distance = activity.distance;
    self.calories = activity.calories;
    self.sleep = activity.sleep;
    self.date = activity.date;
    self.segments = activity.segments;
    if (self.watchID == nil || [self.watchID  isEqualToString: @""]) {
        self.watchID = [iDevicesUtil getWatchID];
    }
    
    NSMutableSet *sleepEvents = [[NSMutableSet alloc] init];
    for (SleepEventsModal *sleep in activity.sleepEvents.allObjects) {
        DBSleepEvents *event = (DBSleepEvents *)[[DBModule sharedInstance] addOrUpdateRowInEntity:@"DBSleepEvents" mockObject:sleep key:@"date" value:sleep.date];
        [sleepEvents addObject:event];
    }
    
    self.sleepEvents = sleepEvents;
    
    NSMutableSet *hourActivities = [[NSMutableSet alloc] init];
    for (HourActivityModal *activityHrMock in activity.hourActivities.allObjects) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(%K==%@) AND (timeID==%@)",@"date",activityHrMock.date,activityHrMock.timeID];
        DBHourActivity *activity = (DBHourActivity *)[[DBModule sharedInstance] addOrUpdateRowInEntity:@"DBHourActivity" mockObject:activityHrMock predicate:predicate];
        [hourActivities addObject:activity];
    }
    self.hourActivities = hourActivities;
    
    [[DBModule sharedInstance] saveContext];
}

@end
