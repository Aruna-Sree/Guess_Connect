//
//  DBActivity+CoreDataClass.h
//  timex
//
//  Created by Aruna Kumari Yarra on 10/04/17.
//  Copyright © 2017 iDevices, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class DBHourActivity, DBSleepEvents;

NS_ASSUME_NONNULL_BEGIN

@interface DBActivity : NSManagedObject

@end

NS_ASSUME_NONNULL_END

#import "DBActivity+CoreDataProperties.h"
