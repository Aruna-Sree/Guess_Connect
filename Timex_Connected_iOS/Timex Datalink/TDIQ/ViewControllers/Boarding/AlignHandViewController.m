//
//  AlignSubDialHandViewController.m
//  Timex
//
//  Created by kpasupuleti on 5/4/16.
//

#import "AlignHandViewController.h"
#import "SetUpCompleteViewController.h"
#import "iDevicesUtil.h"
#import "TDDefines.h"
#import "TDAppDelegate.h"
#import "CalibrationClass.h"
#import "CalibrateCell.h"
#import "TDM328WatchSettingsUserDefaults.h"
#import "TDDeviceManager.h"
#import "CalibratingWatchViewController.h"
#import "TDHomeViewController.h"
#import "SettingsViewController.h"
#import "TDWatchProfile.h"
#import "MFSideMenuContainerViewController.h"

#define FIVE_STEPS 20
#define ONE_STEP 1
#define LONG_PRESS_TIMER_VALUE 0.25
#define SINGLE_PRESS_TIME_VALUE 0.1

@interface AlignHandViewController () {
    enum Hand_Type viewType;

    NSInteger currentSelectedValue;
    
    IBOutlet UIButton *minusBtn;
    IBOutlet UIButton *plusBtn;
    
    int numberOfRows;
    NSTimer *timer;
    BOOL doOnce;
    CalibrationClass *calibrationObject;
    BOOL isCalibrationFinished;
}

@end

@implementation AlignHandViewController
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil viewType:(int)handType {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        viewType = (Hand_Type)handType;
    }
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))  {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    // Newly Added
    self.navigationItem.titleView = [iDevicesUtil getNavigationTitle];
    minusBtn.hidden = NO;

    [_nextBtn setTitle:[NSString stringWithFormat:@"%@  ", NSLocalizedString(@"NEXT", nil)] forState:UIControlStateNormal];
    _nextBtn.transform = CGAffineTransformMakeScale(-1.0, 1.0);
    _nextBtn.titleLabel.transform = CGAffineTransformMakeScale(-1.0, 1.0);
    _nextBtn.imageView.transform = CGAffineTransformMakeScale(-1.0, 1.0);
    [_nextBtn setTitleColor:UIColorFromRGB(AppColorRed) forState:UIControlStateNormal];
    _nextBtn.tintColor = UIColorFromRGB(AppColorRed);
    
     if (viewType == Hand_Hour) {
         
         infoLabel.attributedText = [self getAttributedStrWithText:NSLocalizedString(@"Align the hour hand to twelve",nil) formatStr:NSLocalizedString(@"\n\nTap the on-screen buttons to move the hand one increment,or hold it to move the hand continuously.",nil) andHighlightText:NSLocalizedString(@"hour",nil)];
         [headerImg setImage:[UIImage imageNamed:@"Hour"]];

        numberOfRows = M328_HourHandRows;
        
        
     } else if (viewType == Hand_Minute) {
         infoLabel.attributedText = [self getAttributedStrWithText:NSLocalizedString(@"Align the minute hand to twelve",nil) formatStr:NSLocalizedString(@"\n\nTap the on-screen buttons to move the hand one increment,or hold it to move the hand continuously.",nil) andHighlightText:NSLocalizedString(@"minute",nil)];
         [headerImg setImage:[UIImage imageNamed:@"Minute"]];
         numberOfRows = M328_MinuteHandRows;
         
        
    } else if (viewType == Hand_Second) {
        infoLabel.attributedText = [self getAttributedStrWithText:NSLocalizedString(@"Align the second hand to twelve",nil) formatStr:NSLocalizedString(@"\n\nTap the on-screen buttons to move the hand one increment,or hold it to move the hand continuously.",nil) andHighlightText:NSLocalizedString(@"second",nil)];
        [headerImg setImage:[UIImage imageNamed:@"Second"]];
        numberOfRows = M328_SecondHandRows;
        minusBtn.hidden = YES;
    } else if (viewType == Hand_SubDial) {
        
        infoLabel.attributedText = [self getAttributedStrWithText:NSLocalizedString(@"Align the sub-dial hand to zero",nil) formatStr:NSLocalizedString(@"\n\nTap the on-screen buttons to move the hand one increment,or hold it to move the hand continuously.",nil) andHighlightText:NSLocalizedString(@"sub-dial",nil)];
        [headerImg setImage:[UIImage imageNamed:@"Subdial"]];
        numberOfRows = M328_SubdialHandRows;
        
        if (!self.isFromSetup) { // Placing done button when calibraiton is from settings screen
            [self.nextBtn setTitle:NSLocalizedString(@"DONE",nil) forState:UIControlStateNormal];
            [self.nextBtn setImage:nil forState:UIControlStateNormal];
            self.nextBtn.titleEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 25);
        }
    }
    
    if (IS_IPAD) {
        infoLblTopConstraint.constant = 70;
        infoLblleftConstraint.constant = infoLblRightConstraint.constant = 60;
        infoLblRightConstraint.constant = 60;
    } else {
        infoLblleftConstraint.constant = infoLblRightConstraint.constant = 40;
        if (ScreenHeight <= 568) {
            infoLblleftConstraint.constant = infoLblRightConstraint.constant = 10;
        }
    }
    infoLblBottomContraint.constant = ((ScreenHeight)/2) - 70 - M328_REGISTRATION_BOTTOM_CONSTRAINT_MINUSVALUE;
    
    progressLbl.backgroundColor = UIColorFromRGB(AppColorRed);
    progressLblWidthContraint.constant = ScreenWidth * ([iDevicesUtil getProgressBarValueBasedOnRegistrationEnum:callibrateWatch]);
    
    
    
//    if (IS_IPAD) {
//        nextButtonBottomContraint.constant = 40;
//        viewWidthContraint.constant = (ScreenWidth-260);
//    }
    if (viewType != Hand_Hour) {
    UIButton *backBtn = [iDevicesUtil getBackButton];
    [backBtn addTarget:self action:@selector(backButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barBtn = [[UIBarButtonItem alloc] initWithCustomView:backBtn];
    self.navigationItem.leftBarButtonItem = barBtn;
    }else{
        self.navigationItem.hidesBackButton = TRUE;
    }
    
    [progressLbl setHidden:(_isFromSetup) ? NO : YES];
    
    [self addLongPressGesturesToBtns];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(watchDisconnected:) name:kDeviceManagerDeviceLostConnectiondNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(watchDisconnected:) name:kPeripheralDeviceAuthorizationFailedNotification object: nil];
    TDAppDelegate *appdel = (TDAppDelegate *)[[UIApplication sharedApplication] delegate];
    appdel.customTabbar.autoSyncAllowed = NO;
    
    ((MFSideMenuContainerViewController *)appdel.window.rootViewController).panMode = MFSideMenuPanModeNone;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated]; // Calling super method.
    calibrationObject = [CalibrationClass sharedInstance];
    calibrationObject.motorType = viewType;
    calibrationObject.steps = 1;
}

-(void)viewDidDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kDeviceManagerDeviceLostConnectiondNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kPeripheralDeviceAuthorizationFailedNotification object: nil];
}

#pragma  mark Button Actions
- (void) backButtonTapped {
    
    if(!isCalibrationFinished)
        [self.navigationController popViewControllerAnimated:YES];
    
}

- (IBAction)nextButtonAction:(id)sender {
    if (timer) {
        [timer invalidate];
        timer = nil;
    }
//    TDAppDelegate *del = (AppDelegate *)[[UIApplication sharedApplication] delegate];
//    Calibration *cal = [del fetchCalibrateOfType:type];

    if (viewType == Hand_Hour) {
        AlignHandViewController *alignHourHand=[[AlignHandViewController alloc] initWithNibName:@"AlignHandViewController" bundle:nil viewType:Hand_Minute];
        alignHourHand.isFromSetup = self.isFromSetup;
        [self.navigationController pushViewController:alignHourHand animated:YES];
    } else if (viewType == Hand_Minute) {
        AlignHandViewController *alignSubdialHand=[[AlignHandViewController alloc] initWithNibName:@"AlignHandViewController" bundle:nil viewType:Hand_Second];
          alignSubdialHand.isFromSetup = self.isFromSetup;
        [self.navigationController pushViewController:alignSubdialHand animated:YES];
    } else if (viewType == Hand_Second) {
        AlignHandViewController *alignSubdialHand=[[AlignHandViewController alloc] initWithNibName:@"AlignHandViewController" bundle:nil viewType:Hand_SubDial];
          alignSubdialHand.isFromSetup = self.isFromSetup;
        [self.navigationController pushViewController:alignSubdialHand animated:YES];
    } else if (viewType == Hand_SubDial) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:kDeviceManagerDeviceLostConnectiondNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:kPeripheralDeviceAuthorizationFailedNotification object: nil];
        if ([TDM328WatchSettingsUserDefaults resetWarning])
        {
            [TDM328WatchSettingsUserDefaults isResetWarning:0];
            [TDM328WatchSettingsUserDefaults setNumOfWarnings:(int)[TDM328WatchSettingsUserDefaults numOfWarnings] + 1];
        }
        
        if ([TDM328WatchSettingsUserDefaults numberOfCalibrations] && [TDM328WatchSettingsUserDefaults numberOfCalibrations] % 2 == 0)
        {
            [[CalibrationClass sharedInstance] exitCalibrationMode];
            isCalibrationFinished = YES;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [self exitSyncModeManually];
                ((MFSideMenuContainerViewController *)(TDAppDelegate *)[[UIApplication sharedApplication] delegate].window.rootViewController).panMode = MFSideMenuPanModeDefault;
            });
            warningLbl.attributedText = [self getAttributedStrWithText:NSLocalizedString(@"Something seems off...",nil) formatStr:NSLocalizedString(@"\n\nYou're realigning the watch hands quite a bit.",nil) andHighlightText:NSLocalizedString(@"",nil)];
            headerImg.image = [UIImage imageNamed:@"ErrorLvl1"];
            warningView.hidden = NO;
        }
        else
        {
            [self goToNextController];
        }
    }
}

- (void)goToNextController
{
    [[CalibrationClass sharedInstance] exitCalibrationMode];
    isCalibrationFinished = YES;
    NSLog(@"Calibration exited");
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[iDevicesUtil getConnectedTimexDevice] endFileAccessSession];
    });
    
    _nextBtn.userInteractionEnabled = NO;
    double delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        //code to be executed on the main queue after delay
        
        [self exitSyncModeManually];
        
        ((MFSideMenuContainerViewController *)(TDAppDelegate *)[[UIApplication sharedApplication] delegate].window.rootViewController).panMode = MFSideMenuPanModeDefault;
        
        [self continueAfterWatchExitSyncMode];
    });
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
        if (self.isFromSetup)
        {
            SetUpCompleteViewController *setUpComplete = [[SetUpCompleteViewController alloc] initWithNibName:@"SetUpCompleteViewController" bundle:nil skippedCalibration:NO];
            [self.navigationController pushViewController:setUpComplete animated:YES];
        }
        else
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
                [self popToSettingsVC:settingsVC];
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

        TDAppDelegate *appdel = (TDAppDelegate *)[[UIApplication sharedApplication] delegate];
        appdel.customTabbar.autoSyncAllowed = YES;
    }
}
- (void)popToSettingsVC:(SettingsViewController*)settingsVC {
    [self.navigationController popToViewController:settingsVC animated:YES];
}
- (void) AssignNewControllerToCenterController: (TDRootViewController *) newController
{
    UINavigationController *navigationController = self.navigationController;
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    NSArray *controllers = [NSArray arrayWithObject: newController];
    navigationController.viewControllers = controllers;
}

- (IBAction)customerServiceTap:(id)sender
{
    if (![MFMailComposeViewController canSendMail]){
        
        UIAlertController *addMailAlert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Mail not configured", nil)
                                                                              message:NSLocalizedString(@"You have not setup your e-mail in this device. Please configure it in Mail app", nil)
                                                                       preferredStyle:UIAlertControllerStyleAlert];
        
        [addMailAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * _Nonnull action)
                                 {
                                     [self goToNextController];
                                 }]];
        
        [self presentViewController:addMailAlert animated:YES completion:nil];
        
        return;
    }
    
    NSString *emailTitle = @"SYSBLOCK.BIN files";
    NSString *messageBody = @"";
    NSArray *toRecipents = [NSArray arrayWithObject:CUSTOMER_SUPPORT_URL];
    
    MFMailComposeViewController *mc = [[MFMailComposeViewController alloc] init];
    mc.mailComposeDelegate = self;
    [mc setSubject:emailTitle];
    [mc setMessageBody:messageBody isHTML:NO];
    [mc setToRecipients:toRecipents];
    
    NSArray *files = [TDM328WatchSettingsUserDefaults storedNames];
    NSString *file = @"";
    // Add attachments
    for (file in files)
    {
        // Determine the file name and extension
        NSArray *paths = NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *directoryFix = [NSString stringWithFormat:@"%@/%@", documentsDirectory, file];
        
        // Get the resource path and read the file using NSData
        NSData *fileData = [NSData dataWithContentsOfFile:directoryFix];
        [mc addAttachmentData:fileData mimeType:@"application/x-binary" fileName:file];
    }
    
    // Present mail view controller on screen
    [self.navigationController presentViewController:mc animated:YES completion:nil];
}

- (void) mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    switch (result)
    {
        case MFMailComposeResultCancelled:
            NSLog(@"Mail cancelled");
            break;
        case MFMailComposeResultSaved:
            NSLog(@"Mail saved");
            break;
        case MFMailComposeResultSent:
            NSLog(@"Mail sent");
            break;
        case MFMailComposeResultFailed:
            NSLog(@"Mail sent failure: %@", [error localizedDescription]);
            break;
        default:
            break;
    }
    [controller dismissViewControllerAnimated:YES completion:nil];
    [self goToNextController];
}

- (IBAction)cancelTap:(id)sender
{
    ((UIButton *)sender).userInteractionEnabled = NO;
    [self goToNextController];
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
        NSLog(@"startFileAccessSession");
    }
}

- (void)watchDisconnected:(NSNotification*)notification
{
    if (!doOnce)
    {
        CalibratingWatchViewController *calibVC = [[CalibratingWatchViewController alloc] initWithNibName:@"CalibratingWatchViewController" bundle:nil doSettingsMenuCalibration:!self.isFromSetup];
        calibVC.openCalibration = YES;
        
        [self.navigationController pushViewController:calibVC animated:YES];
        doOnce = YES;
    }
}

-(void)didStartFileAccessSession:(NSNotification*)notification
{
    NSLog(@"didStartFileAccessSession");
    // Remove observer.
    [[NSNotificationCenter defaultCenter]removeObserver:self name:kTDM328SessionStartNotification object:nil];
    
    PeripheralDevice * timexDevice = [iDevicesUtil getConnectedTimexDevice];
    if(timexDevice)
    {
        [timexDevice endFileAccessSession];
        NSLog(@"endFileAccessSession");
    }
}

- (void)addLongPressGesturesToBtns {
    UILongPressGestureRecognizer *longPressPlus = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressOnPlusBtn:)];
    [plusBtn addGestureRecognizer:longPressPlus];
    
    UILongPressGestureRecognizer *longPressMinus = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressOnMinusBtn:)];
    [minusBtn addGestureRecognizer:longPressMinus];
}

- (void)longPressOnPlusBtn:(UILongPressGestureRecognizer*)gesture {
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan: {
            if (timer) {
                [timer invalidate];
                timer = nil;
            }
            if(viewType == Hand_Second)
            {
                calibrationObject.steps = ONE_STEP;
                timer = [NSTimer timerWithTimeInterval:SINGLE_PRESS_TIME_VALUE target:self selector:@selector(clickedOnPlusBtn:) userInfo:nil repeats:YES];
            }
            else
            {
                calibrationObject.steps = FIVE_STEPS;
                timer = [NSTimer timerWithTimeInterval:LONG_PRESS_TIMER_VALUE target:self selector:@selector(clickedOnPlusBtn:) userInfo:nil repeats:YES];
            }
            
            NSRunLoop * theRunLoop = [NSRunLoop currentRunLoop];
            [theRunLoop addTimer:timer forMode:NSDefaultRunLoopMode];
        }
            break;
        case UIGestureRecognizerStateEnded: {
            [timer invalidate];
            timer = nil;
            calibrationObject.steps = ONE_STEP;
        }
            break;
        default:
            break;
    }
}
- (void)longPressOnMinusBtn:(UILongPressGestureRecognizer*)gesture {
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan: {
            if (timer) {
                [timer invalidate];
                timer = nil;
            }
            if(viewType == Hand_Second)
            {
                calibrationObject.steps = ONE_STEP;
                timer = [NSTimer timerWithTimeInterval:SINGLE_PRESS_TIME_VALUE target:self selector:@selector(clickedOnMinusBtn:) userInfo:nil repeats:YES];
            }
            else
            {
                calibrationObject.steps = FIVE_STEPS;
                timer = [NSTimer timerWithTimeInterval:LONG_PRESS_TIMER_VALUE target:self selector:@selector(clickedOnMinusBtn:) userInfo:nil repeats:YES];
            }
            NSRunLoop * theRunLoop = [NSRunLoop currentRunLoop];
            [theRunLoop addTimer:timer forMode:NSDefaultRunLoopMode];
        }
            break;
        case UIGestureRecognizerStateEnded: {
            [timer invalidate];
            timer = nil;
            calibrationObject.steps = ONE_STEP;
        }
            break;
        default:
            break;
    }
}

- (IBAction)clickedOnPlusBtn:(id)sender {
    if (currentSelectedValue == numberOfRows) {
        currentSelectedValue = 0;
    }
    currentSelectedValue++;
    calibrationObject.motorDirection = QA_CW_DIR; //CLOCK WISE DIRECTION
    
    [self rotateHand];
}

- (IBAction)clickedOnMinusBtn:(id)sender {
    if (currentSelectedValue == 0) {
        currentSelectedValue = numberOfRows;
    }
    currentSelectedValue--;
    calibrationObject.motorDirection = QA_CCW_DIR; //COUNTER CLOCK WISE DIRECTION
    [self rotateHand];
}

- (void)rotateHand {
//    CGFloat angleInDegrees = currentSelectedValue * (DEGREES/numberOfRows);
//    
//    CGFloat angleInRadians = angleInDegrees * (M_PI / 180);
//    
//    [UIView animateWithDuration:0.3 animations:^{
//        if (viewType == Hand_Minute || viewType == Hand_Second) {
//            self.handView.transform = CGAffineTransformRotate(CGAffineTransformIdentity, angleInRadians);
//        } else if (viewType == Hand_Hour) {
//            self.handView.transform = CGAffineTransformRotate(CGAffineTransformIdentity, angleInRadians);
//        } else if (viewType == Hand_SubDial) {
//            self.subDialHandView.transform = CGAffineTransformRotate(CGAffineTransformIdentity, angleInRadians);
//        }
//    }];
    
    [calibrationObject buildPCCOMMCalibMessage:PC_RX_CMD_M328_MOVE_SPECIFIED_MOTOR];
}

- (NSAttributedString *)getAttributedStrWithText:(NSString *)textStr formatStr:(NSString *)formatStr andHighlightText:(NSString *)highlightText {
    
    UIFont *textFont = [UIFont fontWithName:[iDevicesUtil getAppWideMediumFontName] size:M328_REGISTRATION_TITLE_FONTSIZE];
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:textFont, NSFontAttributeName, [UIColor blackColor],NSForegroundColorAttributeName, nil];
    NSMutableAttributedString *textAtrStr = [[NSMutableAttributedString alloc] initWithString:textStr attributes:dict];
    
    UIFont *formatFont = [UIFont fontWithName: [iDevicesUtil getAppWideFontName] size:M328_REGISTRATION_INFO_FONTSIZE];
    NSDictionary *atrsDict = [NSDictionary dictionaryWithObjectsAndKeys:formatFont, NSFontAttributeName, UIColorFromRGB(COLOR_DEFAULT_TIMEX_FONT),NSForegroundColorAttributeName, nil];
    NSMutableAttributedString *formatAtrStr = [[NSMutableAttributedString alloc] initWithString:formatStr attributes:atrsDict];
    
    
    NSString *searchstring = highlightText;
    NSRange foundRange = [textStr rangeOfString:searchstring];
    if (foundRange.length > 0) {
        UIFont *font = [UIFont fontWithName: [iDevicesUtil getAppWideBoldFontName] size:M328_REGISTRATION_TITLE__HIGHLIGHT_FONTSIZE];
        NSDictionary *higDict = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, UIColorFromRGB(AppColorRed),NSForegroundColorAttributeName, nil];
        [textAtrStr addAttributes:higDict range:foundRange];
    }
    
    [textAtrStr appendAttributedString:formatAtrStr];
    
    return textAtrStr;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}
/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
