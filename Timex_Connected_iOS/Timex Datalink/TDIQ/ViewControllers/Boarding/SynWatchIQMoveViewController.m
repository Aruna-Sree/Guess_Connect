 //
//  TDSynWatchMetropolitanViewController.m
//  Timex
//
//  Created by Diego Santiago on 5/27/16.
//  Copyright © 2016 iDevices, LLC. All rights reserved.
//

#import "SynWatchIQMoveViewController.h"
#import "UIImage+Tint.h"
#import "TDDeviceManager.h"
#import "TDDevice.h"
#import "PeripheralDevice.h"
#import "TDOnBoardingTableViewCell.h"
#import "PCCommWhosThere.h"
#import "PCCommChargeInfo.h"
#import "TDM372WatchSettings.h"
#import "TDM372ActigraphyDataFile.h"
#import "TDM372WatchActivity.h"
#import "TDM372SleepSummaryFile.h"
#import "TDM372ActigraphyKeyFile.h"
#import "UpdateFirmwareViewController.h"
#import "iDevicesUtil.h"
#import "TDM328WatchSettings.h"
#import "TDWatchProfile.h"
#import "TDAppDelegate.h"
#import "OTLogUtil.h"
#import "HelpViewController.h"
#import "TDM328WatchSettingsUserDefaults.h"
#import "SettingsViewController.h"
#import "TDHomeViewController.h"
#import "CustomAlertViewController.h"
#import "TDM372ActigraphyStepFile.h"

#define AFTER_SYNC_TIMEOUT 2.0
#define UNIT_PROGRESS_VALUE 4.3

//enum syncActionsEnum
//{
//    syncActionsEnum_Unselected = 0,
//    syncActionsEnum_WatchOverPhone,
//    syncActionsEnum_PhoneOverWatch
//};

@interface SynWatchIQMoveViewController ()
{
    BOOL mInitialSetupSynchronization;
    syncActionsEnum mCurrentSyncActionSelected;
    
    NSInteger mReconnectAttempts;
    NSTimer *actionTimer;
    UIAlertController *_noWatchFounded;
    BOOL errorDisplayed;
    BOOL succesinTheConnection;
    
    float syncProgressValue;
    
    BOOL lowBattery;
    BOOL endSession;
}

@end

@implementation SynWatchIQMoveViewController

@synthesize watchObject = _watchObject;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil kickOffSyncAutomatically: (BOOL) autoSyncFlag
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Custom initialization
        mInitialSetupSynchronization = autoSyncFlag;
        if (mInitialSetupSynchronization)
            mCurrentSyncActionSelected = syncActionsEnum_WatchOverPhone;
        else
            mCurrentSyncActionSelected = syncActionsEnum_Unselected;
        
        
        succesinTheConnection = false;
    }
    return self;
}



- (void)viewDidLoad {
    [super viewDidLoad];
    if (mInitialSetupSynchronization)
    {
        self.navigationItem.titleView = [iDevicesUtil getNavigationTitle];
        
//        UIButton *backBtn = [iDevicesUtil getBackButton];
//        [backBtn addTarget:self action:@selector(backButtonTapped) forControlEvents:UIControlEventTouchUpInside];
//        UIBarButtonItem *barBtn = [[UIBarButtonItem alloc] initWithCustomView:backBtn];
//        self.navigationItem.leftBarButtonItem = barBtn;
        
        titleLabel.attributedText = [self getAttributedStrWithText:NSLocalizedString(@"Syncing your watch.",nil) formatStr:NSLocalizedString(@"\n\nWe're setting up your watch and reading your current activity data.",nil)];
        
        //Put sensor and adjustment to defaults
        [TDM328WatchSettingsUserDefaults setDistanceAdjustment:M328_Default_DistanceAdjustment];
        [TDM328WatchSettingsUserDefaults setSensorSensitivity:M328_Default_AccelSensitivity];

        if (IS_IPAD) {
            infoLblTopConstraint.constant = 70;
            infoLblleftConstraint.constant = infoLblRightConstraint.constant = 60;
        } else {
            infoLblleftConstraint.constant = infoLblRightConstraint.constant = 40;
        }
        infoLblBottomContraint.constant = ((ScreenHeight)/2) - 70 - M328_REGISTRATION_BOTTOM_CONSTRAINT_MINUSVALUE;
        
        progressLbl.backgroundColor = UIColorFromRGB(AppColorRed);
        progressLblWidthContraint.constant = ScreenWidth * ([iDevicesUtil getProgressBarValueBasedOnRegistrationEnum:setupWatch]);

    }
    
    [self startAction];
    
    [self setupProgressView];
}


- (NSAttributedString *)getAttributedStrWithText:(NSString *)textStr formatStr:(NSString *)formatStr {
    
    UIFont *textFont = [UIFont fontWithName:[iDevicesUtil getAppWideFontName] size:M328_REGISTRATION_BIG_TITLE_FONTSIZE];
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:textFont, NSFontAttributeName, UIColorFromRGB(COLOR_DEFAULT_TIMEX_FONT),NSForegroundColorAttributeName, nil];
    NSMutableAttributedString *textAtrStr = [[NSMutableAttributedString alloc] initWithString:textStr attributes:dict];
    
    UIFont *formatFont = [UIFont fontWithName: [iDevicesUtil getAppWideMediumFontName] size:M328_WELCOME_INFO_FONTSIZE];
    NSDictionary *atrsDict = [NSDictionary dictionaryWithObjectsAndKeys:formatFont, NSFontAttributeName, UIColorFromRGB(COLOR_DEFAULT_TIMEX_FONT),NSForegroundColorAttributeName, nil];
    NSMutableAttributedString *formatAtrStr = [[NSMutableAttributedString alloc] initWithString:formatStr attributes:atrsDict];
    
    [textAtrStr appendAttributedString:formatAtrStr];
    
    return textAtrStr;
}
-(void) backButtonTapped
{
    [self.navigationController popViewControllerAnimated:YES];

}

#pragma mark table view delegates
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger rows = 1;
    
    return rows;
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    return ONBOARDING_PAIR_WATCH_CELL_HEIGHT;
}
- (void)didReceiveMemoryWarning {
     OTLog([NSString stringWithFormat:@"Recived Memory Warning  in %@ ",NSStringFromClass([self class])]);
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    PeripheralDevice * currentDevice = (PeripheralDevice *)_watchObject;
    
    static NSString *CellIdentifier = @"Cell";
    TDOnBoardingTableViewCell *cellx = (TDOnBoardingTableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cellx == nil) {
        cellx = (TDOnBoardingTableViewCell *) [[[NSBundle mainBundle] loadNibNamed:@"TDOnBoardingTableViewCell" owner:self options:nil] objectAtIndex:0];
        cellx.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    if (currentDevice.name != nil)
    {
        [cellx setWatchConnectingString:@""]; //delete the text in connecting label
        [cellx setWatchIndicationActivityOff];
        
        [cellx setWatchNameString:currentDevice.name];
        
        if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)
            [cellx setWatchNameString:@"iQ+ Travel"];
        else
            [cellx setWatchNameString:@"Guess iQ+"];
        
    }
    else
        [cellx setWatchNameString:NSLocalizedString(@"Timex Watch", nil)];
    
    
    
        [cellx setWatchUIImage:[[UIImage imageNamed: @"M372-Sync-White"] imageWithTint:[UIColor redColor]]];
   
        [cellx setWatchIndicationActivityOn];
        [cellx setWatchConnectingString:NSLocalizedString(@"Connecting", nil)];
    
    if (succesinTheConnection)
    {
        [cellx setWatchIndicationActivityOff];
        [cellx setWatchConnectingString:NSLocalizedString(@"Connected", nil)];
        [cellx setWatchComleteImage:[UIImage imageNamed: @"checkmark_icon"]];
    }
    
    return cellx;
}

#pragma mark Selectors
- (void) WatchInfoRead: (NSNotification*)notification
{
    OTLog(@" -> Watch Info read");
    [self updateSyncProgressByValue:UNIT_PROGRESS_VALUE];
    
    PCCommWhosThere * newSettings = [notification.userInfo objectForKey: kDeviceWatchInfoKey];
    if (newSettings)
    {
        OTLog(newSettings.mSerialNumber);
//        NSString * mappedName = [iDevicesUtil convertTimexModuleStringToProductName: newSettings.mModelNumber];
//        if (mappedName == nil)
//            mappedName = newSettings.mModelNumber;
        
        [[NSUserDefaults standardUserDefaults] setObject:newSettings.mSerialNumber forKey:WATCH_SERIAL_NUMBER];
        [[NSUserDefaults standardUserDefaults]synchronize];
        
    }
}
- (void) WatchChargeInfoRead: (NSNotification*)notification
{
    OTLog(@" -> Watch charge Info read");
    [self updateSyncProgressByValue:UNIT_PROGRESS_VALUE];

    PCCommChargeInfo * chargeInfo = [notification.userInfo objectForKey: kDeviceWatchChargeInfoKey];
    [TDM328WatchSettingsUserDefaults setBatteryVolt:chargeInfo.voltage];
    if (chargeInfo)
    {
        if (chargeInfo.voltage > M372_GOOD_VOLTAGE_THRESHOLD)
            OTLog(@"battery status good");
        else
        {
            lowBattery = YES;
            [self removeNotConnectedMessage];
            [[NSNotificationCenter defaultCenter] removeObserver: self name: kDeviceManagerDeviceLostConnectiondNotification object: nil];
            [[NSNotificationCenter defaultCenter] removeObserver: self name: kPeripheralDeviceAuthorizationFailedNotification object: nil];
            [self exitSyncModeManually];
            CustomAlertViewController *cav = [[CustomAlertViewController alloc] initWithTitle:NSLocalizedString(@"Watch Battery Low", nil) andMessage:NSLocalizedString(@"Your watch battery is too low to sync. You will need to replace your watch battery soon.", nil)];
            [cav addActionButton:[[CustomAlertButton alloc] initWithTitle:NSLocalizedString(@"Go Back", nil) andActionBlock:^{
                [self.navigationController popViewControllerAnimated:YES];
            }]];
            
            [cav addActionButton:[[CustomAlertButton alloc] initWithTitle:NSLocalizedString(@"Learn More", nil) andActionBlock:^{
                HelpViewController *helpVC = [[HelpViewController alloc] initWithNibName:@"HelpViewController" bundle:nil fromSync:YES];
                NSMutableArray *controllers = [NSMutableArray arrayWithArray:self.navigationController.viewControllers];
                [controllers removeLastObject];
                [controllers addObject:helpVC];
                [self.navigationController setViewControllers:controllers animated:YES];
            }]];
            
            cav.modalPresentationStyle = UIModalPresentationOverCurrentContext;
            
            [self presentViewController: cav animated:NO completion:nil];
        }
    }
}

-(void)exitSyncModeManually
{
    // Logic here is to start and end the session if not present.
    // This will disconnect the watch.
    // Observe for notification on start of session
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(didStartFileAccessSession:) name:kTDM328SessionStartNotification object:nil];
    endSession = YES;
    PeripheralDevice * timexDevice = [iDevicesUtil getConnectedTimexDevice];
    if(timexDevice)
    {
        if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)
        {
            [timexDevice endFileAccessSession];
        }
        else
        {
            [timexDevice startFileAccessSession];
        }
    }
}

-(void)didStartFileAccessSession:(NSNotification*)notification
{
    // Remove observer.
    [[NSNotificationCenter defaultCenter]removeObserver:self name:kTDM328SessionStartNotification object:nil];
    
    PeripheralDevice * timexDevice = [iDevicesUtil getConnectedTimexDevice];
    if(timexDevice && endSession)
    {
        [timexDevice endFileAccessSession];
    }
}
- (void) WatchM328SettingsRead: (NSNotification*)notification
{
    OTLog(@" -> Watch Settings read for no reason");
    [self updateSyncProgressByValue:UNIT_PROGRESS_VALUE];

    //No need to store values from watch
    /*
    TDM328WatchSettings * newData = [notification.userInfo objectForKey: kM328SettingsDataFileKey];
    if (newData)
    {
        [newData serializeIntoSettings]; //settings saved
    }
     */
}
- (void) WatchM328SettingsReadFailed
{
     OTLog(@" -> Watch Settings read failed");
    [self syncFinished:true];
    if (!mInitialSetupSynchronization)
    {
        actionTimer = [NSTimer scheduledTimerWithTimeInterval: AFTER_SYNC_TIMEOUT target:self selector:@selector(removeNotConnectedMessage) userInfo: nil repeats: NO];
        
    }
    OTLog( @"M328 Read Failed!!!");
}

- (void) WatchM28ActivitiesRead: (NSNotification*)notification
{
    OTLog( @"WatchM28ActivitiesRead!!!");
    [self updateSyncProgressByValue:UNIT_PROGRESS_VALUE];
    
    TDM372WatchActivity * newData = [notification.userInfo objectForKey: kM372ActivitiesDataFileKey];
    if (newData)
    {
        //record last sync date
        [[NSUserDefaults standardUserDefaults] setObject: [NSDate date] forKey: kLastActivityTrackerSyncSyncDate];
        [newData recordActivityData];
    }
}
- (void) WatchM28ActivitiesReadFailed
{
    OTLog(@"Watch activities read failed");
    [self syncFinished:true];
    if (!mInitialSetupSynchronization)
    {
        actionTimer = [NSTimer scheduledTimerWithTimeInterval: AFTER_SYNC_TIMEOUT target:self selector:@selector(removeNotConnectedMessage) userInfo: nil repeats: NO];
    }
    OTLog( @"M328 Read Failed!!!");
}


- (void) WatchM372SleepActigraphyData: (NSNotification*)notification
{
    OTLog(@"WatchM372SleepActigraphyData");
    [self updateSyncProgressByValue:UNIT_PROGRESS_VALUE];

    TDM372ActigraphyDataFile * newData = [notification.userInfo objectForKey: kM372ActigraphyDataFile];
    if (newData)
    {
        //record last sync date
        [[NSUserDefaults standardUserDefaults] setObject: [NSDate date] forKey: kLastActivityTrackerSyncSyncDate];
        //[newData recordActivityData];
    }
}
- (void) WatchM372SleepActigraphyDataFailed
{
    NSLog(@"Sleep actigraphy data sleep summary failed");
    [self syncFinished:true];
    if (!mInitialSetupSynchronization)
    {
        actionTimer = [NSTimer scheduledTimerWithTimeInterval: AFTER_SYNC_TIMEOUT target:self selector:@selector(removeNotConnectedMessage) userInfo: nil repeats: NO];
        
    }
    OTLog(@"M328 ActigraphyData Sleep Summary Failed!!!");
}

#pragma mark - WatchM372ActigraphyStepFileData
- (void) WatchM372ActigraphyStepData: (NSNotification*)notification
{
    OTLog(@"WatchM372ActigraphyStepData");
    [self updateSyncProgressByValue:UNIT_PROGRESS_VALUE];
    TDM372ActigraphyStepFile * newData = [notification.userInfo objectForKey: kM372ActigraphyStepFile];
    if (newData)
    {
        //record last sync date
        [[NSUserDefaults standardUserDefaults] setObject: [NSDate date] forKey: kLastActivityTrackerSyncSyncDate];
        //[newData recordActivityData];
    }
}
- (void) WatchM372ActigraphyStepDataFailed
{
    OTLog(@"WatchM372ActigraphyStepDataFailed");
    [self syncFinished:true];
    if (!mInitialSetupSynchronization)
    {
        actionTimer = [NSTimer scheduledTimerWithTimeInterval: AFTER_SYNC_TIMEOUT target:self selector:@selector(removeNotConnectedMessage) userInfo: nil repeats: NO];
        
    }
}

- (void) WatchM372SleepSummaryRead: (NSNotification*)notification
{
     NSLog(@"WatchM372SleepSummaryRead!!!");
    [self updateSyncProgressByValue:UNIT_PROGRESS_VALUE];

    TDM372SleepSummaryFile * newData = [notification.userInfo objectForKey: kM372SleepSummaryFileKey];
    if (newData)
    {
        //record last sync date
        [[NSUserDefaults standardUserDefaults] setObject: [NSDate date] forKey: kLastActivityTrackerSyncSyncDate];
        //[newData recordActivityData];
    }
}

- (void) WatchM372SleepSummaryReadFailed
{
    
    [self syncFinished:true];
    if (!mInitialSetupSynchronization)
    {
        actionTimer = [NSTimer scheduledTimerWithTimeInterval: AFTER_SYNC_TIMEOUT target:self selector:@selector(removeNotConnectedMessage) userInfo: nil repeats: NO];
    }
    NSLog(@"M328 Read Sleep Summary Failed!!!");
}
- (void) WatchM372SleepKeyFileRead: (NSNotification*)notification
{
    OTLog(@"WatchM372SleepKeyFileRead!!!");
    [self updateSyncProgressByValue:UNIT_PROGRESS_VALUE];

    TDM372ActigraphyKeyFile * newData = [notification.userInfo objectForKey: kM372SleepKeyFile];
    if (newData)
    {
        //record last sync date
        [[NSUserDefaults standardUserDefaults] setObject: [NSDate date] forKey: kLastActivityTrackerSyncSyncDate];
        //[newData recordActivityData];
    }
}

- (void) WatchM372SleepKeyFileReadFailed
{
    [self syncFinished:true];
    if (!mInitialSetupSynchronization)
    {
        actionTimer = [NSTimer scheduledTimerWithTimeInterval: AFTER_SYNC_TIMEOUT target:self selector:@selector(removeNotConnectedMessage) userInfo: nil repeats: NO];
    }
    OTLog( @"M328 Read Sleep Key Summary Failed!!!");
    
}

#pragma mark - SYSBLOCK

- (void) SYSBLOCKRead: (NSNotification*)notification
{
    OTLog(@"SYSBLOCKRead");
}
- (void) SYSBLOCKReadFailed
{
    OTLog(@"SYSBLOCKFailed");
    [self syncFinished:true];
    if (!mInitialSetupSynchronization)
    {
        actionTimer = [NSTimer scheduledTimerWithTimeInterval: AFTER_SYNC_TIMEOUT target:self selector:@selector(removeNotConnectedMessage) userInfo: nil repeats: NO];
        
    }
}

- (void) SettingsSaved: (NSNotification*)notification
{
    OTLog(@"M328 settings save success");
    float remainingPercentage = (100-syncProgressValue);
    NSLog(@"update remaing percentage %f", remainingPercentage);
    [self updateSyncProgressByValue:remainingPercentage];

    [self syncFinished:false];
    if (!mInitialSetupSynchronization)
    {
        actionTimer = [NSTimer scheduledTimerWithTimeInterval: AFTER_SYNC_TIMEOUT target:self selector:@selector(timerFired) userInfo: nil repeats: NO];
        OTLog(@"DiegoT1");
        
        //[self getInformationLabelTwo].text = @""; //leave as is for Metropolitan
    }
}
- (void) SettingsSaveFailed: (NSNotification*)notification
{
    OTLog(@"M328 settings save failed");
    [self syncFinished:true];
    if (!mInitialSetupSynchronization)
    {
        actionTimer = [NSTimer scheduledTimerWithTimeInterval: AFTER_SYNC_TIMEOUT target:self selector:@selector(removeNotConnectedMessage) userInfo: nil repeats: NO];
    }
}
- (void) ApptsSaved: (NSNotification*)notification
{
    OTLog(@"Appointments saved");
    [self syncFinished:false];
    if (!mInitialSetupSynchronization)
    {
        //actionTimer = [NSTimer scheduledTimerWithTimeInterval: AFTER_SYNC_TIMEOUT target:self selector:@selector(returnToPreviousScreen) userInfo: nil repeats: NO];
    }
}
- (void) ApptsSaveFailed: (NSNotification*)notification
{
     OTLog(@"Appointments save failed");
    [self syncFinished:true];
    if (!mInitialSetupSynchronization)
    {
        actionTimer = [NSTimer scheduledTimerWithTimeInterval: AFTER_SYNC_TIMEOUT target:self selector:@selector(removeNotConnectedMessage) userInfo: nil repeats: NO];
    }
}

-(void) successfullyConnectedToDevice:(NSNotification*)notification
{
    // Need not look for device. Already connected.
    
//    [self performSelector:@selector(startFullFileRead) withObject:nil afterDelay: 1.0];
//    
//    if (mCurrentSyncActionSelected == syncActionsEnum_WatchOverPhone)
//        [self performSelector:@selector(startFullFileRead) withObject:nil afterDelay: 1.0];
//    else if (mCurrentSyncActionSelected == syncActionsEnum_PhoneOverWatch)
//        [self performSelector:@selector(startFullFileReadWithSubsequentWritingToWatch) withObject:nil afterDelay: 1.0];
}
-(void) startFullFileRead
{
    PeripheralDevice * timexDevice = [iDevicesUtil getConnectedTimexDevice];
    if (timexDevice != nil)
    {
        [timexDevice readTimexWatchSettings];
    }
}
-(void) startFullFileReadWithSubsequentWritingToWatch
{
    PeripheralDevice * timexDevice = [iDevicesUtil getConnectedTimexDevice];
    if (timexDevice != nil)
    {
        [timexDevice readTimexWatchActivityData];
        [timexDevice readTimexWatchSleepSummary];//TestLog_SleepFiles
        [timexDevice readTimexWatchSleepKeyFile];//TestLog_SleepFiles
        [timexDevice readTimexWatchSleepActigraphyFiles];//TestLog_SleepFiles
        [timexDevice readTimexWatchActigraphyStepFiles];
    }
}

- (void) startAction
{
    actionTimer = [NSTimer scheduledTimerWithTimeInterval: 60 target:self selector:@selector(timerFired) userInfo: nil repeats: NO];
    
    OTLog(@"DiegoT2");
    //start sync here:
    
    if (mInitialSetupSynchronization)
    {
        [self startFullFileRead];
    }
    else
    {
        [self reconnectToDevice];
    }
}


- (void)reconnectToDevice
{
    //first, we need to CONNECT to the device again... and not just A device, but THE device
    NSString * deviceUUID = [[NSUserDefaults standardUserDefaults] objectForKey: kCONNECTED_DEVICE_UUID_PREF_NAME];
    if (deviceUUID != nil)
    {
        NSArray * adverts = [[TDDeviceManager sharedInstance] getAllConnectedAndAdvertisingDevices];
        NSUInteger idx = NSNotFound;
        idx = [adverts indexOfObjectPassingTest:
               ^ BOOL (PeripheralDevice* device, NSUInteger idx, BOOL *stop)
               {
                   return [device.peripheral.UUID.UUIDString isEqualToString: deviceUUID];
               }];
        
        if (idx != NSNotFound)
        {
            mReconnectAttempts = 0;
            PeripheralDevice * device = [adverts objectAtIndex: idx];
            if (device != NULL)
            {
                [[TDDeviceManager sharedInstance] connect: device];
            }
        }
        else
        {
            mReconnectAttempts++;
            if (mReconnectAttempts > 30)
            {
                mReconnectAttempts = 0;
                
                [self timerFired];
                OTLog(@"DiegoT3");
                if (!mInitialSetupSynchronization)
                {
                    actionTimer = [NSTimer scheduledTimerWithTimeInterval: AFTER_SYNC_TIMEOUT target:self selector:@selector(removeNotConnectedMessage) userInfo: nil repeats: NO];
                    OTLog(@"Unable to start sync");
                }
            }
            else
            {
                OTLog(@"Attempting to reconnect...");
                [self performSelector:@selector(reconnectToDevice) withObject:nil afterDelay: 1.0];
            }
        }
    }
    else
    {
        [self timerFired];
        OTLog(@"DiegoT4");
    }
}
- (void) removeNotConnectedMessage
{
    NSLog(@"removeNotConnectedMessage");
    if (actionTimer)
    {
        [actionTimer invalidate];
        actionTimer = NULL;
    }
}
-(void)timerFired
{
    if(!errorDisplayed)
    {
        errorDisplayed = YES;
        OTLog(@"timer fired");
        mCurrentSyncActionSelected = syncActionsEnum_Unselected;
        [self.navigationController popViewControllerAnimated:YES];
        
        OTLog(@"Done out of intial");
        
        UIAlertController *tryAgainAlert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"WATCH TIMED OUT DURING SYNC.", nil)
                                                                               message:NSLocalizedString(@"After 30 seconds of searching the watch sync will stop if it does not find the phone. You may need to restart the sync.", nil)
                                                                        preferredStyle:UIAlertControllerStyleAlert];
        [tryAgainAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                          style:UIAlertActionStyleCancel
                                                        handler:^(UIAlertAction * _Nonnull action)
                                  {
                                      errorDisplayed = NO;
                                  }]];
        [self presentViewController:tryAgainAlert animated:YES completion:nil];
    }
}
- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear: animated];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    TDAppDelegate *appdel = (TDAppDelegate *)[[UIApplication sharedApplication] delegate];
    appdel.customTabbar.autoSyncAllowed = NO;
    
    self.navigationItem.hidesBackButton = TRUE;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(WatchInfoRead:) name: kTDWatchInfoReadSuccessfullyNotification object: nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(WatchChargeInfoRead:) name: kTDWatchChargeInfoReadSuccessfullyNotification object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(WatchM328SettingsRead:) name: kTDM328SettingsReadSuccessfullyNotification object: nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(WatchM328SettingsReadFailed) name: kTDM328SettingsReadUnsuccessfullyNotification object: nil];
    
    //ActigraphyStepdata
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(WatchM372ActigraphyStepData:) name: kTDM372ActigraphyStepFileDataSuccessfullyNotification object: nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(WatchM372ActigraphyStepDataFailed) name: kTDM372ActigraphyStepFileDataUnsuccessfullyNotification object: nil];
    
    //TestLog_SleepFiles
    //ActigraphyData
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(WatchM372SleepActigraphyData:) name: kTDM372SleepActigraphyDataSuccessfullyNotification object: nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(WatchM372SleepActigraphyDataFailed) name: kTDM372SleepActigraphyDataUnsuccessfullyNotification object: nil];
    
    //SleepSumamry
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(WatchM372SleepSummaryRead:) name: kTDM372SleepSummarySuccessfullyNotification object: nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(WatchM372SleepSummaryReadFailed) name: kTDM372SleepSummaryUnsuccessfullyNotification object: nil];
    
    //SleepKeyFile
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(WatchM372SleepKeyFileRead:) name: kTDM372SleepKeyFileReadSuccessfullyNotification object: nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(WatchM372SleepKeyFileReadFailed) name: kTDM372SleepKeyFileReadUnsuccessfullyNotification object: nil];
    //TestLog_SleepFiles
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(WatchM372ActivitiesRead:) name: kTDM372ActivitiesReadSuccessfullyNotification object: nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(WatchM372ActivitiesReadFailed) name: kTDM372ActivitiesReadUnsuccessfullyNotification object: nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(SettingsSaved:) name: kTDSettingsWrittenSuccessfullyNotification object: nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(SettingsSaveFailed:) name: kTDSettingsWrittenUnsuccessfullyNotification object: nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ApptsSaved:) name: kTDApptsWrittenSuccessfullyNotification object: nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ApptsSaveFailed:) name: kTDApptsWrittenUnsuccessfullyNotification object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ApptsSaved:) name: kTDPhoneTimeWrittenSuccessfullyNotification object: nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ApptsSaveFailed:) name: kTDPhoneTimeWrittenUnsuccessfullyNotification object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(successfullyConnectedToDevice:) name: kPeripheralDeviceTimexDatalinkPrimaryCharacteristicDiscovered object: nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(watchDisconnected:) name:kDeviceManagerDeviceLostConnectiondNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(watchDisconnected:) name:kPeripheralDeviceAuthorizationFailedNotification object: nil];
    
}
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kTDM053ReadSuccessfullyNotification object:nil]; // ??
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kTDM053ReadUnsuccessfullyNotification object:nil]; // ??
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name: kTDSettingsWrittenSuccessfullyNotification object: nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name: kTDSettingsWrittenUnsuccessfullyNotification object: nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name: kTDApptsWrittenSuccessfullyNotification object: nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name: kTDApptsWrittenUnsuccessfullyNotification object: nil];
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kPeripheralDeviceTimexDatalinkPrimaryCharacteristicDiscovered object: nil];
    
    // Settings read
    [[NSNotificationCenter defaultCenter]removeObserver:self name:kTDM328SettingsReadSuccessfullyNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kTDM372SettingsReadUnsuccessfullyNotification object: nil];
    
    // Watch info and charge info
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kTDWatchInfoReadSuccessfullyNotification object: nil];
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kTDWatchChargeInfoReadSuccessfullyNotification object: nil];
    
    //Actigraphy step file
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kTDM372ActigraphyStepFileDataSuccessfullyNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kTDM372ActigraphyStepFileDataUnsuccessfullyNotification object:nil];
    
    // Actigraphy read
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kTDM372SleepActigraphyDataSuccessfullyNotification object: nil];
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kTDM372SleepActigraphyDataUnsuccessfullyNotification object: nil];
    
    // Sleep summary read
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kTDM372SleepSummarySuccessfullyNotification object: nil];
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kTDM372SleepSummaryUnsuccessfullyNotification object: nil];
    
    // Sleep key summary read
    
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kTDM372SleepKeyFileReadSuccessfullyNotification object: nil];
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kTDM372SleepKeyFileReadUnsuccessfullyNotification object: nil];
    
    // Activities
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kTDM372ActivitiesReadSuccessfullyNotification object: nil];
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kTDM372ActivitiesReadUnsuccessfullyNotification object: nil];
    
    // Phone time
    
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kTDPhoneTimeWrittenSuccessfullyNotification object: nil];
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kTDPhoneTimeWrittenUnsuccessfullyNotification object: nil];
    
    // Watch connection
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kDeviceManagerDeviceLostConnectiondNotification object: nil];
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kPeripheralDeviceAuthorizationFailedNotification object: nil];
    TDAppDelegate *appdel = (TDAppDelegate *)[[UIApplication sharedApplication] delegate];
    appdel.customTabbar.autoSyncAllowed = YES;
    
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
//    // Try to end the file session here. if possible. Then we can figure out what to do next.
//    PeripheralDevice *timexDevice =  [iDevicesUtil getConnectedTimexDevice];
//    if(timexDevice){
//        [timexDevice endFileAccessSession]; // Not sure if this is correct.
//    }
//    // Try to see if we can end the file session
}

-(void)syncFinished:(bool)failed
{
    OTLog(@"Sync finish called");
    [actionTimer invalidate];
    actionTimer = NULL;
    
    mCurrentSyncActionSelected = syncActionsEnum_Unselected;
    
    if (failed)
    {
        [self.navigationController popViewControllerAnimated:YES];
        if (!lowBattery) {
            /*
            PeripheralDevice * timexDevice = [iDevicesUtil getConnectedTimexDevice];
            if (timexDevice != nil)
            {
                [timexDevice softResetM372Watch];
            }*/
            [self showErrorMessage:@"ERROR OCCURRED DURING SYNC" error:@"Move away from other Bluetooth devices like phones, tablets, activity trackers and headsets."];
        }
    }
    else {
        if (mInitialSetupSynchronization)
        {
            succesinTheConnection = true;
            [devicesTableView reloadData];
           
            [NSTimer scheduledTimerWithTimeInterval:2.0f target:self selector:@selector(moveToFirmwareUpdate) userInfo:nil repeats:NO];
        }
        else
        {
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
}

- (void)moveToFirmwareUpdate
{
    if (_openedByMenu)
    {
        SettingsViewController *settingsVC;
        for (UIViewController *vc in [self.navigationController viewControllers])
        {
            if ([vc isKindOfClass:[SettingsViewController class]])
            {
                settingsVC = (SettingsViewController*)vc;
            }
        }
        if (settingsVC)
        {
            [self.navigationController popToViewController:settingsVC animated:YES];
        }
        else
        {
            TDHomeViewController *mainControllerIQMove = [[TDHomeViewController alloc]initWithNibName:@"TDHomeViewController"
                                                                                               bundle:nil
                                                                                      doFirmwareCheck:TRUE
                                                                                          initialSync:NO];
            if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)
            {
                mainControllerIQMove = [[TDHomeViewController alloc]initWithNibName:@"TDTravelHomeViewController"
                                                                             bundle:nil
                                                                    doFirmwareCheck:TRUE
                                                                        initialSync:YES];
            }
            [self AssignNewControllerToCenterController: mainControllerIQMove];
        }
    }
    else
    {
        OTLog(@"moveToFirmwareUpdate");
        NSString * keyFirstTiem = @FIRST_SYNC;
        if ([[NSUserDefaults standardUserDefaults] objectForKey: keyFirstTiem] == nil)
        {
            [[NSUserDefaults standardUserDefaults] setObject: @"0" forKey: keyFirstTiem];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        
        _watchObject = nil;
        UpdateFirmwareViewController *updateFirmwareVC=[[UpdateFirmwareViewController alloc] initWithNibName:@"UpdateFirmwareViewController" bundle:nil];
        [self.navigationController pushViewController:updateFirmwareVC animated:NO];
    }
}

- (void) AssignNewControllerToCenterController: (TDRootViewController *) newController
{
    UINavigationController *navigationController = self.navigationController;
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    NSArray *controllers = [NSArray arrayWithObject: newController];
    navigationController.viewControllers = controllers;
}

- (void)showErrorMessage:(NSString*)title error:(NSString*)message
{
    OTLog(@"showErrorMessage");
    [[NSUserDefaults standardUserDefaults]removeObjectForKey:@USERID_USERDEFAULT];
    TDAppDelegate *delegate = (TDAppDelegate *)[[UIApplication sharedApplication] delegate];
    [delegate showAlertWithTitle: NSLocalizedString(title, nil) Message:NSLocalizedString(message, nil) andButtonTitle:NSLocalizedString(@"Ok", nil)];

}

- (void) WatchM372ActivitiesRead: (NSNotification*)notification
{
    OTLog(@"WatchM372ActivitiesRead");
    [self updateSyncProgressByValue:UNIT_PROGRESS_VALUE];

    TDM372WatchActivity * newData = [notification.userInfo objectForKey: kM372ActivitiesDataFileKey];
    if (newData)
    {
        //record last sync date
        [[NSUserDefaults standardUserDefaults] setObject: [NSDate date] forKey: kLastActivityTrackerSyncSyncDate];
        [newData recordActivityData];
    }
}
- (void) WatchM372ActivitiesReadFailed
{
    OTLog(@"Watch activities Read failed");
    [self syncFinished:true];
    if (!mInitialSetupSynchronization)
    {
        actionTimer = [NSTimer scheduledTimerWithTimeInterval: AFTER_SYNC_TIMEOUT target:self selector:@selector(removeNotConnectedMessage) userInfo: nil repeats: NO];
    }
    OTLog(@"M328 Read Failed!!!");
}


- (void)watchDisconnected:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kDeviceManagerDeviceLostConnectiondNotification object: nil];
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kPeripheralDeviceAuthorizationFailedNotification object: nil];
    if (!lowBattery) {
        _noWatchFounded = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Connection lost.", nil)
                                                              message:NSLocalizedString(@"An error occurred while connecting to watch. Please make sure to keep watch in sync mode. Let's try again.", nil)
                                                       preferredStyle:UIAlertControllerStyleAlert];
        
        [_noWatchFounded addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Ok", nil)
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * _Nonnull action)
                                    {
                                        [self.navigationController popViewControllerAnimated:YES];
                                    }]];
        
        [self presentViewController:_noWatchFounded animated:YES completion:nil];
    }
}

- (void) setupProgressView
{
    syncProgressValue = 0;
    [percentageLabel setText:NSLocalizedString(@"0 %", nil)];
    [mainViewCircleProgress setProgress:syncProgressValue animated:YES];
    [mainViewCircleProgress setHintHidden:YES];
    [mainViewCircleProgress setProgressBarProgressColor:UIColorFromRGB(M328_PROGRESS_GREEN_COLOR)];
    [mainViewCircleProgress setProgressBarTrackColor:UIColorFromRGB(COLOR_LIGHT_GRAY)];
    [mainViewCircleProgress setProgressBarWidth: 13.0];
    [mainViewCircleProgress setStartAngle: -90.0];
}

-(void)updateSyncProgressByValue:(float)unitProgressValue
{
    syncProgressValue = syncProgressValue + unitProgressValue;
    [percentageLabel setText:[NSString stringWithFormat:@"%d %%", (int)syncProgressValue]];
    [mainViewCircleProgress setProgress:(syncProgressValue/100.0) animated:YES];
}

@end
