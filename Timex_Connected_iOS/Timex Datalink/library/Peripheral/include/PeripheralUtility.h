//
//  PeripheralUtility.h
//  Wahooo
//
//  Created by Michael Nannini on 2/5/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PeripheralProxy.h"

/*!
 *  \class PeripheralUtility
 *  \brief  Helper method class
 */
@interface PeripheralUtility : NSObject

/*!
 *  \brief  Converts hexadecimal formatted string to NSNumber (with uint64 backing)
 *
 *  \param  strVal  String representaiton of hexadecimal number
 *
 *  \return NSNumber instance containing uint64 value or nil if string is not a valid hexadecimal number
 */
+(NSNumber*) hexStringToNumber:(NSString*)strVal;

/*!
 *  \brief  Helper method for discovering/finding characteristics within a service.
 *
 *  Requests characteristics to be discovered from a service, passing the found selector and target.
 *  If characteristics are already discovered they are still passed to the found selector.
 *
 *  \param  charIds     Array of CBUUIDs of the characteristics to discover or nil if all 
 *                      characteristics should be discovered.
 *  \param  service     Service instance to discover characteristics for
 *  \param  found       Selector to call for each "discovered" characteristics
 *  \param  target      Object ot call found selector on
 *
 */
+(void) loadCharacteristics:(NSArray*)charIds fromService:(ServiceProxy*)service foundSelector:(SEL)found target:(id)target;

/*!
 *  \brief  Converts data containing UTF-8 string into an NSString
 *
 *  \param  data    Data to convert
 *
 *  \return Converted string.
 */
+(NSString*) utf8StringFromData:(NSData*)data;

/*!
 *  \brief  Converts hexadecimal string to data bytes
 *
 *  The string is processed two characteris at a time starting with the first character.
 *  The result is an array of bytes ordered the same way the appear
 *  in the string.
 *
 *  ###Example:###
 *  The string "DEADBEEF" would result in the bytes {0xDE, 0xAD, 0xBE, 0xEF}
 *
 *  \param  string  String to convert
 *
 *  \return Data containing the converted bytes
 */
+(NSData*) hexStringToBytes:(NSString*)string;


+(NSString*) cbuuidToString:(CBUUID*)uuid;


@end
