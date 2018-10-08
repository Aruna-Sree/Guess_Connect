//
//  DBManager.h

#import <Foundation/Foundation.h>
#import "DBActivity+CoreDataClass.h"
#import "DBSleepEvents.h"
#import "ActivityModal.h"
#import "SleepEventsModal.h"
#import "DBHourActivity+CoreDataClass.h"
#import "HourActivityModal.h"

@interface DBManager : NSObject

+ (void) addOrUpdateActivityEntities:(NSArray *)activityMockArr;

+ (void) addOrUpdateSleepEventsArray:(NSArray *)sleepEventsMockArr;

+ (DBSleepEvents *) addOrUpdateSleepEvent:(SleepEventsModal *)item;

+ (DBActivity *) addOrUpdateActivity:(ActivityModal *)activityMock;

+ (DBHourActivity *) addOrUpdateHourActivity:(HourActivityModal *)activityHrMock;

+ (void) deleteAll;

+ (void)saveTotalSleep:(DBActivity *)activity;
@end
