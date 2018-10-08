//
//  TDDeviceManager.h
//  Timex Connected
//
//  Created by Lev Verbitsky on 9/12/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

//#if DEBUG
#define SIM_DEVICES (0)
//#endif
extern NSString* const kDeviceManagerAdvertisingDevicesChangedNotification;
extern NSString* const kDeviceManagerConnectedDevicesChangedNotification;
extern NSString* const kDeviceManagerDeviceLostConnectiondNotification;
extern NSString* const kPeripheralDeviceForgetAndDisconnectedNotification;
extern NSString* const kPeripheralDeviceAuthorizationFailedNotification;

@class PeripheralDevice;
@class TDDevice;
@class TDDeviceProfile;
@class BLEManager;

@interface TDDeviceManager : NSObject

@property (strong, nonatomic, readonly) NSMutableArray *devices;
@property (nonatomic, readonly) NSArray* advertisingDevices;
@property (nonatomic, readonly) NSArray* connectedDevices;

+ (TDDeviceManager *)sharedInstance;

- (BOOL) isWatchConnected;
- (void) startScan;
- (void) stopScan;
- (void) restartScan;
- (void) connect:(TDDevice*)device;
- (void) disconnect:(TDDevice*)device;
- (void) forgetAndDisconnect:(TDDevice*)device;
- (TDDeviceProfile*) loadDeviceDataForId:(NSString*)deviceId;
- (void) saveDeviceProfileData:(TDDeviceProfile*)profileData;
- (void) setDashboardCurrentlySelectedDevice:(PeripheralDevice*)device;
- (PeripheralDevice*) getDashboardCurrentlySelectedDevice;
- (NSArray *) getAllConnectedAndAdvertisingDevices;
- (NSArray *) getAllConnectedDevices;
- (void) buildConnectedDevicesDisplay;
- (BLEManager *)getBleManager;
@end
