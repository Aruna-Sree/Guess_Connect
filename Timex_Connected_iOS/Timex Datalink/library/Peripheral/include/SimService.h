//
//  SimService.h
//  Wahooo
//
//  Created by Michael Nannini on 1/28/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

#import "ServiceProxy.h"

@class SimCharacteristic;

@interface SimService : ServiceProxy

-(id) initWithUUID:(CBUUID*)uuid;

-(void) addCharacteristic:(SimCharacteristic*)characteristic;

-(void) setPeripheral:(PeripheralProxy*)peripheral;

@end
