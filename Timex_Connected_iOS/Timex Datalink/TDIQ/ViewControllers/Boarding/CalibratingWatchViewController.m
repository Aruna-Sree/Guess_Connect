//
//  CalibratingWatchViewController.m
//  Timex
//
//  Created by kpasupuleti on 5/4/16.
//

#import "CalibratingWatchViewController.h"
#import "AlignHandViewController.h"
#import "SetUpCompleteViewController.h"
#import "iDevicesUtil.h"
#import "TDDefines.h"
#import "CalibrateCell.h"
#import "TDAppDelegate.h"
#import "MFSideMenuContainerViewController.h"
#import "SideMenuViewController.h"
#import "CalibrationClass.h"
#import "TDDeviceManager.h"
#import "OTLogUtil.h"
#import "TDM328WatchSettingsUserDefaults.h"
#import "TDWatchProfile.h"
#import "MBProgressHUD.h"

@interface CalibratingWatchViewController () {
    
    NSInteger mReconnectAttempts;
    NSInteger calibrationFindingCount;
    MBProgressHUD *HUD;
    BOOL isSettingsMenuCalibration;
    NSTimer *animation;
    BOOL isCalibarted;
    int watchFrame;
    UIImageView *headerImg;
    int transition;
    NSTimer *transify;
    BOOL isConnected;
    UIAlertController *_noWatchFounded;
    BOOL startedSession;
    BOOL watchHandsReady;
    NSTimer *reconnection;
}

@end

@implementation CalibratingWatchViewController
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil doSettingsMenuCalibration:(BOOL)isFromSettings {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        isSettingsMenuCalibration = isFromSettings;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))  {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    if (isSettingsMenuCalibration && [[self.navigationController viewControllers] count] != 1) {
        UIButton *backBtn = [iDevicesUtil getBackButton];
        [backBtn addTarget:self action:@selector(backButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *barBtn = [[UIBarButtonItem alloc] initWithCustomView:backBtn];
        self.navigationItem.leftBarButtonItem = barBtn;
    }
    
    self.navigationItem.titleView = [iDevicesUtil getNavigationTitle];
    
    syncLbl.attributedText = [self getAttributedStrWithText:NSLocalizedString(@"Reconnect to align watch hands.",nil) formatStr:NSLocalizedString(@"\n\nPress and hold the Crown for about 5 seconds until you hear a 3 tone melody.",nil)];
    
    infoLabel.attributedText = [self getAttributedStrWithText:NSLocalizedString(@"Are your watch hands aligned?",nil) formatStr:NSLocalizedString(@"\n\nAre your watch's hands in the same position as the diagram below?\nIf not, tap \"Adjust Now\".",nil)];
    if (IS_IPAD) {
        infoLblTopConstraint.constant = 70;
        infoLblleftConstraint.constant = infoLblRightConstraint.constant = 60;
        infoLblRightConstraint.constant = 60;
    } else {
        infoLblleftConstraint.constant = infoLblRightConstraint.constant = 40;
        if (ScreenHeight <= 568) {
            infoLblleftConstraint.constant = infoLblRightConstraint.constant = 20;
        }
    }
    infoLblBottomContraint.constant = ((ScreenHeight)/2) - 70 - M328_REGISTRATION_BOTTOM_CONSTRAINT_MINUSVALUE;
    
    progressLbl.backgroundColor = UIColorFromRGB(AppColorRed);
    progressLblWidthContraint.constant = ScreenWidth * ([iDevicesUtil getProgressBarValueBasedOnRegistrationEnum:callibrateWatch]);
    
    headerImg = [[UIImageView alloc] initWithFrame:CGRectMake((ScreenWidth - M328_SUB_DIAL_DISTANCE_WIDTH)/2, 0, M328_SUB_DIAL_DISTANCE_WIDTH, M328_SUB_DIAL_DISTANCE_HEIGHT)];
    [headerImg setImage:[UIImage imageNamed:@"CalibrateWatch"]];
    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)
    {
        [headerImg setImage:[UIImage imageNamed:@"TravelCalibrate"]];
        watchSetup.image = [UIImage imageNamed:@"TravelSetup"];
    }
    headerImg.contentMode = UIViewContentModeScaleAspectFit;
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, M328_SUB_DIAL_DISTANCE_HEIGHT)];
    [headerView addSubview:headerImg];
    
    indicatorTopConstraint.constant =  indicatorTopConstraint.constant + M328_SUB_DIAL_DISTANCE_HEIGHT + 17.0 ;
    activityIndicator.hidden = true;

    calibrateTableView.tableHeaderView = headerView;
    calibrateTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 1)];
    
    [progressLbl setHidden:(isSettingsMenuCalibration) ? YES : NO];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        watchHandsReady = YES;
    });
    
    // Watch animation
    watchFrame = 0;
    animation = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(watchAnimation) userInfo:nil repeats:YES];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    TDAppDelegate *appdel = (TDAppDelegate *)[[UIApplication sharedApplication] delegate];
    appdel.customTabbar.autoSyncAllowed = NO;
    isCalibarted = NO;
    
    [reconnection invalidate];
    
    if (_openCalibration)
    {
        [self clickedOnCalibrateNow];
    }
    else if (!isSettingsMenuCalibration)
    {
        [[CalibrationClass sharedInstance] enterCalibrationMode];
        
        isCalibarted = YES;
    }
    self.navigationItem.hidesBackButton = YES;
    
    if (isSettingsMenuCalibration && isCalibarted)
    {
        [[CalibrationClass sharedInstance] exitCalibrationMode];
    }
    
    [self addNotifications];
    
    calibrateTableView.hidden = YES;
    double delayInSeconds = 4.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        calibrateTableView.hidden = NO;
    });
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

-(void) fadeOut
{
    headerImg.alpha = transition;
    if (transition == 0)
        [transify invalidate];
    transition--;
}

-(void) fadeIn
{
    headerImg.alpha = transition;
    if (transition == 100)
        [transify invalidate];
    transition++;
}

-(void) backButtonTapped
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (NSAttributedString *)getAttributedStrWithText:(NSString *)textStr formatStr:(NSString *)formatStr {
    
    UIFont *textFont = [UIFont fontWithName:[iDevicesUtil getAppWideMediumFontName] size:M328_REGISTRATION_TITLE_FONTSIZE];
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:textFont, NSFontAttributeName, [UIColor blackColor],NSForegroundColorAttributeName, nil];
    NSMutableAttributedString *textAtrStr = [[NSMutableAttributedString alloc] initWithString:textStr attributes:dict];
    
    UIFont *formatFont = [UIFont fontWithName: [iDevicesUtil getAppWideFontName] size:M328_REGISTRATION_INFO_FONTSIZE];
    NSDictionary *atrsDict = [NSDictionary dictionaryWithObjectsAndKeys:formatFont, NSFontAttributeName, UIColorFromRGB(COLOR_DEFAULT_TIMEX_FONT),NSForegroundColorAttributeName, nil];
    NSMutableAttributedString *formatAtrStr = [[NSMutableAttributedString alloc] initWithString:formatStr attributes:atrsDict];
    
    
    NSString *searchstring = @"\"Adjust Now\"";
    NSRange foundRange = [formatStr rangeOfString:searchstring];
    if (foundRange.length > 0) {
        UIFont *font = [UIFont fontWithName: [iDevicesUtil getAppWideMediumFontName] size:M328_REGISTRATION_INFO_FONTSIZE];
        NSDictionary *higDict = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, UIColorFromRGB(AppColorRed),NSForegroundColorAttributeName, nil];
        [formatAtrStr addAttributes:higDict range:foundRange];
    }
    
    [textAtrStr appendAttributedString:formatAtrStr];
    
    return textAtrStr;
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [animation invalidate];
    [reconnection invalidate];
    reconnection = nil;
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    [self removeNotifications];
    
    TDAppDelegate *appdel = (TDAppDelegate *)[[UIApplication sharedApplication] delegate];
    appdel.customTabbar.autoSyncAllowed = YES;
}

- (void)didReceiveMemoryWarning {
     OTLog([NSString stringWithFormat:@"Recived Memory Warning  in %@ ",NSStringFromClass([self class])]);
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(void)clickedOnCalibrateNow {
    BLEManager *bleManager = [[TDDeviceManager sharedInstance] getBleManager];
    if ([bleManager isBLESupported] && [bleManager isBLEAvailable]) {
        NSString * deviceUUID = [[NSUserDefaults standardUserDefaults] objectForKey: kCONNECTED_DEVICE_UUID_PREF_NAME];
        NSArray * adverts = [[TDDeviceManager sharedInstance] getAllConnectedAndAdvertisingDevices];
        NSUInteger idx = NSNotFound;
        idx = [adverts indexOfObjectPassingTest:
               ^ BOOL (PeripheralDevice* device, NSUInteger idx, BOOL *stop)
               {
                   return [device.peripheral.UUID.UUIDString isEqualToString: deviceUUID];
               }];
        
        if (idx != NSNotFound) {
            if (!_openCalibration && !isSettingsMenuCalibration)
            {
                [self openAlignHandVC];
            }
            else
            {
                [self startCalibrationAction];
            }
        } else {
            [self startCalibrationAction];
//            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Calibrate your watch" message:@"Press and hold the crown to put your watch into communications mode." delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
//            [alert show];
        }
    } else {
        NSString * title = NSLocalizedString(@"Bluetooth unavailable", nil);
        NSString * msg = nil;
        if (![bleManager isBLESupported]) {
            msg = NSLocalizedString(@"Bluetooth is not available on this device.", nil);
        } else if (![bleManager isBLEAvailable]) {
            msg = NSLocalizedString(@"Bluetooth is powered off. Please turn on Bluetooth in System Settings before proceeding.", nil);
        }
        
        UIAlertView *message = [[UIAlertView alloc] initWithTitle: title
                                                          message: msg
                                                         delegate: nil
                                                cancelButtonTitle: NSLocalizedString(@"OK", nil)
                                                otherButtonTitles: nil];
        [message show];
    }
}

- (void)startCalibrationAction {
    //[self showLoadingView];
    [self reconnectToDevice];
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"OK",nil)]) {
        [self startCalibrationAction];
    }
}

- (void)openAlignHandVC {
    AlignHandViewController *alignMinHand = [[AlignHandViewController alloc] initWithNibName:@"AlignHandViewController" bundle:nil  viewType:Hand_Hour];
    if(isSettingsMenuCalibration == YES){
        alignMinHand.isFromSetup = NO;
    }
    else{
        alignMinHand.isFromSetup = YES;
    }
    
    [self.navigationController pushViewController:alignMinHand animated:YES];
}

- (void)showLoadingView {
    [activityIndicator startAnimating];
    activityIndicator.hidden = false;
    [calibrateTableView reloadData];
    infoLabel.attributedText = [self getAttributedStrWithText:NSLocalizedString(@"Set up your watch.",nil)
                                             mediumFormatText:NSLocalizedString(@"Crown",nil)
                                            mediumFormatText2:NSLocalizedString(@"3 tone melody",nil)
                                                    formatStr:NSLocalizedString(@"\n\nTo connect your watch with the phone, press and hold the Crown for about 5 seconds until you hear a 3 tone melody. Then select your watch below.",nil)];
}

- (NSAttributedString *)getAttributedStrWithText:(NSString *)textStr mediumFormatText:(NSString *)mediumFormatStr mediumFormatText2:(NSString *)mediumFormatStr2 formatStr:(NSString *)formatStr
{
    UIFont *textFont = [UIFont fontWithName:[iDevicesUtil getAppWideMediumFontName] size:M328_REGISTRATION_TITLE_FONTSIZE];
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:textFont, NSFontAttributeName, [UIColor blackColor],NSForegroundColorAttributeName, nil];
    NSMutableAttributedString *textAtrStr = [[NSMutableAttributedString alloc] initWithString:textStr attributes:dict];
    
    UIFont *formatFont = [UIFont fontWithName: [iDevicesUtil getAppWideFontName] size:M328_REGISTRATION_BIG_TITLE_FONTSIZE];
    NSDictionary *atrsDict = [NSDictionary dictionaryWithObjectsAndKeys:formatFont, NSFontAttributeName, UIColorFromRGB(COLOR_DEFAULT_TIMEX_FONT),NSForegroundColorAttributeName, nil];
    NSMutableAttributedString *formatAtrStr = [[NSMutableAttributedString alloc] initWithString:formatStr attributes:atrsDict];
    [textAtrStr appendAttributedString:formatAtrStr];
    
    UIFont *mediumFont = [UIFont fontWithName:[iDevicesUtil getAppWideMediumFontName] size:M328_REGISTRATION_BIG_TITLE_FONTSIZE];
    NSDictionary *dict2 = [NSDictionary dictionaryWithObjectsAndKeys:mediumFont, NSFontAttributeName, [UIColor blackColor],NSForegroundColorAttributeName, nil];
    NSRange formatStrRange = [textStr rangeOfString:mediumFormatStr];
    [formatAtrStr setAttributes:dict2 range:formatStrRange];
    NSRange formatStrRange2 = [textStr rangeOfString:mediumFormatStr2];
    [formatAtrStr setAttributes:dict2 range:formatStrRange2];
    
    return formatAtrStr;
}

-(void)addNotifications {
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(successfullyConnectedToDevice:) name: kPeripheralDeviceTimexDatalinkPrimaryCharacteristicDiscovered object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(watchDisconnected:) name:kDeviceManagerDeviceLostConnectiondNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(watchDisconnected:) name:kPeripheralDeviceAuthorizationFailedNotification object: nil];
    
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(undiscoveredPeripheral:) name:kBLEManagerUndiscoveredPeripheralNotification object:nil];
    
}

-(void)removeNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kPeripheralDeviceTimexDatalinkPrimaryCharacteristicDiscovered object: nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kDeviceManagerDeviceLostConnectiondNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kPeripheralDeviceAuthorizationFailedNotification object: nil];
    
    //[[NSNotificationCenter defaultCenter] removeObserver: self name: kBLEManagerUndiscoveredPeripheralNotification object:nil];
    
}

- (void)reconnectToDevice
{
    //first, we need to CONNECT to the device again... and not just A device, but THE device
    NSString * deviceUUID = [[NSUserDefaults standardUserDefaults] objectForKey: kCONNECTED_DEVICE_UUID_PREF_NAME];
    if (deviceUUID != nil && !isConnected)
    {
        syncView.hidden = NO;
        syncCover.hidden = NO;
        syncViewActivityIndicator.hidden = false;
        [syncViewActivityIndicator startAnimating];
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
                [reconnection invalidate];
                reconnection = nil;
                reconnection = [NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(errorController) userInfo:nil repeats:NO];
            }
        }
        else
        {
            mReconnectAttempts++;
            if (mReconnectAttempts > 300)
            {
                mReconnectAttempts = 0;
                
                syncView.hidden = YES;
                syncCover.hidden = YES;
                syncViewActivityIndicator.hidden = true;
                [syncViewActivityIndicator stopAnimating];
                [self calibrationFailed:NSLocalizedString(@"Failed to connect to device",nil)];
            }
            else
            {
                OTLog(@"Attempting to reconnect...");
                [reconnection invalidate];
                reconnection = nil;
                reconnection = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(reconnectToDevice) userInfo:nil repeats:NO];
//                [self performSelector:@selector(reconnectToDevice) withObject:nil afterDelay: 1.0];
            }
        }
    }
}

-(void) successfullyConnectedToDevice:(NSNotification*)notification
{
    // May be remove device detection stuff.
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kPeripheralDeviceTimexDatalinkPrimaryCharacteristicDiscovered object: nil];
    
    OTLog(@"successfully connected to device");
    
    [reconnection invalidate];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(watchDisconnected:) name:kDeviceManagerDeviceLostConnectiondNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(watchDisconnected:) name:kPeripheralDeviceAuthorizationFailedNotification object: nil];
    isConnected = YES;
    calibrationFindingCount = 0;
    if (!isSettingsMenuCalibration && _openCalibration)
    {
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(didStartFileAccessSession:) name:kTDM328SessionStartNotification object:nil];
        PeripheralDevice * timexDevice = [iDevicesUtil getConnectedTimexDevice];
        if(timexDevice)
        {
            [timexDevice startFileAccessSession];
            int delayInSeconds = 1;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                if (!startedSession)
                {
                    [timexDevice startFileAccessSession];
                }
            });
        }
    }
    else
    {
        [self findCalibrationCharacteristic];
    }
}

- (void)watchDisconnected:(NSNotification *)notification {
    [HUD hide:true];
    syncView.hidden = YES;
    syncCover.hidden = YES;
    syncViewActivityIndicator.hidden = true;
    [syncViewActivityIndicator stopAnimating];
    syncViewActivityIndicator.hidden = true;
    [syncViewActivityIndicator stopAnimating];
    watchFrame = 0;
    animation = nil;
    startedSession = NO;
    isConnected = NO;
    [animation invalidate];
    [self errorController];
}

-(void)errorController
{
    [reconnection invalidate];
    _noWatchFounded = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Unable to Sync", nil)
                                                          message:NSLocalizedString(@"There was a problem when trying to connect to your watch.", nil)
                                                   preferredStyle:UIAlertControllerStyleAlert];
    
    [_noWatchFounded addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Try Again", nil)
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * _Nonnull action)
                                {
                                    OTLog(@"clickedOnTryAgain");
                                    [HUD hide:true];
                                    [self reconnectToDevice];
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

-(void)exitSyncModeManually

{
    // Logic here is to start and end the session if not present.
    // This will disconnect the watch.
    // Observe for notification on start of session
    
    NSLog(@"exitSyncModeManually");
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(didStartFileAccessSession:) name:kTDM328SessionStartNotification object:nil];
    
    PeripheralDevice * timexDevice = [iDevicesUtil getConnectedTimexDevice];
    if(timexDevice)
    {
        [timexDevice startFileAccessSession];
    }
}

-(void)didStartFileAccessSession:(NSNotification*)notification
{
    [[NSNotificationCenter defaultCenter]removeObserver:self name:kTDM328SessionStartNotification object:nil];
    if (!startedSession)
    {
        OTLog(@"didStartFileAccessSession");
        startedSession = YES;
        [self findCalibrationCharacteristic];
    }
    else
    {
        [self endFileAccessSession];
    }
}

-(void)endFileAccessSession
{
    OTLog(@"endFileAccessSession");
    PeripheralDevice * timexDevice = [iDevicesUtil getConnectedTimexDevice];
    [timexDevice endFileAccessSession];
}

-(void)undiscoveredPeripheral:(NSNotification*)notification
{
    OTLog(@"device undiscovered");
    
    [self calibrationFailed:NSLocalizedString(@"Failed to connect to device", nil)];
}

-(void)findCalibrationCharacteristic
{
    OTLog(@"finding calibration characteristics");
    PeripheralDevice *peripheralDevice = [iDevicesUtil getConnectedTimexDevice];
    BLEPeripheral *blePeripheral = (BLEPeripheral *)peripheralDevice.peripheral;
    
    if(calibrationFindingCount < 10)
    {
        ServiceProxy* service = [blePeripheral findService: [PeripheralDevice timexDatalinkServiceId]];
        BLECharacteristic* timexChar = (BLECharacteristic *)[service findCharacteristic: [CBUUID UUIDWithString:TDLS_DATA_IN_UUID1]];
        
        CBCharacteristic *characteristic = [timexChar cbCharacteristic];
        
        if(characteristic != nil)
        {
            OTLog(@"found calibration characteristic");
            if (_openCalibration) {
                [self enterCalibrationMode];
            }
            else
            {
                [[CalibrationClass sharedInstance] enterCalibrationMode];
                isCalibarted = YES; // to figure out if its already in calibratioin mode.
                
                syncView.hidden = YES;
                syncCover.hidden = YES;
            }
            
            return;
        }
        calibrationFindingCount++;
        
        [self performSelector:@selector(findCalibrationCharacteristic) withObject:nil afterDelay:1.0];
    }
    else
    {
        OTLog(@"Could not find calibration characteristics");
        [self calibrationFailed:NSLocalizedString(@"Could not find calibration characteristics",nil)];
    }
}

-(void)enterCalibrationMode
{
     OTLog(@"enterCalibrationMode");
    [self removeNotifications];
    
    [[CalibrationClass sharedInstance] enterCalibrationMode];
    
    [HUD hide: YES];
    
    isCalibarted = YES; // to figure out if its already in calibratioin mode.
    
    [self openAlignHandVC];
}

- (void)calibrationFailed:(NSString *)message
{
    [self removeNotifications];
    syncView.hidden = YES;
    syncCover.hidden = YES;
    [HUD hide: YES];
    [activityIndicator stopAnimating];
    activityIndicator.hidden = true;
    [calibrateTableView reloadData];
    
    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Guess Connect",nil) message:message delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil] show];
    
    OTLog(@"%@", message);
    OTLog(@"calibration failed");
    
}

-(void)clickedOnSkip
{
    if (watchHandsReady)
    {
        [self removeNotifications];
        OTLog(@"Calibration skipped");
        [[CalibrationClass sharedInstance] exitCalibrationMode];
        NSLog(@"Calibration exited");
        calibrateTableView.userInteractionEnabled = NO;
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[iDevicesUtil getConnectedTimexDevice] endFileAccessSession];
        });
        
        double delayInSeconds = 2.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            //code to be executed on the main queue after delay
            startedSession = YES;
            [self exitSyncModeManually];
            
            ((MFSideMenuContainerViewController *)(TDAppDelegate *)[[UIApplication sharedApplication] delegate].window.rootViewController).panMode = MFSideMenuPanModeDefault;
            
            [self continueAfterWatchExitSyncMode];
        });
    }
}

-(void)continueAfterWatchExitSyncMode
{
    if([iDevicesUtil getConnectedTimexDevice])
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self continueAfterWatchExitSyncMode];
        });
    }
    else
    {
        SetUpCompleteViewController *setUpComplete=[[SetUpCompleteViewController alloc] initWithNibName:@"SetUpCompleteViewController" bundle:nil skippedCalibration:YES];
        [self.navigationController pushViewController:setUpComplete animated:YES];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (_openCalibration)
    {
        return 1;
    }
    return 2;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    CalibrateCell * cell = NULL;
    
    cell = (CalibrateCell *)[tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell)
    {
        [tableView registerNib:[UINib nibWithNibName:@"CalibrateCell" bundle:nil] forCellReuseIdentifier:@"cell"];
        cell = (CalibrateCell *)[tableView dequeueReusableCellWithIdentifier:@"cell"];
    }
    
    cell.separatorInset = UIEdgeInsetsZero;
    cell.layoutMargins = UIEdgeInsetsZero;
    cell.selectionStyle = UITableViewCellSelectionStyleGray;


    cell.calibrateLbl.hidden = YES;
    cell.skipBtn.hidden = YES;
    
    if(!activityIndicator.isHidden){
        return cell;
    }
    
    if (indexPath.row == 0)
    {
        cell.calibrateLbl.hidden = NO;
    }
    
    else if(indexPath.row == 1 && !isSettingsMenuCalibration)
    {
        cell.skipBtn.hidden = NO;
    }
    
    
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.row == 0)
    {
        [self clickedOnCalibrateNow];
    }
    else if(indexPath.row == 1 && !isSettingsMenuCalibration)
    {
        [self clickedOnSkip];
    }
}

-(void)showSlideMenuIcon
{
    UIBarButtonItem *slideMenuItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"menu"] style:UIBarButtonItemStylePlain target:self action:@selector(slideMenuTapped)];
    self.navigationItem.leftBarButtonItem = slideMenuItem;    
    self.navigationItem.titleView = [iDevicesUtil getNavigationTitle];
}

-(void)slideMenuTapped {
    TDAppDelegate * delegate = (TDAppDelegate *)[UIApplication sharedApplication].delegate;
    SideMenuViewController *leftController = (SideMenuViewController *)((MFSideMenuContainerViewController *)delegate.window.rootViewController).leftMenuViewController;
    if (leftController == nil)
    {
        SideMenuViewController *leftController = [[SideMenuViewController alloc] init];
        ((MFSideMenuContainerViewController *)delegate.window.rootViewController).leftMenuViewController = leftController;
    }
}

@end
