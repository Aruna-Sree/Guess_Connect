//
//  NSString+StringToHex.h
//  Kestrel
//
//  Created by Michael Nannini on 3/1/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (HexString)

-(NSData*) hexToBytes;
@end
