//
//  M372ActigraphyKeyFileTrackerRecord.h
//  Timex
//
//  Created by Diego Santiago on 3/22/16.
//  Copyright © 2016 iDevices, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TDM372ActigraphyKeyFileTrackerRecord : NSObject

@property (nonatomic) Byte mKeyRecords;
@property (nonatomic) Byte mDay;
@property (nonatomic) Byte mMonth;
@property (nonatomic) Byte mYear;
@property (nonatomic) Byte mStatus;

- (NSDate *) getActivityDate;


@end
