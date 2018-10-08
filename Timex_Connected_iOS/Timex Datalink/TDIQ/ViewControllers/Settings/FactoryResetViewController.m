//
//  FactoryResetViewController.m
//  timex
//
//  Created by Nick Graff on 1/12/17.
//  Copyright © 2017 iDevices, LLC. All rights reserved.
//

#import "FactoryResetViewController.h"
#import "TDM328WatchSettingsUserDefaults.h"
#import "OTLogUtil.h"
#import "TDDeviceManager.h"
#import "TDWatchProfile.h"
#import "TimexWatchDB.h"
#import "SideMenuViewController.h"
#import "TDAppDelegate.h"
#import "MFSideMenuContainerViewController.h"
#import "TDFlurryDataPacket.h"
#import "DBManager.h"
#import "MBProgressHUD.h"

@interface FactoryResetViewController ()
{
    int watchFrame;
    NSTimer *animation;
    NSInteger mReconnectAttempts;
    BOOL isConnectCalled;
    MBProgressHUD   *  HUD;
    UIButton *backBtn;
}
@end

@implementation FactoryResetViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    self.title = NSLocalizedString(@"FACTORY RESET", nil) ;
    
    NSDictionary * navBarTitleTextAttributes =  @{NSFontAttributeName : [UIFont fontWithName:[iDevicesUtil getAppWideBoldFontName] size:APP_HEADER_FONT_SIZE] };
    self.navigationController.navigationBar.titleTextAttributes = navBarTitleTextAttributes;

    backBtn = [iDevicesUtil getBackButton];
    [backBtn addTarget:self action:@selector(backButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barBtn = [[UIBarButtonItem alloc] initWithCustomView:backBtn];
    self.navigationItem.leftBarButtonItem = barBtn;
    
    
    syncLbl.attributedText = [self getAttributedStrWithText:NSLocalizedString(@"Activate sync mode.",nil) formatStr:[NSString stringWithFormat:@"\n\n%@",NSLocalizedString(@"To enter sync mode, press and hold the Crown for about 5 seconds until you hear a 3 tone melody. Once in sync mode, the hands should point to 12.",nil)]];
    
    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)
    {
        watchSetup.image = [UIImage imageNamed:@"TravelSetup"];
    }
    
    checkmarkImage.image = [checkmarkImage.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [checkmarkImage setTintColor:[UIColor blackColor]];
    
    [self reconnectToDevice];
    watchFrame = 0;
    animation = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(watchAnimation) userInfo:nil repeats:YES];
    
    [self addObservers];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    TDAppDelegate *appdel = (TDAppDelegate *)[[UIApplication sharedApplication] delegate];
    appdel.customTabbar.autoSyncAllowed = NO;
}
-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [animation invalidate];
    mReconnectAttempts = 31;
    [self removeObservers];
    TDAppDelegate *appdel = (TDAppDelegate *)[[UIApplication sharedApplication] delegate];
    appdel.customTabbar.autoSyncAllowed = YES;
}

-(void)addObservers
{
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(successfullyConnectedToDevice:) name: kPeripheralDeviceTimexDatalinkPrimaryCharacteristicDiscovered object: nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(watchDisconnected:) name:kPeripheralDeviceAuthorizationFailedNotification object:nil];
}

-(void)removeObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kPeripheralDeviceTimexDatalinkPrimaryCharacteristicDiscovered object: nil];
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kPeripheralDeviceAuthorizationFailedNotification object: nil];
}

- (NSAttributedString *)getAttributedStrWithText:(NSString *)textStr formatStr:(NSString *)formatStr {
    
    UIFont *textFont = [UIFont fontWithName:[iDevicesUtil getAppWideMediumFontName] size:M328_REGISTRATION_TITLE_FONTSIZE];
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:textFont, NSFontAttributeName, [UIColor blackColor],NSForegroundColorAttributeName, nil];
    NSMutableAttributedString *textAtrStr = [[NSMutableAttributedString alloc] initWithString:textStr attributes:dict];
    
    UIFont *formatFont = [UIFont fontWithName: [iDevicesUtil getAppWideMediumFontName] size:M328_WELCOME_INFO_FONTSIZE];
    NSDictionary *atrsDict = [NSDictionary dictionaryWithObjectsAndKeys:formatFont, NSFontAttributeName, UIColorFromRGB(COLOR_DEFAULT_TIMEX_FONT),NSForegroundColorAttributeName, nil];
    NSMutableAttributedString *formatAtrStr = [[NSMutableAttributedString alloc] initWithString:formatStr attributes:atrsDict];
    
    NSString *searchstring = NSLocalizedString(@"Crown", nil) ;
    NSString *anotherSearchstring = NSLocalizedString(@"3 tone melody.", nil) ;;
    NSRange foundRange = [formatStr rangeOfString:searchstring];
    NSRange foundAnotherRange = [formatStr rangeOfString:anotherSearchstring];
    if (foundRange.length > 0 || foundAnotherRange.length > 0) {
        UIFont *font = [UIFont fontWithName: [iDevicesUtil getAppWideMediumFontName] size:M328_WELCOME_INFO_FONTSIZE];
        NSDictionary *higDict = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, [UIColor blackColor],NSForegroundColorAttributeName, nil];
        if (foundRange.length > 0)
            [formatAtrStr addAttributes:higDict range:foundRange];
        if (foundAnotherRange.length > 0)
            [formatAtrStr addAttributes:higDict range:foundAnotherRange];
    }
    
    [textAtrStr appendAttributedString:formatAtrStr];

    return textAtrStr;
}

-(void) backButtonTapped
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)okTap:(id)sender
{
    [self deleteDataAlert];
}
- (void)deleteDataAlert
{
    [TDM328WatchSettingsUserDefaults setSyncNeeded:NO];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Delete All Data",nil) message:NSLocalizedString(@"Do you want to delete or save existing data?",nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Delete",nil) otherButtonTitles:NSLocalizedString(@"Save",nil), nil];
    alert.tag = 1;
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 1) {
        OTLog(@"WATCHED REMOVED CALLED AT Settings ViewController with alertviewaction");
        if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"Delete",nil)])
        {
            //database cleanup
            [DBManager deleteAll];
        }
        
        PeripheralDevice * connectedDevice = [iDevicesUtil getConnectedTimexDevice];
        if (connectedDevice != nil)
        {
            [[TDDeviceManager sharedInstance] forgetAndDisconnect: connectedDevice];
        }
        
        [[TDWatchProfile sharedInstance] setActiveProfile: FALSE];
        [[TDWatchProfile sharedInstance] commitChangesToDatabase];
        OTLog(@"Setting active profile to false so that it will bring us choose watch screen SettingsViewController.m");
        [TDM328WatchSettingsUserDefaults removeResets];
        
        // Removing DB file : Aruna
        NSString * sourceDbName = @"timexDatalinkDB.db";
        NSString * dbPath = [[[TimexWatchDB sharedInstance] getDataPath] stringByAppendingPathComponent:sourceDbName];
        BOOL dbExists = [[TimexWatchDB sharedInstance] doesFileExist: dbPath];
        if (dbExists) {
            [[NSFileManager defaultManager] removeItemAtPath:dbPath error:nil];
        }
        
        [TDWatchProfile resetSharedInstance]; //to force reinitialization
        
        [[TimexWatchDB sharedInstance] createBlankDatabase : dbPath];
        
        [(TimexWatchDB *)[TimexWatchDB sharedInstance] init : dbPath];
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults removeObjectForKey: kCONNECTED_DEVICE_UUID_PREF_NAME];
        //Mantis 309
        [userDefaults setBool: FALSE forKey: kBLEandBTCPairingConfirmed];
        //TestLog_sleepFiles
        [userDefaults removeObjectForKey:@USERID_USERDEFAULT];
        [userDefaults removeObjectForKey:@ALL_THE_DATA_IN_EPOCHS];
        [userDefaults removeObjectForKey:@DATA_DATAIL_BY_DAY];
        [userDefaults removeObjectForKey:@DAYS_READ_BEFORE];
        [userDefaults removeObjectForKey:@FIRST_SYNC];
        [userDefaults removeObjectForKey:@"kLAST_FIRMWARE_CHECK_DATE_NEW"];
        [userDefaults removeObjectForKey:@"NotificaitonDismissedDates"];
        
        //M328 defaults need to remove
        [self removeM328WatchSettingsInfo];
        
        //Mantis 309
        TDFlurryDataPacket * dictFlurry = [[TDFlurryDataPacket alloc] init];
        [iDevicesUtil logFlurryEvent: @"WATCH_REMOVED" withParameters: dictFlurry isTimedEvent:NO];
        
        TDAppDelegate * delegate = (TDAppDelegate *)[UIApplication sharedApplication].delegate;
        [(SideMenuViewController *)((MFSideMenuContainerViewController *)delegate.window.rootViewController).leftMenuViewController goToMain];
        [delegate.customTabbar removeObserversTosync];
        [delegate.customTabbar removeDevicesChangedNotificaiton];
        delegate.customTabbar = nil;
        
        watchFrame = 0;
        [animation invalidate];
        animation = nil;
        
        UIAlertController *forgetWatch = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Make sure to \"Forget This Device\"", nil)
                                                                             message:NSLocalizedString(@"The watch remains paired with your phone until you remove it from Bluetooth settings.", nil)
                                                                      preferredStyle:UIAlertControllerStyleAlert];
        
        [forgetWatch addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                        style:UIAlertActionStyleCancel
                                                      handler:^(UIAlertAction * _Nonnull action){}]];
        
        [forgetWatch addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Settings", nil)
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * _Nonnull action)
                                {
                                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
//                                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"App-Prefs:root=Bluetooth"]];
                                }]];
        
        [self presentViewController:forgetWatch animated:YES completion:nil];
    }
}
-(void)removeM328WatchSettingsInfo
{
    [TDM328WatchSettingsUserDefaults removeM328WatchSettings];
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

- (void)reconnectToDevice
{
    //first, we need to CONNECT to the device again... and not just A device, but THE device
    NSString * deviceUUID = [[NSUserDefaults standardUserDefaults] objectForKey: kCONNECTED_DEVICE_UUID_PREF_NAME];
    if (deviceUUID != nil)
    {
        syncView.hidden = NO;
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
                isConnectCalled = YES;
            }
        }
        else
        {
            mReconnectAttempts++;
            if (mReconnectAttempts > 30)
            {
                mReconnectAttempts = 0;
                
                [self failedToConnectToDevice];
            }
            else
            {
                OTLog(@"Attempting to reconnect...");
                [self performSelector:@selector(reconnectToDevice) withObject:nil afterDelay: 1.0];
            }
        }
    }
}

-(void) successfullyConnectedToDevice:(NSNotification*)notification
{
    if (!isConnectCalled) {
        return;
    }
    isConnectCalled = NO;
    if (HUD == nil)
    {
        HUD = [[MBProgressHUD alloc] initWithView: self.navigationController.view];
        [self.navigationController.view addSubview: HUD];
    }
    
    HUD.labelText = NSLocalizedString(@"Please Wait", nil);
    HUD.detailsLabelText = NSLocalizedString(@"Requesting Watch Reset...", nil);
    HUD.square = YES;
    HUD.mode = MBProgressHUDModeIndeterminate;
    
    [HUD show: YES];
    
    [checkmarkImage setHidden:YES];
    [resetCompleteLabel setHidden:YES];
    
    [syncView setHidden:YES];
    [syncViewActivityIndicator stopAnimating];
    
    [animation invalidate];
    animation = nil;
    watchFrame = 0;
    
    [self performSelector:@selector(resetWatch) withObject:nil afterDelay:2];
}

- (void)watchDisconnected:(NSNotification *)notification
{
    HUD.labelText = NSLocalizedString(@"FACTORY RESET", nil);
    HUD.detailsLabelText = NSLocalizedString(@"Reset Complete", nil);
    
    [checkmarkImage setHidden:NO];
    [resetCompleteLabel setHidden:NO];
    
    [backBtn setHidden:YES];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        [HUD hide:YES];
    });
}

-(void)resetWatch
{
    PeripheralDevice * timexDevice = [iDevicesUtil getConnectedTimexDevice];
    if (timexDevice)
    {
        [timexDevice resetM372Watch];
    }
}

-(void)failedToConnectToDevice
{
    
    UIAlertController *syncFailAlert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil)
                                                        message:NSLocalizedString(@"There was a problem when trying to connect to your watch.", nil)
                                                 preferredStyle:UIAlertControllerStyleAlert];
    
    [syncFailAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                      style:UIAlertActionStyleCancel
                                                    handler:^(UIAlertAction * _Nonnull action)
                              {
                                  
                              }]];
    
    [syncFailAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Try Again", nil)
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction * _Nonnull action)
                              {
                                  OTLog(@"clickedOnTryAgain");
                                  [self reconnectToDevice];
                              }]];
    
    [self presentViewController:syncFailAlert animated:YES completion:nil];
}
@end
