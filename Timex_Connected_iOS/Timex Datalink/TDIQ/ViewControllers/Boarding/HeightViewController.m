//
//  HeightViewController.m
//  Timex
//
//  Created by avemulakonda on 5/4/16.
//

#import "HeightViewController.h"
#import "WeightViewController.h"
#import "iDevicesUtil.h"
#import "TDDefines.h"
#import "UIImage+Tint.h"
#import "TDAppDelegate.h"
#import "TDM328WatchSettingsUserDefaults.h"
@interface HeightViewController () {
    int mHeight;
    TDAppDelegate *appDel;
}

@end

@implementation HeightViewController

#pragma  mark Life Cycle Methods

- (void)viewDidLoad {
    [super viewDidLoad];
    
    appDel = (TDAppDelegate *)[[UIApplication sharedApplication] delegate];
    self.navigationItem.titleView = [iDevicesUtil getNavigationTitle];
    infoLabel.attributedText = [self getAttributedStrWithText:NSLocalizedString(@"tall",nil) formatStr:NSLocalizedString(@"How tall\nare you?",nil)];
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
    progressLblWidthContraint.constant = ScreenWidth * ([iDevicesUtil getProgressBarValueBasedOnRegistrationEnum:height]);
    
    [infoButton setImage:[[UIImage imageNamed:@"info_icon"] imageWithTint: UIColorFromRGB(INFO_ICON_TINT_COLOR)] forState:UIControlStateNormal];
    [infoButton setTitle:NSLocalizedString(infoButton.currentTitle, nil) forState:UIControlStateNormal];
    
    UIButton *backBtn = [iDevicesUtil getBackButton];
    [backBtn addTarget:self action:@selector(backButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barBtn = [[UIBarButtonItem alloc] initWithCustomView:backBtn];
    self.navigationItem.leftBarButtonItem = barBtn;
    
    [self addBottomBorderToTextField:ftTextField];
    [self addBottomBorderToTextField:inTextField];
    
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
    ftTextField.inputAccessoryView = numberToolbar;
    inTextField.inputAccessoryView = numberToolbar;

    if ([iDevicesUtil isMetricSystem]) {
        ftlbl.text = NSLocalizedString(@"m",nil);
        inlbl.text = NSLocalizedString(@"cm",nil);
        ftTextField.text = @"";
        inTextField.text = @"";
    } else {
        ftlbl.text = NSLocalizedString(@"ft",nil);
        inlbl.text = NSLocalizedString(@"in",nil);
        ftTextField.text = @"";
        inTextField.text = @"";
    }
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))  {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    if ([TDM328WatchSettingsUserDefaults userHeight])
    {
        [self setToDefaultHeight];
    }
    
    [ftTextField addTarget:self action:@selector(feetsTextChanged) forControlEvents:UIControlEventEditingChanged];
}

- (IBAction)clickedOnInfoBtn:(id)sender {
    [self showAlertViewWithText:NSLocalizedString(@"This information is used only to help improve the accuracy of activity data. It will not be used for marketing purposes or shared with any third parties.",nil)];
    //    WebViewController *webVC=[[WebViewController alloc] initWithNibName:@"WebViewController" bundle:nil];
    //    [self.navigationController pushViewController:webVC animated:YES];
}


- (int)getMinHeight {
    if ([iDevicesUtil isMetricSystem]) {
        return M328_USER_DATA_HEIGHT_MINIMUM_CENTIEMTERS;
    } else {
       return [iDevicesUtil convertCentimetersToInches:M328_USER_DATA_HEIGHT_MINIMUM_CENTIEMTERS];
    }
}

- (float)getMaxHeight {
    if ([iDevicesUtil isMetricSystem]) {
        return M328_USER_DATA_HEIGHT_MAXIMUM_CENTIEMTERS;
    } else {
        return [iDevicesUtil convertCentimetersToInches:M328_USER_DATA_HEIGHT_MAXIMUM_CENTIEMTERS];
    }
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
    [ftTextField becomeFirstResponder];
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

#pragma  mark Button Actions
- (IBAction) backButtonTapped:(id)sender
{
    bool goodInput = YES;
    int ftTextFieldValue = [ftTextField.text intValue];
    int inTextFieldValue = [inTextField.text intValue];
    if ([iDevicesUtil isMetricSystem]) {
        int total = (ftTextFieldValue *100) + inTextFieldValue;
        if (total < [self getMinHeight]) {
            goodInput = NO;
        } else if (total > [self getMaxHeight]) {
            goodInput = NO;
        }
    } else {
        int total = (ftTextFieldValue *12) + inTextFieldValue;
        if (total < [self getMinHeight]) {
            goodInput = NO;
        } else if (total > roundf([self getMaxHeight])) {
            goodInput = NO;
        }
    }
    if (goodInput)
    {
        [self saveHeightToDefaults];
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}
- (IBAction)nextButtonTapped:(id)sender
{
    if ([self validateFields]) {
        [self saveHeightToDefaults];
     
        WeightViewController *weightVC = [[WeightViewController alloc] initWithNibName:@"WeightViewController" bundle:nil];
        [self.navigationController pushViewController:weightVC animated:YES];
    }
}

-(void)setToDefaultHeight
{
    int firstData;
    int secondData;
    float total = (float)[TDM328WatchSettingsUserDefaults userHeight];
    
    if ([iDevicesUtil isMetricSystem])
    {
        firstData = roundf(total) / 100; //convert mts to cm
        secondData = fmod(roundf(total), 100);
    }
    else
    {
        total = [iDevicesUtil convertCentimetersToInches:total];
        
        firstData = roundf(total) / 12;      //Convert ft to in
        secondData = fmod(roundf(total), 12);
    }
    
    ftTextField.text = [NSString stringWithFormat:@"%d", firstData];
    inTextField.text = [NSString stringWithFormat:@"%d", secondData];
}

-(void)saveHeightToDefaults
{
    
    float firstData = [ftTextField.text floatValue];
    float secondData= [inTextField.text floatValue];
    float total = 0;
    
    if ([iDevicesUtil isMetricSystem])
    {
        firstData = firstData *100; //convert mts to cm
        total = firstData +secondData;
    }
    else
    {
        firstData = firstData * 12.0f;      //Convert ft to in
        total = firstData + secondData;
        
        total = [iDevicesUtil convertInchesToCentimeters:total];
    }
    mHeight = total;
    [TDM328WatchSettingsUserDefaults setUserHeight:mHeight];
}

- (BOOL)validateFields {

    int ftTextFieldValue = [ftTextField.text intValue];
    int inTextFieldValue = [inTextField.text intValue];
    if ([iDevicesUtil isMetricSystem]) {
        int total = (ftTextFieldValue *100) + inTextFieldValue;
        if (total < [self getMinHeight]) {
            [self showAlertViewWithText:[NSString stringWithFormat:NSLocalizedString(@"Please enter minimum %@",nil),[iDevicesUtil convertCMToMeters:[self getMinHeight]]]];
            return NO;
        } else if (total > [self getMaxHeight]) {
            [self showAlertViewWithText:[NSString stringWithFormat:NSLocalizedString(@"Please enter maximum %@",nil),[iDevicesUtil convertCMToMeters:[self getMaxHeight]]]];
            return NO;
        }
    } else {
        int total = (ftTextFieldValue *12) + inTextFieldValue;
        if (total < [self getMinHeight]) {
            [self showAlertViewWithText:[NSString stringWithFormat:NSLocalizedString(@"Please enter minimum %@",nil),[iDevicesUtil convertInchToFeet:[self getMinHeight]]]];
            return NO;
        } else if (total > roundf([self getMaxHeight])) {
            [self showAlertViewWithText:[NSString stringWithFormat:NSLocalizedString(@"Please enter maximum %@",nil),[iDevicesUtil convertInchToFeet:[self getMaxHeight]]]];
            return NO;
        }
    }
    return YES;
}

- (void)showAlertViewWithText:(NSString *)text {
    TDAppDelegate *delegate = (TDAppDelegate *)[[UIApplication sharedApplication] delegate];
    [delegate showAlertWithTitle:nil Message:text andButtonTitle:NSLocalizedString(@"Ok",nil)];

}

#pragma mark TextField Delegate methods
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if ([string isEqualToString:@""]) {
        return YES;
    }
    NSCharacterSet *numbers = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];
    if ([string rangeOfCharacterFromSet:numbers].location != NSNotFound)
    {
        NSString *result = [textField.text stringByReplacingCharactersInRange:range withString:string];
        if (textField == inTextField)
        {
            if ([iDevicesUtil isMetricSystem])
            {
                if (result.intValue > 99)
                {
                    return NO;
                }
            }
            else
            {
                if (result.intValue > 11)
                {
                    return NO;
                }
            }
        }
        else
        {
            if ([iDevicesUtil isMetricSystem])
            {
                if (result.intValue > 3)
                {
                    return NO;
                }
            }
            else
            {
                if (result.intValue > 7)
                {
                    return NO;
                }
            }
        }
        return YES;
    }
    return NO;
}

-(void)textFieldDidEndEditing:(UITextField *)textField
{
    if (textField == ftTextField)
    {
        [inTextField becomeFirstResponder];
    }
}

-(void)feetsTextChanged
{
    if(ftTextField.text.length > 0)
    {
        [inTextField becomeFirstResponder];
    }
}
@end
