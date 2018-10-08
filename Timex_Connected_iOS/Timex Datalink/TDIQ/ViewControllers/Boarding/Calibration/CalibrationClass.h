//
//  CalibrationClass.h
//  timex
//
//  Created by Raghu on 05/07/16.
//  Copyright © 2016 iDevices, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PCCOMM_Utils.h"
#import "iDevicesUtil.h"
#import "ServiceProxy.h"
#import "CharacteristicProxy.h"
#import "PeripheralDevice.h"
#import "PCCOMMDefines.h"
#import "BLECharacteristic.h"
#import "BLEPeripheral.h"
#import "BLEServiceDefs.h"

@interface CalibrationClass : NSObject

@property MotorDir_t motorDirection;

+(id) sharedInstance;

@property enum Hand_Type motorType;
@property int steps;

//        QA_MOTOR_NONE,  // 0
//        QA_MOTOR_1,		// 1, MINUTE HAND
//        QA_MOTOR_2,		// 2, HOUR HAND
//        QA_MOTOR_3,		// 3, SUBDIAL HAND
//        QA_TOD_MOTOR	// 4, SECONDS HAND


-(void)buildPCCOMMCalibMessage:(PCCOMM_Cmd_t)cmd;
-(void) sendTDLSDataPacket:(NSData*)data;
-(void)enterCalibrationMode;
-(void)exitCalibrationMode;

@end
