//
//  BirthDateViewController.m
//  Timex-iOS
//
//  Created by avemulakonda on 5/4/16.
//

#import "BirthDateViewController.h"
#import "HeightViewController.h"
#import "iDevicesUtil.h"
#import "TDDefines.h"
#import "TDAppDelegate.h"
#import "TDM328WatchSettingsUserDefaults.h"
#import "OTLogUtil.h"
#import "UIImage+Tint.h"
//#import "User.h"

@class NameViewController;

@interface BirthDateViewController ()
{
    int years;
}
@end

@implementation BirthDateViewController

- (void)viewDidLoad {
    [super viewDidLoad];
   
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *componentsMax = [calendar components:(NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear) fromDate:[NSDate date]];
    componentsMax.year = componentsMax.year - M328_USER_DATA_AGE_MINIMUM;
//    componentsMax.month = 12; // Last day of the year
//    componentsMax.day = 31; // Last day of the year
    
    NSDateComponents *componentsMin = [calendar components:(NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear) fromDate:[NSDate date]];
    componentsMin.year = componentsMin.year - M328_USER_DATA_AGE_MAXIMUM;
//    componentsMin.month = 1; // January
//    componentsMin.day = 1; // 1st of January.
    
    NSDateComponents *componentsDefault = [calendar components:(NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear) fromDate:[NSDate date]];
    componentsDefault.year = componentsDefault.year - 30;

    [_datePicker setMinimumDate:[calendar dateFromComponents:componentsMin]];
    [_datePicker setMaximumDate:[calendar dateFromComponents:componentsMax]];
    
    // Making relastic date
    componentsMin.year = componentsMin.year + M328_USER_STATIC_AGE;
    componentsMin.month = 1;
    componentsMin.day = 1;
    _datePicker.date = [calendar dateFromComponents:componentsDefault];
    
    self.navigationItem.titleView = [iDevicesUtil getNavigationTitle];
    infoLabel.attributedText = [self getAttributedStrWithText:NSLocalizedString(@"birthdate?",nil) formatStr:NSLocalizedString(@"When is\nyour birthdate?",nil)];
    
    [nextButton setTitle:[NSString stringWithFormat:@"%@  ", NSLocalizedString(@"NEXT", nil)] forState:UIControlStateNormal];
    nextButton.transform = CGAffineTransformMakeScale(-1.0, 1.0);
    nextButton.titleLabel.transform = CGAffineTransformMakeScale(-1.0, 1.0);
    nextButton.imageView.transform = CGAffineTransformMakeScale(-1.0, 1.0);
    [nextButton setTitleColor:UIColorFromRGB(AppColorRed) forState:UIControlStateNormal];
    nextButton.tintColor = UIColorFromRGB(AppColorRed);
    
    if (IS_IPAD) {
        infoLblTopConstraint.constant = 70;
        infoBtnleftConstraint.constant = 60;
        infoLblleftConstraint.constant = 60;
        infoLblBottomContraint.constant = 30;
        infoBtnBottomContraint.constant = ((ScreenHeight)/2)- 30 - 70 - M328_REGISTRATION_BOTTOM_CONSTRAINT_MINUSVALUE;
    } else {
        infoLblleftConstraint.constant = 40;
        infoBtnleftConstraint.constant = 30;
        dobLblTopContraint.constant = 30;
        infoBtnBottomContraint.constant = ((ScreenHeight)/2) - 70 - M328_REGISTRATION_BOTTOM_CONSTRAINT_MINUSVALUE;
    }
    
    progressLbl.backgroundColor = UIColorFromRGB(AppColorRed);
    progressLblWidthContraint.constant = ScreenWidth * ([iDevicesUtil getProgressBarValueBasedOnRegistrationEnum:birthdate]);
    
    [infoButton setImage:[[UIImage imageNamed:@"info_icon"] imageWithTint: UIColorFromRGB(INFO_ICON_TINT_COLOR)] forState:UIControlStateNormal];
    [infoButton setTitle:NSLocalizedString(infoButton.currentTitle, nil) forState:UIControlStateNormal];
    
    UIButton *backBtn = [iDevicesUtil getBackButton];
    [backBtn addTarget:self action:@selector(backButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barBtn = [[UIBarButtonItem alloc] initWithCustomView:backBtn];
    self.navigationItem.leftBarButtonItem = barBtn;
    

    [self updateDOB];
    [_datePicker addTarget:self action:@selector(datePickerValueChanged:) forControlEvents:UIControlEventValueChanged];
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))  {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    if ([TDM328WatchSettingsUserDefaults dateOfBirth])
    {
        _datePicker.date = [TDM328WatchSettingsUserDefaults dateOfBirth];
    }
}

- (IBAction)clickedOnInfoBtn:(id)sender {
    [self showAlertViewWithText:NSLocalizedString(@"This information is used only to help improve the accuracy of activity data. It will not be used for marketing purposes or shared with any third parties.",nil)];
    //    WebViewController *webVC=[[WebViewController alloc] initWithNibName:@"WebViewController" bundle:nil];
    //    [self.navigationController pushViewController:webVC animated:YES];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateDOB];
}

- (NSAttributedString *)getAttributedStrWithText:(NSString *)textStr formatStr:(NSString *)formatStr
{
    UIFont *formatFont = [UIFont fontWithName: [iDevicesUtil getAppWideFontName] size:M328_REGISTRATION_BIG_TITLE_FONTSIZE];
    NSDictionary *atrsDict = [NSDictionary dictionaryWithObjectsAndKeys:formatFont, NSFontAttributeName, UIColorFromRGB(COLOR_DEFAULT_TIMEX_FONT),NSForegroundColorAttributeName, nil];
    NSMutableAttributedString *formatAtrStr = [[NSMutableAttributedString alloc] initWithString:formatStr attributes:atrsDict];
    
    UIFont *textFont = [UIFont fontWithName:[iDevicesUtil getAppWideMediumFontName] size:M328_REGISTRATION_BIG_TITLE_FONTSIZE];
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:textFont, NSFontAttributeName, UIColorFromRGB(AppColorRed),NSForegroundColorAttributeName, nil];
    NSRange formatStrRange = [formatStr rangeOfString:textStr];
    [formatAtrStr setAttributes:dict range:formatStrRange];
    
    return formatAtrStr;
}

-(void)updateDOB
{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"MMMM dd yyyy"];
    
    _dobTextLbl.text = [[df stringFromDate:[_datePicker date]] uppercaseString];
    
}
-(void)datePickerValueChanged:(id)sender
{
    [self updateDOB];
}
- (void)didReceiveMemoryWarning {
     OTLog([NSString stringWithFormat:@"Recived Memory Warning  in %@ ",NSStringFromClass([self class])]);
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)backButtonTapped:(id)sender
{
    [self getYears];
    [TDM328WatchSettingsUserDefaults setAge:years];
    [TDM328WatchSettingsUserDefaults setDateOfBirth:_datePicker.date];
    
    [self.navigationController popViewControllerAnimated:YES];
}


- (IBAction)nextButtonTapped:(id)sender
{
    [self getYears];
    if (years >= 5)
    {
        [TDM328WatchSettingsUserDefaults setAge:years];
        [TDM328WatchSettingsUserDefaults setDateOfBirth:_datePicker.date];
        
        HeightViewController *heightVC=[[HeightViewController alloc] initWithNibName:@"HeightViewController" bundle:nil];
        [self.navigationController pushViewController:heightVC animated:YES];
    }
    else
    {
        [self showAlertViewWithText:NSLocalizedString(@"", nil)];
    }
}

- (void)getYears
{
    NSDate *dateA = _datePicker.date;
    NSDate *dateB = [NSDate date];
    
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay
                                               fromDate:dateA
                                                 toDate:dateB
                                                options:0];
    
    years = (int)components.year;
}

- (void)showAlertViewWithText:(NSString *)text {
    TDAppDelegate *delegate = (TDAppDelegate *)[[UIApplication sharedApplication] delegate];
    [delegate showAlertWithTitle:nil Message:text andButtonTitle:NSLocalizedString(@"Ok",nil)];
    
}
@end
