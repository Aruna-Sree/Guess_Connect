//
//  DBHourActivity+Helper.m
//  timex
//
//  Created by Aruna Kumari Yarra on 10/04/17.
//  Copyright © 2017 iDevices, LLC. All rights reserved.
//

#import "HourActivity+Helper.h"
#import "HourActivityModal.h"
#import "iDevicesUtil.h"
@implementation DBHourActivity (Helper)
- (void) saveDetailsInDB:(id)details
{
    HourActivityModal *hourActivity = (HourActivityModal*)details;
    
    self.watchID = [iDevicesUtil getWatchID];
    self.date = hourActivity.date;
    self.timeID = hourActivity.timeID;
    self.steps = hourActivity.steps;
    self.distance = hourActivity.distance;
    self.calories = hourActivity.calories;
}

- (void) updateDetailsInDB:(id)details
{
    HourActivityModal *hourActivity = (HourActivityModal*)details;
    
    self.date = hourActivity.date;
    self.timeID = hourActivity.timeID;
    self.steps = hourActivity.steps;
    self.distance = hourActivity.distance;
    self.calories = hourActivity.calories;
    if (self.watchID == nil || [self.watchID  isEqualToString: @""]) {
        self.watchID = [iDevicesUtil getWatchID];
    }
}
@end
