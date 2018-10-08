//
//  TDAppDelegate.m
//  Timex Connected
//
//  Created by Lev Verbitsky on 6/18/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

#import "TDAppDelegate.h"
#import "MFSideMenuContainerViewController.h"
#import "iDevicesUtil.h"
#import "PeripheralDevice.h"
#import "TDWatchProfile.h"
#import "TDDefines.h"
#import "Flurry.h"
#import "TDHomeViewController.h"
#import "TDDeviceManager.h"
#import "OTLogUtil.h"
#import <HockeySDK/HockeySDK.h>
#import "DBModule.h"
#import "TimerViewController.h"
#import "TDM328WatchSettingsUserDefaults.h"

#import "ActivityModal.h"
#import "SleepEventsModal.h"
#import "DBM372Migration.h"
#import "DBManager.h"
#import "TimexWatchDB.h"
#import "WelcomeViewController.h"
#define FlurryKey @"QPY7BB34W5WKZ8W5Z9XG"

@interface TDAppDelegate ()
{
    NSDate *timeDown;
}
           
@end

@implementation TDAppDelegate
@synthesize alertView;
- (TDHomeViewController *)IQMoveMainController {
        
    TDHomeViewController *mainControllerIQMove;
    
    mainControllerIQMove = [[TDHomeViewController alloc]initWithNibName:@"TDHomeViewController" bundle:nil doFirmwareCheck:TRUE initialSync:YES];
    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)
    {
        mainControllerIQMove = [[TDHomeViewController alloc]initWithNibName:@"TDTravelHomeViewController" bundle:nil doFirmwareCheck:TRUE initialSync:YES];
    }
    return mainControllerIQMove;
    
}
- (UIViewController *)welcomeViewController {
//    [self.navigationController.navigationBar setFrame:CGRectMake(0, 0, self.view.frame.size.width, 65)];
    [self resetUserDefaults];
    [[TDWatchProfile sharedInstance] setWatchStyle: timexDatalinkWatchStyle_IQ];
    [[TimexWatchDB sharedInstance] augmentExistingDatabaseForM053];
    OTLog([NSString stringWithFormat:@"You select: %u",timexDatalinkWatchStyle_IQ]);
    
    UIViewController *welcomeViewCOntroller = [[WelcomeViewController alloc] initWithNibName:@"WelcomeViewController" bundle:nil];
    return welcomeViewCOntroller;
}
- (UINavigationController *)navigationController {
    UINavigationController *navViewController;
    timexDatalinkWatchStyle existingStyle = [iDevicesUtil getActiveWatchProfileStyle];
    OTLog(@"Getting watch active profile presence is %d in Didfinishlaunching",[iDevicesUtil checkForActiveProfilePresence]);
    //TestLog_SleepTrackerImplementation
    if ((existingStyle == timexDatalinkWatchStyle_IQ || existingStyle == timexDatalinkWatchStyle_IQTravel) && [iDevicesUtil checkForActiveProfilePresence]) {
        navViewController = [[UINavigationController alloc] initWithRootViewController:[self IQMoveMainController]];
    } else {
        navViewController = [[UINavigationController alloc] initWithRootViewController:[self welcomeViewController]];
    }
    
    [self setNavigationBarSettingsForM328:navViewController];
    
    [[TDDeviceManager sharedInstance] getBleManager];
    
    return navViewController;
}

- (void)resetUserDefaults {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults removeObjectForKey:@USERID_USERDEFAULT];
    [userDefaults removeObjectForKey:@ALL_THE_DATA_IN_EPOCHS];
    [userDefaults removeObjectForKey:@DATA_DATAIL_BY_DAY];
    [userDefaults removeObjectForKey:@DAYS_READ_BEFORE];
    [userDefaults removeObjectForKey:@FIRST_SYNC];
    [userDefaults removeObjectForKey:@"kLAST_FIRMWARE_CHECK_DATE_NEW"];
    [userDefaults setObject:@"1" forKey:DistanceDecimalCorrectionKey];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
    [[DBModule sharedInstance] managedObjectContext];
    //initialize the database
    
	NSString * sourceDbName = @"timexDatalinkDB.db";
    
	NSString* dbPath = [[[TimexWatchDB sharedInstance] getDataPath] stringByAppendingPathComponent:sourceDbName];
    OTLog(@"Database path: %@", dbPath);
	BOOL dbExists = [[TimexWatchDB sharedInstance] doesFileExist: dbPath];
    
	[(TimexWatchDB*)[TimexWatchDB sharedInstance] init : dbPath];
    timexDatalinkWatchStyle existingStyle = [iDevicesUtil getActiveWatchProfileStyle];
    if (dbExists) {
        [[TDWatchProfile sharedInstance] loadProfileForStyle: existingStyle statusUpdateCode: NULL];
        if (existingStyle == timexDatalinkWatchStyle_Metropolitan && ([[NSUserDefaults standardUserDefaults] objectForKey:M372_MIGRATION_DONE] == nil || [[[NSUserDefaults standardUserDefaults] objectForKey:M372_MIGRATION_DONE] isEqualToString:@"0"])) { // Migrating only Metro Activity data
            [DBM372Migration getActivityDataAndAddToCoreData];
            [DBM372Migration setGoals];
        }
        if (existingStyle == timexDatalinkWatchStyle_Metropolitan || existingStyle == timexDatalinkWatchStyle_IQ || existingStyle == timexDatalinkWatchStyle_IQTravel) {
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            BOOL distanceDecimalCorrectionStatus = [userDefaults boolForKey:DistanceDecimalCorrectionKey];
            if (distanceDecimalCorrectionStatus == false) {
                [userDefaults setObject:@"1" forKey:DistanceDecimalCorrectionKey];
                double distance;
                if (existingStyle == timexDatalinkWatchStyle_IQ || existingStyle == timexDatalinkWatchStyle_IQTravel) {
                    distance = [self doDistanceDecimalCorrectionInDefaultsForM328];
                }
                else if (existingStyle == timexDatalinkWatchStyle_Metropolitan) {
                    distance = [self doDistanceDecimalCorrectionInDefaultsForM372];
                }
                
                if ([[NSUserDefaults standardUserDefaults] objectForKey:[iDevicesUtil getGoalTypeStringFormat:Custom]] != nil) {
                    NSMutableDictionary *goal = [[[NSUserDefaults standardUserDefaults] valueForKey: [iDevicesUtil getGoalTypeStringFormat:Custom]] mutableCopy];
                    [goal setObject:[NSNumber numberWithDouble:distance] forKey:DISTANCE];
                    [[NSUserDefaults standardUserDefaults] setValue:goal forKey:[iDevicesUtil getGoalTypeStringFormat:Custom]];
                }
            }
        }
	} else {
        OTLog(@"WARNING DATABASE NOT FOUND");
		[[TimexWatchDB sharedInstance] createBlankDatabase : dbPath];
	}

    if ([[NSUserDefaults standardUserDefaults] objectForKey:WATCHID_COREDATA_MIGRATION_DONE] == nil || [[[NSUserDefaults standardUserDefaults] objectForKey:WATCHID_COREDATA_MIGRATION_DONE] isEqualToString:@"0"]) { // Adding watchID to already stored data in DB for first item only.
        [DBM372Migration setWatchIDForAllEntitiesINCoreData];
    }
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"AppOldVersionNumber"] == nil) {
        [[NSUserDefaults standardUserDefaults] setObject:@"0" forKey:@"AppOldVersionNumber"];
    }
    [[TimexWatchDB sharedInstance] performTableAlterations:[[[NSUserDefaults standardUserDefaults] objectForKey:@"AppOldVersionNumber"] intValue]];

    [self setupDummyGoals];

    [[BITHockeyManager sharedHockeyManager] configureWithIdentifier:@"30e10002819915fb1d9a8dab0ed69e9a"];
    [[BITHockeyManager sharedHockeyManager] startManager];
    [[BITHockeyManager sharedHockeyManager].authenticator authenticateInstallation]; // This line is obsolete in the crash only build
    
    [Flurry setLogLevel:FlurryLogLevelAll];
    [Flurry setDebugLogEnabled:YES];
    [Flurry setBackgroundSessionEnabled:NO];
    [Flurry setSessionReportsOnCloseEnabled:YES];
    [Flurry setSessionReportsOnPauseEnabled:YES];
    [Flurry startSession: FlurryKey withOptions: launchOptions];
    [self setRootViewController];
    [self.window makeKeyAndVisible];
    [self registerSettingsBundle];
     OTLog(@"app launched");
    return YES;
}

- (double)doDistanceDecimalCorrectionInDefaultsForM372
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString * diskey = [iDevicesUtil createKeyForAppSettingsPropertyWithClass: appSettingsM372_PropertyClass_Goals andIndex: appSettingsM372_PropertyClass_Goals_Distance];
    double distance = [[NSUserDefaults standardUserDefaults] doubleForKey: diskey];
    double decimalDistance = distance/100;
    [userDefaults setDouble:decimalDistance forKey:diskey];
    return decimalDistance;
}

- (double)doDistanceDecimalCorrectionInDefaultsForM328
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *key = [iDevicesUtil createKeyForAppSettingsPropertyWithClass: appSettingsM328_PropertyClass_Goals andIndex: appSettingsM328_PropertyClass_Goals_Distance];
    double distance = [userDefaults doubleForKey:key];
    double decimalDistance = distance/100;
    [userDefaults setDouble:decimalDistance forKey:key];
    return decimalDistance;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    if ([TDM328WatchSettingsUserDefaults timerStatus] == 1) {
        if ([self.window.rootViewController isKindOfClass:[MFSideMenuContainerViewController class]] && [((MFSideMenuContainerViewController *)self.window.rootViewController).centerViewController isKindOfClass:[UINavigationController class]]) {
            UINavigationController *navVC = ((MFSideMenuContainerViewController *)self.window.rootViewController).centerViewController;
            if ([navVC.topViewController isKindOfClass:[TimerViewController class]]) {
                TimerViewController *timeVC = (TimerViewController*)navVC.topViewController;
                [timeVC invalidateTimer];
            }
        }
        [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"timeDown"];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"timeDown"];
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"timeDown"] != nil) {
        if ([self.window.rootViewController isKindOfClass:[MFSideMenuContainerViewController class]] && [((MFSideMenuContainerViewController *)self.window.rootViewController).centerViewController isKindOfClass:[UINavigationController class]]) {
            UINavigationController *navVC = ((MFSideMenuContainerViewController *)self.window.rootViewController).centerViewController;
            timeDown = [[NSUserDefaults standardUserDefaults] objectForKey:@"timeDown"];
            if ([navVC.topViewController isKindOfClass:[TimerViewController class]]) {
                TimerViewController *timeVC = (TimerViewController*)navVC.topViewController;
                if (([TDM328WatchSettingsUserDefaults timerTemp] - (-[timeDown timeIntervalSinceNow])) > 0) { //timeIntervalSinceNow we are getting negitive value
                    [TDM328WatchSettingsUserDefaults setTimerTemp:((int)[TDM328WatchSettingsUserDefaults timerTemp] - (-[timeDown timeIntervalSinceNow]))];
                    [timeVC countdownTimerStart];
                } else {
                    [timeVC invalidateTimer];
                    [timeVC timerStarted:NO];
                }
            } else {
                if (([TDM328WatchSettingsUserDefaults timerTemp] - (-[timeDown timeIntervalSinceNow])) <= 0) {
                    [TDM328WatchSettingsUserDefaults setTimerTemp:0];
                    [TDM328WatchSettingsUserDefaults setTimerStatus:M328_TIMER_OFF];
                }
            }
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"timeDown"];
        }
    }
}
- (void)setTimerTempAfterLaunchingApp {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"timeDown"] != nil) {
        timeDown = [[NSUserDefaults standardUserDefaults] objectForKey:@"timeDown"];
        if (([TDM328WatchSettingsUserDefaults timerTemp] - (-[timeDown timeIntervalSinceNow])) <= 0) {
            [TDM328WatchSettingsUserDefaults setTimerTemp:0];
            [TDM328WatchSettingsUserDefaults setTimerStatus:M328_TIMER_OFF];
        } else {
            [TDM328WatchSettingsUserDefaults setTimerTemp:((int)[TDM328WatchSettingsUserDefaults timerTemp] - (-[timeDown timeIntervalSinceNow]))];
        }
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"timeDown"];
    }
}
- (void)applicationDidBecomeActive:(UIApplication *)application
{
    
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}
- (NSString *)removingLastSpecialCharecter:(NSString *)str {
    @try {
        str = [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        str = [str stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        return str;
    }
    @catch (NSException *exception) {
        OTLog(@"Exception At: %s %d %s %s %@", __FILE__, __LINE__, __PRETTY_FUNCTION__, __FUNCTION__,exception);
    }
    @finally {
    }
}

-(void)setRootViewController{
    MFSideMenuContainerViewController *container = [MFSideMenuContainerViewController
                                                    containerWithCenterViewController:[self navigationController]
                                                    leftMenuViewController:nil
                                                    rightMenuViewController: nil];
    
    container.shadowEnabled  = NO;
    
    self.window.rootViewController = container;
}
- (NSString *)getLastSyncDate {
    NSDate * lastSyncDate = (NSDate *)[[NSUserDefaults standardUserDefaults] objectForKey:kLastActivityTrackerSyncSyncDate];
    if (lastSyncDate == nil) {
        return NSLocalizedString(@"Never Synced", nil);
    } else {
        NSCalendar *cal = [NSCalendar currentCalendar];
        
        NSDateComponents *components = [cal components:(NSCalendarUnitEra | NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate: [NSDate date]];
        NSDate *today = [cal dateFromComponents: components];
        
        components = [cal components:(NSCalendarUnitEra | NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate: [[NSDate date] dateByAddingTimeInterval:-SECONDS_PER_DAY]];
        NSDate *yesterday = [cal dateFromComponents:components];
        
        components = [cal components:(NSCalendarUnitEra | NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate: lastSyncDate];
        NSDate * syncDateSansTime = [cal dateFromComponents: components];
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        [dateFormatter setLocale: enUSPOSIXLocale];
        
        [dateFormatter setDateFormat:@"h:mm a"];
        
        NSMutableString * formattedDate = [[NSMutableString alloc] initWithString:[[dateFormatter stringFromDate: lastSyncDate] lowercaseString]];
        
        if([today isEqualToDate: syncDateSansTime]) {
            [formattedDate appendString:[NSString stringWithFormat:@" %@", NSLocalizedString(@"Today", nil)]];
        } else if([yesterday isEqualToDate: syncDateSansTime]) {
            [formattedDate appendString:[NSString stringWithFormat:@" %@", NSLocalizedString(@"Yesterday", nil)]];
        } else {
            [dateFormatter setDateFormat:@"MM/dd/yyyy"];
            [formattedDate appendFormat:@" %@",[dateFormatter stringFromDate: lastSyncDate]];
        }
        return formattedDate;
    }
}
- (void)InitialiseCustomTabbar {
    self.customTabbar = [[CustomTabbar alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, 70)];
}

- (void)setNavigationBarSettingsForM328:(UINavigationController *)navigationController {
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    [navigationController.navigationBar setTranslucent:NO];
    [navigationController.navigationBar setTintColor:[UIColor lightGrayColor]];
    [navigationController.navigationBar setShadowImage:[[UIImage alloc] init]];
    [navigationController.navigationBar setBackgroundImage:[[UIImage alloc] init] forBarMetrics:UIBarMetricsDefault];
    [navigationController.navigationBar setBackgroundColor:[UIColor whiteColor]];
    self.window.backgroundColor = [UIColor whiteColor];
}
- (void)setNavigationBarSettingsForM054andM053:(UINavigationController *)navViewController {
    UIColor *color = [UIColor blackColor];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    navViewController.navigationBar.backgroundColor = color;
    [navViewController.navigationBar setBackgroundImage:[iDevicesUtil imageWithColor:color] forBarMetrics:UIBarMetricsDefault];
    navViewController.navigationBar.layer.cornerRadius = 0.0f;
    navViewController.navigationBar.layer.masksToBounds = NO;
    navViewController.navigationBar.layer.shadowColor = [UIColor grayColor].CGColor;
    
    navViewController.navigationBar.layer.shadowOpacity = 0.8;
    navViewController.navigationBar.layer.shadowRadius = 1;
    navViewController.navigationBar.layer.shadowOffset = CGSizeMake(0.0f, 2.0f);
    //fixed issue with iPad Title color showing up as "clear"
    navViewController.navigationBar.tintColor = UIColorFromRGB(COLOR_DEFAULT_TIMEX_WHITE);
}
- (void)deleteOldAndInsertGoalOfType:(enum GoalType)type {
//    NSArray *goalsArr = [self fetchGoalsOfType:type];
//    for (Goals *goal in goalsArr) {
//        [self.managedObjectContext deleteObject:goal];
//    }
//    [self saveContext];
//    [self setupGoalsWithType:type];
}

- (void)setupGoalsWithType:(GoalType)type {
    BOOL isGoalExist = [self fetchGoalsOfType:type];
    NSString *goals = @"";
    if (type == Normal) {
        if (isGoalExist) {
            goals = [NSString stringWithFormat:@"UPDATE M328_Goals SET distance = '1.20' WHERE type = %@;",[NSNumber numberWithInt:type]];
        } else {
            goals = [NSString stringWithFormat:@"INSERT INTO M328_Goals (steps,calories,distance,sleepTime,type) VALUES (%@,%@,%@,%@,%@);",@1500,@2500,@1.20,@8.0,[NSNumber numberWithInt:type]];
        }
    } else if (type == Pretty) {
        if (isGoalExist) {
            goals = [NSString stringWithFormat:@"UPDATE M328_Goals SET distance = '3.22' WHERE type = %@;",[NSNumber numberWithInt:type]];
        } else {
            goals = [NSString stringWithFormat:@"INSERT INTO M328_Goals (steps,calories,distance,sleepTime,type) VALUES (%@,%@,%@,%@,%@);",@4000,@2850,@3.22,@8.0,[NSNumber numberWithInt:type]];
        }
    } else {
        if (isGoalExist) {
            goals = [NSString stringWithFormat:@"UPDATE M328_Goals SET distance = '8.04' WHERE type = %@;",[NSNumber numberWithInt:type]];
        } else {
            goals = [NSString stringWithFormat:@"INSERT INTO M328_Goals (steps,calories,distance,sleepTime,type) VALUES (%@,%@,%@,%@,%@);",@10000,@3500,@8.04,@8.0,[NSNumber numberWithInt:type]];
        }
    }
    TimexDatalink::IDBQuery * query = [[TimexWatchDB sharedInstance] createQuery : goals];
    if (query)
    {
        delete query;
    }
}

-(void)setupDummyGoals{
    [self setupGoalsWithType:Normal];
    [self setupGoalsWithType:Pretty];
    [self setupGoalsWithType:Very];
}
- (BOOL)fetchGoalsOfType:(GoalType)type {
    NSString * expression = [NSString stringWithFormat:@"SELECT * FROM M328_Goals where type = %@",[NSNumber numberWithInt:type]];
    
    TimexDatalink::IDBQuery * query = [[TimexWatchDB sharedInstance] createQuery : expression];
    if (query)
    {
        if (query->getRowCount() > 0)
        {
            return TRUE;
        }
        
        delete query;
    }
    return FALSE;
}

-(NSDictionary*)getGoalsForType:(GoalType)type {
    
    return [[TimexWatchDB sharedInstance] getGoals1ForType:[NSNumber numberWithInt:type]];
}

-(void)saveGoal:(NSMutableDictionary*)goal {
    
    NSString *expression = [NSString stringWithFormat:@"UPDATE M328_Goals SET calories = %@,distance = %@ ,steps = %@,sleepTime = %@ WHERE type = %@;",(NSNumber*)[goal valueForKey:CALORIES],(NSNumber*)[goal valueForKey:DISTANCE],(NSNumber*)[goal valueForKey:STEPS],(NSNumber*)[goal valueForKey:SLEEPTIME],(NSNumber*)[goal valueForKey:GOALTYPE]];
    TimexDatalink::IDBQuery * query = [[TimexWatchDB sharedInstance] createQuery : expression];
    if (query)
    {
        delete query;
    }
}


- (void)ls {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSArray *directoryContent = [[NSFileManager defaultManager] directoryContentsAtPath: documentsDirectory];
    
    OTLog(@"%@", documentsDirectory);
    OTLog(@"Content : %@",directoryContent);
    return ;
}

#pragma mark
#pragma mark Alertview
- (void)showAlertWithTitle:(NSString *)title Message:(NSString *)message andButtonTitle:(NSString *)btnTitle {
    self.alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:btnTitle otherButtonTitles:nil, nil];
    [self.alertView show];
}
// Need to dismiss alert when video is playing
- (void)dismissAlertViews {
    [alertView dismissWithClickedButtonIndex:[alertView cancelButtonIndex] animated:NO];
}

-(void)registerSettingsBundle{
    
    NSUserDefaults * defs = [NSUserDefaults standardUserDefaults];
    [defs synchronize];
    
    NSString *settingsBundle = [[NSBundle mainBundle] pathForResource:@"Settings" ofType:@"bundle"];
    
    if(!settingsBundle)
    {
        OTLog(@"Could not find Settings.bundle");
    }
    
    NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:[settingsBundle stringByAppendingPathComponent:@"Root.plist"]];
    NSArray *preferences = [settings objectForKey:@"PreferenceSpecifiers"];
    NSMutableDictionary *defaultsToRegister = [[NSMutableDictionary alloc] initWithCapacity:[preferences count]];
    
    for (NSDictionary *prefSpecification in preferences)
    {
        NSString *key = [prefSpecification objectForKey:@"Key"];
        if (key)
        {
            // check if value readable in userDefaults
            id currentObject = [defs objectForKey:key];
            if (currentObject == nil)
            {
                // not readable: set value from Settings.bundle
                id objectToSet = [prefSpecification objectForKey:@"DefaultValue"];
                [defaultsToRegister setObject:objectToSet forKey:key];
                OTLog(@"Setting object %@ for key %@", objectToSet, key);
            }
            else
            {
                // already readable: don't touch
                OTLog(@"Key %@ is readable (value: %@), nothing written to defaults.", key, currentObject);
            }
        }
    }
    
    [defs registerDefaults:defaultsToRegister];
    [defs synchronize];
}

//wrote this in-order to reproduce artifact artf26070 : M372(iOS): Steps, Distance, and Calories graph takes approximately 42 seconds to load
-(void)addDummy
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"dd-MM-yyyy"];
    NSDate *date = [dateFormatter dateFromString:@"01-12-2016"];

    NSMutableArray *array = [[NSMutableArray alloc] init];
    
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    [dateComponents setDay:-1];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSLog(@"%@", date);
    for (int i=0; i<200; i++)
    {
        ActivityModal *activityModel = [[ActivityModal alloc]init];
        activityModel.date = date;
        activityModel.distance = [NSNumber numberWithInt:0];
        activityModel.steps = [NSNumber numberWithInt:1000];
        activityModel.calories = [NSNumber numberWithInt:20000];
        activityModel.segments = @"";
        activityModel.sleep = [NSNumber numberWithInt:0];
        
        [array addObject:activityModel];
        
        date = [calendar dateByAddingComponents:dateComponents toDate:date options:0];
        NSLog(@"%@", date);
    }
    
    [DBManager addOrUpdateActivityEntities:array];
}

@end
