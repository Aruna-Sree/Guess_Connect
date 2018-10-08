//
//  SimCharacteristic.h
//  Wahooo
//
//  Created by Michael Nannini on 1/28/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

#import "CharacteristicProxy.h"

@class SimCharacteristic;

@protocol SimCharacteristicDelegate <NSObject>

//! allow delegate a chance to return a simulated error
-(NSError*) simCharacteristic:(SimCharacteristic*)characteristic simulateWriteWithData:(NSData*)data;

//! post write processing simulation only
-(void) simCharacteristic:(SimCharacteristic*)characteristic didWriteValue:(NSData*)data;

@end

@interface SimCharacteristic : CharacteristicProxy

@property (nonatomic, weak) id<SimCharacteristicDelegate> delegate;

@property (nonatomic, copy) NSData* data;

-(id) initWithUUID:(CBUUID*)uuid;

-(id) initWithUUID:(CBUUID*)uuid andValue:(NSData*)data;

-(void) setService:(ServiceProxy *)service;

-(void) setProperties:(NSUInteger) props;

@end
