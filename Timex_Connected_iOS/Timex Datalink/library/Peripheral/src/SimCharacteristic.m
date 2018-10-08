//
//  SimCharacteristic.m
//  Wahooo
//
//  Created by Michael Nannini on 1/28/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

#import "SimCharacteristic.h"

@interface SimCharacteristic ()
{
    CBUUID*     _uuid;
    NSData*     _data;
    BOOL        _notify;
    id<SimCharacteristicDelegate> __weak _delegate;
    
    NSUInteger  _properties;
}

@end

@implementation SimCharacteristic

@synthesize delegate=_delegate;
@synthesize data=_data;

-(id) initWithUUID:(CBUUID*)uuid
{
    self = [super init];
    
    if ( self )
    {
        _uuid = [uuid copy];
        _notify = NO;
    }
    
    return self;
}

-(id) initWithUUID:(CBUUID*)uuid andValue:(NSData*)data
{
    self = [super init];
    
    if ( self )
    {
        _uuid = [uuid copy];
        
        _data = [data copy];
    
    }
    
    return self;
    
}

-(void) setService:(ServiceProxy *)service
{
    _service = service;
}

-(void) setProperties:(NSUInteger) props
{
    _properties = props;
}


-(void) updateValue:(CharacteristicValueUpdateCompleteBlock)completionBlock
{
    [super updateValue:completionBlock];
    
    //[self valueUpdated];
    
    [self performSelector:@selector(valueUpdated) withObject:nil afterDelay:0.5];
}

-(void) updateValueWithError:(CharacteristicValueUpdateCompleteWithErrorBlock)completionBlock
{
    [super updateValueWithError:completionBlock];
    
    //[self valueUpdated];
    
    [self performSelector:@selector(valueUpdated) withObject:nil afterDelay:0.5];
    
}


-(void) updateValue:(SEL)completion target:(id<NSObject>)completionTarget
{
    [super updateValue:completion target:completionTarget];
    
    //[self valueUpdated];
    
    [self performSelector:@selector(valueUpdated) withObject:nil afterDelay:0.5];
}


-(void) writeValue:(NSData *)newValue response:(SEL)selector target:(id<NSObject>)target
{
    [super writeValue:newValue response:selector target:target];
    
    NSError* error = nil;
    
    if( _delegate && [_delegate respondsToSelector:@selector(simCharacteristic:simulateWriteWithData:)] )
    {
        error = [_delegate simCharacteristic:self simulateWriteWithData:newValue];
    }
    
    if ( error == nil )
    {
        _data = [newValue copy];
        
    }
    
    [self performSelector:@selector(writeCompletedWithError:) withObject:error afterDelay:0.01];
    
    if( error == nil )
    {
        if ( _notify )
        {
            [self performSelector:@selector(valueUpdated) withObject:nil afterDelay:0.5];
        }
        
        if ( _delegate && [_delegate respondsToSelector:@selector(simCharacteristic:didWriteValue:)] )
        {
            [_delegate simCharacteristic:self didWriteValue:newValue];
        }
    }

}

-(void) writeValue:(NSData *)newValue responseBlock:(CharacteristicValueWriteCompleteBlock)responseBlock
{
    [super writeValue:newValue responseBlock:responseBlock];
    
    NSError* error = nil;
    
    if( _delegate && [_delegate respondsToSelector:@selector(simCharacteristic:simulateWriteWithData:)] )
    {
        error = [_delegate simCharacteristic:self simulateWriteWithData:newValue];
    }
    
    if( error == nil )
    {
        _data = [newValue copy];
    }
    
    [self performSelector:@selector(writeCompletedWithError:) withObject:error afterDelay:0.01];
    
    if( error == nil )
    {
        if ( _notify )
        {
            [self performSelector:@selector(valueUpdated) withObject:nil afterDelay:0.5];
        }

        
        if ( _delegate && [_delegate respondsToSelector:@selector(simCharacteristic:didWriteValue:)] )
        {
            [_delegate simCharacteristic:self didWriteValue:newValue];
        }
    }

}

-(void) writeValue:(NSData *)newValue responseWithErrorBlock:(CharacteristicValueWriteCompleteWithErrorBlock)responseBlock
{
    [super writeValue:newValue responseWithErrorBlock:responseBlock];
    
    NSError* error = nil;
    
    if( _delegate && [_delegate respondsToSelector:@selector(simCharacteristic:simulateWriteWithData:)] )
    {
        error = [_delegate simCharacteristic:self simulateWriteWithData:newValue];
    }
    
    if( error == nil )
    {
        _data = [newValue copy];
    }
    
    [self performSelector:@selector(writeCompletedWithError:) withObject:error afterDelay:0.01];
    
    if( error == nil )
    {
        if ( _notify )
        {
            [self performSelector:@selector(valueUpdated) withObject:nil afterDelay:0.5];
        }
        
        
        if ( _delegate && [_delegate respondsToSelector:@selector(simCharacteristic:didWriteValue:)] )
        {
            [_delegate simCharacteristic:self didWriteValue:newValue];
        }
    }
    
}


-(void) enableNotification:(BOOL)enable
{
    _notify = enable;
}

-(void) setData:(NSData *)data
{
    _data = [data copy];
    
    [self valueUpdated];
}

-(NSData*) value
{
    return _data;
}

-(CBUUID*) UUID
{
    return _uuid;
}

@end
