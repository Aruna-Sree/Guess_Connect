//
//  ProfileObject.m
//  MillMonitoringSystem
//
//  Created by Michael Nannini on 3/26/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

#import "ProfileObject.h"
#import "PeripheralProxy.h"
#import "ServiceProxy.h"
#import "CharacteristicProxy.h"
#import "ProfileData.h"


@interface ProfileObject ()
{
    ProfileData*   _profileData;
    PeripheralProxy* __weak _peripheral;
    id<ProfileObjectDelegate> __weak _delegate;
    
}



-(void) _discoverServices;

-(void) _didDiscoverService:(ServiceProxy*)service;

-(void) _discoverCharacteristicsForService:(CBUUID*)serviceId;

-(void) _didDiscoverCharacteristic:(CharacteristicProxy*)characteristic;

@end

@implementation ProfileObject



@synthesize delegate=_delegate;

@synthesize profileData=_profileData;


-(void) _discoverServices
{
    if ( _peripheral && _profileData )
    {
        NSArray* serviceIds = [_profileData serviceIds];
        NSMutableArray* loadServiceIds = [[NSMutableArray alloc] init];
        
        for(CBUUID* uuid in serviceIds)
        {
            ServiceProxy* service = [_peripheral findService:uuid];
            
            if ( service == nil )
            {
                [loadServiceIds addObject:uuid];
            }
            else
            {
                [self _didDiscoverService:service];
            }
        }
        
        if ( loadServiceIds.count > 0 )
        {
            [_peripheral loadServices:loadServiceIds foundSelector:@selector(_didDiscoverService:) target:self ];
        }
    }
}

-(void) _didDiscoverService:(ServiceProxy*)service
{
    if ( _peripheral == service.peripheral )
    {
        if ( _delegate && [_delegate respondsToSelector:@selector(profileObject:discoveredService:)] )
        {
            [_delegate profileObject:self discoveredService:service];
        }
        
        [self _discoverCharacteristicsForService:service.UUID];
    }
}

-(void) _discoverCharacteristicsForService:(CBUUID*)serviceId
{
    if ( _peripheral && _profileData )
    {
        ServiceData* serviceData = [_profileData serviceDataForUUID:serviceId];
        
        if( serviceData )
        {
            NSArray* characteristicIds = serviceData.characteristicIds;
            NSMutableArray* loadCharacteristicIds = [[NSMutableArray alloc] init];
            ServiceProxy* service = [_peripheral findService:serviceId];
            
            for( CBUUID* uuid in characteristicIds )
            {
                CharacteristicProxy* characteristic = [service findCharacteristic:uuid];
                
                if ( characteristic == nil )
                {
                    [loadCharacteristicIds addObject:uuid];
                }
                else
                {
                    [self _didDiscoverCharacteristic:characteristic];
                }
            }
            
            if ( loadCharacteristicIds.count > 0 )
            {
                [service loadCharacteristics:loadCharacteristicIds foundSelector:@selector(_didDiscoverCharacteristic:) target:self];
            }
        }

    }
}

-(void) _didDiscoverCharacteristic:(CharacteristicProxy*)characteristic
{
    if ( characteristic.service.peripheral == _peripheral )
    {
        if ( _delegate && [_delegate respondsToSelector:@selector(profileObject:discoveredCharacteristic:)] )
        {
            [_delegate profileObject:self discoveredCharacteristic:characteristic];
        }
        
    }
}


-(void) setPeripheral:(PeripheralProxy*)peripheral
{

    _peripheral = peripheral;
    
    if ( _profileData )
    {
        [self _discoverServices];
    }

}

-(id) initWithFile:(NSString*)fileName
{
    self = [super init];
    
    if ( self )
    {
        _profileData = [ProfileData loadProfileData:fileName];
    }
    
    return self;
}

-(id) initWithFile:(NSString *)fileName inBundle:(NSBundle*)bundle
{
    self = [super init];
    
    if ( self )
    {
        _profileData = [ProfileData loadProfileData:fileName fromBundle:bundle];
    }
    
    return self;
}

-(NSArray*) getServiceIds
{
    return [_profileData serviceIds];
}

-(NSArray*) getCharacteristicIdsForService:(CBUUID*)serviceId
{
    ServiceData* serviceData = [_profileData serviceDataForUUID:serviceId];
    
    if ( serviceData )
    {
        return [serviceData characteristicIds];
    }
    
    return [NSArray array];
}

@end
