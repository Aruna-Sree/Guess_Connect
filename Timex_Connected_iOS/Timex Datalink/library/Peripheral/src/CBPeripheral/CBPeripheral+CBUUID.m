//
//  CBPeripheral+CBUUID.m
//  Peripheral
//
//  Created by Michael Nannini on 12/11/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

#import "CBPeripheral+CBUUID.h"
#import <objc/runtime.h>
#import <UIKit/UIKit.h>

static const char kCBUUIDKey;

@interface CBPeripheral (CBPeripheral_CBUUID)

-(CFUUIDRef) UUID;

@end

@implementation CBPeripheral (CBUUID)

-(CBUUID*) CBUUID
{
    CBUUID* result = objc_getAssociatedObject(self, &kCBUUIDKey);
    
    if ( result == nil )
    {

        if ( [self respondsToSelector:@selector(identifier)] )
        {
            result = [CBUUID UUIDWithNSUUID:self.identifier];
        }
        else if ( [self respondsToSelector:@selector(UUID)] && [self UUID] )
        {
            result = [CBUUID UUIDWithCFUUID:[self UUID]];
        }
        
        if ( result )
        {
            objc_setAssociatedObject(self, &kCBUUIDKey, result, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    }
    
    return result;
}

@end
