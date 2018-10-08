//
//  TDFlurryDataPacket.m
//  Timex Connected
//
//  Created by Lev Verbitsky on 7/2/14.
//  Copyright (c) 2014 iDevices, LLC. All rights reserved.
//

#import "TDFlurryDataPacket.h"
#import "iDevicesUtil.h"
#import "TDWatchProfile.h"

@implementation TDFlurryDataPacket

- (id) init
{
    if (self = [super init])
    {
        _dict = [[NSMutableDictionary alloc] init];
        
        NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
        NSString *build = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
        
        [_dict setValue: version forKey: @"App_Version"];
        [_dict setValue: build forKey: @"App_Build_Number"];
        [_dict setValue: [iDevicesUtil convertWatchStyleToProductName: [[TDWatchProfile sharedInstance] watchStyle]] forKey: @"Watch_Product"];
    }
    
    return self;
}

- (id) initWithValue:(id)value forKey:(NSString *)key
{
    if (self = [self init])
    {
        [_dict setValue: value forKey: key];
    }
    
    return self;
}

- (NSUInteger)count
{
    return [_dict count];
}
- (id)objectForKey:(id)aKey
{
    return [_dict objectForKey:aKey];
}
- (id)valueForKey:(id)aKey
{
    return [_dict valueForKey: aKey];
}
- (NSEnumerator *)keyEnumerator
{
    return [_dict keyEnumerator];
}
- (void)setValue:(id)value forKey:(NSString *)key
{
    [_dict setValue: value forKey: key];
}
@end
