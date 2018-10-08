//
//  DeviceInformationService.m
//  Wahooo
//
//  Created by Michael Nannini on 2/5/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

#import "DeviceInformationService.h"
#import "PeripheralUtility.h"
#import "CharacteristicProxy.h"

static CBUUID* s_deviceInformationServiceID = nil;

static CBUUID* s_manufacturerNameID = nil;

static CBUUID* s_modelNumberID = nil;

static CBUUID* s_serialNumberID = nil;

static CBUUID* s_hardwareRevisionID = nil;

static CBUUID* s_firmwareRevisionID = nil;

static CBUUID* s_softwareRevisionID = nil;

static CBUUID* s_systemIDID = nil;

@interface DeviceInformationService ()
{
    PeripheralProxy* __weak     _peripheral;
    
    NSString*                   _manufacturerName;
    
    NSString*                   _modelNumber;
    
    NSString*                   _serialNumber;
    
    NSString*                   _hardwareRevision;
    
    NSString*                   _firmwareRevision;
    
    NSString*                   _softwareRevision;
    
    DeviceInformationSystemID_t _systemID;
    
    id<DeviceInformationServiceDelegate> __weak _delegate;
    
}

-(void) _loadCharacteristics;

-(void) _foundCharacteristic:(CharacteristicProxy*)characteristic;

-(void) _readManufacturerName:(CharacteristicProxy*) characteristic;

-(void) _readModelNumber:(CharacteristicProxy*)characteristic;

-(void) _readSerialNumber:(CharacteristicProxy*) characteristic;

-(void) _readHardwareRevision:(CharacteristicProxy*) characteristic;

-(void) _readFirmwareRevision:(CharacteristicProxy*) characteristic;

-(void) _readSoftwareRevision:(CharacteristicProxy*) characteristic;

-(void) _readSystemID:(CharacteristicProxy*) characteristic;

@end

@implementation DeviceInformationService

@synthesize manufacturerName=_manufacturerName;

@synthesize modelNumber=_modelNumber;

@synthesize serialNumber=_serialNumber;

@synthesize hardwareRevision=_hardwareRevision;

@synthesize firmwareRevision=_firmwareRevision;

@synthesize softwareRevision=_softwareRevision;

@synthesize systemID=_systemID;

@synthesize delegate=_delegate;

+(CBUUID*) deviceInformationServiceID
{
    if ( s_deviceInformationServiceID == nil )
    {
        s_deviceInformationServiceID = [CBUUID UUIDWithString:@"180A"];
    }
    
    return s_deviceInformationServiceID;
}

+(CBUUID*) manufacturerNameID
{
    if ( s_manufacturerNameID == nil )
    {
        s_manufacturerNameID = [CBUUID UUIDWithString:@"2A29"];
    }
    
    return s_manufacturerNameID;
}

+(CBUUID*) modelNumberID
{
    if ( s_modelNumberID == nil )
    {
        s_modelNumberID = [CBUUID UUIDWithString:@"2A24"];
    }
    
    return s_modelNumberID;
}

+(CBUUID*) serialNumberID
{
    if ( s_serialNumberID == nil )
    {
        s_serialNumberID = [CBUUID UUIDWithString:@"2A25"];
    }
    
    return s_serialNumberID;
}

+(CBUUID*) hardwareRevisionID
{
    if ( s_hardwareRevisionID == nil )
    {
        s_hardwareRevisionID = [CBUUID UUIDWithString:@"2A27"];
    }
    
    return s_hardwareRevisionID;
}

+(CBUUID*) firmwareRevisionID
{
    if ( s_firmwareRevisionID == nil )
    {
        s_firmwareRevisionID = [CBUUID UUIDWithString:@"2A26"];
    }
    
    return s_firmwareRevisionID;
}

+(CBUUID*) softwareRevisionID
{
    if ( s_softwareRevisionID == nil )
    {
        s_softwareRevisionID = [CBUUID UUIDWithString:@"2A28"];
    }
    
    return s_softwareRevisionID;
}

+(CBUUID*) systemIDID
{
    if ( s_systemIDID == nil )
    {
        s_systemIDID = [CBUUID UUIDWithString:@"2A23"];
    }
    
    return s_systemIDID;
}

-(id) init
{
    self = [super init];
    
    if ( self )
    {
        _systemID.data = 0;
    }
    
    return self;
}

-(id) initWithDelegate:(id<DeviceInformationServiceDelegate>)delegate
{
    self = [super init];
    
    if ( self )
    {
        _systemID.data = 0;
        _delegate = delegate;
    }
    
    return self;
}

-(void) setPeripheral:(PeripheralProxy*)peripheral
{
    _peripheral = peripheral;
    
    [self _loadCharacteristics];
}

-(void) _loadCharacteristics
{
    if ( _peripheral )
    {
        ServiceProxy* service = [_peripheral findService:[DeviceInformationService deviceInformationServiceID]];
        
        if ( service )
        {
            NSArray* charIds = @[[DeviceInformationService manufacturerNameID], [DeviceInformationService modelNumberID], [DeviceInformationService serialNumberID], [DeviceInformationService hardwareRevisionID], [DeviceInformationService firmwareRevisionID], [DeviceInformationService softwareRevisionID],[DeviceInformationService systemIDID]];
            
            [PeripheralUtility loadCharacteristics:charIds fromService:service foundSelector:@selector(_foundCharacteristic:) target:self];
        }
        else
        {
            NSLog(@"DeviceInformationService:: Peripheral does not contain the Device Information Service");
        }
    }
}

-(void) _foundCharacteristic:(CharacteristicProxy*)characteristic
{
    
    if ( [characteristic.UUID isEqual: [DeviceInformationService manufacturerNameID]] )
    {
        [characteristic updateValue:@selector(_readManufacturerName:) target:self];
    }
    else if( [characteristic.UUID isEqual:[DeviceInformationService modelNumberID]] )
    {
        [characteristic updateValue:@selector(_readModelNumber:) target:self];
    }
    else if ( [characteristic.UUID isEqual:[DeviceInformationService serialNumberID]] )
    {
        [characteristic updateValue:@selector(_readSerialNumber:) target:self];
    }
    else if ( [characteristic.UUID isEqual:[DeviceInformationService hardwareRevisionID]])
    {
        [characteristic updateValue:@selector(_readHardwareRevision:) target:self];
    }
    else if ( [characteristic.UUID isEqual:[DeviceInformationService firmwareRevisionID]] )
    {
        [characteristic updateValue:@selector(_readFirmwareRevision:) target:self];
    }
    else if ( [characteristic.UUID isEqual:[DeviceInformationService softwareRevisionID]])
    {
        [characteristic updateValue:@selector(_readSoftwareRevision:) target:self];
    }
    else if ( [characteristic.UUID isEqual:[DeviceInformationService systemIDID]] )
    {
        [characteristic updateValue:@selector(_readSystemID:) target:self];
    }
}

-(void) _readManufacturerName:(CharacteristicProxy*) characteristic
{
    _manufacturerName = [characteristic stringValueFromUTF8];
    
    if( _delegate &&
       [_delegate respondsToSelector:@selector(dis:manufacturerNameUpdated:) ])
    {
        [_delegate dis:self manufacturerNameUpdated:_manufacturerName];
    }
    
    NSLog(@"Manufacturer Name: %@", _manufacturerName);
}

-(void) _readModelNumber:(CharacteristicProxy *)characteristic
{
    _modelNumber = [characteristic stringValueFromUTF8];
    
    if( _delegate &&
       [_delegate respondsToSelector:@selector(dis:modelNumberUpdated:) ])
    {
        [_delegate dis:self modelNumberUpdated:_modelNumber];
    }

    
    NSLog(@"Model Number %@", _modelNumber);
}

-(void) _readSerialNumber:(CharacteristicProxy*) characteristic
{
    _serialNumber = [characteristic stringValueFromUTF8];
    
    if( _delegate &&
       [_delegate respondsToSelector:@selector(dis:serialNumberUpdated:) ])
    {
        [_delegate dis:self serialNumberUpdated:_serialNumber];
    }

    
    NSLog(@"Serial Number %@", _serialNumber);
}

-(void) _readHardwareRevision:(CharacteristicProxy*) characteristic
{
    _hardwareRevision = [characteristic stringValueFromUTF8];
    
    if( _delegate &&
       [_delegate respondsToSelector:@selector(dis:hardwareRevisionUpdated:) ])
    {
        [_delegate dis:self hardwareRevisionUpdated:_hardwareRevision];
    }

    
    NSLog(@"Hardware Revision %@", _hardwareRevision);
}

-(void) _readFirmwareRevision:(CharacteristicProxy*) characteristic
{
    _firmwareRevision = [characteristic stringValueFromUTF8];
    
    if( _delegate &&
       [_delegate respondsToSelector:@selector(dis:firmwareRevisionUpdated:) ])
    {
        [_delegate dis:self firmwareRevisionUpdated:_firmwareRevision];
    }

    
    NSLog(@"Firmware Revision %@", _firmwareRevision);
}

-(void) _readSoftwareRevision:(CharacteristicProxy*) characteristic
{
    _softwareRevision = [characteristic stringValueFromUTF8];
    
    if( _delegate &&
       [_delegate respondsToSelector:@selector(dis:softwareRevisionUpdated:)] )
    {
        [_delegate dis:self softwareRevisionUpdated:_softwareRevision];
    }
    
    NSLog(@"Software Revision %@", _softwareRevision);
}

-(void) _readSystemID:(CharacteristicProxy *)characteristic
{
    // System ID requires 8 bytes
    if ( characteristic.value && characteristic.value.length == 8 )
    {
        uint64_t data;

        memcpy( &data, characteristic.value.bytes, sizeof(uint64_t));
        
       // NSLog(@" %X, %X, %X", &_systemID.manufacturerID, &_systemID.oui, &_systemID.data);
        _systemID.data = NSSwapLittleLongLongToHost(data);
        uint64_t mid = _systemID.manufacturerID;
        uint32_t oui = _systemID.oui;
        
        if( _delegate &&
           [_delegate respondsToSelector:@selector(dis:systemIDUpdated:) ])
        {
            [_delegate dis:self systemIDUpdated:_systemID];
        }


        NSLog(@"System ID Manufacturer ID %llx, OUI %x", mid, oui);
    }
}


@end
