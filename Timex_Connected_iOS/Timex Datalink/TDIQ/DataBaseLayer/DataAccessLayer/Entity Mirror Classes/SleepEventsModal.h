//
//  SleepEventsModal.h
//  Timex
//
//  Created by Aruna Kumari Yarra on 26/08/16.
//  Copyright © 2016 iDevices, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SleepEventsModal : NSObject
@property (nonatomic, retain) NSDate *date;
@property (nonatomic, retain) NSNumber *duration;
@property (nonatomic, retain) NSDate *endDate;
@property (nonatomic, retain) NSString *eventValid;
@property (nonatomic, retain) NSDate *startDate;
@property (nonatomic, retain) NSNumber *twoDaysEvent;
@property (nonatomic, retain) NSString *segmentsByEvent;
@property (nonatomic, retain) NSString *watchID;
@property (nonatomic, retain) NSString *isEdited;
@property (nonatomic, retain) NSString *startDateEndDateString;
@end
