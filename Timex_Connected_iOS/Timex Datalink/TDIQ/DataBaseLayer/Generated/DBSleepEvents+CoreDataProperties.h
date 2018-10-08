//
//  DBSleepEvents+CoreDataProperties.h
//  timex
//
//  Created by Raghu on 26/08/16.
//  Copyright © 2016 iDevices, LLC. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "DBSleepEvents.h"

NS_ASSUME_NONNULL_BEGIN

@interface DBSleepEvents (CoreDataProperties)

@property (nullable, nonatomic, retain) NSDate *date;
@property (nullable, nonatomic, retain) NSNumber *duration;
@property (nullable, nonatomic, retain) NSDate *endDate;
@property (nullable, nonatomic, retain) NSString *eventValid;
@property (nullable, nonatomic, retain) NSString *segmentsByEvent;
@property (nullable, nonatomic, retain) NSDate *startDate;
@property (nullable, nonatomic, retain) NSNumber *twoDaysEvent;
@property (nullable, nonatomic, retain) NSString *watchID;
@property (nullable, nonatomic, retain) NSString *isEdited;
@property (nullable, nonatomic, retain) NSString *startDateEndDateString;

@end

NS_ASSUME_NONNULL_END
