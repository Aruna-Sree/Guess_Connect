//
//  BLECharacteristic.m
//  HeartRateMonitor
//
//  Created by Michael Nannini on 1/16/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

#import "BLECharacteristic.h"

@implementation BLECharacteristic

@synthesize cbCharacteristic=_characteristic;

-(id) initWithCharacteristic:(CBCharacteristic *)characteristic
{
    self = [super init];
    
    if ( self )
    {
        _characteristic = characteristic;
    }
    
    return self;
}

-(CBUUID*) UUID
{
    return _characteristic.UUID;
}

-(NSData*) value
{
    return _characteristic.value;
}

-(NSUInteger) properties
{
    if ( _characteristic )
        return _characteristic.properties;
    
    return 0;
}

-(void) setService:(ServiceProxy *)service
{
    _service = service;
}

-(void) updateValue:(CharacteristicValueUpdateCompleteBlock)completionBlock
{
    if ( _characteristic.properties & CBCharacteristicPropertyRead )
    {
        [super updateValue:completionBlock];
        
        [_characteristic.service.peripheral readValueForCharacteristic:_characteristic];
    }
}

-(void) updateValueWithError:(CharacteristicValueUpdateCompleteWithErrorBlock)completionBlock
{
    if ( _characteristic.properties & CBCharacteristicPropertyRead )
    {
        [super updateValueWithError:completionBlock];
        
        [_characteristic.service.peripheral readValueForCharacteristic:_characteristic];
    }
    
}

-(void) updateValue:(SEL)completion target:(id<NSObject>)completionTarget
{
    if ( _characteristic.properties & CBCharacteristicPropertyRead )
    {
        [super updateValue:completion target:completionTarget];
        
        [_characteristic.service.peripheral readValueForCharacteristic:_characteristic];
    }
    
}

-(void) enableNotification:(BOOL)enable
{
    if ( _characteristic.properties & CBCharacteristicPropertyNotify )
    {
        [_characteristic.service.peripheral setNotifyValue:enable forCharacteristic:_characteristic];
    }
}

-(void) writeValue:(NSData*)newValue response:(SEL)selector target:(id<NSObject>)target
{
    if ( _characteristic.properties & ( CBCharacteristicPropertyWrite | CBCharacteristicPropertyWriteWithoutResponse ) )
    {
        
        CBCharacteristicWriteType writeType = CBCharacteristicWriteWithResponse;
        
        if ( target && selector )
        {
            if ( _characteristic.properties & CBCharacteristicPropertyWrite )
            {
                writeType = CBCharacteristicWriteWithResponse;
            }
            else
            {
                writeType = CBCharacteristicWriteWithoutResponse;
                selector = nil;
                target = nil;
            }
        }
        else if ( _characteristic.properties & CBCharacteristicPropertyWriteWithoutResponse )
        {
            writeType = CBCharacteristicWriteWithoutResponse;
            target = nil;
            selector = nil;
        }
        
        [super writeValue:newValue response:selector target:target];
        
        [_characteristic.service.peripheral writeValue:newValue forCharacteristic:_characteristic type:writeType];
    }
}

-(void) writeValue:(NSData*)newValue responseBlock:(CharacteristicValueWriteCompleteBlock)responseBlock
{
    if ( _characteristic.properties & ( CBCharacteristicPropertyWrite | CBCharacteristicPropertyWriteWithoutResponse ) )
    {
        CBCharacteristicWriteType writeType = CBCharacteristicWriteWithResponse;
        
        if ( responseBlock )
        {
            if ( _characteristic.properties & CBCharacteristicPropertyWrite )
            {
                writeType = CBCharacteristicWriteWithResponse;
            }
            else
            {
                writeType = CBCharacteristicWriteWithoutResponse;
                responseBlock = nil;
            }
        }
        else if ( _characteristic.properties & CBCharacteristicPropertyWriteWithoutResponse )
        {
            writeType = CBCharacteristicWriteWithoutResponse;
            responseBlock = nil;
        }
        
        
        [super writeValue:newValue responseBlock:responseBlock];
        
        
        [_characteristic.service.peripheral writeValue:newValue forCharacteristic:_characteristic type:writeType];
        
    }
    
}

-(void) writeValue:(NSData*)newValue responseWithErrorBlock:(CharacteristicValueWriteCompleteWithErrorBlock)responseBlock
{
    if ( _characteristic.properties & ( CBCharacteristicPropertyWrite | CBCharacteristicPropertyWriteWithoutResponse ) )
    {
        CBCharacteristicWriteType writeType = CBCharacteristicWriteWithResponse;
        
        if ( responseBlock )
        {
            if ( _characteristic.properties & CBCharacteristicPropertyWrite )
            {
                writeType = CBCharacteristicWriteWithResponse;
            }
            else
            {
                writeType = CBCharacteristicWriteWithoutResponse;
                responseBlock = nil;
            }
        }
        else if ( _characteristic.properties & CBCharacteristicPropertyWriteWithoutResponse )
        {
            writeType = CBCharacteristicWriteWithoutResponse;
            responseBlock = nil;
        }
        
        
        [super writeValue:newValue responseWithErrorBlock:responseBlock];
        
        
        [_characteristic.service.peripheral writeValue:newValue forCharacteristic:_characteristic type:writeType];
        
    }
}


@end
