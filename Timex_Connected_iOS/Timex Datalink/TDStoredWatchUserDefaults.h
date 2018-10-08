//
//  TDStoredWatchUserDefaults.h
//  timex
//
//  Created by Nick Graff on 3/24/17.
//  Copyright © 2017 iDevices, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "iDevicesUtil.h"
#import "TDDefines.h"

@interface TDStoredWatchUserDefaults : NSObject

+(void)setStoredPeripherals:(NSArray*)value;
+(NSArray*)storedPeripherals;
+(void)changeHomeScreen:(PeripheralDevice*)device;

@end
