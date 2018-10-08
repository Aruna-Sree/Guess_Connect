//
//  TDDeviceManager.m
//  Timex Connected
//
//  Created by Lev Verbitsky on 9/12/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

#import "TDDeviceManager.h"
#import <AVFoundation/AVFoundation.h>
#import "TDDevice.h"
#import "PeripheralDevice.h"
#import "BLEManager.h"
#import "iDevicesUtil.h"
#import "TDDeviceProfile.h"
#import "OTLogUtil.h"
#define ADVERTISE_TIME_OUT (5)

NSString* const kDeviceManagerAdvertisingDevicesChangedNotification = @"kDeviceManagerAdvertisingDevicesChangedNotification";
NSString* const kDeviceManagerConnectedDevicesChangedNotification = @"kDeviceManagerConnectedDevicesChangedNotification";
NSString* const kDeviceManagerDeviceLostConnectiondNotification = @"kDeviceManagerDeviceLostConnectiondNotification";
NSString* const kPeripheralDeviceForgetAndDisconnectedNotification = @"kPeripheralDeviceForgetAndDisconnectedNotification";
NSString* const kPeripheralDeviceAuthorizationFailedNotification = @"kPeripheralDeviceAuthorizationFailedNotification";

@interface TDDeviceManager ()
{
    BLEManager*     _bleManager;    
    NSMutableArray* _advertisingDevices;
    NSMutableArray* _connectedDevices;
    NSMutableArray* _connectingDevices;
    NSTimer*        _advertisingTimer;
    NSArray*        _connectedDevicesDisplay;
    CBUUID*         _deviceService;
    NSTimer*        _processTimer;
    
    PeripheralDevice * _currentlySelectedDevice;
}

@property (strong, nonatomic) NSMutableArray *devices;
@property (strong, nonatomic) NSMutableArray *activePeripherals;

@property (strong) AVAudioPlayer *highBeep;
@property (strong) AVAudioPlayer *lowBeep;

-(void) _discoveredPeripheral:(NSNotification*)notification;

-(void) _connectedPeripheral:(NSNotification*)notification;

-(void) _bleManagerStateChanged:(NSNotification*)notifcation;

-(void) _retrieveConnectedDevices;

-(PeripheralDevice*) _findConnectedDeviceForPeripheral:(PeripheralProxy*)peripheral;

-(void) _deviceDataUpdated:(NSNotification*)notification;

-(void) _process:(NSTimer*)timer;

@end

@implementation TDDeviceManager


@synthesize devices                 = _devices;
@synthesize activePeripherals       = _activePeripherals;
@synthesize highBeep                = _highBeep;
@synthesize lowBeep                 = _lowBeep;
@synthesize advertisingDevices      = _advertisingDevices;
@synthesize connectedDevices        = _connectedDevices;

static TDDeviceManager * instance = nil;

+ (TDDeviceManager *)sharedInstance
{
    if (instance == nil)
    {
        instance = [[super alloc] init];
    }
    return instance;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        _advertisingDevices = [[NSMutableArray alloc] init];
        _devices = [[NSMutableArray alloc] init];
        _activePeripherals = [[NSMutableArray alloc] init];
        _connectedDevices = [[NSMutableArray alloc] init];
        _connectingDevices = [[NSMutableArray alloc] init];

        _connectedDevicesDisplay = [NSArray array];
        
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_discoveredPeripheral:) name:kBLEManagerDiscoveredPeripheralNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_undiscoveredPeripheral:) name:kBLEManagerUndiscoveredPeripheralNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_connectedPeripheral:) name:kBLEManagerConnectedPeripheralNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_connectedPeripheral:) name:kBLEManagerRestoredConnectedPeripheralNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_bleManagerStateChanged:) name:kBLEManagerStateChanged object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_deviceDataUpdated:) name:kTDDeviceDataUpdatedNotification object:nil];
        
        _bleManager = [[BLEManager alloc] init];
        
        if ( _bleManager.isBLEAvailable )
        {
          
            [self _retrieveConnectedDevices];
        }

        _processTimer = [NSTimer scheduledTimerWithTimeInterval: 1 target:self selector:@selector(_process:) userInfo:nil repeats:YES];
    }
    return self;
}
- (BOOL) isWatchConnected
{
    OTLog(@"TDDeviceManager isWatchConnected");
    BOOL retValue = false;
    
    if ([_bleManager isBLESupported] && [_bleManager isBLEAvailable])
    {
        if (_connectedDevices && [_connectedDevices count] > 0)
        {
            PeripheralDevice * timexDevice = [iDevicesUtil getConnectedTimexDevice];
            if (timexDevice != nil)
                retValue = true;
        }
    }
    
    return retValue;
}


- (void)setDashboardCurrentlySelectedDevice:(PeripheralDevice*)device{
    OTLog(@"TDDeviceManager setDashboardCurrentlySelectedDevice");
    _currentlySelectedDevice = device;
}
- (PeripheralDevice*)getDashboardCurrentlySelectedDevice {
    return _currentlySelectedDevice;
}

// IMPORTANT NOTE: this wrapper property allows the services array to be observable via KVO
- (NSMutableArray *)observableDevices
{
    OTLog(@"TDDeviceManager observableDevices");
    // need to use collection proxy to allow KVO for mutable arrays
    return [self mutableArrayValueForKey:@"devices"];
}

-(void) dealloc
{
    OTLog(@"TDDeviceManager dealloc");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_processTimer invalidate];
    _processTimer = nil;
}

- (void)startScan
{
    OTLog(@"TDDeviceManager startScan");
    NSArray         *uuidArray  = @[[PeripheralDevice timexDatalinkServiceId]];

    if (_bleManager.isBLEAvailable)
        [_bleManager scanForPeripheralsWithServices: uuidArray allowDupes: YES];
        
    [_advertisingDevices removeAllObjects];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kDeviceManagerAdvertisingDevicesChangedNotification object:self];
}

- (void)stopScan
{
    OTLog(@"TDDeviceManager stopScan");
    // stop scan
    [_bleManager stopScan];
}

//This method is used to speed up the advertising peripheral discovery process by the centralManger
-(void)restartScan
{
    [_bleManager stopScan];
    [_connectedDevices removeAllObjects];
    [_connectingDevices removeAllObjects];
    [_advertisingDevices removeAllObjects];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void)
    {
        OTLog(@"TDDeviceManager scanning restarted");
        NSArray *uuidArray  = @[[PeripheralDevice timexDatalinkServiceId]];
        [_bleManager scanForPeripheralsWithServices: uuidArray allowDupes: YES];
    });

}

- (void) saveDeviceProfileData:(TDDeviceProfile*)profileData
{
    OTLog(@"TDDeviceManager saveDeviceProfileData");
}

-(TDDeviceProfile*) loadDeviceDataForId:(NSString*)deviceId
{
    OTLog(@"TDDeviceManager loadDeviceDataForId");
    //load device by serial number
    TDDeviceProfile * devProf =  [[TDDeviceProfile alloc] init];
    
    return devProf;
}

-(NSArray *) getAllConnectedDevices
{
//    OTLog(@"TDDeviceManager getAllConnectedDevices");
    [self buildConnectedDevicesDisplay];
    NSMutableArray *newArray = [NSMutableArray arrayWithArray:_connectedDevicesDisplay];
    return newArray;
}


-(NSArray *) getAllConnectedAndAdvertisingDevices
{
    OTLog(@"TDDeviceManager getAllConnectedAndAdvertisingDevices");
    [self buildConnectedDevicesDisplay];
    NSMutableArray *newArray = [NSMutableArray arrayWithArray:_connectedDevicesDisplay];
    [newArray addObjectsFromArray:_advertisingDevices];
    return newArray;
}

- (void)connect:(TDDevice*)device
{
    
    //  if ( device.type != kTDDevice_Peripheral )
    //     return;
    OTLog(@"TDDeviceManager Connect");
    PeripheralDevice* prphDevice = (PeripheralDevice*)device;
    
    switch( prphDevice.peripheral.type )
    {
            
        case kPeripheralSource_BLE:
            [_bleManager connectPeripheral:prphDevice.peripheral];
            break;
            
        default:
            break;
            
    }
    
    [_connectingDevices addObject:device];
    [_advertisingDevices removeObject:device];
    
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kDeviceManagerAdvertisingDevicesChangedNotification object:self];
    
}

- (void)forgetAndDisconnect:(TDDevice*)device
{
    OTLog(@"TDDeviceManager forgetAndDisconnect");
    [self forgetDevice:device];
    
    [self disconnect:device];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kPeripheralDeviceForgetAndDisconnectedNotification object:self];
    
}

- (void)forgetDevice:(TDDevice*)device
{
    OTLog(@"TDDeviceManager forgetDevice");
    [device forgetDevice];
}


- (void)disconnect:(TDDevice*)device
{
    OTLog(@"Force disconnecting device");
    [_connectedDevices removeObject:device];
    
    if (device ==_currentlySelectedDevice)
        _currentlySelectedDevice = nil;
    
    PeripheralDevice* prphDevice = (PeripheralDevice*)device;
    [prphDevice invalidateAllInternalTimers];
    
    [device disconnect];
    

    if ( prphDevice.peripheral.isConnected )
    {
        switch( prphDevice.peripheral.type )
        {
            case kPeripheralSource_BLE:
                [_bleManager disconnectPeripheral:prphDevice.peripheral];
                break;
                
            default:
                break;
        }
    }
    
    [self buildConnectedDevicesDisplay];
    [[NSNotificationCenter defaultCenter] postNotificationName:kDeviceManagerConnectedDevicesChangedNotification object:self];
}

-(void) _cullAdvertisingDevices:(NSTimer*)timer
{
    OTLog(@"TDDeviceManager _cullAdvertisingDevices");
    NSArray* devices = [_advertisingDevices copy];
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    const NSTimeInterval kMaxTime = 2;
    
    for( PeripheralProxy* peripheral in devices )
    {
        NSTimeInterval timeSinceDiscovery = now - peripheral.discoveredTime;
        
        if ( timeSinceDiscovery > kMaxTime )
        {
            [_advertisingDevices removeObject:peripheral];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kDeviceManagerAdvertisingDevicesChangedNotification object:self];
        }
    }
}


-(void) _discoveredPeripheral:(NSNotification*)notification
{
    //OTLog(@"TDDeviceManager _discoveredPeripheral");
    PeripheralProxy* peripheral = [notification.userInfo objectForKey:kBLEManagerPeripheralKey];
    NSDictionary* advertisementData = [notification.userInfo objectForKey:kBLEManagerAdvertisementDataKey];
    
    PeripheralDevice* connectedDevice = [self _findConnectedDeviceForPeripheral:peripheral];
    // If the device is in the connected list, reestablish connection
    if ( connectedDevice )
    {
        [self connect:connectedDevice];
        return;
    }
    
    for( PeripheralDevice* device in _connectingDevices )
    {
        if ( device.peripheral == peripheral )
            return;
    }
    
    for( PeripheralDevice* device in _advertisingDevices )
    {
        if( device.peripheral == peripheral )
            return;
    }
    
    NSString* name = [advertisementData objectForKey:CBAdvertisementDataLocalNameKey];
    if( name == nil )
    {
        name = peripheral.name;
    }
    

    if ( name != nil )
    {
        OTLog(@"Found Device Named: %@", name);
    }
    else
    {
        OTLog(@"Found Device: %@; no name fetched", peripheral.UUID.UUIDString);
    }
    
    PeripheralDevice* newDevice = [[PeripheralDevice alloc] init];
    newDevice.peripheral = peripheral;
    [_advertisingDevices addObject:newDevice];
            
    [[NSNotificationCenter defaultCenter] postNotificationName:kDeviceManagerAdvertisingDevicesChangedNotification object:self];// userInfo:[NSDictionary dictionaryWithObject: connectedDevice forKey: kPeripheralDeviceKey]];
}

-(void) _undiscoveredPeripheral:(NSNotification*)notification
{
    OTLog(@"TDDeviceManager _undiscoveredPeripheral");
    PeripheralProxy* peripheral = [notification.userInfo objectForKey:kBLEManagerPeripheralKey];
    
    NSArray* tempArray = [_advertisingDevices copy];
    
    for( PeripheralDevice* device in tempArray )
    {
        if (device.peripheral == peripheral )
        {
            [_advertisingDevices removeObject:device];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kDeviceManagerAdvertisingDevicesChangedNotification object:self];
        }
    }
    
}

-(void) _connectedPeripheral:(NSNotification*)notification
{
    OTLog(@"TDDeviceManager _connectedPeripheral");
    PeripheralProxy* peripheral = [notification.userInfo objectForKey:kBLEManagerPeripheralKey];
    
    PeripheralDevice* connectedDevice = nil;
    
    for( PeripheralDevice* device in _connectingDevices )
    {
        if( device.peripheral == peripheral )
        {
            connectedDevice = device;
            break;
        }
    }
    
    for( PeripheralDevice* device in _advertisingDevices )
    {
        if( device.peripheral == peripheral )
        {
            //this one is connected, remove it from advertising list
            OTLog(@"Removing %@ from _advertisingDevices", device);
            connectedDevice = device;
            [_advertisingDevices removeObject: device];
            break;
        }
    }
    
    if ( connectedDevice )
    {
        [_connectingDevices removeObject:connectedDevice];
    }
    else
    {
        for( PeripheralDevice* device in _connectedDevices )
        {
            if( device.peripheral == peripheral )
            {
                return;
            }
        }
        
        connectedDevice = [[PeripheralDevice alloc] init];
        connectedDevice.peripheral = peripheral;
        
    }
    
    if ( ![_connectedDevices containsObject:connectedDevice ] )
    {
        [_connectedDevices addObject:connectedDevice];
        
        OTLog(@"-------------->_connectedDevices contains %ld", (unsigned long)[_connectedDevices count]);
        OTLog(@"-------------->_connectingDevices contains %ld", (long)[_connectingDevices count]);
        OTLog(@"-------------->_advertisingDevices contains %ld", (long)[_advertisingDevices count]);
    }
    
    [self buildConnectedDevicesDisplay];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kDeviceManagerConnectedDevicesChangedNotification object:self];
    
}


-(void) _deviceDataUpdated:(NSNotification*)notification
{
    if ( [_connectedDevices containsObject:notification.object] )
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:kDeviceManagerConnectedDevicesChangedNotification object:self];
    }
    
}

-(void) _process:(NSTimer*)timer
{
    [_bleManager purgeAdvertisingDevices:ADVERTISE_TIME_OUT];
    
    
    //The Timex watch uses both Bluetooth classic and BLE and it appears when the classic device is paired through the bluetooth settings it also connects the peripheral as well.  It shows up as two devices in the bluetooth settings.  It also is returned by CoreBluetooth when calling retrieveConnectedPeripherals.
    
    //The issue that this is causing is the device will automatically pair as an accessory and the app won't get either advertisements or a notification that the device connected (since the peripheral connection has to be initiated form within the app for that to happen).
    
    //Currently the work around is to periodically call retrieveConnectedPeripherals to check if the peripheral is connected.
    if ([self getAllConnectedDevices].count == 0)
    {
        if ( _bleManager.isBLEAvailable )
        {
            
            [self _retrieveConnectedDevices];
        }
    }

}

-(void) buildConnectedDevicesDisplay
{
    NSMutableArray* combined = [NSMutableArray arrayWithArray:_connectedDevices];
    
    NSArray* sorted = [combined sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2)
    {
        TDDevice* device1 = (TDDevice*)obj1;
        TDDevice* device2 = (TDDevice*)obj2;
        
        NSComparisonResult nameResult = [device1.name localizedCaseInsensitiveCompare:device2.name];
        
        NSInteger stateValue1 = [TDDevice sortValueForDeviceState:device1.deviceState];
        NSInteger stateValue2 = [TDDevice sortValueForDeviceState:device2.deviceState];
        
        if ( stateValue1 < stateValue2 )
            return NSOrderedAscending;
        
        if ( stateValue1 > stateValue2 )
            return NSOrderedDescending;
        
        return nameResult;
    }];
    
    _connectedDevicesDisplay = sorted;
    
}

- (BLEManager *)getBleManager{
    OTLog(@"TDDeviceManager getBleManager");
    return _bleManager;
}

-(void) _bleManagerStateChanged:(NSNotification*)notifcation
{
    OTLog(@"TDDeviceManager _bleManagerStateChanged");
    if ( _bleManager.isBLEAvailable )
    {
        
        [self startScan];
        [self _retrieveConnectedDevices];
    }
}

-(void) _retrieveConnectedDevices
{
    NSArray         *uuidArray  = @[[PeripheralDevice timexDatalinkServiceId]];
    
    [_bleManager retrieveConnectedPeripheralProxies:^BOOL(PeripheralProxy *peripheral)
    {
        NSString * currentPeripheralID = peripheral.UUID.UUIDString;
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSString * storedUUID = [userDefaults objectForKey: kCONNECTED_DEVICE_UUID_PREF_NAME];
        if ((storedUUID == nil) || (storedUUID != nil && [storedUUID isEqualToString: peripheral.UUID.UUIDString])) {
            OTLog(@"Reconnecting to watch (UUID %@)", currentPeripheralID);
            [_bleManager connectPeripheral: peripheral];
        }
        return YES;
    } withServiceIds: uuidArray];
}

-(PeripheralDevice*) _findAdvertisingDeviceForPeripheral:(PeripheralProxy*)peripheral
{
    OTLog(@"TDDeviceManager _findAdvertisingDeviceForPeripheral");
    for( PeripheralDevice* device in _advertisingDevices )
    {
        if( device.peripheral == peripheral )
        {
            return device;
        }
    }
    
    return nil;
}

-(PeripheralDevice*) _findConnectedDeviceForPeripheral:(PeripheralProxy*)peripheral
{
    //OTLog(@"TDDeviceManager _findConnectedDeviceForPeripheral");
    for( PeripheralDevice* device in _connectedDevices )
    {
        if( device.peripheral == peripheral )
        {
            return device;
        }
    }
    
    return nil;
}


@end
