//
//  Resources.h
//  SleepTrackerFilesTool
//
//  Created by Diego Santiago on 3/10/16.
//  Copyright © 2016 Diego Santiago. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TDResources : NSObject

- (void) dumpData:(NSData *)data;
- (int) byteArrayToInt: (Byte *) b;
- (NSDate *) getActivityDate:(Byte)day month:(Byte)month year:(Byte)year;
- (NSDate *) getActivityDateDetail:(Byte)day month:(Byte)month year:(Byte)year hour:(Byte)hour minute:(Byte)minute;
- (NSDate *) getActivityDateYearTwo:(Byte)day month:(Byte)month year:(Byte)year;




@end
