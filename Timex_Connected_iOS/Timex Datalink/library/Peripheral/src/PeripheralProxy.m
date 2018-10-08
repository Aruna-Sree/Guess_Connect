//
//  PeripheralProxy.m
//  HeartRateMonitor
//
//  Created by Michael Nannini on 1/16/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

#import "PeripheralProxy.h"
#import "ServiceProxy.h"

@interface PeripheralProxy ()
{
    SEL             _loadServiceSelector;
    SEL             _loadServiceCompleteSelector;
    id<NSObject>  __weak  _loadServiceTarget;
    
    FoundServiceBlock _loadServiceBlock;
    FoundServiceCompleteBlock _loadServiceCompleteBlock;
    
    UpdateRSSIBlock     _updateRSSIBlock;
    SEL                 _updateRSSISelector;
    id<NSObject> __weak _updateRSSITarget;
}


@end

@implementation PeripheralProxy

-(id) init
{
    self = [super init];
    
    if ( self )
    {
        _services = [[NSMutableDictionary alloc] init];

    }
    
    return self;
}

-(CBUUID*) UUID
{
    return nil;
}

-(NSString*) name
{
    return @"No Name";
}

-(BOOL) isConnected
{
    return NO;
}

-(int) RSSI
{
    return -110.0;
}

-(NSTimeInterval) discoveredTime
{
    return 0;
}

-(PeripheralSourceType) type
{
    return kPeripheralSource_Unknown;
}

-(ServiceProxy*) findService:(CBUUID*)serviceId
{
    ServiceProxy* service = [_services objectForKey:serviceId];
    
    return service;
}

-(CharacteristicProxy*) findCharacteristic:(CBUUID*)charId forService:(CBUUID*)serviceId
{
    ServiceProxy* service = [self findService:serviceId];
    CharacteristicProxy* characteristic = nil;
    
    if ( service )
    {
        characteristic = [service findCharacteristic:charId];
    }
    
    return characteristic;
}

-(void) loadServices:(NSArray*)serviceIds foundSelector:(SEL)found target:(id<NSObject>)target
{
    [self loadServices:serviceIds foundSelector:found completeSelector:nil target:target];
}

-(void) loadServices:(NSArray *)serviceIds foundSelector:(SEL)found completeSelector:(SEL)complete target:(id<NSObject>)target
{
    if ( target && (found || complete) )
    {
        _loadServiceSelector = found;
        _loadServiceTarget = target;
        _loadServiceCompleteSelector = complete;
        
    }
    else
    {
        _loadServiceTarget = nil;
        _loadServiceSelector = nil;
        _loadServiceCompleteSelector = nil;
    }
    
    _loadServiceBlock = nil;
    _loadServiceCompleteBlock = nil;
}

-(void) loadServices:(NSArray *)serviceIds foundBlock:(FoundServiceBlock)block
{
    [self loadServices:serviceIds foundBlock:block completeBlock:nil];
}

-(void) loadServices:(NSArray *)serviceIds foundBlock:(FoundServiceBlock)foundBlock completeBlock:(FoundServiceCompleteBlock)completeBlock
{
    _loadServiceBlock = foundBlock;
    _loadServiceCompleteBlock = completeBlock;
    _loadServiceTarget = nil;
    _loadServiceSelector = nil;

}

-(void) foundService:(ServiceProxy *)service
{
    if ( _loadServiceTarget && _loadServiceSelector )
    {
        [_loadServiceTarget performSelector:_loadServiceSelector withObject:service];
    }
    else if ( _loadServiceBlock )
    {
        _loadServiceBlock( service );
    }
    
}

-(void) foundServiceCompleted
{
    if ( _loadServiceCompleteSelector && _loadServiceTarget )
    {
        [_loadServiceTarget performSelector:_loadServiceCompleteSelector withObject:self];
    }
    else if ( _loadServiceCompleteBlock )
    {
        _loadServiceCompleteBlock(self);
    }
}

-(void) updateRSSI:(SEL)selector target:(id<NSObject>)target
{
    _updateRSSISelector = selector;
    _updateRSSITarget = target;
    
    _updateRSSIBlock = nil;
}

-(void) updateRSSI:(UpdateRSSIBlock)block
{
    _updateRSSIBlock = block;
    
    _updateRSSISelector = nil;
    _updateRSSITarget = nil;

}

-(void) RSSIUpdated
{
    if ( _updateRSSIBlock )
    {
        _updateRSSIBlock(self);
    }
    else if ( _updateRSSITarget && _updateRSSISelector )
    {
        [_updateRSSITarget performSelector:_updateRSSISelector withObject:self];
    }
}

-(void) disconnect
{
    // remove all stored services;
    _services = [[NSMutableDictionary alloc] init];
}


@end
