//
//  SleepEvents+Helper.m
//  Timex
//
//  Created by Aruna Kumari Yarra on 26/08/16.
//  Copyright © 2016 iDevices, LLC. All rights reserved.
//

#import "SleepEvents+Helper.h"
#import "SleepEventsModal.h"
#import "iDevicesUtil.h"
@implementation DBSleepEvents (Helper)

- (void) saveDetailsInDB:(id)details
{
    SleepEventsModal *sleepEvent = (SleepEventsModal*)details;
    
    self.date = sleepEvent.date;
    self.duration = sleepEvent.duration;
    self.endDate = sleepEvent.endDate;
    self.eventValid = sleepEvent.eventValid;
    self.startDate = sleepEvent.startDate;
    self.twoDaysEvent = sleepEvent.twoDaysEvent;
    self.segmentsByEvent = sleepEvent.segmentsByEvent;
    self.watchID = [iDevicesUtil getWatchID];
    self.isEdited = sleepEvent.isEdited;
    self.startDateEndDateString = sleepEvent.startDateEndDateString;
}

- (void) updateDetailsInDB:(id)details
{
    SleepEventsModal *sleepEvent = (SleepEventsModal*)details;
    
    self.date = sleepEvent.date;
    self.duration = sleepEvent.duration;
    self.endDate = sleepEvent.endDate;
    self.eventValid = sleepEvent.eventValid;
    self.startDate = sleepEvent.startDate;
    self.twoDaysEvent = sleepEvent.twoDaysEvent;
    self.segmentsByEvent = sleepEvent.segmentsByEvent;
    if (self.watchID == nil || [self.watchID  isEqualToString: @""]) {
        self.watchID = [iDevicesUtil getWatchID];
    }
    self.isEdited = sleepEvent.isEdited;
    self.startDateEndDateString = sleepEvent.startDateEndDateString;
}
@end
