//
//  DBSleepEvents+CoreDataProperties.m
//  timex
//
//  Created by Raghu on 26/08/16.
//  Copyright © 2016 iDevices, LLC. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "DBSleepEvents+CoreDataProperties.h"

@implementation DBSleepEvents (CoreDataProperties)

@dynamic date;
@dynamic duration;
@dynamic endDate;
@dynamic eventValid;
@dynamic segmentsByEvent;
@dynamic startDate;
@dynamic twoDaysEvent;
@dynamic watchID;
@dynamic isEdited;
@dynamic startDateEndDateString;

-(NSString*)description{
    return [NSString stringWithFormat:@"Date: %@ ,Duration %f, Segment %@",self.date,self.duration.doubleValue,self.segmentsByEvent];
}

@end
