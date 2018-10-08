//
//  NSString+StringToHex.m
//  Kestrel
//
//  Created by Michael Nannini on 3/1/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

#import "NSString+HexString.h"

@implementation NSString (StringToHex)

-(NSData*) hexToBytes
{
    NSMutableData* data = [NSMutableData data];
 
    int idx;
    for (idx = 0; idx+2 <= self.length; idx+=2) {
        NSRange range = NSMakeRange(idx, 2);
        NSString* hexStr = [self substringWithRange:range];
        NSScanner* scanner = [NSScanner scannerWithString:hexStr];
        unsigned int intValue;
        [scanner scanHexInt:&intValue];
        [data appendBytes:&intValue length:1];
    }
 
    return data;
     
}

@end
