//
//  BLEPeripheral.m
//  HeartRateMonitor
//
//  Created by Michael Nannini on 1/16/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

#import "BLEPeripheral.h"
#import "BLEService.h"
#import "BLECharacteristic.h"
#import "CBPeripheral+CBUUID.h"

@interface CBPeripheral (BLEPeripheral)

-(BOOL) isConnected;

@end

@interface BLEPeripheral ()
{

    NSTimeInterval _discoveredTime;
}


-(void) _loadDiscoveredServices;

-(void) _setCBPeripheral:(CBPeripheral*)peripheral;

-(CharacteristicProxy*) _findProxyForCharacteristic:(CBCharacteristic*) characteristic;

@end

@implementation BLEPeripheral

@synthesize cbPeripheral=_peripheral;

-(id) initWithPeripheral:(CBPeripheral*)peripheral
{
    self = [super init];
    
    if ( self )
    {
        _peripheral = peripheral;
        _peripheral.delegate = self;
        
        
        [self _loadDiscoveredServices];
    }
    
    return self;
}

-(void) dealloc
{
    if ( _peripheral )
        _peripheral.delegate = nil;
    
    NSLog(@"BLEPeripheral Dealloc");
}

-(CBUUID*) UUID
{
    return _peripheral.CBUUID;
}

-(NSString*) name
{
    return _peripheral.name;
}

-(PeripheralSourceType) type
{
    return kPeripheralSource_BLE;
}

-(int) RSSI
{
    if ( _peripheral.RSSI )
        return [_peripheral.RSSI intValue];
    
    return -110;
}

-(void) setDiscoveredTime:(NSTimeInterval)time
{
    _discoveredTime = time;
}

-(NSTimeInterval) discoveredTime
{
    return _discoveredTime;
}


-(void) _setCBPeripheral:(CBPeripheral*)peripheral
{
    if (_peripheral )
    {
        _peripheral.delegate = nil;
    }
    
    if ( peripheral )
    {
        peripheral.delegate = self;
    }
    
    
    _peripheral = peripheral;
}

-(BOOL) isConnected
{
    if ( [_peripheral respondsToSelector:@selector(state)] )
    {
        return (_peripheral.state == CBPeripheralStateConnected);
    }
    else if ( [_peripheral respondsToSelector:@selector(isConnected)] )
    {
        return [_peripheral isConnected];
    }

    return NO;
}

-(void) _loadDiscoveredServices
{
    NSArray* services = [_peripheral.services copy];
    
    for( CBService* service in services )
    {
        ServiceProxy* serviceProxy = [self findService:service.UUID];
        
        if ( serviceProxy == nil )
        {
            BLEService* bleService = [[BLEService alloc] initWithService:service];
            
            [bleService setPeripheral:self];
            
            [_services setObject:bleService forKey:service.UUID];
            
            [self foundService:bleService];
            
        }
    }
    
    [self foundServiceCompleted];
    
    
}

-(void) loadServices:(NSArray*)serviceIds foundSelector:(SEL)found target:(id<NSObject>)target
{
    [self loadServices:serviceIds foundSelector:found completeSelector:nil target:target];
}

-(void) loadServices:(NSArray*)serviceIds foundSelector:(SEL)found completeSelector:(SEL)complete target:(id<NSObject>)target
{
    [super loadServices:serviceIds foundSelector:found completeSelector:complete target:target];
    
    [_peripheral discoverServices:serviceIds];
}


-(void) loadServices:(NSArray *)serviceIds foundBlock:(FoundServiceBlock)block
{
    [self loadServices:serviceIds foundBlock:block completeBlock:nil];
}

-(void) loadServices:(NSArray *)serviceIds foundBlock:(FoundServiceBlock)foundBlock completeBlock:(FoundServiceCompleteBlock)completeBlock
{
    [super loadServices:serviceIds foundBlock:foundBlock completeBlock:completeBlock];
    
    [_peripheral discoverServices:serviceIds];
}

-(void) updateRSSI:(SEL)selector target:(id<NSObject>)target
{
    [super updateRSSI:selector target:target];
    
    [_peripheral readRSSI];
}

-(void) updateRSSI:(UpdateRSSIBlock)block
{
    [super updateRSSI:block];
    
    [_peripheral readRSSI];
}


-(NSString*) unknownKey
{
    return [BLEPeripheral unknownKey:_peripheral];
}

+(NSString*) unknownKey:(CBPeripheral*)peripheral;
{
    NSString* ptrString = [NSString stringWithFormat:@"%X", (uint32_t)peripheral];
    
    return ptrString;
}

-(CharacteristicProxy*) _findProxyForCharacteristic:(CBCharacteristic*) characteristic;
{
    CBService* service = characteristic.service;
    
    BLEService* bleService = [_services objectForKey:service.UUID];
    
    if ( bleService )
    {
        CharacteristicProxy* proxyChar = [bleService findCharacteristic:characteristic.UUID];
        
        return proxyChar;
    }
    else
    {
        // Why can't we find this service!?
    }

    return nil;
}


#pragma mark - CBPeripheralDelegate

-(void) peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
#if CENTRAL_USE_DISPATCH_QUEUE
    dispatch_async(dispatch_get_main_queue(), ^{
#endif
        
    if ( error )
    {
        // Handle error
        NSLog(@"BLEPeripheral Discovered Services Error \n%@", error);
    }
    
    [self _loadDiscoveredServices];
        
#if CENTRAL_USE_DISPATCH_QUEUE
    });
#endif
}

-(void) peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
#if CENTRAL_USE_DISPATCH_QUEUE
   dispatch_async(dispatch_get_main_queue(), ^{
#endif
       
    //Wrong peripheral?
    if ( peripheral != _peripheral )
    {
        return;
    }
    
    BLEService* bleService = (BLEService*)[self findService:service.UUID];
    
    if ( error )
    {
        // Handle error
        NSLog(@"BLEPeripheral Discovered Characteristics for Service %@ Error \n%@", service.UUID, error);
    }
    
    if ( bleService )
    {
        [bleService loadDiscoveredCharacteristics];
    }
    else
    {
        // Why isn't there already a service?
    }
       
#if CENTRAL_USE_DISPATCH_QUEUE
   });
#endif
}

-(void) peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
#if CENTRAL_USE_DISPATCH_QUEUE
   dispatch_async(dispatch_get_main_queue(), ^{
#endif
       
    if ( peripheral != _peripheral )
    {
        return;
    }
    
    CharacteristicProxy* proxyChar = [self _findProxyForCharacteristic:characteristic];
    
    if ( proxyChar )
    {
        [proxyChar valueUpdatedWithError:error];
    }
    
#if DEBUG
    //NSLog(@"didUpdateValueForCharacteristic %@", characteristic.UUID);
#endif
       
#if CENTRAL_USE_DISPATCH_QUEUE
   });
#endif
}

-(void) peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(NSError *)error
{
#if CENTRAL_USE_DISPATCH_QUEUE
   dispatch_async(dispatch_get_main_queue(), ^{
#endif
       
    if ( peripheral == _peripheral )
    {
        [self RSSIUpdated];
    }

#if CENTRAL_USE_DISPATCH_QUEUE
   });
#endif
}

-(void) peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
#if CENTRAL_USE_DISPATCH_QUEUE
    dispatch_async(dispatch_get_main_queue(), ^{
#endif
        
#if DEBUG
    NSLog(@"didWriteValueForCharacteristic %@", characteristic.UUID);
#endif
    
    if ( _peripheral != peripheral )
    {
        return;
    }
    
    if ( error )
    {
        NSLog(@"Write Error for Characteristic %@\n %@", characteristic.UUID, error);
    }
    
    CharacteristicProxy* proxyChar = [self _findProxyForCharacteristic:characteristic];
    
    if ( proxyChar )
    {
        [proxyChar writeCompletedWithError:error];
    }
        
#if CENTRAL_USE_DISPATCH_QUEUE
   });
#endif
    
}



@end
