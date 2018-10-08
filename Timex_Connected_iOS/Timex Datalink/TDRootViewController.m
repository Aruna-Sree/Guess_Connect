//
//  TDRootViewController.m
//  Timex Connected
//
//  Created by Lev Verbitsky on 6/18/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

#import "TDRootViewController.h"
#import "TDDeviceManager.h"
#import "BLEManager.h"
#import "MFSideMenuContainerViewController.h"
#import "TDWatchProfile.h"
#import "PCCommWhosThere.h"
#import "PCCommChargeInfo.h"
#import "TDDatacastFirmwareUpgradeInfo.h"
#import "TDFlurryDataPacket.h"
#import "MBProgressHUD.h"
#import "TDAppDelegate.h"
#import "UIImage+Tint.h"
#import "PCCommExtendedFirmwareVersionInfo.h"
#import <TCBlobDownload/TCBlobDownload.h>
#import "BLEManager.h"
#import "OTLogUtil.h"
#import "TDM328WatchSettingsUserDefaults.h"


NSString* const kLAST_FIRMWARE_CHECK_DATE = @"kLAST_FIRMWARE_CHECK_DATE";
NSString* const kFirmwareCheckUserInitiatedNotification = @"kFirmwareCheckUserInitiatedNotification";
NSString* const kFirmwareRequestUserInitiatedNotification = @"kFirmwareRequestUserInitiatedNotification";
NSString* const kM372WatchResetUserInitiatedNotification = @"kM372WatchResetUserInitiatedNotification";

#define kFirmwareCheckQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) //1

@interface TDRootViewController () <TDFirmwareUploadStatusDelegate, UIAlertViewDelegate, TCBlobDownloaderDelegate, UINavigationControllerDelegate>
{
    BLEManager      *  bleManager;//Diego_Santiago_artf21122
    MBProgressHUD   *  HUD;
    //MBProgressHUD   *  HUDWaitingForWatch;
    PCCommWhosThere * _mReadSettings;
    UIAlertView     * _mFirmwareUpdateAlert;
    UIAlertView     * _mFirmwareInformationAlert;
    UIAlertView     * _mFirmwareUpdateCancelAlert;
    UIAlertView     * _notEnoughChargeAlert;
    UIAlertView     * _mFirmwareUpdateSuccessful;//TestLog_M372FirmwareUpdateV2
    
    NSInteger         _firmwareVersionOnServer;
    
    NSInteger       m372ReconnectAttempts;
    BOOL            m372WatchResetRequested;
    BOOL            m372StuckInBootloader;
}
@property (nonatomic, weak, readonly) UIButton * bleStatusButton;
@end

@implementation TDRootViewController

@synthesize bluetoothStatusPopupVisible = _bluetoothStatusPopupVisible;
@synthesize bleStatusButton = _bleStatusButton;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Do Nothing
        _bluetoothStatusPopupVisible = FALSE;
        
        TDAppDelegate * delegate = (TDAppDelegate *)[UIApplication sharedApplication].delegate;
        UINavigationController * navBar = (UINavigationController *)((MFSideMenuContainerViewController *)delegate.window.rootViewController).centerViewController;
        navBar.delegate = self;
        
        // Diego_Santiago_artf21122
        //initialize here to give the BLEManager some time to get its status
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    bleManager = [[TDDeviceManager sharedInstance] getBleManager];
    if(!self.title)
    {
        UIImageView *imageViewBackgr = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, NAVIGATION_BAR_FOOTER_IMAGE_WIDTH + (NAVIGATION_BAR_RED_SQUARE_EDGE_WIDTH * 2), NAVIGATION_BAR_FOOTER_IMAGE_HEIGHT + (NAVIGATION_BAR_RED_SQUARE_EDGE_WIDTH * 2))];
        [imageViewBackgr setBackgroundColor: [iDevicesUtil getTimexRedColor]];
        
        UIImage *img = [UIImage imageNamed:@"timex_logo.png"];
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(NAVIGATION_BAR_RED_SQUARE_EDGE_WIDTH, NAVIGATION_BAR_RED_SQUARE_EDGE_WIDTH, NAVIGATION_BAR_FOOTER_IMAGE_WIDTH, NAVIGATION_BAR_FOOTER_IMAGE_HEIGHT)];
        [imageView setContentMode: UIViewContentModeCenter];
        [imageView setBackgroundColor: [UIColor clearColor]];
        imageView.image = img;
        [imageView setAlpha:1.0f];
        
        UIImageView *workaroundImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, NAVIGATION_BAR_FOOTER_IMAGE_WIDTH + (NAVIGATION_BAR_RED_SQUARE_EDGE_WIDTH * 2), NAVIGATION_BAR_FOOTER_IMAGE_HEIGHT + (NAVIGATION_BAR_RED_SQUARE_EDGE_WIDTH * 2))];
        [workaroundImageView addSubview:imageViewBackgr];
        [workaroundImageView addSubview:imageView];
        [self.navigationItem setTitleView: workaroundImageView];
        
        _bluetoothStatusPopupVisible = FALSE;
        m372StuckInBootloader = FALSE;
        m372WatchResetRequested = FALSE;
    }
    
    [self refreshNavigationBar: self];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear: animated];
    [self refreshNavigationBar: self];
}
- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear: animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(WatchInfoRead:) name: kTDWatchInfoFWReadSuccessfullyNotification object: nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(WatchInfoReadFailed:) name: kTDWatchInfoFWReadUnsuccessfullyNotification object: nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(M372FirmwareUploadWatchChargeInfoRead:) name: kTDWatchChargeInfoReadSuccessfullyNotification object: nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(WatchChargeInfoRead:) name: kTDWatchChargeInfoFWReadSuccessfullyNotification object: nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(WatchChargeInfoReadFailed:) name: kTDWatchChargeInfoFWReadUnsuccessfullyNotification object: nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(BootloaderInfoRead:) name: kTDWatchInfoBootloaderReadSuccessfullyNotification object: nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(BootloaderInfoReadFailed:) name: kTDWatchInfoBootloaderReadUnsuccessfullyNotification object: nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(FirmwareUpdateComplete:) name: kTDFirmwareWrittenSuccessfullyNotification object: nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(BootloaderFirmwareUpdateComplete:) name: kTDBootloaderFirmwareWrittenSuccessfullyNotification object: nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(FirmwareUpdateCanceled:) name: kTDFirmwareUpdateCancelledNotification object: nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(FirmwareUpdateFailure:) name: kTDFirmwareWrittenUnsuccessfullyNotification object: nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(launchFirmwareCheck:) name: UIApplicationWillEnterForegroundNotification object: nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(launchFirmwareCheck:) name: kTDFullPairingWithWatchConfirmed object: nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(launchUserInitiatedFirmwareCheck:) name: kFirmwareCheckUserInitiatedNotification object: nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(launchUserInitiatedWatchReset:) name: kM372WatchResetUserInitiatedNotification object: nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNewFirmwareVersion:) name: kFirmwareRequestUserInitiatedNotification object: nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(successfulInitialConnectionToM372Watch:) name: kPeripheralDeviceTimexDatalinkPrimaryCharacteristicDiscovered object: nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bootloaderModeForM372Requested:) name: kTDM372BootloaderModeRequested object: nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(unexpectedBootloaderModeForM372Detected:) name: kTDM372UnexpectedBootloaderModeDetected object: nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(unexpectedBootloaderModeForM372DetectedAndApproved:) name: kTDM372UnexpectedBootloaderModeDetectedAndApproved object: nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(watchDisconnected:) name:kDeviceManagerDeviceLostConnectiondNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(watchDisconnected:) name:kPeripheralDeviceAuthorizationFailedNotification object: nil];
    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(apptsReadingStarted:) name:kTDApptsWritingStartedNotification object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(apptsReadingFinished:) name:kTDApptsWrittenSuccessfullyNotification object:nil];
//    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(apptsReadingFinished:) name:kTDApptsWrittenUnsuccessfullyNotification object:nil];
    

    if ([self viewSupportsFirmwareUpdateHandling] && [TDFirmwareUploadStatus sharedInstance: FALSE] != nil)
    {
        [(TDFirmwareUploadStatus *)[TDFirmwareUploadStatus sharedInstance: FALSE] setDelegate: self];
        [self.view addSubview: [TDFirmwareUploadStatus sharedInstance: FALSE]];
    }
}

//-(void)apptsReadingStarted: (NSNotification*)notification
//{
//    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_M054)
//    {
//        OTLog(@"appointments reading started");
//        HUD = [[MBProgressHUD alloc] initWithView: self.navigationController.view];
//        [self.navigationController.view addSubview: HUD];
//        
//        HUD.labelText = NSLocalizedString(@"Please Wait", nil);
//        HUD.detailsLabelText = NSLocalizedString(@"Reading appointments....", nil);
//        HUD.square = YES;
//        HUD.mode = MBProgressHUDModeIndeterminate;
//        
//        [HUD show: YES];
//        
//        TDAppDelegate * delegate = (TDAppDelegate *)[UIApplication sharedApplication].delegate;
//        ((MFSideMenuContainerViewController *)delegate.window.rootViewController).panMode = MFSideMenuPanModeNone;
//    }
//}

//-(void)apptsReadingFinished: (NSNotification*)notification
//{
//    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_M054)
//    {
//        TDAppDelegate * delegate = (TDAppDelegate *)[UIApplication sharedApplication].delegate;
//        ((MFSideMenuContainerViewController *)delegate.window.rootViewController).panMode = MFSideMenuPanModeCenterViewController;
//        
//        OTLog(@"appointments reading finished");
//        [HUD hide:YES];
//    }
//}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    //[self refreshNavigationBar: viewController];
    
    TDAppDelegate * delegate = (TDAppDelegate *)[UIApplication sharedApplication].delegate;
    UINavigationController * navBar = (UINavigationController *)((MFSideMenuContainerViewController *)delegate.window.rootViewController).centerViewController;
    
    if ([viewController conformsToProtocol:@protocol(UINavigationControllerDelegate)])
    {
        navBar.delegate = (id<UINavigationControllerDelegate>)viewController;
    }
    else
    {
        navBar.delegate = nil;
    }
}

- (void) refreshNavigationBar: (UIViewController *) viewController
{
    UIColor * primaryColor = [UIColor blackColor];
    
    OTLog([NSString stringWithFormat:@"refreshNavigatorBar: %@", [viewController debugDescription]]);
    
    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQ || [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel || [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_Metropolitan) {
        
        [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleDefault;
        
    }
    TDAppDelegate * delegate = (TDAppDelegate *)[UIApplication sharedApplication].delegate;
    UINavigationController * navBar = (UINavigationController *)((MFSideMenuContainerViewController *)delegate.window.rootViewController).centerViewController;
    if (!([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQ || [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel || [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_Metropolitan)) {
        navBar.navigationBar.backgroundColor = primaryColor;
        [navBar.navigationBar setBackgroundImage:[iDevicesUtil imageWithColor:primaryColor] forBarMetrics:UIBarMetricsDefault];
//        [navBar.navigationBar setBackgroundImage:[iDevicesUtil imageWithColor: primaryColor] forBarMetrics:UIBarMetricsDefault]; // Fixed back button and Title of topbar appearence in all screens of RunX and Classic
    } else {
        [delegate setNavigationBarSettingsForM328:navBar];
    }
    
    [self setupMenuBarButtonItems];
}
- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear: animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kBLEManagerConnectedPeripheralNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kBLEManagerDisconnectedPeripheralNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kTDWatchInfoFWReadSuccessfullyNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kTDWatchInfoFWReadUnsuccessfullyNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kTDWatchInfoBootloaderReadSuccessfullyNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kTDWatchInfoBootloaderReadUnsuccessfullyNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kTDWatchChargeInfoFWReadSuccessfullyNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kTDWatchChargeInfoFWReadUnsuccessfullyNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kTDFirmwareWrittenSuccessfullyNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kTDBootloaderFirmwareWrittenSuccessfullyNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kTDFirmwareWrittenUnsuccessfullyNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kTDFirmwareUpdateCancelledNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kFirmwareCheckUserInitiatedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kM372WatchResetUserInitiatedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kTDFullPairingWithWatchConfirmed object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kFirmwareRequestUserInitiatedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kTDM372UnexpectedBootloaderModeDetectedAndApproved object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kTDM372UnexpectedBootloaderModeDetected object:nil];
    
    //TestLog_CorrectErrorsInSync
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kTDM372SleepKeyFileReadUnsuccessfullyNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kTDM372SleepSummaryUnsuccessfullyNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kTDM372SleepActigraphyDataUnsuccessfullyNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kTDM372SleepKeyFileReadSuccessfullyNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kTDM372SleepActigraphyDataSuccessfullyNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kTDM372SleepSummarySuccessfullyNotification object:nil];
    
    //Actigraphy step file
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kTDM372ActigraphyStepFileDataSuccessfullyNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kTDM372ActigraphyStepFileDataUnsuccessfullyNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kPeripheralDeviceTimexDatalinkPrimaryCharacteristicDiscovered object:nil];
    
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:kTDApptsWritingStartedNotification object:nil];
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:kTDApptsWrittenSuccessfullyNotification object:nil];
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:kTDApptsWrittenUnsuccessfullyNotification object:nil];
    //TestLog_CorrectErrorsInSync
}

- (void) launchUserInitiatedWatchReset: (NSNotification*)notification
{
    HUD = [[MBProgressHUD alloc] initWithView: self.navigationController.view];
    [self.navigationController.view addSubview: HUD];
    
    HUD.labelText = NSLocalizedString(@"Please Wait", nil);
    HUD.detailsLabelText = NSLocalizedString(@"Requesting Watch Reset...", nil);
    HUD.square = YES;
    HUD.mode = MBProgressHUDModeIndeterminate;
    
    [HUD show: YES];
    
    m372WatchResetRequested = TRUE;
    [self _connectToM372DeviceForFirmwareUpload];
}
- (void) launchUserInitiatedFirmwareCheck: (NSNotification*)notification
{
    if ([iDevicesUtil hasInternetConnectivity])
    {
        if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_Metropolitan || [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQ || [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)
        {
            [self handleFirmwareCheckInitiation];
            dispatch_async(kFirmwareCheckQueue, ^{
                NSData* data = [NSData dataWithContentsOfURL: kTimexFirmwareCheckURL];
                
                [self performSelectorOnMainThread:@selector(fetchedFirmwareInfo:) withObject: data waitUntilDone: YES];
            });
        }
        else
        {
            PeripheralDevice * timexDevice = [iDevicesUtil getConnectedTimexDevice];
            if (timexDevice != nil)
            {
                [self handleFirmwareCheckInitiation];
                [self getConnectedDeviceInfo];
            }
            else
            {
                UIAlertView * notConnectedAlert = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"FIRMWARE UPDATE", nil)
                                                                   message: NSLocalizedString(@"Not connected to watch.", nil)
                                                                  delegate:self cancelButtonTitle: NSLocalizedString(@"OK", nil) otherButtonTitles: nil ];
                [notConnectedAlert show];
            }
        }
    }
    else
    {
        UIAlertView * notConnectedAlert = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"FIRMWARE UPDATE", nil)
                                                                 message: NSLocalizedString(@"Not connected to internet.", nil)
                                                                delegate:self cancelButtonTitle: NSLocalizedString(@"OK", nil) otherButtonTitles: nil ];
        [notConnectedAlert show];
    }
}
- (void) launchFirmwareCheck: (NSNotification*)notification
{    
    OTLog([NSString stringWithFormat:@"Firmware check requested by %@", notification.name]);
    
    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_Metropolitan || [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQ || [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)
    {
        [self launchFirmwareCheckForM372: notification];
    }
    else if ([self viewSupportsFirmwareUpdateHandling] == TRUE)
    {
        if ([[NSUserDefaults standardUserDefaults] objectForKey: kBLEandBTCPairingConfirmed] != nil)
        {
            TDAppDelegate * delegate = (TDAppDelegate *)[UIApplication sharedApplication].delegate;
            BOOL BLEandBTCpairingStatus = [[NSUserDefaults standardUserDefaults] boolForKey: kBLEandBTCPairingConfirmed];
            if (BLEandBTCpairingStatus)
            {
                NSInteger secsPerDay = 60 * 60 * 12;
                NSDate * now = [NSDate date];
                NSDate * lastFirmwareCheckDate = [[NSUserDefaults standardUserDefaults] objectForKey: kLAST_FIRMWARE_CHECK_DATE];
                if (lastFirmwareCheckDate == nil || [now timeIntervalSinceDate: lastFirmwareCheckDate] > secsPerDay)
                {
                    [self getConnectedDeviceInfo];
                }
                else
                {
                    ((MFSideMenuContainerViewController *)delegate.window.rootViewController).panMode = MFSideMenuPanModeCenterViewController;
                    [HUD hide:YES];
                    OTLog(@"Did not perform Firmware check because less then 12 hours elapsed since the last firmware check");
                }
            }
            else
            {
                ((MFSideMenuContainerViewController *)delegate.window.rootViewController).panMode = MFSideMenuPanModeCenterViewController;
                [HUD hide:YES];
                OTLog(@"Did not perform Firmware check because the phone is not fully paired to watch");
            }
        }
    }
}

- (void) launchFirmwareCheckForM372: (NSNotification*)notification
{
    OTLog([NSString stringWithFormat:@"M372 Firmware check requested by %@", notification.name]);
    
    PeripheralDevice * timexDevice = [iDevicesUtil getConnectedTimexDevice];
    if (timexDevice != nil)
    {
        if ([timexDevice isFirmwareUpgradeInProgress])
        {
            OTLog(@"Did not perform M372 Firmware check because the firmware upgrade is currently in progress");
            return;
        }
    }
    //TestLog_artf21290_AddedThisValidationToCheckIfWatchWasAddedBeforeAndCheckTheFirmwareVersion
    if ([iDevicesUtil checkForActiveProfilePresence])
    {
        NSInteger secsPerDay = 60 * 60 * 24; //60 * 60 * 24
        NSDate * now = [NSDate date];
        NSDate * lastFirmwareCheckDate = [[NSUserDefaults standardUserDefaults] objectForKey: kLAST_FIRMWARE_CHECK_DATE];
        if (lastFirmwareCheckDate == nil || [now timeIntervalSinceDate: lastFirmwareCheckDate] > secsPerDay)
        {
            if ([iDevicesUtil hasInternetConnectivity])
                [[NSNotificationCenter defaultCenter] postNotificationName: kFirmwareCheckUserInitiatedNotification object:self];
        }
        else
        {
            OTLog(@"Did not perform M372 Firmware check because less then 24 hours elapsed since the last firmware check");
        }
    }
}

- (BOOL) viewHasContextualMenu
{
    return FALSE; //to be overwritten by children, if necessary
}
- (BOOL) viewSupportsFirmwareUpdateHandling
{
    return FALSE; //to be overwritten by children, if necessary
}
- (MFSideMenuContainerViewController *)menuContainerViewController
{
    return (MFSideMenuContainerViewController *)self.navigationController.parentViewController;
}

- (void)setupMenuBarButtonItems
{
    if ([self viewHasContextualMenu] == true)
    {
        self.navigationItem.rightBarButtonItem = [self rightMenuBarButtonItem];
    }
    else
    {
        self.navigationItem.rightBarButtonItem = [self rightMenuBarButtonItemNoMenu];
    }
    
    if(self.menuContainerViewController.menuState == MFSideMenuStateClosed &&
       self.menuContainerViewController.panMode == MFSideMenuPanModeNone &&
       ![[self.navigationController.viewControllers objectAtIndex:0] isEqual:self])
    {
        self.navigationItem.leftBarButtonItem = [self backBarButtonItem];
        self.navigationItem.rightBarButtonItem = nil;
    }
    else
    {
        self.navigationItem.leftBarButtonItem = [self leftMenuBarButtonItem];
    }
}

- (UIBarButtonItem *)leftMenuBarButtonItem
{
    UIImage *image;
    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQ || [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel || [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_Metropolitan) {
        image=[[UIImage imageNamed:@"menu"] stretchableImageWithLeftCapWidth:0 topCapHeight:0];
    } else {
        image=[[UIImage imageNamed:@"menu-icon"] stretchableImageWithLeftCapWidth:0 topCapHeight:0];
    }
//    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_Metropolitan)
//    {
//        //TestLog_SleepTrackerImplementation
//            image = [image imageWithTint: [UIColor grayColor]];
//    }
    
    CGRect frameimg = CGRectMake(0, 0, image.size.width,image.size.height);
    UIButton *but = [[UIButton alloc] initWithFrame:frameimg];
    [but setBackgroundImage:image forState:UIControlStateNormal];
    [but addTarget:self action:@selector(leftSideMenuButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    return [[UIBarButtonItem alloc] initWithCustomView:but];
    
}

- (UIBarButtonItem *)rightMenuBarButtonItem
{    
    CGRect frameCustomButtonView = CGRectMake(0, 0, NAVIGATION_ITEM_ICON_SIZE * 2 + NAVIGATION_ITEM_ICON_SPACER, NAVIGATION_ITEM_ICON_SIZE);
	UIView * customButtonView = [[UIView alloc] initWithFrame:frameCustomButtonView];
    
	CGRect frame = CGRectMake(0, 0, NAVIGATION_ITEM_ICON_SIZE, NAVIGATION_ITEM_ICON_SIZE);
	UIButton* buttonBLE = [[UIButton alloc] initWithFrame:frame];
//	[self setupBLEStatusButton: buttonBLE];
	[customButtonView addSubview: buttonBLE];
    
    CGSize iconSize = CGSizeMake(NAVIGATION_ITEM_IMAGE_SIZE, NAVIGATION_ITEM_IMAGE_SIZE);
    UIImage * editIcon = [UIImage imageWithImage: [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"contextual-menu-icon" ofType:@"png"]] scaledToSize: iconSize];
    
    CGRect frame2 = CGRectMake(NAVIGATION_ITEM_ICON_SIZE + NAVIGATION_ITEM_ICON_SPACER, 0, NAVIGATION_ITEM_ICON_SIZE, NAVIGATION_ITEM_ICON_SIZE);
	UIButton* buttonEditMode = [[UIButton alloc] initWithFrame:frame2];
	[buttonEditMode setExclusiveTouch: YES];
	[buttonEditMode setImage: editIcon forState:UIControlStateNormal];
	[buttonEditMode addTarget:self action:@selector(rightSideMenuButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
	[buttonEditMode setShowsTouchWhenHighlighted:YES];
	[customButtonView addSubview:buttonEditMode];
    
	UIBarButtonItem* customButtons = [[UIBarButtonItem alloc] initWithCustomView:customButtonView];
    
    return customButtons;
}

- (UIBarButtonItem *)rightMenuBarButtonItemNoMenu
{
    CGRect frameCustomButtonView = CGRectMake(0, 0, NAVIGATION_ITEM_ICON_SIZE, NAVIGATION_ITEM_ICON_SIZE);
	UIView * customButtonView = [[UIView alloc] initWithFrame:frameCustomButtonView];
    
	CGRect frame = CGRectMake(0, 0, NAVIGATION_ITEM_ICON_SIZE, NAVIGATION_ITEM_ICON_SIZE);
	UIButton* buttonBLE = [[UIButton alloc] initWithFrame:frame];
    //TestLog_SleepTracker
    
	UIBarButtonItem* customButtons = [[UIBarButtonItem alloc] initWithCustomView:customButtonView];
    
    return customButtons;
}

- (UIBarButtonItem *)backBarButtonItem
{
    UIButton *but = [iDevicesUtil getNavBarButtonBasedOnText: NSLocalizedString(@"Back", nil)];
    [but setImage:[UIImage imageNamed:@"arrow_left.png"] forState:UIControlStateNormal]; 
    
    [but addTarget:self action:@selector(backButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    return [[UIBarButtonItem alloc] initWithCustomView:but];
}

- (void)leftSideMenuButtonPressed:(id)sender
{
    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_Metropolitan)
    {
        //do not allow user to do anything while we are performing firmware upgrade on M372
        PeripheralDevice * timexDevice = [iDevicesUtil getConnectedTimexDevice];
        if (timexDevice != nil && [timexDevice isFirmwareUpgradeInProgress])
            return;
    }
    
    __weak TDRootViewController * weakSelf = self;
    [self.menuContainerViewController toggleLeftSideMenuCompletion:^
     {
         TDRootViewController * strongSelf = weakSelf;
         [strongSelf setupMenuBarButtonItems];
     }];
}

- (void)rightSideMenuButtonPressed:(id)sender
{
    [self contextualMenuRequested];
}

- (void) contextualMenuRequested
{
    //to be overwritten by children if necessary; this function intentionally left blank
}

- (void)backButtonPressed:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark TDConnectionStatusWindowDelegate methods
- (void) willShowTDConnectionStatusWindow:(TDConnectionStatusWindow*)sender
{
    _bluetoothStatusPopupVisible = TRUE;
}
- (void) didShowTDConnectionStatusWindow:(TDConnectionStatusWindow*)sender
{
    _bluetoothStatusPopupVisible = TRUE;
}
- (void) willCloseTDConnectionStatusWindow:(TDConnectionStatusWindow*)sender
{
    _bluetoothStatusPopupVisible = TRUE;
}
- (void) didCloseTDConnectionStatusWindow:(TDConnectionStatusWindow*)sender
{
    _bluetoothStatusPopupVisible = FALSE;
}

#pragma mark -
#pragma mark Firmware Check and Download methods
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

- (void) BootloaderInfoRead: (NSNotification*)notification
{
    OTLog(@"Read Bootloader Info:");
    
    PCCommWhosThere * readSettings = [notification.userInfo objectForKey: kDeviceWatchInfoKey];
    if (readSettings)
    {
        OTLog(@"Bootloader status is %d", readSettings.mModeStatus);
        if (readSettings.mModeStatus == 0)
        {
            [[TDFirmwareUploadStatus sharedInstance: FALSE] dismiss];
            //we are not yet in bootloader
            OTLog(@"Kicking off bootloader mode");
            [self performSelector:@selector(_initiateBootloaderModeForM372) withObject:nil afterDelay: 0.5];
        }
        else
        {
            [self _sendBootloaderFiles];
        }
    }
}
- (void) BootloaderInfoReadFailed: (id) sender
{
    
}
- (void) _sendBootloaderFiles
{
    OTLog(@"We are already in bootloader");
    //we are already in bootloader! proceed
    TDFirmwareUploadStatus * progress = [TDFirmwareUploadStatus sharedInstance: FALSE];
    TDM372FirmwareUpgradeInfo * activity = [self _getM372FirmwareUpgradeFileInfoForType: TDM372FirmwareUpgradeInfoType_Activity];
    if (activity)
    {
        PeripheralDevice * timexDevice = [iDevicesUtil getConnectedTimexDevice];
        if (timexDevice)
        {
            [timexDevice setProgressDialog: progress];
            [timexDevice doBootloaderFirmwareUpgrade: [NSArray arrayWithObject: activity]];
        }
    }
    else
    {
        TDM372FirmwareUpgradeInfo * codeplug = [self _getM372FirmwareUpgradeFileInfoForType: TDM372FirmwareUpgradeInfoType_Codeplug];
        if (codeplug)
        {
            PeripheralDevice * timexDevice = [iDevicesUtil getConnectedTimexDevice];
            if (timexDevice)
            {
                [timexDevice setProgressDialog: progress];
                [timexDevice doBootloaderFirmwareUpgrade: [NSArray arrayWithObject: codeplug]];
            }
        }
        else
        {
            TDM372FirmwareUpgradeInfo * firmw = [self _getM372FirmwareUpgradeFileInfoForType: TDM372FirmwareUpgradeInfoType_Firmware];
            if (firmw)
            {
                PeripheralDevice * timexDevice = [iDevicesUtil getConnectedTimexDevice];
                if (timexDevice)
                {
                    [timexDevice setProgressDialog: progress];
                    [timexDevice doBootloaderFirmwareUpgrade: [NSArray arrayWithObject: firmw]];
                }
            }
        }
    }
}
- (void) WatchChargeInfoRead: (NSNotification*)notification
{
    //This is a fix for Mantis 577, when the watch status dialog is launched by the user but dismissed before watch battery charge information is processed... so bluetoothStatusPopupVisible is false. Ensure that we are not tricked into thinking that we are in teh middle of firmware upgrade.
    if (_mFirmwareUpgradeInfo == nil) //if, for whatever reason, we don't have firmware download data
        return;
    
    //This is a fix for Mantis 591, when the watch status dialog is launched in the middle of firmware download, but dismissed before the information could be processed there. We ned to make sure that we don't process this information here if we are in the middle of firmware download.
    PeripheralDevice * timexDevice = [iDevicesUtil getConnectedTimexDevice];
    if ([timexDevice isFirmwareUpgradeInProgress] || [timexDevice isFirmwareUpgradePaused])
        return;
    
    PCCommChargeInfo * chargeInfo = [notification.userInfo objectForKey: kDeviceWatchChargeInfoKey];
    if (chargeInfo)
    {
        [[NSUserDefaults standardUserDefaults] setFloat:chargeInfo.voltage forKey:KEY_BATTERRY_CHARGE_M372];

        if (chargeInfo.USBStatus == 0 && chargeInfo.charge < 50.0)
        {
            _notEnoughChargeAlert = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"Insufficient Battery Charge", nil)
                                                                                       message: NSLocalizedString(@"Please charge your watch.", nil)
                                                                                      delegate:self cancelButtonTitle: NSLocalizedString(@"OK", nil) otherButtonTitles: nil ];
            [_notEnoughChargeAlert show];
        }
        else
        {
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
            for (TDDatacastFirmwareUpgradeInfo * downloadInfo in _mFirmwareUpgradeInfo)
            {
                [[TCBlobDownloadManager sharedInstance] startDownloadWithURL:[NSURL URLWithString: downloadInfo.uri] customPath: newDir delegate: self];
            }
        }
    }
}
- (void) WatchChargeInfoReadFailed: (id) sender
{
    
}

- (void) getConnectedDeviceInfo
{
    PeripheralDevice * timexDevice = [iDevicesUtil getConnectedTimexDevice];
    if (timexDevice != nil)
    {
        if ([timexDevice isFirmwareUpgradeInProgress] == FALSE && [timexDevice isFirmwareUpgradePaused] == FALSE)
        {
            [timexDevice requestDeviceInfoForFirmware];
        }
        else
        {
            [self handleFirmwareUpgradeInProgress];
        }
    }
}

- (void) fetchedFirmwareInfo: (NSData *)responseData
{
    BOOL        foundJSONmodule = false;
    NSError     * error = nil;
        
    //if we got no data, or we are no longer on the foreground for whatever reason....
    if (responseData == nil || ![self isViewLoaded] || self.view.window == nil)
        return;
    
    NSDictionary* json = [NSJSONSerialization JSONObjectWithData: responseData options:kNilOptions error: &error];
    
    NSNumber * json_version = [json objectForKey: @"file_version"];
    NSLog(@"%@",json);
    
    if ([json_version intValue] == FIRMWARE_UPGRADE_JSON_FILE_VERSION)
    {
        NSArray* availableModules = [json objectForKey: @"modules"];
        for (NSDictionary * availableModule in availableModules)
        {
            OTLog([NSString stringWithFormat:@"module: %@", availableModule]);
            
            NSString * moduleName = [availableModule objectForKey:@"name"];
            if (moduleName && [_mReadSettings.mModelNumber isEqualToString: moduleName] == TRUE)
            {
                //we found the module that we need
                foundJSONmodule = TRUE;
                
                //record that we have done a SUCCESSFUL firmware update  check today
                [[NSUserDefaults standardUserDefaults] setObject: [NSDate date] forKey: kLAST_FIRMWARE_CHECK_DATE];
                
                _mFirmwareUpgradeInfo = [[NSMutableArray alloc] init];
                NSArray * moduleInfo = [availableModule objectForKey: @"files"];
                for (NSDictionary * cluster in moduleInfo)
                {
                    TDDatacastFirmwareUpgradeInfo * newInfoCluster = [[TDDatacastFirmwareUpgradeInfo alloc] init];
                    
                    NSString * uriType = [cluster objectForKey:@"type"];
                    
                    if ([uriType isEqualToString: @"firmware"])
                        newInfoCluster.type = TDDatacastFirmwareUpgradeInfoType_Firmware;
                    else if ([uriType isEqualToString: @"codeplug"])
                        newInfoCluster.type = TDDatacastFirmwareUpgradeInfoType_Codeplug;
                    
                    NSString * uriStr = [cluster objectForKey:@"uri"];
                    newInfoCluster.uri = uriStr;
                    
                    NSNumber * uriVersion = [cluster objectForKey: @"version"];
                    newInfoCluster.version = [uriVersion integerValue];
                    
                    [_mFirmwareUpgradeInfo addObject: newInfoCluster];
                }
                
                break;
            }
            else if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_Metropolitan && [moduleName isEqualToString: @"M372"])
            {
                //we found the module that we need
                foundJSONmodule = TRUE;
                [self _createFirmwareUpdateInfoArrayForM372: availableModule bootloaderOnly: FALSE];
            }
            else if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQ && [moduleName isEqualToString: @"M328"])
            {
                //we found the module that we need
                foundJSONmodule = TRUE;
                [self _createFirmwareUpdateInfoArrayForM372: availableModule bootloaderOnly: FALSE];
            }
            else if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel && [moduleName isEqualToString: @"M329"])
            {
                //we found the module that we need
                foundJSONmodule = TRUE;
                [self _createFirmwareUpdateInfoArrayForM372: availableModule bootloaderOnly: FALSE];
            }
        }
    }
    
    //make a determination if firmware update is required HERE:
    if (foundJSONmodule)
    {
        if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_Metropolitan)
        {
            NSString * versionOnWatch = [[NSUserDefaults standardUserDefaults] objectForKey: kM372FirmwareVersionFile1Key];
            [self _upgradeRequiredForM372FirmwareFile: versionOnWatch];
            
            versionOnWatch = [[NSUserDefaults standardUserDefaults] objectForKey: kM372FirmwareVersionFile2Key];
            [self _upgradeRequiredForM372FirmwareFile: versionOnWatch];
            
            versionOnWatch = [[NSUserDefaults standardUserDefaults] objectForKey: kM372FirmwareVersionFile3Key];
            [self _upgradeRequiredForM372FirmwareFile: versionOnWatch];
            
            versionOnWatch = [[NSUserDefaults standardUserDefaults] objectForKey: kM372FirmwareVersionFile4Key];
            [self _upgradeRequiredForM372FirmwareFile: versionOnWatch];
            
            //get rid of files that we don't need to upload
            //keep in mind that Firmware and Activity files always go together...
            BOOL upgradeForFirmwareRequired;
            BOOL upgradeForActivityRequired;
            for (TDM372FirmwareUpgradeInfo * downloadInfo in _mFirmwareUpgradeInfo)
            {
                if (downloadInfo.type == TDM372FirmwareUpgradeInfoType_Firmware)
                    upgradeForFirmwareRequired = downloadInfo.upgradeRequired;
                else if (downloadInfo.type == TDM372FirmwareUpgradeInfoType_Activity)
                    upgradeForActivityRequired = downloadInfo.upgradeRequired;
            }
            
            for (NSInteger i = _mFirmwareUpgradeInfo.count - 1; i >= 0; i--)
            {
                TDM372FirmwareUpgradeInfo * downloadInfo = [_mFirmwareUpgradeInfo objectAtIndex: i];
                if (downloadInfo.upgradeRequired == FALSE)
                {
                    if (downloadInfo.type == TDM372FirmwareUpgradeInfoType_Firmware)
                    {
                        if (!upgradeForActivityRequired)
                            [_mFirmwareUpgradeInfo removeObject: downloadInfo];
                    }
                    else if (downloadInfo.type == TDM372FirmwareUpgradeInfoType_Activity)
                    {
                        if (!upgradeForFirmwareRequired)
                            [_mFirmwareUpgradeInfo removeObject: downloadInfo];
                    }
                    else
                        [_mFirmwareUpgradeInfo removeObject: downloadInfo];
                }
            }
            
            if (_mFirmwareUpgradeInfo.count)
            {
                [self handleNewFirmwareVersion: nil];
            }
            else
            {
                [self handleNoNewFirmwareVersion];
            }
        }
        else
        {
            _firmwareVersionOnServer = 0;
            for (TDDatacastFirmwareUpgradeInfo * downloadInfo in _mFirmwareUpgradeInfo)
            {
                if (downloadInfo.type == TDDatacastFirmwareUpgradeInfoType_Firmware)
                {
                    _firmwareVersionOnServer = downloadInfo.version;
                    break;
                }
            }
            
            NSString* noLettersCurrentVersion = [_mReadSettings.mProductRev stringByTrimmingCharactersInSet:[NSCharacterSet letterCharacterSet]];
            NSInteger currVersion = [noLettersCurrentVersion integerValue];
            
            if (_firmwareVersionOnServer > currVersion)
            {
                [self handleNewFirmwareVersion: nil];
            }
            else
            {
                [self handleNoNewFirmwareVersion];
            }
        }
    }
    else
    {
        [self handleNoNewFirmwareVersion];
    }
}

- (void) _upgradeRequiredForM372FirmwareFile: (NSString *) versionOnWatch
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
            NSInteger version = [[self _getVersionSubstring: versionOnWatch] integerValue];
            if (version < downloadInfo.version)
                downloadInfo.upgradeRequired = TRUE;
            break;
        }
    }
}
- (NSString *)_getVersionSubstring: (NSString *)value
{
    NSRange finalRange = NSMakeRange(value.length - 3, 3);
    return [value substringWithRange:finalRange];
}
- (void) handleFirmwareCheckInitiation
{
    //overwrite if necessary
}
- (void) handleNewFirmwareVersion: (NSNotification *) notification
{
    if (notification != nil)
    {
        //if notification parameter is not nill, handleNewFirmwareVersion was launched by
        //kFirmwareRequestUserInitiatedNotification notification
        NSDictionary * userInfo = notification.userInfo;
        _mFirmwareUpgradeInfo = [[NSMutableArray alloc] initWithArray:[userInfo allValues]];
    }
    if ([self viewSupportsFirmwareUpdateHandling])
    {
        if (_mFirmwareUpdateAlert == nil || _mFirmwareUpdateAlert.isVisible == false)
        {

                _mFirmwareUpdateAlert = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"Update Available", nil)
                                                                   message: NSLocalizedString(@"New software is available for your watch. Would you like to download it now?", nil)
                                                                  delegate:self cancelButtonTitle: NSLocalizedString(@"Later", nil) otherButtonTitles:NSLocalizedString(@"Yes", nil), nil ];
                
                [_mFirmwareUpdateAlert show];
        }
    }
}
- (void) handleNoNewFirmwareVersion
{
    //overwrite if necessary
}
- (void) handleErrorDuringFirmwareCheck
{
    //overwrite if necessary
}
- (void) handleFirmwareUpgradeInProgress
{
    //overwrite if necessary
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView == _mFirmwareUpdateAlert)
    {
        if (buttonIndex != _mFirmwareUpdateAlert.cancelButtonIndex)
        {
            _mFirmwareInformationAlert = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"FIRMWARE UPDATE", nil)
                                                                    message: NSLocalizedString(@"You may use other app features or even other apps while the download is in progress.\n\nPlease keep the phone and watch within range until this completes.", nil)
                                                                   delegate:self cancelButtonTitle: NSLocalizedString(@"OK", nil) otherButtonTitles: nil ];
            [_mFirmwareInformationAlert show];
        }
        else
        {
            [self _DeleteDownloadedData];
        }
    }
    else if (alertView == _mFirmwareInformationAlert)
    {
        PeripheralDevice * timexDevice = [iDevicesUtil getConnectedTimexDevice];
        if (timexDevice != nil)
        {
            [timexDevice requestDeviceChargeInfoForFirmware];
        }
    }
    else if (alertView == _mFirmwareUpdateCancelAlert)
    {
        if (buttonIndex != _mFirmwareUpdateCancelAlert.cancelButtonIndex)
        {
            PeripheralDevice * timexDevice = [iDevicesUtil getConnectedTimexDevice];
            if (timexDevice != nil)
            {
                [timexDevice cancelFirmwareUpgrade];
            }
        }
    }
}

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
}
- (void)download:(TCBlobDownloader *)blobDownload
didFinishWithSuccess:(BOOL)downloadFinished
          atPath:(NSString *)pathToFile
{
    BOOL allDone = TRUE;
    
    NSString * downloadedURL = [[blobDownload downloadURL] absoluteString];
    
    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_Metropolitan)
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
            
            
            if (m372StuckInBootloader)
            {
                m372StuckInBootloader = FALSE;
                [self _sendStuckBootloaderFiles];
            }
            else
            {
                /*
                _mFirmwareInformationAlert = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"StepsToUpdateWatchTitle", nil)
                                                                    message: NSLocalizedString(@"StepsToUpdateWatchMessage", nil)
                                                                   delegate:self cancelButtonTitle: NSLocalizedString(NSLocalizedString(@"YesWatchIsInSyncMode", nil), nil) otherButtonTitles: nil ];
                [_mFirmwareInformationAlert show];//TestLog_M372FirmwareUpdateV2_changedTheTitleAndMessage
                 */
            }
        }
    }
    else
    {
        for (TDDatacastFirmwareUpgradeInfo * downloadInfo in _mFirmwareUpgradeInfo)
        {
            if ([downloadInfo.uri isEqualToString: downloadedURL])
            {
                downloadInfo.downloaded = TRUE;
                downloadInfo.pathToDownloadedFile = blobDownload.pathToFile;
                break;
            }
        }
        for (TDDatacastFirmwareUpgradeInfo * downloadInfo in _mFirmwareUpgradeInfo)
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
            
            //done with downloads!
            
            if ([[TDWatchProfile sharedInstance] watchStyle] != timexDatalinkWatchStyle_Metropolitan)
            {
                TDFirmwareUploadStatus * progress = [TDFirmwareUploadStatus sharedInstance: TRUE];
                progress.delegate = self;
                
                progress.progressText = [NSString stringWithFormat: @"%@\n%@", NSLocalizedString(@"Watch firmware download in progress", nil), NSLocalizedString(@"Preparing download...", nil)];
                progress.progressTextWarning = NSLocalizedString(@"We are updating your watch. Keep your watch and phone close together until this is done.", nil);//TestLog_M372FirmwareUpdateV2_addedANewSectionInTheView
                
                [self.view addSubview: progress];
                
                [UIView animateWithDuration: 0.8f animations:^
                 {
                     CGRect frame = progress.frame;
                     frame.origin.y += frame.size.height;
                     progress.frame = frame;
                 }
                                 completion:^(BOOL finished)
                 {
                     PeripheralDevice * timexDevice = [iDevicesUtil getConnectedTimexDevice];
                     if (timexDevice != nil)
                     {
                         TDFlurryDataPacket * dictFlurry = [[TDFlurryDataPacket alloc] initWithValue: [NSNumber numberWithInteger: _firmwareVersionOnServer] forKey: @"Firmware_Sent"];
                         [iDevicesUtil logFlurryEvent: @"FIRMWARE_UPGRADE" withParameters:dictFlurry isTimedEvent: YES];
                         
                         [timexDevice setProgressDialog: progress];
                         [timexDevice doFirmwareUpgrade: _mFirmwareUpgradeInfo];
                     }
                 }];
            }
        }
    }
}

#pragma mark -
- (void)_DeleteDownloadedData
{
    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_Metropolitan)
    {
        for (TDM372FirmwareUpgradeInfo * downloadInfo in _mFirmwareUpgradeInfo)
        {
            if (downloadInfo.downloaded)
            {
                [[NSFileManager defaultManager] removeItemAtPath: downloadInfo.pathToDownloadedFile error: NULL];
            }
        }
    }
    else
    {
        for (TDDatacastFirmwareUpgradeInfo * downloadInfo in _mFirmwareUpgradeInfo)
        {
            if (downloadInfo.downloaded)
            {
                [[NSFileManager defaultManager] removeItemAtPath: downloadInfo.pathToDownloadedFile error: NULL];
            }
        }
    }
    _mFirmwareUpgradeInfo = nil;
}
- (void)FirmwareUpdateCanceled: (NSNotification*)notification
{
    NSMutableDictionary * dictFlurry = [[NSMutableDictionary alloc] init];
    [dictFlurry setValue: [iDevicesUtil convertWatchStyleToProductName: [[TDWatchProfile sharedInstance] watchStyle]] forKey: @"Watch_Product"];
    [dictFlurry setValue: [NSNumber numberWithInteger: _firmwareVersionOnServer] forKey: @"Firmware_Sent"];
    [dictFlurry setValue: [NSNumber numberWithBool: NO] forKey: @"Firmware_Sent_Successfully"];
    [iDevicesUtil endTimedFlurryEvent: @"FIRMWARE_UPGRADE" withParameters:dictFlurry];
    
    //delete the downloaded files....
    [self _DeleteDownloadedData];
    
    //only when we receive confirmation that the firmware has been successfully canceled we can dismiss the progress dialog...
    [[TDFirmwareUploadStatus sharedInstance: FALSE] dismiss];
}
- (void)FirmwareUpdateFailure: (NSNotification*)notification
{
    NSMutableDictionary * dictFlurry = [[NSMutableDictionary alloc] init];
    [dictFlurry setValue: [iDevicesUtil convertWatchStyleToProductName: [[TDWatchProfile sharedInstance] watchStyle]] forKey: @"Watch_Product"];
    [dictFlurry setValue: [NSNumber numberWithInteger: _firmwareVersionOnServer] forKey: @"Firmware_Sent"];
    [dictFlurry setValue: [NSNumber numberWithBool: NO] forKey: @"Firmware_Sent_Successfully"];
    [iDevicesUtil endTimedFlurryEvent: @"FIRMWARE_UPGRADE" withParameters:dictFlurry];
    
    [[TDFirmwareUploadStatus sharedInstance: FALSE] dismiss];
    
    //delete the downloaded files....
    [self _DeleteDownloadedData];
}

- (void)BootloaderFirmwareUpdateComplete: (NSNotification*)notification
{
    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_Metropolitan || [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQ || [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)
    {
        if (_mFirmwareUpgradeInfo && [self _getM372FirmwareUpgradeFileCount])
        {
            [[TDFirmwareUploadStatus sharedInstance: FALSE] dismiss];
            [self performSelector:@selector(successfullyConnectedToM372Watch:) withObject: notification afterDelay: 1.0];
        }
        else
        {
            [self _exitBootloaderModeForM372];
            
            NSMutableDictionary * dictFlurry = [[NSMutableDictionary alloc] init];
            [dictFlurry setValue: [iDevicesUtil convertWatchStyleToProductName: [[TDWatchProfile sharedInstance] watchStyle]] forKey: @"Watch_Product"];
            [dictFlurry setValue: [NSNumber numberWithInteger: _firmwareVersionOnServer] forKey: @"Firmware_Sent"];
            [dictFlurry setValue: [NSNumber numberWithBool: YES] forKey: @"Firmware_Sent_Successfully"];
            [iDevicesUtil endTimedFlurryEvent: @"FIRMWARE_UPGRADE" withParameters:dictFlurry];
            
            [[TDFirmwareUploadStatus sharedInstance: FALSE] dismiss];
            
            //delete the downloaded files....
            [self _DeleteDownloadedData];
            
            [self displayFirmwareUploadSuccessAlert];
        }
    }
}
- (void)FirmwareUpdateComplete: (NSNotification*)notification
{
    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_Metropolitan || [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQ || [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)
    {
        if (_mFirmwareUpgradeInfo && [self _getM372FirmwareUpgradeFileCount])
        {
            OTLog(@"Completed uploading one firmware file... see what else is there");
            
            [self successfullyConnectedToM372Watch: nil];
            
            [[TDFirmwareUploadStatus sharedInstance: FALSE] dismiss];
        }
        else
        {
            [self _softResetWatch];
            
            NSMutableDictionary * dictFlurry = [[NSMutableDictionary alloc] init];
            [dictFlurry setValue: [iDevicesUtil convertWatchStyleToProductName: [[TDWatchProfile sharedInstance] watchStyle]] forKey: @"Watch_Product"];
            [dictFlurry setValue: [NSNumber numberWithInteger: _firmwareVersionOnServer] forKey: @"Firmware_Sent"];
            [dictFlurry setValue: [NSNumber numberWithBool: YES] forKey: @"Firmware_Sent_Successfully"];
            [iDevicesUtil endTimedFlurryEvent: @"FIRMWARE_UPGRADE" withParameters:dictFlurry];
            
            [[TDFirmwareUploadStatus sharedInstance: FALSE] dismiss];
            
            //delete the downloaded files....
            [self _DeleteDownloadedData];
            
            [self displayFirmwareUploadSuccessAlert];
        }
    }
    else
    {
        NSMutableDictionary * dictFlurry = [[NSMutableDictionary alloc] init];
        [dictFlurry setValue: [iDevicesUtil convertWatchStyleToProductName: [[TDWatchProfile sharedInstance] watchStyle]] forKey: @"Watch_Product"];
        [dictFlurry setValue: [NSNumber numberWithInteger: _firmwareVersionOnServer] forKey: @"Firmware_Sent"];
        [dictFlurry setValue: [NSNumber numberWithBool: YES] forKey: @"Firmware_Sent_Successfully"];
        [iDevicesUtil endTimedFlurryEvent: @"FIRMWARE_UPGRADE" withParameters:dictFlurry];
        
        [[TDFirmwareUploadStatus sharedInstance: FALSE] dismiss];
        
        //delete the downloaded files....
        [self _DeleteDownloadedData];
        
        [self displayFirmwareUploadSuccessAlert];
    }
}

- (void) displayFirmwareUploadSuccessAlert
{

    //TestLog_M372FirmwareUpdateV2 start
    //UIAlertView * confirmationAlert = nil;
    
    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_Metropolitan)
    {
        _mFirmwareUpdateSuccessful = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"Firmware Uploaded", nil) message: NSLocalizedString(@"FirmwareUpdateCompleted", nil) delegate:self cancelButtonTitle: NSLocalizedString(@"OK", nil) otherButtonTitles: nil ];
    }
    else
    {
        _mFirmwareUpdateSuccessful = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"Firmware Uploaded", nil) message: NSLocalizedString(@"All firmware files successfully uploaded to watch. Please confirm firmware update on your watch.", nil) delegate:self cancelButtonTitle: NSLocalizedString(@"OK", nil) otherButtonTitles: nil ];
    }
    [_mFirmwareUpdateSuccessful show];
    //TestLog_M372FirmwareUpdateV2 end
}
#pragma mark - TDFirmwareUploadStatusDelegate methods
- (void) cancelFirmwareUpload
{
    _mFirmwareUpdateCancelAlert = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"Cancel Software Update?", nil)
                                                             message: NSLocalizedString(@"Are you sure you want to cancel?", nil)
                                                            delegate:self cancelButtonTitle: NSLocalizedString(@"No", nil) otherButtonTitles:NSLocalizedString(@"Yes", nil), nil ];
    [_mFirmwareUpdateCancelAlert show];
}





#pragma mark -
- (BOOL) _getM372FirmwareUpgradeFileInfoPresenceForType: (TDM372FirmwareUpgradeInfoType) type
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
- (TDM372FirmwareUpgradeInfo *) _getM372FirmwareUpgradeFileInfoForType: (TDM372FirmwareUpgradeInfoType) type
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
- (NSInteger) _getM372FirmwareUpgradeFileCount
{
    NSInteger count = 0;
    
    for (TDM372FirmwareUpgradeInfo * downloadInfo in _mFirmwareUpgradeInfo)
    {
        if (!downloadInfo.processed) count++;
    }
    
    return count;
}
- (void) M372FirmwareUploadWatchChargeInfoRead: (NSNotification*)notification
{
    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_Metropolitan)
    {
        if (_mFirmwareUpgradeInfo && [self _getM372FirmwareUpgradeFileCount])
        {
            PCCommChargeInfo * chargeInfo = [notification.userInfo objectForKey: kDeviceWatchChargeInfoKey];
            if (chargeInfo)
            {
                [[NSUserDefaults standardUserDefaults] setFloat:chargeInfo.voltage forKey:KEY_BATTERRY_CHARGE_M372];

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
                    [self successfullyConnectedToM372Watch: nil];
                }
            }
        }
    }
}
-(void) successfulInitialConnectionToM372Watch:(NSNotification*)notification
{
    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_Metropolitan || [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQ || [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)
    {
        OTLog(@"Initial Successful Connection to M372 watch!");
        
        if (_mFirmwareUpgradeInfo && [self _getM372FirmwareUpgradeFileCount])
        {
            BOOL radioPresent = [self _getM372FirmwareUpgradeFileInfoPresenceForType: TDM372FirmwareUpgradeInfoType_Radio];
            if (radioPresent) //only if we are not in bootloader node
            {
                //request the freaking battery info!
                PeripheralDevice * timexDevice = [iDevicesUtil getConnectedTimexDevice];
                if (timexDevice)
                {
                    [timexDevice performSelector:@selector(requestDeviceChargeInfoForFirmwareM372) withObject:nil afterDelay: 1.0];
                }
            }
            else
            {
                [self successfullyConnectedToM372Watch: notification];
            }
        }
        else
        {
            [self successfullyConnectedToM372Watch: notification];
        }
    }
}
-(void) successfullyConnectedToM372Watch:(NSNotification*)notification
{
    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_Metropolitan || [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQ || [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)
    {
        OTLog(@"Connected to M372 watch!");
        
        //Removed it because auto sync code is allready written in CustomTabBar
        /*if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQ && !self.dontCheck && [TDM328WatchSettingsUserDefaults autoSyncMode])
        {
            int hour = 0;
            int min = 0;
            switch ([TDM328WatchSettingsUserDefaults autoSyncPeriod])
            {
                case 0:
                    hour = (int)[TDM328WatchSettingsUserDefaults autoSyncTimes1_Hour];
                    min = (int)[TDM328WatchSettingsUserDefaults autoSyncTimes1_Minute];
                    break;
                case 1:
                    hour = (int)[TDM328WatchSettingsUserDefaults autoSyncTimes2_Hour];
                    min = (int)[TDM328WatchSettingsUserDefaults autoSyncTimes2_Minute];
                    break;
                case 2:
                    hour = (int)[TDM328WatchSettingsUserDefaults autoSyncTimes3_Hour];
                    min = (int)[TDM328WatchSettingsUserDefaults autoSyncTimes3_Minute];
                    break;
                default:
                    hour = (int)[TDM328WatchSettingsUserDefaults autoSyncTimes4_Hour];
                    min = (int)[TDM328WatchSettingsUserDefaults autoSyncTimes4_Minute];
                    break;
            }
            NSDate *date = [NSDate date];
            NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier: NSCalendarIdentifierGregorian];
            NSDateComponents *components = [calendar components: NSUIntegerMax fromDate: date];
            [components setHour: hour];
            [components setMinute: min - 1];
            [components setSecond: 0];
            NSDate *autoTime = [calendar dateFromComponents:components];
            [components setMinute: min + 1];
            NSDate *autoTime2 = [calendar dateFromComponents:components];
            if ([NSDate date] >= autoTime && [NSDate date] <= autoTime2)
            {
                self.dontCheck = YES;
                [[SyncWatchUtil sharedInstance] startAction];
            }
        }*/
        
        if (_mFirmwareUpgradeInfo && [self _getM372FirmwareUpgradeFileCount])
        {
            TDFirmwareUploadStatus * progress = [TDFirmwareUploadStatus sharedInstance: TRUE];
            progress.delegate = self;
            
            if ([[TDWatchProfile sharedInstance] watchStyle] != timexDatalinkWatchStyle_Metropolitan)
            {
                NSString * firstLine = [NSString stringWithFormat: @"%@ %@", NSLocalizedString(@"Watch firmware download:", nil), [NSString stringWithFormat: NSLocalizedString(@"file %ld of %ld", nil), (_mFirmwareUpgradeInfo.count - [self _getM372FirmwareUpgradeFileCount]) + 1, _mFirmwareUpgradeInfo.count]];
                progress.progressText = [NSString stringWithFormat: @"%@\n%@", firstLine, NSLocalizedString(@"Preparing download...", nil)];
                progress.progressTextWarning = NSLocalizedString(@"We are updating your watch. Keep your watch and phone close together until this is done.", nil);//TestLog_M372FirmwareUpdateV2_addedANewSectionInTheView
                [self.view addSubview: progress];
                
                
                [UIView animateWithDuration: 0.8f animations:^
                 {
                     CGRect frame = progress.frame;
                     frame.origin.y += frame.size.height;
                     progress.frame = frame;
                 }
                                 completion:^(BOOL finished)
                 {
                     //For M372, we need to send the radio file first....
                     TDM372FirmwareUpgradeInfo * radio = [self _getM372FirmwareUpgradeFileInfoForType: TDM372FirmwareUpgradeInfoType_Radio];
                     if (radio)
                     {
                         PeripheralDevice * timexDevice = [iDevicesUtil getConnectedTimexDevice];
                         if (timexDevice)
                         {
                             [timexDevice setProgressDialog: progress];
                             [timexDevice doFirmwareUpgrade: [NSArray arrayWithObject: radio]];
                         }
                     }
                     else
                     {
                         //the rest of the files need top be sent via bootloader mode.... but are we in it already?
                         [self _initiateBootloaderModeStatusCheck];
                     }
                 }];
            }
        }
        else
        {
            if (m372WatchResetRequested)
            {
                double delayInSeconds = 12.0;
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                    HUD.labelText = NSLocalizedString(@"FACTORY RESET", nil);
                    HUD.detailsLabelText = NSLocalizedString(@"Reset Complete", nil);
                });
                delayInSeconds += 3.0;
                popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                    [HUD hide:YES];
                });
                m372WatchResetRequested = FALSE;
                [self _resetWatchAfterDelay: 1.0];
            }
        }
    }
}
- (void) watchDisconnected:(NSNotification*)notification
{
    self.dontCheck = NO;
}

- (void) _connectToM372DeviceForFirmwareUpload
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
            //if (!m372WatchResetRequested)
                //[HUD hide: TRUE];
            m372ReconnectAttempts = 0;
            PeripheralDevice * device = [adverts objectAtIndex: idx];
            if (device != NULL)
            {
                OTLog(@"Attempting to connect to %@...", device.peripheral.UUID.UUIDString);
                [[TDDeviceManager sharedInstance] connect: device];
            }
        }
        else
        {
            m372ReconnectAttempts++;
            if (m372ReconnectAttempts > 15)
            {
                [HUD hide: TRUE];
                
                [self _DeleteDownloadedData];
                
                m372ReconnectAttempts = 0;
                m372WatchResetRequested = FALSE;
                
            }
            else
            {
                
                //Diego_Santiagoartf21277 start
                if (!m372WatchResetRequested)
                    [HUD hide: TRUE];
                
                //HUDWaitingForWatch = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
                //HUDWaitingForWatch.mode = MBProgressHUDModeIndeterminate;
                //HUDWaitingForWatch.detailsLabelText = NSLocalizedString(@"ConnectingToWatch" ,nil);
                //[HUDWaitingForWatch hide:TRUE afterDelay:1.1];

                //Diego_Santiagoartf21277 end

                OTLog(@"Attempting to reconnect...");
                [self performSelector:@selector(_connectToM372DeviceForFirmwareUpload) withObject:nil afterDelay: 1.0];
            }
        }
    }
}
-(void) unexpectedBootloaderModeForM372Detected:(NSNotification*)notification
{
   [[TDFirmwareUploadStatus sharedInstance: FALSE] dismiss];
}
-(void) unexpectedBootloaderModeForM372DetectedAndApproved:(NSNotification*)notification
{
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

-(void) bootloaderModeForM372Requested:(NSNotification*)notification
{
    OTLog(@"Bootloader Command sent.... initiating 10 second wait period");
    [self performSelector:@selector(_connectToM372DeviceForFirmwareUpload) withObject:nil afterDelay: 10.0];
}
- (void) _initiateBootloaderModeStatusCheck
{
    PeripheralDevice * timexDevice = [iDevicesUtil getConnectedTimexDevice];
    if (timexDevice)
    {
        [timexDevice requestDeviceInfoForBootloaderStatus];
    }
}
- (void) _initiateBootloaderModeForM372
{
    HUD = [[MBProgressHUD alloc] initWithView: self.navigationController.view];
    [self.navigationController.view addSubview: HUD];
    
    HUD.labelText = NSLocalizedString(@"Please Wait", nil);
    HUD.detailsLabelText = NSLocalizedString(@"Initiating Bootloader...", nil);
    [HUD show: YES];
    
    PeripheralDevice * timexDevice = [iDevicesUtil getConnectedTimexDevice];
    if (timexDevice)
    {
        [timexDevice startBootloaderForM372];
    }
}
- (void) _exitBootloaderModeForM372
{
    PeripheralDevice * timexDevice = [iDevicesUtil getConnectedTimexDevice];
    if (timexDevice)
    {
        [timexDevice exitBootloaderForM372];
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

- (void) _softResetWatch
{
    PeripheralDevice * timexDevice = [iDevicesUtil getConnectedTimexDevice];
    if (timexDevice)
    {
        [timexDevice softResetM372Watch];
    }
}

- (void) fetchedStuckBootloaderFirmwareInfo: (NSData *)responseData
{
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
            if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_Metropolitan && [moduleName isEqualToString: @"M372"])
            {
                foundJSONmodule = TRUE;
                [self _createFirmwareUpdateInfoArrayForM372: availableModule bootloaderOnly: TRUE];
            }
        }
    }
    
    if (foundJSONmodule)
    {
        //since we are in bootloader mode, we want to send ALL firmware files to ensure that we successfully kick out of bootloader. therefore, do not check for versions
        if (_mFirmwareUpgradeInfo.count)
        {
            [self getBootloaderUnstuck];
        }
        else
        {
            [self handleNoNewFirmwareVersion];
        }
    }
    else
    {
        [self handleNoNewFirmwareVersion];
    }
}
- (void) getBootloaderUnstuck
{
    m372StuckInBootloader = TRUE;
    
    /*
    HUD = [[MBProgressHUD alloc] initWithView: self.navigationController.view];
    [self.navigationController.view addSubview: HUD];
    
    HUD.labelText = NSLocalizedString(@"Please Wait", nil);
    HUD.detailsLabelText = NSLocalizedString(@"Downloading Firmware Update...", nil);
    HUD.square = YES;
    HUD.mode = MBProgressHUDModeDeterminateHorizontalBar;
     */
    
    [HUD show: YES];
    
    NSString * tempDir = NSTemporaryDirectory();
    NSString * newDir = [tempDir stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]];
    [[NSFileManager defaultManager] createDirectoryAtPath:newDir withIntermediateDirectories: NO attributes: nil error: nil];
    for (TDM372FirmwareUpgradeInfo * downloadInfo in _mFirmwareUpgradeInfo)
    {
        [[TCBlobDownloadManager sharedInstance] startDownloadWithURL:[NSURL URLWithString: downloadInfo.uri] customPath: newDir delegate: self];
    }
}

- (void) _sendStuckBootloaderFiles
{
    TDFirmwareUploadStatus * progress = [TDFirmwareUploadStatus sharedInstance: TRUE];
    progress.delegate = self;
    
    if ([[TDWatchProfile sharedInstance] watchStyle] != timexDatalinkWatchStyle_Metropolitan)
    {
        NSString * firstLine = [NSString stringWithFormat: @"%@ %@", NSLocalizedString(@"Watch firmware download:", nil), [NSString stringWithFormat: NSLocalizedString(@"file %ld of %ld", nil), (_mFirmwareUpgradeInfo.count - [self _getM372FirmwareUpgradeFileCount]) + 1, _mFirmwareUpgradeInfo.count]];
        progress.progressText = [NSString stringWithFormat: @"%@\n%@", firstLine, NSLocalizedString(@"Preparing download...", nil)];
        progress.progressTextWarning = NSLocalizedString(@"We are updating your watch. Keep your watch and phone close together until this is done.", nil);
        //TestLog_M372FirmwareUpdateV2_addedANewSectionInTheView
        
        [self.view addSubview: progress];
        
        [UIView animateWithDuration: 0.8f animations:^
         {
             CGRect frame = progress.frame;
             frame.origin.y += frame.size.height;
             progress.frame = frame;
         }
                         completion:^(BOOL finished)
         {
             [self _sendBootloaderFiles];
         }];
    }
}

- (void) _createFirmwareUpdateInfoArrayForM372: (NSDictionary *) availableModule bootloaderOnly: (BOOL) blOnly
{
    //record that we have done a SUCCESSFUL firmware update  check today
    [[NSUserDefaults standardUserDefaults] setObject: [NSDate date] forKey: kLAST_FIRMWARE_CHECK_DATE];
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
@end
