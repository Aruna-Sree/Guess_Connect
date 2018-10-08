//
//  BatteryService.h
//  Wahooo
//
//  Created by Michael Nannini on 2/5/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PeripheralProxy.h"

@class BatteryService;

@protocol BatteryServiceDelegate <NSObject>

-(void) batteryService:(BatteryService*)service batteryLevelUpdated:(NSInteger)level;

@end


@interface BatteryService : NSObject
{
    id<BatteryServiceDelegate>  __weak _delegate;
    
}

@property (nonatomic, readonly) NSInteger batteryLevel;

@property (nonatomic, weak) id<BatteryServiceDelegate> delegate;

+(CBUUID*) batteryServiceID;

+(CBUUID*) batteryLevelID;

-(void) setPeripheral:(PeripheralProxy*)peripheral;

-(void) readBatteryLevel;

-(void) enableBatterLevelNotify:(BOOL)enable;



@end
