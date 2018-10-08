//
//  UpdateFirmwareViewController.m
//  Timex
//
//  Created by avemulakonda on 5/4/16.
//

#import "SetupWatchViewController.h"
#import "UpdateFirmwareViewController.h"
#import "MBProgressHUD.h"
#import "CalibratingWatchViewController.h"
#import "iDevicesUtil.h"
#import "TDDefines.h"
#import "CalibrationClass.h"
#import "TDWatchProfile.h"
#import "PCCommExtendedFirmwareVersionInfo.h"
#import <TCBlobDownload/TCBlobDownload.h>
#import "TDDeviceManager.h"
#import "PCCommWhosThere.h"
#import "PCCommChargeInfo.h"
#import "TDM328WatchSettingsUserDefaults.h"
#import "OTLogUtil.h"
#import "TDHomeViewController.h"
#import "TDAppDelegate.h"
#import "MFSideMenuContainerViewController.h"
#import "SyncWatchAfterFirmwareUpdate.h"

NSString* const kLAST_FIRMWARE_CHECK_DATE_NEW = @"kLAST_FIRMWARE_CHECK_DATE_NEW";
NSString* const kFirmwareCheckUserInitiatedNotificationNew = @"kFirmwareCheckUserInitiatedNotificationNew";
NSString* const kFirmwareRequestUserInitiatedNotificationNew = @"kFirmwareRequestUserInitiatedNotificationNew";
NSString* const kM328WatchResetUserInitiatedNotificationNew = @"kM328WatchResetUserInitiatedNotificationNew";

@interface UpdateFirmwareViewController ()<TCBlobDownloaderDelegate,UIAlertViewDelegate,TDProgressFirmwareUpdateDelegate>{
    /**
     *  Array that stores upgrading information.
     */
    NSMutableArray  * _mFirmwareUpgradeInfo;
    
    UIAlertView *_mFirmwareUpdateAlert;
    UIAlertView *_mFirmwareInformationAlert;
    UIAlertController *_noWatchFounded;
    UIAlertView *_confirmationAlert;
    UIAlertView *_mFirmwareUpdateSuccessful;
    UIAlertView *noFirmwareUpdate;

    PCCommWhosThere * _mReadSettings;
    /**
     *  Alert for no internet.
     */
    UIAlertController *_noInternetAlert;
    BLEManager *bleManager;
    
    MBProgressHUD   *  HUD;
    NSInteger       m328ReconnectAttempts; // Reconnect attempts
    BOOL            m328WatchResetRequested;
    BOOL            m328StuckInBootloader;
    BOOL ismanuallyDisconnected;
    NSInteger         _firmwareVersionOnServer;
    BOOL            m328FirmwareComplete;
    NSTimer *animation;
    int watchFrame;
    BOOL fileStarted;
    int firmwareFileTotal;
    BOOL isThereAnUpdate;
    BOOL doOnce;
}

@end

@implementation UpdateFirmwareViewController
@synthesize neededUpdate = _neededUpdate;
@synthesize retryUpdate;


- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))  {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    //    UIButton *backBtn = [iDevicesUtil getBackButton];
    //    [backBtn addTarget:self action:@selector(backButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    //    UIBarButtonItem *barBtn = [[UIBarButtonItem alloc] initWithCustomView:backBtn];
    //    self.navigationItem.leftBarButtonItem = barBtn;
    
    self.navigationItem.titleView = [iDevicesUtil getNavigationTitle];
    infoLabel.attributedText = [self getAttributedStrWithText:NSLocalizedString(@"Please wait.",nil) formatStr:NSLocalizedString(@"\n\nChecking latest firmware.",nil)];
    if (IS_IPAD) {
        infoLblTopConstraint.constant = 70;
        infoLblleftConstraint.constant = infoLblRightConstraint.constant = 60;
    } else {
        infoLblleftConstraint.constant = infoLblRightConstraint.constant = 40;
    }
    infoLblBottomContraint.constant = ((ScreenHeight)/2) - 70 - M328_REGISTRATION_BOTTOM_CONSTRAINT_MINUSVALUE;
    
    progressLbl.backgroundColor = UIColorFromRGB(AppColorRed);
    progressLblWidthContraint.constant = ScreenWidth * ([iDevicesUtil getProgressBarValueBasedOnRegistrationEnum:updateFirmware]);
    _progressBar.hidden = YES;
    completeLbl.hidden = YES;
    indicationView.hidden = YES;
    
    bleManager = [[TDDeviceManager sharedInstance] getBleManager];
    if(![bleManager isBLEAvailable])
    {
        [self showBluetoothNonAvailabilityAlert];
    }
    
    //    [[CalibrationClass sharedInstance] enterCalibrationMode]; // Need to take this out
    
    // Do any additional setup after loading the view from its nib.
    
    // Actual implementation. Needs to be confirmed.
    
    // Uncomment the line below for actual launch of firmware stuff.
    if (_unstickBootloader)
    {
        [self unexpectedBootloaderModeForM372DetectedAndApproved:nil];
    }
    else
    {
        [self performSelector:@selector(launchFirmwareCheckForM328:) withObject: [NSNotification notificationWithName: kFirmwareCheckUserInitiatedNotificationNew object: self] afterDelay: 3.0];
        HUD = [[MBProgressHUD alloc] initWithView: self.navigationController.view];
        [self.navigationController.view addSubview: HUD];
        m328FirmwareComplete = NO;
        HUD.labelText = NSLocalizedString(@"Please wait.", nil);
        HUD.detailsLabelText = NSLocalizedString(@"Checking for updates...", nil);
        HUD.square = YES;
        
        [HUD show:YES];
    }
    
    [_progressBar setProgressColor:UIColorFromRGB(M328_PROGRESS_GREEN_COLOR)];
    [_progressBar setProgressStrokeColor:UIColorFromRGB(M328_PROGRESS_GREEN_COLOR)];
}

- (void)didReceiveMemoryWarning
{
    OTLog([NSString stringWithFormat:@"Recived Memory Warning  in %@ ",NSStringFromClass([self class])]);
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSAttributedString *)getAttributedStrWithText:(NSString *)textStr formatStr:(NSString *)formatStr {
    
    UIFont *textFont = [UIFont fontWithName:[iDevicesUtil getAppWideMediumFontName] size:M328_REGISTRATION_TITLE_FONTSIZE];
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:textFont, NSFontAttributeName, [UIColor blackColor],NSForegroundColorAttributeName, nil];
    NSMutableAttributedString *textAtrStr = [[NSMutableAttributedString alloc] initWithString:textStr attributes:dict];
    
    UIFont *formatFont = [UIFont fontWithName: [iDevicesUtil getAppWideFontName] size:M328_REGISTRATION_INFO_FONTSIZE];
    NSDictionary *atrsDict = [NSDictionary dictionaryWithObjectsAndKeys:formatFont, NSFontAttributeName, UIColorFromRGB(COLOR_DEFAULT_TIMEX_FONT),NSForegroundColorAttributeName, nil];
    NSAttributedString *formatAtrStr = [[NSAttributedString alloc] initWithString:formatStr attributes:atrsDict];
    [textAtrStr appendAttributedString:formatAtrStr];
    
    return textAtrStr;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationItem.hidesBackButton = YES;
    TDAppDelegate *appdel = (TDAppDelegate *)[[UIApplication sharedApplication] delegate];
    appdel.customTabbar.autoSyncAllowed = NO;
    
    ((MFSideMenuContainerViewController *)appdel.window.rootViewController).panMode = MFSideMenuPanModeNone;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(launchUserInitiatedFirmwareCheck:) name: kFirmwareCheckUserInitiatedNotificationNew object: nil];
    //TODO: Need to add more of these.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(BootloaderInfoRead:) name: kTDWatchInfoBootloaderReadSuccessfullyNotification object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(BootloaderInfoReadFailed:) name: kTDWatchInfoBootloaderReadUnsuccessfullyNotification object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bootloaderModeForM328Requested:) name: kTDM372BootloaderModeRequested object: nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(watchDisconnected:) name:kDeviceManagerDeviceLostConnectiondNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(watchDisconnected:) name:kPeripheralDeviceAuthorizationFailedNotification object: nil];
    
    // Firmware upgrade notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(FirmwareUpdateComplete:) name: kTDFirmwareWrittenSuccessfullyNotification object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(BootloaderFirmwareUpdateComplete:) name: kTDBootloaderFirmwareWrittenSuccessfullyNotification object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(FirmwareUpdateFailure:) name: kTDFirmwareWrittenUnsuccessfullyNotification object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(WatchInfoRead:) name: kTDWatchInfoFWReadSuccessfullyNotification object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(WatchInfoReadFailed:) name: kTDWatchInfoFWReadUnsuccessfullyNotification object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(successfulInitialConnectionToM328Watch:) name: kPeripheralDeviceTimexDatalinkPrimaryCharacteristicDiscovered object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(unexpectedBootloaderModeForM372Detected:) name: kTDM372UnexpectedBootloaderModeDetected object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(unexpectedBootloaderModeForM372DetectedAndApproved:) name: kTDM372UnexpectedBootloaderModeDetectedAndApproved object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_bleManagerStateChanged:) name:kBLEManagerStateChanged object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    // Remove all the notification observers.
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kFirmwareCheckUserInitiatedNotificationNew object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kPeripheralDeviceTimexDatalinkPrimaryCharacteristicDiscovered object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kTDWatchInfoBootloaderReadSuccessfullyNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kTDWatchInfoBootloaderReadUnsuccessfullyNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kTDM372BootloaderModeRequested object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kTDM372UnexpectedBootloaderModeDetected object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kTDM372UnexpectedBootloaderModeDetectedAndApproved object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kTDFirmwareWrittenSuccessfullyNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kTDBootloaderFirmwareWrittenSuccessfullyNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kTDFirmwareWrittenUnsuccessfullyNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kPeripheralDeviceTimexDatalinkPrimaryCharacteristicDiscovered object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kTDWatchInfoFWReadSuccessfullyNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kTDWatchInfoFWReadUnsuccessfullyNotification object:nil];
   // [[NSNotificationCenter defaultCenter] removeObserver:self name:kDeviceManagerAdvertisingDevicesChangedNotification object:nil];
    //[[NSNotificationCenter defaultCenter] removeObserver:self name:kDeviceManagerConnectedDevicesChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kDeviceManagerDeviceLostConnectiondNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kPeripheralDeviceAuthorizationFailedNotification object: nil];
    [[NSNotificationCenter defaultCenter] removeObserver: self name:kBLEManagerStateChanged object:nil];
    //
    //    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(WatchInfoRead:) name: kTDWatchInfoFWReadSuccessfullyNotification object: nil];
    //
    //    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(WatchInfoReadFailed:) name: kTDWatchInfoFWReadUnsuccessfullyNotification object: nil];
    //TODO: Need to remove more of these.
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    TDAppDelegate *appdel = (TDAppDelegate *)[[UIApplication sharedApplication] delegate];
    appdel.customTabbar.autoSyncAllowed = YES;
    
    [HUD hide:YES];
}

#pragma mark -Watch connection and methods

-(void)unexpectedBootloaderModeForM372Detected:(NSNotification*)notification{
    OTLog(@"Unexpected boot loader mode for m372 detected error");
    _unstickBootloader = YES;
}

-(void)unexpectedBootloaderModeForM372DetectedAndApproved:(NSNotification*)notification
{
    _unstickBootloader = YES;
    infoLabel.attributedText = [self getAttributedStrWithText:NSLocalizedString(@"Stay close.",nil) formatStr:NSLocalizedString(@"\n\nWe are updating your watch. Keep your watch and phone close together until this is done.",nil)];
    bodyLbl.hidden = YES;
    updateBtn.hidden = YES;
    laterBtn.hidden = YES;
    _progressBar.hidden = NO;
    completeLbl.hidden = NO;
    watchProgress.hidden = NO;
    fileLbl.hidden = NO;
    fileLbl.text = [NSString stringWithFormat:NSLocalizedString(@"File %d of %d",nil),0,0];
    // Try to get back or do something here.
    OTLog(@"Unexpected boot loader mode for m372 approved and detected error");
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(didStartFileAccessSession:) name:kTDM328SessionStartNotification object:nil];
    if ([iDevicesUtil hasInternetConnectivity])
    {
        dispatch_async(kFirmwareCheckQueue, ^{
            NSData* data = [NSData dataWithContentsOfURL: kTimexFirmwareCheckURL];
            
            [self performSelectorOnMainThread:@selector(fetchedStuckBootloaderFirmwareInfo:) withObject: data waitUntilDone: YES];
        });
    }
    else
    {
        OTLog(@"No internet connectivity - unable to fetch firmware information from server");
        
        [self handleErrorDuringFirmwareCheck];
    }
    
}

-(void) successfulInitialConnectionToM328Watch:(NSNotification*)notification
{
    if (watchProgress.hidden == YES)
    {
        OTLog(@"Initial Successful Connection to M328 watch!");
       
        [HUD hide: TRUE]; // To fix artf26986
        syncView.hidden = YES;
        syncCover.hidden = YES;
        watchFrame = 0;
        animation = nil;
        [animation invalidate];
        
        infoLabel.attributedText = [self getAttributedStrWithText:NSLocalizedString(@"Stay close.",nil) formatStr:NSLocalizedString(@"\n\nWe are updating your watch. Keep your watch and phone close together until this is done.",nil)];
        //somelbl.text = [NSString stringWithFormat:@"File %@ out of %@", [self _getM328FirmwareUpgradeFileCount]];
        bodyLbl.hidden = YES;
        updateBtn.hidden = YES;
        laterBtn.hidden = YES;
        _progressBar.hidden = NO;
        completeLbl.hidden = NO;
        watchProgress.hidden = NO;
        fileLbl.hidden = NO;
        indicationView.hidden = YES;
        fileLbl.text = [NSString stringWithFormat:NSLocalizedString(@"File %d of %d",nil),0,0];

        PeripheralDevice * timexDevice = [iDevicesUtil getConnectedTimexDevice];
        if (timexDevice)
        {
            OTLog(@"Device connected");
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (_unstickBootloader)
                {
                    [self unexpectedBootloaderModeForM372DetectedAndApproved:nil];
                }
                else
                {
                    [self whosThere:notification];
                }
            });
        }
    }
    
    //TODO: Read the battery information irrespective of Radio file present or not.
    // Charge information is got with kTDWatchChargeInfoFWReadSuccessfullyNotification notification.
    // Once the information is got, check for battery level and threshold.
    // call the next method.
}

- (void) whosThere:(NSNotification*)notification
{
    OTLog(@"whosThere");
    PeripheralDevice * timexDevice = [iDevicesUtil getConnectedTimexDevice];
    if(timexDevice)
    {
        [timexDevice requestWhosThereForFirmwareM328];
        [self performSelector:@selector(successfullyConnectedToM328Watch:) withObject:notification afterDelay:0.5];
    }
}

- (void) successfullyConnectedToM328Watch:(NSNotification*)notification
{
    OTLog(@"Successfully Connected to M328 watch!");
    for (UIWindow* window in [UIApplication sharedApplication].windows)
    {
        NSArray* subviews = window.subviews;
        if ([subviews count] > 0)
        {
            for (id view in subviews)
            {
                if ([view isKindOfClass:[UIAlertView class]])
                {
                    return;
                }
            }
        }
    }
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(didStartFileAccessSession:) name:kTDM328SessionStartNotification object:nil];
    PeripheralDevice * timexDevice = [iDevicesUtil getConnectedTimexDevice];
    if(timexDevice)
    {
        if (self.openedByMenu)
        {
            //_timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(forceFileAccess) userInfo:nil repeats:NO];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (!_unstickBootloader)
                {
                    [timexDevice startFileAccessSession];
                }
            });
        }
        else
        {
            if (retryUpdate && !_unstickBootloader)
            {
                NSLog(@"in retry");
                
                [timexDevice startFileAccessSession];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [timexDevice setUpIQForFirmwareUpgrade];
                });
            }
            else
                [timexDevice setUpIQForFirmwareUpgrade];
        }
    }
}

- (void) _resetWatchAfterDelay: (CGFloat) delay
{
    PeripheralDevice * timexDevice = [iDevicesUtil getConnectedTimexDevice];
    if (timexDevice)
    {
        [timexDevice performSelector:@selector(resetM372Watch) withObject:nil afterDelay: delay];
    }
}

-(void)didStartFileAccessSession:(NSNotification*)notification
{
    fileStarted = YES;
    [[NSNotificationCenter defaultCenter]removeObserver:self name:kTDM328SessionStartNotification object:nil];
    OTLog(@"Connected to M328 watch!");
    if (_unstickBootloader)
    {
        for (TDM372FirmwareUpgradeInfo * downloadInfo in _mFirmwareUpgradeInfo)
        {
            downloadInfo.processed = NO;
        }
    }
    if (_mFirmwareUpgradeInfo && [self _getM328FirmwareUpgradeFileCount] > 0) {
        TDProgressFirmwareUpdate * progress = [TDProgressFirmwareUpdate sharedInstance: FALSE];
        progress.delegate = self;
        //For M372, we need to send the radio file first....
        TDM372FirmwareUpgradeInfo * radio = [self _getM328FirmwareUpgradeFileInfoForType: TDM372FirmwareUpgradeInfoType_Radio];
        if (radio) {
            OTLog(@"Radio upgrade is present");
            PeripheralDevice * timexDevice = [iDevicesUtil getConnectedTimexDevice];
            if (timexDevice) {
                [timexDevice clearPendingActions];
                [timexDevice setProgressFirmware: progress];
                [timexDevice doFirmwareUpgrade: [NSArray arrayWithObject: radio]];
                _timer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                                          target:self
                                                        selector:@selector(progressBarValueChanged:)
                                                        userInfo:timexDevice
                                                         repeats:YES];
            }
        } else {
            OTLog(@"Radio upgrade not present.");
            [self _sendPendingFirmWareFilesBootlaoder:NO];
        }
    } else {
        OTLog(@"No more files to be written");
        if (m328WatchResetRequested) {
            [HUD hide: TRUE];
            syncView.hidden = YES;
            syncCover.hidden = YES;
            watchFrame = 0;
            animation = nil;
            [animation invalidate];
            m328WatchResetRequested = FALSE;
            OTLog(@"Requesting reset");
            [self _resetWatchAfterDelay: 1.0];
        }
    }
}


/**
 *  This method should not be called at all.
 */
- (void) _initiateBootloaderModeStatusCheck
{
    PeripheralDevice * timexDevice = [iDevicesUtil getConnectedTimexDevice];
    if (timexDevice)
    {
        //[self doTimexBluetoothSmart: [self nextSubAction: SUBACTION_END]];
        //        [timexDevice resetPendingActions]; // Need to check this one.
        [timexDevice requestDeviceInfoForBootloaderStatus];
    }
}


- (void) BootloaderInfoRead: (NSNotification*)notification
{
    OTLog(@"Read Bootloader Info:");
    
    PCCommWhosThere * readSettings = [notification.userInfo objectForKey: kDeviceWatchInfoKey];
    if (readSettings)
    {
        OTLog(@"Bootloader status is %d", readSettings.mModeStatus);
        if (readSettings.mModeStatus == 0)
        {
            [[TDProgressFirmwareUpdate sharedInstance: FALSE] dismiss];// Not sure about this one.
            //we are not yet in bootloader
            //            OTLog(@"Kicking off bootloader mode");
            // Dont load into bootloader ever.
            //            [self performSelector:@selector(_initiateBootloaderModeForM328) withObject:nil afterDelay: 0.5];
        }
        else
        {
            [self _sendPendingFirmWareFilesBootlaoder:YES];
        }
    }
}

- (void) BootloaderInfoReadFailed: (id) sender
{
    //    OTLog(@"Boot loader info read failed... WTF");
    
}


- (void) M372FirmwareUploadWatchChargeInfoRead: (NSNotification*)notification
{
    if (_mFirmwareUpgradeInfo && [self _getM328FirmwareUpgradeFileCount] > 0)
    {
        PCCommChargeInfo * chargeInfo = [notification.userInfo objectForKey: kDeviceWatchChargeInfoKey];
        [TDM328WatchSettingsUserDefaults setBatteryVolt:chargeInfo.voltage];
        OTLog(@"M328FirmwareUploadWatchChargeInfoRead");
        if (chargeInfo)
        {
            if (chargeInfo.voltage <= M372_GOOD_VOLTAGE_THRESHOLD)
            {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"Low Battery Alert", @"Modification Date: 06/01/2015")
                                                                message: NSLocalizedString(@"Your battery is too low to perform this firmware update. Please replace the battery and try again.", @"Modification Date: 12/10/2015")
                                                               delegate:self cancelButtonTitle: NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
                if (!alert.visible)
                {
                    [alert show];
                }
            }
            else
            {
                //[self successfullyConnectedToM328Watch: nil];
            }
        }
    }
}

- (void)BootloaderFirmwareUpdateComplete: (NSNotification*)notification
{
    OTLog(@"BootloaderFirmwareUpdateComplete");
    if (_mFirmwareUpgradeInfo && [self _getM328FirmwareUpgradeFileCount] > 0)
    {
        [[TDProgressFirmwareUpdate sharedInstance: FALSE] dismiss];
        [self performSelector:@selector(successfullyConnectedToM328Watch:) withObject: notification afterDelay: 1.0];
    }
    else
    {
        //            [self _exitBootloaderModeForM372];
        
        [self endDeviceFileAccessSession];
        
        m328FirmwareComplete = YES;
        NSMutableDictionary * dictFlurry = [[NSMutableDictionary alloc] init];
        [dictFlurry setValue: [iDevicesUtil convertWatchStyleToProductName: [[TDWatchProfile sharedInstance] watchStyle]] forKey: @"Watch_Product"];
        [dictFlurry setValue: [NSNumber numberWithInteger: _firmwareVersionOnServer] forKey: @"Firmware_Sent"];
        [dictFlurry setValue: [NSNumber numberWithBool: YES] forKey: @"Firmware_Sent_Successfully"];
        [iDevicesUtil endTimedFlurryEvent: @"FIRMWARE_UPGRADE" withParameters:dictFlurry];
        
        [[TDProgressFirmwareUpdate sharedInstance: FALSE] dismiss];
        
        //delete the downloaded files....
        [self _DeleteDownloadedData];
        
        [self displayFirmwareUploadSuccessAlert];
    }
}
- (void)FirmwareUpdateComplete: (NSNotification*)notification
{
    if (_mFirmwareUpgradeInfo && [self _getM328FirmwareUpgradeFileCount] > 0)
    {
        OTLog(@"Completed uploading one firmware file... see what else is there");
        [self successfullyConnectedToM328Watch: nil];
        
        [[TDProgressFirmwareUpdate sharedInstance: FALSE] dismiss];
    }
    else
    {
        if (_unstickBootloader)
        {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:kDeviceManagerDeviceLostConnectiondNotification object:nil];
            [[NSNotificationCenter defaultCenter] removeObserver: self name: kPeripheralDeviceAuthorizationFailedNotification object: nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(FirmwareUpdateFailure:) name: kTDFirmwareWrittenUnsuccessfullyNotification object: nil];
            
            [self endDeviceFileAccessSession];
        }
        else
        {
            [self _softResetWatch];
        }
        OTLog(@"Firmware update fully completed");
        NSMutableDictionary * dictFlurry = [[NSMutableDictionary alloc] init];
        [dictFlurry setValue: [iDevicesUtil convertWatchStyleToProductName: [[TDWatchProfile sharedInstance] watchStyle]] forKey: @"Watch_Product"];
        [dictFlurry setValue: [NSNumber numberWithInteger: _firmwareVersionOnServer] forKey: @"Firmware_Sent"];
        [dictFlurry setValue: [NSNumber numberWithBool: YES] forKey: @"Firmware_Sent_Successfully"];
        [iDevicesUtil endTimedFlurryEvent: @"FIRMWARE_UPGRADE" withParameters:dictFlurry];
        
        [[TDProgressFirmwareUpdate sharedInstance: FALSE] dismiss]; // May be.
        
        //delete the downloaded files....
        for (TDM372FirmwareUpgradeInfo * downloadInfo in _mFirmwareUpgradeInfo)
        {
            NSString *version = [NSString stringWithFormat:@"%ld",(long)downloadInfo.version];
            if (downloadInfo.version < 100)
            {
                version = [NSString stringWithFormat:@"0%ld",(long)downloadInfo.version];
            }
            else if (downloadInfo.version < 10)
            {
                version = [NSString stringWithFormat:@"00%ld",(long)downloadInfo.version];
            }
            switch (downloadInfo.type)
            {
                case TDM372FirmwareUpgradeInfoType_Activity:
                    [[NSUserDefaults standardUserDefaults] setObject: [NSString stringWithFormat:@"M372A%@",version] forKey: kM372FirmwareVersionFile1Key];
                    break;
                case TDM372FirmwareUpgradeInfoType_Radio:
                    if([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)
                        [[NSUserDefaults standardUserDefaults] setObject: [NSString stringWithFormat:@"M329R%@",version] forKey: kM372FirmwareVersionFile2Key];
                    else
                        [[NSUserDefaults standardUserDefaults] setObject: [NSString stringWithFormat:@"M328R%@",version] forKey: kM372FirmwareVersionFile2Key];
                    break;
                case TDM372FirmwareUpgradeInfoType_Firmware:
                    if([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)
                        [[NSUserDefaults standardUserDefaults] setObject: [NSString stringWithFormat:@"M329F%@",version] forKey: kM372FirmwareVersionFile3Key];
                    else
                        [[NSUserDefaults standardUserDefaults] setObject: [NSString stringWithFormat:@"M328F%@",version] forKey: kM372FirmwareVersionFile3Key];
                    break;
                case TDM372FirmwareUpgradeInfoType_Codeplug:
                    if([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)
                        [[NSUserDefaults standardUserDefaults] setObject: [NSString stringWithFormat:@"M329C%@",version] forKey: kM372FirmwareVersionFile4Key];
                    else
                        [[NSUserDefaults standardUserDefaults] setObject: [NSString stringWithFormat:@"M328C%@",version] forKey: kM372FirmwareVersionFile4Key];
                    break;
                default:
                    break;
            }
        }
        [self _DeleteDownloadedData];
        m328FirmwareComplete = YES;
        
        [_timer invalidate];
        _timer = nil;
        
        [self.progressBar setValue:0];
        [self displayFirmwareUploadSuccessAlert];
    }
}

- (void)FirmwareUpdateFailure: (NSNotification*)notification
{
    OTLog(@"FirmwareUpdateFailure");
    NSMutableDictionary * dictFlurry = [[NSMutableDictionary alloc] init];
    [dictFlurry setValue: [iDevicesUtil convertWatchStyleToProductName: [[TDWatchProfile sharedInstance] watchStyle]] forKey: @"Watch_Product"];
    [dictFlurry setValue: [NSNumber numberWithInteger: _firmwareVersionOnServer] forKey: @"Firmware_Sent"];
    [dictFlurry setValue: [NSNumber numberWithBool: NO] forKey: @"Firmware_Sent_Successfully"];
    [iDevicesUtil endTimedFlurryEvent: @"FIRMWARE_UPGRADE" withParameters:dictFlurry];
    
    [[TDProgressFirmwareUpdate sharedInstance: FALSE] dismiss];
    
    //delete the downloaded files....
    [self _DeleteDownloadedData];
    
    [self removeAllAlerts];
    
    [_timer invalidate];
    _timer = nil;
    
    [self.progressBar setValue:0];
    [self errorController];
    //TestLog_M372FirmwareUpdateV2
    //ThisAlertHasAnActionWhenTryAgainIsSelected
}

-(void) _bleManagerStateChanged:(NSNotification*)notifcation
{
    if (!bleManager.isBLEAvailable)
    {
        [self performSelector:@selector(showBluetoothNonAvailabilityAlert) withObject:nil afterDelay:0.5];
    }
}

-(void)showBluetoothNonAvailabilityAlert
{
    if (!bleManager.isBLEAvailable)
    {
        NSString * title = NSLocalizedString(@"Bluetooth unavailable", nil);
        NSString * msg = nil;
        msg = NSLocalizedString(@"Bluetooth is powered off. Please turn on Bluetooth in System Settings before proceeding.", nil);
        UIAlertView *message = [[UIAlertView alloc] initWithTitle: title
                                                          message: msg
                                                         delegate: nil
                                                cancelButtonTitle: NSLocalizedString(@"OK", nil)
                                                otherButtonTitles: nil];
        [message show];
    }
}

- (NSInteger) _getM328FirmwareUpgradeFileCount
{
    NSInteger count = 0;
    
    for (TDM372FirmwareUpgradeInfo * downloadInfo in _mFirmwareUpgradeInfo)
    {
        if (!downloadInfo.processed) count++;
    }
    
    return count;
}

- (BOOL) _getM328FirmwareUpgradeFileInfoPresenceForType: (TDM372FirmwareUpgradeInfoType) type
{
    BOOL present = FALSE;
    
    for (TDM372FirmwareUpgradeInfo * downloadInfo in _mFirmwareUpgradeInfo)
    {
        if (type == downloadInfo.type && downloadInfo.processed == FALSE)
        {
            present = TRUE;
            break;
        }
    }
    
    return present;
}

- (TDM372FirmwareUpgradeInfo *) _getM328FirmwareUpgradeFileInfoForType: (TDM372FirmwareUpgradeInfoType) type
{
    for (TDM372FirmwareUpgradeInfo * downloadInfo in _mFirmwareUpgradeInfo)
    {
        if (type == downloadInfo.type && downloadInfo.processed == FALSE)
        {
            TDM372FirmwareUpgradeInfo * downloadInfoCopy = downloadInfo;
            downloadInfo.processed = TRUE;
            return downloadInfoCopy;
            break;
        }
    }
    
    return nil;
}


/**
 *  Attempts to connect to device for about 15 times with a gap of 1 second
 *  Once its connected, need to get the watch information and stuff.
 */
- (void) _connectToM328DeviceForFirmwareUpload
{
    //first, we need to CONNECT to the device again... and not just A device, but THE device
    NSArray* newList = [NSArray arrayWithArray:[TDDeviceManager sharedInstance].advertisingDevices];
    // Filtered devices which are only iQ+ watches.
    NSArray *devicesArray;
    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)
    {
        // Filter by only iQ+ Travel watches.
        devicesArray = [[[newList arrayByAddingObjectsFromArray: [TDDeviceManager sharedInstance].connectedDevices] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.name contains[c] 'iQTR'"]] mutableCopy];
    }
    else
    {
        // Filter by only Guess iQ+ watches.
        devicesArray = [[[newList arrayByAddingObjectsFromArray: [TDDeviceManager sharedInstance].connectedDevices] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.name contains[c] 'iQMV'"]] mutableCopy];
    }
    
    NSString * deviceUUID = [[NSUserDefaults standardUserDefaults] objectForKey: kCONNECTED_DEVICE_UUID_PREF_NAME];
    if (deviceUUID != nil)
    {
//        NSArray * adverts = [[TDDeviceManager sharedInstance] getAllConnectedAndAdvertisingDevices];
        NSUInteger idx = NSNotFound;
        
        if (devicesArray.count > 0) {
            for (PeripheralDevice *device in devicesArray) {
                if ([device.peripheral.UUID.UUIDString isEqualToString:deviceUUID]) {
                    idx = [devicesArray indexOfObject:device];
                    break;
                }
            }
        }
        
        if (idx != NSNotFound)
        {
            m328ReconnectAttempts = 0;
            PeripheralDevice * device = [devicesArray objectAtIndex: idx];
            if (device != NULL)
            {
                OTLog(@"Attempting to connect to %@...", device.peripheral.UUID.UUIDString);
                [[TDDeviceManager sharedInstance] connect: device];
            }
        }
        else
        {
            m328ReconnectAttempts++;
            if (m328ReconnectAttempts > 30)
            {
                [HUD hide: TRUE];
                
                [self _DeleteDownloadedData];
                
                m328ReconnectAttempts = 0;
                m328WatchResetRequested = FALSE;
                
                syncView.hidden = YES;
                syncCover.hidden = YES;
                watchFrame = 0;
                animation = nil;
                [animation invalidate];
                
                //TODO:Validation when the app doesn't find the watch
                OTLog(@"An error occurred while connecting to watch after 30 sec");
                [self removeAllAlerts];
                [self errorController];
                
                
            }
            else
            {

                if (m328ReconnectAttempts == 1) {
                    [HUD hide:YES];
//                    if (_openedByMenu)
//                    {
                        syncView.hidden = NO;
                        syncCover.hidden = NO;
                        watchFrame = 0;
                        infoLbl.attributedText = [self getAttributedStrWithText:NSLocalizedString(@"Sync to update",nil)
                                                               mediumFormatText:NSLocalizedString(@"Crown",nil)
                                                              mediumFormatText2:NSLocalizedString(@"3 tone melody",nil)
                                                                      formatStr:NSLocalizedString(@"\n\nTo connect your watch with the phone, press and hold the Crown for about 5 seconds until you hear a 3 tone melody and the hands move together.",nil)];
                        animation = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(watchAnimation) userInfo:nil repeats:YES];
//                    }
                }
                
                
                OTLog(@"Attempting to reconnect...");
                [self performSelector:@selector(_connectToM328DeviceForFirmwareUpload) withObject:nil afterDelay: 1.0];
            }
        }
    }
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


#pragma  mark - Selectors

- (void) _initiateBootloaderModeForM328
{
    OTLog(@"_initiateBootloaderModeForM328");
    HUD = [[MBProgressHUD alloc] initWithView: self.navigationController.view];
    [self.navigationController.view addSubview: HUD];
    
    HUD.labelText = NSLocalizedString(@"Please Wait", nil);
    HUD.detailsLabelText = NSLocalizedString(@"Initiating Bootloader...", nil);
    [HUD show: YES];
    
    PeripheralDevice * timexDevice = [iDevicesUtil getConnectedTimexDevice];
    if (timexDevice)
    {
        // Not sure about reseting pending actions.
        //        [timexDevice resetPendingActions]; // Resets the pending actions. Checking it once.
        
        [timexDevice startBootloaderForM372];
    }
}

- (void) _softResetWatch
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kDeviceManagerDeviceLostConnectiondNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kPeripheralDeviceAuthorizationFailedNotification object: nil];
    
    OTLog(@"_softResetWatch");
    PeripheralDevice * timexDevice = [iDevicesUtil getConnectedTimexDevice];
    if (timexDevice)
    {
        [timexDevice softResetM372Watch]; // Same command for both M372 and M328
    }
}


//- (void) _sendBootloaderFiles
/**
 *  Sends the pending firmware files from the instances.
 */
-(void)_sendPendingFirmWareFilesBootlaoder:(BOOL)isBootLoader
{
    OTLog(@"_sendPendingFirmWareFiles");
    if (isBootLoader) {
        OTLog(@"We are already in bootloader");
    }
    //we are already in bootloader! proceed
    TDProgressFirmwareUpdate * progress = [TDProgressFirmwareUpdate sharedInstance: FALSE];
    OTLog(@"\n\n\nProgress : %f",progress.progress);
//    [self.progressBar setValue:[[NSNumber numberWithInt:progress.progress] intValue]];
    TDM372FirmwareUpgradeInfo *activity = [self _getM328FirmwareUpgradeFileInfoForType: TDM372FirmwareUpgradeInfoType_Activity];
    TDM372FirmwareUpgradeInfo *codePlug = [self _getM328FirmwareUpgradeFileInfoForType: TDM372FirmwareUpgradeInfoType_Codeplug];
    TDM372FirmwareUpgradeInfo *fmw = [self _getM328FirmwareUpgradeFileInfoForType: TDM372FirmwareUpgradeInfoType_Firmware];
    
    PeripheralDevice * timexDevice = [iDevicesUtil getConnectedTimexDevice];
    if (timexDevice)
    {
        NSMutableArray *group = [NSMutableArray new];
        [timexDevice setProgressFirmware: progress];
        if (activity)
        {
            OTLog(@"Sending activity file.");
            HUD.detailsLabelText = NSLocalizedString(@"Sending activity file", nil);
            [group addObject:activity];
        }
        if (codePlug)
        {
            OTLog(@"Sending code plug file");
            HUD.detailsLabelText = NSLocalizedString(@"Sending code plug file", nil);
            [group addObject:codePlug];
        }
        if (fmw)
        {
            OTLog(@"Sending firmware file");
            HUD.detailsLabelText = NSLocalizedString(@"Sending firmware file", nil);
            [group addObject:fmw];
        }
        _timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(progressBarValueChanged:) userInfo:timexDevice repeats:YES];
        [timexDevice clearPendingActions];
        [timexDevice doFirmwareUpgrade: group];
        firmwareFileTotal = (int)group.count;
        int filesLeft = (firmwareFileTotal - (int)[self _getM328FirmwareUpgradeFileCount]);
        fileLbl.text = [NSString stringWithFormat:NSLocalizedString(@"File %d of %d",nil),filesLeft,firmwareFileTotal];
        
    }
}


// Not to be used.
//- (void) _exitBootloaderModeForM372
//{
//    PeripheralDevice * timexDevice = [iDevicesUtil getConnectedTimexDevice];
//    if (timexDevice)
//    {
//        [timexDevice exitBootloaderForM372];
//    }
//}


- (void) fetchedStuckBootloaderFirmwareInfo: (NSData *)responseData
{
    OTLog(@"fetchedStuckBootloaderFirmwareInfo");
    
    BOOL        foundJSONmodule = false;
    NSError     * error = nil;
    
    NSDictionary* json = [NSJSONSerialization JSONObjectWithData: responseData options:kNilOptions error: &error];
    
    NSNumber * json_version = [json objectForKey: @"file_version"];
    
    if ([json_version intValue] == FIRMWARE_UPGRADE_JSON_FILE_VERSION)
    {
        NSArray* availableModules = [json objectForKey: @"modules"];
        for (NSDictionary * availableModule in availableModules)
        {
            NSString * moduleName = [availableModule objectForKey:@"name"];
            if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQ && [moduleName isEqualToString: @"M328"])
            {
                foundJSONmodule = TRUE;
                [self _createFirmwareUpdateInfoArrayForM328: availableModule bootloaderOnly: TRUE];
            }
            else if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel && [moduleName isEqualToString: @"M329"])
            {
                foundJSONmodule = TRUE;
                [self _createFirmwareUpdateInfoArrayForM328: availableModule bootloaderOnly: TRUE];
            }
        }
    }
    
    if (foundJSONmodule)
    {
        //since we are in bootloader mode, we want to send ALL firmware files to ensure that we successfully kick out of bootloader. therefore, do not check for versions
        if (_mFirmwareUpgradeInfo.count > 0)
        {
            [self getBootloaderUnstuck];
        }
        else
        {
            [self tickButtonTapped:nil];
        }
    }
    else
    {
        [self tickButtonTapped:nil];
    }
}

- (void) getBootloaderUnstuck
{
    m328StuckInBootloader = TRUE;
    
    HUD = [[MBProgressHUD alloc] initWithView: self.navigationController.view];
    [self.navigationController.view addSubview: HUD];
    
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
        [[TCBlobDownloadManager sharedInstance] startDownloadWithURL:[NSURL URLWithString: downloadInfo.uri] customPath: newDir delegate: self];
    }
}


#pragma mark - Checking for firmware upgrades.

- (void) WatchInfoRead: (NSNotification*)notification
{
    //This is a fix for Mantis 591, when the watch status dialog is launched in the middle of firmware download, but dismissed before the information could be processed there. We ned to make sure that we don't process this information here if we are in the middle of firmware download.
    PeripheralDevice * timexDevice = [iDevicesUtil getConnectedTimexDevice];
    if ([timexDevice isFirmwareUpgradeInProgress] || [timexDevice isFirmwareUpgradePaused])
        return;
    
    _mReadSettings = [notification.userInfo objectForKey: kDeviceWatchInfoKey];
    if (_mReadSettings)
    {
        if ([iDevicesUtil hasInternetConnectivity])
        {
            //read board WHOIS info successfully... now perform firmware check
            dispatch_async(kFirmwareCheckQueue, ^{
                NSData* data = [NSData dataWithContentsOfURL: kTimexFirmwareCheckURL];
                
                [self performSelectorOnMainThread:@selector(fetchedFirmwareInfo:) withObject: data waitUntilDone: YES];
            });
        }
        else
        {
            OTLog(@"No internet connectivity - unable to fetch firmware information from server");
            
            [self handleErrorDuringFirmwareCheck];
        }
    }
}
- (void) WatchInfoReadFailed: (id) sender
{
    [self handleErrorDuringFirmwareCheck];
}

- (void) handleErrorDuringFirmwareCheck
{
    if(_noInternetAlert == nil)
    {
        _noInternetAlert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"FIRMWARE UPDATE", nil)
                                                               message:NSLocalizedString(@"Internet connection lost", nil)
                                                        preferredStyle:UIAlertControllerStyleAlert];
        
        [_noInternetAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                             style:UIAlertActionStyleCancel
                                                           handler:^(UIAlertAction * _Nonnull action)
                                     {
                                         [self tickButtonTapped:nil];
                                     }]];
        
        [self presentViewController:_noInternetAlert animated:YES completion:nil];
    }
    [HUD hide: TRUE];
    syncView.hidden = YES;
    syncCover.hidden = YES;
    watchFrame = 0;
    animation = nil;
    [animation invalidate];
}



- (void) launchUserInitiatedFirmwareCheck: (NSNotification*)notification
{
    if ([iDevicesUtil hasInternetConnectivity])
    {
        //            [self handleFirmwareCheckInitiation]; // No implementation. Nothing done here.
        dispatch_async(kFirmwareCheckQueue, ^{
            NSData* data = [NSData dataWithContentsOfURL: kTimexFirmwareCheckURL];
            
            [self performSelectorOnMainThread:@selector(fetchedFirmwareInfo:) withObject: data waitUntilDone: YES];
        });
    }
    else
    {
        if(_noInternetAlert == nil){
            if(_noInternetAlert == nil)
            {
                _noInternetAlert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"FIRMWARE UPDATE", nil)
                                                                       message:NSLocalizedString(@"Internet connection lost", nil)
                                                                preferredStyle:UIAlertControllerStyleAlert];
                
                [_noInternetAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                                     style:UIAlertActionStyleCancel
                                                                   handler:^(UIAlertAction * _Nonnull action)
                                             {
                                                 [self tickButtonTapped:nil];
                                             }]];
                
                [self presentViewController:_noInternetAlert animated:YES completion:nil];
            }
        }
        //TODO: Go to next view.
        
        
    }
}


/**
 *  Method that checks and updates the information for upgrade.
 * This is reused from M372 but with a name change on the method.
 * Logic to download or not stays here.
 *
 *  @param versionOnWatch <#versionOnWatch description#>
 */
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

/**
 *  Gets the version number out of the value
 *
 *  @param value Value of the string
 *
 *  @return version number.
 */
- (NSString *)_getVersionSubstring: (NSString *)value
{
    NSRange finalRange = NSMakeRange(value.length - 3, 3);
    return [value substringWithRange:finalRange];
}


/**
 *  Called to let the user know that there is a new firmware that needs to be upgraded.
 *
 *  @param notification <#notification description#>
 */
- (void) handleNewFirmwareVersion: (NSNotification *) notification
{
    if (notification != nil)
    {
        //if notification parameter is not nill, handleNewFirmwareVersion was launched by
        //kFirmwareRequestUserInitiatedNotification notification
        NSDictionary * userInfo = notification.userInfo;
        _mFirmwareUpgradeInfo = [[NSMutableArray alloc] initWithArray:[userInfo allValues]];
    }
    if (_mFirmwareUpdateAlert == nil || _mFirmwareUpdateAlert.isVisible == false)
    {
        [self removeAllAlerts];
        if (!_openedByMenu || _neededUpdate)
        {
            [self updateNowTap:nil];
        }
        else
        {
            infoLabel.attributedText = [self getAttributedStrWithText:NSLocalizedString(@"We found an update.",nil) formatStr:NSLocalizedString(@"\n\nThis process may take several minutes.",nil)];
            bodyLbl.hidden = NO;
            updateBtn.hidden = NO;
            laterBtn.hidden = NO;
            
            TDAppDelegate *appdel = (TDAppDelegate *)[[UIApplication sharedApplication] delegate];
            ((MFSideMenuContainerViewController *)appdel.window.rootViewController).panMode = MFSideMenuPanModeDefault;
        }
    }
}

- (IBAction)updateLaterTap:(id)sender
{
    // Delete the information for firmware and move to next page.
    [self _DeleteDownloadedData];
    [self tickButtonTapped:nil];
}
- (IBAction)updateNowTap:(id)sender
{
    //Keep the watch connected
    //ismanuallyDisconnected = YES;
    //[self endDeviceFileAccessSession];
    
    TDAppDelegate *appdel = (TDAppDelegate *)[[UIApplication sharedApplication] delegate];
    ((MFSideMenuContainerViewController *)appdel.window.rootViewController).panMode = MFSideMenuPanModeNone;
    
    HUD = [[MBProgressHUD alloc] initWithView: self.navigationController.view];
    [self.navigationController.view addSubview: HUD];
    
    HUD.labelText = NSLocalizedString(@"Please Wait", nil);
    HUD.detailsLabelText = NSLocalizedString(@"Downloading Firmware Update...", nil);
    HUD.square = YES;
    HUD.mode = MBProgressHUDModeDeterminateHorizontalBar;
    [HUD show: YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(successfulInitialConnectionToM328Watch:) name: kPeripheralDeviceTimexDatalinkPrimaryCharacteristicDiscovered object: nil];
    
    NSString * tempDir = NSTemporaryDirectory();
    NSString * newDir = [tempDir stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]];
    [[NSFileManager defaultManager] createDirectoryAtPath:newDir withIntermediateDirectories: NO attributes: nil error: nil];
    for (TDM372FirmwareUpgradeInfo * downloadInfo in _mFirmwareUpgradeInfo)
    {
        OTLog(@"\n\n\nDownloaded PAth:%@",newDir);
        [[TCBlobDownloadManager sharedInstance] startDownloadWithURL:[NSURL URLWithString: downloadInfo.uri] customPath: newDir delegate: self];
    }
}

- (IBAction)okTap:(id)sender
{
    [self tickButtonTapped:nil];
}


/**
 *  Creates an array of firmware upgrading logic. We are
 * re using M372 update ones since the structure can be re-used.
 *
 *  @param availableModule List of available module
 *  @param blOnly          bootloader only mode.
 */
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

/**
 *  Called when the firmware information is downloaded from the server.
 * There will be parsing and checking of the received data and then comparision.
 *
 *  @param data : Firmware json data from server.
 */
-(void)fetchedFirmwareInfo:(NSData*)responseData {
    
    BOOL        foundJSONmodule = false;
    NSError     * error = nil;
    
    //if we got no data, or we are no longer on the foreground for whatever reason....
    if (responseData == nil || ![self isViewLoaded] || self.view.window == nil)
    {
        [self removeAllAlerts];
        [self tickButtonTapped:nil];
        [HUD hide:YES];
        watchFrame = 0;
        animation = nil;
        [animation invalidate];
        [self handleErrorDuringFirmwareCheck];
        return;
    }
    NSDictionary* json = [NSJSONSerialization JSONObjectWithData: responseData options:kNilOptions error: &error];
    if (!json)
    {
        [self removeAllAlerts];
        [HUD hide:YES];
        watchFrame = 0;
        animation = nil;
        [animation invalidate];
        [self handleErrorDuringFirmwareCheck];
        return;
    }
    
    NSNumber * json_version = [json objectForKey: @"file_version"];
    OTLog(@"%@",json);
    if ([json_version intValue] == FIRMWARE_UPGRADE_JSON_FILE_VERSION)
    {
        NSArray* availableModules = [json objectForKey: @"modules"];
        for (NSDictionary * availableModule in availableModules)
        {
            // Look for M328 named module
            NSString * moduleName = [availableModule objectForKey:@"name"];
            if([moduleName isEqualToString:@"M328"] && [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQ)
            {
                foundJSONmodule = true;
                [self _createFirmwareUpdateInfoArrayForM328:availableModule bootloaderOnly:FALSE];
            }
            else if([moduleName isEqualToString:@"M329"] && [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)
            {
                foundJSONmodule = true;
                [self _createFirmwareUpdateInfoArrayForM328:availableModule bootloaderOnly:FALSE];
            }
        }
    }
    if (foundJSONmodule == YES)
    {
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
            
            [HUD hide:true];
            syncView.hidden = YES;
            syncCover.hidden = YES;
            watchFrame = 0;
            animation = nil;
            [animation invalidate];
            isThereAnUpdate = NO;
            if (_mFirmwareUpgradeInfo.count > 0)
            {
                isThereAnUpdate = YES;
                [self handleNewFirmwareVersion: nil];
            }
            else
            {
                //                [self handleNoNewFirmwareVersion];
                [self removeAllAlerts];
                [HUD hide:YES];
                syncView.hidden = YES;
                syncCover.hidden = YES;
                watchFrame = 0;
                animation = nil;
                [animation invalidate];
                if (isThereAnUpdate || _openedByMenu)
                {
                    infoLabel.attributedText = [self getAttributedStrWithText:NSLocalizedString(@"Your watch is up to date.", nil) formatStr:NSLocalizedString(@"\n\nYour watch is up to date with the newest features.", nil)];
                    [self performSelector:@selector(tickButtonTapped:) withObject:nil afterDelay:6];
                    [self setInfoText];
                    bodyLbl.hidden = NO;
                    
                    TDAppDelegate *appdel = (TDAppDelegate *)[[UIApplication sharedApplication] delegate];
                    ((MFSideMenuContainerViewController *)appdel.window.rootViewController).panMode = MFSideMenuPanModeDefault;

                }
                else
                {
                    [self tickButtonTapped:nil];
                }
                alignLbl.hidden = YES;
                _progressBar.hidden = YES;
                completeLbl.hidden = YES;
                watchProgress.hidden = YES;
                fileLbl.hidden = YES;
                _tickButton.hidden = NO;
                return;
            }
        }
    }
}

/**
 *  Method that checks for device and then checks if
 the last sync time is more than a week. Post that, it will send
 a notification to get the firmware versions.
 *
 *  @param notification <#notification description#>
 */
- (void) launchFirmwareCheckForM328: (NSNotification*)notification
{
    OTLog(@"M328 Firmware check requested by %@", notification.name);
    
    PeripheralDevice * timexDevice = [iDevicesUtil getConnectedTimexDevice];
    if (timexDevice != nil)
    {
        if ([timexDevice isFirmwareUpgradeInProgress])
        {
            OTLog(@"Did not perform M328 Firmware check because the firmware upgrade is currently in progress");
            return;
        }
    }

        [[NSNotificationCenter defaultCenter] postNotificationName: kFirmwareCheckUserInitiatedNotificationNew object:self];
}


-(void)displayFirmwareUploadSuccessAlert{
    
    if (_unstickBootloader)
    {
        PeripheralDevice * timexDevice = [iDevicesUtil getConnectedTimexDevice];
        if(timexDevice)
        {
            [timexDevice performSelector:@selector(endFileAccessSession) withObject:nil afterDelay:1];
        }
    }
    // show the update succesfull
    [self removeAllAlerts];
    _progressBar.hidden = YES;
    completeLbl.hidden = YES;
    watchProgress.hidden = YES;
    fileLbl.hidden = YES;
    bodyLbl.hidden = NO;
    indicationView.hidden = NO;
    bodyLbl.hidden = NO;
    [self setInfoText];
    [indicationView startAnimating];
    if (!_unstickBootloader)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(90 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self wiggleComplete];
        });
    }
    else
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self wiggleComplete];
        });
    }
    
    infoLabel.attributedText = [self getAttributedStrWithText:NSLocalizedString(@"Your watch is up to date",nil) formatStr:NSLocalizedString(@"\n\nPlease do not close the app.",nil)];
    
    [self setInfoText];
    bodyLbl.hidden = NO;
    NSMutableString *bodyString = [[NSMutableString alloc] initWithString:bodyLbl.text];
    [bodyString appendString:NSLocalizedString(@"\n\n\nThe watch hand will wiggle for a few minutes.\n\nYou'll need to reconnect the watch to the app and align the hands.",nil)];
    bodyLbl.text = bodyString;
}

- (void)setInfoText
{
    NSString *text = NSLocalizedString(@"Firmware\nOn watch: #FIRMWARE1#-#FIRMWARE2#-#FIRMWARE3#-#FIRMWARE4#\nAvailable: #FIRMWARE1#-#FIRMWARE2#-#FIRMWARE3#-#FIRMWARE4#",nil);
    
    NSMutableString *string = [text mutableCopy];
    // Get the firmware information also
    for (int i = 0; i < 2; i++)
    {
        NSString * firmwareOnWatch = [NSString stringWithFormat:@"A%ld", [[[[NSUserDefaults standardUserDefaults] objectForKey: kM372FirmwareVersionFile1Key] stringByReplacingOccurrencesOfString:@"M372A" withString:@""] integerValue]];
        [string replaceOccurrencesOfString:@"#FIRMWARE1#" withString:firmwareOnWatch?:@"" options:NSCaseInsensitiveSearch range:[string rangeOfString:@"#FIRMWARE1#"]];
        
        firmwareOnWatch = [NSString stringWithFormat:@"R%ld", [[[[NSUserDefaults standardUserDefaults] objectForKey: kM372FirmwareVersionFile2Key] stringByReplacingOccurrencesOfString:@"M328R" withString:@""] integerValue]];
        [string replaceOccurrencesOfString:@"#FIRMWARE2#" withString:firmwareOnWatch?:@"" options:NSCaseInsensitiveSearch range:[string rangeOfString:@"#FIRMWARE2#"]];
        
        if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)
        {
            firmwareOnWatch = [NSString stringWithFormat:@"F%ld", [[[[NSUserDefaults standardUserDefaults] objectForKey: kM372FirmwareVersionFile3Key] stringByReplacingOccurrencesOfString:@"M329F" withString:@""] integerValue]];
            [string replaceOccurrencesOfString:@"#FIRMWARE3#" withString:firmwareOnWatch?:@"" options:NSCaseInsensitiveSearch range:[string rangeOfString:@"#FIRMWARE3#"]];
            
            firmwareOnWatch = [NSString stringWithFormat:@"C%ld", [[[[NSUserDefaults standardUserDefaults] objectForKey: kM372FirmwareVersionFile4Key] stringByReplacingOccurrencesOfString:@"M329C" withString:@""] integerValue]];
            [string replaceOccurrencesOfString:@"#FIRMWARE4#" withString:firmwareOnWatch?:@"" options:NSCaseInsensitiveSearch range:[string rangeOfString:@"#FIRMWARE4#"]];
        } else {
            firmwareOnWatch = [NSString stringWithFormat:@"F%ld", [[[[NSUserDefaults standardUserDefaults] objectForKey: kM372FirmwareVersionFile3Key] stringByReplacingOccurrencesOfString:@"M328F" withString:@""] integerValue]];
            [string replaceOccurrencesOfString:@"#FIRMWARE3#" withString:firmwareOnWatch?:@"" options:NSCaseInsensitiveSearch range:[string rangeOfString:@"#FIRMWARE3#"]];
            
            firmwareOnWatch = [NSString stringWithFormat:@"C%ld", [[[[NSUserDefaults standardUserDefaults] objectForKey: kM372FirmwareVersionFile4Key] stringByReplacingOccurrencesOfString:@"M328C" withString:@""] integerValue]];
            [string replaceOccurrencesOfString:@"#FIRMWARE4#" withString:firmwareOnWatch?:@"" options:NSCaseInsensitiveSearch range:[string rangeOfString:@"#FIRMWARE4#"]];
        }
    }
    
    bodyLbl.text = string;
}

- (void)wiggleComplete
{
    [indicationView stopAnimating];
    indicationView.hidden = YES;
    okBtn.hidden = NO;
}

- (void)watchDisconnected:(NSNotification *)notification {
    [HUD hide:true];
    syncView.hidden = YES;
    syncCover.hidden = YES;
    watchFrame = 0;
    animation = nil;
    [animation invalidate];
    
    [_timer invalidate];
    _timer = nil;
    
    if (!ismanuallyDisconnected) {
        [self removeAllAlerts];
        [self errorController];
    }
}

-(void)errorController
{
    _noWatchFounded = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Unable to Sync", nil)
                                                          message:NSLocalizedString(@"There was a problem when trying to connect to your watch. Please wait until your watch times out before you try again.", nil)
                                                   preferredStyle:UIAlertControllerStyleAlert];
    
    [_noWatchFounded addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                        style:UIAlertActionStyleCancel
                                                      handler:^(UIAlertAction * _Nonnull action)
                                {
                                    [self tickButtonTapped:nil];
                                }]];
    
    [_noWatchFounded addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Try Again", nil)
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * _Nonnull action)
                                {
                                    OTLog(@"clickedOnTryAgain");
                                    [HUD hide:true];
                                    indicationView.hidden = NO;
                                    [indicationView startAnimating];
                                    [self removeAllAlerts];
                                    watchProgress.hidden = YES;
                                    if (_unstickBootloader)
                                    {
                                        [self _connectToM328DeviceForFirmwareUpload];
                                    }
                                    else
                                    {
                                        UpdateFirmwareViewController *updateFirmwareVC=[[UpdateFirmwareViewController alloc] initWithNibName:@"UpdateFirmwareViewController" bundle:nil];
                                        updateFirmwareVC.neededUpdate = self.neededUpdate;
                                        updateFirmwareVC.openedByMenu = self.openedByMenu;
                                        updateFirmwareVC.unstickBootloader = self.unstickBootloader;
                                        updateFirmwareVC.retryUpdate = YES;
                                        [self.navigationController pushViewController:updateFirmwareVC animated:NO];
                                    }
                                }]];
    
    [_noWatchFounded addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Something Else is Wrong", nil)
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * _Nonnull action)
                                {
                                    OTLog(@"clickedOnSomethingWrong");
                                    [HUD hide:true];
                                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString: TIMEX_HELP_IQ_URL]];
                                }]];
    
    [self presentViewController:_noWatchFounded animated:YES completion:nil];
}
#pragma mark : Alertview delegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView == _mFirmwareUpdateAlert)
    {
        if (buttonIndex != _mFirmwareUpdateAlert.cancelButtonIndex)
        {
            //Keep the watch connected
            //ismanuallyDisconnected = YES;
            //[self endDeviceFileAccessSession];
            
            HUD = [[MBProgressHUD alloc] initWithView: self.navigationController.view];
            [self.navigationController.view addSubview: HUD];
            
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
                [[TCBlobDownloadManager sharedInstance] startDownloadWithURL:[NSURL URLWithString: downloadInfo.uri] customPath: newDir delegate: self];
            }
        }
        else {
            // Delete the information for firmware and move to next page.
            [self _DeleteDownloadedData];
            [self tickButtonTapped:nil];
        }
        
    }
    else if(alertView == _mFirmwareUpdateSuccessful ) {
        // Push to next view.
        [self tickButtonTapped:nil];
    }
    else if(alertView ==  _confirmationAlert) {
        //Edited by aruna
        [HUD hide:true];
        syncView.hidden = YES;
        syncCover.hidden = YES;
        watchFrame = 0;
        animation = nil;
        [animation invalidate];
        [self tickButtonTapped:nil];
        //End
        // Not sure if it is the 4th one or 5th one.
        //       [self.navigationController popToViewController:[self.navigationController.viewControllers objectAtIndex:4] animated:YES];
    } else if (alertView == noFirmwareUpdate) {
        [HUD hide:true];
        syncView.hidden = YES;
        syncCover.hidden = YES;
        watchFrame = 0;
        animation = nil;
        [animation invalidate];
    }
}


#pragma mark - Firmware upgrade methods
-(void) bootloaderModeForM328Requested:(NSNotification*)notification
{
    OTLog(@"Bootloader Command sent.... initiating 10 second wait period");
    [self performSelector:@selector(_connectToM328DeviceForFirmwareUpload) withObject:nil afterDelay: 10.0];
}


#pragma mark -
#pragma mark - BlobDownloadManager Delegate (Optional, your choice)

- (void)download:(TCBlobDownloader *)blobDownload
  didReceiveData:(uint64_t)receivedLength
         onTotal:(uint64_t)totalLength
        progress:(float)progress
{
    float progressStatus = (float)receivedLength / (float)totalLength;
    HUD.progress = progressStatus;
}

- (void)download:(TCBlobDownloader *)blobDownload didStopWithError:(NSError *)error
{
    [HUD hide: TRUE];
    syncView.hidden = YES;
    syncCover.hidden = YES;
    watchFrame = 0;
    animation = nil;
    [animation invalidate];
}

- (void)download:(TCBlobDownloader *)blobDownload
didFinishWithSuccess:(BOOL)downloadFinished
          atPath:(NSString *)pathToFile
{
    BOOL allDone = TRUE;
    
    NSString * downloadedURL = [[blobDownload downloadURL] absoluteString];
    
    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQ || [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)
    {
        for (TDM372FirmwareUpgradeInfo * downloadInfo in _mFirmwareUpgradeInfo)
        {
            if ([downloadInfo.uri isEqualToString: downloadedURL])
            {
                downloadInfo.downloaded = TRUE;
                downloadInfo.pathToDownloadedFile = blobDownload.pathToFile;
                break;
            }
        }
        for (TDM372FirmwareUpgradeInfo * downloadInfo in _mFirmwareUpgradeInfo)
        {
            if (downloadInfo.downloaded == FALSE)
            {
                allDone = FALSE;
                break;
            }
        }
        
        if (allDone)
        {
            [HUD hide: TRUE];
            syncView.hidden = YES;
            syncCover.hidden = YES;
            watchFrame = 0;
            animation = nil;
            [animation invalidate];
            
            //TODO: Need to handle bootloader stuck.
            if (m328StuckInBootloader)
            {
                m328StuckInBootloader = FALSE;
                [self _sendStuckBootloaderFiles];
            }
            else
            {
                [self removeAllAlerts];
                if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQ || [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)
                {
                    [self _connectToM328DeviceForFirmwareUpload]; // Try to connect to device.
                }
                else
                {
                    PeripheralDevice * timexDevice = [iDevicesUtil getConnectedTimexDevice];
                    if (timexDevice != nil)
                    {
                        [timexDevice requestDeviceChargeInfoForFirmware]; // Request for charge information.
                    }
                }
            }
        }
    }
}

- (void) _sendStuckBootloaderFiles {
    
    [self _sendPendingFirmWareFilesBootlaoder:YES];
}

#pragma mark - File utility methods
- (void)_DeleteDownloadedData
{
    for (TDM372FirmwareUpgradeInfo * downloadInfo in _mFirmwareUpgradeInfo)
    {
        if (downloadInfo.downloaded)
        {
            [[NSFileManager defaultManager] removeItemAtPath: downloadInfo.pathToDownloadedFile error: NULL];
        }
    }
    _mFirmwareUpgradeInfo = nil;
}



/**
 *  Dummy progress bar changer. Not to be used for live application.
 *
 *  @param sender <#sender description#>
 */
-(void)progressBarValueChanged:(NSTimer*)timer
{
    int filesLeft = 0;
    PeripheralDevice * timexDevice = (PeripheralDevice*)[timer userInfo];
    if (timexDevice)
    {
        if (_currentVal < 100) {
            _currentVal = timexDevice.firmwareProgress * 100;
            filesLeft = timexDevice.firmwareUpgradePendingFilesCount;
            
            [self.progressBar setValue:_currentVal];
        }
    }
    if (_currentVal >= 100)
    {
        [_timer invalidate];
        _timer = nil;
    }
    filesLeft = (firmwareFileTotal - filesLeft);
    fileLbl.text = [NSString stringWithFormat:NSLocalizedString(@"File %d of %d",nil),filesLeft,firmwareFileTotal];
}

- (IBAction)tickButtonTapped:(id)sender {
    [self removeAllAlerts];
    [HUD hide: TRUE];
    syncView.hidden = YES;
    syncCover.hidden = YES;
    watchFrame = 0;
    animation = nil;
    [animation invalidate];
    [NSObject cancelPreviousPerformRequestsWithTarget:self]; // ?? What does it do?
    
    if (self.openedByMenu && !m328FirmwareComplete)
    {
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
    else
    {
        if (_unstickBootloader)
        {
            UIAlertController *forgetWatch = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"\"Forget This Device\" from Bluetooth Settings", nil)
                                                                                 message:[NSString stringWithFormat:NSLocalizedString(@"%@ Then toggle Bluetooth off and back on to repair.", nil), NSLocalizedString(@"It seems like your watch is not fully paired with Guess Connect. You'll need to remove it from Bluetooth Settings to continue.", nil)]
                                                                          preferredStyle:UIAlertControllerStyleAlert];
            
            [forgetWatch addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                            style:UIAlertActionStyleCancel
                                                          handler:^(UIAlertAction * _Nonnull action)
                                    {
                                        SetupWatchViewController *setupWatch = [[SetupWatchViewController alloc] initWithNibName:@"SetupWatchViewController" bundle:nil];
                                        setupWatch.openedByMenu = self.openedByMenu;
                                        [self.navigationController pushViewController:setupWatch animated:YES];
                                    }]];
            
            [forgetWatch addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Settings", nil)
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * _Nonnull action)
                                    {
                                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
//                                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"App-Prefs:root=Bluetooth"]];
                                        SetupWatchViewController *setupWatch = [[SetupWatchViewController alloc] initWithNibName:@"SetupWatchViewController" bundle:nil];
                                        setupWatch.openedByMenu = self.openedByMenu;
                                        [self.navigationController pushViewController:setupWatch animated:YES];
                                    }]];
            
            [self presentViewController:forgetWatch animated:YES completion:nil];
        }
        else if(m328FirmwareComplete)
        {
            UIAlertController *forgetWatch = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Please Sync", nil)
                                                                                 message:NSLocalizedString(@"You will need to sync on the home screen before your watch can start tracking your activity.", nil)
                                                                          preferredStyle:UIAlertControllerStyleAlert];
            
            [forgetWatch addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                            style:UIAlertActionStyleCancel
                                                          handler:^(UIAlertAction * _Nonnull action)
                                    {
                                        CalibratingWatchViewController *calibVC;
                                        
                                        if (self.openedByMenu)
                                        {
                                            calibVC = [[CalibratingWatchViewController alloc] initWithNibName:@"CalibratingWatchViewController" bundle:nil doSettingsMenuCalibration:YES];
                                        } else {
                                            calibVC = [[CalibratingWatchViewController alloc] initWithNibName:@"CalibratingWatchViewController" bundle:nil doSettingsMenuCalibration:NO];
                                        }
                                        calibVC.openCalibration = YES;
                                        
                                        [self.navigationController pushViewController:calibVC animated:YES];
                                    }]];
            
            [self presentViewController:forgetWatch animated:YES completion:nil];
        }
        else
        {
            CalibratingWatchViewController *calibVC;
            
            if (self.openedByMenu)
            {
                calibVC = [[CalibratingWatchViewController alloc] initWithNibName:@"CalibratingWatchViewController" bundle:nil doSettingsMenuCalibration:YES];
            } else {
                calibVC = [[CalibratingWatchViewController alloc] initWithNibName:@"CalibratingWatchViewController" bundle:nil doSettingsMenuCalibration:NO];
            }
            
            [self.navigationController pushViewController:calibVC animated:YES];
        }
    }
}

- (void) AssignNewControllerToCenterController: (TDRootViewController *) newController
{
    UINavigationController *navigationController = self.navigationController;
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    NSArray *controllers = [NSArray arrayWithObject: newController];
    navigationController.viewControllers = controllers;
}

- (void)endDeviceFileAccessSession {
    PeripheralDevice *timexDevice =  [iDevicesUtil getConnectedTimexDevice];
    if(timexDevice){
        [timexDevice endFileAccessSession];
    }
}
- (void)removeAllAlerts {
    [_mFirmwareUpdateAlert dismissWithClickedButtonIndex:-1 animated:NO];
    [_mFirmwareInformationAlert dismissWithClickedButtonIndex:-1 animated:NO];
    [_noWatchFounded dismissViewControllerAnimated:NO completion:nil];
    [_confirmationAlert dismissWithClickedButtonIndex:-1 animated:NO];
    [_mFirmwareUpdateSuccessful dismissWithClickedButtonIndex:-1 animated:NO];
    [noFirmwareUpdate dismissWithClickedButtonIndex:-1 animated:NO];
}
@end
