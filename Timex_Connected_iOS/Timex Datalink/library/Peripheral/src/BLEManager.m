//
//  BLEManager.m
//  HeartRateMonitor
//
//  Created by Michael Nannini on 1/17/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

#import "BLEManager.h"
#import "BLEPeripheral.h"
#import "BLEService.h"
#import "PeripheralUtility.h"
#import "CBPeripheral+CBUUID.h"
#import <UIKit/UIKit.h>


NSString* const kBLEManagerDiscoveredPeripheralNotification = @"kBLEManagerDiscoveredPeripheralNotification";
NSString* const kBLEManagerUndiscoveredPeripheralNotification = @"kBLEManagerUndiscoveredPeripheralNotification";
NSString* const kBLEManagerConnectedPeripheralNotification = @"kBLEManagerConnectedPeripheralNotification";
NSString* const kBLEManagerDisconnectedPeripheralNotification = @"kBLEManagerDisconnectedPeripheralNotification";
NSString* const kBLEManagerPeripheralConnectionFailedNotification = @"kBLEManagerPeripheralConnectionFailedNotification";
NSString* const kBLEManagerRestoredConnectedPeripheralNotification = @"kBLEManagerRestoredConnectedPeripheralNotification";
NSString* const kBLEManagerManagerKey = @"kBLEManagerManagerKey";
NSString* const kBLEManagerPeripheralKey = @"kBLEManagerPeripheralKey";
NSString* const kBLEManagerAdvertisementDataKey = @"kBLEManagerAdvertisementDataKey";
NSString* const kBLEManagerStateChanged = @"kBLEManagerStateChanged";

// MRN: category in CBCentralManager for iOS 9+ for methods that were removed
@interface CBCentralManager (BLEManager)

-(void) retrieveConnectedPeripherals;

-(void) retrievePeripherals:(NSArray*)identifiers;

@end


static NSComparator _sortComparePeripheralName = ^(id obj1, id obj2)
{

    BLEPeripheral* p1 = (BLEPeripheral*)obj1;
    BLEPeripheral* p2 = (BLEPeripheral*)obj2;
    
    return [p1.name compare:p2.name];
    
};

@interface BLEManager () <CBCentralManagerDelegate>
{
    CBCentralManager*   _cbManager;
    NSMutableDictionary*    _connectedPeripherals;
    NSMutableDictionary*    _advertisingPeripherals;
    NSMutableDictionary*    _unknownPeripherals;
    NSMutableDictionary*    _allPeripherals;
    NSMutableArray*         _restoredPeripherals;
    FilterPeripheralProxy   _retrieveConnectedFilter;
    FilterPeripheralProxy   _retrieveKnownFilter;
    
    NSArray*                _scanningServices;
}

-(void) _fireNotification:(NSString*)name withPeripheral:(BLEPeripheral*)peripheral;

-(NSArray*) _findDiscoveredPeripherals:(NSMutableDictionary*)peripherals olderThan:(NSTimeInterval)duration;


@end

@implementation BLEManager


-(id) init
{
    return [self initWithRestorationId:nil];
}

-(id) initWithRestorationId:(NSString*)restorationId
{
    self = [super init];
    
    if ( self )
    {
        _connectedPeripherals = [[NSMutableDictionary alloc] init];
        _advertisingPeripherals = [[NSMutableDictionary alloc] init];
        _unknownPeripherals = [[NSMutableDictionary alloc] init];
        _allPeripherals = [[NSMutableDictionary alloc] init];
        _scanningServices = nil;
        _restoredPeripherals = [[NSMutableArray alloc] init];
        
        dispatch_queue_t queue = nil;
        
#if CENTRAL_USE_DISPATCH_QUEUE
        queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
#endif
        
        _cbManager = [CBCentralManager alloc];
        
        if ( [_cbManager respondsToSelector:@selector(initWithDelegate:queue:options:)] )
        {
            NSMutableDictionary* options = [[NSMutableDictionary alloc] init];
            
            if ( restorationId )
            {
                [options setObject:restorationId forKey:CBCentralManagerOptionRestoreIdentifierKey];
            }

            _cbManager = [_cbManager initWithDelegate:self queue:queue options:options];
        }
        else
        {
            _cbManager = [_cbManager initWithDelegate:self queue:queue];
        }
    }
    
    return self;
}

-(void) scanForPeripheralsWithServices:(NSArray*)serviceUUIDs allowDupes:(BOOL)allow
{
    NSNumber* dupes =[NSNumber numberWithBool:allow];
    NSDictionary* options = [NSDictionary dictionaryWithObject:dupes forKey:CBCentralManagerScanOptionAllowDuplicatesKey];
 
    _scanningServices = nil;
    
    if ( serviceUUIDs )
    {
        _scanningServices = [serviceUUIDs copy];
    }
    
    //Clear out advertising list and repopulate
    [_advertisingPeripherals removeAllObjects];
    [_unknownPeripherals removeAllObjects];
    [_allPeripherals removeAllObjects];
    
    if( [self isBLEAvailable] )
    {
        [_cbManager scanForPeripheralsWithServices:serviceUUIDs options:options];
    }
}

-(void) stopScan
{
    if( [self isBLEAvailable] )
    {
        [_cbManager stopScan];
    }
}

-(void) retrieveConnectedPeripherals:(FilterPeripheral)filterBlock
{
    //Don't use me
    NSLog(@"BLEManager::retrieveConnectedPeripherals is depricated and does nothing!  Use retrieveConnectedPeripheralProxies instead");
}

//TODO: The CBCentralManager method retrieveConnectedPeripherals is depricated in iOS 7
//      Need to pass an array of Service Ids to use
-(void) retrieveConnectedPeripheralProxies:(FilterPeripheralProxy)filterBlock
{
    _retrieveConnectedFilter = filterBlock;
    
    if( [self isBLEAvailable] )
    {
        NSArray* serviceIds = _scanningServices;
        
        if ( serviceIds == nil )
            serviceIds = [NSArray array];
        
        
        // By default pass in the services being scanned for
        // Use retrieveConnectedPeripheralProxies: withServiceIds: to specify other services
        [self retrieveConnectedPeripheralProxies:filterBlock withServiceIds:serviceIds];
        
    }
}

-(void) retrieveConnectedPeripheralProxies:(FilterPeripheralProxy)filterBlock withServiceIds:(NSArray*)serviceIds
{
    if ( serviceIds == nil )
    {
        NSLog(@"BLEManager::retrieveConnectedPeripheralProxies: withServiceIds: serviceIds cannot be nil");
        return;
    }
    
    _retrieveConnectedFilter = filterBlock;
    
    if ( [_cbManager respondsToSelector:@selector(retrieveConnectedPeripheralsWithServices:)] )
    {
        NSArray* array = [_cbManager retrieveConnectedPeripheralsWithServices:serviceIds];
        
        if ( array )
        {
            [self centralManager:_cbManager didRetrieveConnectedPeripherals:array];
        }
    }
    else if ( [_cbManager respondsToSelector:@selector(retrieveConnectedPeripherals)] )
    {
        [_cbManager retrieveConnectedPeripherals];
    }
    
}


-(void) retrieveKnownPeripheralProxies:(FilterPeripheralProxy)filterBlock withIds:(NSArray*)uuids
{
    _retrieveKnownFilter = filterBlock;
    
    if ( [self isBLEAvailable] )
    {
        NSMutableArray* convertedIds = [[NSMutableArray alloc] init];
        
        BOOL ios7up = [_cbManager respondsToSelector:@selector(retrievePeripheralsWithIdentifiers:)];

        for( CBUUID* cbuuid in uuids )
        {
            NSString* uuidString = [PeripheralUtility cbuuidToString:cbuuid];
            
            if ( ios7up )
            {
                [convertedIds addObject:[[NSUUID alloc] initWithUUIDString:uuidString]];
            }
            else
            {
                CFUUIDRef converted = CFUUIDCreateFromString(nil, (__bridge CFStringRef)uuidString);
                
                [convertedIds addObject:(__bridge_transfer id)converted];
                
                CFRelease(converted);
                
            }
            
        }
        
        if ( ios7up )
        {
            NSArray* peripherals = [_cbManager retrievePeripheralsWithIdentifiers:convertedIds];
            
            [self centralManager:_cbManager didRetrievePeripherals:peripherals];
        }
        else if ( [_cbManager respondsToSelector:@selector(retrievePeripherals:)] )
        {
            [_cbManager retrievePeripherals:convertedIds];
        }
        
    }
}

-(void) connectPeripheral:(PeripheralProxy *)peripheral
{
    if ( [peripheral isKindOfClass:[BLEPeripheral class]] )
    {
        BLEPeripheral* blePeripheral = (BLEPeripheral*)peripheral;
        
        if ( peripheral.UUID )
        {
            [_advertisingPeripherals removeObjectForKey:peripheral.UUID];
        }
        
        NSDictionary* options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:CBConnectPeripheralOptionNotifyOnDisconnectionKey];
        
        if( [self isBLEAvailable] )
        {
            [_cbManager connectPeripheral:blePeripheral.cbPeripheral options:options];
        }

    }
}

-(void) disconnectPeripheral:(PeripheralProxy*)peripheral
{
    if ( [peripheral isKindOfClass:[BLEPeripheral class]] )
    {
        //TODO: Add pending disconnect peripherals dictionary
        BLEPeripheral* blePeripheral = (BLEPeripheral*)peripheral;
        
        [blePeripheral disconnect];
        
        if( [self isBLEAvailable] )
        {
            [_cbManager cancelPeripheralConnection:blePeripheral.cbPeripheral];
        }
#if DEBUG
        NSLog(@"BLEManager::disconnectPeripheral");
#endif
    }
}

-(BOOL) isBLESupported
{
    switch (_cbManager.state)
    {
        case CBCentralManagerStatePoweredOff:
        case CBCentralManagerStatePoweredOn:
        case CBCentralManagerStateResetting:
            return YES;
        case CBCentralManagerStateUnauthorized:
        case CBCentralManagerStateUnknown:
        case CBCentralManagerStateUnsupported:
            break;
    }
    return NO;
}

-(BOOL) isBLEAvailable
{
    if ( _cbManager.state == CBCentralManagerStatePoweredOn )
        return YES;
        
    return NO;
}

-(void) purgeAdvertisingDevices:(NSTimeInterval)duration
{
    NSArray *oldAdvertising = [self _findDiscoveredPeripherals:_advertisingPeripherals olderThan:duration];
    NSArray* oldUnknown = [self _findDiscoveredPeripherals:_unknownPeripherals olderThan:duration];
    
    if ( oldAdvertising.count > 0 )
    {
        for( BLEPeripheral* peripheral in oldAdvertising )
        {
            [_advertisingPeripherals removeObjectForKey:peripheral.UUID];
            
            [self _fireNotification:kBLEManagerUndiscoveredPeripheralNotification withPeripheral:peripheral];
        }
    }
    
    if ( oldUnknown.count > 0 )
    {
        for( BLEPeripheral* peripheral in oldUnknown )
        {
            [_unknownPeripherals removeObjectForKey:[peripheral unknownKey]];
            
            [self _fireNotification:kBLEManagerUndiscoveredPeripheralNotification withPeripheral:peripheral];
        }
        
    }
}



-(NSArray*) getAdvertisingPeripherals
{
    NSMutableArray* peripherals = [NSMutableArray arrayWithArray:[_advertisingPeripherals allValues]];
    [peripherals addObjectsFromArray:[_unknownPeripherals allValues]];
    
    return peripherals;
}

-(NSArray*) getConnectedPeripherals
{
    return [_connectedPeripherals allValues];
}

-(void) _fireNotification:(NSString*)name withPeripheral:(BLEPeripheral*)peripheral
{
    NSMutableDictionary* userInfo = [[NSMutableDictionary alloc] init];

    if ( peripheral )
    {
        [userInfo setValue:peripheral forKey:kBLEManagerPeripheralKey];
    }
    
    [userInfo setValue:self forKey:kBLEManagerManagerKey];

    [[NSNotificationCenter defaultCenter] postNotificationName:name object:self userInfo:userInfo];
}

-(NSArray*) _findDiscoveredPeripherals:(NSMutableDictionary*)peripherals olderThan:(NSTimeInterval)duration
{
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    NSArray* tempArray = [peripherals allValues];
    NSMutableArray* result = [[NSMutableArray alloc] init];
    
    for( BLEPeripheral* peripheral in tempArray )
    {
        NSTimeInterval timeSinceDiscovery = now - peripheral.discoveredTime;
        
        if ( timeSinceDiscovery > duration )
        {
            [result addObject:peripheral];
        }
    }
    
    return result;
}

#pragma mark - CBCentralManagerDelegate

-(void) centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
#if CENTRAL_USE_DISPATCH_QUEUE
    dispatch_async(dispatch_get_main_queue(), ^{
#endif
    
#if DEBUG
    if ( peripheral.CBUUID == nil )
    {
        //MRN: I don't think this should ever happen
        NSLog(@"Why is CBUUID nil!?");
        
    }
#endif
    
    CBUUID* uuid = peripheral.CBUUID;
    
    BLEPeripheral* blePeripheral = [_allPeripherals objectForKey:uuid];
    
    
    [_advertisingPeripherals removeObjectForKey:uuid];
    
    if ( blePeripheral == nil )
    {

        blePeripheral = [_unknownPeripherals objectForKey:[BLEPeripheral unknownKey:peripheral]];
        
        if ( blePeripheral )
        {
            [_allPeripherals setObject:blePeripheral forKey:uuid];
            
            [_unknownPeripherals removeObjectForKey:blePeripheral.unknownKey];
        }
    }
    
    if ( blePeripheral == nil )
    {
        blePeripheral = [[BLEPeripheral alloc] initWithPeripheral:peripheral];
        
        [_allPeripherals setObject:blePeripheral forKey:uuid];

    }
    else if ( blePeripheral.cbPeripheral != peripheral )
    {
#if DEBUG
        NSLog(@"BLEManager: Connected peripheral instance doesn't match CBPeripheral instance?!");
#endif
    }
    else
    {
#if DEBUG
        NSLog(@"BLEManager: Connected peripheral contains %lu services", (unsigned long)peripheral.services.count);
#endif
    }
    
    if ( blePeripheral.cbPeripheral.delegate != blePeripheral )
    {
#if DEBUG
        NSLog(@"BLE Peripheral Delegate is not set!  %@", blePeripheral.cbPeripheral.delegate);
#endif
    }
    
    [_unknownPeripherals removeObjectForKey:[blePeripheral unknownKey]];
    
    [_connectedPeripherals setObject:blePeripheral forKey:uuid];
    
    [self _fireNotification:kBLEManagerConnectedPeripheralNotification withPeripheral:blePeripheral];
        
#if CENTRAL_USE_DISPATCH_QUEUE
    });
#endif

}


-(void) centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
#if CENTRAL_USE_DISPATCH_QUEUE
    dispatch_async(dispatch_get_main_queue(), ^{
#endif
        
    if ( peripheral.CBUUID )
    {
        CBUUID* uuid = peripheral.CBUUID;
        
        BLEPeripheral* blePeripheral = [_allPeripherals objectForKey:uuid];
        
        if ( blePeripheral == nil )
        {
#if DEBUG
            NSLog(@"Disconnected a peripheral that isn't in our list");
#endif
        }
        else
        {
            [blePeripheral disconnect];
        }
#if DEBUG
        NSLog(@"Disconnect Peripheral %@", peripheral.CBUUID);
#endif
        if ( [_connectedPeripherals objectForKey:uuid] == blePeripheral )
        {
            //If already in local connected list, connect
            if( !blePeripheral.isConnected )
            {
                [self connectPeripheral:blePeripheral];
            }
        }
        [_connectedPeripherals removeObjectForKey:uuid];

        [self _fireNotification:kBLEManagerDisconnectedPeripheralNotification withPeripheral:blePeripheral];
    }
#if CENTRAL_USE_DISPATCH_QUEUE
    });
#endif
    
}

-(void) centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
#if CENTRAL_USE_DISPATCH_QUEUE
    dispatch_async(dispatch_get_main_queue(), ^{
#endif
        
    BLEPeripheral* blePeripheral = nil;

    NSNumber* connectable = nil;
        
    if ( &CBAdvertisementDataIsConnectable )
    {
        connectable = [advertisementData objectForKey:CBAdvertisementDataIsConnectable];
    }
        
    if ( connectable && ![connectable boolValue] )
    {
        // CBUUID won't be nil because the connectable key only exists in iOS 7+
        blePeripheral= [_advertisingPeripherals objectForKey:peripheral.CBUUID];
        
        [_advertisingPeripherals removeObjectForKey:peripheral.CBUUID];
        
        if ( blePeripheral )
        {
            [self _fireNotification:kBLEManagerUndiscoveredPeripheralNotification withPeripheral:blePeripheral];
        }

        return;
    }
    
    if ( peripheral.CBUUID == nil)
    {
        blePeripheral = [_unknownPeripherals objectForKey:[BLEPeripheral unknownKey:peripheral]];
        
        if ( blePeripheral == nil )
        {
            blePeripheral = [[BLEPeripheral alloc] initWithPeripheral:peripheral];
            
            [_unknownPeripherals setObject:blePeripheral forKey:[blePeripheral unknownKey]];
        }
    }
    else
    {
        CBUUID* uuid = peripheral.CBUUID;
        
        
        //TODO:: Need to change this so peripherals can be connected AND advertising at the same time
        blePeripheral = [_allPeripherals objectForKey:uuid];

        //[_connectedPeripherals removeObjectForKey:uuid];
        
        if ( blePeripheral == nil || blePeripheral.cbPeripheral != peripheral )
        {
            blePeripheral = [[BLEPeripheral alloc] initWithPeripheral:peripheral];
            
            [_allPeripherals setObject:blePeripheral forKey:uuid];
#if DEBUG
            NSLog(@"Discovered Peripheral %@", uuid );
            
            NSLog(@"Peripheral Not in List yet");
#endif
        }
        else if ( blePeripheral.cbPeripheral != peripheral )
        {
#if DEBUG
            NSLog(@"BLEManager: discovered peripheral doesn't match existing instance!");
#endif
        }
        
        [_advertisingPeripherals setObject:blePeripheral forKey:uuid];
    }
    
    [blePeripheral setDiscoveredTime:[[NSDate date] timeIntervalSince1970]];
        
    NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:blePeripheral, kBLEManagerPeripheralKey, advertisementData, kBLEManagerAdvertisementDataKey, self, kBLEManagerManagerKey, nil];
        
    [[NSNotificationCenter defaultCenter] postNotificationName:kBLEManagerDiscoveredPeripheralNotification object:self userInfo:userInfo];
    
#if CENTRAL_USE_DISPATCH_QUEUE
    });
#endif

}

-(void) centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
#if CENTRAL_USE_DISPATCH_QUEUE
    dispatch_async(dispatch_get_main_queue(), ^{
#endif
    BLEPeripheral* blePeripheral = nil;
    
    if ( peripheral.CBUUID != nil )
    {
        CBUUID* uuid = peripheral.CBUUID;
        
        blePeripheral = [_allPeripherals objectForKey:uuid];
    }
    
    if( blePeripheral == nil )
    {
        blePeripheral = [_unknownPeripherals objectForKey:[BLEPeripheral unknownKey:peripheral]];
    }
    
    
    // If we found the peripheral in our list, send notification
    if ( blePeripheral )
    {
#if DEBUG
        NSLog(@"BLEManager: Failed to connect peripheral");
#endif
      
        [self _fireNotification:kBLEManagerPeripheralConnectionFailedNotification withPeripheral:blePeripheral];

    }
#if CENTRAL_USE_DISPATCH_QUEUE
    });
#endif
}

-(void) centralManager:(CBCentralManager *)central didRetrieveConnectedPeripherals:(NSArray *)peripherals
{
#if CENTRAL_USE_DISPATCH_QUEUE
    dispatch_async(dispatch_get_main_queue(), ^{
#endif
    for( CBPeripheral* peripheral in peripherals )
    {
     
        //MRN: Don't think this should happen
        if ( peripheral.CBUUID == nil )
        {
            continue;
        }
        
        CBUUID* uuid = peripheral.CBUUID;
        
        BLEPeripheral* blePeripheral = [_allPeripherals objectForKey:uuid];
        
        if ( blePeripheral == nil )
        {
            NSString* key = [BLEPeripheral unknownKey:peripheral];
            
            blePeripheral = [_unknownPeripherals objectForKey:key];
            
            if ( blePeripheral != nil )
            {
                [_allPeripherals setObject:blePeripheral forKey:blePeripheral.UUID];
                
                [_unknownPeripherals removeObjectForKey:key];
            }
        }
        
        if( blePeripheral == nil )
        {
            blePeripheral = [[BLEPeripheral alloc] initWithPeripheral:peripheral];
            
            [_allPeripherals setObject:blePeripheral forKey:uuid];
        }
        else if ( [_advertisingPeripherals objectForKey:uuid] == blePeripheral )
        {
//            continue;
        }
        else if ( [_connectedPeripherals objectForKey:uuid] == blePeripheral )
        {
            //If already in local connected list, connect
            if( !blePeripheral.isConnected )
            {
                [self connectPeripheral:blePeripheral];
            }
            continue;
        }
        
        if( _retrieveConnectedFilter == nil || _retrieveConnectedFilter(blePeripheral) )
        {
            // MRN: the filter should handle what to do with the peripheral that is not in the advertising
        }
        
    }
#if CENTRAL_USE_DISPATCH_QUEUE
    });
#endif
}


-(void) centralManager:(CBCentralManager *)central didRetrievePeripherals:(NSArray *)peripherals
{
#if CENTRAL_USE_DISPATCH_QUEUE
    dispatch_async(dispatch_get_main_queue(), ^{
#endif
        
    for( CBPeripheral* peripheral in peripherals )
    {
        if ( peripheral.CBUUID == nil)
            continue;
        
        CBUUID* uuid = peripheral.CBUUID;
        
        BLEPeripheral* blePeripheral = [_allPeripherals objectForKey:uuid];
        
        if( blePeripheral == nil )
        {
            blePeripheral = [[BLEPeripheral alloc] initWithPeripheral:peripheral];
            
            [_allPeripherals setObject:blePeripheral forKey:uuid];
        }
        
        if( _retrieveKnownFilter )
        {
            // MRN: the filter should handle what to do with the peripheral that is not in the advertising
         
            _retrieveKnownFilter(blePeripheral);
         
        }
        
    }

#if CENTRAL_USE_DISPATCH_QUEUE
    });
#endif
}

-(void) centralManagerDidUpdateState:(CBCentralManager *)central
{
#if CENTRAL_USE_DISPATCH_QUEUE
    dispatch_async(dispatch_get_main_queue(), ^{
#endif
    
    if ( central.state != CBCentralManagerStatePoweredOn )
    {
        if ( _connectedPeripherals.count > 0 )
        {
            NSArray* connected = _connectedPeripherals.allValues;
            
            for( BLEPeripheral* peripheral in connected )
            {
                [central cancelPeripheralConnection:peripheral.cbPeripheral];
                [peripheral disconnect];
                [self _fireNotification:kBLEManagerDisconnectedPeripheralNotification withPeripheral:peripheral];
            }
        }
        
        if ( _advertisingPeripherals.count > 0 )
        {
            NSArray* advertising = _advertisingPeripherals.allValues;
            
            for( BLEPeripheral* peripheral in advertising )
            {
                [self _fireNotification:kBLEManagerUndiscoveredPeripheralNotification withPeripheral:peripheral];
            }
        }
        
        [_connectedPeripherals removeAllObjects];
        [_advertisingPeripherals removeAllObjects];
    }

    if ( central.state == CBCentralManagerStatePoweredOn )
    {
        if ( _restoredPeripherals.count > 0 )
        {
            
            for( BLEPeripheral* peripheral in _restoredPeripherals )
            {
                [_connectedPeripherals setObject:peripheral forKey:peripheral.UUID];
                [self _fireNotification:kBLEManagerRestoredConnectedPeripheralNotification withPeripheral:peripheral];
            }
            
            [_restoredPeripherals removeAllObjects];
        }
    }

    [self _fireNotification:kBLEManagerStateChanged withPeripheral:nil];
        
#if CENTRAL_USE_DISPATCH_QUEUE
    });
#endif

}

-(void) centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary *)dict
{
#if CENTRAL_USE_DISPATCH_QUEUE
    dispatch_async(dispatch_get_main_queue(), ^{
#endif
    
    NSArray* peripherals = [dict objectForKey:CBCentralManagerRestoredStatePeripheralsKey];
    
#if DEBUG
    NSLog(@"Restore Central Manager");
#endif
    
    if ( peripherals )
    {
        for( CBPeripheral* peripheral in peripherals )
        {
            BLEPeripheral* blePeripheral = [_allPeripherals objectForKey:peripheral.CBUUID];
            
            if ( blePeripheral == nil )
            {
                blePeripheral = [[BLEPeripheral alloc] initWithPeripheral:peripheral];
                
                [_allPeripherals setObject:blePeripheral forKey:peripheral.CBUUID];
            }
         
            if ( [peripheral respondsToSelector:@selector(state)] )
            {
                switch( peripheral.state )
                {
                    case CBPeripheralStateConnected:

                        [_restoredPeripherals addObject:blePeripheral];

                    #if DEBUG
                        NSLog(@"Restored Peripheral %@ Connected", peripheral.CBUUID);
                    #endif
                        break;
                        
                    case CBPeripheralStateConnecting:
                    #if DEBUG
                        NSLog(@"Restored Peripheral %@ Connecting", peripheral.CBUUID);
                    #endif
                        break;
                        
                    case CBPeripheralStateDisconnected:
                    #if DEBUG
                        NSLog(@"Restored Peripheral %@ Disconnected", peripheral.CBUUID);
                    #endif
                        break;
                        
                    case CBPeripheralStateDisconnecting:
                    #if DEBUG
                        NSLog(@"Restored Peripheral %@ Disconnecting", peripheral.CBUUID);
                    #endif
                        break;

                }
            }
            
        }
    }

#if CENTRAL_USE_DISPATCH_QUEUE
    });
#endif
}

@end
