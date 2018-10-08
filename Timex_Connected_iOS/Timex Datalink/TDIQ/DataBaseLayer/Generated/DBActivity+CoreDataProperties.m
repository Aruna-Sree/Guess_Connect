//
//  DBActivity+CoreDataProperties.m
//  timex
//
//  Created by Aruna Kumari Yarra on 10/04/17.
//  Copyright © 2017 iDevices, LLC. All rights reserved.
//

#import "DBActivity+CoreDataProperties.h"

@implementation DBActivity (CoreDataProperties)

+ (NSFetchRequest<DBActivity *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"DBActivity"];
}

@dynamic calories;
@dynamic date;
@dynamic distance;
@dynamic segments;
@dynamic sleep;
@dynamic steps;
@dynamic hourActivities;
@dynamic sleepEvents;
@dynamic watchID;
@end
