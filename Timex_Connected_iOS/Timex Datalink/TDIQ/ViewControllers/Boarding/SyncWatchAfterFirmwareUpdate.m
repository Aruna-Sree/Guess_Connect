//
//  SyncWatchAfterFirmwareUpdate.m
//  timex
//
//  Created by Raghu on 25/01/17.
//  Copyright © 2017 iDevices, LLC. All rights reserved.
//

#import "SyncWatchAfterFirmwareUpdate.h"
#import "TDDefines.h"
#import "iDevicesUtil.h"
#import "TDDeviceManager.h"

#import "TDWatchProfile.h"
#import "OTLogUtil.h"
#import "PCCommChargeInfo.h"
#import "PCCommWhosThere.h"
#import "TDM328WatchSettingsUserDefaults.h"
#import "TDAppDelegate.h"
#import "MFSideMenuContainerViewController.h"
#import "HelpViewController.h"
#import "TDM372ActigraphyDataFile.h"
#import "TDM372SleepSummaryFile.h"
#import "TDM372ActigraphyKeyFile.h"
#import "TDM372WatchActivity.h"
#import "UpdateFirmwareViewController.h"
#import "CalibratingWatchViewController.h"
#import "TDM372ActigraphyStepFile.h"

#define UNIT_PROGRESS_VALUE 4.3
@interface SyncWatchAfterFirmwareUpdate ()
{
    int mReconnectAttempts;
    
    int watchFrame;
    NSTimer *animation;
    float syncProgressValue;
}

@end

@implementation SyncWatchAfterFirmwareUpdate

- (void)viewDidLoad {
    [super viewDidLoad];
    
    PeripheralDevice * timexDevice = [iDevicesUtil getConnectedTimexDevice];
    if (timexDevice)
    {
        [[TDDeviceManager sharedInstance] disconnect: timexDevice];
    }
    
    self.navigationItem.titleView = [iDevicesUtil getNavigationTitle];
    self.navigationItem.hidesBackButton = YES;
    
    titleLabel.adjustsFontSizeToFitWidth = true;
    titleLabel.minimumScaleFactor = 0.5;
    
    
    if (IS_IPAD) {
        infoLblTopConstraint.constant = 70;
        infoLblleftConstraint.constant = infoLblRightConstraint.constant = 60;
    } else {
        infoLblleftConstraint.constant = infoLblRightConstraint.constant = 40;
    }
    infoLblBottomContraint.constant = ((ScreenHeight)/2) - 70 - M328_REGISTRATION_BOTTOM_CONSTRAINT_MINUSVALUE;
    
    progressLbl.backgroundColor = UIColorFromRGB(AppColorRed);
    progressLblWidthContraint.constant = ScreenWidth * ([iDevicesUtil getProgressBarValueBasedOnRegistrationEnum:updateFirmware]);
    
    titleLabel.attributedText = [self getAttributedStrWithText:NSLocalizedString(@"Reconnect your watch",nil)
                                             mediumFormatText:NSLocalizedString(@"Crown",nil)
                                            mediumFormatText2:NSLocalizedString(@"3 tone melody",nil)
                                                    formatStr:NSLocalizedString(@"\n\nTo connect your watch with the phone, press and hold the Crown for about 5 seconds until you hear a 3 tone melody and the hands move together.",nil)];
    [activityIndicator startAnimating];
    activityIndicator.hidden = NO;
    [self performSelector:@selector(startAction) withObject:nil afterDelay:2];
    
    [mainViewCircleProgress setHidden:YES];
    [connectingToWatchLabel setHidden:YES];
    
    watchFrame = 0;
    animation = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(watchAnimation) userInfo:nil repeats:YES];
    
    [self setupProgressView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    TDAppDelegate *appdel = (TDAppDelegate *)[[UIApplication sharedApplication] delegate];
    appdel.customTabbar.autoSyncAllowed = NO;
}
-(void)addObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(WatchInfoRead:) name: kTDWatchInfoReadSuccessfullyNotification object: nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(WatchInfoReadFailed:) name: kTDWatchInfoReadUnsuccessfullyNotification object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(lostPeriPheralConnection:) name: kPeripheralDeviceAuthorizationFailedNotification object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(lostPeriPheralConnection:) name: kDeviceManagerDeviceLostConnectiondNotification object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(WatchChargeInfoRead:) name: kTDWatchChargeInfoReadSuccessfullyNotification object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(WatchM328SettingsRead:) name: kTDM328SettingsReadSuccessfullyNotification object: nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(WatchM328SettingsReadFailed) name: kTDM328SettingsReadUnsuccessfullyNotification object: nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(BLEResponseNotRecieved) name: kTDM328DidNotRecieveBLEResponse object: nil];
    //    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(deviceListChanged:) name: kDeviceManagerConnectedDevicesChangedNotification object: nil];
    
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncFailed) name:kDeviceManagerDeviceLostConnectiondNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncFailed) name:kPeripheralDeviceAuthorizationFailedNotification object: nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(unexpectedBootloaderModeForM372DetectedAndApproved:) name: kTDM372UnexpectedBootloaderModeDetectedAndApproved object: nil];
}

-(void)removeObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kTDWatchInfoReadSuccessfullyNotification object: nil];
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kTDWatchInfoReadUnsuccessfullyNotification object: nil];
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kPeripheralDeviceAuthorizationFailedNotification object: nil];
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kDeviceManagerDeviceLostConnectiondNotification object: nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kTDWatchChargeInfoReadSuccessfullyNotification object: nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kTDM328SettingsReadSuccessfullyNotification object: nil];
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kTDM328SettingsReadUnsuccessfullyNotification object: nil];
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kTDM328DidNotRecieveBLEResponse object: nil];
    //    [[NSNotificationCenter defaultCenter] removeObserver: self name: kDeviceManagerConnectedDevicesChangedNotification object: nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kTDM372ActigraphyStepFileDataSuccessfullyNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kTDM372ActigraphyStepFileDataUnsuccessfullyNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kTDM372SleepActigraphyDataSuccessfullyNotification object: nil];
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kTDM372SleepActigraphyDataUnsuccessfullyNotification object: nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kTDM372SleepSummarySuccessfullyNotification object: nil];
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kTDM372SleepSummaryUnsuccessfullyNotification object: nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kTDM372SleepKeyFileReadSuccessfullyNotification object: nil];
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kTDM372SleepKeyFileReadUnsuccessfullyNotification object: nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kTDM372ActivitiesReadSuccessfullyNotification object: nil];
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kTDM372ActivitiesReadUnsuccessfullyNotification object: nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kTDSettingsWrittenSuccessfullyNotification object: nil];
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kTDSettingsWrittenUnsuccessfullyNotification object: nil];
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kTDApptsWrittenSuccessfullyNotification object: nil];
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kTDApptsWrittenUnsuccessfullyNotification object: nil];
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kTDPhoneTimeWrittenSuccessfullyNotification object: nil];
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kTDPhoneTimeWrittenUnsuccessfullyNotification object: nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kPeripheralDeviceTimexDatalinkPrimaryCharacteristicDiscovered object: nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver: self name:kDeviceManagerDeviceLostConnectiondNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver: self name:kPeripheralDeviceAuthorizationFailedNotification object: nil];
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kTDM372UnexpectedBootloaderModeDetectedAndApproved object: nil];
}

- (NSAttributedString *)getAttributedStrWithText:(NSString *)textStr
                                mediumFormatText:(NSString *)mediumFormatStr
                               mediumFormatText2:(NSString *)mediumFormatStr2
                                       formatStr:(NSString *)formatStr
{
    //Title
    UIFont *textFont = [UIFont fontWithName:[iDevicesUtil getAppWideFontName]
                                       size:M328_REGISTRATION_TITLE_FONTSIZE];
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:textFont,
                          NSFontAttributeName,
                          [UIColor blackColor],
                          NSForegroundColorAttributeName,
                          nil];
    NSMutableAttributedString *textAtrStr = [[NSMutableAttributedString alloc] initWithString:textStr
                                                                                   attributes:dict];
    //Body
    UIFont *formatFont = [UIFont fontWithName:[iDevicesUtil getAppWideMediumFontName]
                                         size:M328_REGISTRATION_INFO_FONTSIZE];
    NSDictionary *atrsDict = [NSDictionary dictionaryWithObjectsAndKeys:formatFont,
                              NSFontAttributeName,
                              UIColorFromRGB(COLOR_DEFAULT_TIMEX_FONT),
                              NSForegroundColorAttributeName,
                              nil];
    NSMutableAttributedString *formatAtrStr = [[NSMutableAttributedString alloc] initWithString:formatStr
                                                                                     attributes:atrsDict];
    //Bold Words
    NSDictionary *dict2 = [NSDictionary dictionaryWithObjectsAndKeys:formatFont,
                           NSFontAttributeName,
                           [UIColor blackColor],
                           NSForegroundColorAttributeName,
                           nil];
    NSRange formatStrRange = [formatStr rangeOfString:mediumFormatStr];
    [formatAtrStr setAttributes:dict2
                          range:formatStrRange];
    NSRange formatStrRange2 = [formatStr rangeOfString:mediumFormatStr2];
    [formatAtrStr setAttributes:dict2
                          range:formatStrRange2];
    
    [textAtrStr appendAttributedString:formatAtrStr];
    return textAtrStr;
}

- (void)watchAnimation
{
    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)
    {
        switch (watchFrame)
        {
            case 0:
            case 1:
                watchSetup.image = [UIImage imageNamed:@"TravelSetup"];
                watchFrame++;
                break;
            case 2:
                watchSetup.image = [UIImage imageNamed:@"TravelSetup1"];
                watchFrame++;
                break;
            case 3:
                watchSetup.image = [UIImage imageNamed:@"TravelSetup2"];
                watchFrame++;
                break;
            case 4:
            case 5:
                watchSetup.image = [UIImage imageNamed:@"TravelSetup3"];
                watchFrame++;
                break;
            case 6:
            case 7:
                watchSetup.image = [UIImage imageNamed:@"TravelSetup4"];
                watchFrame++;
                break;
            case 8:
            case 9:
                watchSetup.image = [UIImage imageNamed:@"TravelSetup5"];
                watchFrame++;
                break;
            case 10:
            case 11:
                watchSetup.image = [UIImage imageNamed:@"TravelSetup6"];
                watchFrame++;
                break;
            case 12:
            case 13:
                watchSetup.image = [UIImage imageNamed:@"TravelSetup7"];
                watchFrame++;
                break;
            case 14:
            case 15:
                watchSetup.image = [UIImage imageNamed:@"TravelSetup8"];
                watchFrame++;
                break;
            case 16:
                watchSetup.image = [UIImage imageNamed:@"TravelSetup9"];
                watchFrame++;
                break;
            case 17:
                watchSetup.image = [UIImage imageNamed:@"TravelSetup10"];
                watchFrame++;
                break;
            case 18:
                watchSetup.image = [UIImage imageNamed:@"TravelSetup11"];
                watchFrame++;
                break;
            case 19:
                watchSetup.image = [UIImage imageNamed:@"TravelSetup12"];
                watchFrame++;
                break;
            case 20:
                watchSetup.image = [UIImage imageNamed:@"TravelSetup13"];
                watchFrame++;
                break;
            case 21:
            case 22:
            case 23:
            case 24:
                watchSetup.image = [UIImage imageNamed:@"TravelSetup14"];
                watchFrame++;
                break;
            case 26:
                watchFrame = 0;
                break;
            default:
                watchFrame++;
                break;
        }
    }
    else
    {
        switch (watchFrame)
        {
            case 0:
            case 1:
                watchSetup.image = [UIImage imageNamed:@"WatchSetup"];
                watchFrame++;
                break;
            case 2:
                watchSetup.image = [UIImage imageNamed:@"WatchSetup1"];
                watchFrame++;
                break;
            case 3:
                watchSetup.image = [UIImage imageNamed:@"WatchSetup2"];
                watchFrame++;
                break;
            case 4:
            case 5:
                watchSetup.image = [UIImage imageNamed:@"WatchSetup3"];
                watchFrame++;
                break;
            case 6:
            case 7:
                watchSetup.image = [UIImage imageNamed:@"WatchSetup4"];
                watchFrame++;
                break;
            case 8:
            case 9:
                watchSetup.image = [UIImage imageNamed:@"WatchSetup5"];
                watchFrame++;
                break;
            case 10:
            case 11:
                watchSetup.image = [UIImage imageNamed:@"WatchSetup6"];
                watchFrame++;
                break;
            case 12:
            case 13:
                watchSetup.image = [UIImage imageNamed:@"WatchSetup7"];
                watchFrame++;
                break;
            case 14:
            case 15:
                watchSetup.image = [UIImage imageNamed:@"WatchSetup8"];
                watchFrame++;
                break;
            case 16:
                watchSetup.image = [UIImage imageNamed:@"WatchSetup9"];
                watchFrame++;
                break;
            case 17:
                watchSetup.image = [UIImage imageNamed:@"WatchSetup10"];
                watchFrame++;
                break;
            case 18:
                watchSetup.image = [UIImage imageNamed:@"WatchSetup11"];
                watchFrame++;
                break;
            case 19:
                watchSetup.image = [UIImage imageNamed:@"WatchSetup12"];
                watchFrame++;
                break;
            case 20:
                watchSetup.image = [UIImage imageNamed:@"WatchSetup13"];
                watchFrame++;
                break;
            case 21:
            case 22:
            case 23:
            case 24:
                watchSetup.image = [UIImage imageNamed:@"WatchSetup14"];
                watchFrame++;
                break;
            case 26:
                watchFrame = 0;
                break;
            default:
                watchFrame++;
                break;
        }
    }
}


- (void)startAction {
    BLEManager *bleManager = [[TDDeviceManager sharedInstance] getBleManager];
    if ([bleManager isBLESupported] && [bleManager isBLEAvailable])
    {
        [self addObservers];
        [self reconnectToDevice];
    }
    else
    {
        NSString * title = NSLocalizedString(@"Bluetooth unavailable", nil);
        NSString * msg = nil;
        if (![bleManager isBLESupported])
        {
            msg = NSLocalizedString(@"Bluetooth is not available on this device.", nil);
        }
        else if (![bleManager isBLEAvailable])
        {
            msg = NSLocalizedString(@"Bluetooth is powered off. Please turn on Bluetooth in System Settings before proceeding.", nil);
        }
        
        TDAppDelegate *delegate = (TDAppDelegate *)[[UIApplication sharedApplication] delegate];
        [delegate showAlertWithTitle:title Message:msg andButtonTitle:@"Ok"];
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
                [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Guess Connect",nil) message:NSLocalizedString(@"Failed to connect to device",nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Try Again", nil) otherButtonTitles:nil] show];
            }
            else
            {
                OTLog(@"Attempting to reconnect...");
                [self performSelector:@selector(reconnectToDevice) withObject:nil afterDelay: 1.0];
            }
        }
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [self reconnectToDevice];
}

- (void) setupProgressView
{
    syncProgressValue = 0;
    [percentageLabel setText:@"0 %"];
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

#pragma mark - successfullyConnectedToDevice
-(void) successfullyConnectedToDevice:(NSNotification*)notification
{
    OTLog(@"successfullyConnectedToDevice");
    titleLabel.attributedText = [self getAttributedStrWithText:NSLocalizedString(@"Watch connected",nil)
                                              mediumFormatText:@""
                                             mediumFormatText2:@""
                                                     formatStr:[NSString stringWithFormat:@"\n\n%@",NSLocalizedString(@"Performing sync to turn on Activity tracking",nil)]];
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kPeripheralDeviceTimexDatalinkPrimaryCharacteristicDiscovered object: nil];
    
    [mainViewCircleProgress setHidden:NO];
    [connectingToWatchLabel setHidden:NO];
    
    [activityIndicator stopAnimating];
    [activityIndicator setHidden:YES];
    
    [self performSelector:@selector(startFullFileReadWithSubsequentWritingToWatch) withObject:nil afterDelay: 1.0];
}

-(void)lostPeriPheralConnection:(NSNotification*)notification {
    OTLog(@"lostPeriPheralConnection");
    [self syncFailed];
}

-(void) startFullFileReadWithSubsequentWritingToWatch
{
    titleLabel.attributedText = [self getAttributedStrWithText:NSLocalizedString(@"Sync in progress",nil)
                                              mediumFormatText:@""
                                             mediumFormatText2:@""
                                                     formatStr:[NSString stringWithFormat:@"\n\n%@",NSLocalizedString(@"Performing sync to turn on Activity tracking",nil)]];
    OTLog(@"startFullFileReadWithSubsequentWritingToWatch");
    PeripheralDevice * timexDevice = [iDevicesUtil getConnectedTimexDevice];
    if (timexDevice != nil)
    {
        if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQ || [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)
        {
            [timexDevice readTimexWatchActivityData];
            [timexDevice readTimexWatchSleepSummary];//TestLog_SleepFiles
            [timexDevice readTimexWatchSleepKeyFile];//TestLog_SleepFiles
            [timexDevice readTimexWatchSleepActigraphyFiles];//TestLog_SleepFiles
            [timexDevice readTimexWatchActigraphyStepFiles];
        }
    }
}

#pragma mark Selectors
- (void) WatchInfoRead: (NSNotification*)notification
{
    OTLog(@"WatchInfoRead");
    
    [self updateSyncProgressByValue:UNIT_PROGRESS_VALUE];
    
    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQ || [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)
    {
        PCCommWhosThere * newSettings = [notification.userInfo objectForKey: kDeviceWatchInfoKey];
        if (newSettings)
        {
            [[NSUserDefaults standardUserDefaults] setObject:newSettings.mSerialNumber forKey:WATCH_SERIAL_NUMBER];
            [[NSUserDefaults standardUserDefaults]synchronize];
        }
    }
}
- (void) WatchInfoReadFailed: (id) sender
{
    OTLog(@"WatchInfoReadFailed");
    [self syncFailed];
}

- (void) WatchChargeInfoRead: (NSNotification*)notification
{
    OTLog(@"WatchChargeInfoRead");
    [self updateSyncProgressByValue:UNIT_PROGRESS_VALUE];
    
    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQ || [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)
    {
        
        PCCommChargeInfo * chargeInfo = [notification.userInfo objectForKey: kDeviceWatchChargeInfoKey];
        if (chargeInfo)
        {
            
            NSString * batteryChargeStatus = NSLocalizedString(@"LOW", @"Modification Date: 06/01/2015");
            [TDM328WatchSettingsUserDefaults setBatteryVolt:chargeInfo.voltage];
            if (chargeInfo.voltage > M372_GOOD_VOLTAGE_THRESHOLD)
            {
                batteryChargeStatus = NSLocalizedString(@"GOOD", @"Modification Date: 06/01/2015");
            }
            else
            {
                TDAppDelegate * delegate = (TDAppDelegate *)[UIApplication sharedApplication].delegate;
                UINavigationController * navBar = (UINavigationController *)((MFSideMenuContainerViewController *)delegate.window.rootViewController).centerViewController;
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Watch Battery Low", @"Modification Date: 06/01/2015")
                                                                               message:NSLocalizedString(@"You will need to replace your watch battery soon.", @"Modification Date: 06/01/2015")
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                
                [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Remind me later", nil)
                                                          style:UIAlertActionStyleCancel
                                                        handler:^(UIAlertAction * _Nonnull action){}]];
                
                [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Learn More", nil)
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction * _Nonnull action)
                                  {
                                      HelpViewController *helpVC=[[HelpViewController alloc] initWithNibName:@"HelpViewController" bundle:nil];
                                      NSArray *controllers = [NSArray arrayWithObject: helpVC];
                                      navBar.viewControllers = controllers;
                                  }]];
                
                [navBar presentViewController:alert animated:YES completion:nil];
            }
        }
    }
}


- (void) WatchM328SettingsRead: (NSNotification*)notification
{
    OTLog(@"WatchM328SettingsRead");
    [self updateSyncProgressByValue:UNIT_PROGRESS_VALUE];
    
    TDM328WatchSettings * newData = [notification.userInfo objectForKey: kM328SettingsDataFileKey];
    if (newData)
    {
        [newData serializeIntoSettings];
    }
}
- (void) WatchM328SettingsReadFailed
{
    OTLog(@"WatchM328SettingsReadFailed");
    [self syncFailed];
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
    [self syncFailed];
    
}

- (void) WatchM372SleepActigraphyData: (NSNotification*)notification
{
    OTLog(@"WatchM372SleepActigraphyData");
    [self updateSyncProgressByValue:UNIT_PROGRESS_VALUE];
    
    TDM372ActigraphyDataFile * newData = [notification.userInfo objectForKey: kM372ActigraphyDataFile];
    if (newData)
    {
        [[NSUserDefaults standardUserDefaults] setObject: [NSDate date] forKey: kLastActivityTrackerSyncSyncDate];
    }
}
- (void) WatchM372SleepActigraphyDataFailed
{
    OTLog(@"WatchM372SleepActigraphyDataFailed");
    [self syncFailed];
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
    }
}
- (void) WatchM372ActigraphyStepDataFailed
{
    OTLog(@"WatchM372ActigraphyStepDataFailed");
    [self syncFailed];
}

- (void) WatchM372SleepSummaryRead: (NSNotification*)notification
{
    OTLog(@"WatchM372SleepSummaryRead");
    [self updateSyncProgressByValue:UNIT_PROGRESS_VALUE];
    
    TDM372SleepSummaryFile * newData = [notification.userInfo objectForKey: kM372SleepSummaryFileKey];
    if (newData)
    {
        [[NSUserDefaults standardUserDefaults] setObject: [NSDate date] forKey: kLastActivityTrackerSyncSyncDate];
    }
}
- (void) WatchM372SleepSummaryReadFailed
{
    OTLog(@"WatchM372SleepSummaryReadFailed");
    [self syncFailed];
}


- (void) WatchM372SleepKeyFileRead: (NSNotification*)notification
{
    OTLog(@"WatchM372SleepKeyFileRead");
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
    OTLog(@"WatchM372SleepKeyFileReadFailed");
    [self syncFailed];
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
    OTLog(@"WatchM372ActivitiesReadFailed");
    [self syncFailed];
}

- (void) SettingsSaved: (NSNotification*)notification
{
    OTLog(@"SettingsSaved");
    
    float remainingPercentage = (100-syncProgressValue);
    NSLog(@"update remaing percentage %f", remainingPercentage);
    [self updateSyncProgressByValue:remainingPercentage];
    
    [TDM328WatchSettingsUserDefaults setSyncNeeded:NO];
    [self syncFinished];
}
- (void) SettingsSaveFailed: (NSNotification*)notification
{
    OTLog(@"SettingsSaveFailed");
    [self syncFailed];
}

- (void) ApptsSaved: (NSNotification*)notification
{
    OTLog(@"ApptsSaved");
    [self syncFinished];
    [TDM328WatchSettingsUserDefaults setSyncNeeded:NO];
}
- (void) ApptsSaveFailed: (NSNotification*)notification
{
    OTLog(@"ApptsSaveFailed");
    [self syncFailed];
}

-(void)endFileAccessSession
{
    OTLog(@"endFileAccessSession");
    PeripheralDevice * timexDevice = [iDevicesUtil getConnectedTimexDevice];
    if (timexDevice)
    {
        [timexDevice endFileAccessSession];
    }
}


#pragma mark - bootloader
-(void)unexpectedBootloaderModeForM372DetectedAndApproved:(NSNotification*)notification
{
    OTLog(@"moveToFirmwareUpdate");
    UpdateFirmwareViewController *updateFirmwareVC=[[UpdateFirmwareViewController alloc] initWithNibName:@"UpdateFirmwareViewController" bundle:nil];
    updateFirmwareVC.unstickBootloader = YES;
    updateFirmwareVC.openedByMenu = YES;
    
    TDAppDelegate * delegate = (TDAppDelegate *)[UIApplication sharedApplication].delegate;
    UINavigationController * navBar = (UINavigationController *)((MFSideMenuContainerViewController *)delegate.window.rootViewController).centerViewController;
    NSArray *controllers = [NSArray arrayWithObject: updateFirmwareVC];
    navBar.viewControllers = controllers;
    MFSideMenuContainerViewController *sideContainer =(MFSideMenuContainerViewController *)delegate.window.rootViewController;
    [sideContainer setMenuState:MFSideMenuStateClosed];
    [navBar.navigationBar setUserInteractionEnabled:YES];
    
}
- (void)BLEResponseNotRecieved {
    OTLog(@"BLEResponseNotRecieved");
    [self syncFailed];
}

-(void)syncFinished
{
    [self removeObservers];
    
    [self performSelector:@selector(moveToCalibrationScren) withObject:nil afterDelay:2];
}

- (void)syncFailed
{
    OTLog(@"syncFailed");
    PeripheralDevice * timexDevice = [iDevicesUtil getConnectedTimexDevice];
    if (timexDevice)
    {
        [timexDevice endFileAccessSession];
        [timexDevice disconnect];
    }
    
    [self removeObservers];
    
    [self showErrorAlert];
    
    [mainViewCircleProgress setHidden:YES];
    [connectingToWatchLabel setHidden:YES];
    
    [activityIndicator startAnimating];
    [activityIndicator setHidden:NO];

}


-(void)moveToCalibrationScren
{
    [self endFileAccessSession];
    CalibratingWatchViewController *calibVC = [[CalibratingWatchViewController alloc] initWithNibName:@"CalibratingWatchViewController" bundle:nil doSettingsMenuCalibration:_openedByMenu];
    calibVC.openCalibration = self.openCalibration;
    [self.navigationController pushViewController:calibVC animated:YES];
    
    [animation invalidate];
}

-(void)showErrorAlert
{
   UIAlertController *_noWatchFounded = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Unable to Sync", nil)
                                                          message:NSLocalizedString(@"There was a problem when trying to connect to your watch.", nil)
                                                   preferredStyle:UIAlertControllerStyleAlert];
    
    [_noWatchFounded addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                        style:UIAlertActionStyleCancel
                                                      handler:^(UIAlertAction * _Nonnull action)
                                {
                                    [self.navigationController popToRootViewControllerAnimated:YES];
                                }]];
    
    [_noWatchFounded addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Try Again", nil)
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * _Nonnull action)
                                {
                                    OTLog(@"clickedOnTryAgain");
                                    
                                    [self startAction];
                                }]];
    
    [self presentViewController:_noWatchFounded animated:YES completion:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    TDAppDelegate *appdel = (TDAppDelegate *)[[UIApplication sharedApplication] delegate];
    appdel.customTabbar.autoSyncAllowed = YES;
}
@end
