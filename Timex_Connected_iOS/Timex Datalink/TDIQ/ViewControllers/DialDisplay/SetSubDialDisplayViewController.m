//
//  SetSubDialDisplayViewController.m
//  Timex
//
//  Created by kpasupuleti on 5/4/16.
//

#import "SetSubDialDisplayViewController.h"
#import "TDDefines.h"
#import "iDevicesUtil.h"
#import "UIImage+Tint.h"
#import "MFSideMenuContainerViewController.h"
#import "SideMenuViewController.h"
#import "TDAppDelegate.h"
#import "TDM328WatchSettingsUserDefaults.h"


@interface SetSubDialDisplayViewController (){
     typeM328ActivityDisplay calibrationType;
    CustomTabbar *customTabbar;
}
@end

@implementation SetSubDialDisplayViewController
{
    
}
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {

    }
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))  {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    self.view.backgroundColor = UIColorFromRGB(COLOR_DEFAULT_TIMEX_WHITE);
    self.navigationItem.titleView = [iDevicesUtil getNavigationTitle];
    
    TDAppDelegate *appdel = (TDAppDelegate *)[[UIApplication sharedApplication] delegate];
    customTabbar = appdel.customTabbar;
    
    if (IS_IPAD) {
        infoLblTopConstraint.constant = 70;
        infoLblleftConstraint.constant = 60;
    } else {
        infoLblleftConstraint.constant = 40;
    }

    UIButton *backBtn = [iDevicesUtil getBackButton];
    [backBtn addTarget:self action:@selector(backButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barBtn = [[UIBarButtonItem alloc] initWithCustomView:backBtn];
    self.navigationItem.leftBarButtonItem = barBtn;

    NSDictionary * navBarTitleTextAttributes =  @{NSFontAttributeName : [UIFont fontWithName:[iDevicesUtil getAppWideBoldFontName] size:APP_HEADER_FONT_SIZE] };
    self.navigationController.navigationBar.titleTextAttributes = navBarTitleTextAttributes;
    
    [self configureSubDialViews];
    
    calibrationType = (typeM328ActivityDisplay)[TDM328WatchSettingsUserDefaults displaySubDial];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    int row = 1;
    if ([TDM328WatchSettingsUserDefaults displaySubDial])
    {
        row = (int)[TDM328WatchSettingsUserDefaults displaySubDial];
    }
    [pickView selectRow:row inComponent:0 animated:NO];
    UILabel *view = (UILabel*)[pickView viewForRow:row forComponent:0];
    if (row == M328_DISTANCE_PERC_GOAL)
    {
        calibrationType = M328_DISTANCE_PERC_GOAL;
        [watchImageView setImage:[UIImage imageNamed:@"WatchWithDistance"]];
        [view setTextColor:UIColorFromRGB(M328_DISTANCE_COLOR)];
    }
    else
    {
        calibrationType = M328_STEPS_PERC_GOAL;
        [watchImageView setImage:[UIImage imageNamed:@"WatchWithSteps"]];
        [view setTextColor:UIColorFromRGB(M328_STEPS_COLOR)];
    }
}

-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    int row = (int)[TDM328WatchSettingsUserDefaults displaySubDial];
    [pickView selectRow:row inComponent:0 animated:NO];
    [self pickerView:pickView didSelectRow:row inComponent:0];
}

- (void) backButtonTapped
{
    [TDM328WatchSettingsUserDefaults setDisplaySubDial:calibrationType];

    [self.navigationController popViewControllerAnimated:YES];
}

-(void)configureSubDialViews
{    
    infoLabel.attributedText = [self getAttributedStrWithText:NSLocalizedString(@"Configure your sub-dial.",nil) formatStr:NSLocalizedString(@"\n\nThe sub-dial can display how close you are to reach your goal in an activity type. Tap the activity type you want to set your sub-dial to.",nil)];
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
    if (row == M328_DISTANCE_PERC_GOAL)
    {
        [tView setText:NSLocalizedString(@"DISTANCE",nil)];
    }
    else
    {
        [tView setText:NSLocalizedString(@"STEPS",nil)];
    }
    [tView setTextColor:UIColorFromRGB(COLOR_DEFAULT_TIMEX_FONT)];
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
        [watchImageView setImage:[UIImage imageNamed:@"WatchWithDistance"]];
        [view setTextColor:UIColorFromRGB(M328_DISTANCE_COLOR)];
    }
    else
    {
        calibrationType = M328_STEPS_PERC_GOAL;
        [watchImageView setImage:[UIImage imageNamed:@"WatchWithSteps"]];
        [view setTextColor:UIColorFromRGB(M328_STEPS_COLOR)];
    }
    [customTabbar syncNeeded];
}
@end
