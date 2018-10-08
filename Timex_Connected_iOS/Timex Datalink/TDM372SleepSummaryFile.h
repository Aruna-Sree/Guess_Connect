//
//  M372SleepSummaryFile.h
//  Timex
//
//  Created by Diego Santiago on 3/10/16.
//  Copyright © 2016 iDevices, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TDM372SleepSummaryFile : NSObject

//@property (nonatomic) Byte mMaxRecordNumber;
//@property (nonatomic) Byte mNextRecordIndex;
//@property (nonatomic) Byte mSumaryrecords;
//
//@property (nonatomic) Byte mDay;
//@property (nonatomic) Byte mMonth;
//@property (nonatomic) Byte mYear;
//
//
//@property (nonatomic) unsigned long   mStartMinute;
//@property (nonatomic) unsigned long   mStartHour;
//@property (nonatomic) unsigned long   mEndHour;
//@property (nonatomic) unsigned long   mEndMinute;
//@property (nonatomic) unsigned long   mEndDate;
//@property (nonatomic) unsigned long   mEndMonth;
//@property (nonatomic) unsigned long   mEndYear;
//@property (nonatomic) unsigned int    mSleepOffSet;
//@property (nonatomic) unsigned long   mDuration;
//@property (nonatomic) unsigned long   mStatus;
//
//@property (nonatomic,strong) NSDateFormatter *formatter;
//@property (nonatomic,strong) NSDateFormatter *formatterNoKey;

@property (nonatomic, strong) dispatch_semaphore_t semaphore;

//- (NSMutableDictionary *) readSleepActivities: (NSData *) inDataObject;

- (id) init;
- (id) init: (NSData *) inData;

@end
