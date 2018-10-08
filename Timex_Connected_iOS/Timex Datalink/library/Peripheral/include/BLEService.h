//
//  BLEService.h
//  HeartRateMonitor
//
//  Created by Michael Nannini on 1/16/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

#import "ServiceProxy.h"

/*!
 *  \class  BLEService
 *  
 *  \brief  Core Bluetooth implementation for ServiceProxy
 *  
 *  BLEService wraps the Core Bluetooth calls to discover characteristics
 *  and handles storing the discovered characteristics.
 *  
 */

@interface BLEService : ServiceProxy
{
    //! Wrapped instance of CBService
    CBService*      _service;
}

//! Reference to contained service object
@property (nonatomic, readonly) CBService* cbService;

/*!
 *  \brief Initializer that takes CBService object
 *
 *  \param  service Service object to wrap
 *
 *  \return Initialized instance of BLEService
 */
-(id) initWithService:(CBService*)service;

/*!
 *  \brief  Retrieves the discovered characteristics from CBService object
 *
 *  For each CBCharacteristic found a BLECharacteristic is created and added to the 
 *  characteristic dictionary.
 *
 *  \note   This method shouldn't be called directly
 */
-(void) loadDiscoveredCharacteristics;

/*!
 *  \brief Sets the peripheral object that contains this service
 *
 *  \note   This method shouldn't be called directly
 *
 *  \param  peripheral  Peripheral that owns this service
 */
-(void) setPeripheral:(PeripheralProxy*)peripheral;

@end
