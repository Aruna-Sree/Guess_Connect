//
//  TDFactoryResetViewController.m
//  timex
//
//  Created by Raghu on 06/03/17.
//  Copyright © 2017 iDevices, LLC. All rights reserved.
//

#import "TDFactoryResetViewController.h"
#import "MBProgressHUD.h"
#import "iDevicesUtil.h"
#import "TDDefines.h"
#import "OTLogUtil.h"
#import "TDDeviceManager.h"
#import "TDWatchProfile.h"
#import "DBManager.h"
#import "TimexWatchDB.h"
#import "TDFlurryDataPacket.h"
#import "TDAppDelegate.h"
#import "SideMenuViewController.h"
#import "MFSideMenuContainerViewController.h"

@interface TDFactoryResetViewController ()

@end

@implementation TDFactoryResetViewController
{
    int watchFrame;
    NSInteger mReconnectAttempts;
    BOOL isConnectCalled;
    MBProgressHUD   *  HUD;
    UIButton *backBtn;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"FACTORY RESET", nil) ;
    
    NSDictionary * navBarTitleTextAttributes =  @{NSFontAttributeName : [UIFont fontWithName:[iDevicesUtil getAppWideBoldFontName] size:APP_HEADER_FONT_SIZE] };
    self.navigationController.navigationBar.titleTextAttributes = navBarTitleTextAttributes;
    
    backBtn = [iDevicesUtil getBackButton];
    [backBtn addTarget:self action:@selector(backButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barBtn = [[UIBarButtonItem alloc] initWithCustomView:backBtn];
    self.navigationItem.leftBarButtonItem = barBtn;
    
    
    syncLbl.attributedText = [self getAttributedStrWithText:NSLocalizedString(@"Activate sync mode.",nil) formatStr:[NSString stringWithFormat:@"%@",NSLocalizedString(@"\n\nPress and hold the Push Button until the upper dial points to Bluetooth symbol, then release the button",nil)]];
    
    
    
    checkmarkImage.image = [checkmarkImage.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [checkmarkImage setTintColor:[UIColor blackColor]];
    
    [self reconnectToDevice];
    watchFrame = 0;
    
    [self addObservers];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self removeObservers];
}

-(void)addObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(successfullyConnectedToDevice:) name: kPeripheralDeviceTimexDatalinkPrimaryCharacteristicDiscovered object: nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(watchDisconnected:) name:kPeripheralDeviceAuthorizationFailedNotification object: nil];
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
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Delete All Data",nil) message:NSLocalizedString(@"Do you want to delete or save existing data?",nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Delete",nil) otherButtonTitles:NSLocalizedString(@"Save",nil), nil];
    alert.tag = 1;
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    
}

- (void)reconnectToDevice
{
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
            //if (!m372WatchResetRequested)
            //[HUD hide: TRUE];
            mReconnectAttempts = 0;
            PeripheralDevice * device = [adverts objectAtIndex: idx];
            if (device != NULL)
            {
                OTLog(@"Attempting to connect to %@...", device.peripheral.UUID.UUIDString);
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
