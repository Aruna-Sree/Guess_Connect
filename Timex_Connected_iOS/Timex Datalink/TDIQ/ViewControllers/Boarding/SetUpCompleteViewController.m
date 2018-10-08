//
//  SetUpCompleteViewController.m
//  Timex
//
//  Created by kpasupuleti on 5/4/16.
//

#import "SetUpCompleteViewController.h"
#import "TDAppDelegate.h"
#import "iDevicesUtil.h"
#import "TDDefines.h"
#import "CalibrationClass.h"
#import "TDHomeViewController.h"
#import "TDWatchProfile.h"
#import "TDDeviceManager.h"
#import "OTLogUtil.h"
#import "TDM328WatchSettingsUserDefaults.h"
@interface SetUpCompleteViewController () {
    BOOL calibrationSkipped;
}

@end

@implementation SetUpCompleteViewController
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil skippedCalibration:(BOOL)isSkipped {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        calibrationSkipped = isSkipped;
    }
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    if (!calibrationSkipped) {
        [self exitSyncModeManually];
    }
    else
    {
        [self didStartFileAccessSession:nil];
    }
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))  {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    self.navigationItem.hidesBackButton = TRUE;
    
    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)
    {
        infoLabel.attributedText = [self getRegistrationAttributedStrWithText:NSLocalizedString(@"Congratulations!",nil) formatStr:NSLocalizedString(@"\n\nYou're ready to start tracking steps, distance, calories, and sleep with your iQ+ Travel.",nil)];
    }
    else
    {
        infoLabel.attributedText = [self getRegistrationAttributedStrWithText:NSLocalizedString(@"Congratulations!",nil) formatStr:NSLocalizedString(@"\n\nYou're ready to start tracking steps, distance, calories, and sleep with your Guess iQ+.",nil)];
    }
    
    [nexButton setTitle:[NSString stringWithFormat:@"%@  ", NSLocalizedString(nexButton.currentTitle, nil)] forState:UIControlStateNormal];
    nexButton.transform = CGAffineTransformMakeScale(-1.0, 1.0);
    nexButton.titleLabel.transform = CGAffineTransformMakeScale(-1.0, 1.0);
    nexButton.imageView.transform = CGAffineTransformMakeScale(-1.0, 1.0);
    [nexButton setTitleColor:UIColorFromRGB(AppColorRed) forState:UIControlStateNormal];
    nexButton.tintColor = UIColorFromRGB(AppColorRed);
    
    [remeberToSyncLabel setText:NSLocalizedString(remeberToSyncLabel.text, nil)];
    remeberToSyncLabel.font = [UIFont fontWithName:[iDevicesUtil getAppWideMediumFontName] size:(M328_REGISTRATION_INFO_FONTSIZE-3)];
    if (IS_IPAD) {
        infoLblTopConstraint.constant = 70;
        leftConstraint.constant = 60;
        bottomViewTopContraint.constant = 100;
    }
    infoLblBottomContraint.constant = ((ScreenHeight)/2) - 70 - M328_REGISTRATION_BOTTOM_CONSTRAINT_MINUSVALUE;
    
    progressLbl.backgroundColor = UIColorFromRGB(AppColorRed);
    progressLblWidthContraint.constant = ScreenWidth * ([iDevicesUtil getProgressBarValueBasedOnRegistrationEnum:setupComplete]);
    
    //Put sensor and adjustment to defaults
    [TDM328WatchSettingsUserDefaults setSensorSensitivity:M328_Default_AccelSensitivity];
    [TDM328WatchSettingsUserDefaults setDistanceAdjustment:M328_Default_DistanceAdjustment];
    

    [self performSelector:@selector(tickButtonTapped:) withObject:nil afterDelay:20];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationItem.titleView = [iDevicesUtil getNavigationTitle];
    self.navigationItem.hidesBackButton = YES;
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
        if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel || !calibrationSkipped)
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
    if(timexDevice)
    {
        [timexDevice endFileAccessSession];
    }
}

- (NSAttributedString *)getRegistrationAttributedStrWithText:(NSString *)textStr formatStr:(NSString *)formatStr {
    
    UIFont *textFont = [UIFont fontWithName:[iDevicesUtil getAppWideMediumFontName] size:M328_REGISTRATION_TITLE_FONTSIZE];
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:textFont, NSFontAttributeName, [UIColor blackColor],NSForegroundColorAttributeName, nil];
    NSMutableAttributedString *textAtrStr = [[NSMutableAttributedString alloc] initWithString:textStr attributes:dict];
    
    UIFont *formatFont = [UIFont fontWithName: [iDevicesUtil getAppWideFontName] size: M328_REGISTRATION_INFO_FONTSIZE];
    NSDictionary *atrsDict = [NSDictionary dictionaryWithObjectsAndKeys:formatFont, NSFontAttributeName, UIColorFromRGB(COLOR_DEFAULT_TIMEX_FONT),NSForegroundColorAttributeName, nil];
    NSAttributedString *formatAtrStr = [[NSAttributedString alloc] initWithString:formatStr attributes:atrsDict];
    [textAtrStr appendAttributedString:formatAtrStr];
    
    return textAtrStr;
}

- (void)didReceiveMemoryWarning {
     OTLog([NSString stringWithFormat:@"Recived Memory Warning  in %@ ",NSStringFromClass([self class])]);
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) AssignNewControllerToCenterController: (TDRootViewController *) newController
{
    UINavigationController *navigationController = self.navigationController;
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    NSArray *controllers = [NSArray arrayWithObject: newController];
    navigationController.viewControllers = controllers;
}

- (IBAction)tickButtonTapped:(id)sender {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[TDWatchProfile sharedInstance] commitChangesToDatabase];
        
    TDHomeViewController *mainControllerIQMove;
    
    mainControllerIQMove = [[TDHomeViewController alloc]initWithNibName:@"TDHomeViewController" bundle:nil doFirmwareCheck:TRUE initialSync:YES];
    
    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)
    {
        mainControllerIQMove = [[TDHomeViewController alloc]initWithNibName:@"TDTravelHomeViewController" bundle:nil doFirmwareCheck:TRUE initialSync:YES];
    }
    
    [self AssignNewControllerToCenterController: mainControllerIQMove];
}


@end
