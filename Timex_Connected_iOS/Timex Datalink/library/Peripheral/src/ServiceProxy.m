//
//  ServiceProxy.m
//  HeartRateMonitor
//
//  Created by Michael Nannini on 1/16/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

#import "ServiceProxy.h"

@interface ServiceProxy ()
{
    SEL                         _loadCharSelector;
    id<NSObject>  __weak        _loadCharTarget;
    FoundCharacteristicBlock    _loadCharBlock;
}
@end

@implementation ServiceProxy


-(id) init
{
    self = [super init];
    
    if ( self )
    {
        _characteristics = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

-(CBUUID*) UUID
{
    return nil;
}

-(PeripheralProxy*) peripheral
{
    return _peripheral;
}

-(CharacteristicProxy*) findCharacteristic:(CBUUID*)characteristicId
{
    CharacteristicProxy* characteristic = [_characteristics objectForKey:characteristicId];
    
    return characteristic;
}

-(ServiceProxy*) findIncludedService:(CBUUID*)serviceId
{
    ServiceProxy* service = [_includedServices objectForKey:serviceId];
    
    return service;
}


-(void) loadCharacteristics:(NSArray*)characteristicIds foundSelector:(SEL)selector target:(id<NSObject>)target
{
    if ( target && selector )
    {
        _loadCharSelector = selector;
        _loadCharTarget = target;
        
    }
    else
    {
        _loadCharTarget = nil;
        _loadCharSelector = nil;
    }
    
    _loadCharBlock = nil;
}


-(void) loadCharacteristics:(NSArray *)characteristicIds foundBlock:(FoundCharacteristicBlock)block
{
    _loadCharBlock = block;
    _loadCharTarget = nil;
    _loadCharSelector = nil;
}

-(void) foundCharacteristic:(CharacteristicProxy*)characteristic
{
    if ( _loadCharSelector && _loadCharTarget )
    {
        [_loadCharTarget performSelector:_loadCharSelector withObject:characteristic];
    }
    else if ( _loadCharBlock )
    {
        _loadCharBlock(characteristic);
    }
}


@end
