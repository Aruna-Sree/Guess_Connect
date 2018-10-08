//
//  WelcomeViewController.m
//  Timex-iOS
//
//  Created by avemulakonda on 5/4/16.
//

#import "WelcomeViewController.h"
#import "UnitViewController.h"
#import "StepsViewController.h"
#import "iDevicesUtil.h"
#import "TDDefines.h"
#import "UIImage+Tint.h"
#import "TDAppDelegate.h"
#import "TDM328WatchSettingsUserDefaults.h"
#import "OTLogUtil.h"
#import "TDWatchProfile.h"

NSString* const  kEULApresentedAndAgreedTo = @"kEULApresentedAndAgreedTo";

@interface WelcomeViewController ()

@end

@implementation WelcomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.titleView = [iDevicesUtil getNavigationTitle];
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))  {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    [(TDAppDelegate *)[[UIApplication sharedApplication] delegate] setNavigationBarSettingsForM328:self.navigationController];
    
    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)
    {
        welcomeTextLbl.attributedText = [self getAttributedStrWithText:NSLocalizedString(@"Welcome!",nil) formatStr:NSLocalizedString(@"\n\nGuess Connect helps you stay on time and healthy by syncing your watch with up to three separate timezones while tracking your activity.",nil)];
        welcomeImg.image = [UIImage imageNamed:@"WelcomeTravel"];
    }
    else
    {
        welcomeTextLbl.attributedText = [self getAttributedStrWithText:NSLocalizedString(@"Welcome!",nil) formatStr:[NSString stringWithFormat:@"\n\n%@",NSLocalizedString(@"Guess Connect helps you stay healthy by tracking activities such as steps you've taken, distance you've traveled, and your sleep patterns.",nil)]];
    }
    
    [getStartedButton setTitle:[NSString stringWithFormat:@"%@  ", NSLocalizedString(@"GET STARTED", nil)] forState:UIControlStateNormal];
    getStartedButton.transform = CGAffineTransformMakeScale(-1.0, 1.0);
    getStartedButton.titleLabel.transform = CGAffineTransformMakeScale(-1.0, 1.0);
    getStartedButton.imageView.transform = CGAffineTransformMakeScale(-1.0, 1.0);
    [getStartedButton setTitleColor:UIColorFromRGB(AppColorRed) forState:UIControlStateNormal];
    getStartedButton.tintColor = UIColorFromRGB(AppColorRed);
    
    [pleaseCreateYourProfileLabel setText:NSLocalizedString(pleaseCreateYourProfileLabel.text, nil)];
    
    if (IS_IPAD) {
        welcomeTextLblTopConstraint.constant = 60;
        welcomeTextLblLeftConstraint.constant = 60;
        bottomLblLeftConstraint.constant = 60;
        welcomeTextLblRightContraint.constant = 60;
        bottomLblRightContraint.constant = 60;
        
        welcomeTextLblHeightContraint.constant = 150;

        welcomeTextLblBottomContraint.constant = 150;
        
        nextButtonBottomContraint.constant = 40;
        
    } else {
        welcomeTextLblTopConstraint.constant = 10;
        if (ScreenHeight > 480) {
            welcomeTextLblBottomContraint.constant = 100;
        }
        welcomeTextLblHeightContraint.constant = 120;
    }
    
    if (ScreenWidth > 600) {
        imgsViewWidthContraint.constant = 400;
        imgsViewHeightContraint.constant = 400/4;
    } else {
        imgsViewWidthContraint.constant = ScreenWidth;
        imgsViewHeightContraint.constant = ScreenWidth/4;
    }
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    }
    [self.view layoutIfNeeded];
    self.navigationItem.hidesBackButton = YES;
}
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //show the EULA... if they have never seen it that is
    if ([[NSUserDefaults standardUserDefaults] objectForKey: kEULApresentedAndAgreedTo] == nil || [[NSUserDefaults standardUserDefaults] boolForKey: kEULApresentedAndAgreedTo] == FALSE)
    {
        if([UIAlertController class])
        {
            UIAlertController * eula =   [UIAlertController alertControllerWithTitle: NSLocalizedString(@"First some details.", nil)
                                                                             message: NSLocalizedString(@"We take your privacy seriously.\n\nPlease Review and accept the Privacy Policy and the End User Agreement.", nil)
                                                                      preferredStyle: UIAlertControllerStyleAlert];
            UIAlertAction* ok = [UIAlertAction actionWithTitle: NSLocalizedString(@"Accept", nil) style: UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * action)
                                 {
                                     [[NSUserDefaults standardUserDefaults] setBool: TRUE forKey: kEULApresentedAndAgreedTo];
                                 }];
            UIAlertAction* details = [UIAlertAction actionWithTitle: NSLocalizedString(@"Details", nil) style: nil
                                                            handler:^(UIAlertAction * action)
                                      {
                                          if ([iDevicesUtil hasInternetConnectivity]) {
                                              [iDevicesUtil displayEULADetailsFromViewController:self];
                                          } else {
                                              UIAlertController *noInternetAlert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Guess Connect", nil)
                                                                                                                       message:NSLocalizedString(@"The Internet connection appears to be offline", nil)
                                                                                                                preferredStyle:UIAlertControllerStyleAlert];
                                              
                                              [noInternetAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                                                                  style:UIAlertActionStyleCancel
                                                                                                handler:^(UIAlertAction * _Nonnull action) {}]];
                                              
                                              [self presentViewController:noInternetAlert animated:YES completion:nil];
                                          }
                                      }];
            
            //this is necessary so it scrolls
            eula.view.frame = [[UIScreen mainScreen] applicationFrame];
            
            [eula addAction:details];
            [eula addAction:ok];
            
            [self presentViewController: eula animated:YES completion:nil];
        }
        else
        {
            UIAlertView *eulaAlert = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"First some details.", nil)
                                                   message: NSLocalizedString(@"We take your privacy seriously.\n\nPlease Review and accept the Privacy Policy and the End User Agreement.", nil)
                                                  delegate: self cancelButtonTitle: NSLocalizedString(@"Details", nil) otherButtonTitles: NSLocalizedString(@"Accept", nil), nil ];
            eulaAlert.tag = 1;
            [eulaAlert show];
        }
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 1)
    {
        if (buttonIndex == alertView.cancelButtonIndex)
        {
            [iDevicesUtil displayEULADetailsFromViewController:self];
        }
        else
        {
            [[NSUserDefaults standardUserDefaults] setBool: TRUE forKey: kEULApresentedAndAgreedTo];
        }
    }
    
}
-(IBAction) backButtonTapped:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}
- (NSAttributedString *)getAttributedStrWithText:(NSString *)textStr formatStr:(NSString *)formatStr {
    
    UIFont *textFont = [UIFont fontWithName:[iDevicesUtil getAppWideFontName] size:M328_REGISTRATION_BIG_TITLE_FONTSIZE];
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:textFont, NSFontAttributeName, [UIColor blackColor],NSForegroundColorAttributeName, nil];
    NSMutableAttributedString *textAtrStr = [[NSMutableAttributedString alloc] initWithString:textStr attributes:dict];
    
    UIFont *formatFont = [UIFont fontWithName: [iDevicesUtil getAppWideMediumFontName] size:M328_WELCOME_INFO_FONTSIZE];
    NSDictionary *atrsDict = [NSDictionary dictionaryWithObjectsAndKeys:formatFont, NSFontAttributeName, UIColorFromRGB(COLOR_DEFAULT_TIMEX_FONT),NSForegroundColorAttributeName, nil];
    NSMutableAttributedString *formatAtrStr = [[NSMutableAttributedString alloc] initWithString:formatStr attributes:atrsDict];
    
    [textAtrStr appendAttributedString:formatAtrStr];

    return textAtrStr;
}

- (void)didReceiveMemoryWarning {
    OTLog([NSString stringWithFormat:@"Recived Memory Warning  in %@ ",NSStringFromClass([self class])]);
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)startButtonTapped:(id)sender {
    
    if ([[[NSLocale currentLocale] objectForKey:NSLocaleUsesMetricSystem] boolValue]) {
        [TDM328WatchSettingsUserDefaults setUnits:M328_METRIC];
    } else {
        [TDM328WatchSettingsUserDefaults setUnits:M328_IMPERIAL];
    }
    UnitViewController *unitVC=[[UnitViewController alloc] initWithNibName:@"UnitViewController" bundle:nil];
    [self.navigationController pushViewController:unitVC animated:YES];
}

@end
