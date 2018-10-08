//
//  AboutViewController.m
//  Timex
//
//  Created by Aruna Kumari Yarra on 27/06/16.
//

#import "AboutViewController.h"
#import "iDevicesUtil.h"
#import "TDDefines.h"
#import "TDAppDelegate.h"
//#import "User.h"
#import "MFSideMenuContainerViewController.h"
#import "SideMenuViewController.h"
#import "TDM328WatchSettingsUserDefaults.h"
#import "OTLogUtil.h"
#import "PCCommChargeInfo.h"
#import "TDWatchProfile.h"

NSString * const kUSERPREFERENCESFIRSTNAME = @"kUSERPREFERENCESFIRSTNAME";
NSString * const kUSERPREFERENCESLASTNAME = @"kUSERPREFERENCESLASTNAME";
NSString * const kUSERPREFERENCESEMAIL = @"kUSERPREFERENCESEMAIL";
NSString * const kUSERPREFERENCESZIPCODE = @"kUSERPREFERENCESZIPCODE";
NSString * const kUSERPREFERENCESGENDER = @"kUSERPREFERENCESGENDER";
NSString * const kUSERPREFERENCESOPTIN = @"kUSERPREFERENCESOPTIN";
NSString * const kUSERREGISTRATIONCOMPLETEDKEY = @"USERREGISTRATIONCOMPLETEDKEY";

@interface AboutViewController () {
    //User *user;
    
    IBOutlet UILabel *regTitle;
    IBOutlet UILabel *regMessage;
    
    
    IBOutlet UITextField *regFirstName;
    IBOutlet UITextField *regLastName;
    IBOutlet UITextField *regEmail;
    IBOutlet UITextField *regZipCode;
    
    
    IBOutlet UIButton *regMaleButton;
    IBOutlet UIButton *regFemaleButton;
    IBOutlet UIButton *regNotSexButton;
    
    IBOutlet UIButton *regCheckButton;
    
    IBOutlet UIButton *cancelButton;
    IBOutlet UIButton *registerButton;
    
    int sexSelected; // 0 male - 1 female -> in the future 3 notSelected
    MBProgressHUD *HUD;
    
    TDAppDelegate * delegate;
}

@end

@implementation AboutViewController

- (void)viewDidLoad {
    [super viewDidLoad];
   // AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
   // user = [app getUser];
    self.title = NSLocalizedString(@"About",nil);
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))  {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    self.navigationItem.titleView = [iDevicesUtil getNavigationTitle];
    NSDictionary * navBarTitleTextAttributes =  @{NSFontAttributeName : [UIFont fontWithName:[iDevicesUtil getAppWideBoldFontName] size:APP_HEADER_FONT_SIZE] };
    self.navigationController.navigationBar.titleTextAttributes = navBarTitleTextAttributes;
    UIBarButtonItem *slideMenuItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"menu"] style:UIBarButtonItemStylePlain target:self action:@selector(slideMenuTapped)];
    self.navigationItem.leftBarButtonItem = slideMenuItem;
    
    watchInfoLbl.font = [UIFont fontWithName:[iDevicesUtil getAppWideFontName] size:M328_ABOUT_TEXT_FONT_SIZE];
    
    appVersionLbl.attributedText = [self getAttributedStrWithText:NSLocalizedString(@"Guess Connect", nil)  formatStr:[NSString stringWithFormat:@"\n%@ %@",NSLocalizedString(@"App Version", nil), [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]]];
    
    [licenseAgreementBtn setTitle:NSLocalizedString(licenseAgreementBtn.currentTitle, nil) forState:UIControlStateNormal];
    [yourWatchLabel setText:NSLocalizedString(yourWatchLabel.text, nil)];
    [backBtn setTitle:NSLocalizedString(backBtn.currentTitle, nil) forState:UIControlStateNormal];
    
    delegate = (TDAppDelegate *)[[UIApplication sharedApplication] delegate];
    [self setInfoText];

    [licenseAgreementBtn.titleLabel setFont:[UIFont fontWithName:[iDevicesUtil getAppWideFontName] size:M328_ABOUT_TEXT_FONT_SIZE]];
    
    [registerWatchBtn setBackgroundColor:UIColorFromRGB(AppColorRed)];
    [registerWatchBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [registerWatchBtn.titleLabel setFont:[UIFont fontWithName:[iDevicesUtil getAppWideFontName] size:M328_ABOUT_TEXT_FONT_SIZE]];
    
    
    NSMutableArray *registeredWatchArray = [[[NSUserDefaults standardUserDefaults] objectForKey:kUSERREGISTRATIONCOMPLETEDKEY] mutableCopy];
    if (([[NSUserDefaults standardUserDefaults] stringForKey:WATCH_SERIAL_NUMBER] != nil) && ![registeredWatchArray containsObject:[[NSUserDefaults standardUserDefaults] stringForKey:WATCH_SERIAL_NUMBER]])
    {
        [registerWatchBtn setTitle:NSLocalizedString(@"Register Watch",nil) forState:UIControlStateNormal];
        registerWatchBtn.userInteractionEnabled = YES;
    }
    else
    {
        [registerWatchBtn setTitle:NSLocalizedString(@"Watch already registered",nil) forState:UIControlStateNormal];
        registerWatchBtn.userInteractionEnabled = NO;
    }
    
    registrationView.hidden = YES;
    registrationScrollView.layer.cornerRadius = 10.0f;
    registrationScrollView.layer.masksToBounds = YES;
    if ([TDM328WatchSettingsUserDefaults warningTriggered]) {
        [watchBtn setBackgroundImage:[UIImage imageNamed:@"ResetWarn"] forState:UIControlStateNormal];
    } else {
        [watchBtn setBackgroundImage:[UIImage imageNamed:@"AboutWatch"] forState:UIControlStateNormal];
    }
    if (!_showBackButton) {
        UIBarButtonItem *slideMenuItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"menu"] style:UIBarButtonItemStylePlain target:self action:@selector(slideMenuTapped)];
        self.navigationItem.leftBarButtonItem = slideMenuItem;
        [self slideMenuTapped];
    }
    [backBtn setTitleColor:UIColorFromRGB(AppColorRed) forState:UIControlStateNormal];
}

- (void)backButtonTapped {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)setInfoText
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *watchName = [userDefaults objectForKey:@"kCONNECTED_DEVICE_PREF_NAME"];
    watchInfoLbl.text = [NSString stringWithFormat:NSLocalizedString(@"Model: Guess iQ+\nName: %@\n\nFirmware Version\nM328-#FIRMWARE3#-#FIRMWARE1#-#FIRMWARE4#-#FIRMWARE2#\n\nMAC Address\n#SERIALNUMBER#\n\nBattery At Last Sync\n#LASTSYNC#",nil), watchName];
    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)
    {
        watchInfoLbl.text = [NSString stringWithFormat:NSLocalizedString(@"Model: iQ+ Travel\nName: %@\n\nFirmware Version\nM329-#FIRMWARE3#-#FIRMWARE1#-#FIRMWARE4#-#FIRMWARE2#\n\nMAC Address\n#SERIALNUMBER#\n\nBattery At Last Sync\n#LASTSYNC#",nil), watchName];
    }
    
    NSMutableString *string = [watchInfoLbl.text mutableCopy];
    // Get the firmware information also
    NSString *firmwareOnWatch;
    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)
    {
        firmwareOnWatch = [NSString stringWithFormat:@"A%ld", [[[[NSUserDefaults standardUserDefaults] objectForKey: kM372FirmwareVersionFile1Key] stringByReplacingOccurrencesOfString:@"M372A" withString:@""] integerValue]];
        [string replaceOccurrencesOfString:@"#FIRMWARE1#" withString:firmwareOnWatch?:@"" options:NSCaseInsensitiveSearch range:[string rangeOfString:@"#FIRMWARE1#"]];
        
        firmwareOnWatch = [NSString stringWithFormat:@"R%ld", [[[[NSUserDefaults standardUserDefaults] objectForKey: kM372FirmwareVersionFile2Key] stringByReplacingOccurrencesOfString:@"M328R" withString:@""] integerValue]];
        [string replaceOccurrencesOfString:@"#FIRMWARE2#" withString:firmwareOnWatch?:@"" options:NSCaseInsensitiveSearch range:[string rangeOfString:@"#FIRMWARE2#"]];
        
        firmwareOnWatch = [NSString stringWithFormat:@"F%ld", [[[[NSUserDefaults standardUserDefaults] objectForKey: kM372FirmwareVersionFile3Key] stringByReplacingOccurrencesOfString:@"M329F" withString:@""] integerValue]];
        [string replaceOccurrencesOfString:@"#FIRMWARE3#" withString:firmwareOnWatch?:@"" options:NSCaseInsensitiveSearch range:[string rangeOfString:@"#FIRMWARE3#"]];
        
        firmwareOnWatch = [NSString stringWithFormat:@"C%ld", [[[[NSUserDefaults standardUserDefaults] objectForKey: kM372FirmwareVersionFile4Key] stringByReplacingOccurrencesOfString:@"M329C" withString:@""] integerValue]];
        [string replaceOccurrencesOfString:@"#FIRMWARE4#" withString:firmwareOnWatch?:@"" options:NSCaseInsensitiveSearch range:[string rangeOfString:@"#FIRMWARE4#"]];
    }
    else
    {
        firmwareOnWatch = [NSString stringWithFormat:@"A%ld", [[[[NSUserDefaults standardUserDefaults] objectForKey: kM372FirmwareVersionFile1Key] stringByReplacingOccurrencesOfString:@"M372A" withString:@""] integerValue]];
        [string replaceOccurrencesOfString:@"#FIRMWARE1#" withString:firmwareOnWatch?:@"" options:NSCaseInsensitiveSearch range:[string rangeOfString:@"#FIRMWARE1#"]];
        
        firmwareOnWatch = [NSString stringWithFormat:@"R%ld", [[[[NSUserDefaults standardUserDefaults] objectForKey: kM372FirmwareVersionFile2Key] stringByReplacingOccurrencesOfString:@"M328R" withString:@""] integerValue]];
        [string replaceOccurrencesOfString:@"#FIRMWARE2#" withString:firmwareOnWatch?:@"" options:NSCaseInsensitiveSearch range:[string rangeOfString:@"#FIRMWARE2#"]];
        
        firmwareOnWatch = [NSString stringWithFormat:@"F%ld", [[[[NSUserDefaults standardUserDefaults] objectForKey: kM372FirmwareVersionFile3Key] stringByReplacingOccurrencesOfString:@"M328F" withString:@""] integerValue]];
        [string replaceOccurrencesOfString:@"#FIRMWARE3#" withString:firmwareOnWatch?:@"" options:NSCaseInsensitiveSearch range:[string rangeOfString:@"#FIRMWARE3#"]];
        
        firmwareOnWatch = [NSString stringWithFormat:@"C%ld", [[[[NSUserDefaults standardUserDefaults] objectForKey: kM372FirmwareVersionFile4Key] stringByReplacingOccurrencesOfString:@"M328C" withString:@""] integerValue]];
        [string replaceOccurrencesOfString:@"#FIRMWARE4#" withString:firmwareOnWatch?:@"" options:NSCaseInsensitiveSearch range:[string rangeOfString:@"#FIRMWARE4#"]];
    }
    
    // Putting connected watch serial number
    NSMutableString *tempStringSerial = [[NSMutableString alloc] initWithString:[[[NSUserDefaults standardUserDefaults] stringForKey:WATCH_SERIAL_NUMBER] substringWithRange:NSMakeRange(8, 12)]];
    for (int i = 10; i > 0; i = i - 2)
    {
        [tempStringSerial insertString:@":" atIndex:i];
    }
    [string replaceOccurrencesOfString:@"#SERIALNUMBER#" withString:tempStringSerial?:@"" options:NSCaseInsensitiveSearch range:[string rangeOfString:@"#SERIALNUMBER#"]];
    
    firmwareOnWatch = [NSString stringWithFormat:@"%.2fv %@",[TDM328WatchSettingsUserDefaults batteryVolt],[delegate getLastSyncDate]];
    [string replaceOccurrencesOfString:@"#LASTSYNC#" withString:firmwareOnWatch?:@"" options:NSCaseInsensitiveSearch range:[string rangeOfString:@"#LASTSYNC#"]];
    
    watchInfoLbl.text = string;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self registerForKeyboardNotifications];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self customizeRegistrationView];
    if (_showBackButton) {
        UIButton *navbackBtn = [iDevicesUtil getBackButton];
        [navbackBtn addTarget:self action:@selector(backButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *barBtn = [[UIBarButtonItem alloc] initWithCustomView:navbackBtn];
        self.navigationItem.leftBarButtonItem = barBtn;
    }
}
- (void)didReceiveMemoryWarning {
     OTLog([NSString stringWithFormat:@"Recived Memory Warning  in %@ ",NSStringFromClass([self class])]);
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)slideMenuTapped {
    SideMenuViewController *leftController = (SideMenuViewController *)((MFSideMenuContainerViewController *)delegate.window.rootViewController).leftMenuViewController;
    if (leftController == nil)
    {
        SideMenuViewController *leftController = [[SideMenuViewController alloc] init];
        ((MFSideMenuContainerViewController *)delegate.window.rootViewController).leftMenuViewController = leftController;
    } 
}
- (IBAction)clickedOnLicenseBtn:(id)sender {
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
}
- (IBAction)clickedOnRegisterWatchBtn:(id)sender {
    
    NSMutableArray *registeredWatchArray = [[[NSUserDefaults standardUserDefaults] objectForKey:kUSERREGISTRATIONCOMPLETEDKEY] mutableCopy];
    if (([[NSUserDefaults standardUserDefaults] stringForKey:WATCH_SERIAL_NUMBER] != nil) && ![registeredWatchArray containsObject:[[NSUserDefaults standardUserDefaults] stringForKey:WATCH_SERIAL_NUMBER]])
    {
        if ([TDM328WatchSettingsUserDefaults syncNeeded]) {
            [delegate showAlertWithTitle:NSLocalizedString(@"Guess Connect",nil) Message:NSLocalizedString(@"Please set up your watch before registering.",nil) andButtonTitle:NSLocalizedString(@"Ok",nil)];
            return;
        }
        else {
            registrationView.hidden = NO;
        }
    }
    else
    {
        [delegate showAlertWithTitle:NSLocalizedString(@"Watch registered", nil) Message:NSLocalizedString(@"The watch was registered before.", nil) andButtonTitle:NSLocalizedString(@"OK", nil)];
    }
}
- (IBAction)customerServiceTap:(id)sender
{
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
    [self presentViewController:mc animated:YES completion:NULL];
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
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSAttributedString *)getAttributedStrWithText:(NSString *)textStr formatStr:(NSString *)formatStr {
    
    UIFont *textFont = [UIFont fontWithName:[iDevicesUtil getAppWideFontName] size:M328_REGISTRATION_BIG_TITLE_FONTSIZE];
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:textFont, NSFontAttributeName, UIColorFromRGB(COLOR_DEFAULT_TIMEX_FONT),NSForegroundColorAttributeName, nil];
    NSMutableAttributedString *textAtrStr = [[NSMutableAttributedString alloc] initWithString:textStr attributes:dict];
    
    UIFont *formatFont = [UIFont fontWithName: [iDevicesUtil getAppWideMediumFontName] size:M328_WELCOME_INFO_FONTSIZE];
    NSDictionary *atrsDict = [NSDictionary dictionaryWithObjectsAndKeys:formatFont, NSFontAttributeName, UIColorFromRGB(COLOR_DEFAULT_TIMEX_FONT),NSForegroundColorAttributeName, nil];
    NSMutableAttributedString *formatAtrStr = [[NSMutableAttributedString alloc] initWithString:formatStr attributes:atrsDict];
    
    [textAtrStr appendAttributedString:formatAtrStr];
    
    return textAtrStr;
}

- (void)customizeRegistrationView {
    registrationScrollView.contentSize = CGSizeMake(registrationScrollView.frame.size.width, 516);
    [registrationScrollView layoutSubviews];
    regTitle.font = [UIFont fontWithName:[iDevicesUtil getAppWideMediumFontName] size:18];
    regTitle.text = NSLocalizedString(@"Register your Guess Connect", nil);
    
    regMessage.font = [UIFont fontWithName:[iDevicesUtil getAppWideMediumFontName] size:10];
    regMessage.text = NSLocalizedString(@"Registering your Guess Connect will enable us to provide more efficient service if you ever have a question or problem. Please be assured that Guess Connect will not share your information with any outside parties.", nil);
    
    regFirstName.placeholder = NSLocalizedString(@"First name", nil);
   regFirstName.text = [TDM328WatchSettingsUserDefaults userName];
    regFirstName.font = [UIFont fontWithName:[iDevicesUtil getAppWideMediumFontName] size:12];
    [self addBottomBorderToTextField:regFirstName];
    
    regLastName.placeholder = NSLocalizedString(@"Last name", nil);
    regLastName.font = [UIFont fontWithName:[iDevicesUtil getAppWideMediumFontName] size:12];
    [self addBottomBorderToTextField:regLastName];
    
    regEmail.placeholder = NSLocalizedString(@"Email address", nil);
    regEmail.font = [UIFont fontWithName:[iDevicesUtil getAppWideMediumFontName] size:12];
    [self addBottomBorderToTextField:regEmail];
    
    regZipCode.placeholder = NSLocalizedString(@"Zip code", nil);
    regZipCode.font = [UIFont fontWithName:[iDevicesUtil getAppWideMediumFontName] size:12];
    [self addBottomBorderToTextField:regZipCode];
    UIToolbar* numberToolbar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, 0, ScreenWidth, NUMBER_TOOLBAR_HEIGHT)];
    numberToolbar.barStyle = UIBarStyleDefault;
    numberToolbar.translucent = YES;
    numberToolbar.barTintColor = [UIColor whiteColor];
    
    UIButton *doneBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    doneBtn.frame = CGRectMake(0, 0, 50, NUMBER_TOOLBAR_HEIGHT);
    [doneBtn setTitleColor:UIColorFromRGB(AppColorRed) forState:UIControlStateNormal];
    [doneBtn setTitle:NSLocalizedString(@"DONE",nil) forState:UIControlStateNormal];
    [doneBtn.titleLabel setFont:[UIFont fontWithName:[iDevicesUtil getAppWideBoldFontName] size:12]];
    [doneBtn addTarget:self action:@selector(doneWithNumberPad) forControlEvents:UIControlEventTouchUpInside];
    
    numberToolbar.items = @[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                            [[UIBarButtonItem alloc] initWithCustomView:doneBtn]];
    regZipCode.inputAccessoryView = numberToolbar;
    
    [regMaleButton setImage:[UIImage imageNamed:@"GenderChecked"] forState:UIControlStateSelected];
    [regMaleButton setImage:[UIImage imageNamed:@"GenderUnchecked"] forState:UIControlStateNormal];
    [regMaleButton setTitle:NSLocalizedString(@"Male", nil) forState:UIControlStateNormal];
    [regMaleButton setTitle:NSLocalizedString(@"Male", nil) forState:UIControlStateSelected];
    [regMaleButton.titleLabel setFont:[UIFont fontWithName:[iDevicesUtil getAppWideMediumFontName] size:12]];
    [regMaleButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 10, 0, 0)];
    
    [regFemaleButton setImage:[UIImage imageNamed:@"GenderChecked"] forState:UIControlStateSelected];
    [regFemaleButton setImage:[UIImage imageNamed:@"GenderUnchecked"] forState:UIControlStateNormal];
    [regFemaleButton setTitle:NSLocalizedString(@"Female",nil) forState:UIControlStateNormal];
    [regFemaleButton setTitle:NSLocalizedString(@"Female",nil) forState:UIControlStateSelected];
    [regFemaleButton.titleLabel setFont:[UIFont fontWithName:[iDevicesUtil getAppWideMediumFontName] size:12]];
    [regFemaleButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 10, 0, 0)];
    
    [regNotSexButton setImage:[UIImage imageNamed:@"GenderChecked"] forState:UIControlStateSelected];
    [regNotSexButton setImage:[UIImage imageNamed:@"GenderUnchecked"] forState:UIControlStateNormal];
    [regNotSexButton setTitle:NSLocalizedString(@"I'd rather not say", nil) forState:UIControlStateNormal];
    [regNotSexButton setTitle:NSLocalizedString(@"I'd rather not say",nil) forState:UIControlStateSelected];
    [regNotSexButton.titleLabel setFont:[UIFont fontWithName:[iDevicesUtil getAppWideMediumFontName] size:12]];
    [regNotSexButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 10, 0, 0)];
    
    
    
    //if (user.gender.intValue == General_Gender_Female) {
//        [self genderSelected:regFemaleButton];
   // } else {
//        [self genderSelected:regMaleButton];
   // }
    
    if ((BOOL)[TDM328WatchSettingsUserDefaults gender])
    {
        [self genderSelected:regFemaleButton];
    }
    else
    {
        [self genderSelected:regMaleButton];
    }
    
    [regCheckButton setImage:[UIImage imageNamed:@"checkedButton"] forState:UIControlStateSelected];
    [regCheckButton setImage:[UIImage imageNamed:@"uncheckedButton"] forState:UIControlStateNormal];
    [regCheckButton setTitle:NSLocalizedString(@"Yes, I'd like to receive the latest product information, exclusive offers and special discounts from Guess Connect.",nil) forState:UIControlStateNormal];
    [regCheckButton setTitle:NSLocalizedString(@"Yes, I'd like to receive the latest product information, exclusive offers and special discounts from Guess Connect.",nil) forState:UIControlStateSelected];
    [regCheckButton.titleLabel setFont:[UIFont fontWithName:[iDevicesUtil getAppWideMediumFontName] size:12]];
    [regCheckButton.titleLabel setNumberOfLines:0];
    regCheckButton.selected = NO;
    [regCheckButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 10, 0, 0)];
    
    [registerButton setBackgroundColor:UIColorFromRGB(AppColorRed)];
    [registerButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [registerButton.titleLabel setFont:[UIFont fontWithName:[iDevicesUtil getAppWideFontName] size:M328_ABOUT_TEXT_FONT_SIZE]];
    [registerButton setTitle:NSLocalizedString(registerButton.currentTitle, nil) forState:UIControlStateNormal];
    
    [cancelButton setBackgroundColor:UIColorFromRGB(AppColorRed)];
    [cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [cancelButton.titleLabel setFont:[UIFont fontWithName:[iDevicesUtil getAppWideFontName] size:M328_ABOUT_TEXT_FONT_SIZE]];
    [cancelButton setTitle:NSLocalizedString(cancelButton.currentTitle, nil) forState:UIControlStateNormal];
}

- (void)addBottomBorderToTextField :(UITextField *)textfield {
    CALayer *border = [CALayer layer];
    CGFloat borderWidth = 1;
    border.borderColor = [UIColor blackColor].CGColor;
    border.frame = CGRectMake(0, textfield.frame.size.height - borderWidth, textfield.frame.size.width, textfield.frame.size.height);
    border.borderWidth = borderWidth;
    [textfield.layer addSublayer:border];
    textfield.layer.masksToBounds = YES;
}

- (void)doneWithNumberPad {
    [regZipCode resignFirstResponder];
}

- (IBAction)genderSelected:(UIButton *)sender {
    regMaleButton.selected = NO;
    regFemaleButton.selected = NO;
    regNotSexButton.selected = NO;
    if (sender == regMaleButton) {
        regMaleButton.selected = YES;
        sexSelected = 0;
    } else if (sender == regFemaleButton) {
        regFemaleButton.selected = YES;
        sexSelected = 1;
    } else {
        //Now the database doesn't support this function, we sent male as default
        sexSelected = 0;
        regNotSexButton.selected = YES;
    }
}

- (IBAction)moreInfoTapped:(id)sender
{
    watchInfoLbl.text = [NSString stringWithFormat:NSLocalizedString(@"Activity log from last sync:\nWDR: %d\nPOR: %d\nLPR: %d\nSYR: %d\nTimes Calibrated: %d", nil) ,
                         (int)[TDM328WatchSettingsUserDefaults currentWatchdogResets],
                         (int)[TDM328WatchSettingsUserDefaults currentPowerOnResets],
                         (int)[TDM328WatchSettingsUserDefaults currentLowPowerResets],
                         (int)[TDM328WatchSettingsUserDefaults currentSystemResets],
                         (int)[TDM328WatchSettingsUserDefaults numberOfCalibrations]];
    backBtn.hidden = NO;
    if ([TDM328WatchSettingsUserDefaults warningTriggered]) {
        supportBtn.hidden = NO;
        [watchBtn setBackgroundImage:[UIImage imageNamed:@"ResetWarn"] forState:UIControlStateNormal];
    } else {
        [watchBtn setBackgroundImage:[UIImage imageNamed:@"AboutWatch"] forState:UIControlStateNormal];
    }
}

- (IBAction)backTapped:(id)sender
{
    [self setInfoText];
    backBtn.hidden = YES;
    supportBtn.hidden = YES;
}

- (IBAction)checkedButton {
    if ([regCheckButton isSelected]) {
        regCheckButton.selected = NO;
    } else {
        regCheckButton.selected = YES;
    }
}

#pragma mark TextField Delegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    if (textField == regFirstName) {
        [regLastName becomeFirstResponder];
    } else if (textField == regLastName) {
        [regEmail becomeFirstResponder];
    } else if (textField == regEmail) {
        [regZipCode becomeFirstResponder];
    }
    
    return YES;
}

- (IBAction)clickedOnCancelBtn
{
    [self cleanFieldsColor];
    registrationView.hidden = YES;
}

- (IBAction)clickedOnRegisterBtn {
    [self cleanFieldsColor];
    
    if ([self validateFields])
    {
        [self doneCLickedAction];
    }
    else
    {
        [delegate showAlertWithTitle:NSLocalizedString(@"Error",nil) Message:NSLocalizedString(@"All fields are required",nil) andButtonTitle:NSLocalizedString(@"Ok",nil)];
    }
}

- (void)doneCLickedAction
{
    NSString * email = regEmail.text;
    if ([iDevicesUtil IsValidEmail: email] == FALSE)
    {
        [delegate showAlertWithTitle:NSLocalizedString(@"Error", nil) Message:NSLocalizedString(@"You have entered an invalid email address.", nil) andButtonTitle:NSLocalizedString(@"OK", nil)];
        
        [regEmail setBackgroundColor:RedUnselected];
        return;
    }
    
    if (regZipCode.text.length < 4 || regZipCode.text.length > 7 )
    {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"Invalid zip code", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"Ok", nil) otherButtonTitles:nil] show];
        return;
    }
    
    //first, save the information if the user has entered anything
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString * fName = regFirstName.text;
    if ([fName length] > 0)
    {
        [defaults  setObject: fName forKey: kUSERPREFERENCESFIRSTNAME];
    }
    
    NSString * lName = regLastName.text;
    if ([lName length] > 0)
    {
        [defaults  setObject: lName forKey: kUSERPREFERENCESLASTNAME];
    }
    
    if ([email length] > 0)
    {
        [defaults  setObject: email forKey: kUSERPREFERENCESEMAIL];
    }
    
    NSString * zip = regZipCode.text;
    if ([zip length] > 0)
    {
        [defaults  setObject: zip forKey: kUSERPREFERENCESZIPCODE];
    }
    
    BOOL gender = sexSelected;
    [defaults setBool: gender forKey: kUSERPREFERENCESGENDER];
    
    BOOL optInOption = regCheckButton.selected;
    [defaults setBool: optInOption forKey: kUSERPREFERENCESOPTIN];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    //------------------------------------------------------------
    
    TDHTTPClient * httpClient = [[TDHTTPClient sharedInstance] initWithBaseURL: [NSURL URLWithString: @"http://app.bronto.com/public/webform/process/"]];
    [httpClient setDelegate: self];
    
    NSMutableDictionary * parametersDictionary = [[NSMutableDictionary alloc] init];
    
    NSString * retrievedValue = nil;
    retrievedValue = [defaults  objectForKey: kUSERPREFERENCESFIRSTNAME];
    if (retrievedValue != nil && retrievedValue.length != 0)
    {
        [parametersDictionary setObject: retrievedValue forKey: @"58415[63359]"];
    }
    
    retrievedValue = nil;
    retrievedValue = [defaults  objectForKey: kUSERPREFERENCESLASTNAME];
    if (retrievedValue != nil && retrievedValue.length != 0)
    {
        [parametersDictionary setObject: retrievedValue forKey: @"58416[63360]"];
    }
    
    retrievedValue = nil;
    retrievedValue = [defaults  objectForKey: kUSERPREFERENCESEMAIL];
    if (retrievedValue != nil && retrievedValue.length != 0)
    {
        [parametersDictionary setObject: retrievedValue forKey: @"58404"];
    }
    
    retrievedValue = nil;
    retrievedValue = [defaults  objectForKey: kUSERPREFERENCESZIPCODE];
    if (retrievedValue != nil && retrievedValue.length != 0)
    {
        [parametersDictionary setObject: retrievedValue forKey: @"58418[63060]"];
    }
    
    NSMutableArray *registeredWatchArray = [[[NSUserDefaults standardUserDefaults] objectForKey:kUSERREGISTRATIONCOMPLETEDKEY] mutableCopy];
    if (([[NSUserDefaults standardUserDefaults] stringForKey:WATCH_SERIAL_NUMBER] != nil) && ![registeredWatchArray containsObject:[[NSUserDefaults standardUserDefaults] stringForKey:WATCH_SERIAL_NUMBER]])
    {
        if ([parametersDictionary count] > 0)
        {
            [parametersDictionary setObject: ([defaults boolForKey: kUSERPREFERENCESGENDER] == FALSE ? @"Male" : @"Female") forKey: @"58417[63368]"];
            [parametersDictionary setObject: [defaults objectForKey: kUSERPREFERENCESOPTIN] forKey: @"85942[584497]"];
            [parametersDictionary setObject: [NSNumber numberWithInteger: 1] forKey: @"58420[152557]"];
            [parametersDictionary setObject: [NSNumber numberWithInteger: 1] forKey: @"58421[348661]"];
            
            [parametersDictionary setObject: M328_WATCH_MODEL forKey: @"84309[63853]"];
            
            [parametersDictionary setObject: @"kao9d51h9m0gfi75jegpp23r92t66" forKey: @"fid"];
            [parametersDictionary setObject: @"8cc9204ef318d1e205bafdbb567b2344" forKey: @"sid"];
            [parametersDictionary setObject: @"" forKey: @"delid"];
            [parametersDictionary setObject: @"" forKey: @"subid"];
            
            [httpClient setParameters: parametersDictionary];
            
            [self initiateLastProgressDialog];
            HUD.detailsLabelText = [NSString stringWithFormat: NSLocalizedString(@"Registering user...", nil)];
            [HUD show: TRUE];
            
            [httpClient startPost];
        }
        else
        {
            [delegate showAlertWithTitle:NSLocalizedString(@"Error", nil) Message:NSLocalizedString(@"Unable to perform registration - no data entered.", nil) andButtonTitle:NSLocalizedString(@"OK", nil)];
        }
    }
    else
    {
        [self initiateLastProgressDialog];
    }
    
}

- (void) initiateLastProgressDialog
{
    __weak AboutViewController * weakSelf = self;
    void (^completionBlock)(void) = ^(void)
    {
        AboutViewController * strongSelf = weakSelf;
        [strongSelf performSelector: @selector(finishSetup:) withObject : self afterDelay: 0.0];
    };
    
    HUD = [[MBProgressHUD alloc] initWithView: self.navigationController.view];
    [self.navigationController.view addSubview: HUD];
    
    HUD.delegate = self;
    HUD.completionBlock = completionBlock;
    HUD.labelText = NSLocalizedString(@"Please Wait", nil);
    HUD.square = YES;
    HUD.mode = MBProgressHUDModeAnnularDeterminate;
}

-(void) finishSetup: (id) sender
{
    [self clickedOnCancelBtn];
}

#pragma mark -
#pragma mark TDHTTPClientDelegate methods
- (void)postSuccessful: (AFHTTPRequestOperation *)operation
{
    if (operation.response.statusCode >= 200 && operation.response.statusCode <= 299)
    {
        [delegate showAlertWithTitle:NSLocalizedString(@"Success!", nil) Message:NSLocalizedString(@"User Registration successful!", nil) andButtonTitle:NSLocalizedString(@"OK", nil)];
        
        //save in preferences that registration completed
        if ([[NSUserDefaults standardUserDefaults] stringForKey:WATCH_SERIAL_NUMBER] != nil) {
            NSMutableArray *registeredWatchArray = [[[NSUserDefaults standardUserDefaults] objectForKey:kUSERREGISTRATIONCOMPLETEDKEY] mutableCopy];
            if (registeredWatchArray == nil) {
                registeredWatchArray = [NSMutableArray array];
            }
            [registeredWatchArray addObject:[[NSUserDefaults standardUserDefaults] stringForKey:WATCH_SERIAL_NUMBER]];
            [[NSUserDefaults standardUserDefaults]  setObject: registeredWatchArray forKey: kUSERREGISTRATIONCOMPLETEDKEY];
        }
        
        [registerWatchBtn setTitle:NSLocalizedString(@"Watch already registered",nil) forState:UIControlStateNormal];
        registerWatchBtn.userInteractionEnabled = NO;
    }
    else
    {
        [delegate showAlertWithTitle:NSLocalizedString(@"Error", nil) Message:[NSString stringWithFormat: NSLocalizedString(@"Unable to register user.\n(status code %d)\nPlease try again later.", nil), operation.response.statusCode] andButtonTitle:NSLocalizedString(@"OK", nil)];
        
        if ([[NSUserDefaults standardUserDefaults] stringForKey:WATCH_SERIAL_NUMBER] != nil) {
            NSMutableArray *registeredWatchArray = [[[NSUserDefaults standardUserDefaults] objectForKey:kUSERREGISTRATIONCOMPLETEDKEY] mutableCopy];
            if (registeredWatchArray == nil) {
                registeredWatchArray = [NSMutableArray array];
            }
            if ([registeredWatchArray containsObject:[[NSUserDefaults standardUserDefaults] stringForKey:WATCH_SERIAL_NUMBER]])
            {
                [registeredWatchArray removeObject:[[NSUserDefaults standardUserDefaults] stringForKey:WATCH_SERIAL_NUMBER]];
            }
            [[NSUserDefaults standardUserDefaults]  setObject: registeredWatchArray forKey: kUSERREGISTRATIONCOMPLETEDKEY];
        }
    }
    [self hudWasHidden:HUD];
    
    registrationView.hidden = YES;
}

- (void)postFailed: (AFHTTPRequestOperation *)operation
{
    [delegate showAlertWithTitle:NSLocalizedString(@"Error", nil) Message:NSLocalizedString(@"Unable to register. Please try again later.", nil) andButtonTitle:NSLocalizedString(@"OK", nil)];
    
    [self hudWasHidden:HUD];
    
    registrationView.hidden = YES;
}

- (void)hudWasHidden:(MBProgressHUD *)hud
{
    // Remove HUD from screen when the HUD was hidden
    [HUD removeFromSuperview];
    HUD = nil;
}

- (BOOL)validateFields {
    BOOL result = false;
    
    int numberOfEmpties = 0;
    
    if (!(regFirstName.text.length > 0))
    {
        numberOfEmpties++;
        [regFirstName setBackgroundColor:RedUnselected];
    }
    
    if (!(regLastName.text.length > 0))
    {
        numberOfEmpties++;
        [regLastName setBackgroundColor:RedUnselected];
    }
    
    if (!(regEmail.text.length > 0))
    {
        numberOfEmpties++;
        [regEmail setBackgroundColor:RedUnselected];
    }
    
    if (!(regZipCode.text.length > 0))
    {
        numberOfEmpties++;
        [regZipCode setBackgroundColor:RedUnselected];
    }
    
    if (numberOfEmpties == 0)
        result = true;
    
    return result;
}

- (void)cleanFieldsColor {
    [regFirstName setBackgroundColor:[UIColor clearColor]];
    [regLastName setBackgroundColor:[UIColor clearColor]];
    [regEmail setBackgroundColor:[UIColor clearColor]];
    [regZipCode setBackgroundColor:[UIColor clearColor]];
}


#pragma mark Keyboard
// Call this method somewhere in your view controller setup code.
- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
}

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWasShown:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    registrationScrollView.contentInset = contentInsets;
    registrationScrollView.scrollIndicatorInsets = contentInsets;
    
    // If active text field is hidden by keyboard, scroll it so it's visible
    // Your application might not need or want this behavior.
    CGRect aRect = self.view.frame;
    aRect.size.height -= kbSize.height;
    if (!CGRectContainsPoint(aRect, regFirstName.frame.origin) ) {
        CGPoint scrollPoint = CGPointMake(0.0, regFirstName.frame.origin.y-kbSize.height);
        [registrationScrollView setContentOffset:scrollPoint animated:YES];
    }
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    registrationScrollView.contentInset = contentInsets;
    registrationScrollView.scrollIndicatorInsets = contentInsets;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
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
