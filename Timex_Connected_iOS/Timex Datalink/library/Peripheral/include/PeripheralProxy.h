//
//  PeripheralProxy.h
//  HeartRateMonitor
//
//  Created by Michael Nannini on 1/16/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

/*!
 *  \class PeripheralProxy
 *
 *  \brief Base class / interface defining a generic Peripheral object.
 *
 *  PeripheralProxy defines a generic base class for Peripheral objects based on the Core Bluetooth API.  PeripheralProxy
 *  handles shared management of Service discovery callbacks and storing discovered ServiceProxies objects.
 *  
 *  \note Classes that need to store PeripheralProxy objects should use weak references and test if the pointer is still valid
 *  before using.
 */

/*!
 *  \enum PeripheralSourceType
 *
 *  Enumeration defining hints for what implementation source interited classes use.
 */
typedef enum
{
    //! Default value.  Child class isn't implemented properly
    kPeripheralSource_Unknown = 0,
    //! The implementation uses CBPeripheral as the source
    kPeripheralSource_BLE,
    //! The implementation uses remote data
    kPeripheralSource_WiFi,
    //! The implementation is simulated locally in software
    kPeripheralSource_Sim,
    //! Total number of values defined in the enumeration
    kPeripheralSource_Total
    
} PeripheralSourceType;

@class ServiceProxy;
@class CharacteristicProxy;
@class PeripheralProxy;

/*!
 *  \typedef void FoundServiceBlock
 *
 *  Block pointer signature definition of callback for when Service has been discovered.
 *  Passed as an argument to PeripheralProxy::loadServices:foundBlock: and PeripheralProxy::loadServices:foundBlock:completeBlock:
 *
 *  \param  service Pointer to the ServiceProxy that was found
 *
 */
typedef void (^FoundServiceBlock)(ServiceProxy* service);

/*!
 *  \typedef void FoundServiceCompleteBlock
 *
 *  Block pointer signature definition of callback for when the discovered services have been processed
 *  Passed as an argument to PeripheralProxy::loadServices:foundBlock:completeBlock:
 *
 *  \param  peripheral  The calling PeripheralProxy object
 *
 */
typedef void (^FoundServiceCompleteBlock)(PeripheralProxy* peripheral);

/*!
 *  \typedef void UpdateRSSIBlock
 *
 *  Block pointer signature definition of callback for updating RSSI value
 *
 *  \param  peripheral  The calling PeripheralProxy object
 *
 */
typedef void (^UpdateRSSIBlock)(PeripheralProxy* peripheral);

@interface PeripheralProxy : NSObject
{
    NSMutableDictionary*    _services;  //!< Discovered ServiceProxy objects keyed on UUID.  This needs to be populated by child implementation.
}

//! Unique Identifier of peripheral
@property (nonatomic, readonly) CBUUID* UUID;

//! Name of peripheral.  Base implementation returns "No Name"
@property (nonatomic, readonly) NSString* name;

//! Is the peripheral connected.  Base implementation returns NO.
@property (nonatomic, readonly) BOOL isConnected;

//! Implementation source type.  Base implementation returns kPeripheralSource_Unknown.
@property (nonatomic, readonly) PeripheralSourceType type;

//! Signal strength value.  Base implementation returns -110.
@property (nonatomic, readonly) int RSSI;

//! Time stamp (seconds since 1970) since advertisement packet from this peripheral received.  Base implementation returns 0.
@property (nonatomic, readonly) NSTimeInterval discoveredTime;

/*!
 *  \brief Look up ServiceProxy by UUID
 *
 *  Searches the discovered services for a value with the specified UUID
 *
 *  \param  serviceId   UUID of desired service
 *
 *  \return The service if it has been discovered or nil
 */
-(ServiceProxy*) findService:(CBUUID*)serviceId;

/*!
 *  \brief Looks up CharacteristicProxy for charId in ServiceProxy for serviceId
 *
 *  Searches the discovered services for the service with UUID serviceId and then 
 *  searches discovered characteristics in that service for the characteristic with UUID charId
 *
 *  \param  charId  UUID of desired characteristic
 *  \param  serviceId   UUID of service that should contain the desired characteristic
 *
 *  \return The characteristic if it has been discovered or nil if either it or the service 
 *          hasn't been discovered
 */
-(CharacteristicProxy*) findCharacteristic:(CBUUID*)charId forService:(CBUUID*)serviceId;

/*!
 *  \brief  Initiates discovery of requested serviceIds.
 *
 *  Base implementation does nothing but store the selector/target objects.
 *  The service discovery needs to be implemented in the child class.  
 *  The child implementation should call the super implementation unless they want to handle the callback storage themselves
 *
 *  \note   If the services have already been discovered the implementation may not discover anything 
 *          and findService: should be used instead.
 *
 *  \note   This method calls loadServices:foundSelector:completeSelector:target:.  Child class implementations should only 
 *          override loadServices:foundSelector:completeSelector:target: to prevent possible issues.
 *
 *  \param  serviceIds  Array of CBUUID objects of services to discover or nil if all available services should be discovered.
 *  \param  found   Selector to call for each discovered service.  Can be nil.
 *  \param  target  Target object to call found selector on.  If nil then no callbacks called.
 *
 */
-(void) loadServices:(NSArray*)serviceIds foundSelector:(SEL)found target:(id<NSObject>)target;

/*!
 *  \brief  Initiates discovery of requested serviceIds.
 *
 *  Base implementation does nothing but store the selector/target objects.
 *  The service discovery needs to be implemented in the child class.
 *  The child implementation should call the super implementation unless they want to handle the callback storage themselves
 *
 *  \note   If the services have already been discovered the implementation may not discover anything
 *          and findService: should be used instead.
 *
 *  \param  serviceIds  Array of CBUUID objects of services to discover or nil if all available services should be discovered.
 *  \param  found   Selector to call for each discovered service.  Can be nil.
 *  \param  complete    Selector to call once all discovered services have been processed.  Can be nil.
 *  \param  target  Target object to call found selector on.  If nil then no callbacks called.
 *
 */
-(void) loadServices:(NSArray *)serviceIds foundSelector:(SEL)found completeSelector:(SEL)complete target:(id<NSObject>)target;

/*!
 *  \brief  Initiates discovery of requested serviceIds.
 *
 *  Base implementation does nothing but store the block pointer.
 *  The service discovery needs to be implemented in the child class.
 *  The child implementation should call the super implementation unless they want to handle the callback storage themselves
 *
 *  \note   If the services have already been discovered the implementation may not discover anything
 *          and findService: should be used instead.
 *
 *  \note   This method calls loadServices:foundBlock:completeBlock:.  Child class implementations should only
 *          override loadServices:foundBlock:completeBlock: to prevent possible issues.
 *
 *  \param  serviceIds  Array of CBUUID objects of services to discover or nil if all available services should be discovered.
 *  \param  block   The block called for each discovered service.  Can be nil.
 *
 */
-(void) loadServices:(NSArray *)serviceIds foundBlock:(FoundServiceBlock)block;

/*!
 *  \brief  Initiates discovery of requested serviceIds.
 *
 *  Base implementation does nothing but store the block pointer.
 *  The service discovery needs to be implemented in the child class.
 *  The child implementation should call the super implementation unless they want to handle the callback storage themselves
 *
 *  \note   If the services have already been discovered the implementation may not discover anything
 *          and findService: should be used instead.
 *
 *  \param  serviceIds  Array of CBUUID objects of services to discover or nil if all available services should be discovered.
 *  \param  foundBlock   The block called for each discovered service.  Can be nil.
 *  \param  completeBlock   The block called after all discovered services have been processed.  Can be nil.
 *
 */
-(void) loadServices:(NSArray *)serviceIds foundBlock:(FoundServiceBlock)foundBlock completeBlock:(FoundServiceCompleteBlock)completeBlock;

/*!
 *  \brief  Method that is called by child class for each discovered service
 *
 *  This method serves only as a way for child classes to fire off the registered callbacks for service
 *  discovery in their various loadServices... methods.
 *
 *  \note   This method should not be called anywhere other than child classes
 *
 *  \param  service ServiceProxy object of discovered service
 *
 */
-(void) foundService:(ServiceProxy*)service;

/*!
 *  \brief  Method that is called by child class once service discovery has completed
 *
 *  This method serves only as a way for child classes to fire off the registered callbacks for service
 *  discovery completion in their various loadServices... methods.
 *
 *  \note   This method should not be called anywhere other than child classes
 *
 */
-(void) foundServiceCompleted;

/*!
 *  \brief Initiates request for RSSI signal update
 *
 *  The base implementation only stores the target/selector pointers which are called from 
 *  RSSIUpdated.
 *
 *  \param  selector    Selector called when RSSI value has been updated.
 *  \param  target      Target object selector is called on once RSSI value is updated.
 *
 */
-(void) updateRSSI:(SEL)selector target:(id<NSObject>)target;

/*!
 *  \brief Initiates request for RSSI signal update
 *
 *  The base implementation only stores the block pointer which is called from
 *  RSSIUpdated.
 *
 *  \param  block   Block callback pointer that is called when RSSI value is updated
 *
 */
-(void) updateRSSI:(UpdateRSSIBlock)block;

/*!
 *  \brief Method that is called by child class once RSSI update request has completed
 *
 *  This method serves only as a way for child classes to fire off the the registered callback for 
 *  RSSI update.
 *
 *  \note   This method should not be called anywhere other than child classes
 *
 */
-(void) RSSIUpdated;

/*!
 *  \brief Performs clean up upon peripheral disconnection
 *
 *  This method does not perform the actual disconnect but rather cleans up the peripheral data once it has
 *  disconnected.
 *
 *  \note   The actual disconnection should be initiated by whatever object is managing the child implementation of PeripheralProxy.
 *          For instance the BLEManager handles the Core Bluetooth calls for disconnecting a BLEPeripheral and once the peripheral disconnection
 *          is confirmed calls disconnect on the BLEPeripheral.
 */
-(void) disconnect;

@end

