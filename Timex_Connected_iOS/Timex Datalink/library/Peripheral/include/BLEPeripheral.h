//
//  BLEPeripheral.h
//  HeartRateMonitor
//
//  Created by Michael Nannini on 1/16/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

/*!
 *  \class BLEPeripheral
 *
 *  \brief Core Bluetooth implementation of PeripheralProxy.
 *
 *  Class wraps calls to CBPeripheral
 *  Instances of this class also double as the CBPeripheralDelegate of the wrapper peripheral instance.
 *  Relevant delegate calls are forwarded to contained services and characteristics.
 *
 */
#import "PeripheralProxy.h"

@interface BLEPeripheral : PeripheralProxy <CBPeripheralDelegate>
{
    //! Wrapped instance of CBPeripheral
    CBPeripheral*    _peripheral;
}

//! Reference to contained CBPeripheral instance
@property (nonatomic, readonly) CBPeripheral*   cbPeripheral;

/*!
 *  \brief Initializer that takes peripheral object
 *
 *  \param  peripheral Core Bluetooth object operations will be performed on.
 *
 *  \return Initialized instance of BLEPeripheral
 */
-(id) initWithPeripheral:(CBPeripheral*)peripheral;

/*!
 *  \brief Returns key based on CBPeripheral instance. 
 *  Used as alternative key if CBPeripheral's UUID is nil which can occur pre-iOS 7
 *  if the peripheral hasn't been connected to this device yet (or after iOS device settings are reset)
 *
 *  \return Unique-ish key based on the contained CBPeripheral instance
 */
-(NSString*) unknownKey;

/*!
 *  \brief Static method that returns a key string based on the passed CBPeripheral instance.
 *  Used as alternative key if CBPeripheral's UUID is nil which can occur pre-iOS 7
 *  if the peripheral hasn't been connected to this device yet (or after iOS device settings are reset)
 *
 *  \param  peripheral  Peripheral object to generate key from
 *
 *  \return Unique-ish key based on the contained CBPeripheral instance
 */
+(NSString*) unknownKey:(CBPeripheral*)peripheral;

/*!
 *  \brief  Set the time stamp (seconds since 1970) of the last time
 *          this peripheral sent advertising data
 *
 *  \param  time    Time advertising data was received
 */
-(void) setDiscoveredTime:(NSTimeInterval)time;

@end
