//
//  NSData+AES128.m
//  Wahooo
//
//  Created by Michael Nannini on 7/29/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

#import "NSData+AES128.h"
#import <CommonCrypto/CommonCrypto.h>

@implementation NSData (AES128)


- (NSData *)AES128EncryptWithKey:(NSData *)key {
    if ([key length] != kCCKeySizeAES128) {
        NSLog(@"AES128EncryptWithKey: keySize invalid for AES128");
        return nil;
    }
    
	NSUInteger dataLength = [self length];
    size_t bufferSize = 16; // hardcode to 16 bytes for kCCOptionECBMode
    void *buffer = malloc(bufferSize);
    
	size_t numBytesEncrypted = 0;
	CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt, kCCAlgorithmAES128, kCCOptionECBMode,
										  [key bytes], kCCKeySizeAES128,
										  NULL /* initialization vector (optional) */,
										  [self bytes], dataLength, /* input */
										  buffer, bufferSize, /* output */
										  &numBytesEncrypted);
	
	if (cryptStatus == kCCSuccess) {
		//the returned NSData takes ownership of the buffer and will free it on deallocation
		return [NSData dataWithBytesNoCopy:buffer length:numBytesEncrypted];
	} else {
        NSLog(@"CCCrypt FAILED with cryptStatus = %d", cryptStatus);
    }
	
	free(buffer); //free the buffer;
	return nil;
}


@end
