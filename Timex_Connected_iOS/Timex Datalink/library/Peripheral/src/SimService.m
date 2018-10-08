//
//  SimService.m
//  Wahooo
//
//  Created by Michael Nannini on 1/28/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

#import "SimService.h"
#import "SimCharacteristic.h"

@interface SimService ()
{
    CBUUID* _uuid;
}
@end

@implementation SimService

-(CBUUID*) UUID
{
    return _uuid;
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

-(void) setPeripheral:(PeripheralProxy*)peripheral
{
    _peripheral = peripheral;
}


-(void) addCharacteristic:(SimCharacteristic*)characteristic
{
    characteristic.service = self;
    
    [_characteristics setObject:characteristic forKey:characteristic.UUID];
}

-(void) loadCharacteristics:(NSArray *)characteristicIds foundSelector:(SEL)selector target:(id<NSObject>)target
{
    [super loadCharacteristics:characteristicIds foundSelector:selector target:target];
    
    NSArray* characteristics = [_characteristics allValues];
    
    for( CharacteristicProxy* characteristic in characteristics )
    {
        if ( characteristic )
        {
            for( CBUUID* charId in characteristicIds )
            {
                if ( [charId isEqual:characteristic.UUID] )
                {
                    [self foundCharacteristic:characteristic];
                }
            }
        }
    }
}

-(void) loadCharacteristics:(NSArray *)characteristicIds foundBlock:(FoundCharacteristicBlock)block
{
    [super loadCharacteristics:characteristicIds foundBlock:block];
    
    NSArray* characteristics = [_characteristics allValues];
    
    for( CharacteristicProxy* characteristic in characteristics )
    {
        if ( characteristic )
        {
            
            for( CBUUID* charId in characteristicIds )
            {
                if ( [charId isEqual:characteristic.UUID] )
                {
                    [self foundCharacteristic:characteristic];
                }
            }
        }
    }

}


@end
