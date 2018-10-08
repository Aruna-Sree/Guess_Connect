//
//  TDDeviceProfile.m
//  Timex Connected
//
//  Created by Lev Verbitsky on 9/12/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

#import "TDDeviceProfile.h"
#import "TimexWatchDB.h"

@implementation TDDeviceProfile


@synthesize deviceType;

- (id)init
{
	if (self = [super init])
	{

    }
    
    return self;
}

- (id)initWithDeviceType:(TDDeviceType)type
{
	if (self = [super init])
	{
        deviceType = type;
    }
    
    return self;
}

@end
