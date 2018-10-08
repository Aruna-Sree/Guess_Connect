//
//  SimPeripheral.m
//  Wahooo
//
//  Created by Michael Nannini on 1/28/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

#import "SimPeripheral.h"
#import "SimService.h"

@interface SimPeripheral ()
{
    CBUUID*     _uuid;
    BOOL        _connected;
}

@end


@implementation SimPeripheral

-(CBUUID*) UUID
{
    return _uuid;
}

-(BOOL) isConnected
{
    return _connected;
}


-(PeripheralSourceType) type
{
    return kPeripheralSource_Sim;
}

-(id) initWithUUID:(CBUUID*)uuid
{
    self = [super init];
    
    if ( self )
    {
        _uuid = [uuid copy];
    }
    
    return self;
}

-(void) addService:(SimService*)service
{
    service.peripheral = self;
    
    [_services setObject:service forKey:service.UUID];
}

-(void) setConnected:(BOOL)connected
{
    _connected = connected;
}


-(void) loadServices:(NSArray *)serviceIds foundSelector:(SEL)found target:(id<NSObject>)target
{
    [self loadServices:serviceIds foundSelector:found completeSelector:nil target:target];
}

-(void) loadServices:(NSArray *)serviceIds foundSelector:(SEL)found completeSelector:(SEL)complete target:(id<NSObject>)target
{
    [super loadServices:serviceIds foundSelector:found completeSelector:complete target:target];
    
    NSArray* services = [_services allValues];
    
    for( ServiceProxy* service in services )
    {
        if ( [serviceIds containsObject:service.UUID] )
        {
            [self foundService:service];
        }
        
    }
    
    [self foundServiceCompleted];
    
}

-(void) loadServices:(NSArray *)serviceIds foundBlock:(FoundServiceBlock)block
{
    [self loadServices:(NSArray*)serviceIds foundBlock:block completeBlock:nil];
}

-(void) loadServices:(NSArray *)serviceIds foundBlock:(FoundServiceBlock)block completeBlock:(FoundServiceCompleteBlock)completeBlock
{
    [super loadServices:serviceIds foundBlock:block completeBlock:completeBlock];
    
    NSArray* services = [_services allValues];
    
    for( ServiceProxy* service in services )
    {
        if ( [serviceIds containsObject:service.UUID] )
        {
            [self foundService:service];
        }

    }

   [self foundServiceCompleted];
}

@end
