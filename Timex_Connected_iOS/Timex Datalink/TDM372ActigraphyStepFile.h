//
//  M372ActigraphyStepFile.h
//  SleepTrackerFilesTool
//
//  Created by Diego Santiago on 3/11/16.
//  Copyright © 2016 Diego Santiago. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TDM372ActigraphyStepFile : NSObject

@property (nonatomic) Byte mDay;
@property (nonatomic) Byte mMonth;
@property (nonatomic) Byte mYear;
@property (nonatomic) Byte mStatus;

- (id) init: (NSData *) inData;



@end
