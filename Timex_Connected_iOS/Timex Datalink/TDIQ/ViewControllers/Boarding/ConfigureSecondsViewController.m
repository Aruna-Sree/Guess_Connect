//
//  ConfigureSecondsViewController.m
//  Timex
//
//  Created by avemulakonda on 5/4/16.
//

#import "ConfigureSecondsViewController.h"
#import "SetupWatchViewController.h"
#import "iDevicesUtil.h"
#import "TDDefines.h"
#import "TDM328WatchSettings.h"
#import "TDM328WatchSettingsUserDefaults.h"
#import "TDM329WatchSettings.h"
#import "TDM329WatchSettingsUserDefaults.h"
#import "OTLogUtil.h"
#import "TDAppDelegate.h"
#import "TDWatchProfile.h"

@interface ConfigureSecondsViewController () {
     typeM329SecondHandOperation calibrationType;
    CustomTabbar *customTabbar;
    BOOL setupDone;
}

@end

@implementation ConfigureSecondsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))  {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }

    if(_openedByMenu)
    {
        TDAppDelegate *appdel = (TDAppDelegate *)[[UIApplication sharedApplication] delegate];
        customTabbar = appdel.customTabbar;
        progressLbl.hidden = YES;
        if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQ)
        {
            _nextButton.hidden = YES;
        }
    }
    
    [self showLeftBarButtonItem:YES];
    
    self.navigationItem.titleView = [iDevicesUtil getNavigationTitle];
    infoLabel.attributedText = [self getAttributedStrWithText:NSLocalizedString(@"Just a second...",nil) formatStr:NSLocalizedString(@"\n\nThe second hand is not just for telling time. It can show your daily activity totals or date. Choose what you want to indicate with the second hand.",nil)];
    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)
    {
        infoLabel.attributedText = [self getAttributedStrWithText:NSLocalizedString(@"What do you want your second hand to always display?",nil) formatStr:NSLocalizedString(@"\n\nChoose an option below.",nil)];
    }
    if (IS_IPAD) {
        infoLblTopConstraint.constant = 70;
        infoLblleftConstraint.constant = infoLblRightConstraint.constant = 60;
        nextButtonBottomContraint.constant = 40;
    } else {
        infoLblleftConstraint.constant = infoLblRightConstraint.constant = 40;
        if (ScreenHeight <= 568) {
            infoLblleftConstraint.constant = infoLblRightConstraint.constant = 20;
        }
    }
    infoLblBottomContraint.constant = ((ScreenHeight)/2) - 70 - M328_REGISTRATION_BOTTOM_CONSTRAINT_MINUSVALUE;
    
    progressLbl.backgroundColor = UIColorFromRGB(AppColorRed);
    progressLblWidthContraint.constant = ScreenWidth * ([iDevicesUtil getProgressBarValueBasedOnRegistrationEnum:configureSubDial]);
    
    [_nextButton setTitle:[NSString stringWithFormat:@"%@  ", NSLocalizedString(@"NEXT", nil)] forState:UIControlStateNormal];
    _nextButton.transform = CGAffineTransformMakeScale(-1.0, 1.0);
    _nextButton.titleLabel.transform = CGAffineTransformMakeScale(-1.0, 1.0);
    _nextButton.imageView.transform = CGAffineTransformMakeScale(-1.0, 1.0);
    [_nextButton setTitleColor:UIColorFromRGB(AppColorRed) forState:UIControlStateNormal];
    _nextButton.tintColor = UIColorFromRGB(AppColorRed);
}

- (void)showLeftBarButtonItem:(BOOL)show {
    if (show) {
        UIButton *backBtn = [iDevicesUtil getBackButton];
        [backBtn addTarget:self action:@selector(backButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *barBtn = [[UIBarButtonItem alloc] initWithCustomView:backBtn];
        self.navigationItem.leftBarButtonItem = barBtn;
    } else {
        self.navigationItem.leftBarButtonItem = nil;
    }
}
-(void) backButtonTapped
{
    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)
    {
        [TDM329WatchSettingsUserDefaults setSecondHandMode:calibrationType];
        if ([TDM329WatchSettingsUserDefaults secondHandMode] == M329_DISPLAY_STEPS)
        {
            [TDM329WatchSettingsUserDefaults setPB4DisplayFunction:M329_DISTANCE_PERC_GOAL];
        }
        else if ([TDM329WatchSettingsUserDefaults secondHandMode] == M329_DISPLAY_DISTANCE)
        {
            [TDM329WatchSettingsUserDefaults setPB4DisplayFunction:M329_STEPS_PERC_GOAL];
        }
    }
    else
    {
        [TDM328WatchSettingsUserDefaults setSecondHandMode:calibrationType];
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationItem.hidesBackButton = YES;
}

-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    if (!setupDone)
    {
        int row = 1;
        if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)
        {
            switch ([TDM329WatchSettingsUserDefaults secondHandMode])
            {
                case M329_DISPLAY_DATE:
                    row = 3;
                    break;
                case M329_DISPLAY_DISTANCE:
                    row = 1;
                    break;
                case M329_DISPLAY_STEPS:
                    row = 0;
                    break;
                case DISPLAY_TZ3:
                    row = 4;
                    break;
                default:
                    row = 2;
                    break;
            }
        }
        else
        {
            switch ([TDM328WatchSettingsUserDefaults secondHandMode])
            {
                case M328_DISPLAY_DATE:
                    row = 0;
                    break;
                case M328_DISPLAY_DISTANCE:
                    row = 3;
                    break;
                case M328_DISPLAY_STEPS:
                    row = 2;
                    break;
                default:
                    row = 1;
                    break;
            }
        }
        [secondsPicker selectRow:row inComponent:0 animated:NO];
        [self pickerView:secondsPicker didSelectRow:row inComponent:0];
    }
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    setupDone = YES;
}

- (void)didReceiveMemoryWarning
{
     OTLog([NSString stringWithFormat:@"Recived Memory Warning  in %@ ",NSStringFromClass([self class])]);
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSAttributedString *)getAttributedStrWithText:(NSString *)textStr formatStr:(NSString *)formatStr
{
    
    UIFont *textFont = [UIFont fontWithName:[iDevicesUtil getAppWideMediumFontName] size:M328_REGISTRATION_TITLE_FONTSIZE];
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:textFont, NSFontAttributeName, [UIColor blackColor],NSForegroundColorAttributeName, nil];
    NSMutableAttributedString *textAtrStr = [[NSMutableAttributedString alloc] initWithString:textStr attributes:dict];
    
    UIFont *formatFont = [UIFont fontWithName: [iDevicesUtil getAppWideFontName] size:M328_REGISTRATION_INFO_FONTSIZE];
    NSDictionary *atrsDict = [NSDictionary dictionaryWithObjectsAndKeys:formatFont, NSFontAttributeName, UIColorFromRGB(COLOR_DEFAULT_TIMEX_FONT),NSForegroundColorAttributeName, nil];
    NSAttributedString *formatAtrStr = [[NSAttributedString alloc] initWithString:formatStr attributes:atrsDict];
    [textAtrStr appendAttributedString:formatAtrStr];
    
    return textAtrStr;
}

- (IBAction)nextButtonTapped:(id)sender
{
    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)
    {
        [TDM329WatchSettingsUserDefaults setSecondHandMode:calibrationType];
    }
    else
    {
        [TDM328WatchSettingsUserDefaults setSecondHandMode:calibrationType];
    }
    SetupWatchViewController *setupWatch = [[SetupWatchViewController alloc] initWithNibName:@"SetupWatchViewController" bundle:nil];
    [self.navigationController pushViewController:setupWatch animated:YES];
}

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)
        return 5;
    return 4;
}
-(CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
{
    return 30;
}
-(UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view
{
    UILabel *tView = (UILabel*)view;
    if (!tView)
    {
        tView = [[UILabel alloc] init];
        [tView setFont:[UIFont fontWithName:[iDevicesUtil getAppWideBoldFontName] size:18]];
        tView.textAlignment = NSTextAlignmentCenter;
    }
    if (row == 0)
    {
        [tView setText:NSLocalizedString(@"PERFECT DATE",nil)];
    }
    else if (row == 1)
    {
        [tView setText:NSLocalizedString(@"SECONDS",nil)];
    }
    else if (row == 2)
    {
        [tView setText:NSLocalizedString(@"STEPS",nil)];
    }
    else if (row == 3)
    {
        [tView setText:NSLocalizedString(@"DISTANCE",nil)];
    }
    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)
    {
        switch (row)
        {
            case 0:
                [tView setText:NSLocalizedString(@"STEPS",nil)];
                break;
            case 1:
                [tView setText:NSLocalizedString(@"DISTANCE",nil)];
                break;
            case 3:
                [tView setText:NSLocalizedString(@"PERFECT DATE",nil)];
                break;
            case 4:
                [tView setText:NSLocalizedString(@"3RD TIME ZONE",nil)];
                break;
            default:
                [tView setText:NSLocalizedString(@"SECONDS",nil)];
                break;
        }
    }
    [tView setTextColor:UIColorFromRGB(COLOR_DEFAULT_TIMEX_FONT)];
    return tView;
}
-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    for (int i = 0; i < [pickerView numberOfRowsInComponent:component]; i++)
    {
        UILabel *view = (UILabel*)[pickerView viewForRow:i forComponent:0];
        [view setTextColor:UIColorFromRGB(COLOR_DEFAULT_TIMEX_FONT)];
    }
    UILabel *view = (UILabel*)[pickerView viewForRow:row forComponent:0];
    
    if (row == 0)
    {
        calibrationType = M329_DISPLAY_DATE;
        watchImage.image = [UIImage imageNamed:@"SecondsDate"];
        [view setTextColor:UIColorFromRGB(M328_DATE_MAGENTA)];
    }
    else if (row == 1)
    {
        calibrationType = M329_DISPLAY_SECONDS;
        watchImage.image = [UIImage imageNamed:@"SecondsSeconds"];
        [view setTextColor:UIColorFromRGB(M328_SECONDS_GREEN)];
    }
    else if (row == 2)
    {
        calibrationType = M329_DISPLAY_STEPS;
        watchImage.image = [UIImage imageNamed:@"SecondsSteps"];
        [view setTextColor:UIColorFromRGB(M328_STEPS_COLOR)];
    }
    else
    {
        calibrationType = M329_DISPLAY_DISTANCE;
        watchImage.image = [UIImage imageNamed:@"SecondsDistance"];
        [view setTextColor:UIColorFromRGB(M328_DISTANCE_COLOR)];
    }
    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)
    {
        [self showLeftBarButtonItem:YES];
        if (row == 0)
        {
            calibrationType = M329_DISPLAY_STEPS;
            watchImage.image = [UIImage imageNamed:@"TravelSecSteps"];
        }
        else if (row == 1)
        {
            calibrationType = M329_DISPLAY_DISTANCE;
            watchImage.image = [UIImage imageNamed:@"TravelSecDistance"];
        }
        else if (row == 2)
        {
            calibrationType = M329_DISPLAY_SECONDS;
            watchImage.image = [UIImage imageNamed:@"TravelSecSeconds"];
        }
        else if (row == 3)
        {
            calibrationType = M329_DISPLAY_DATE;
            watchImage.image = [UIImage imageNamed:@"TravelSecDate"];
        }
        else
        {
            calibrationType = DISPLAY_TZ3;
            watchImage.image = [UIImage imageNamed:@"TravelSecTZ"];
            [self showLeftBarButtonItem:NO];
        }
        [view setTextColor:UIColorFromRGB(M328_STEPS_COLOR)];
    }
    if (_openedByMenu)
        [customTabbar syncNeeded];
}
@end
