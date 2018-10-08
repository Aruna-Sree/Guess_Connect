//
//  CharacteristicProxy.h
//  HeartRateMonitor
//
//  Created by Michael Nannini on 1/16/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

/*!
 *  \class  CharacteristicProxy
 *
 *  \brief  Base class / interface defining generic characteristic object.
 *
 *  CharacteristicProxy defines a generic base class for Characteristic objects based on Core Bluetooth API.
 *  CharacteristicProxy handles management of callbacks and notifications for read and write requests.
 *  CharacteristicProxy also defines getters for characteristic related data that need to be implented in child classes.
 *
 *  \note Classes that need to store references to CharacteristicProxy objects should use weak referencing.
 *
 */
#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "ServiceProxy.h"

@class CharacteristicProxy;

/*!
 *  \typedef void CharacteristicValueUpdateCompleteBlock
 *  
 *  Block pointer signature definition for data update callback.
 *  Argument type for CharacteristicProxy::updateValue:
 *
 *  \param  characteristic  Characteristic that has been updated
 */
typedef void (^CharacteristicValueUpdateCompleteBlock)(CharacteristicProxy* characteristic);

/*!
 *  \typedef void CharacteristicValueUpdateCompleteWithErrorBlock
 *
 *  Block pointer signature definition for data update callback.
 *  Argument type for CharacteristicProxy::updateValue:
 *
 *  \param  characteristic  Characteristic that has been updated
 *  \param  error           Error
 */
typedef void (^CharacteristicValueUpdateCompleteWithErrorBlock)(CharacteristicProxy* characteristic, NSError* error);


/*!
 *  \typedef void CharacteristicValueWriteCompleteBlock
 *
 *  Block pointer signature definition for write complete callback
 *  Argument type for CharacteristicProxy::writeValue:responseBlock:
 *
 *  \param  characteristic  Characteristic that has been written to
 */
typedef void (^CharacteristicValueWriteCompleteBlock)(CharacteristicProxy* characteristic);

/*!
 *  \typedef void CharacteristicValueWriteCompleteWithErrorBlock
 *
 *  Block pointer signature definition for write complete callback
 *  Argument type for CharacteristicProxy::writeValue:responseBlock:
 *
 *  \param  characteristic  Characteristic that has been written to
 *  \param  error           Error or nil if no error occurred.
 */
typedef void (^CharacteristicValueWriteCompleteWithErrorBlock)(CharacteristicProxy* characteristic, NSError* error);

@interface CharacteristicProxy : NSObject
{
    //! Reference to owning service object
    ServiceProxy*  __weak  _service;
    //TODO: Descriptors
    
    
}

//! UUID of characterisitc.  Base implementation returns nil.
@property (nonatomic, readonly) CBUUID* UUID;

//! Characteristic's data.  Base implementation returns nil.
@property (nonatomic, readonly) NSData* value;

//! Reference to owning service.
@property (nonatomic, readonly) ServiceProxy* service;

//! Characteristic property flags.  Base implementation returns 0.
@property (nonatomic, readonly) NSUInteger  properties;

/*!
 *  \brief  Initiates characteristic data update request.
 *
 *  Base implementation manages completion callback pointers. 
 *  Child implementation is responsible for initiating the actual update request.
 *  Child implemntation should call super implentation unless it wants to handle
 *  callback management.
 *
 *  \note   Multiple target selector pairs can be queued with successive calls.
 *          All targets and selectors are then cleared after value is updated.
 *
 *  \param  completion  Selector that is called when the value is updated
 *  \param  completionTarget    Object that the selector is called on
 */
-(void) updateValue:(SEL)completion target:(id<NSObject>)completionTarget;

/*!
 *  \brief  Initiates characteristic data update request.
 *  
 *  Base implementation manages completion callback pointers.
 *  Child implementation is responsible for initiating the actual update request.
 *  Child implementation should call super implementation unless it wants to handle
 *  callback management.
 *
 *  \note   Multiple blocks can be queued with successive calls.
 *          All blocks are then cleared after value is updated.
 *
 *  \param  completionBlock     Block called when value is updated
 */
-(void) updateValue:(CharacteristicValueUpdateCompleteBlock)completionBlock;

/*!
 *  \brief  Initiates characteristic data update request.  This version supports error handling
 *
 *  Base implementation manages completion callback pointers.
 *  Child implementation is responsible for initiating the actual update request.
 *  Child implementation should call super implementation unless it wants to handle
 *  callback management.
 *
 *  \note   Multiple blocks can be queued with successive calls.
 *          All blocks are then cleared after value is updated.
 *
 *  \param  completionBlock     Block called when value is updated
 */
-(void) updateValueWithError:(CharacteristicValueUpdateCompleteWithErrorBlock)completionBlock;


/*!
 *  \brief  Method called by child classes when value has been updated
 *
 *  This method serves only as a way for the class handling characteristic operations to fire the update callbacks.
 *
 *  Calls all the listening selectors/blocks that were registered and then clears them out
 *  Also notifies observers.
 *  
 *  \note   This method should not be called anywhere other the class that is handling
 *          read responses
 */
-(void) valueUpdated;

/*!
 *  \brief  Method called by child classes when value has been updated
 *
 *  This method serves only as a way for the class handling characteristic operations to fire the update callbacks.
 *
 *  Calls all the listening selectors/blocks that were registered and then clears them out
 *  Also notifies observers.
 *
 *  \note   This method should not be called anywhere other the class that is handling
 *          read responses
 *  \param  error   Error returned by update or nil
 */

-(void) valueUpdatedWithError:(NSError*)error;

/*!
 *  \brief  Registers an observer that is notified when the characteristic value is updated.
 *
 *  Adds a target selector pair that is called when the value updates
 *  Useful for characteristics that allow notify.
 *  Unlike updateValue methods, the observer and selector are not cleared after the
 *  value update is caught
 *
 *  \note   Multiple observers can be registered
 *
 *  \param  observer    Object selector is called on
 *  \param  selector    Selector that is called when value is updated
 */
-(void) addValueObserver:(NSObject *)observer withSelector:(SEL)selector;

/*!
 *  Removes a target selector pair that is called when the value updates
 *
 *  \param  observer    Object to remove from observer list.  If nil then nothing happens.
 *  \param  selector    Selector used to filter which entries to remove.  If nil then all entries for
 *                      observer are removed.
 */
-(void) removeValueObserver:(NSObject*)observer forSelector:(SEL)selector;

/*!
 *  \brief  Enable or disable notification of characteristic
 *
 *  Toggle the property notifications on/off if the characteristic supports notify.
 *  The notification will be received by valueUpdated
 *  The base implementation does nothing.
 *
 *  \param  enable  YES or NO.  If Characteristic doesn't support Notify then it is moot.
 */
-(void) enableNotification:(BOOL)enable;

/*!
 *  \brief  Initiates write request without callback
 *
 *  Base implementation calls writeValue:response:target: with nil for response and target.
 *
 *  \note Child implementation should only override implentation of writeValue:response:target: to prevent issues.
 *
 *  \param  newValue    value to write to characteristic
 */
-(void) writeValue:(NSData*)newValue;

/*!
 *  \brief  Initiates a write request with a callback
 *
 *  Base implementation only stores the selector/target pairs.
 *  Child implenentation is responsible for initiating the actual write request
 *  
 *  \note   If the characteristic does not support write responses these may not get called
 *
 *  \param  newValue    Value to write to characteristic
 *  \param  selector    Selector to call when write is completed
 *  \param  target      Object selector is called on
 */
-(void) writeValue:(NSData*)newValue response:(SEL)selector target:(id<NSObject>)target;

/*!
 *  \brief  Initiates a write request with a callback
 *
 *  Base implementation only stores the response block
 *  Child implenentation is responsible for initiating the actual write request
 *
 *  \note   If the characteristic does not support write responses these may not get called
 *
 *  \param  newValue    Value to write to characteristic
 *  \param  responseBlock   Block to call when write is completed
 */
-(void) writeValue:(NSData*)newValue responseBlock:(CharacteristicValueWriteCompleteBlock)responseBlock;

/*!
 *  \brief  Initiates a write request with a callback
 *
 *  Base implementation only stores the response block
 *  Child implenentation is responsible for initiating the actual write request
 *
 *  \note   If the characteristic does not support write responses these may not get called
 *
 *  \param  newValue                    Value to write to characteristic
 *  \param  responseWithErrorBlock      Block to call when write is completed
 */
-(void) writeValue:(NSData*)newValue responseWithErrorBlock:(CharacteristicValueWriteCompleteWithErrorBlock)responseBlock;

/*!
 *  \brief Method called by child class when write response is received
 *
 *  This method serves only as a way for the class handling characteristic operations to fire the write callbacks.
 *
 *  \note   This method should not be called anywhere other the class that is handling
 *          write responses
 */
-(void) writeCompleted DEPRECATED_ATTRIBUTE;

/*!
 *  \brief Method called by child class when write response is received
 *
 *  This method serves only as a way for the class handling characteristic operations to fire the write callbacks.
 *
 *  \note   This method should not be called anywhere other the class that is handling
 *          write responses
 *
 *  \param  error   Write error if one is received, or nil
 */

-(void) writeCompletedWithError:(NSError*)error;

/*!
 *  \brief  Converts characteristic data to string
 *  
 *  Convenience method for converting characteristic data to NSString instance.
 *  This assumes the data is a character array of UTF-8 encoding.
 *
 *  \note   If the string encoding is not UTF-8 the results are undefined.
 */
-(NSString*) stringValueFromUTF8;

@end
