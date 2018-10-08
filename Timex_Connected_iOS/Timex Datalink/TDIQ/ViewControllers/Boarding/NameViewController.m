//
//  NameViewController.m
//  Timex-iOS
//
//  Created by kpasupuleti on 5/4/16.
//

#import "NameViewController.h"
#import "BirthDateViewController.h"
#import "iDevicesUtil.h"
#import "TDDefines.h"
#import "UIImage+Tint.h"
#import "TDAppDelegate.h"
//#import "User.h"
#import "TDM328WatchSettingsUserDefaults.h"
#import "OTLogUtil.h"
@interface NameViewController () {
    int selectedGender;
}

@end

@implementation NameViewController

#pragma  mark Life Cycle Methods

- (void)viewDidLoad {
    [super viewDidLoad];

    selectedGender = -1;
    nameTextField.text = [TDM328WatchSettingsUserDefaults userName];
    if ([TDM328WatchSettingsUserDefaults gender] == 1)
    {
        [self genderButtonTapped:femaleBtn];
    }
    
    if ([TDM328WatchSettingsUserDefaults gender] == 0)
    {
        [self genderButtonTapped:maleBtn];
    }
    
    self.navigationItem.titleView = [iDevicesUtil getNavigationTitle];
   
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))  {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    infoLabel.attributedText = [self getAttributedStrWithText:NSLocalizedString(@"yourself...",nil) formatStr:NSLocalizedString(@"Tell us \nabout yourself...",nil)];
    if (IS_IPAD) {
        infoLblTopConstraint.constant = 70;
        infoBtnleftConstraint.constant = 60;
        infoLblleftConstraint.constant = 60;
        fieldViewWidthContraint.constant = (ScreenWidth-150)/2;
        infoLblBottomContraint.constant = 30;
        infoBtnBottomContraint.constant = ((ScreenHeight)/2)- 30 - 70 - M328_REGISTRATION_BOTTOM_CONSTRAINT_MINUSVALUE;
    } else {
        infoLblleftConstraint.constant = 40;
        infoBtnleftConstraint.constant = 30;
        fieldViewTopContraint.constant = 30;
        infoBtnBottomContraint.constant = ((ScreenHeight)/2) - 70 - M328_REGISTRATION_BOTTOM_CONSTRAINT_MINUSVALUE;
    }
    
    
    progressLbl.backgroundColor = UIColorFromRGB(AppColorRed);
    progressLblWidthContraint.constant = ScreenWidth * ([iDevicesUtil getProgressBarValueBasedOnRegistrationEnum:nameandsex]);
    
    
    UIButton *backBtn = [iDevicesUtil getBackButton];
    [backBtn addTarget:self action:@selector(backButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barBtn = [[UIBarButtonItem alloc] initWithCustomView:backBtn];
    self.navigationItem.leftBarButtonItem = barBtn;
    

    [infoBtn setImage:[[UIImage imageNamed:@"info_icon"] imageWithTint: UIColorFromRGB(INFO_ICON_TINT_COLOR)] forState:UIControlStateNormal];
    nameTextField.font = [UIFont fontWithName: [iDevicesUtil getAppWideFontName] size:M328_REGISTRATION_TITLE_FONTSIZE];
    [femaleBtn.titleLabel setFont:[UIFont fontWithName: [iDevicesUtil getAppWideBoldFontName] size:M328_REGISTRATION_INFO_FONTSIZE]];
    [maleBtn.titleLabel setFont:[UIFont fontWithName: [iDevicesUtil getAppWideBoldFontName] size:M328_REGISTRATION_INFO_FONTSIZE]];
    
    [infoBtn setTitle:NSLocalizedString(infoBtn.currentTitle, nil) forState:UIControlStateNormal];
    [nameTextField setPlaceholder:NSLocalizedString(nameTextField.placeholder, nil)];
    [femaleBtn setTitle:NSLocalizedString(femaleBtn.currentTitle, nil) forState:UIControlStateNormal];
    [maleBtn setTitle:NSLocalizedString(maleBtn.currentTitle, nil) forState:UIControlStateNormal];
    
    [nextButton setTitle:[NSString stringWithFormat:@"%@  ", NSLocalizedString(@"NEXT", nil)] forState:UIControlStateNormal];
    nextButton.transform = CGAffineTransformMakeScale(-1.0, 1.0);
    nextButton.titleLabel.transform = CGAffineTransformMakeScale(-1.0, 1.0);
    nextButton.imageView.transform = CGAffineTransformMakeScale(-1.0, 1.0);
    [nextButton setTitleColor:UIColorFromRGB(AppColorRed) forState:UIControlStateNormal];
    nextButton.tintColor = UIColorFromRGB(AppColorRed);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear: animated];
    [self addBottomBorderToTextField:nameTextField];
    [self addLeftBorderToButton:femaleBtn];
    
    if (nameTextField.text.length == 0)
        [nameTextField becomeFirstResponder];
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

- (void)addLeftBorderToButton :(UIButton *)btn {
    CALayer *border = [CALayer layer];
    CGFloat borderWidth = 1;
    border.borderColor = (UIColorFromRGB(M328_TABLEVIEW_HEADER_GRAY_COLOR)).CGColor;
    border.frame = CGRectMake(-1, -1, btn.frame.size.width, btn.frame.size.height+2);
    border.borderWidth = borderWidth;
    [btn.layer addSublayer:border];
    btn.layer.masksToBounds = YES;
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

- (void)didReceiveMemoryWarning {
     OTLog([NSString stringWithFormat:@"Recived Memory Warning  in %@ ",NSStringFromClass([self class])]);
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma  mark Button Actions

-(IBAction) backButtonTapped:(id)sender
{
    TDAppDelegate *appDelgate = (TDAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if (nameTextField.text.length > 0)
    {
        nameTextField.text = [appDelgate removingLastSpecialCharecter:nameTextField.text];
        
        if (nameTextField.text.length != 0)
            [TDM328WatchSettingsUserDefaults setUserName:nameTextField.text];
    }
    if (selectedGender != -1)
        [TDM328WatchSettingsUserDefaults setGender:selectedGender];
    
    [self.navigationController popViewControllerAnimated:YES];
}

-(IBAction)genderButtonTapped:(UIButton *)sender
{
    if (sender.tag == 1) {
        selectedGender = 1;
        [femaleBtn setTitleColor:UIColorFromRGB(AppColorRed) forState:UIControlStateNormal];
        [maleBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    } else {
        selectedGender = 0;
        [femaleBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [maleBtn setTitleColor:UIColorFromRGB(AppColorRed) forState:UIControlStateNormal];
    }
}

- (IBAction)nextButtonTapped:(id)sender {
    TDAppDelegate *appDelgate = (TDAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (nameTextField.text.length > 0) {
        nameTextField.text = [appDelgate removingLastSpecialCharecter:nameTextField.text];
    } else {
        [self showAlertViewWithText:NSLocalizedString(@"Please enter your name",nil)];
        return;
    }
    if (nameTextField.text.length == 0) {
        [self showAlertViewWithText:NSLocalizedString(@"Please enter your name",nil)];
        return;
    }else {
        if (selectedGender == -1) {
            [self showAlertViewWithText:NSLocalizedString(@"Please select gender",nil)];
            return;
        } else {
          
            [TDM328WatchSettingsUserDefaults setUserName:nameTextField.text];
            [TDM328WatchSettingsUserDefaults setGender:selectedGender];
                        // [appDelgate saveContext];

            BirthDateViewController *birthDateVC=[[BirthDateViewController alloc] initWithNibName:@"BirthDateViewController" bundle:nil];
            [self.navigationController pushViewController:birthDateVC animated:YES];
        }
    }
}

- (void)showAlertViewWithText:(NSString *)text {
    TDAppDelegate *delegate = (TDAppDelegate *)[[UIApplication sharedApplication] delegate];
    [delegate showAlertWithTitle:nil Message:text andButtonTitle:NSLocalizedString(@"Ok",nil)];
}

#pragma  mark Text Field Delegates
-(void)textFieldDidBeginEditing:(UITextField *)textField {
    CGRect rect = self.view.frame;
    if (ScreenHeight == 480) {
        
        rect.origin.y -= 100;
        [UIView animateWithDuration:0.3 animations:^{
            
            self.view.frame = rect;
            
        } completion:^(BOOL finished) {
            
        }];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    CGRect rect = self.view.frame;
    if (ScreenHeight == 480) {
        
        rect.origin.y = 64;
        [UIView animateWithDuration:0.3 animations:^{
            
            self.view.frame = rect;
            
        } completion:^(BOOL finished) {
            
        }];
    }
    
    
    [textField resignFirstResponder];
    return YES;
}
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    
    NSUInteger newLength = [textField.text length] + [string length] - range.length;
    if (newLength <= 64 == false){
        [self showAlertViewWithText:NSLocalizedString(@"Name shouldn't exceed 64 characters",nil)];
        return false;
    }
    return true;
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
