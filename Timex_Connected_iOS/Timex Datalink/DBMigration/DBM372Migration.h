//
//  DBM372Migration.h
//  timex
//
//  Created by Aruna Kumari Yarra on 20/09/16.
//  Copyright © 2016 iDevices, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DBM372Migration : NSObject

+ (void)getActivityDataAndAddToCoreData;
+ (void)setGoals;
+ (void)setWatchIDForAllEntitiesINCoreData;
@end
