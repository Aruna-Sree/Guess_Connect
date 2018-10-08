//
//  TDActivityTrackerRecord.h
//  Timex
//
//  Created by Lev Verbitsky on 6/10/15.
//  Copyright (c) 2015 iDevices, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TDActivityTrackerRecord : NSObject

@property (nonatomic) Byte mDay;
@property (nonatomic) Byte mMonth;
@property (nonatomic) Byte mYear;
@property (nonatomic) Byte mActivityDataSavedFlag;
@property (nonatomic) unsigned int   mTotalSteps;
@property (nonatomic) unsigned short mTotalDistance;
@property (nonatomic) unsigned int   mTotalCalories;
//@property (nonatomic) unsigned int   mTotalSleep;

- (NSDate *) getActivityDate;

@end
