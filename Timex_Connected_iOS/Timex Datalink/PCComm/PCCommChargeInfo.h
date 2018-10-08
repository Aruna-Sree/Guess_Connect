//
//  PCCommChargeInfo.h
//  Timex
//
//  Created by Lev Verbitsky on 9/3/14.
//  Copyright (c) 2014 iDevices, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#define PCCOMM_SIZE_CHARGEINFO 20

@interface PCCommChargeInfo : NSObject

@property (nonatomic) Byte  ACK;
@property (nonatomic) Byte  Handle;
@property (nonatomic) Byte  Unused;
@property (nonatomic) Byte  USBStatus;
@property (nonatomic) float current;
@property (nonatomic) float charge;
@property (nonatomic) float temperature;
@property (nonatomic) float voltage;

- (id) init: (NSData *) data;

@end
