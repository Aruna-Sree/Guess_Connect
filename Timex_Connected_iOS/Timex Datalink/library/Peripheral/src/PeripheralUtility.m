//
//  PeripheralUtility.m
//  Wahooo
//
//  Created by Michael Nannini on 2/5/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

#import "PeripheralUtility.h"
#import "ServiceProxy.h"
#import "CharacteristicProxy.h"

@implementation PeripheralUtility

+(NSNumber*) hexStringToNumber:(NSString*)strVal
{
    NSString* processString = strVal;
    
    if ( [strVal hasPrefix:@"0x" ])
    {
        processString = [strVal stringByReplacingOccurrencesOfString:@"0x" withString:@""];
    }
    
    uint64_t sum = 0;
    NSUInteger len = processString.length;
    
    for( int i = 0; i < len; i++ )
    {
        unichar c = [processString characterAtIndex:i];
        short digit = 0;
        
        switch ( c )
        {
            case '0':
                break;
                
            case '1':
            case '2':
            case '3':
            case '4':
            case '5':
            case '6':
            case '7':
            case '8':
            case '9':
                digit = c - '0';
                break;
                
            case 'A':
            case 'B':
            case 'C':
            case 'D':
            case 'E':
            case 'F':
                digit = c - 'A' + 10;
                break;
                
            case 'a':
            case 'b':
            case 'c':
            case 'd':
            case 'e':
            case 'f':
                digit = c - 'a' + 10;
                break;
                
            default:
                //Invalid hex character
                return nil;
                break;

        }

        sum <<= 4;
        sum += (digit & 0x000F);

    }
    
    return [NSNumber numberWithUnsignedLongLong:sum];
}

+(void) loadCharacteristics:(NSArray*)charIds fromService:(ServiceProxy*)service foundSelector:(SEL)found target:(id)target
{
    NSMutableArray* needToLoad = [charIds mutableCopy];
    
    
    for( CBUUID* currId in charIds )
    {
        CharacteristicProxy* currentChar = [service findCharacteristic:currId];
        
        if ( currentChar )
        {
            [target performSelector:found withObject:currentChar];
            
            [needToLoad removeObject:currId];
        }
    
    }
    
    if ( needToLoad.count > 0 )
    {
        [service loadCharacteristics:needToLoad foundSelector:found target:target];
    }
}

+(NSString*) utf8StringFromData:(NSData*)data
{
    
    size_t strLen = strnlen((char*)data.bytes, data.length);

    NSString* string = [[NSString alloc] initWithBytes:data.bytes length:strLen encoding:NSUTF8StringEncoding];
    
    return string;
}

+(NSData*) hexStringToBytes:(NSString*)string
{
    NSMutableData* data = [NSMutableData data];
    
    int idx;
    for (idx = 0; idx+2 <= string.length; idx+=2) {
        NSRange range = NSMakeRange(idx, 2);
        NSString* hexStr = [string substringWithRange:range];
        NSScanner* scanner = [NSScanner scannerWithString:hexStr];
        unsigned int intValue;
        [scanner scanHexInt:&intValue];
        [data appendBytes:&intValue length:1];
    }
    
    return data;
    
}

+(NSString*) cbuuidToString:(CBUUID*)uuid
{
    
    NSData *data = [uuid data];
    
    NSUInteger bytesToConvert = [data length];
    const unsigned char *uuidBytes = [data bytes];
    NSMutableString *outputString = [NSMutableString stringWithCapacity:16];
    
    for (NSUInteger currentByteIndex = 0; currentByteIndex < bytesToConvert; currentByteIndex++)
    {
        switch (currentByteIndex)
        {
            case 3:
            case 5:
            case 7:
            case 9:[outputString appendFormat:@"%02x-", uuidBytes[currentByteIndex]]; break;
            default:[outputString appendFormat:@"%02x", uuidBytes[currentByteIndex]];
        }
        
    }
    
    return outputString;
}


@end
