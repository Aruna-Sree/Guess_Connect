//
//  ConfigureSubdialViewController.m
//  Timex
//
//  Created by avemulakonda on 5/4/16.
//

#import "ConfigureSubdialViewController.h"
#import "ConfigureSecondsViewController.h"
#import "iDevicesUtil.h"
#import "TDDefines.h"
#import "TDM328WatchSettings.h"
#import "TDM328WatchSettingsUserDefaults.h"
#import "OTLogUtil.h"

@interface ConfigureSubdialViewController () {
     typeM328ActivityDisplay calibrationType;
}

@end

@implementation ConfigureSubdialViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))  {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    if(_openedByMenu)
    {
        _NextButton.hidden = YES;
    }
    
    selectedButton.layer.cornerRadius = 15;
    
    UIButton *backBtn = [iDevicesUtil getBackButton];
    [backBtn addTarget:self action:@selector(backButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barBtn = [[UIBarButtonItem alloc] initWithCustomView:backBtn];
    self.navigationItem.leftBarButtonItem = barBtn;
    
    self.navigationItem.titleView = [iDevicesUtil getNavigationTitle];
    infoLabel.attributedText = [self getAttributedStrWithText:NSLocalizedString(@"Which goal would you like to see?",nil) formatStr:NSLocalizedString(@"\n\nSteps or distance? Choose the daily goal you would like to display on the activity sub-dial.",nil)];
    if (IS_IPAD) {
        infoLblTopConstraint.constant = 70;
        infoLblleftConstraint.constant = infoLblRightConstraint.constant = 60;
        nextButtonBottomContraint.constant = 40;
    } else {
        infoLblleftConstraint.constant = infoLblRightConstraint.constant = 40;
    }
    infoLblBottomContraint.constant = ((ScreenHeight)/2) - 70 - M328_REGISTRATION_BOTTOM_CONSTRAINT_MINUSVALUE;

    progressLbl.backgroundColor = UIColorFromRGB(AppColorRed);
    progressLblWidthContraint.constant = ScreenWidth * ([iDevicesUtil getProgressBarValueBasedOnRegistrationEnum:configureSubDial]);
    
    [_NextButton setTitle:[NSString stringWithFormat:@"%@  ", NSLocalizedString(@"NEXT", nil)] forState:UIControlStateNormal];
    _NextButton.transform = CGAffineTransformMakeScale(-1.0, 1.0);
    _NextButton.titleLabel.transform = CGAffineTransformMakeScale(-1.0, 1.0);
    _NextButton.imageView.transform = CGAffineTransformMakeScale(-1.0, 1.0);
    [_NextButton setTitleColor:UIColorFromRGB(AppColorRed) forState:UIControlStateNormal];
    _NextButton.tintColor = UIColorFromRGB(AppColorRed);
}

-(void) backButtonTapped
{
    [TDM328WatchSettingsUserDefaults setDisplaySubDial:calibrationType];
    
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
    int row = (int)[TDM328WatchSettingsUserDefaults displaySubDial];
    [pickView selectRow:row inComponent:0 animated:NO];
    [self pickerView:pickView didSelectRow:row inComponent:0];
}

- (void)didReceiveMemoryWarning {
     OTLog([NSString stringWithFormat:@"Recived Memory Warning  in %@ ",NSStringFromClass([self class])]);
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSAttributedString *)getAttributedStrWithText:(NSString *)textStr formatStr:(NSString *)formatStr {
    
    UIFont *textFont = [UIFont fontWithName:[iDevicesUtil getAppWideMediumFontName] size:M328_REGISTRATION_TITLE_FONTSIZE];
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:textFont, NSFontAttributeName, [UIColor blackColor],NSForegroundColorAttributeName, nil];
    NSMutableAttributedString *textAtrStr = [[NSMutableAttributedString alloc] initWithString:textStr attributes:dict];
    
    UIFont *formatFont = [UIFont fontWithName: [iDevicesUtil getAppWideFontName] size:M328_REGISTRATION_INFO_FONTSIZE];
    NSDictionary *atrsDict = [NSDictionary dictionaryWithObjectsAndKeys:formatFont, NSFontAttributeName, UIColorFromRGB(COLOR_DEFAULT_TIMEX_FONT),NSForegroundColorAttributeName, nil];
    NSAttributedString *formatAtrStr = [[NSAttributedString alloc] initWithString:formatStr attributes:atrsDict];
    [textAtrStr appendAttributedString:formatAtrStr];
    
    return textAtrStr;
}

- (IBAction)nextButtonTapped:(id)sender {
      [TDM328WatchSettingsUserDefaults setDisplaySubDial:calibrationType];
    // Need to calibrate managed object based on user selected type: Present creating for distance
    
    ConfigureSecondsViewController *configureVC = [[ConfigureSecondsViewController alloc] initWithNibName:@"ConfigureSecondsViewController" bundle:nil];
    [self.navigationController pushViewController:configureVC animated:YES];
}

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return 2;
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
    }
    [tView setTextColor:UIColorFromRGB(COLOR_DEFAULT_TIMEX_FONT)];
    tView.textAlignment = NSTextAlignmentCenter;
    if (row == M328_DISTANCE_PERC_GOAL)
    {
        [tView setText:NSLocalizedString(@"DISTANCE",nil)];
    }
    else
    {
        [tView setText:NSLocalizedString(@"STEPS",nil)];
    }
    return tView;
}
-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    for (int i = 0; i < 2; i++)
    {
        UILabel *view = (UILabel*)[pickerView viewForRow:i forComponent:0];
        [view setTextColor:UIColorFromRGB(COLOR_DEFAULT_TIMEX_FONT)];
    }
    UILabel *view = (UILabel*)[pickerView viewForRow:row forComponent:0];
    if (row == M328_DISTANCE_PERC_GOAL)
    {
        calibrationType = M328_DISTANCE_PERC_GOAL;
        [watchImage setImage:[UIImage imageNamed:@"WatchWithDistance"]];
        [view setTextColor:UIColorFromRGB(M328_DISTANCE_COLOR)];
    }
    else
    {
        calibrationType = M328_STEPS_PERC_GOAL;
        [watchImage setImage:[UIImage imageNamed:@"WatchWithSteps"]];
        [view setTextColor:UIColorFromRGB(M328_STEPS_COLOR)];
    }
}
@end
