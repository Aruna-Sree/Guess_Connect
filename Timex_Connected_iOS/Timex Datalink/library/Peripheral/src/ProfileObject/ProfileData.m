//
//  ProfileData.m
//  MillMonitoringSystem
//
//  Created by Michael Nannini on 3/28/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

#import "ProfileData.h"
#import "PeripheralUtility.h"

NSString* const kServicesKey    = @"services";
NSString* const kCharacteristicsKey = @"characteristics";
NSString* const kUUIDKey = @"uuid";
NSString* const kNameKey = @"name";
NSString* const kLocalIdKey = @"localid";
NSString* const kSimulatorDataKey = @"simulator";

CBUUID* convertUUID(NSString* strUUID)
{
    if ( strUUID )
    {
        CBUUID* cbuuid = [CBUUID UUIDWithString:strUUID];
        
        return cbuuid;
    }
    
    return nil;
}

NSNumber* loadLocalId(NSObject* idObject)
{
    if( [idObject isKindOfClass:[NSNumber class]] )
        return (NSNumber*)idObject;
    
    if ( [idObject isKindOfClass:[NSString class]] )
        return [PeripheralUtility hexStringToNumber:(NSString*)idObject];
    
    return nil;
}

@interface ProfileData ()
{
    NSArray*               _serviceData;
    NSMutableDictionary*   _servicesByUUID;
    NSMutableDictionary*   _servicesByLocalId;
}

+(void) _createProfileDataCache;

-(void) _setupProfileData:(NSDictionary*)source;


@end

@implementation ProfileData

static NSMutableDictionary* _profileDataCache;

@synthesize services=_serviceData;

+(ProfileData*) loadProfileData:(NSString*)fileName
{
    return [ProfileData loadProfileData:fileName fromBundle:[NSBundle mainBundle]];
}

+(ProfileData*) loadProfileData:(NSString *)fileName fromBundle:(NSBundle*)bundle
{
    [ProfileData _createProfileDataCache];
    
    NSString* filePath = [bundle pathForResource:fileName ofType:@"plist"];
    
    ProfileData* profileData = [_profileDataCache objectForKey:filePath];
    
    if ( profileData == nil )
    {
        NSDictionary* sourceData = [NSDictionary dictionaryWithContentsOfFile:filePath];
        
        
        if ( sourceData )
        {
            profileData = [[ProfileData alloc] initWithData:sourceData];
        }
        
        [_profileDataCache setObject:profileData forKey:filePath];
        
    }
    
    return profileData;
}

-(id) initWithData:(NSDictionary*)data
{
    self = [super init];
    
    if ( self )
    {
        [self _setupProfileData:data];
    }
    
    return self;
}

-(ServiceData*) serviceDataForUUID:(CBUUID*)uuid
{
    return [_servicesByUUID objectForKey:uuid];
}

-(ServiceData*) serviceDataForLocalId:(NSNumber *)localId
{
    return [_servicesByLocalId objectForKey:localId];
}


-(NSArray*) serviceIds
{
    return _servicesByUUID.allKeys;
}

+(void) _createProfileDataCache
{
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        _profileDataCache = [[NSMutableDictionary alloc] init];
    });
}



-(void) _setupProfileData:(NSDictionary*)source
{
    
    NSMutableArray* serviceData = [[NSMutableArray alloc] init];
    
    _serviceData = serviceData;
    
    _servicesByUUID = [[NSMutableDictionary alloc] init];
    
    _servicesByLocalId = [[NSMutableDictionary alloc] init];
    
    NSArray* services = [source objectForKey:kServicesKey];
    
    if ( services )
    {
        
        for( int s = 0; s < services.count; s++ )
        {
            ServiceData* service = [[ServiceData alloc] initWithData:[services objectAtIndex:s]];
            
            
            
            if ( service.uuid )
            {
                if ( [_servicesByUUID objectForKey:service.uuid] )
                {
                    NSLog(@"ProfileData:: Dubplicate Service UUID %@", service.uuid);
                }
                
                [_servicesByUUID setObject:service forKey:service.uuid];
            }
            

            
            if ( service.localId )
            {
                if ( [_servicesByLocalId objectForKey:service.localId] )
                {
                    NSLog(@"ProfileData:: Duplicate Service Local ID %@", service.localId);
                }
                
                [_servicesByLocalId setObject:service forKey:service.localId];
            }
            
            [serviceData addObject:service];
            
        }
    }
    
}



@end


//************************************************************************************************

@interface ServiceData ()
{
    CBUUID*     _uuid;
    NSArray*    _characteristics;
    NSNumber*   _localId;
    NSString*   _name;
    NSDictionary*   _characteristicsByUUID;
    NSDictionary*   _characteristicsByLocalId;
}

-(void) _setupCharacteristics:(NSArray*) charSource;

@end

@implementation ServiceData

@synthesize uuid=_uuid;
@synthesize localId=_localId;
@synthesize name=_name;
@synthesize characteristics=_characteristics;

-(id) initWithData:(NSDictionary *)data
{
    self = [super init];
    
    if ( self )
    {
        _name = [data objectForKey:kNameKey];
        _localId = loadLocalId([data objectForKey:kLocalIdKey]);
        
        _uuid = convertUUID([data objectForKey:kUUIDKey]);
        
        [self _setupCharacteristics:[data objectForKey:kCharacteristicsKey]];
    
    }
    
    return self;
}

-(CharacteristicData*) characteristicDataForUUID:(CBUUID*)uuid
{
    return [_characteristicsByUUID objectForKey:uuid];
}

-(CharacteristicData*) characteristicDataForLocalId:(NSNumber *)localId
{
    return [_characteristicsByLocalId objectForKey:localId];
}

-(NSArray*) characteristicIds
{
    return [_characteristicsByUUID allKeys];
}

-(void) _setupCharacteristics:(NSArray*) charSource
{
    NSMutableDictionary* charByUUID = [[NSMutableDictionary alloc] init];
    NSMutableDictionary* charByLocalId = [[NSMutableDictionary alloc] init];
    
    NSMutableArray* characteristics = [[NSMutableArray alloc] init];
    
    _characteristicsByUUID = charByUUID;
    _characteristicsByLocalId = charByLocalId;

    _characteristics = characteristics;
    
    if ( charSource )
    {
        
        for( int c = 0; c < charSource.count; c++ )
        {
            CharacteristicData* characteristic = [[CharacteristicData alloc] initWithData:[charSource objectAtIndex:c]];
            
            if ( characteristic.uuid )
            {
                if ( [charByUUID objectForKey:characteristic.uuid] )
                {
                    NSLog(@"ProfileData:: Duplicate Characteristic UUID %@", characteristic.uuid);
                }
                
                [charByUUID setObject:characteristic forKey:characteristic.uuid];
            }
            
            if ( characteristic.localId )
            {
                if ( [charByLocalId objectForKey:characteristic.localId] )
                {
                    NSLog( @"ProfileData:: Duplicate Characteristic Local ID %@", characteristic.localId );
                }
                
                [charByLocalId setObject:characteristic forKey:characteristic.localId];
            }
            
            [characteristics addObject:characteristic];
    
        }
    }
}

@end


//************************************************************************************************

@interface CharacteristicData ()
{
    CBUUID*     _uuid;
    NSNumber*   _localId;
    NSString*   _name;
    NSDictionary* _simData;
}

@end

@implementation CharacteristicData

@synthesize uuid=_uuid;
@synthesize localId=_localId;
@synthesize name=_name;
@synthesize simData=_simData;

-(id) initWithData:(NSDictionary*) data
{
    self = [super init];
    
    if ( self )
    {
        _name = [data objectForKey:kNameKey];
        _localId =  loadLocalId([data objectForKey:kLocalIdKey]);
        
        _uuid = convertUUID([data objectForKey:kUUIDKey]);
        _simData = [data objectForKey:kSimulatorDataKey];
    }
    
    return self;
}

@end
