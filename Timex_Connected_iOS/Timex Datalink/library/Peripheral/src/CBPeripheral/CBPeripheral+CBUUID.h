//
//  CBPeripheral+CBUUID.h
//  Peripheral
//
//  Created by Michael Nannini on 12/11/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>

@interface CBPeripheral (CBUUID)

@property (nonatomic, readonly) CBUUID* CBUUID;

@end
