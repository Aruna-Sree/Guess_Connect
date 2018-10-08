//
//  TargetSelectorPair.h
//  Peripheral
//
//  Created by Michael Nannini on 9/9/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TargetSelectorPair : NSObject

@property (nonatomic, assign) SEL selector;
@property (nonatomic, weak)   id<NSObject> target;


@end
