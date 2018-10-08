//
//  M372ActigraphyKeyFile.h
//  SleepTrackerFilesTool
//
//  Created by Diego Santiago on 3/14/16.
//  Copyright © 2016 Diego Santiago. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TDM372ActigraphyKeyFile : NSObject

//@property (nonatomic) Byte mMaxNumFiles;
//@property (nonatomic) Byte mFileNameIndex;
//@property (nonatomic) Byte mKeyRecords;
//@property (nonatomic) Byte mDay;
//@property (nonatomic) Byte mMonth;
//@property (nonatomic) Byte mYear;
//@property (nonatomic) unsigned long mStatus;

//@property (nonatomic, strong) NSDateFormatter *formatter;

- (id) init;
- (id) init: (NSData *) inData;

@end
