//
//  PCCommandInfo.h
//  Timex Connected
// iOS Developer
//  Created by Lev Verbitsky on 1/20/14.
//  Copyright (c) 2014 iDevices, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PCCommBaseClass.h"

@interface PCCCommandInfo : PCCommBaseClass

- (BOOL) isResponse;
- (BOOL) isMultiPacket;
- (BOOL) isNack;
@end
