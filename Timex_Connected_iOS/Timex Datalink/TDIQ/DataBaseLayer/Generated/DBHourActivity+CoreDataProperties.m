//
//  DBHourActivity+CoreDataProperties.m
//  timex
//
//  Created by Aruna Kumari Yarra on 10/04/17.
//  Copyright © 2017 iDevices, LLC. All rights reserved.
//

#import "DBHourActivity+CoreDataProperties.h"

@implementation DBHourActivity (CoreDataProperties)

+ (NSFetchRequest<DBHourActivity *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"DBHourActivity"];
}

@dynamic calories;
@dynamic date;
@dynamic distance;
@dynamic steps;
@dynamic timeID;
@dynamic watchID;
@end
