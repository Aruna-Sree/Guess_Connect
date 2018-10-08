//
//  TDM372WatchActivity.h
//  Timex
//
//  Created by Lev Verbitsky on 6/8/15.
//  Copyright (c) 2015 iDevices, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TDM372WatchActivity : NSObject


- (id) init;
- (id) init: (NSData *) inData;
- (void) recordActivityData;
@end
