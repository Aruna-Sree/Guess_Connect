//
//  TDFlurryDataPacket.h
//  Timex Connected
//
//  Created by Lev Verbitsky on 7/2/14.
//  Copyright (c) 2014 iDevices, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TDFlurryDataPacket : NSDictionary
{
    NSMutableDictionary * _dict;
}

- (id) initWithValue:(id)value forKey:(NSString *)key;
- (void)setValue:(id)value forKey:(NSString *)key;
@end
