//
//  BatteryService.m
//  Wahooo
//
//  Created by Michael Nannini on 2/5/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

#import "BatteryService.h"

#import "CharacteristicProxy.h"

#import "PeripheralUtility.h"

static CBUUID* s_batteryLevelID = nil;

static CBUUID* s_batteryServiceID = nil;

@interface BatteryService ()
{
    NSInteger                   _batteryLevel;
    __weak PeripheralProxy*     _peripheral;
    __weak CharacteristicProxy* _batteryLevelCharacteristic;
    BOOL                        _batteryLevelNotify;
}

-(void) _loadCharacteristics;

-(void) _foundCharacteristic:(CharacteristicProxy*)characteristic;

-(void) _updatedBatteryLevel:(CharacteristicProxy*)characteristic;

@end

@implementation BatteryService

@synthesize delegate=_delegate;

@synthesize batteryLevel=_batteryLevel;

+(CBUUID*) batteryServiceID
{
    if ( s_batteryServiceID == nil )
    {
        s_batteryServiceID = [CBUUID UUIDWithString:@"180F"];
    }
    
    return s_batteryServiceID;
}

+(CBUUID*) batteryLevelID
{
    if ( s_batteryLevelID == nil )
    {
        s_batteryLevelID = [CBUUID UUIDWithString:@"2A19"];
    }
    
    return s_batteryLevelID;
}


-(void) setPeripheral:(PeripheralProxy*)peripheral
{
    _peripheral = peripheral;
    _batteryLevelCharacteristic = nil;
    
    [self _loadCharacteristics];
}

-(void) readBatteryLevel
{
    if ( _batteryLevelCharacteristic )
    {
        [_batteryLevelCharacteristic updateValue:nil target:nil];
    }
}

-(void) enableBatterLevelNotify:(BOOL)enable
{
    _batteryLevelNotify = enable;
    
    if ( _batteryLevelCharacteristic )
    {
        [_batteryLevelCharacteristic enableNotification:enable];
    }
}


-(void) _loadCharacteristics
{
    if ( _peripheral )
    {
        //MRN: For now assume the service has already been loaded
        ServiceProxy* service = [_peripheral findService:[BatteryService batteryServiceID]];
        
        if ( service )
        {
            NSArray* charIds = @[[BatteryService batteryLevelID] ];
            
            [PeripheralUtility loadCharacteristics:charIds fromService:service foundSelector:@selector(_foundCharacteristic:) target:self];
        }
        else
        {
            NSLog(@"BatteryService:: Peripheral does not contain the Battery Service");
        }
    }
}

-(void) _foundCharacteristic:(CharacteristicProxy*)characteristic
{
    if ([characteristic.UUID isEqual:[BatteryService batteryLevelID]])
    {
        _batteryLevelCharacteristic = characteristic;
        
        [_batteryLevelCharacteristic removeValueObserver:self forSelector:nil];
        [_batteryLevelCharacteristic addValueObserver:self withSelector:@selector(_updatedBatteryLevel:)];
        
        [_batteryLevelCharacteristic enableNotification:_batteryLevelNotify];
        
        [self readBatteryLevel];
    }
}

-(void) _updatedBatteryLevel:(CharacteristicProxy*)characteristic
{
    const uint8_t* bytes = characteristic.value.bytes;
    
    if ( bytes )
    {
        _batteryLevel = (NSInteger)bytes[0];
        
        if ( _delegate && [_delegate respondsToSelector:@selector(batteryService:batteryLevelUpdated:)])
        {
            [_delegate batteryService:self batteryLevelUpdated:_batteryLevel];
        }
        
    }
}


@end
