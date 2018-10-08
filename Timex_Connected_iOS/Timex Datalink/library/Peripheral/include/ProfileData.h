//
//  ProfileData.h
//  MillMonitoringSystem
//
//  Created by Michael Nannini on 3/28/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

extern NSString* const kServicesKey;
extern NSString* const kCharacteristicsKey;
extern NSString* const kUUIDKey;
extern NSString* const kNameKey;
extern NSString* const kLocalIdKey;

@class ServiceData;
@class CharacteristicData;

//************************************************************************************************

@interface ProfileData : NSObject

@property (nonatomic, readonly) NSArray* services;

+(ProfileData*) loadProfileData:(NSString*)fileName;

+(ProfileData*) loadProfileData:(NSString *)fileName fromBundle:(NSBundle*)bundle;

-(id) initWithData:(NSDictionary*)data;

-(ServiceData*) serviceDataForUUID:(CBUUID*)uuid;

-(ServiceData*) serviceDataForLocalId:(NSNumber*)localId;

-(NSArray*) serviceIds;

@end

//************************************************************************************************

@interface ServiceData : NSObject

@property (nonatomic, readonly) NSArray* characteristics;

@property (nonatomic, readonly) CBUUID* uuid;

@property (nonatomic, readonly) NSNumber* localId;

@property (nonatomic, readonly) NSString* name;

-(id) initWithData:(NSDictionary*) data;

-(CharacteristicData*) characteristicDataForUUID:(CBUUID*)uuid;

-(CharacteristicData*) characteristicDataForLocalId:(NSNumber *)localId;

-(NSArray*) characteristicIds;

@end

//************************************************************************************************

@interface CharacteristicData : NSObject

@property (nonatomic, readonly) CBUUID* uuid;

@property (nonatomic, readonly) NSNumber* localId;

@property (nonatomic, readonly) NSString* name;

@property (nonatomic, readonly) NSDictionary* simData;

-(id) initWithData:(NSDictionary*) data;

@end
