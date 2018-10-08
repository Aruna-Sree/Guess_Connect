//
//  CharacteristicProxy.m
//  HeartRateMonitor
//
//  Created by Michael Nannini on 1/16/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

#import "CharacteristicProxy.h"
#import "TargetSelectorPair.h"
#import "PeripheralUtility.h"

@interface CharacteristicValueUpdateCompleteBlockWrapper : NSObject

@property (nonatomic, strong) CharacteristicValueUpdateCompleteBlock block;

@end

@implementation CharacteristicValueUpdateCompleteBlockWrapper

@synthesize block;

@end

//****************************************************************************************
//****************************************************************************************

@interface CharacteristicValueUpdateCompleteWithErrorBlockWrapper : NSObject

@property (nonatomic, strong) CharacteristicValueUpdateCompleteWithErrorBlock block;

@end

@implementation CharacteristicValueUpdateCompleteWithErrorBlockWrapper

@synthesize block;

@end

//****************************************************************************************
//****************************************************************************************

@interface CharacteristicValueWriteCompleteBlockWrapper : NSObject

@property (nonatomic, strong) CharacteristicValueWriteCompleteBlock block;

@end

@implementation CharacteristicValueWriteCompleteBlockWrapper

@synthesize block;

@end

//****************************************************************************************
//****************************************************************************************


@interface CharacteristicValueWriteCompleteWithErrorBlockWrapper : NSObject

@property (nonatomic, strong) CharacteristicValueWriteCompleteWithErrorBlock block;

@end

@implementation CharacteristicValueWriteCompleteWithErrorBlockWrapper

@synthesize block;

@end

//****************************************************************************************
//****************************************************************************************

@interface CharacteristicProxy ()
{
    NSMutableArray*     _updateValueSelectorPairs;
    NSMutableArray*     _updateValueBlocks;
    
    NSMutableArray*     _writeResponsePairs;
    NSMutableArray*     _writeResponseBlocks;
    
    NSMutableArray*     _notifySelectorPairs;
    
    
}

@end

@implementation CharacteristicProxy


-(id) init
{
    self = [super init];
    
    if ( self )
    {
        _updateValueBlocks = [[NSMutableArray alloc] init];
        _updateValueSelectorPairs = [[NSMutableArray alloc] init];
        _writeResponsePairs = [[NSMutableArray alloc] init];
        _writeResponseBlocks = [[NSMutableArray alloc] init];
        _notifySelectorPairs = [[NSMutableArray alloc] init];
    }
    
    return self;
}


-(CBUUID*) UUID
{
    return nil;
}

-(NSData*) value
{
    return nil;
}

-(ServiceProxy*) service
{
    return _service;
}

-(NSUInteger) properties
{
    return 0;
}

-(void) updateValue:(SEL)completion target:(id<NSObject>)completionTarget
{
    // The base implementation simply adds the selector and target to the array of completion observers
    // Don't bother storing if no target or selector passed
    if ( completionTarget && completion )
    {
        TargetSelectorPair* pair = [[TargetSelectorPair alloc] init];
        pair.selector = completion;
        pair.target = completionTarget;
        
        [_updateValueSelectorPairs addObject:pair];
    }
}

-(void) updateValue:(CharacteristicValueUpdateCompleteBlock)completionBlock
{
    // The base implementation only adds the block to the update listeners
    if ( completionBlock )
    {
        CharacteristicValueUpdateCompleteBlockWrapper* wrapper = [[CharacteristicValueUpdateCompleteBlockWrapper alloc] init];
        
        wrapper.block = completionBlock;
        
        [_updateValueBlocks addObject:wrapper];
    }
}

-(void) updateValueWithError:(CharacteristicValueUpdateCompleteWithErrorBlock)completionBlock
{
    // The base implementation only adds the block to the update listeners
    if ( completionBlock )
    {
        CharacteristicValueUpdateCompleteWithErrorBlockWrapper* wrapper = [[CharacteristicValueUpdateCompleteWithErrorBlockWrapper alloc] init];
        
        wrapper.block = completionBlock;
        
        [_updateValueBlocks addObject:wrapper];
    }
    
}

-(void) valueUpdated
{
    [self valueUpdatedWithError:nil];
}

-(void) valueUpdatedWithError:(NSError*)error
{
    NSMutableArray* blocks = [_updateValueBlocks copy];
    NSMutableArray* pairs = [_updateValueSelectorPairs copy];
    
    [_updateValueSelectorPairs removeAllObjects];
    [_updateValueBlocks removeAllObjects];


    if ( pairs.count > 0 )
    {
        
        for( TargetSelectorPair* pair in pairs )
        {
            // target is weak, so if the target has been released since the
            // update request was made this will be nil
            if( pair.target != nil )
            {
                [pair.target performSelector:pair.selector withObject:self withObject:error];
            }
        }
    }
    
    if ( blocks.count > 0 )
    {
        
        for ( NSObject* block in blocks )
        {
            if ( [block isKindOfClass:[CharacteristicValueUpdateCompleteBlockWrapper class]] )
            {
                ((CharacteristicValueUpdateCompleteBlockWrapper*)block).block(self);
            }
            else if ( [block isKindOfClass:[CharacteristicValueUpdateCompleteWithErrorBlockWrapper class]] )
            {
                ((CharacteristicValueUpdateCompleteWithErrorBlockWrapper*)block).block(self, error);
            }

        }
        
    }

    // Notify observers
    if ( _notifySelectorPairs.count > 0 )
    {
        NSArray* obersvers = [_notifySelectorPairs copy];
        
        for( TargetSelectorPair* pair in obersvers )
        {
            if( pair.target == nil )
            {
                [_notifySelectorPairs removeObject:pair];
            }
            else
            {
                [pair.target performSelector:pair.selector withObject:self withObject:error];
            }
        }
    }
}

-(void) addValueObserver:(NSObject *)observer withSelector:(SEL)selector
{
    if ( observer && selector)
    {
        TargetSelectorPair* pair = [[TargetSelectorPair alloc] init];
        pair.target = observer;
        pair.selector = selector;
        
        [_notifySelectorPairs addObject:pair];
    }
}


-(void) removeValueObserver:(NSObject*)observer forSelector:(SEL)selector
{
    NSArray* observers = [_notifySelectorPairs copy];
    
    for( TargetSelectorPair* pair in observers )
    {
        BOOL remove = NO;
        
        if ( pair.target == nil || pair.selector == nil )
        {
            remove = YES;
        }
        else if ( pair.target == observer )
        {
            if ( selector == nil || selector == pair.selector )
            {
                remove = YES;
            }
        }

        if ( remove )
        {
            [_notifySelectorPairs removeObject:pair];
        }
            
    }
}


-(void) enableNotification:(BOOL)enable
{
    
}


-(void) writeValue:(NSData*)newValue
{
    [self writeValue:newValue response:nil target:nil];
}


-(void) writeValue:(NSData*)newValue response:(SEL)selector target:(id<NSObject>)target
{
    if ( selector && target )
    {
        TargetSelectorPair* pair = [[TargetSelectorPair alloc] init];
        pair.target = target;
        pair.selector = selector;
        
        [_writeResponsePairs addObject:pair];
    }
}


-(void) writeValue:(NSData*)newValue responseBlock:(CharacteristicValueWriteCompleteBlock)responseBlock
{
    if ( responseBlock )
    {
        CharacteristicValueWriteCompleteBlockWrapper* wrapper = [[CharacteristicValueWriteCompleteBlockWrapper alloc] init];
        
        wrapper.block = responseBlock;
        
        [_writeResponseBlocks addObject:wrapper];
    }
}

-(void) writeValue:(NSData*)newValue responseWithErrorBlock:(CharacteristicValueWriteCompleteWithErrorBlock)responseBlock
{
    if ( responseBlock )
    {
        CharacteristicValueWriteCompleteWithErrorBlockWrapper* wrapper = [[CharacteristicValueWriteCompleteWithErrorBlockWrapper alloc] init];
        
        wrapper.block = responseBlock;
        
        [_writeResponseBlocks addObject:wrapper];
    }
}

-(void) writeCompleted
{
    [self writeCompletedWithError:nil];
}

-(void) writeCompletedWithError:(NSError*)error
{
    NSArray* pairs = [_writeResponsePairs copy];
    NSArray* blocks = [_writeResponseBlocks copy];
    
    [_writeResponsePairs removeAllObjects];
    [_writeResponseBlocks removeAllObjects];
    
    if ( pairs.count > 0 )
    {
     
        for ( TargetSelectorPair* pair in pairs )
        {
            if ( pair.target && pair.selector )
            {
                [pair.target performSelector:pair.selector withObject:self withObject:error];
            }
        }
        
    }
    
    if ( blocks.count > 0 )
    {
        
        for( NSObject* block in blocks )
        {
            if ( [block isKindOfClass:[CharacteristicValueWriteCompleteBlockWrapper class]] )
            {
                ((CharacteristicValueWriteCompleteBlockWrapper*)block).block(self);
            }
            else if ( [block isKindOfClass:[CharacteristicValueWriteCompleteWithErrorBlockWrapper class]] )
            {
                ((CharacteristicValueWriteCompleteWithErrorBlockWrapper*)block).block(self, error);
            }

        }
    }

}

-(NSString*) stringValueFromUTF8
{
    NSString* string = nil;
    
    if ( self.value && self.value.length > 0 )
    {
        string = [PeripheralUtility utf8StringFromData:self.value];
    }
    
    return string;
}

@end
