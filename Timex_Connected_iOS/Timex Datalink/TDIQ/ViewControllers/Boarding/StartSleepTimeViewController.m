//
//  BirthDateViewController.m
//  Timex-iOS
//
//  Created by avemulakonda on 5/4/16.
//

#import "StartSleepTimeViewController.h"
#import "SetGoalsViewController.h"
#import "iDevicesUtil.h"
#import "TDDefines.h"
#import "TDAppDelegate.h"
#import "TDM328WatchSettingsUserDefaults.h"
#import "OTLogUtil.h"
#import "TDWatchProfile.h"
#import "UIImage+Tint.h"

@implementation StartSleepTimeViewController
{
    NSDateFormatter *dateFormat;
}

- (void)viewDidLoad {
    [super viewDidLoad];
   TCSTART
    dateFormat = [NSDateFormatter new];
    if ([iDevicesUtil isSystemTimeFormat24Hr]) {
        [dateFormat setDateFormat:@"HH:mm"];
        if (_isAwakeVC) {
            _timePicker.date = [dateFormat dateFromString:@"10:00"];
        } else {
            _timePicker.date = [dateFormat dateFromString:@"22:00"];
        }
    } else {
        [dateFormat setDateFormat:@"h:mm a"];
        if (_isAwakeVC) {
            _timePicker.date = [dateFormat dateFromString:@"10:00 am"];
        } else {
            _timePicker.date = [dateFormat dateFromString:@"10:00 pm"];
        }
    }
    
    self.navigationItem.titleView = [iDevicesUtil getNavigationTitle];
    
    [nextButton setTitle:[NSString stringWithFormat:@"%@  ", NSLocalizedString(@"NEXT", nil)] forState:UIControlStateNormal];
    nextButton.transform = CGAffineTransformMakeScale(-1.0, 1.0);
    nextButton.titleLabel.transform = CGAffineTransformMakeScale(-1.0, 1.0);
    nextButton.imageView.transform = CGAffineTransformMakeScale(-1.0, 1.0);
    [nextButton setTitleColor:UIColorFromRGB(AppColorRed) forState:UIControlStateNormal];
    nextButton.tintColor = UIColorFromRGB(AppColorRed);
    
    if (IS_IPAD) {
        infoLblTopConstraint.constant = 70;
        infoLblleftConstraint.constant = 60;
        infoLblBottomContraint.constant = 30;
        
        infoBtnleftConstraint.constant = 60;
        infoBtnBottomContraint.constant = ((ScreenHeight)/2)- 30 - 70 - M328_REGISTRATION_BOTTOM_CONSTRAINT_MINUSVALUE;
    } else {
        infoLblleftConstraint.constant = 40;
        infoBtnleftConstraint.constant = 30;
        infoBtnBottomContraint.constant = ((ScreenHeight)/2) - 70 - M328_REGISTRATION_BOTTOM_CONSTRAINT_MINUSVALUE;
        pickerLblTopContraint.constant = 30;
        if (ScreenHeight <= 480) {
            pickerLblTopContraint.constant = 10;
        }
    }
    
    progressLbl.backgroundColor = UIColorFromRGB(AppColorRed);
    progressLblWidthContraint.constant = ScreenWidth * ([iDevicesUtil getProgressBarValueBasedOnRegistrationEnum:settingGoals]);
    
    [infoBtn setImage:[[UIImage imageNamed:@"info_icon"] imageWithTint: UIColorFromRGB(INFO_ICON_TINT_COLOR)] forState:UIControlStateNormal];
    [infoBtn setTitle:NSLocalizedString(infoBtn.currentTitle, nil) forState:UIControlStateNormal];
    
    UIButton *backBtn = [iDevicesUtil getBackButton];
    [backBtn addTarget:self action:@selector(backButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barBtn = [[UIBarButtonItem alloc] initWithCustomView:backBtn];
    self.navigationItem.leftBarButtonItem = barBtn;
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))  {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }

    if (_isAwakeVC)
    {
        infoLabel.attributedText = [self getAttributedStrWithText:NSLocalizedString(@"wake up?",nil) formatStr:NSLocalizedString(@"When do you\nusually wake up?",nil)];
        if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQ  || [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel) {
            if ([TDM328WatchSettingsUserDefaults awakeHour] || [TDM328WatchSettingsUserDefaults awakeMin])
            {
                if ([iDevicesUtil isSystemTimeFormat24Hr]) {
                    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
                    [dateFormat setLocale:locale];
                    [dateFormat setDateFormat:@"HH:mm"];
                    NSDate *date = [dateFormat dateFromString:[NSString stringWithFormat:@"%d:%d", (int)[TDM328WatchSettingsUserDefaults awakeHour], (int)[TDM328WatchSettingsUserDefaults awakeMin]]];
                    _timePicker.date = date;
                } else {
                    [dateFormat setDateFormat:@"h:mm a"];
                    if ((int)[TDM328WatchSettingsUserDefaults awakeHour] >= 12){
                        _timePicker.date =  [dateFormat dateFromString:[NSString stringWithFormat:@"%d:%d pm", (int)[TDM328WatchSettingsUserDefaults awakeHour] - 12, (int)[TDM328WatchSettingsUserDefaults awakeMin]]];
                    } else {
                        _timePicker.date =  [dateFormat dateFromString:[NSString stringWithFormat:@"%d:%d am", (int)[TDM328WatchSettingsUserDefaults awakeHour], (int)[TDM328WatchSettingsUserDefaults awakeMin]]];
                    }
                }
            }
        } else {
            NSString * awakeHr = [iDevicesUtil createKeyForAppSettingsPropertyWithClass: appSettingsM372Sleeptracker_PropertyClass_UserInformation andIndex: appSettingsM372_PropertyClass_ActivityTracking_AwakeHour];
            NSString * awakeMin = [iDevicesUtil createKeyForAppSettingsPropertyWithClass: appSettingsM372Sleeptracker_PropertyClass_UserInformation andIndex: appSettingsM372_PropertyClass_ActivityTracking_AwakeMinute];
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            if ([defaults objectForKey:awakeHr] != nil && [defaults objectForKey:awakeMin] != nil) {
                if ([iDevicesUtil isSystemTimeFormat24Hr]) {
                    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
                    [dateFormat setLocale:locale];
                    [dateFormat setDateFormat:@"HH:mm"];
                    NSDate *date = [dateFormat dateFromString:[NSString stringWithFormat:@"%d:%d", (int)[defaults integerForKey:awakeHr], (int)[defaults integerForKey:awakeMin]]];
                    _timePicker.date = date;
                } else {
                    [dateFormat setDateFormat:@"h:mm a"];
                    if ((int)[defaults integerForKey:awakeHr] > 12) {
                        _timePicker.date = [dateFormat dateFromString:[NSString stringWithFormat:@"%d:%d pm",
                                                                       (int)[defaults integerForKey:awakeHr] - 12,
                                                                       (int)[defaults integerForKey:awakeMin]]];
                    } else {
                        _timePicker.date = [dateFormat dateFromString:[NSString stringWithFormat:@"%d:%d am",
                                                                       (int)[defaults integerForKey:awakeHr],
                                                                       (int)[defaults integerForKey:awakeMin]]];
                    }
                }
            }
        }
    }
    else
    {
        infoLabel.attributedText = [self getAttributedStrWithText:NSLocalizedString(@"go to bed?",nil) formatStr:NSLocalizedString(@"When do you\nusually go to bed?",nil)];
        if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQ  || [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel) {
            if ([TDM328WatchSettingsUserDefaults bedHour] || [TDM328WatchSettingsUserDefaults bedMin]) {
                if ([iDevicesUtil isSystemTimeFormat24Hr]) {
                    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
                    [dateFormat setLocale:locale];
                    [dateFormat setDateFormat:@"HH:mm"];
                    NSDate *date = [dateFormat dateFromString:[NSString stringWithFormat:@"%d:%d", (int)[TDM328WatchSettingsUserDefaults bedHour], (int)[TDM328WatchSettingsUserDefaults bedMin]]];
                    _timePicker.date = date;
                } else {
                    [dateFormat setDateFormat:@"h:mm a"];
                    if ((int)[TDM328WatchSettingsUserDefaults bedHour] >= 12){
                        _timePicker.date = [dateFormat dateFromString:[NSString stringWithFormat:@"%d:%d pm",
                                                                       (int)[TDM328WatchSettingsUserDefaults bedHour] - 12,
                                                                       (int)[TDM328WatchSettingsUserDefaults bedMin]]];
                    } else {
                        _timePicker.date = [dateFormat dateFromString:[NSString stringWithFormat:@"%d:%d am",
                                                                       (int)[TDM328WatchSettingsUserDefaults bedHour],
                                                                       (int)[TDM328WatchSettingsUserDefaults bedMin]]];
                    }
                }
            }
        } else {
            NSString * bedHr = [iDevicesUtil createKeyForAppSettingsPropertyWithClass: appSettingsM372Sleeptracker_PropertyClass_UserInformation andIndex: appSettingsM372_PropertyClass_ActivityTracking_BedHour];
            NSString * bedMin = [iDevicesUtil createKeyForAppSettingsPropertyWithClass: appSettingsM372Sleeptracker_PropertyClass_UserInformation andIndex: appSettingsM372_PropertyClass_ActivityTracking_BedMinute];
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            if ([defaults objectForKey:bedHr] != nil && [defaults objectForKey:bedMin] != nil) {
                if ([iDevicesUtil isSystemTimeFormat24Hr]) {
                    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
                    [dateFormat setLocale:locale];
                    [dateFormat setDateFormat:@"HH:mm"];
                    NSDate *date = [dateFormat dateFromString:[NSString stringWithFormat:@"%d:%d", (int)[defaults integerForKey:bedHr], (int)[defaults integerForKey:bedMin]]];
                    _timePicker.date = date;
                } else {
                    [dateFormat setDateFormat:@"h:mm a"];
                    if ((int)[defaults integerForKey:bedHr] > 12) {
                        _timePicker.date = [dateFormat dateFromString:[NSString stringWithFormat:@"%d:%d pm",
                                                                       (int)[defaults integerForKey:bedHr] - 12,
                                                                       (int)[defaults integerForKey:bedMin]]];
                    } else {
                        _timePicker.date = [dateFormat dateFromString:[NSString stringWithFormat:@"%d:%d am",
                                                                       (int)[defaults integerForKey:bedHr],
                                                                       (int)[defaults integerForKey:bedMin]]];
                    }
                }
            }
        }
    }
    
    TCEND
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

- (IBAction)clickedOnInfoBtn:(id)sender {
    [self showAlertViewWithText:NSLocalizedString(@"This information is used only to help improve the accuracy of activity data. It will not be used for marketing purposes or shared with any third parties.",nil)];
    //    WebViewController *webVC=[[WebViewController alloc] initWithNibName:@"WebViewController" bundle:nil];
    //    [self.navigationController pushViewController:webVC animated:YES];
}

- (void)showAlertViewWithText:(NSString *)text {
    TDAppDelegate *delegate = (TDAppDelegate *)[[UIApplication sharedApplication] delegate];
    [delegate showAlertWithTitle:nil Message:text andButtonTitle:NSLocalizedString(@"Ok", nil)];
}

- (IBAction)backButtonTapped:(id)sender
{
    [self setBedTimeOrAwakeTime];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)setBedTimeOrAwakeTime {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDate *time = [_timePicker date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:(NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:time];
    NSInteger hour = [components hour];
    NSInteger minute = [components minute];
    if (_isAwakeVC) {
        if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQ || [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel) {
            [TDM328WatchSettingsUserDefaults setAwakeHour:hour];
            [TDM328WatchSettingsUserDefaults setAwakeMin:minute];
        } else {
            NSString * awakeHr = [iDevicesUtil createKeyForAppSettingsPropertyWithClass: appSettingsM372Sleeptracker_PropertyClass_UserInformation andIndex: appSettingsM372_PropertyClass_ActivityTracking_AwakeHour];
            NSString * awakeMin = [iDevicesUtil createKeyForAppSettingsPropertyWithClass: appSettingsM372Sleeptracker_PropertyClass_UserInformation andIndex: appSettingsM372_PropertyClass_ActivityTracking_AwakeMinute];
            [defaults setInteger:hour forKey:awakeHr];
            [defaults setInteger:minute forKey:awakeMin];
        }
    } else {
        if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQ || [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel) {
            [TDM328WatchSettingsUserDefaults setBedHour:hour];
            [TDM328WatchSettingsUserDefaults setBedMin:minute];
        } else {
            NSString * bedHr = [iDevicesUtil createKeyForAppSettingsPropertyWithClass: appSettingsM372Sleeptracker_PropertyClass_UserInformation andIndex: appSettingsM372_PropertyClass_ActivityTracking_BedHour];
            NSString * bedMin = [iDevicesUtil createKeyForAppSettingsPropertyWithClass: appSettingsM372Sleeptracker_PropertyClass_UserInformation andIndex: appSettingsM372_PropertyClass_ActivityTracking_BedMinute];
            [defaults setInteger:hour forKey:bedHr];
            [defaults setInteger:minute forKey:bedMin];
        }
    }
}
- (IBAction)nextButtonTapped:(id)sender {
    [self setBedTimeOrAwakeTime];
    TDAppDelegate *appDelgate = (TDAppDelegate*)[[UIApplication sharedApplication] delegate];
    if (_isAwakeVC) {
        if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQ || [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel) {
            [appDelgate setupDummyGoals];
            SetGoalsViewController *setGoalsVC = [[SetGoalsViewController alloc] initWithNibName:@"SetGoalsViewController" bundle:nil];
            setGoalsVC.notOpenedByMenu = YES;
            [self.navigationController pushViewController:setGoalsVC animated:YES];
        }
    } else {
        StartSleepTimeViewController *startSleepVC = [[StartSleepTimeViewController alloc] initWithNibName:@"StartSleepTimeViewController" bundle:nil];
        startSleepVC.isAwakeVC = YES;
        [self.navigationController pushViewController:startSleepVC animated:YES];
    }
}

@end
