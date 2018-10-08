//
//  NSData+AES128.h
//  Wahooo
//
//  Created by Michael Nannini on 7/29/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (AES128)

- (NSData *)AES128EncryptWithKey:(NSData *)key;

@end
