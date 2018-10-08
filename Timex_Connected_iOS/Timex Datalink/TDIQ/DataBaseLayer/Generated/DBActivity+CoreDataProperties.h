//
//  DBActivity+CoreDataProperties.h
//  timex
//
//  Created by Aruna Kumari Yarra on 10/04/17.
//  Copyright © 2017 iDevices, LLC. All rights reserved.
//

#import "DBActivity+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface DBActivity (CoreDataProperties)

+ (NSFetchRequest<DBActivity *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSNumber *calories;
@property (nullable, nonatomic, copy) NSDate *date;
@property (nullable, nonatomic, copy) NSNumber *distance;
@property (nullable, nonatomic, copy) NSString *segments;
@property (nullable, nonatomic, copy) NSNumber *sleep;
@property (nullable, nonatomic, copy) NSNumber *steps;
@property (nullable, nonatomic, retain) NSSet<DBHourActivity *> *hourActivities;
@property (nullable, nonatomic, retain) NSSet<DBSleepEvents *> *sleepEvents;
@property (nullable, nonatomic, copy) NSString *watchID;

@end

@interface DBActivity (CoreDataGeneratedAccessors)

- (void)addHourActivitiesObject:(DBHourActivity *)value;
- (void)removeHourActivitiesObject:(DBHourActivity *)value;
- (void)addHourActivities:(NSSet<DBHourActivity *> *)values;
- (void)removeHourActivities:(NSSet<DBHourActivity *> *)values;

- (void)addSleepEventsObject:(DBSleepEvents *)value;
- (void)removeSleepEventsObject:(DBSleepEvents *)value;
- (void)addSleepEvents:(NSSet<DBSleepEvents *> *)values;
- (void)removeSleepEvents:(NSSet<DBSleepEvents *> *)values;

@end

NS_ASSUME_NONNULL_END
