//
//  M372SleepSummaryTrackerRecord.h
//  Timex
//
//  Created by Diego Santiago on 3/21/16.
//  Copyright © 2016 iDevices, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TDM372SleepSummaryTrackerRecord : NSObject

@property (nonatomic) Byte mMaxRecordNumber;
@property (nonatomic) Byte mNextRecordIndex;
@property (nonatomic) Byte mSumaryrecords;

@property (nonatomic) Byte mDay;
@property (nonatomic) Byte mMonth;
@property (nonatomic) Byte mYear;


@property (nonatomic) Byte   mStartMinute;
@property (nonatomic) Byte   mStartHour;
@property (nonatomic) Byte   mEndHour;
@property (nonatomic) Byte   mEndMinute;
@property (nonatomic) Byte   mEndDate;
@property (nonatomic) Byte   mEndMonth;
@property (nonatomic) Byte   mEndYear;
@property (nonatomic) unsigned int      mSleepOffSet;
@property (nonatomic) unsigned int     mDuration;
@property (nonatomic) Byte   mStatus;


- (NSDate *) getActivityDate;
- (NSDate *) getActivityDateDetailStart;
- (NSDate *) getActivityDateDetailEnd;
- (NSDate *) getActivityEndDate;
@end
