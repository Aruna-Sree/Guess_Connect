//
//  BLECharacteristic.h
//  HeartRateMonitor
//
//  Created by Michael Nannini on 1/16/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

#import "CharacteristicProxy.h"

/*!
 *  \class  BLECharacteristic
 *
 *  \brief  Core Bluetooth implementation of CharacteristicProxy
 *
 *  The main responsibility of this class is to initiate the read/write calls
 *  to CBPeripheral that contains the CBCharacteristic instance contained 
 *  in this class.
 */

@interface BLECharacteristic : CharacteristicProxy
{
    //! Wrapped instance of CBCharacteristic
    CBCharacteristic*       _characteristic;
}

//! Reference to contained characteristic object
@property (nonatomic, readonly) CBCharacteristic* cbCharacteristic;

/*!
 *  \brief  Initializer that takes the CBCharacteristic to wrap
 *
 *  \param  characteristic  Characteristic object to wrap.
 *
 *  \return Initialized instance of BLECharacteristic
 */
-(id) initWithCharacteristic:(CBCharacteristic*)characteristic;

/*!
 *  \brief  Sets the service object that owns this characteristic
 * 
 *  \param  service The service object that owns this characteristic
 */
-(void) setService:(ServiceProxy*)service;

@end
