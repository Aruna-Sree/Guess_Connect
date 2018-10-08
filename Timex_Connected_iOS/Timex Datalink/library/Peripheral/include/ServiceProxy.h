//
//  ServiceProxy.h
//  HeartRateMonitor
//
//  Created by Michael Nannini on 1/16/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

/*!
 *  \class ServiceProxy
 *  
 *  \brief Base class / interface defining a generic service object.
 *
 *  ServiceProxy defines a generic base class for Service objects based on the Core Bluetooth API.  
 *  ServiceProxy handles management of Characteristic discovery callbacks and storing CharacteristicProxy objects.
 *
 *  \note Classes that need to store references to ServiceProxy objects should use weak referencing and test stored pointers
 *  to make sure they are valid before using.
 *
 */

#import <Foundation/Foundation.h>
#import "PeripheralProxy.h"

@class CharacteristicProxy;

/*!
 *  \typedef void FoundCharacteristicBlock
 *
 *  Block pointer signature definition of callback for when a characteristic has been discovered.
 *  Argument type in ServiceProxy::loadCharacteristics:foundBlock:
 *
 *  \param characteristic   The characteristic that was discovered.
 *
 */
typedef void (^FoundCharacteristicBlock)(CharacteristicProxy* characteristic);

@interface ServiceProxy : NSObject
{    
    NSMutableDictionary*    _includedServices;  //!< Discovered ServiceProxy objects of included services keyed on UUID.  This needs to be populated by child implementation.
    NSMutableDictionary*    _characteristics;   //!< Discovered CharacteristicProxy objects keyed on UUID.  This needs to be populated by child implementation
    PeripheralProxy* __weak _peripheral;        //!< Reference to owning peripheral object
}

//! Unique Identifier of Service.  Base implementation returns nil.
@property (nonatomic, readonly) CBUUID* UUID;

//! Reference to owning peripheral object
@property (nonatomic, readonly) PeripheralProxy* peripheral;

/*!
 *  \brief  Lookup CharacteristicProxy by UUID
 *
 *  Searches for a discovered CharacteristicProxy by UUID.
 *
 *  \param  characteristicId    UUID of characteristic to find
 *
 *  \return The CharacteristicProxy with the specified UUID or nil if the characteristic
 *          hasn't been discovered or isn't part of this service.
 */
-(CharacteristicProxy*) findCharacteristic:(CBUUID*)characteristicId;

/*!
 *  \brief  Lookup included ServiceProxy by UUID
 *
 *  Searches for a discovered included ServiceProxy by UUID
 *
 *  \param  serviceId   UUID of included service to find.
 *
 *  \return The ServiceProxy with the specified UUID or nil if the service isn't discovered
 *          or isn't an included service for this service.
 */
-(ServiceProxy*) findIncludedService:(CBUUID*)serviceId;


/*!
 *  \brief Initiates discovery of requested characteristics
 *
 *  Base implementation does nothing but stores the selector/target pointers.
 *  Child implementation is responsible for the actual characterisitc discovery.
 *  The child implementation should call the super implementation unless it wants to handle the callback pointers itself.
 *
 *  \note   If the characteristics have already been discovered this method may not do anything.
 *          findCharacteristic: should be used to determine if the characteristic has already been discovered.
 *
 *  \param  characteristicIds   Array of UUIDs of the desired characteristics to discover or nil 
 *                              if all available characteristics should be discovered.
 *  \param  selector            Selector to call for each discovered characteristic
 *  \param  target              Object to call selector on for each discovered characteristic
 *
 */
-(void) loadCharacteristics:(NSArray*)characteristicIds foundSelector:(SEL)selector target:(id<NSObject>)target;

/*!
 *  \brief Initiates discovery of requested characteristics
 *
 *  Base implementation does nothing but stores the block pointer.
 *  Child implementation is responsible for the actual characterisitc discovery.
 *  The child implementation should call the super implementation unless it wants to handle the callback pointer itself.
 *
 *  \note   If the characteristics have already been discovered this method may not do anything.
 *          findCharacteristic: should be used to determine if the characteristic has already been discovered.
 *
 *  \param  characteristicIds   Array of UUIDs of the desired characteristics to discover or nil
 *                              if all available characteristics should be discovered.
 *  \param  block               The block to call for each discovered characteristic
 *
 */
-(void) loadCharacteristics:(NSArray *)characteristicIds foundBlock:(FoundCharacteristicBlock)block;

/*!
 *  \brief Method called by child classes for each discovered characterisitc
 *
 *  This method serves only as a way for child implementations to fire off the 
 *  discovered characteristic callback from their various loadCharacteristics... methods.
 *
 *  \note   This method should not be called anywhere other than child classes.
 *
 */
-(void) foundCharacteristic:(CharacteristicProxy*)characteristic;

@end
