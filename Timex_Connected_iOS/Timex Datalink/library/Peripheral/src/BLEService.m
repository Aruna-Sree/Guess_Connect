//
//  BLEService.m
//  HeartRateMonitor
//
//  Created by Michael Nannini on 1/16/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

#import "BLEService.h"
#import "BLECharacteristic.h"

@implementation BLEService

@synthesize cbService=_service;

-(id) initWithService:(CBService*)service
{
    self = [super init];
    
    if ( self )
    {
        _service = service;
    }
    
    return self;
}

-(CBUUID*) UUID
{
    return _service.UUID;
}


-(void) setPeripheral:(PeripheralProxy*)peripheral
{
    _peripheral = peripheral;
}

-(void) loadDiscoveredCharacteristics
{
 
    NSArray* characteristics = [_service.characteristics copy];
    
    for( CBCharacteristic* characteristic in characteristics )
    {
        CharacteristicProxy* proxyChar = [self findCharacteristic:characteristic.UUID];
        
        if ( proxyChar == nil )
        {
            BLECharacteristic* bleChar = [[BLECharacteristic alloc] initWithCharacteristic:characteristic];
            
            [bleChar setService:self];
            
            [_characteristics setObject:bleChar forKey:characteristic.UUID];
            
            [self foundCharacteristic:bleChar];
        }
        
    }
    
}

-(void) loadCharacteristics:(NSArray*)characteristicIds foundSelector:(SEL)selector target:(id<NSObject>)target
{
    [super loadCharacteristics:characteristicIds foundSelector:selector target:target];
    
    [_service.peripheral discoverCharacteristics:characteristicIds forService:_service];
}

-(void) loadCharacteristics:(NSArray *)characteristicIds foundBlock:(FoundCharacteristicBlock)block
{
    [super loadCharacteristics:characteristicIds foundBlock:block];
    
    [_service.peripheral discoverCharacteristics:characteristicIds forService:_service];
}


@end
