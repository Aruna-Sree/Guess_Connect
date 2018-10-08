//
//  WeightViewController.m
//  Timex
//
//  Created by avemulakonda on 5/4/16.
//

#import "WeightViewController.h"
#import "StartSleepTimeViewController.h"
#import "iDevicesUtil.h"
#import "TDDefines.h"
#import "UIImage+Tint.h"
#import "TDAppDelegate.h"
#import "TDM328WatchSettingsUserDefaults.h"
#import "OTLogUtil.h"
@interface WeightViewController () {
    float weigth;
    TDAppDelegate *appDelegate;
}

@end

@implementation WeightViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    appDelegate = (TDAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))  {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    self.navigationItem.titleView = [iDevicesUtil getNavigationTitle];
    infoLabel.attributedText = [self getAttributedStrWithText:NSLocalizedString(@"weight?",nil) formatStr:NSLocalizedString(@"What is\nyour weight?",nil)];
    
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
    progressLblWidthContraint.constant = ScreenWidth * ([iDevicesUtil getProgressBarValueBasedOnRegistrationEnum:weight]);
    
    
    UIButton *backBtn = [iDevicesUtil getBackButton];
    [backBtn addTarget:self action:@selector(backButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barBtn = [[UIBarButtonItem alloc] initWithCustomView:backBtn];
    self.navigationItem.leftBarButtonItem = barBtn;
    
    
    /////
    UIToolbar* numberToolbar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, 0, ScreenWidth, NUMBER_TOOLBAR_HEIGHT)];
    numberToolbar.barStyle = UIBarStyleDefault;
    numberToolbar.translucent = YES;
    numberToolbar.barTintColor = [UIColor whiteColor];
    
    UIButton *nextBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    nextBtn.frame = CGRectMake(0, 0, self.view.frame.size.width, NUMBER_TOOLBAR_HEIGHT);
    [nextBtn setTitleColor:UIColorFromRGB(AppColorRed) forState:UIControlStateNormal];
    [nextBtn.titleLabel setFont:[UIFont fontWithName:[iDevicesUtil getAppWideBoldFontName] size:13]];
    [nextBtn setImage:[[UIImage imageNamed:@"arrow_right"] imageWithTint:UIColorFromRGB(AppColorRed)] forState:UIControlStateNormal];
    
    [nextBtn setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
    [nextBtn setContentVerticalAlignment:UIControlContentHorizontalAlignmentCenter];
    
    [nextBtn setTitle:[NSString stringWithFormat:@"%@  ", NSLocalizedString(@"NEXT", nil)] forState:UIControlStateNormal];
    nextBtn.transform = CGAffineTransformMakeScale(-1.0, 1.0);
    nextBtn.titleLabel.transform = CGAffineTransformMakeScale(-1.0, 1.0);
    nextBtn.imageView.transform = CGAffineTransformMakeScale(-1.0, 1.0);
    nextBtn.tintColor = UIColorFromRGB(AppColorRed);
    [nextBtn addTarget:self action:@selector(nextButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    numberToolbar.items = @[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                            [[UIBarButtonItem alloc] initWithCustomView:nextBtn]];
    weightTextField.inputAccessoryView = numberToolbar;
    
    [self addBottomBorderToTextField:weightTextField];
    
    if ([iDevicesUtil isMetricSystem]) {
        weightlbl.text = NSLocalizedString(@"kg",nil);
        weightTextField.text = @"";
    } else {
        weightlbl.text = NSLocalizedString(@"lbs",nil);
        weightTextField.text = @"";
    }
    
    if ([TDM328WatchSettingsUserDefaults userWeight])
    {
        float weightTemp = (float)[TDM328WatchSettingsUserDefaults userWeight] / 10;
        weightTextField.text = [NSString stringWithFormat:@"%d", (int)roundf(weightTemp)];
        if (![iDevicesUtil isMetricSystem]) {
            weightTextField.text = [NSString stringWithFormat:@"%d", (int)roundf([iDevicesUtil convertKilogramsToPounds:weightTemp])];
        }
    }
    [infoBtn setImage:[[UIImage imageNamed:@"info_icon"] imageWithTint: UIColorFromRGB(INFO_ICON_TINT_COLOR)] forState:UIControlStateNormal];
    [infoBtn setTitle:NSLocalizedString(infoBtn.currentTitle, nil) forState:UIControlStateNormal];
}

- (IBAction)clickedOnInfoBtn:(id)sender {
    [self showAlertViewWithText:NSLocalizedString(@"This information is used only to help improve the accuracy of activity data. It will not be used for marketing purposes or shared with any third parties.",nil)];
    //    WebViewController *webVC=[[WebViewController alloc] initWithNibName:@"WebViewController" bundle:nil];
    //    [self.navigationController pushViewController:webVC animated:YES];
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

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [weightTextField becomeFirstResponder];
    if (ScreenHeight <= 480) {
        dobLblTopContraint.constant = 10;
        [UIView animateWithDuration:0.3 animations:^{
            CGRect f = self.view.frame;
            f.origin.y = -5;
            self.view.frame = f;
        }];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    OTLog([NSString stringWithFormat:@"Recived Memory Warning  in %@ ",NSStringFromClass([self class])]);
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)backButtonTapped:(id)sender
{
    bool goodInput = YES;
    int weightValue = [weightTextField.text intValue];
    if ([iDevicesUtil isMetricSystem]) {
        if (weightValue < M328_USER_DATA_WEIGHT_MINIMUM_KILOS/10) {
            goodInput = NO;
        } else if (weightValue > M328_USER_DATA_WEIGHT_MAXIMUM_KILOS/10) {
            goodInput = NO;
        }
    } else {
        if (weightValue < (int)[iDevicesUtil convertKilogramsToPounds:M328_USER_DATA_WEIGHT_MINIMUM_KILOS/10]) {
            goodInput = NO;
        } else if (weightValue > (int)[iDevicesUtil convertKilogramsToPounds:M328_USER_DATA_WEIGHT_MAXIMUM_KILOS/10]) {
            goodInput = NO;
        }
    }
    
    if (goodInput)
        [self saveWeightToUserDefauls];
    
    [self.navigationController popViewControllerAnimated:YES];
}


- (IBAction)nextButtonTapped:(id)sender
{
    if ([self validateFields]) {
        [self saveWeightToUserDefauls];
        StartSleepTimeViewController *startSleepVC = [[StartSleepTimeViewController alloc] initWithNibName:@"StartSleepTimeViewController" bundle:nil];
        startSleepVC.isAwakeVC = NO;
        [self.navigationController pushViewController:startSleepVC animated:YES];
    }
}
- (void)saveWeightToUserDefauls {
    if (weightTextField.text.length > 0) {
        float valueWeight = [weightTextField.text floatValue];
        if (![iDevicesUtil isMetricSystem]) {
            valueWeight = [iDevicesUtil convertPoundsToKilograms:valueWeight];
        }
        weigth = valueWeight;
        [weightTextField setBackgroundColor:[UIColor clearColor]];
        [weightTextField resignFirstResponder];
        [TDM328WatchSettingsUserDefaults setUserWeight:(int)(weigth*10)];
    }
}

- (void)showAlertViewWithText:(NSString *)text {
    TDAppDelegate *delegate = (TDAppDelegate *)[[UIApplication sharedApplication] delegate];
    [delegate showAlertWithTitle:nil Message:text andButtonTitle:NSLocalizedString(@"Ok", nil)];
}
- (BOOL)validateFields {
    int weightValue = [weightTextField.text intValue];
    if ([iDevicesUtil isMetricSystem]) {
        if (weightValue < M328_USER_DATA_WEIGHT_MINIMUM_KILOS/10) {
            [self showAlertViewWithText:[NSString stringWithFormat:NSLocalizedString(@"Please enter minimum %d kg",nil),(int)M328_USER_DATA_WEIGHT_MINIMUM_KILOS/10]];
            return NO;
        } else if (weightValue > M328_USER_DATA_WEIGHT_MAXIMUM_KILOS/10) {
            [self showAlertViewWithText:[NSString stringWithFormat:NSLocalizedString(@"Please enter maximum %d kg",nil),(int)M328_USER_DATA_WEIGHT_MAXIMUM_KILOS/10]];
            return NO;
        }
    } else {
        if (weightValue < round([iDevicesUtil convertKilogramsToPounds:M328_USER_DATA_WEIGHT_MINIMUM_KILOS/10])) {
            [self showAlertViewWithText:[NSString stringWithFormat:NSLocalizedString(@"Please enter minimum %d lbs",nil),(int)[iDevicesUtil convertKilogramsToPounds:M328_USER_DATA_WEIGHT_MINIMUM_KILOS/10]]];
            return NO;
        } else if (weightValue > round([iDevicesUtil convertKilogramsToPounds:M328_USER_DATA_WEIGHT_MAXIMUM_KILOS/10])) {
            [self showAlertViewWithText:[NSString stringWithFormat:NSLocalizedString(@"Please enter maximum %d lbs",nil),(int)[iDevicesUtil convertKilogramsToPounds:M328_USER_DATA_WEIGHT_MAXIMUM_KILOS/10]]];
            return NO;
        }
    }
    return YES;
}

#pragma mark TextField Delegate methods
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if ([string isEqualToString:@""]) {
        return YES;
    }
    NSCharacterSet *numbers = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];
    if ([string rangeOfCharacterFromSet:numbers].location != NSNotFound)
    {
        NSString *result = [textField.text stringByReplacingCharactersInRange:range withString:string];
        if ([iDevicesUtil isMetricSystem])
        {
            if (result.intValue > (M328_USER_DATA_WEIGHT_MAXIMUM_KILOS/10))
            {
                [self showAlertViewWithText:[NSString stringWithFormat:NSLocalizedString(@"Please enter maximum %d kg",nil),(int)M328_USER_DATA_WEIGHT_MAXIMUM_KILOS/10]];
                return NO;
            }
        }
        else
        {
            if (result.intValue > round([iDevicesUtil convertKilogramsToPounds:M328_USER_DATA_WEIGHT_MAXIMUM_KILOS/10]))
            {
                [self showAlertViewWithText:[NSString stringWithFormat:NSLocalizedString(@"Please enter maximum %d lbs",nil),(int)roundf([iDevicesUtil convertKilogramsToPounds:M328_USER_DATA_WEIGHT_MAXIMUM_KILOS/10])]];
                return NO;
            }
        }
        return YES;
    }
    return NO;
}
@end
