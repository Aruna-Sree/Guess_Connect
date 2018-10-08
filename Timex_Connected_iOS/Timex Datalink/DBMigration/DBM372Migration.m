//
//  DBM372Migration.m
//  timex
//
//  Created by Aruna Kumari Yarra on 20/09/16.
//  Copyright © 2016 iDevices, LLC. All rights reserved.
//

#import "DBM372Migration.h"
#import "TimexWatchDB.h"
#import "DBActivity+CoreDataClass.h"
#import "DBModule.h"
#import "ActivityModal.h"
#import "DBManager.h"
#import "TDDefines.h"
#import "TDAppDelegate.h"

@implementation DBM372Migration

+ (void)getActivityDataAndAddToCoreData {
    NSMutableArray *dbModalObjsArray = [[NSMutableArray alloc] init];
    NSMutableArray *activitiesArray = [[NSMutableArray alloc] init];
    NSString * expression = [NSString stringWithFormat: @"SELECT * FROM ActivityData WHERE WorkoutID IS NULL AND LapID IS NULL"];
    TimexDatalink::IDBQuery * query = [[TimexWatchDB sharedInstance] createQuery : expression];
    if (query)
    {
        NSInteger rowCount = query->getRowCount();
        if (rowCount > 0)
        {
            for (int i = 0; i < rowCount; i++ )
            {
                NSTimeInterval date = query->getDoubleColumnForRow(i, @"ActivityDate");
                NSDate * activityDate = [NSDate dateWithTimeIntervalSince1970: date];
                NSNumber * steps = [NSNumber numberWithInt: query->getIntColumnForRow(i, @"ActivitySteps")];
                NSNumber * cal = [NSNumber numberWithInt: query->getIntColumnForRow(i, @"ActivityCalories")];
                NSNumber * dis = [NSNumber numberWithInt: query->getIntColumnForRow(i, @"ActivityDistance")];
                DBActivity *activity = (DBActivity*)[[DBModule sharedInstance]getEntity:@"DBActivity" columnName:@"date" value:activityDate];
                if (activity != nil) {
                    activity.steps = steps;
                    activity.distance = dis;
                    activity.calories = cal;
                    [activitiesArray addObject:activity];
                } else {
                    ActivityModal *modal  = [[ActivityModal alloc] init];
                    modal.date = activityDate;
                    modal.steps = steps;
                    modal.distance = dis;
                    modal.calories = cal;
                    modal.sleep = [NSNumber numberWithDouble:0];
                    [dbModalObjsArray addObject:modal];
                }
            }
        }
        delete query;
    }
    
    if (dbModalObjsArray.count > 0) {
        [DBManager addOrUpdateActivityEntities:dbModalObjsArray];
    }
    
    if (activitiesArray.count > 0) {
        [[DBModule sharedInstance] saveContext];
    }
    
    NSString * deleteActivityExpression = [NSString stringWithFormat:@"DELETE FROM ActivityData WHERE WorkoutID IS NULL AND LapID IS NULL"];
    TimexDatalink::IDBQuery * activityDeleteQuery = [[TimexWatchDB sharedInstance] createQuery : deleteActivityExpression];
    if (activityDeleteQuery)
        delete activityDeleteQuery;
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:@"1" forKey:M372_MIGRATION_DONE];
    
    [userDefaults setObject:@"0" forKey:M372_SLEEP_REFRESH_MIGRATION]; // To read all sleep epochs
}
+ (void)setGoals {
    TDAppDelegate *delegate = (TDAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSString *sqlStatement = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS M328_Goals (rowID INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, calories INTEGER, distance INTEGER,steps INTEGER, sleepTime INTEGER, type INTEGER);"];
    TimexDatalink::IDBQuery * query = [[TimexWatchDB sharedInstance] createQuery : sqlStatement];
    if (query) {
        [delegate setupDummyGoals];
    }
    
    NSString * stepskey = [iDevicesUtil createKeyForAppSettingsPropertyWithClass: appSettingsM372_PropertyClass_Goals andIndex: appSettingsM372_PropertyClass_Goals_Steps];
    NSInteger steps = [[NSUserDefaults standardUserDefaults] integerForKey: stepskey];
    
    NSString * diskey = [iDevicesUtil createKeyForAppSettingsPropertyWithClass: appSettingsM372_PropertyClass_Goals andIndex: appSettingsM372_PropertyClass_Goals_Distance];
    NSInteger distance = [[NSUserDefaults standardUserDefaults] integerForKey: diskey];
    
    NSString * calkey = [iDevicesUtil createKeyForAppSettingsPropertyWithClass: appSettingsM372_PropertyClass_Goals andIndex: appSettingsM372_PropertyClass_Goals_Calories];
    NSInteger calories = [[NSUserDefaults standardUserDefaults] integerForKey: calkey];
    
    NSString *hrskey = [iDevicesUtil createKeyForAppSettingsPropertyWithClass: appSettingsM372_PropertyClass_Goals andIndex: appSettingsM372_PropertyClass_Goals_Sleep];
    [[NSUserDefaults standardUserDefaults] setInteger: 80 forKey: hrskey];
    NSInteger hrsSleep = [[NSUserDefaults standardUserDefaults] integerForKey: hrskey];
        
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    
    NSMutableDictionary *goal = [NSMutableDictionary dictionary];
    [goal setValue:[NSNumber numberWithDouble:steps] forKey: STEPS];
    [goal setValue:[NSNumber numberWithDouble:distance/100.0f] forKey: DISTANCE];
    [goal setValue:[NSNumber numberWithDouble:calories/10.0f] forKey: CALORIES];
    [goal setValue:[NSNumber numberWithDouble:hrsSleep/10.0f] forKey: SLEEPTIME];
    
    [def setInteger:steps       forKey:stepskey];
    [def setInteger:distance    forKey:diskey];
    [def setInteger:calories    forKey:calkey];
    [def setInteger:hrsSleep    forKey:hrskey];
    [def setValue:goal forKey:GOAL_TYPE_CUSTOM];
    [def setInteger:Custom forKey:@"GoalType"];
    [def synchronize];
    
}
+ (void)setWatchIDForAllEntitiesINCoreData {
    NSString * storedUUID = [iDevicesUtil getWatchID];
    NSArray *array;
    if (storedUUID != nil) {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setObject:@"1" forKey:WATCHID_COREDATA_MIGRATION_DONE];
        array = [[DBModule sharedInstance] getAllRecordsForEntityToUpdateWatchID:@"DBActivity"];
        for (DBActivity *activity in array) {
            activity.watchID = storedUUID;
        }
        
        array = [[DBModule sharedInstance] getAllRecordsForEntityToUpdateWatchID:@"DBSleepEvents"];
        for (DBSleepEvents *activity in array) {
            activity.watchID = storedUUID;
        }
        
        array = [[DBModule sharedInstance] getAllRecordsForEntityToUpdateWatchID:@"DBHourActivity"];
        for (DBSleepEvents *activity in array) {
            activity.watchID = storedUUID;
        }
        [[DBModule sharedInstance] saveContext];
    }
}
@end
