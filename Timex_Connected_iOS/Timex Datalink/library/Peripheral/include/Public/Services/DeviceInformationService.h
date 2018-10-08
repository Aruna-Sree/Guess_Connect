//
//  DeviceInformationService.h
//  Wahooo
//
//  Created by Michael Nannini on 2/5/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PeripheralProxy.h"

@protocol DeviceInformationServiceDelegate;

typedef union 
{
  struct
    {
        uint64_t manufacturerID:40;
        uint64_t oui:24;
    };
    uint64_t data;
} DeviceInformationSystemID_t;

@interface DeviceInformationService : NSObject

+(CBUUID*) deviceInformationServiceID;

+(CBUUID*) manufacturerNameID;

+(CBUUID*) modelNumberID;

+(CBUUID*) serialNumberID;

+(CBUUID*) hardwareRevisionID;

+(CBUUID*) firmwareRevisionID;

+(CBUUID*) softwareRevisionID;

+(CBUUID*) systemIDID;

//TODO:
// IEEE 11073-20601 Regulatory Certification Data List
// PNP ID

@property (nonatomic, readonly) NSString* manufacturerName;

@property (nonatomic, readonly) NSString* modelNumber;

@property (nonatomic, readonly) NSString* serialNumber;

@property (nonatomic, readonly) NSString* hardwareRevision;

@property (nonatomic, readonly) NSString* firmwareRevision;

@property (nonatomic, readonly) NSString* softwareRevision;

@property (nonatomic, readonly) DeviceInformationSystemID_t systemID;

@property (nonatomic, weak) id<DeviceInformationServiceDelegate> delegate;

-(id) initWithDelegate:(id<DeviceInformationServiceDelegate>)delegate;

-(void) setPeripheral:(PeripheralProxy*)peripheral;

@end

//************************************************************************************************

@protocol DeviceInformationServiceDelegate<NSObject>
@optional
-(void) dis:(DeviceInformationService*)dis manufacturerNameUpdated:(NSString*)manufacturerName;
-(void) dis:(DeviceInformationService*)dis modelNumberUpdated:(NSString*)modelNumber;
-(void) dis:(DeviceInformationService*)dis serialNumberUpdated:(NSString*)serialNumber;
-(void) dis:(DeviceInformationService*)dis hardwareRevisionUpdated:(NSString*)hardwareRevision;
-(void) dis:(DeviceInformationService*)dis firmwareRevisionUpdated:(NSString*)firmwareRevision;
-(void) dis:(DeviceInformationService*)dis softwareRevisionUpdated:(NSString*)softwareRevision;
-(void) dis:(DeviceInformationService*)dis systemIDUpdated:(DeviceInformationSystemID_t)systemID;
@end
