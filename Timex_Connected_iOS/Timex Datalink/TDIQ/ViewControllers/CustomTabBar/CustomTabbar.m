//
//  CustomTabbar.m
//  TableViewCellTest
//
//  Created by Aruna Kumari Yarra on 28/03/16.
//

#import "CustomTabbar.h"
#import "TDDefines.h"
#import "iDevicesUtil.h"
#import "TDAppDelegate.h"
#import "HelpViewController.h"
#import "PCCommWhosThere.h"
#import "BLEPeripheral.h"
#import "TDM372WatchActivity.h"
#import "TDHomeViewController.h"
#import "TDDeviceManager.h"
#import "MFSideMenuContainerViewController.h"
#import "TDWatchProfile.h"
#import "PCCommChargeInfo.h"
#import "TDM328WatchSettings.h"
#import "TDM372ActigraphyKeyFile.h"
#import "TDM372ActigraphyDataFile.h"
#import "TDM372SleepSummaryFile.h"
#import "TDM372ActigraphyStepFile.h"
#import "OTLogUtil.h"
#import "SleepHistoryViewController.h"
#import "TDM328WatchSettingsUserDefaults.h"
#import "MBProgressHUD.h"
#import "PCCommExtendedFirmwareVersionInfo.h"
#import <TCBlobDownload/TCBlobDownload.h>
#import "UpdateFirmwareViewController.h"
#import "HelpViewController.h"
#import "SYSBLOCKSettings.h"
#import "CalibratingWatchViewController.h"
#import "TDHomeViewController.h"
#import "SettingsViewController.h"
#import "CustomAlertViewController.h"
#import "TDM329WatchSettingsUserDefaults.h"
#import "TDGetInTouchViewController.h"

NSString* const kLAST_FIRMWARE_CHECK_DATE_NEW = @"kLAST_FIRMWARE_CHECK_DATE_NEW";
NSString* const kFirmwareCheckUserInitiatedNotificationNew = @"kFirmwareCheckUserInitiatedNotificationNew";
NSString* const kFirmwareRequestUserInitiatedNotificationNew = @"kFirmwareRequestUserInitiatedNotificationNew";
NSString* const kM328WatchResetUserInitiatedNotificationNew = @"kM328WatchResetUserInitiatedNotificationNew";

@interface CustomTabbar(){
    // tracks if the sync is in progress.
    MBProgressHUD   *  HUD;
    BOOL isSyncInProgress;
    BOOL alertBarComplete;
    UITapGestureRecognizer *tap;
    UIAlertController *cancel;
    UIAlertController *syncFailAlert;
    int count;
    NSTimer *timer;
    NSTimer *animation;
    int watchFrame;
    NSTimer *reconnection;
    NSMutableArray  * _mFirmwareUpgradeInfo;
    
    BOOL syncCancelled;
}
@end

@implementation CustomTabbar
@synthesize autoSyncAllowed;

- (id)initWithFrame:(CGRect)frame {
    
    // TO Make or not to make the super init call?
    
    
    self = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:self options:nil] objectAtIndex:0];
    self.frame = frame;
    _lastSynLbl.font = [UIFont fontWithName:[iDevicesUtil getAppWideMediumFontName] size:M328_HOME_SCREEN_FORMAT_STRING_FONT_SIZE];
    
    if (IS_IPAD) {
        _infoLblTopConstraint.constant = 70;
        _infoLblleftConstraint.constant = _infoLblRightConstraint.constant = 40;
    } else {
        _infoLblleftConstraint.constant = _infoLblRightConstraint.constant = 20;
    }
    
    [self updateLastLblText];
    alertBarComplete = YES;
    _alertBarIsUp = NO;
    
    synImgView.backgroundColor = UIColorFromRGB(AppColorRed);
    synImgView.layer.cornerRadius = 25;
    synImgView.layer.masksToBounds = YES;
    
    _alertBar.layer.cornerRadius = 10;
    _alertBar.layer.masksToBounds = YES;
    
    stillAnimationgButton = NO;
    [syncImg setImage:[UIImage imageNamed:@"Sync"] forState:UIControlStateNormal];
    
    // Add Notifications for devices list changed.
    
    
    bleManager = [[TDDeviceManager sharedInstance] getBleManager];;
    
    isSyncInProgress = NO;
    autoSyncAllowed = YES;
    [self setupSyncIcon];
    alignNowBtn.titleLabel. numberOfLines = 0;
    alignNowBtn.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    [self removeDevicesChangedNotificaiton];
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(deviceListChanged:) name: kDeviceManagerConnectedDevicesChangedNotification object: nil];
    return self;
}

- (void) alertBarUp
{
    if (alertBarComplete && !_alertBarIsUp)
    {
        CGRect newFrame = _alertBar.frame;
        newFrame.origin.y -= 50;
        [UIView animateWithDuration:.5
                              delay:0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^
         {
             _alertBar.frame = newFrame;
         }
                         completion:^(BOOL finished)
         {
             if (finished)
             {
                 alertBarComplete = YES;
             }
         }];
    }
    _alertBarIsUp = YES;
}

- (void) alertBarDown
{
    if (alertBarComplete && _alertBarIsUp)
    {
        CGRect newFrame = _alertBar.frame;
        newFrame.origin.y += 50;
        [UIView animateWithDuration:.5
                              delay:0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^
         {
             _alertBar.frame = newFrame;
         }
                         completion:^(BOOL finished)
         {
             if (finished)
             {
                 alertBarComplete = YES;
             }
         }];
    }
    _alertBarIsUp = NO;
}

- (void) moveUpOrDown:(NSTimer*)theTimer
{
    count++;
    if ([[theTimer userInfo] isEqual: @"up"]) {
        _alertBar.transform = CGAffineTransformMakeTranslation(0.0f,0.1f);
    }
    else
    {
        _alertBar.transform = CGAffineTransformMakeTranslation(0.0f,0.1f);
    }
    
    if (count == 100)
    {
        [timer invalidate];
        alertBarComplete = YES;
    }
}

- (void)deviceListChanged:(NSNotification*)notification {
    OTLog(@"deviceListChanged");
    if (!autoSyncAllowed) {
        NSLog(@"Auto sync not allowed");
        return;
    }
//    UIApplicationState state = [[UIApplication sharedApplication] applicationState];
//    if (state == UIApplicationStateBackground || state == UIApplicationStateInactive) {
//        NSDateComponents *autoSyncComponents = [[NSCalendar currentCalendar] components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond) fromDate:[NSDate date]];
//        
//        if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel && [TDM329WatchSettingsUserDefaults autoSyncTimes1_TimeEnabled]) {
//            autoSyncComponents.hour = [TDM329WatchSettingsUserDefaults autoSyncTimes1_Hour];
//            autoSyncComponents.minute = [TDM329WatchSettingsUserDefaults autoSyncTimes1_Minute];
//            autoSyncComponents.second = 0;
//        } else if ([TDM328WatchSettingsUserDefaults autoSyncTimes1_TimeEnabled]) {
//            autoSyncComponents.hour = [TDM328WatchSettingsUserDefaults autoSyncTimes1_Hour];
//            autoSyncComponents.minute = [TDM328WatchSettingsUserDefaults autoSyncTimes1_Minute];
//            autoSyncComponents.second = 0;
//        } else {
//            return;
//        }
//        NSDate *autosyncDate = [[NSCalendar currentCalendar] dateFromComponents:autoSyncComponents];
//        NSDate *autoSyncBufferDate = [autosyncDate dateByAddingTimeInterval:10];
//        NSLog(@"\nToday's date : %@\nAutoSyncDate : %@\nAutoSyncbufferDate  : %@\n",[NSDate date], autosyncDate, autoSyncBufferDate);
//        if (![iDevicesUtil date:[NSDate  date] isBetweenDate:autosyncDate andDate:autoSyncBufferDate]) {
//            OTLog(@"Manual bluetooth mode");
//            return;
//        }
//    }
    
    PeripheralDevice *connectedDevice =     [iDevicesUtil getConnectedTimexDevice];
    if (connectedDevice != nil) {
        if (!stillAnimationgButton && !isSyncInProgress) {
            NSLog(@"Performing auto sync");
            [self initSync:NO]; // Auto sync
        }
    } else {
        NSLog(@"Device disconnects in Customtabbar");
    }
}

- (void)updateLastLblText {
    TDAppDelegate *delegate = (TDAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSString *watchModel = NSLocalizedString(@"Guess iQ+  Last Sync:",nil);
    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)
    {
        watchModel = NSLocalizedString(@"iQ+ Travel  Last Sync:",nil);
    }
    _lastSynLbl.text = [NSString stringWithFormat:@"    %@ %@", watchModel,[delegate getLastSyncDate]];
}

- (void)syncNeeded
{
    [TDM328WatchSettingsUserDefaults setSyncNeeded:YES];
    syncImg.transform = CGAffineTransformIdentity;
    [syncImg setImage:[UIImage imageNamed:@"SyncNeeded"] forState:UIControlStateNormal];
}

- (IBAction)calibrateTap:(id)sender
{
    syncViewBgLbl.hidden = YES;
    syncFailedView.hidden = YES;
    CalibratingWatchViewController *calibVC = [[CalibratingWatchViewController alloc] initWithNibName:@"CalibratingWatchViewController" bundle:nil doSettingsMenuCalibration:YES];
    calibVC.openCalibration = YES;
    [self AssignNewControllerToCenterControllerNew:calibVC];
}

- (IBAction)clickedOnContactNow {
    [self removeSyncView];
    TDGetInTouchViewController *getInTouchVC = [[TDGetInTouchViewController alloc] initWithNibName:@"TDGetInTouchViewController" bundle:nil];
    [topVC.navigationController pushViewController:getInTouchVC animated:YES];
}

- (void)backFromGetInTouchScreen {
    [syncView setHidden:NO];
    [self performSelector:@selector(disableUserInteraction) withObject:nil afterDelay:0.2];
}

- (IBAction)clickedOnSync {
    OTLog(@"clickedOnSync");
    TDAppDelegate *delegate = (TDAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (!isSyncInProgress)
    {
        if ([bleManager isBLESupported] && [bleManager isBLEAvailable])
        {
            [self initSync:NO];
        } else {
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
            
            [delegate showAlertWithTitle:title Message:msg andButtonTitle:@"Ok"];
        }
    }
}

- (void)goalsAndALramSyncStarted {
    OTLog(@"initSync");
    [self displaySyncView];
    syncFailedView.hidden = YES;
    
    if (!tap)
    {
        tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                      action:@selector(cancelOrNot)];
    }
    [syncView removeGestureRecognizer:tap];
    [syncView addGestureRecognizer:tap];
    
    stillAnimationgButton = YES;
    
    UIView *view = self.superview;
    topVC = [view.nextResponder isKindOfClass:[UIViewController class]] ? (UIViewController *)view.nextResponder : nil;
    
    if (topVC != nil) {
        [topVC.navigationController.navigationBar setUserInteractionEnabled:NO];
    }
    
    mInitialSetupSynchronization = NO;
    mCurrentSyncActionSelected = syncActionsEnum_PhoneOverWatch;
    
    [self moreNotificationViewWillAppear];
    syncViewBgLbl.backgroundColor = [UIColor clearColor];
}

- (void)initSync:(BOOL)autoSync{
    OTLog(@"initSync");
    syncCancelled = NO;
    isSyncInProgress = NO;
    [self alertBarDown];
    [self displaySyncView];
    syncFailedView.hidden = YES;
    
    if (!tap)
    {
        tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                      action:@selector(cancelOrNot)];
    }
    [syncView removeGestureRecognizer:tap];
    [syncView addGestureRecognizer:tap];
    
    stillAnimationgButton = YES;
    [self rotateImageView];
    [animation invalidate];
    [reconnection invalidate];
    
    UIView *view = self.superview;
    topVC = [view.nextResponder isKindOfClass:[UIViewController class]] ? (UIViewController *)view.nextResponder : nil;
    
    if (topVC != nil)
    {
        [topVC.navigationController.navigationBar setUserInteractionEnabled:NO];
    }
    
   // [self connectToDevice];
    mInitialSetupSynchronization = autoSync;
    if (mInitialSetupSynchronization)
        mCurrentSyncActionSelected = syncActionsEnum_WatchOverPhone;
    else
        mCurrentSyncActionSelected = syncActionsEnum_Unselected;
    
    [self moreNotificationViewWillAppear];
    [self startAction];

    [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(syncWatchView) userInfo:nil repeats:NO];
}

- (void)syncWatchView
{
    syncFailedView.hidden = NO;
    _textLbl.attributedText = [self getAttributedStrWithText:NSLocalizedString(@"Syncing your watch",nil)
                                             mediumFormatText:NSLocalizedString(@"Crown",nil)
                                            mediumFormatText2:NSLocalizedString(@"3 tone melody",nil)
                                                    formatStr:NSLocalizedString(@"\n\nTo connect your watch with the phone, press and hold the Crown for about 5 seconds until you hear a 3 tone melody and the hands move together.",nil)];
    // Watch animation
    watchFrame = 0;
    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)
    {
        _headerImg.image = [UIImage imageNamed:@"TravelSetup"];
    }
    
    animation = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(watchAnimation) userInfo:nil repeats:YES];
}


- (void)watchAnimation
{
    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)
    {
        switch (watchFrame)
        {
            case 0:
            case 1:
                _headerImg.image = [UIImage imageNamed:@"TravelSetup"];
                watchFrame++;
                break;
            case 2:
                _headerImg.image = [UIImage imageNamed:@"TravelSetup1"];
                watchFrame++;
                break;
            case 3:
                _headerImg.image = [UIImage imageNamed:@"TravelSetup2"];
                watchFrame++;
                break;
            case 4:
            case 5:
                _headerImg.image = [UIImage imageNamed:@"TravelSetup3"];
                watchFrame++;
                break;
            case 6:
            case 7:
                _headerImg.image = [UIImage imageNamed:@"TravelSetup4"];
                watchFrame++;
                break;
            case 8:
            case 9:
                _headerImg.image = [UIImage imageNamed:@"TravelSetup5"];
                watchFrame++;
                break;
            case 10:
            case 11:
                _headerImg.image = [UIImage imageNamed:@"TravelSetup6"];
                watchFrame++;
                break;
            case 12:
            case 13:
                _headerImg.image = [UIImage imageNamed:@"TravelSetup7"];
                watchFrame++;
                break;
            case 14:
            case 15:
                _headerImg.image = [UIImage imageNamed:@"TravelSetup8"];
                watchFrame++;
                break;
            case 16:
                _headerImg.image = [UIImage imageNamed:@"TravelSetup9"];
                watchFrame++;
                break;
            case 17:
                _headerImg.image = [UIImage imageNamed:@"TravelSetup10"];
                watchFrame++;
                break;
            case 18:
                _headerImg.image = [UIImage imageNamed:@"TravelSetup11"];
                watchFrame++;
                break;
            case 19:
                _headerImg.image = [UIImage imageNamed:@"TravelSetup12"];
                watchFrame++;
                break;
            case 20:
                _headerImg.image = [UIImage imageNamed:@"TravelSetup13"];
                watchFrame++;
                break;
            case 21:
            case 22:
            case 23:
            case 24:
                _headerImg.image = [UIImage imageNamed:@"TravelSetup14"];
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
                _headerImg.image = [UIImage imageNamed:@"WatchSetup"];
                watchFrame++;
                break;
            case 2:
                _headerImg.image = [UIImage imageNamed:@"WatchSetup1"];
                watchFrame++;
                break;
            case 3:
                _headerImg.image = [UIImage imageNamed:@"WatchSetup2"];
                watchFrame++;
                break;
            case 4:
            case 5:
                _headerImg.image = [UIImage imageNamed:@"WatchSetup3"];
                watchFrame++;
                break;
            case 6:
            case 7:
                _headerImg.image = [UIImage imageNamed:@"WatchSetup4"];
                watchFrame++;
                break;
            case 8:
            case 9:
                _headerImg.image = [UIImage imageNamed:@"WatchSetup5"];
                watchFrame++;
                break;
            case 10:
            case 11:
                _headerImg.image = [UIImage imageNamed:@"WatchSetup6"];
                watchFrame++;
                break;
            case 12:
            case 13:
                _headerImg.image = [UIImage imageNamed:@"WatchSetup7"];
                watchFrame++;
                break;
            case 14:
            case 15:
                _headerImg.image = [UIImage imageNamed:@"WatchSetup8"];
                watchFrame++;
                break;
            case 16:
                _headerImg.image = [UIImage imageNamed:@"WatchSetup9"];
                watchFrame++;
                break;
            case 17:
                _headerImg.image = [UIImage imageNamed:@"WatchSetup10"];
                watchFrame++;
                break;
            case 18:
                _headerImg.image = [UIImage imageNamed:@"WatchSetup11"];
                watchFrame++;
                break;
            case 19:
                _headerImg.image = [UIImage imageNamed:@"WatchSetup12"];
                watchFrame++;
                break;
            case 20:
                _headerImg.image = [UIImage imageNamed:@"WatchSetup13"];
                watchFrame++;
                break;
            case 21:
            case 22:
            case 23:
            case 24:
                _headerImg.image = [UIImage imageNamed:@"WatchSetup14"];
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

- (void)cancelOrNot
{
    [self removeSyncView];
    
    cancel = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Cancel", nil)
                                                 message:NSLocalizedString(@"Are you sure you want to cancel?", nil)
                                          preferredStyle:UIAlertControllerStyleAlert];
    
    [cancel addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"No", nil)
                                               style:UIAlertActionStyleDefault
                                             handler:^(UIAlertAction * _Nonnull action)
                       {
                           [self displaySyncView];
                       }]];
    
    [cancel addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Yes", nil)
                                               style:UIAlertActionStyleDefault
                                             handler:^(UIAlertAction * _Nonnull action)
                       {
                           [self clickedOnCancel];
                       }]];
    
    [topVC presentViewController:cancel animated:YES completion:nil];
}

- (void)moreNotificationViewWillAppear
{
    OTLog(@"moreNotificationViewWillAppear customtabbar");
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(WatchInfoRead:) name: kTDWatchInfoReadSuccessfullyNotification object: nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(WatchChargeInfoRead:) name: kTDWatchChargeInfoReadSuccessfullyNotification object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(WatchM328SettingsRead:) name: kTDM328SettingsReadSuccessfullyNotification object: nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(WatchM328SettingsReadFailed) name: kTDM328SettingsReadUnsuccessfullyNotification object: nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(BLEResponseNotRecieved) name: kTDM328DidNotRecieveBLEResponse object: nil];
    
    //TestLog_SleepFiles
    //ActigraphyData
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(WatchM372SleepActigraphyData:) name: kTDM372SleepActigraphyDataSuccessfullyNotification object: nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(WatchM372SleepActigraphyDataFailed) name: kTDM372SleepActigraphyDataUnsuccessfullyNotification object: nil];
    
    //ActigraphyStepdata
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(WatchM372ActigraphyStepData:) name: kTDM372ActigraphyStepFileDataSuccessfullyNotification object: nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(WatchM372ActigraphyStepDataFailed) name: kTDM372ActigraphyStepFileDataUnsuccessfullyNotification object: nil];
    
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


- (void)removeObserversTosync
{
     OTLog(@"removeObserversTosync customtabbar");
    [[NSNotificationCenter defaultCenter] removeObserver:self name: kTDSettingsWrittenSuccessfullyNotification object: nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name: kTDSettingsWrittenUnsuccessfullyNotification object: nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name: kTDApptsWrittenSuccessfullyNotification object: nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name: kTDApptsWrittenUnsuccessfullyNotification object: nil];
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kPeripheralDeviceTimexDatalinkPrimaryCharacteristicDiscovered object: nil];
//    [[NSNotificationCenter defaultCenter] removeObserver: self name: kDeviceManagerConnectedDevicesChangedNotification object: nil];
    
//    [[NSNotificationCenter defaultCenter] removeObserver: self name: kPeripheralDeviceTimexDatalinkPrimaryCharacteristicDiscovered object: nil];
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kTDPhoneTimeWrittenUnsuccessfullyNotification object: nil];
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kTDPhoneTimeWrittenSuccessfullyNotification object: nil];
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kTDApptsWrittenUnsuccessfullyNotification object: nil];
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kTDApptsWrittenSuccessfullyNotification object: nil];
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kTDSettingsWrittenUnsuccessfullyNotification object: nil];
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kTDSettingsWrittenSuccessfullyNotification object: nil];
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kTDM372ActivitiesReadUnsuccessfullyNotification object: nil];
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kTDM372ActivitiesReadSuccessfullyNotification object: nil];
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kTDM372SleepKeyFileReadUnsuccessfullyNotification object: nil];
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kTDM372SleepSummaryUnsuccessfullyNotification object: nil];
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kTDM372SleepActigraphyDataUnsuccessfullyNotification object: nil];
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kTDM372SleepActigraphyDataSuccessfullyNotification object: nil];
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kTDM328DidNotRecieveBLEResponse object: nil];
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kTDM372ActigraphyStepFileDataSuccessfullyNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kTDM372ActigraphyStepFileDataUnsuccessfullyNotification object:nil];
    // Watch connection
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kDeviceManagerDeviceLostConnectiondNotification object: nil];
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kPeripheralDeviceAuthorizationFailedNotification object: nil];
}

- (NSAttributedString *)getAttributedStrWithText:(NSString *)textStr
                                mediumFormatText:(NSString *)mediumFormatStr
                               mediumFormatText2:(NSString *)mediumFormatStr2
                                       formatStr:(NSString *)formatStr
{
    //Title
    UIFont *textFont = [UIFont fontWithName:[iDevicesUtil getAppWideFontName]
                                       size:M328_REGISTRATION_INFO_FONTSIZE];
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

-(void)disableUserInteraction{
    OTLog(@"disableUserInteraction");
    [_syncBtn setUserInteractionEnabled:NO];
     UIView *view = self.superview;
     topVC = [view.nextResponder isKindOfClass:[UIViewController class]] ? (UIViewController *)view.nextResponder : nil;
    if (topVC != nil) {
        [topVC.navigationController.navigationBar setUserInteractionEnabled:NO];
    }
    
}
-(void)enableUserInteraction {
    OTLog(@"enableUserInteraction");
    UIView *view = self.superview;
    topVC = [view.nextResponder isKindOfClass:[UIViewController class]] ? (UIViewController *)view.nextResponder : nil;
    [cancel dismissViewControllerAnimated:NO completion:nil];

    if (!isSyncInProgress) {
        [_syncBtn setUserInteractionEnabled:YES];
        if (topVC != nil) {
            [topVC.navigationController.navigationBar setUserInteractionEnabled:YES];
        }
    } else {
        [self disableUserInteraction];
    }
    syncImg.transform = CGAffineTransformIdentity;
}
- (void) startAction
{
    OTLog(@"startAction");
    
    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)
    {
        double currentOffset = [[NSTimeZone systemTimeZone] secondsFromGMT] / (60 * 60);
        int minutesOff = (int)(currentOffset * 60) % 60;
        [TDM329WatchSettingsUserDefaults setTZPrimaryOffset1:(int)(currentOffset * 4) + (minutesOff / 15)];
        
        NSTimeZone* destinationTimeZone = [NSTimeZone timeZoneWithName:[TDM329WatchSettingsUserDefaults TZPrimaryDSTiOSName2]];
        currentOffset = [destinationTimeZone secondsFromGMT] / (60 * 60);
        minutesOff = (int)(currentOffset * 60) % 60;
        [TDM329WatchSettingsUserDefaults setTZPrimaryOffset2:(int)(currentOffset * 4) + (minutesOff / 15)];
        
        destinationTimeZone = [NSTimeZone timeZoneWithName:[TDM329WatchSettingsUserDefaults TZPrimaryDSTiOSName3]];
        currentOffset = [destinationTimeZone secondsFromGMT] / (60 * 60);
        minutesOff = (int)(currentOffset * 60) % 60;
        [TDM329WatchSettingsUserDefaults setTZPrimaryOffset3:(int)(currentOffset * 4) + (minutesOff / 15)];
    }
    
    if (!syncCancelled) {
        [self updateStatus:[NSNumber numberWithInt:Searching]];
    }
    
    if (mInitialSetupSynchronization)
    {
        [self startFullFileRead];
    }
    else
    {
        if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQ || [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)
        {
#if TARGET_IPHONE_SIMULATOR
            if (TRUE)
#else
                if ([bleManager isBLESupported] && [bleManager isBLEAvailable])
#endif
                {
                    mCurrentSyncActionSelected = syncActionsEnum_PhoneOverWatch;
                    [self reconnectToDevice];
                }
                else
                {
                    [self removeNotConnectedMessage];
                    [self syncFinished];
                    
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
        else
        {

           UIAlertView *mSyncAlert = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"Please select", nil) message: NSLocalizedString(@"Would you like to sync watch settings from app to watch or upload watch settings from watch to the app?", NULL) delegate: self cancelButtonTitle: NSLocalizedString(@"Cancel", NULL) otherButtonTitles: NSLocalizedString(@"Keep watch settings", NULL), NSLocalizedString(@"Keep app settings", NULL), nil];
            [mSyncAlert show];
        }
    }
    
}
-(void) startFullFileRead
{
     OTLog(@"startFullFileRead");
    PeripheralDevice * timexDevice = [iDevicesUtil getConnectedTimexDevice];
    if (timexDevice != nil)
    {
        if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQ || [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)
        {
            [timexDevice readTimexWatchSettings];
        }
    }
}
- (void)reconnectToDevice
{
    OTLog(@"reconnectToDevice");
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
                NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                [userDefaults setObject: device.name forKey:@"kCONNECTED_DEVICE_PREF_NAME"];
                isSyncInProgress = YES;
                if (!syncCancelled) {
                    [self updateStatus:[NSNumber numberWithInt:DeviceFound]];
                }
                [[TDDeviceManager sharedInstance] connect: device];
                [reconnection invalidate];
                reconnection = nil;
                reconnection = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(syncFailed) userInfo:nil repeats:NO];
            }
        }
        else
        {
            mReconnectAttempts++;
            if (mReconnectAttempts > 30)
            {
                mReconnectAttempts = 0;
                [self syncFailed];
            }
            else
            {
                OTLog(@"Attempting to reconnect...");
                [reconnection invalidate];
                reconnection = nil;
                reconnection = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(reconnectToDevice) userInfo:nil repeats:NO];
                //[self performSelector:@selector(reconnectToDevice) withObject:nil afterDelay: 1.0];
            }
        }
    }
    //    else
    //    {
    //        [self timerFired];
    //    }
}
- (void)BLEResponseNotRecieved {
    OTLog(@"BLEResponseNotRecieved");
    [self syncFailed];
}
- (void)rotateImageView {
    [UIView animateWithDuration:.5 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        [syncImg setTransform:CGAffineTransformRotate(syncImg.transform, -M_PI_2)];
    } completion:^(BOOL finished) {
        if (finished) {
            if (stillAnimationgButton) {
                [self rotateImageView];
            }
        }
    }];
}

- (void)updateStatus:(NSNumber *)status {
    OTLog(@"updateStatus");
    switch (status.intValue) {
        case Searching:
            _lastSynLbl.text = [NSString stringWithFormat:@"      %@", NSLocalizedString(@"Searching", nil)];
            break;
        case BatteryGood:
            _lastSynLbl.text = [NSString stringWithFormat:@"      %@%@%@", NSLocalizedString(@"Battery status", nil), @": ", NSLocalizedString(@"Good", nil)];
            break;
        case SynchronizingData:
            _lastSynLbl.text = [NSString stringWithFormat:@"      %@", NSLocalizedString(@"Synchronizing data", nil)];
            
            break;
        case DeviceFound :
             _lastSynLbl.text = [NSString stringWithFormat:@"      %@", NSLocalizedString(@"Device found", nil)];
            break;
        case SyncCompleted:
            _lastSynLbl.text = [NSString stringWithFormat:@"      %@", NSLocalizedString(@"SYNC SUCCESSFUL", nil)];
            stillAnimationgButton = NO;
            syncImg.transform = CGAffineTransformIdentity;
            [syncImg setImage:[UIImage imageNamed:@"SyncDone"] forState:UIControlStateNormal];
            [self enableUserInteraction];
            [self performSelector:@selector(setupSyncIcon) withObject:nil afterDelay:2.0];
            break;
        case Canceled:
            _lastSynLbl.text = [NSString stringWithFormat:@"      %@", NSLocalizedString(@"Cancelling...", nil)];
            stillAnimationgButton = NO;
            break;
        default:
            break;
    }
}

- (void)syncDone {
    OTLog(@"syncDone");
    [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:kLastActivityTrackerSyncSyncDate];
    [self updateSync];
}

- (void)updateSync {
    OTLog(@"updateSync");
    stillAnimationgButton = NO;
    [self enableUserInteraction];
    syncImg.transform = CGAffineTransformIdentity;
    [self setupSyncIcon];
    [self updateLastLblText];
}

- (void)syncFailed {
    OTLog(@"syncFailed");
    isSyncInProgress = NO;
    stillAnimationgButton = NO;
    [self removeObserversTosync];
    [self enableUserInteraction];
    syncFailedView.hidden = YES;
    watchFrame = 0;
    [animation invalidate];
    [self watchAnimation];
    tap = nil;
    [self removeGestureRecognizer:tap];
    [self updateSync];

    if (!syncCancelled) {
        [self failedAlert];
    }
    syncViewBgLbl.backgroundColor = [UIColor blackColor];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SyncFailed" object:nil];
    [self exitSyncModeManually];
}

- (void)failedAlert
{
    [self exitSyncModeManually];
    [self stopSearchTimer];
    isSyncInProgress = NO;
    syncCancelled = NO;
    [self removeSyncView];
    
    syncFailAlert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Unable to Sync", nil)
                                                 message:NSLocalizedString(@"There was a problem when trying to connect to your watch.", nil)
                                          preferredStyle:UIAlertControllerStyleAlert];
    
    [syncFailAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                               style:UIAlertActionStyleCancel
                                             handler:^(UIAlertAction * _Nonnull action)
                       {
                           [self clickedOnCancel];
                       }]];
    
    [syncFailAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Try Again", nil)
                                               style:UIAlertActionStyleDefault
                                             handler:^(UIAlertAction * _Nonnull action)
                       {
                           OTLog(@"clickedOnTryAgain");
                           [self removeSyncView];
                            isSyncInProgress = NO;
                           [self clickedOnSync];
                       }]];
    
    [syncFailAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Something Else is Wrong", nil)
                                               style:UIAlertActionStyleDefault
                                             handler:^(UIAlertAction * _Nonnull action)
                       {
                           OTLog(@"clickedOnSomethingWrong");
                           HelpViewController *vc = [[HelpViewController alloc] initWithNibName:@"HelpViewController" bundle:nil fromSync:NO];
                           TDAppDelegate * delegate = (TDAppDelegate *)[UIApplication sharedApplication].delegate;
                           UINavigationController * navBar = (UINavigationController *)((MFSideMenuContainerViewController *)delegate.window.rootViewController).centerViewController;
                           NSArray *controllers = [NSArray arrayWithObject: vc];
                           navBar.viewControllers = controllers;
                           // Need to change the state as well
                           MFSideMenuContainerViewController *sideContainer =(MFSideMenuContainerViewController *)delegate.window.rootViewController;
                           [sideContainer setMenuState:MFSideMenuStateClosed];
                           // Enable the navigation bar.
                           [self removeSyncView];
                           [self updateSync];
                           [self removeObserversTosync];
                           [self removeNotConnectedMessage];
                       }]];
    
    [topVC presentViewController:syncFailAlert animated:YES completion:nil];
}

- (IBAction)clickedOnCancel {
    [self stopSearchTimer];
    syncCancelled = YES;
    OTLog(@"clickedOnCancel");
    [reconnection invalidate];
    [self removeSyncView];
    if (!isSyncInProgress) {
        [self removeObserversTosync];
    }
    [self updateStatus:[NSNumber numberWithInt:Canceled]];
    stillAnimationgButton = NO;
    watchFrame = 0;
    [animation invalidate];
    [self watchAnimation];
    [self removeGestureRecognizer:tap];
    tap = nil;
    [self performSelector:@selector(updateSync) withObject:nil afterDelay:1];
}
- (void)displaySyncView {
    OTLog(@"displaySyncView");
    [syncView setHidden:NO];
    warningLbl.hidden = YES;
    alignNowBtn.hidden = YES;
    errorImg.hidden = YES;
    cancelBtn.hidden = YES;
    TDAppDelegate *delegate = (TDAppDelegate *)[[UIApplication sharedApplication] delegate];
    syncView.frame = CGRectMake(0, 64, ScreenWidth, ScreenHeight-64);
    [delegate.window addSubview:syncView];
    syncFailedView.layer.cornerRadius = 10.0f;
    syncFailedView.layer.masksToBounds = YES;
    syncViewBgLbl.backgroundColor = [UIColor blackColor];
}

- (void)removeSyncView {
    OTLog(@"removeSyncView");
    [syncView setHidden:YES];
    syncImg.transform = CGAffineTransformIdentity;
    //[syncView removeFromSuperview];
}

-(void)timerFired
{
    OTLog(@"timerFired");
    [self removeNotConnectedMessage];
     PeripheralDevice * timexDevice = [iDevicesUtil getConnectedTimexDevice];
        if (timexDevice != nil)
        {
            [timexDevice triggerWatchFinder: FALSE];
        }

}

#pragma mark - Connection and syncing details

-(void)connectToDevice {
    OTLog(@"connectToDevice");
    PeripheralDevice *connectedDevice =     [iDevicesUtil getConnectedTimexDevice];
//    connectedDevice.peripheral.
    
    if(connectedDevice == nil){
        OTLog(@"No device connected");
        [self syncFailed];
    }
    else{
        OTLog(@"Device connected");
         [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finshedReadingWatchInfo:) name: kTDWatchInfoReadSuccessfullyNotification object: nil];
        [connectedDevice requestDeviceInfo];
    }
}

-(void)finshedReadingWatchInfo:(NSNotification*) notification {
    OTLog(@"finshedReadingWatchInfo");
//    [[NSNotificationCenter defaultCenter]remove]
    //TODO: Check this method once
     [[NSNotificationCenter defaultCenter] removeObserver: self name: kTDWatchInfoReadSuccessfullyNotification object: nil];
    
    PCCommWhosThere * newSettings = [notification.userInfo objectForKey: kDeviceWatchInfoKey];
    if (newSettings)
    {
        NSString * mappedName = [iDevicesUtil convertTimexModuleStringToProductName: newSettings.mModelNumber];

        PeripheralDevice * timexDevice = [iDevicesUtil getConnectedTimexDevice];
        if (timexDevice && [timexDevice isFirmwareUpgradePaused])
        {
        }
        else
        {
            
            // Trying to read settings file
            [timexDevice readTimexWatchSettings]; //
           
            // Listen to activitydata read
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(watchActivityRead:) name: kTDM372ActivitiesReadSuccessfullyNotification object: nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(watchActivityReadFailed:) name: kTDM372ActivitiesReadUnsuccessfullyNotification object: nil];
//            // Call for activity data read
            [timexDevice readTimexWatchActivityData]; // Not sure if this is needed or not.

        }
    }
}

// Called when sleep summary read finishes
-(void)sleepSummaryRead:(NSNotification*)notification{
    OTLog(@"sleepSummaryRead");
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kTDM372SleepSummarySuccessfullyNotification object: nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kTDM372SleepSummaryUnsuccessfullyNotification object: nil];
}
// Called when sleep summary fails.
-(void)sleepSummaryFailed:(NSNotification*)notification{
    OTLog(@"sleepSummaryFailed");
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kTDM372SleepSummarySuccessfullyNotification object: nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kTDM372SleepSummaryUnsuccessfullyNotification object: nil];
}


// Called when watch activity is read.
-(void)watchActivityRead:(NSNotification*)notification{
    OTLog(@"watchActivityRead");
    TDM372WatchActivity * newData = [notification.userInfo objectForKey: kM372ActivitiesDataFileKey];
    if (newData)
    {
        //record last sync date
        [[NSUserDefaults standardUserDefaults] setObject: [NSDate date] forKey: kLastActivityTrackerSyncSyncDate];
        [newData recordActivityData];
    }
//     PeripheralDevice * timexDevice = [iDevicesUtil getConnectedTimexDevice];
//    [timexDevice writeTimexWatchSettings]; // Trying to write the settings.
    
    [self syncDone];
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kTDM372ActivitiesReadUnsuccessfullyNotification object: nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kTDM372ActivitiesReadSuccessfullyNotification object: nil];
    
}
// Called when watch activity read failed.
-(void)watchActivityReadFailed:(NSNotification*)notification{
    OTLog(@"watchActivityReadFailed");
    [self syncFailed];
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kTDM372ActivitiesReadUnsuccessfullyNotification object: nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kTDM372ActivitiesReadSuccessfullyNotification object: nil];
}


#pragma mark -
#pragma mark - Methods to sync in the same main view
- (void) WatchInfoRead: (NSNotification*)notification
{
    OTLog(@"WatchInfoRead");
    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQ || [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)
    {
        PCCommWhosThere * newSettings = [notification.userInfo objectForKey: kDeviceWatchInfoKey];
        if (newSettings)
        {
//            NSString * mappedName = [iDevicesUtil convertTimexModuleStringToProductName: newSettings.mModelNumber];
//            if (mappedName == nil)
//                mappedName = newSettings.mModelNumber;
            
            //[self getInformationLabelTwo].text = [NSString stringWithFormat: @"%@ %@ %@", mappedName, NSLocalizedString(@"Firmware", nil), [newSettings.mProductRev stringByReplacingOccurrencesOfString:@" " withString:@""]];
            
            //TestLog_SleepTraker_SerialNumber
            [[NSUserDefaults standardUserDefaults] setObject:newSettings.mSerialNumber forKey:WATCH_SERIAL_NUMBER];
            [[NSUserDefaults standardUserDefaults]synchronize];
            
        }
    }
}

- (void) WatchChargeInfoRead: (NSNotification*)notification
{
    OTLog(@"WatchChargeInfoRead");
    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQ || [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)
    {
        _textLbl.attributedText = [self getAttributedStrWithText:NSLocalizedString(@"Watch connected",nil)
                                                mediumFormatText:NSLocalizedString(@"12:00 position",nil)
                                               mediumFormatText2:NSLocalizedString(@"“Align Hands”",nil)
                                                       formatStr:NSLocalizedString(@"\n\nAre the hands pointing to the 12 o’clock position? If not, please go to the settings menu on the app and tap “Align Hands”.",nil)];
        // Watch animation
        watchFrame = 0;
        [animation invalidate];
        _headerImg.image = [UIImage imageNamed:@"CalibrateWatch"];
        if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)
        {
            _headerImg.image = [UIImage imageNamed:@"TravelCalibrate"];
        }
        
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
                
                CustomAlertViewController *cav = [[CustomAlertViewController alloc] initWithTitle:NSLocalizedString(@"Watch Battery Low", nil) andMessage:NSLocalizedString(@"Your watch battery is too low to sync. You will need to replace your watch battery soon.", nil)];
                [cav addActionButton:[[CustomAlertButton alloc] initWithTitle:NSLocalizedString(@"Go Back", nil) andActionBlock:^{
                    NSLog(@"go back clicked");
                    
                    PeripheralDevice * timexDevice = [iDevicesUtil getConnectedTimexDevice];
                    if (timexDevice)
                    {
                        [timexDevice endFileAccessSession];
                    }
                    
                }]];
                
                [cav addActionButton:[[CustomAlertButton alloc] initWithTitle:NSLocalizedString(@"Learn More", nil) andActionBlock:^{
                    if (topVC == nil) {
                        UIView *view = self.superview;
                        topVC = [view.nextResponder isKindOfClass:[UIViewController class]] ? (UIViewController *)view.nextResponder : nil;
                    }
                    HelpViewController *helpVC=[[HelpViewController alloc] initWithNibName:@"HelpViewController" bundle:nil fromSync:YES];
                    [topVC.navigationController pushViewController:helpVC animated:YES];
                }]];
                
                cav.modalPresentationStyle = UIModalPresentationOverCurrentContext;
                
                [navBar presentViewController: cav animated:YES completion:nil];

            }
            
            if (!syncCancelled) {
                _lastSynLbl.text = [NSString stringWithFormat: @"      %@ %@", NSLocalizedString(@"Battery status:", nil),batteryChargeStatus];
                double delayInSeconds = 1.0;
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                    [self updateStatus:[NSNumber numberWithInt:SynchronizingData]];
                });
            }
        }
    }
}

#pragma mark - WatchM372Settings

- (void) WatchM328SettingsRead: (NSNotification*)notification
{
    OTLog(@"WatchM328SettingsRead");
    TDM328WatchSettings * newData = [notification.userInfo objectForKey: kM328SettingsDataFileKey];
    if (newData)
    {
        [newData serializeIntoSettings]; //changed method name serializewatchsettings settings saved
    }
}
- (void) WatchM328SettingsReadFailed
{
    OTLog(@"WatchM328SettingsReadFailed");
    [self syncFinished];
    if (!mInitialSetupSynchronization)
    {
        actionTimer = [NSTimer scheduledTimerWithTimeInterval: AFTER_SYNC_TIMEOUT target:self selector:@selector(removeNotConnectedMessage) userInfo: nil repeats: NO];
        
    }
    [self readFailedAlert];
}

#pragma mark - WatchM372SleepActigraphyData
- (void) WatchM372SleepActigraphyData: (NSNotification*)notification
{
    OTLog(@"WatchM372SleepActigraphyData");
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
    OTLog(@"WatchM372SleepActigraphyDataFailed");
    [self syncFinished];
    if (!mInitialSetupSynchronization)
    {
        actionTimer = [NSTimer scheduledTimerWithTimeInterval: AFTER_SYNC_TIMEOUT target:self selector:@selector(removeNotConnectedMessage) userInfo: nil repeats: NO];
        
        //        [self getInformationLabelOne].text = NSLocalizedString(@"ERROR OCCURRED DURING SYNC", NULL);
        //        [self getInformationLabelTwo].text = @"";
    }
    [self readFailedAlert];
}

#pragma mark - WatchM372ActigraphyStepFileData
- (void) WatchM372ActigraphyStepData: (NSNotification*)notification
{
    OTLog(@"WatchM372ActigraphyStepData");
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
    [self syncFinished];
    if (!mInitialSetupSynchronization)
    {
        actionTimer = [NSTimer scheduledTimerWithTimeInterval: AFTER_SYNC_TIMEOUT target:self selector:@selector(removeNotConnectedMessage) userInfo: nil repeats: NO];
    }
    [self readFailedAlert];
}

#pragma mark - WatchM372SleepSummaryRead
- (void) WatchM372SleepSummaryRead: (NSNotification*)notification
{
    OTLog(@"WatchM372SleepSummaryRead");
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
    OTLog(@"WatchM372SleepSummaryReadFailed");
    [self syncFinished];
    if (!mInitialSetupSynchronization)
    {
        actionTimer = [NSTimer scheduledTimerWithTimeInterval: AFTER_SYNC_TIMEOUT target:self selector:@selector(removeNotConnectedMessage) userInfo: nil repeats: NO];
        
        //        [self getInformationLabelOne].text = NSLocalizedString(@"ERROR OCCURRED DURING SYNC", NULL);
        //        [self getInformationLabelTwo].text = @"";
    }
    [self readFailedAlert];
}

#pragma mark - WatchM372SleepKeyFileRead
- (void) WatchM372SleepKeyFileRead: (NSNotification*)notification
{
    OTLog(@"WatchM372SleepKeyFileRead");
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
    [self syncFinished];
    if (!mInitialSetupSynchronization)
    {
        actionTimer = [NSTimer scheduledTimerWithTimeInterval: AFTER_SYNC_TIMEOUT target:self selector:@selector(removeNotConnectedMessage) userInfo: nil repeats: NO];
        
        //        [self getInformationLabelOne].text = NSLocalizedString(@"ERROR OCCURRED DURING SYNC", NULL);
        //        [self getInformationLabelTwo].text = @"";
    }
    [self readFailedAlert];
}

#pragma mark - WatchM372SleepKeyFileRead
- (void) WatchM372ActivitiesRead: (NSNotification*)notification
{
    OTLog(@"WatchM372ActivitiesRead");
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
    [self syncFinished];
    if (!mInitialSetupSynchronization)
    {
        actionTimer = [NSTimer scheduledTimerWithTimeInterval: AFTER_SYNC_TIMEOUT target:self selector:@selector(removeNotConnectedMessage) userInfo: nil repeats: NO];
        
        //        [self getInformationLabelOne].text = NSLocalizedString(@"ERROR OCCURRED DURING SYNC", NULL);
        //        [self getInformationLabelTwo].text = @"";
    }
    [self readFailedAlert];
}

-(void)endFileAccessSession
{
    OTLog(@"endFileAccessSession");
    PeripheralDevice * timexDevice = [iDevicesUtil getConnectedTimexDevice];
    [timexDevice endFileAccessSession];
}

#pragma mark - SettingsSaved
- (void) SettingsSaved: (NSNotification*)notification
{
    OTLog(@"SettingsSaved");
    [self setSyncCompletedBtn];
    [TDM328WatchSettingsUserDefaults setSyncNeeded:NO];
    [self syncFinished];
    if (!mInitialSetupSynchronization)
    {
        actionTimer = [NSTimer scheduledTimerWithTimeInterval: AFTER_SYNC_TIMEOUT target:self selector:@selector(returnToPreviousScreen) userInfo: nil repeats: NO];
    }
}
- (void) SettingsSaveFailed: (NSNotification*)notification
{
    OTLog(@"SettingsSaveFailed");
    [self syncFinished];
    if (!mInitialSetupSynchronization)
    {
        actionTimer = [NSTimer scheduledTimerWithTimeInterval: AFTER_SYNC_TIMEOUT target:self selector:@selector(removeNotConnectedMessage) userInfo: nil repeats: NO];
        
        //        [self getInformationLabelOne].text = NSLocalizedString(@"ERROR OCCURRED DURING SYNC", NULL);
        //        [self getInformationLabelTwo].text = @"";
    }
    [self readFailedAlert];
}

#pragma mark - SYSBLOCK

- (void) SYSBLOCKRead: (NSNotification*)notification
{
    OTLog(@"SYSBLOCKRead");
}
- (void) SYSBLOCKReadFailed
{
    OTLog(@"SYSBLOCKFailed");
    [self syncFinished];
    if (!mInitialSetupSynchronization)
    {
        actionTimer = [NSTimer scheduledTimerWithTimeInterval: AFTER_SYNC_TIMEOUT target:self selector:@selector(removeNotConnectedMessage) userInfo: nil repeats: NO];
    }
    [self readFailedAlert];
}

#pragma mark - ApptsSaved
- (void) ApptsSaved: (NSNotification*)notification
{
    OTLog(@"ApptsSaved");
    [self setSyncCompletedBtn];
    [TDM328WatchSettingsUserDefaults setSyncNeeded:NO];
    [self syncFinished];
    if (!mInitialSetupSynchronization)
    {
        actionTimer = [NSTimer scheduledTimerWithTimeInterval: AFTER_SYNC_TIMEOUT target:self selector:@selector(returnToPreviousScreen) userInfo: nil repeats: NO];
        
    }
}

- (NSAttributedString *)getAttributedStrWithText:(NSString *)textStr formatStr:(NSString *)formatStr {
    
    UIFont *textFont = [UIFont fontWithName:[iDevicesUtil getAppWideMediumFontName] size:M328_REGISTRATION_TITLE_FONTSIZE];
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:textFont, NSFontAttributeName, [UIColor blackColor],NSForegroundColorAttributeName, nil];
    NSMutableAttributedString *textAtrStr = [[NSMutableAttributedString alloc] initWithString:textStr attributes:dict];
    
    UIFont *formatFont = [UIFont fontWithName: [iDevicesUtil getAppWideMediumFontName] size:M328_WELCOME_INFO_FONTSIZE];
    NSDictionary *atrsDict = [NSDictionary dictionaryWithObjectsAndKeys:formatFont, NSFontAttributeName, [UIColor blackColor],NSForegroundColorAttributeName, nil];
    NSMutableAttributedString *formatAtrStr = [[NSMutableAttributedString alloc] initWithString:formatStr attributes:atrsDict];
    
    [textAtrStr appendAttributedString:formatAtrStr];
    
    return textAtrStr;
}

- (void) ApptsSaveFailed: (NSNotification*)notification
{
    OTLog(@"ApptsSaveFailed");
    [self syncFinished];
    if (!mInitialSetupSynchronization)
    {
        actionTimer = [NSTimer scheduledTimerWithTimeInterval: AFTER_SYNC_TIMEOUT target:self selector:@selector(removeNotConnectedMessage) userInfo: nil repeats: NO];
        
        //        [self getInformationLabelOne].text = NSLocalizedString(@"ERROR OCCURRED DURING SYNC", NULL);
        //        [self getInformationLabelTwo].text = @"";
    }
    [self readFailedAlert];
}

-(void)stopSearchTimer
{
    if (actionTimer) {
        [actionTimer invalidate];
        actionTimer = nil;
    }
}

#pragma mark - successfullyConnectedToDevice
-(void) successfullyConnectedToDevice:(NSNotification*)notification
{
    OTLog(@"successfullyConnectedToDevice");
    [reconnection invalidate];
    // May be remove device detection stuff.
      [[NSNotificationCenter defaultCenter] removeObserver: self name: kPeripheralDeviceTimexDatalinkPrimaryCharacteristicDiscovered object: nil];
    if (mCurrentSyncActionSelected == syncActionsEnum_WatchOverPhone)
        [self performSelector:@selector(startFullFileRead) withObject:nil afterDelay: 1.0];
    else if (mCurrentSyncActionSelected == syncActionsEnum_PhoneOverWatch)
        [self performSelector:@selector(startFullFileReadWithSubsequentWritingToWatch) withObject:nil afterDelay: 1.0];
}
-(void) startFullFileReadWithSubsequentWritingToWatch
{
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

#pragma mark - bootloader
-(void)unexpectedBootloaderModeForM372DetectedAndApproved:(NSNotification*)notification
{
    OTLog(@"moveToFirmwareUpdate");
    UpdateFirmwareViewController *updateFirmwareVC=[[UpdateFirmwareViewController alloc] initWithNibName:@"UpdateFirmwareViewController" bundle:nil];
    updateFirmwareVC.unstickBootloader = YES;
    updateFirmwareVC.openedByMenu = YES;
    [actionTimer invalidate];
    actionTimer = nil;
    TDAppDelegate * delegate = (TDAppDelegate *)[UIApplication sharedApplication].delegate;
    UINavigationController * navBar = (UINavigationController *)((MFSideMenuContainerViewController *)delegate.window.rootViewController).centerViewController;
    NSArray *controllers = [NSArray arrayWithObject: updateFirmwareVC];
    navBar.viewControllers = controllers;
    // Need to change the state as well
    MFSideMenuContainerViewController *sideContainer =(MFSideMenuContainerViewController *)delegate.window.rootViewController;
    [sideContainer setMenuState:MFSideMenuStateClosed];
    // Enable the navigation bar.
    [self removeSyncView];
    [self updateSync];
}
- (void) handleErrorDuringFirmwareCheck
{
    HUD = [[MBProgressHUD alloc] initWithView: syncFailedView];
    [syncFailedView addSubview: HUD];
    
    HUD.labelText = NSLocalizedString(@"Please Wait", nil);
    HUD.detailsLabelText = NSLocalizedString(@"Downloading Firmware Update...", nil);
    HUD.square = YES;
    HUD.mode = MBProgressHUDModeDeterminateHorizontalBar;
    
    [HUD show: YES];
    NSString * tempDir = NSTemporaryDirectory();
    NSString * newDir = [tempDir stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]];
    [[NSFileManager defaultManager] createDirectoryAtPath:newDir withIntermediateDirectories: NO attributes: nil error: nil];
    for (TDM372FirmwareUpgradeInfo * downloadInfo in _mFirmwareUpgradeInfo)
    {
        OTLog(@"\n\n\nDownloaded PAth:%@",newDir);
        [[TCBlobDownloadManager sharedInstance] startDownloadWithURL:[NSURL URLWithString: downloadInfo.uri] customPath: newDir delegate: self.superclass];
    }
}

#pragma mark - self methods
-(void)syncFinished
{
    OTLog(@"syncFinished");
    // May be ask the connected device to end the session ??
    [self endFileAccessSession];// May be..
    isSyncInProgress = NO;
    stillAnimationgButton = NO;
    syncImg.transform = CGAffineTransformIdentity;
    if (!syncCancelled) {
        [self updateStatus:[NSNumber numberWithInt:SyncCompleted]];
    } else {
        [self setupSyncIcon];
    }
    mCurrentSyncActionSelected = syncActionsEnum_Unselected;
    [self removeObserversTosync];
    [self removeNotConnectedMessage];
    [self performSelector:@selector(updateSync) withObject:nil afterDelay:1.0];
    PeripheralDevice * timexDevice = [iDevicesUtil getConnectedTimexDevice];
    if (timexDevice)
    {
        [[TDDeviceManager sharedInstance] disconnect: timexDevice];
    }
    [self exitSyncModeManually];
    [cancel dismissViewControllerAnimated:NO completion:nil];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SyncFinished" object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SyncDataFinished" object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName: kFirmwareCheckUserInitiatedNotificationNew object:self];
    
    [self launchUserInitiatedFirmwareCheck:nil];
}
-(void)exitSyncModeManually

{
    // Logic here is to start and end the session if not present.
    // This will disconnect the watch.
    // Observe for notification on start of session
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(didStartFileAccessSession:) name:kTDM328SessionStartNotification object:nil];
    
    PeripheralDevice * timexDevice = [iDevicesUtil getConnectedTimexDevice];
    if(timexDevice)
    {
        [timexDevice startFileAccessSession];
    }
}

-(void)didStartFileAccessSession:(NSNotification*)notification
{
    // Remove observer.
    [[NSNotificationCenter defaultCenter]removeObserver:self name:kTDM328SessionStartNotification object:nil];
    
    PeripheralDevice * timexDevice = [iDevicesUtil getConnectedTimexDevice];
    if(timexDevice)
    {
        [timexDevice performSelector:@selector(endFileAccessSession) withObject:nil afterDelay:1];
    }
}
- (void)setSyncCompletedBtn {
    stillAnimationgButton = NO;
    syncImg.transform = CGAffineTransformIdentity;
    if (!syncCancelled) {
        [self updateStatus:[NSNumber numberWithInt:SyncCompleted]];
    }
}

- (void)setupSyncIcon
{
    syncImg.transform = CGAffineTransformIdentity;
    if ([TDM328WatchSettingsUserDefaults syncNeeded]) {
        [syncImg setImage:[UIImage imageNamed:@"SyncNeeded"] forState:UIControlStateNormal];
    } else {
        [syncImg setImage:[UIImage imageNamed:@"Sync"] forState:UIControlStateNormal];
    }
}

-(void)readFailedAlert
{
    [self removeSyncView];
    [self removeGestureRecognizer:tap];
    tap = nil;
    cancel = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Something Happened",nil)
                                                 message:NSLocalizedString(@"The activity data on your watch could not be displayed. If this keeps happening, try performing a factory reset from the settings menu.",nil)
                                          preferredStyle:UIAlertControllerStyleAlert];
    
    [cancel addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Settings", nil)
                                               style:UIAlertActionStyleDefault
                                             handler:^(UIAlertAction * _Nonnull action)
                       {
                           SettingsViewController *mainControllerIQMove = [[SettingsViewController alloc]initWithNibName:@"SettingsViewController"
                                                                                                                  bundle:nil];
                           [self AssignNewControllerToCenterController:mainControllerIQMove];
                       }]];
    
    [cancel addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                               style:UIAlertActionStyleDefault
                                             handler:^(UIAlertAction * _Nonnull action){}]];
    
    [topVC presentViewController:cancel animated:YES completion:nil];
}

- (void) AssignNewControllerToCenterController: (TDRootViewController *) newController
{
    TDAppDelegate * delegate = (TDAppDelegate *)[UIApplication sharedApplication].delegate;
    UINavigationController * navBar = (UINavigationController *)((MFSideMenuContainerViewController *)delegate.window.rootViewController).centerViewController;
    [navBar setNavigationBarHidden:NO animated:YES];
    NSArray *controllers = [NSArray arrayWithObject: newController];
    navBar.viewControllers = controllers;
}

- (void) AssignNewControllerToCenterControllerNew: (UIViewController *) newController
{
    TDAppDelegate * delegate = (TDAppDelegate *)[UIApplication sharedApplication].delegate;
    UINavigationController * navBar = (UINavigationController *)((MFSideMenuContainerViewController *)delegate.window.rootViewController).centerViewController;
    [navBar setNavigationBarHidden:NO animated:YES];
    NSArray *controllers = [NSArray arrayWithObject: newController];
    navBar.viewControllers = controllers;
}

-(void)checkWarnings
{
    //[cancel dismissViewControllerAnimated:YES completion:nil];
    if ([TDM328WatchSettingsUserDefaults resetWarning])
    {
        warningLbl.hidden = NO;
        alignNowBtn.hidden = NO;
        errorImg.hidden = NO;
        cancelBtn.hidden = YES;
        _headerImg.hidden = YES;
        [syncView removeGestureRecognizer:tap];

        switch ([TDM328WatchSettingsUserDefaults numOfWarnings])
        {
            case 0:
                [TDM328WatchSettingsUserDefaults setWarningTriggered:1];
                _textLbl.attributedText = [self getAttributedStrWithText:NSLocalizedString(@"Sorry, something happened.",nil)
                                                               formatStr:NSLocalizedString(@"\n\nWe want to make sure your watch is working perfectly.",nil)];
                errorImg.image = [UIImage imageNamed:@"ErrorLvl1"];
                warningLbl.text = NSLocalizedString(@"Unfortunately your activity data may be inaccurate and the watch hands need to be realigned.",nil);
                break;
            case 1:
                _textLbl.attributedText = [self getAttributedStrWithText:NSLocalizedString(@"Oh No! Let's try again.",nil)
                                                               formatStr:NSLocalizedString(@"\n\nSomething happened and we want to make sure your watch is working perfectly.",nil)];
                errorImg.image = [UIImage imageNamed:@"ErrorLvl2"];
                warningLbl.text = NSLocalizedString(@"Unfortunately your activity data may be inaccurate and the watch hands need to be realigned.",nil);
                break;
            default:
                _textLbl.attributedText = [self getAttributedStrWithText:NSLocalizedString(@"There might be a problem.",nil)
                                                               formatStr:NSLocalizedString(@"\n\nWe want to make sure your watch is working perfectly.",nil)];
                errorImg.image = [UIImage imageNamed:@"ErrorLvl3"];
                warningLbl.text = NSLocalizedString(@"Please contact customer service.\nThey'll know what to do.",nil);
                cancelBtn.hidden = NO;
                break;
        }
    }
    else
    {
        [self removeSyncView];
    }
}

- (void) launchUserInitiatedFirmwareCheck: (NSNotification*)notification
{
    if ([iDevicesUtil hasInternetConnectivity] && [iDevicesUtil checkForActiveProfilePresence])
    {
        NSInteger secsPerDay = 60 * 60 * 24; //60 * 60 * 24
        NSDate * now = [NSDate date];
        NSDate * lastFirmwareCheckDate = [[NSUserDefaults standardUserDefaults] objectForKey: kLAST_FIRMWARE_CHECK_DATE_NEW];
        if (lastFirmwareCheckDate == nil || [now timeIntervalSinceDate: lastFirmwareCheckDate] > secsPerDay)
        {
            dispatch_async(kFirmwareCheckQueue, ^{
                NSData* data = [NSData dataWithContentsOfURL: kTimexFirmwareCheckURL];
                
                [self performSelectorOnMainThread:@selector(fetchedFirmwareInfo:) withObject: data waitUntilDone: YES];
            });
        }
        else
        {
            OTLog(@"Did not perform M328 Firmware check because less then 24 hours elapsed since the last firmware check");
            if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)
            {
                [self removeSyncView];
            }
            else if (!notification)
                [self checkWarnings];
        }
    }
    else
    {
        if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)
        {
            [self removeSyncView];
        }
        else if (!notification)
            [self checkWarnings];
    }
}

-(void)fetchedFirmwareInfo:(NSData*)responseData {
    
    BOOL        foundJSONmodule = false;
    NSError     * error = nil;
    
    //if we got no data, or we are no longer on the foreground for whatever reason....
    if (responseData == nil)
    {
        [self checkWarnings];
    }
    NSDictionary* json = [NSJSONSerialization JSONObjectWithData: responseData options:kNilOptions error: &error];
    
    NSNumber * json_version = [json objectForKey: @"file_version"];
    OTLog(@"%@",json);
    if ([json_version intValue] == FIRMWARE_UPGRADE_JSON_FILE_VERSION)
    {
        NSArray* availableModules = [json objectForKey: @"modules"];
        for (NSDictionary * availableModule in availableModules)
        {
            // Look for M328 named module
            NSString * moduleName = [availableModule objectForKey:@"name"];
            if([moduleName isEqualToString:@"M328"] && [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQ){
                foundJSONmodule = true;
                [self _createFirmwareUpdateInfoArrayForM328:availableModule bootloaderOnly:FALSE];
            } else if ([moduleName isEqualToString:@"M329"] && [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel){
                foundJSONmodule = true;
                [self _createFirmwareUpdateInfoArrayForM328:availableModule bootloaderOnly:FALSE];
            }
        }
    }
    if (foundJSONmodule == YES){
        {
            NSString * versionOnWatch = [[NSUserDefaults standardUserDefaults] objectForKey: kM372FirmwareVersionFile1Key];
            [self _upgradeRequiredForM328FirmwareFile: versionOnWatch];
            OTLog(@"Watch Version %@",versionOnWatch);
            
            versionOnWatch = [[NSUserDefaults standardUserDefaults] objectForKey: kM372FirmwareVersionFile2Key];
            [self _upgradeRequiredForM328FirmwareFile: versionOnWatch];
            OTLog(@"Watch Version %@",versionOnWatch);
            
            versionOnWatch = [[NSUserDefaults standardUserDefaults] objectForKey: kM372FirmwareVersionFile3Key];
            [self _upgradeRequiredForM328FirmwareFile: versionOnWatch];
            OTLog(@"Watch Version %@",versionOnWatch);
            
            versionOnWatch = [[NSUserDefaults standardUserDefaults] objectForKey: kM372FirmwareVersionFile4Key];
            [self _upgradeRequiredForM328FirmwareFile: versionOnWatch];
            OTLog(@"Watch Version %@",versionOnWatch);
            
            //get rid of files that we don't need to upload
            //keep in mind that Firmware and Activity files always go together...
            BOOL upgradeForFirmwareRequired;
            BOOL upgradeForActivityRequired;
            for (TDM372FirmwareUpgradeInfo * downloadInfo in _mFirmwareUpgradeInfo){
                if (downloadInfo.type == TDM372FirmwareUpgradeInfoType_Firmware)
                    upgradeForFirmwareRequired = downloadInfo.upgradeRequired;
                
                else if (downloadInfo.type == TDM372FirmwareUpgradeInfoType_Activity)
                    upgradeForActivityRequired = downloadInfo.upgradeRequired;
            }
            
            for (NSInteger i = _mFirmwareUpgradeInfo.count - 1; i >= 0; i--) {
                TDM372FirmwareUpgradeInfo * downloadInfo = [_mFirmwareUpgradeInfo objectAtIndex: i];
                if (downloadInfo.upgradeRequired == FALSE) {
                    if (downloadInfo.type == TDM372FirmwareUpgradeInfoType_Firmware || downloadInfo.type == TDM372FirmwareUpgradeInfoType_Activity) {
                        if (!upgradeForActivityRequired && !upgradeForFirmwareRequired) {
                            [_mFirmwareUpgradeInfo removeObject: downloadInfo];
                        }
                    } else {
                        [_mFirmwareUpgradeInfo removeObject: downloadInfo];
                    }
                }
            }
            
            
            if (_mFirmwareUpgradeInfo.count > 0 && ![TDM328WatchSettingsUserDefaults numOfWarnings])
            {
                UIView *view = self.superview;
                topVC = [view.nextResponder isKindOfClass:[UIViewController class]] ? (UIViewController *)view.nextResponder : nil;
    
                [self removeSyncView];
                tap = nil;
                [self removeGestureRecognizer:tap];
                cancel = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"We found an update.",nil)
                                                             message:NSLocalizedString(@"Updating your watch provides you with the latest features, however data stored on the watch is cleared for the current day. This process may take several minutes.",nil)
                                                      preferredStyle:UIAlertControllerStyleAlert];
                
                [cancel addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Update Later", nil)
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * _Nonnull action)
                                   {
                                       [self updateSkipped:nil];
                                   }]];
                
                [cancel addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Update Now", nil)
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * _Nonnull action)
                                   {
                                       [self updateNowPicked:nil];
                                   }]];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [topVC presentViewController:cancel animated:YES completion:nil];
                });
            }
            else
            {
                [self checkWarnings];
            }
        }
    }
}
- (IBAction)updateSkipped:(id)sender
{
    [self checkWarnings];
}
- (IBAction)updateNowPicked:(id)sender
{
    UpdateFirmwareViewController *updateFirmwareVC=[[UpdateFirmwareViewController alloc] initWithNibName:@"UpdateFirmwareViewController" bundle:nil];
    updateFirmwareVC.openedByMenu = YES;
    updateFirmwareVC.neededUpdate = YES;
    [self AssignNewControllerToCenterControllerNew:updateFirmwareVC];
}

- (void) _createFirmwareUpdateInfoArrayForM328: (NSDictionary *) availableModule bootloaderOnly: (BOOL) blOnly
{
    //record that we have done a SUCCESSFUL firmware update  check today
    [[NSUserDefaults standardUserDefaults] setObject: [NSDate date] forKey: kLAST_FIRMWARE_CHECK_DATE_NEW];
    _mFirmwareUpgradeInfo = [[NSMutableArray alloc] init];
    NSArray * moduleInfo = [availableModule objectForKey: @"files"];
    for (NSDictionary * cluster in moduleInfo)
    {
        TDM372FirmwareUpgradeInfo * newInfoCluster = [[TDM372FirmwareUpgradeInfo alloc] init];
        
        NSString * uriType = [cluster objectForKey:@"type"];
        
        if ([uriType isEqualToString: @"firmware"])
            newInfoCluster.type = TDM372FirmwareUpgradeInfoType_Firmware;
        else if ([uriType isEqualToString: @"codeplug"])
            newInfoCluster.type = TDM372FirmwareUpgradeInfoType_Codeplug;
        else if ([uriType isEqualToString: @"activity"])
            newInfoCluster.type = TDM372FirmwareUpgradeInfoType_Activity;
        else if ([uriType isEqualToString: @"radio"])
        {
            if (blOnly)
                continue;
            else
                newInfoCluster.type = TDM372FirmwareUpgradeInfoType_Radio;
        }
        
        NSString * uriStr = [cluster objectForKey:@"uri"];
        newInfoCluster.uri = uriStr;
        
        NSRange rangeOfLastSlash = [newInfoCluster.uri rangeOfString: @"/" options:NSBackwardsSearch];
        if (rangeOfLastSlash.location != NSNotFound)
        {
            NSString * fullFilename = [newInfoCluster.uri substringFromIndex: rangeOfLastSlash.location + rangeOfLastSlash.length];
            NSRange rangeOfDot = [fullFilename rangeOfString: @"." options:NSBackwardsSearch];
            if (rangeOfDot.location != NSNotFound)
                newInfoCluster.filename = [fullFilename substringToIndex: rangeOfDot.location];
            else
                newInfoCluster.filename = fullFilename;
        }
        
        NSNumber * uriVersion = [cluster objectForKey: @"version"];
        newInfoCluster.version = [uriVersion integerValue];
        
        [_mFirmwareUpgradeInfo addObject: newInfoCluster];
    }
}

- (void) _upgradeRequiredForM328FirmwareFile: (NSString *) versionOnWatch
{
    NSRange letterRange = NSMakeRange(versionOnWatch.length - 4, 1);
    NSString * letterCode = [versionOnWatch substringWithRange: letterRange];
    
    TDM372FirmwareUpgradeInfoType typeToProcess = TDM372FirmwareUpgradeInfoType_Uninitialized;
    
    if ([letterCode isEqualToString: @"F"])
    {
        typeToProcess = TDM372FirmwareUpgradeInfoType_Firmware;
    }
    else if ([letterCode isEqualToString: @"C"])
    {
        typeToProcess = TDM372FirmwareUpgradeInfoType_Codeplug;
    }
    else if ([letterCode isEqualToString: @"A"])
    {
        typeToProcess = TDM372FirmwareUpgradeInfoType_Activity;
    }
    else if ([letterCode isEqualToString: @"R"])
    {
        typeToProcess = TDM372FirmwareUpgradeInfoType_Radio;
    }
    
    for (TDM372FirmwareUpgradeInfo * downloadInfo in _mFirmwareUpgradeInfo)
    {
        if (downloadInfo.type == typeToProcess)
        {
            OTLog(@"Version on Server : %ld",downloadInfo.version);
            
            NSInteger version = [[self _getVersionSubstring: versionOnWatch] integerValue];
            //Setting this logic to include firmware anyways.
            // VERY IMPORTANT FOR UPGRADE.
            if (version < downloadInfo.version ) { // Actual case
                // For testing, use the following line.
                //            if (version < downloadInfo.version || typeToProcess == TDM372FirmwareUpgradeInfoType_Firmware ){
                downloadInfo.upgradeRequired = TRUE;
            }
            break;
        }
        
    }
}

- (NSString *)_getVersionSubstring: (NSString *)value
{
    NSRange finalRange = NSMakeRange(value.length - 3, 3);
    return [value substringWithRange:finalRange];
}

-(void)timerSyncFinished {
    OTLog(@"timerSyncFinished");
    [self removeSyncView];
    [self removeObserversTosync];
    [self removeNotConnectedMessage];
}
- (void) removeNotConnectedMessage
{
    OTLog(@"removeNotConnectedMessage");
    if (actionTimer)
    {
        [actionTimer invalidate];
        actionTimer = NULL;
    }
    
    double delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        TDAppDelegate *delegate = (TDAppDelegate *)[[UIApplication sharedApplication] delegate];
        NSString *watchModel = NSLocalizedString(@"Guess iQ+  Last Sync:",nil);
        if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)
        {
            watchModel = NSLocalizedString(@"iQ+ Travel  Last Sync:",nil);
        }
        _lastSynLbl.text = [NSString stringWithFormat:@"    %@ %@", watchModel,[delegate getLastSyncDate]];
        [self enableUserInteraction];

    });
}

-(void) returnToPreviousScreen
{
}

- (void)removeDevicesChangedNotificaiton {
    // Probably remove the notification listener for device changes.
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kDeviceManagerAdvertisingDevicesChangedNotification object: nil];
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kDeviceManagerConnectedDevicesChangedNotification object: nil];
}
-(void)dealloc{
    [self removeDevicesChangedNotificaiton];
}

@end
