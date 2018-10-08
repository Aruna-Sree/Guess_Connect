//
//  ActRecord.h
//  SleepTrackerFilesTool
//
//  Created by Diego Santiago on 3/4/16.
//  Copyright © 2016 Diego Santiago. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TDM372DailyActivityFile : NSObject

@property (nonatomic) Byte mDay;
@property (nonatomic) Byte mMonth;
@property (nonatomic) Byte mYear;
@property (nonatomic) Byte mActivityDataSavedFlag; 
@property (nonatomic) unsigned int   mTotalSteps;
@property (nonatomic) unsigned short mTotalDistance;
@property (nonatomic) unsigned int   mTotalCalories;
- (void) readActivities: (NSData *) inDataObject;

//@property (nonatomic,strong) NSDateFormatter *formatter;

- (id) init;
- (id) init: (NSData *) inData;


@end

