//
//  M372ActigraphyDataFile.h
//  SleepTrackerFilesTool
//
//  Created by Diego Santiago on 3/14/16.
//  Copyright © 2016 Diego Santiago. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TDM372ActigraphyDataFile : NSObject

@property (nonatomic) Byte mKeyRecords;
@property (nonatomic) Byte mDay;
@property (nonatomic) Byte mMonth;
@property (nonatomic) Byte mYear;
@property (nonatomic) Byte mStatus;
//@property (nonatomic, strong) NSDateFormatter *formatter;

- (id) init: (NSData *) inData;


@end
