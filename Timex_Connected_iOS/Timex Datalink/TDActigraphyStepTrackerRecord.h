//
//  TDActigraphyStepTrackerRecord.h
//  timex
//
//  Created by Aruna Kumari Yarra on 10/04/17.
//  Copyright © 2017 iDevices, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TDActigraphyStepTrackerRecord : NSObject

@property (nonatomic) Byte mActivityDataSavedFlag;
@property (nonatomic) unsigned int   mTotalSteps;
@property (nonatomic) unsigned short mTotalDistance;
@property (nonatomic) unsigned int   mTotalCalories;
@property (nonatomic) NSString   *mTimeId;
@property (nonatomic) NSDate    *date;

@end
