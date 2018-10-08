//
//  TDWatchProfile.m
//  Timex Connected
//
//  Created by Lev Verbitsky on 6/19/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

#import "TDWatchProfile.h"
#import "TimexWatchDB.h"
#import "TDDefines.h"
#import "OTLogUtil.h"

#define ROW_COUNT @"rowCount"
#define WATCH_BACKUP @"watchBackup"

@implementation TDWatchProfile

@synthesize workoutManager = _workoutManager;
@synthesize watchStyle = _watchStyle;
@synthesize watchName = _watchName;
@synthesize mKey = _mKey;
@synthesize activeProfile = _activeProfile;

static TDWatchProfile * instance = nil;

+(id) sharedInstance
{
	if (!instance)
	{
		instance = [[[self class] alloc] init];
	}
	
	return instance;
}

+(void) resetSharedInstance
{
	instance = nil;
}

- (id) init
{
	if (self = [super init])
	{
        _mKey = KEY_UNKNOWN;
        _watchStyle = timexDatalinkWatchStyle_Unselected;
        _activeProfile = TRUE;
    }
    
    return self;
}

-(void)setRowCount:(NSInteger)values
{
    [[NSUserDefaults standardUserDefaults] setInteger:values forKey:ROW_COUNT];
}
+(NSInteger)rowCount
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:ROW_COUNT];
}
-(void)setWatchBackup:(NSDictionary*)values
{
    [[NSUserDefaults standardUserDefaults] setObject:values forKey:WATCH_BACKUP];
}
-(NSDictionary*)watchBackup
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:WATCH_BACKUP];
}

-(void)databaseRecover
{
    NSDictionary *recover = [self watchBackup];
    _mKey = (long)[recover objectForKey:@"rowID"];
    _watchName = [recover objectForKey:@"WatchName"];
    _watchStyle = (timexDatalinkWatchStyle)(long)[recover objectForKey:@"WatchStyle"];
    _activeProfile = (BOOL)(long)[recover objectForKey:@"ProfileActive"];
    [self commitChangesToDatabase];
}

-(TDWorkoutDataManager *) workoutManager
{
    if (_workoutManager == nil)
        _workoutManager = [[TDWorkoutDataManager alloc] init];
    
    return _workoutManager;
}
- (NSInteger) loadProfileForStyle: (timexDatalinkWatchStyle) style statusUpdateCode:(void (^)(float))update
{
    int result = kLoadResult_OK;

    [self.workoutManager clearData];
    
	NSString * expression = [NSString stringWithFormat:@"SELECT Profiles.rowID AS profrowid, Profiles.WatchName, Profiles.WatchStyle, Profiles.ProfileActive, Workouts.rowID AS workoutsrowid FROM Profiles LEFT OUTER JOIN Workouts ON Profiles.rowID = Workouts.WatchID WHERE Profiles.WatchStyle = %d;", style];
    
    TimexDatalink::IDBQuery * query = [[TimexWatchDB sharedInstance] createQuery : expression];
	
    if (query)
    {
        if (query->getRowCount() > 0)
        {
            _mKey = query->getIntColumnForRow(0, @"profrowid");
            
            _watchName = query->getStringColumnForRow(0, @"WatchName");
            _watchStyle = (timexDatalinkWatchStyle)query->getIntColumnForRow(0, @"WatchStyle");
            _activeProfile = query->getIntColumnForRow(0, @"ProfileActive");
            
            //when loading workouts, check for how long workouts should be stored in history... if any of workouts
            //are beyond their expiration date, chuck'em
            
            NSString * key = [iDevicesUtil createKeyForAppSettingsPropertyWithClass: appSettings_PropertyClass_Workouts andIndex: appSettings_PropertyClass_Workouts_StoreHistory];
            
            appSettings_PropertyClass_Workouts_StoreHistoryEnum historyStorageSetting = appSettings_PropertyClass_Workouts_StoreHistory_All;
            if ([[NSUserDefaults standardUserDefaults] objectForKey: key] == nil)
            {
                [[NSUserDefaults standardUserDefaults] setInteger: appSettings_PropertyClass_Workouts_StoreHistory_All forKey: key];
            }
            historyStorageSetting = (appSettings_PropertyClass_Workouts_StoreHistoryEnum)[[NSUserDefaults standardUserDefaults] integerForKey: key];
            
            NSDate * workoutHistoryCutoffDate = [NSDate date];
            NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier: NSCalendarIdentifierGregorian];
            NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
            
            switch (historyStorageSetting)
            {
                case appSettings_PropertyClass_Workouts_StoreHistory_OneMonth:
                    [offsetComponents setMonth: -1];
                    break;
                case appSettings_PropertyClass_Workouts_StoreHistory_SixMonths:
                    [offsetComponents setMonth: -6];
                    break;
                case appSettings_PropertyClass_Workouts_StoreHistory_OneYear:
                    [offsetComponents setYear: -1];
                    break;
                case appSettings_PropertyClass_Workouts_StoreHistory_TwoYears:
                    [offsetComponents setYear: -2];
                    break;
                default:
                    break;
            };
            
            workoutHistoryCutoffDate = [gregorian dateByAddingComponents:offsetComponents toDate: workoutHistoryCutoffDate options: 0];
            
            //process the workout data
            NSInteger totalWorkouts = query->getRowCount();
            for (int x = 0; x < totalWorkouts; x++)
            {
                //send the update back to the caller, if callback is provided
                if (update != NULL)
                {
                    float progress = x / (float)totalWorkouts;
                    update(progress);
                }
                
                NSInteger workoutID = query->getIntColumnForRow(x, @"workoutsrowid");
                
                if (workoutID)
                {
                    TDWorkoutData * workoutInstance = _watchStyle == timexDatalinkWatchStyle_ActivityTracker ? [[TDWorkoutDataActivityTracker alloc] initWithWatchID: _mKey] : [[TDWorkoutData alloc] initWithWatchID: _mKey];
                    [workoutInstance load: workoutID];
                    
                    if (historyStorageSetting == appSettings_PropertyClass_Workouts_StoreHistory_All || [[workoutInstance workoutDate] compare: workoutHistoryCutoffDate] != NSOrderedAscending)
                    {
                        [self.workoutManager addWorkout: workoutInstance resortWorkouts: FALSE]; //will be resorted at the end, for speed
                    }
                    else
                    {
                        //this workout is OLD! Beyond the history limit specified by the user. Bad, bad stuff.... get rid of it permanently.
                        [workoutInstance destroy];
                    }
                }
            }
            //don't forget to re-sort!!!!
            [[[TDWatchProfile sharedInstance] workoutManager] resortWorkoutsByCurrentSortType];
        }
        delete query;
    }
    
    _watchStyle = [iDevicesUtil getActiveWatchProfileStyle];
    
	return result;
}

- (BOOL) checkForInactiveProfileMatchingSelectedWatchStyle
{
    BOOL profileFound = FALSE;
    NSString * expression = [NSString stringWithFormat: @"SELECT * FROM Profiles WHERE WatchStyle = %d AND ProfileActive = 0;", _watchStyle];
    TimexDatalink::IDBQuery * query = [[TimexWatchDB sharedInstance] createQuery : expression];
    
    if (query)
    {
        if (query->getRowCount() > 0)
        {
            OTLog(@"Updating Profile inactive");
            //there in an inactive profile! Assume it's identity:
            _mKey = query->getIntColumnForRow(0, @"rowID");
            _watchName = query->getStringColumnForRow(0, @"WatchName");
            _watchStyle = (timexDatalinkWatchStyle)query->getIntColumnForRow(0, @"WatchStyle");
            _activeProfile = TRUE;
            NSString * expressionUpdate = [NSString stringWithFormat:@"UPDATE Profiles SET WatchName = '%@', WatchStyle = %d, ProfileActive = %d WHERE rowID = %ld;", _watchName, _watchStyle, _activeProfile, (long)_mKey];
            
            TimexDatalink::IDBQuery * queryUpdate = [[TimexWatchDB sharedInstance] createQuery : expressionUpdate];
            if (queryUpdate)
            {
                profileFound = TRUE;
                delete queryUpdate;
            }
            
            [self createBackupDB];
        }
        
        delete query;
    }
    return profileFound;
}

- (void) commitChangesToDatabase
{
    
    if (_mKey != KEY_UNKNOWN)
	{
        OTLog(@"Updating Profile Changes");
        NSString * expression = [NSString stringWithFormat:@"UPDATE Profiles SET WatchName = '%@', WatchStyle = %d, ProfileActive = %d WHERE rowID = %ld;", [[self watchName] stringByReplacingOccurrencesOfString: @"'" withString: @"''"], _watchStyle, _activeProfile, (long)_mKey];
        
        TimexDatalink::IDBQuery * query = [[TimexWatchDB sharedInstance] createQuery : expression];
		if (query)
		{
			delete query;
            
            for (TDWorkoutData * current in [[self workoutManager] workouts])
            {
                //if there is a workout that hasn't been saved to the DB yet or is not associated with this profile yet, save it
                if ([current mKey] == KEY_UNKNOWN || [current watchProfileID] != _mKey)
                {
                    [current setWatchProfileID: _mKey]; // Watch profile
//                    [current setMKey:KEY_UNKNOWN]; // Row ID for workout Data. Not to be set here.
                    [current commitChangesToDatabase];
                }
            }
		}
	}
	else
	{
        if (![self watchName])
        {
            [self setWatchName: NSLocalizedString(@"Undefined", nil)];
        }
        
		NSString * expressionNew = [NSString stringWithFormat:@"INSERT INTO Profiles ('WatchName', 'WatchStyle', 'ProfileActive') VALUES ('%@',%d, %d);", [[self watchName] stringByReplacingOccurrencesOfString: @"'" withString: @"''"], _watchStyle, _activeProfile];
		TimexDatalink::IDBQuery * query = [[TimexWatchDB sharedInstance] createQuery : expressionNew];
		if (query)
		{
			TimexDatalink::IDBQuery * queryID = [[TimexWatchDB sharedInstance] createQuery : @"SELECT last_insert_rowid();"];
			if (queryID)
			{
				_mKey = queryID->getUIntColumnForRow(0, (uint)0);
				delete queryID;
                
                //store backup
                [self setRowCount:1];
                
                //add workouts to the appropriate tables:
                for (TDWorkoutData * current in [[self workoutManager] workouts])
                {
                    [current setWatchProfileID: _mKey];
                    
                    [current commitChangesToDatabase];
                }
			}
			
			delete query;
		}
	}
    
    [self createBackupDB];
}

- (void)createBackupDB
{
    if (_watchName == nil)
    {
        _watchName = @"unknown";
    }
    NSDictionary *backup = @{
                             @"rowID" : [NSNumber numberWithLong:_mKey],
                             @"WatchName" : _watchName,
                             @"WatchStyle" : [NSNumber numberWithInt:_watchStyle],
                             @"ProfileActive" : [NSNumber numberWithBool:_activeProfile]
                             };
    [self setWatchBackup:backup];
}

@end
