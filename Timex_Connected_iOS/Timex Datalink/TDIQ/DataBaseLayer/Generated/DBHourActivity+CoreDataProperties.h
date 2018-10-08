//
//  DBHourActivity+CoreDataProperties.h
//  timex
//
//  Created by Aruna Kumari Yarra on 10/04/17.
//  Copyright © 2017 iDevices, LLC. All rights reserved.
//

#import "DBHourActivity+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface DBHourActivity (CoreDataProperties)

+ (NSFetchRequest<DBHourActivity *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSNumber *calories;
@property (nullable, nonatomic, copy) NSDate *date;
@property (nullable, nonatomic, copy) NSNumber *distance;
@property (nullable, nonatomic, copy) NSNumber *steps;
@property (nullable, nonatomic, copy) NSString *timeID;
@property (nullable, nonatomic, copy) NSString *watchID;
@end

NS_ASSUME_NONNULL_END
