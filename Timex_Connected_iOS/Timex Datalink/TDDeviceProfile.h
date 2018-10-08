//
//  TDDeviceProfile.h
//  Timex Connected
//
//  Created by Lev Verbitsky on 9/12/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TDDevice.h"
#import "TDDefines.h"

@interface TDDeviceProfile : NSObject
{
    TDDeviceType            deviceType;
}

@property (nonatomic) TDDeviceType deviceType;

- (id)              initWithDeviceType:(TDDeviceType) type;

@end