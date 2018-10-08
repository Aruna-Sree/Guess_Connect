//
//  SetupWatchViewController.m
//  Timex
//
//  Created by avemulakonda on 5/4/16.
//

#import "SetupWatchViewController.h"
#import "UpdateFirmwareViewController.h"
#import "TDDefines.h"
#import "iDevicesUtil.h"
#import "UIImage+Tint.h"
#import "TDDeviceManager.h"
#import "TDWatchProfile.h"
#import "PCCommWhosThere.h"
#import "TDM372WatchActivity.h"
#import "SynWatchIQMoveViewController.h"
#import "TDAppDelegate.h"
#import "BLEManager.h"
#import "OTLogUtil.h"
#define TIMEOUT_SECONDS 12

@interface SetupWatchViewController () {
   // NSInteger numberOfRows;
    NSMutableArray *devicesArray;
    NSTimer  *timeoutTimer;
    NSObject *WatchAsAnObject;
    MBProgressHUD           * HUD;
    NSTimer *searchingTimeoutTimer;
    BLEManager *bleManager;
    BOOL isAlertShowedAlready;
    UIAlertView *alert;
    NSTimer *animation;
    int watchFrame;
    int transition;
    NSTimer *transify;
    BOOL dontCheck;
    NSTimer *scanningTimer;
    BOOL isSyncInProgress;
}

@end

@implementation SetupWatchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))  {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    self.navigationItem.titleView = [iDevicesUtil getNavigationTitle];

    infoLabel.attributedText = [self getAttributedStrWithText:NSLocalizedString(@"Set up your watch",nil)
                                             mediumFormatText:NSLocalizedString(@"Crown",nil)
                                            mediumFormatText2:NSLocalizedString(@"3 tone melody",nil)
                                                    formatStr:NSLocalizedString(@"\nTo connect your watch with the phone, press and hold the Crown for about 5 seconds until you hear a 3 tone melody and the hands move together.",nil)];
    
    if (IS_IPAD) {
        infoLblTopConstraint.constant = 70;
        infoLblleftConstraint.constant = infoLblRightConstraint.constant = 60;
    } else {
        infoLblleftConstraint.constant = infoLblRightConstraint.constant = 40;
        if (ScreenHeight <= 568) {
            infoLblleftConstraint.constant = infoLblRightConstraint.constant = 20;
        }
    }
    infoLblBottomContraint.constant = ((ScreenHeight)/2) - 70 - M328_REGISTRATION_BOTTOM_CONSTRAINT_MINUSVALUE;
    
    progressLbl.backgroundColor = UIColorFromRGB(AppColorRed);
    progressLblWidthContraint.constant = ScreenWidth * ([iDevicesUtil getProgressBarValueBasedOnRegistrationEnum:setupWatch]);
    
    [activityIndicator startAnimating];
    
    indicatorTopConstraint.constant =  indicatorTopConstraint.constant + M328_SUB_DIAL_DISTANCE_HEIGHT + 17.0 ;
    
    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)
    {
        watchSetup.image = [UIImage imageNamed:@"TravelSetup"];
    }
    
    UIButton *backBtn = [iDevicesUtil getBackButton];
    [backBtn addTarget:self action:@selector(backButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barBtn = [[UIBarButtonItem alloc] initWithCustomView:backBtn];
    self.navigationItem.leftBarButtonItem = barBtn;
    
    watchListTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

-(void) backButtonTapped
{
    [self.navigationController popViewControllerAnimated:YES];
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

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults removeObjectForKey: kCONNECTED_DEVICE_UUID_PREF_NAME];
    
    [self restartScanning];
    self.navigationItem.hidesBackButton = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(deviceListChanged:) name: kDeviceManagerAdvertisingDevicesChangedNotification object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(deviceListChanged:) name: kDeviceManagerConnectedDevicesChangedNotification object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(lostPeriPheralConnection:) name: kPeripheralDeviceAuthorizationFailedNotification object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(lostPeriPheralConnection:) name: kDeviceManagerDeviceLostConnectiondNotification object: nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(WatchInfoRead:) name: kTDWatchInfoReadSuccessfullyNotification object: nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(WatchInfoReadFailed:) name: kTDWatchInfoReadUnsuccessfullyNotification object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_bleManagerStateChanged:) name:kBLEManagerStateChanged object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(unexpectedBootloaderModeForM372DetectedAndApproved:) name: kTDM372UnexpectedBootloaderModeDetectedAndApproved object: nil];
    [self startSearchTimer];
    
    bleManager = [[TDDeviceManager sharedInstance] getBleManager];
    if(![bleManager isBLEAvailable])
    {
        [self showBluetoothNonAvailabilityAlert];
    }
    isAlertShowedAlready = FALSE;
    
    // Watch animation
    watchFrame = 0;
    //animation = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(watchAnimation) userInfo:nil repeats:YES];
    
    [self deviceListChanged:nil];
    
    isSyncInProgress = NO;
    [self startScanningTimer];
    TDAppDelegate *appdel = (TDAppDelegate *)[[UIApplication sharedApplication] delegate];
    appdel.customTabbar.autoSyncAllowed = NO;
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
    watchSetup.alpha = transition;
    if (transition == 0)
        [transify invalidate];
    transition--;
}

-(void) fadeIn
{
    watchSetup.alpha = transition;
    if (transition == 100)
        [transify invalidate];
    transition++;
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kDeviceManagerAdvertisingDevicesChangedNotification object: nil];
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kDeviceManagerConnectedDevicesChangedNotification object: nil];
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kPeripheralDeviceTimexDatalinkPrimaryCharacteristicDiscovered object: nil];
    [[NSNotificationCenter defaultCenter] removeObserver: self name:kTDWatchInfoReadSuccessfullyNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver: self name:kTDWatchInfoReadUnsuccessfullyNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver: self name:kPeripheralDeviceAuthorizationFailedNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver: self name:kBLEManagerStateChanged object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver: self name:kDeviceManagerDeviceLostConnectiondNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:kTDM372UnexpectedBootloaderModeDetectedAndApproved object:nil];
    devicesArray = [[NSMutableArray alloc] init];
    
    [self stopSearchTimer];
    
    [self checkAndInvalidateTimeout];
    
    [animation invalidate];
    
    [self stopScanningTimer];
    TDAppDelegate *appdel = (TDAppDelegate *)[[UIApplication sharedApplication] delegate];
    appdel.customTabbar.autoSyncAllowed = YES;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)startScanningTimer
{
    if (scanningTimer == nil || ![scanningTimer isValid])
    {
        scanningTimer = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(restartScanning) userInfo:nil repeats:YES];
        NSLog(@"scanning timer started");
    }
}

-(void)stopScanningTimer
{
    NSLog(@"scanning timer stoped");
    [scanningTimer invalidate];
    scanningTimer = nil;
}

-(void)restartScanning
{
    if (!isSyncInProgress)
    {
        [[TDDeviceManager sharedInstance] restartScan];
    }
}

-(void)startSearchTimer
{
    if (searchingTimeoutTimer == nil || ![searchingTimeoutTimer isValid])
    {
        searchingTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval:2*60 target: self selector:@selector(searchTimeout:) userInfo: nil repeats: YES];
    }
}

-(void)stopSearchTimer
{
    [searchingTimeoutTimer invalidate];
}

-(void)searchTimeout:(NSTimer*)timer
{
    if (!alert.visible)
    {
        alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Guess Connect",nil)
                                           message:NSLocalizedString(@"Devices not found",nil)
                                          delegate:nil
                                 cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                 otherButtonTitles:nil];
        [alert show];
    }
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
    if (!bleManager.isBLEAvailable && !dontCheck)
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
    else
    {
        dontCheck = NO;
    }
}


#pragma mark table view datasource
-(void) deviceListChanged:(NSNotification*)notification
{
    NSArray* newList = [NSArray arrayWithArray:[TDDeviceManager sharedInstance].advertisingDevices];
    // Filtered devices which are only iQ+ watches.
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
    // Filter by only iQ+ watches.
//    devicesArray = [devicesArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.name contains[c] 'iQMV'"]];
    
    [watchListTableView reloadData];
    
    if ([devicesArray count] > 0)
    {
        infoLabel.attributedText = [self getAttributedStrWithText:NSLocalizedString(@"Select your watch",nil)
                                                 mediumFormatText:NSLocalizedString(@"",nil)
                                                mediumFormatText2:NSLocalizedString(@"",nil)
                                                        formatStr:NSLocalizedString(@"\n\nOnce it's found, select your watch below and accept the pairing request.",nil)];
        watchListTableView.hidden = NO;
        [self stopSearchTimer];
    }
    else if([devicesArray count] == 0)
    {
        infoLabel.attributedText = [self getAttributedStrWithText:NSLocalizedString(@"Set up your watch",nil)
                                                 mediumFormatText:NSLocalizedString(@"Crown",nil)
                                                mediumFormatText2:NSLocalizedString(@"3 tone melody",nil)
                                                        formatStr:NSLocalizedString(@"\n\nTo connect your watch with the phone, press and hold the Crown for about 5 seconds until you hear a 3 tone melody and the hands move together.",nil)];
        
        watchListTableView.hidden = YES;
        [animation invalidate];
        animation = nil;
        animation = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(watchAnimation) userInfo:nil repeats:YES];
        [self startSearchTimer];
    }

}
-(void)lostPeriPheralConnection:(NSNotification*)notification {
    [self watchConnectionTimeout:nil];
    [alert dismissWithClickedButtonIndex:0 animated:NO];
    [HUD hide:YES];
    [self tryAgain];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return devicesArray.count;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return ONBOARDING_PAIR_WATCH_CELL_HEIGHT;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    OTLog(@"cellForRowAtIndexPath");
    NSLog(@"Devices list array :%@",devicesArray);
    if (!(devicesArray.count > 0)) {
        [self deviceListChanged:nil];
        [activityIndicator startAnimating];
        activityIndicator.hidden = false ;
    }
    else{
        [activityIndicator stopAnimating];
        activityIndicator.hidden = true ;
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellid"];
    if (!cell) {
        cell = [(UITableViewCell *)[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cellid"];
    }
    
    PeripheralDevice * currentDevice = [devicesArray objectAtIndex: indexPath.row];
    
    [cell.imageView setImage:[[UIImage imageNamed: @"FoundWatch"] imageWithTint: UIColorFromRGB(AppColorRed)]];
    cell.textLabel.font = [UIFont fontWithName: [iDevicesUtil getAppWideFontName] size:M328_REGISTRATION_INFO_FONTSIZE];
    cell.textLabel.textColor = [UIColor darkGrayColor];
    
    if (currentDevice.name != nil) {
        cell.textLabel.text = [NSString stringWithFormat:@"Guess iQ+   %@", currentDevice.name];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
    return cell;
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    isAlertShowedAlready = FALSE;
    if ( indexPath.row < devicesArray.count )
    {
        PeripheralDevice * device = [devicesArray objectAtIndex: indexPath.row];
        
        if (device != NULL)
        {
            //TestLog_DoNotLetConectOtherKindOfWatch
            if ([self correctWatchSelected: device] == FALSE)
            {
                TDAppDelegate *delegate = (TDAppDelegate *)[[UIApplication sharedApplication] delegate];
                [delegate showAlertWithTitle:NSLocalizedString(@"Error",nil) Message:NSLocalizedString(@"The type of this device doesn't match the watch style you have selected at the beginning of Setup. Please select another device to connect.", NSLocalizedString(@"Modification Date: 11/25/2015",nil)) andButtonTitle:NSLocalizedString(@"Ok",nil)];
                return;
            }
            
            isSyncInProgress = YES;
            
            [[NSNotificationCenter defaultCenter] removeObserver: self name: kDeviceManagerAdvertisingDevicesChangedNotification object: nil];
            [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(successfullyConnectedToDevice:) name: kPeripheralDeviceTimexDatalinkPrimaryCharacteristicDiscovered object: nil];

            WatchAsAnObject = device;
            
            CBUUID* uID = device.peripheral.UUID;
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            [userDefaults setObject: uID.UUIDString forKey: kCONNECTED_DEVICE_UUID_PREF_NAME];
            [userDefaults setObject: device.name forKey:@"kCONNECTED_DEVICE_PREF_NAME"];

            if (device.deviceState == kTDDeviceState_NotConnected) {
                HUD = [[MBProgressHUD alloc] initWithView: self.navigationController.view];
                [self.navigationController.view addSubview: HUD];
                
                HUD.delegate = self;
                HUD.labelText = NSLocalizedString(@"Please Wait", nil);
                HUD.detailsLabelText = [NSString stringWithFormat: NSLocalizedString(@"Connecting to %@", nil), device.name == nil ? NSLocalizedString(@"Timex Watch", nil) : device.name];
                HUD.square = YES;
                
                timeoutTimer = [NSTimer scheduledTimerWithTimeInterval: TIMEOUT_SECONDS target: self selector:@selector(watchConnectionTimeout:) userInfo: nil repeats: NO];
                
                [HUD show:YES];
                
                [[TDDeviceManager sharedInstance] connect: device];
            } else {
                HUD = [[MBProgressHUD alloc] initWithView: self.navigationController.view];
                [self.navigationController.view addSubview: HUD];
                
                HUD.delegate = self;
                HUD.labelText = NSLocalizedString(@"Please Wait", nil);
                HUD.detailsLabelText = NSLocalizedString(@"Reading Device Info...", nil);
                HUD.square = YES;
                
                [HUD show:YES];
                
                [self performSelector:@selector(ReadDeviceWhoIs) withObject:nil afterDelay: 1];
            }
        }
    }
}

#pragma mark Utilities

/**
 *  Invalidates the initial time out timer. 
 * Used multiple times. Hence put up at single place.
 */
-(void)checkAndInvalidateTimeout{
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kPeripheralDeviceTimexDatalinkPrimaryCharacteristicDiscovered object: nil];
    if(timeoutTimer && timeoutTimer.isValid){
        [timeoutTimer invalidate];
        timeoutTimer = nil;
    }
}


- (BOOL) correctWatchSelected: (PeripheralDevice *) selectedDevice
{
    BOOL watchMatchesSelection = TRUE;
    
    NSString * nameOfDevice = selectedDevice.name;
    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel &&
        !([nameOfDevice rangeOfString: @"iQTR" options: NSCaseInsensitiveSearch].length > 0 ))
        watchMatchesSelection = FALSE;
    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQ &&
        !([nameOfDevice rangeOfString: @"iQMV" options: NSCaseInsensitiveSearch].length > 0 ))
        watchMatchesSelection = FALSE;
    
    if (nameOfDevice == nil)
    {
        watchMatchesSelection = FALSE;
    }
    
    return watchMatchesSelection;
}

- (void) ReadDeviceWhoIs
{
    [self checkAndInvalidateTimeout];
    timeoutTimer = [NSTimer scheduledTimerWithTimeInterval: TIMEOUT_SECONDS target: self selector:@selector(watchConnectionTimeout:) userInfo: nil repeats: NO];
    
    PeripheralDevice * timexDevice = [iDevicesUtil getConnectedTimexDevice];
    if (timexDevice != nil && ![self checkAlerViewShowingOrNot] && isAlertShowedAlready == FALSE)
    {
        if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQ)
        {
            alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Guess Connect",nil) message:NSLocalizedString(@"Did you accept the pairing request?",nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"NO",nil) otherButtonTitles:NSLocalizedString(@"YES",nil),nil] ;
            alert.delegate = self;
            [alert show];
            isAlertShowedAlready = TRUE;
        }
        else
        {
            [timexDevice requestDeviceInfo];
        }
    }
    else
    {
        [HUD hide:YES];
    }
}
-(BOOL)checkAlerViewShowingOrNot {
    for (UIWindow* window in [UIApplication sharedApplication].windows) {
        NSArray* subviews = window.subviews;
        if ([subviews count] > 0)
            if ([[subviews objectAtIndex:0] isKindOfClass:[UIAlertView class]])
                return YES;
    }
    return NO;
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [self checkAndInvalidateTimeout];
    if (buttonIndex == 0)
    {
        [HUD hide:YES];
        [self exitSyncModeManually];
        [self tryAgain];
    }
    else
    {
        PeripheralDevice * timexDevice = [iDevicesUtil getConnectedTimexDevice];
        [timexDevice requestDeviceInfo];
    }
}

-(void)tryAgain
{
    UIAlertController *tryAgainAlert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Try again.", nil)
                                                                           message:NSLocalizedString(@"Please follow the instructions to put your watch into Bluetooth mode.", nil)
                                                                    preferredStyle:UIAlertControllerStyleAlert];
    [tryAgainAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                      style:UIAlertActionStyleCancel
                                                    handler:^(UIAlertAction * _Nonnull action){}]];
    [self presentViewController:tryAgainAlert animated:YES completion:nil];
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

-(void) watchConnectionTimeout:(NSTimer*)timer {
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(deviceListChanged:) name: kDeviceManagerAdvertisingDevicesChangedNotification object: nil];
    [self checkAndInvalidateTimeout];
    OTLog(@"Watch connection time out happened..");
    PeripheralDevice * timexDevice = [iDevicesUtil getConnectedTimexDevice];
    if (timexDevice)
    {
        [[TDDeviceManager sharedInstance] disconnect: timexDevice];
    }
    else
    {
        [HUD hide: YES];
    }
    NSLog(@"device.deviceState:%d",[(PeripheralDevice *)WatchAsAnObject deviceState]);
    if (devicesArray.count > 0 && [devicesArray containsObject:(PeripheralDevice *)WatchAsAnObject]) {
        [devicesArray removeObject:(PeripheralDevice *)WatchAsAnObject];
        [watchListTableView reloadData];
    }
    WatchAsAnObject = nil;
    [self deviceListChanged:nil];
    
    dontCheck = YES;
    UIAlertController *toggleBluetooth = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Watch connection time out happened...", nil)
                                                                             message:NSLocalizedString(@"If this continues to happen, toggle Bluetooth off and back on to repair.", nil)
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [toggleBluetooth addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                        style:UIAlertActionStyleCancel
                                                      handler:nil]];
    [self presentViewController:toggleBluetooth
                       animated:YES
                     completion:nil];
}
-(void) successfullyConnectedToDevice:(NSNotification*)notification {
    [self checkAndInvalidateTimeout];
    [self performSelector:@selector(ReadDeviceWhoIs) withObject:nil afterDelay: 1];
    OTLog(@"Successfully connected to device");
}
- (void) WatchInfoRead: (NSNotification*)notification {
    [self checkAndInvalidateTimeout];
    OTLog(@"====System wide setup watch calling Sync WatchIQMoveViewController");
    PCCommWhosThere * newSettings = [notification.userInfo objectForKey: kDeviceWatchInfoKey];
    if (newSettings)
    {
        // Stop observing this stuff.
//        [[NSNotificationCenter defaultCenter] removeObserver: self name:kTDWatchInfoReadSuccessfullyNotification object:nil];
        SynWatchIQMoveViewController * syncController = [[SynWatchIQMoveViewController alloc] initWithNibName:@"SynWatchIQMoveViewController" bundle: nil kickOffSyncAutomatically: TRUE];
        
        syncController.watchObject = WatchAsAnObject;
        syncController.openedByMenu = self.openedByMenu;
        [[self navigationController] pushViewController: syncController animated: YES];
        
        WatchAsAnObject = nil;
        [devicesArray removeAllObjects];
        
        [HUD hide: YES];
    }
}
- (void) WatchInfoReadFailed: (id) sender
{
    [self checkAndInvalidateTimeout];
    [HUD hide: YES];
}

-(void)unexpectedBootloaderModeForM372DetectedAndApproved:(NSNotification*)notification
{
    OTLog(@"moveToFirmwareUpdate");
    [HUD hide: YES];
    NSString * keyFirstTiem = @FIRST_SYNC;
    if ([[NSUserDefaults standardUserDefaults] objectForKey: keyFirstTiem] == nil)
    {
        [[NSUserDefaults standardUserDefaults] setObject: @"0" forKey: keyFirstTiem];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    UpdateFirmwareViewController *updateFirmwareVC=[[UpdateFirmwareViewController alloc] initWithNibName:@"UpdateFirmwareViewController" bundle:nil];
    updateFirmwareVC.unstickBootloader = YES;
    updateFirmwareVC.openedByMenu = self.openedByMenu;
    [self.navigationController pushViewController:updateFirmwareVC animated:YES];
}

@end
