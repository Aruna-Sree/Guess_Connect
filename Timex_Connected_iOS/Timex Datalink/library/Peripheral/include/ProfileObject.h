//
//  ProfileObject.h
//  MillMonitoringSystem
//
//  Created by Michael Nannini on 3/26/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "PeripheralProxy.h"
#import "ProfileData.h"

@protocol ProfileObjectDelegate;

@interface ProfileObject : NSObject

@property (nonatomic, weak) PeripheralProxy*    peripheral;

@property (nonatomic, weak) id<ProfileObjectDelegate> delegate;

@property (nonatomic, readonly) ProfileData*    profileData;



-(id) initWithFile:(NSString*)fileName;

-(id) initWithFile:(NSString *)fileName inBundle:(NSBundle*)bundle;

-(NSArray*) getServiceIds;

-(NSArray*) getCharacteristicIdsForService:(CBUUID*)serviceId;


@end


@protocol ProfileObjectDelegate <NSObject>

@required

-(void) profileObject:(ProfileObject*)profileObject discoveredService:(ServiceProxy*)service;

-(void) profileObject:(ProfileObject *)profileObject discoveredCharacteristic:(CharacteristicProxy*)characteristic;

//-(void) profileObject:(ProfileObject *)profileObject valueUpdatedForCharacteristic:(CharacteristicProxy*)characteristic;

@end