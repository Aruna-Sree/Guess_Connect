//
//  TDWatchProfile.h
//  Timex Connected
//
//  Created by Lev Verbitsky on 6/19/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TDWorkoutDataManager.h"
#import "iDevicesUtil.h"

@interface TDWatchProfile : NSObject

@property (nonatomic) NSInteger  mKey;
@property (nonatomic, strong) TDWorkoutDataManager * workoutManager;
@property (nonatomic, strong) NSString * watchName;
@property (nonatomic) timexDatalinkWatchStyle watchStyle;
@property (nonatomic) BOOL activeProfile;

+ (id)              sharedInstance;
+ (void)            resetSharedInstance;
- (id)              init;
- (NSInteger)       loadProfileForStyle: (timexDatalinkWatchStyle) style statusUpdateCode:(void (^)(float))update;
- (BOOL)            checkForInactiveProfileMatchingSelectedWatchStyle;
- (void)            commitChangesToDatabase;
+ (NSInteger)       rowCount;
- (void)            databaseRecover;
@end
