//
//  HourActivityModal.h
//  timex
//
//  Created by Aruna Kumari Yarra on 07/04/17.
//  Copyright © 2017 iDevices, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HourActivityModal : NSObject

@property (nonatomic, copy) NSNumber *steps;
@property (nonatomic, copy) NSNumber *distance;
@property (nonatomic, copy) NSNumber *calories;
@property (nonatomic, copy) NSDate *date;
@property (nonatomic, copy) NSString *timeID;
@property (nonatomic, retain) NSString *watchID;

@end
