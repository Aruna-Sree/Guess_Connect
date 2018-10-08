//
//  NameViewController.m
//  Timex-iOS
//
//  Created by kpasupuleti on 5/4/16.
//

#import "UnitViewController.h"
#import "NameViewController.h"
#import "iDevicesUtil.h"
#import "TDDefines.h"
#import "UIImage+Tint.h"
#import "TDAppDelegate.h"
#import "TDM328WatchSettingsUserDefaults.h"
#import "OTLogUtil.h"
#import "TDWatchProfile.h"
@interface UnitViewController () {
    int selectedUnits;
}

@end

@implementation UnitViewController

#pragma  mark Life Cycle Methods

- (void)viewDidLoad {
    [super viewDidLoad];

    selectedUnits = -1;
    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQ || [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel) {
        if ([TDM328WatchSettingsUserDefaults units] == 0)
        {
            [self unitButtonTapped:imperialBtn];
        }
        
        if ([TDM328WatchSettingsUserDefaults units] == 1)
        {
            [self unitButtonTapped:metricBtn];
        }
    } else {
        NSString *unitsKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM372_PropertyClass_General andIndex: programWatchM372_PropertyClass_General_UnitOfMeasure];
        if ([[NSUserDefaults standardUserDefaults] integerForKey:unitsKey] == programWatchActivityTracker_PropertyClass_General_Units_Metric) {
            [self unitButtonTapped:metricBtn];
        } else {
            [self unitButtonTapped:imperialBtn];
        }
    }

    
    self.navigationItem.titleView = [iDevicesUtil getNavigationTitle];
   
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))  {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    infoLabel.attributedText = [self getAttributedStrWithText:NSLocalizedString(@"units",nil) formatStr:NSLocalizedString(@"Which units would you like to use?",nil)];
    if (IS_IPAD) {
        infoLblTopConstraint.constant = 70;
        infoLblleftConstraint.constant = 60;
    } else {
        infoLblleftConstraint.constant = 40;
        fieldViewTopContraint.constant = 30;
    }
    infoLblBottomContraint.constant = ((ScreenHeight)/2) - 70 - M328_REGISTRATION_BOTTOM_CONSTRAINT_MINUSVALUE ;
    
    progressLbl.backgroundColor = UIColorFromRGB(AppColorRed);
    progressLblWidthContraint.constant = ScreenWidth * ([iDevicesUtil getProgressBarValueBasedOnRegistrationEnum:nameandsex]);
    
    
    UIButton *backBtn = [iDevicesUtil getBackButton];
    [backBtn addTarget:self action:@selector(backButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barBtn = [[UIBarButtonItem alloc] initWithCustomView:backBtn];
    self.navigationItem.leftBarButtonItem = barBtn;
    
    [imperialBtn.titleLabel setFont:[UIFont fontWithName: [iDevicesUtil getAppWideBoldFontName] size:M328_REGISTRATION_INFO_FONTSIZE]];
    [metricBtn.titleLabel setFont:[UIFont fontWithName: [iDevicesUtil getAppWideBoldFontName] size:M328_REGISTRATION_INFO_FONTSIZE]];
    
    [imperialBtn setTitle:NSLocalizedString(@"IMPERIAL", nil) forState:UIControlStateNormal];
    [metricBtn setTitle:NSLocalizedString(@"METRIC", nil) forState:UIControlStateNormal];
    
    [milesLabel setText:NSLocalizedString(@"(MILES)", nil)];
    [kiloMetersLabel setText:NSLocalizedString(@"(KILOMETERS)", nil)];
    
    [nextButton setTitle:[NSString stringWithFormat:@"%@  ", NSLocalizedString(@"NEXT", nil)] forState:UIControlStateNormal];
    nextButton.transform = CGAffineTransformMakeScale(-1.0, 1.0);
    nextButton.titleLabel.transform = CGAffineTransformMakeScale(-1.0, 1.0);
    nextButton.imageView.transform = CGAffineTransformMakeScale(-1.0, 1.0);
    nextButton.tintColor = UIColorFromRGB(AppColorRed);
    [nextButton setTitleColor:UIColorFromRGB(AppColorRed) forState:UIControlStateNormal];
}

- (void)addBottomBorderToTextField :(UITextField *)textfield {
    CALayer *border = [CALayer layer];
    CGFloat borderWidth = 1;
    border.borderColor = (UIColorFromRGB(M328_TABLEVIEW_HEADER_GRAY_COLOR)).CGColor;
    border.frame = CGRectMake(0, textfield.frame.size.height - borderWidth, textfield.frame.size.width, textfield.frame.size.height);
    border.borderWidth = borderWidth;
    [textfield.layer addSublayer:border];
    textfield.layer.masksToBounds = YES;
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

#pragma  mark Button Actions

-(IBAction) backButtonTapped:(id)sender
{
    if (selectedUnits != -1) {
        [self setUnits];
    }
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)setUnits {
    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQ || [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel) {
        [TDM328WatchSettingsUserDefaults setUnits:selectedUnits];
    }
    else {
        NSString *unitsKey = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM372_PropertyClass_General andIndex: programWatchM372_PropertyClass_General_UnitOfMeasure];
        if (selectedUnits == 0) {
            [[NSUserDefaults standardUserDefaults] setInteger: programWatchActivityTracker_PropertyClass_General_Units_Imperial forKey: unitsKey];
        } else {
            [[NSUserDefaults standardUserDefaults] setInteger: programWatchActivityTracker_PropertyClass_General_Units_Metric forKey: unitsKey];
        }
    }
}
-(IBAction)unitButtonTapped:(UIButton *)sender
{
    if (sender.tag == 1) {
        selectedUnits = 0;
        [imperialBtn setTitleColor:UIColorFromRGB(AppColorRed) forState:UIControlStateNormal];
        [metricBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    } else {
        selectedUnits = 1;
        [imperialBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [metricBtn setTitleColor:UIColorFromRGB(AppColorRed) forState:UIControlStateNormal];
    }
}

- (IBAction)nextButtonTapped:(id)sender
{
    if (selectedUnits == -1)
    {
        [self showAlertViewWithText:NSLocalizedString(@"Please select units",nil)];
    }
    else
    {
        [self setUnits];
        if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQ || [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel) {
            NameViewController *nameVC=[[NameViewController alloc] initWithNibName:@"NameViewController" bundle:nil];
            [self.navigationController pushViewController:nameVC animated:YES];
        }
    }
}

- (void)showAlertViewWithText:(NSString *)text {
    TDAppDelegate *delegate = (TDAppDelegate *)[[UIApplication sharedApplication] delegate];
    [delegate showAlertWithTitle:nil Message:text andButtonTitle:NSLocalizedString(@"Ok",nil)];
}
@end
