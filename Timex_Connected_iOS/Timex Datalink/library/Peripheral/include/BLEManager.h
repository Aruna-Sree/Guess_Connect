//
//  BLEManager.h
//  HeartRateMonitor
//
//  Created by Michael Nannini on 1/17/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "PeripheralProxy.h"

/*!
 *  \class BLEManager
 *
 *  \brief  Manages instance of CBCentralManager.
 *
 *  BLEManager performs operations on an instanceof CBCentralManager providing a slightly
 *  more convenient interface for discovering, connecting, retrieving, etc Peripheral objects.
 *
 *  \see    BLEManagerNotifications 
 *          BLEManagerBlockTypes
 *
 */

//TODO: Add convenience methods for extracting info from notification dictionary

/*!
 *  \defgroup BLEManagerNotifications
 *
 *  \brief Notification constants used by BLEManager
 *
 *  Notifications and key constants used by BLEManager to alert observers
 *  to changes in the BLEManager state and peripheral lists.
 *  Notifications are posted to default NSNotificationCenter.
 *

 */

/*!
 *  \ingroup BLEManagerNotifications
 *
 *  \{
 */

/*!
 *  \brief Posted when BLEManager receives advertisement from a peripheral.
 *
 *  userInfo keys:
 *  - kBLEManagerPeripheralKey
 *  - kBLEManagerManagerKey
 *  - kBLEManagerAdvertisementDataKey
 */
extern NSString* const kBLEManagerDiscoveredPeripheralNotification;

/*!
 *  \brief  Posted when BLEManager removes old advertising peripherals.
 *
 *  userInfo keys:
 *  - kBLEManagerPeripheralKey
 *  - kBLEManagerManagerKey
 *
 *  This notification posted as a result of calling BLEManager::purgeAdvertisingDevices:
 */
extern NSString* const kBLEManagerUndiscoveredPeripheralNotification;

/*!
 *  \brief  Posted when a BLEPeripheral connects
 *
 *  userInfo keys:
 *  - kBLEManagerPeripheralKey
 *  - kBLEManagerManagerKey
 */
extern NSString* const kBLEManagerConnectedPeripheralNotification;

/*!
 *  \brief Posted when a BLEPeripheral disconnects
 *
 *  userInfo keys:
 *  - kBLEManagerPeripheralKey
 *  - kBLEManagerManagerKey
 */
extern NSString* const kBLEManagerDisconnectedPeripheralNotification;

/*!
 *  \brief Posted when BLEPeripheral fails to connect
 *
 *  userInfo keys:
 *  - kBLEManagerPeripheralKey
 *  - kBLEManagerManagerKey
 */
extern NSString* const kBLEManagerPeripheralConnectionFailedNotification;

/*!
 *  \brief Posted when Bluetooth Central restoration occurs and a connected peripheral is restored
 *
 *  userInfo keys:
 *  - kBLEManagerPeripheralKey
 *  - kBLEManagerManagerKey
 */
extern NSString* const kBLEManagerRestoredConnectedPeripheralNotification;

/*!
 *  \brief Key in notification userInfo dictionary that maps to calling instance of BLEManager
 */
extern NSString* const kBLEManagerManagerKey;

/*!
 *  \brief  Key in notification userInfo dictionary that maps to BLEPeripheral related to notifcation
 */
extern NSString* const kBLEManagerPeripheralKey;

/*!
 *  \brief  Key in notification userInfo dictionary that maps to advertisement data received from peripheral
 */
extern NSString* const kBLEManagerAdvertisementDataKey;

/*!
 *  \brief  Notification posted when Bluetooth state changes
 */
extern NSString* const kBLEManagerStateChanged;

//! \}

/*!
 *  \defgroup BLEManagerBlockTypes
 *
 *  \brief Block function signature definitions used by various BLEManager methods
 *
 */

/*!
 *  \ingroup BLEManagerBlockTypes
 *
 *  \{
 */

/*!
 *  \brief  Callback used to filter objects by UUID
 *
 *  \param  uuid    UUID to test against
 *  
 *  \return YES if UUID passed callback's test.  NO otherwise
 */
typedef BOOL (^FilterCBUUID)(CBUUID* uuid);

/*!
 *  \brief Callback used to filter peripherals
 *  
 *  \param  peripheral  Core Bluetooth peripheral instance to test.
 *
 *  \return YES if passed, NO if failed.
 *
 */
typedef BOOL (^FilterPeripheral)(CBPeripheral* peripheral);

/*!
 *  \brief  Callback used to filter peripherals
 *
 *  \param  peripheral  PeripheralProxy instance to test
 *
 *  \return YES if passed, NO if failed
 */
typedef BOOL (^FilterPeripheralProxy)(PeripheralProxy* peripheral);

//! \}

@interface BLEManager : NSObject

/*!
 *  \brief Initializes BLEManager with a restoration ID used by the system to restore the Core Bluetooth state.
 *
 *  \param  restorationId   The restoration value to associate with the CBCentralManager
 *
 *  \return Initialized BLEManager object
 * 
 *  \note   Bluetooth restoration is supported in iOS 7 and up.  On iOS 6 and earlier the restorationId is ignored.
 */
-(id) initWithRestorationId:(NSString*)restorationId;

/*!
 *  \brief  Initiates scan for advertising peripherals
 *
 *  The method takes an array of CBUUID objects that represent the IDs of Services
 *  to filter on.  If nil is passed all advertising peripherals are found.
 *  For each discovered peripheral kBLEManagerDiscoveredPeripheralNotification is posted.  This may
 *  result in multiple posts per peripheral if YES is passed for allowDupes.
 *
 *  \param  serviceUUIDs    Array of CBUUIDs of the Services to search for, or nil to return all peripherals.
 *  \param  allow           Wether to allow duplicate advertisement packets to be processed.  If NO then only a single
 *                          advertisement for each peripheral is processed unless subsequent packets contain different data.
 *                          YES allows all advertisement packets to be processed.
 *
 *  \note   Before this can be called the Bluetooth state must be available ready.
 *
 *  \see    kBLEManagerStateChanged isBLESupported isBLEAvailable kBLEManagerDiscoveredPeripheralNotification
 */
-(void) scanForPeripheralsWithServices:(NSArray*)serviceUUIDs allowDupes:(BOOL)allow;

/*!
 *  \brief Halts peripheral scan if running.
 */
-(void) stopScan;

/*!
 *  \brief Retrieve peripherals currently connected to the iOS device regardless of which app connected them.
 *  
 *  \deprecated This method is deprecated and currently does nothing.  Use retrieveConnectedPeripheralProxies: instead.
 *
 *  \see retrieveConnectedPeripheralProxies: BLEManagerBlockTypes
 */
-(void) retrieveConnectedPeripherals:(FilterPeripheral)filterBlock DEPRECATED_ATTRIBUTE;

/*!
 *  \brief Retrieve peripherals currently connected to the iOS device regardless of which app connected them.
 *
 *  This method retrieves a list of connected peripherals.  Peripherals that were connected through
 *  the calling app are ignored or re-connected.  Peripherals that were connected from another app will be sent to
 *  filterBlock to be processed.
 *
 *  \param  filterBlock     Block pointer to filter callback that will process the peripherals
 *
 *  \see BLEManagerBlockTypes
 */

-(void) retrieveConnectedPeripheralProxies:(FilterPeripheralProxy)filterBlock NS_DEPRECATED(NA, NA, 5_0, 7_0);

/*!
 *  \brief Retrieve peripherals currently connected to the iOS device regardless of which app connected them.
 *
 *  This method retrieves a list of connected peripherals.  Peripherals that were connected through
 *  the calling app are ignored or re-connected.  Peripherals that were connected from another app will be sent to
 *  filterBlock to be processed.
 *
 *  \param  filterBlock     Block pointer to filter callback that will process the peripherals
 *
 *  \param  serviceIds      Array of CBUUIDs of services to filter connected devices on (iOS 7)
 *
 *  \see BLEManagerBlockTypes
 */

-(void) retrieveConnectedPeripheralProxies:(FilterPeripheralProxy)filterBlock withServiceIds:(NSArray*)serviceIds;


/*!
 *  \brief Retrieves peripheral instances known by system by UUID, regardless of connection state
 *
 *  This method retrieves a list of peripherals known by the system.  Peripherals already detected by BLEManager
 *  are ignored
 *
 *  \param  filterBlock     Block pointer to filter callback that will process the peripherals
 *
 *  \param  uuids           Array of CBUUIDs of the peripherals to retrieve
 *
 *  \see BLEManagerBlockTypes
 */
-(void) retrieveKnownPeripheralProxies:(FilterPeripheralProxy)filterBlock withIds:(NSArray*)uuids;

/*!
 *  \brief Attempts to connect to the specified peripheral
 *  
 *  \param  peripheral  Peripheral to connect to
 *
 *  \see kBLEManagerConnectedPeripheralNotification kBLEManagerPeripheralConnectionFailedNotification
 */
-(void) connectPeripheral:(PeripheralProxy*)peripheral;

/*!
 *  \brief  Attempts to disconnect the specified peripheral
 *  
 *  \param  peripheral  The peripheral to disconnect
 *
 *  \see kBLEManagerDisconnectedPeripheralNotification
 */
-(void) disconnectPeripheral:(PeripheralProxy*)peripheral;

/*!
 *  \brief  Returns whether Bluetooth Low Energy is supported by the hardware.
 *
 *  \return YES if BLE supported, NO otherwise
 *
 */
-(BOOL) isBLESupported;

/*!
 *  \brief  Returns whether Bluetooth Low Energy is in a state to be used
 *  
 *  \return YES if ready to go, NO otherwise
 */
-(BOOL) isBLEAvailable;

/*!
 *  \brief  Forgets advertising peripherals that may have gone stale
 *
 *  The kBLEManagerUndiscoveredPeripheralNotification notification is posted for each
 *  peripheral to be forgotten
 *
 *  \param  duration    The duration since that last advertisement packet was received before forgetting the peripheral
 *
 *  \note   This method should not be used if scanForPeripheralsWithServices:allowDupes: was called 
 *          with allowDupes = NO.
 *
 *  \see kBLEManagerUndiscoveredPeripheralNotification
 *
 */
-(void) purgeAdvertisingDevices:(NSTimeInterval)duration;

/*!
 *  \brief Returns an array of peripherals currently advertising and found
 *
 *  \return Array of advertising peripherals
 */
-(NSArray*) getAdvertisingPeripherals;

/*!
 *  \brief  Returns an array of connected peripherals
 *
 *  \return Array of connected peripheral
 *
 */
-(NSArray*) getConnectedPeripherals;

@end
