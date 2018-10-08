//
//  SimPeripheral.h
//  Wahooo
//
//  Created by Michael Nannini on 1/28/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

#import "PeripheralProxy.h"

@class SimService;

@interface SimPeripheral : PeripheralProxy

-(id) initWithUUID:(CBUUID*)uuid;

-(void) addService:(SimService*)service;

-(void) setConnected:(BOOL)connected;

@end
