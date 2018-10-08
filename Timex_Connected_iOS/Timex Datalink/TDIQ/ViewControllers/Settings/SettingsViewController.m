//
//  SettingsViewController.m
//  Timex
//
//  Created by kpasupuleti on 5/4/16.
//

#import "SettingsViewController.h"

#import "TDDefines.h"
#import "iDevicesUtil.h"

#import "CustomTabbar.h"
#import "TDAppDelegate.h"
#import "TDWatchProfile.h"
#import "TDFlurryDataPacket.h"
#import "MFSideMenuContainerViewController.h"
#import "SideMenuViewController.h"
#import "UpdateFirmwareViewController.h"
#import "SetSubDialDisplayViewController.h"
#import "ConfigureSecondsViewController.h"
#import "TDDeviceManager.h"
#import "TDM328WatchSettingsUserDefaults.h"
#import "TDM328WatchSettings.h"
#import "TimexWatchDB.h"
#import "CalibratingWatchViewController.h"
#import "DBManager.h"
#import "OTLogUtil.h"
#import "PCCommExtendedFirmwareVersionInfo.h"
#import "AutoSyncViewController.h"
#import "TDM329WatchSettingsUserDefaults.h"
#import "FactoryResetViewController.h"

@interface SettingsViewController ()
{
    CustomTabbar *customTabbar;
    
}

@end

@implementation SettingsViewController

#pragma  mark Life Cycle Methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setData];
    [self setViewProperties];
   bleManager = [[TDDeviceManager sharedInstance] getBleManager];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self setData];
    [_settingsTableView reloadData];
    [self addCustomTabbar];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    // Watch connection
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kDeviceManagerDeviceLostConnectiondNotification object: nil];
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kPeripheralDeviceAuthorizationFailedNotification object: nil];
}

#pragma mark
#pragma mark CustomTabbar
- (void)addCustomTabbar {
    TDAppDelegate *appdel = (TDAppDelegate *)[[UIApplication sharedApplication] delegate];
    customTabbar = appdel.customTabbar;
    customTabbar.frame = CGRectMake(0, self.view.frame.size.height - customTabbar.frame.size.height, ScreenWidth, customTabbar.frame.size.height);
    [self.view addSubview:customTabbar];
    
    //Bottom
    NSLayoutConstraint *bottom = [NSLayoutConstraint constraintWithItem:customTabbar attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0f constant:0.f];
    [self.view addConstraint:bottom];
    
    // Left
    NSLayoutConstraint *left = [NSLayoutConstraint constraintWithItem:customTabbar attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1.0f constant:0.f];
    [self.view addConstraint:left];
    
    //Right
    NSLayoutConstraint *right = [NSLayoutConstraint constraintWithItem:customTabbar attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1.0f constant:0.f];
    [self.view addConstraint:right];
    
//    tableViewBottomConstraint.constant = customTabbar.frame.size.height-30+5;
    [customTabbar updateLastLblText];
}


-(void)setViewProperties
{

    self.navigationItem.titleView = [iDevicesUtil getNavigationTitle];
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))  {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    self.view.backgroundColor = UIColorFromRGB(COLOR_DEFAULT_TIMEX_WHITE);
    _settingsTableView.backgroundColor = UIColorFromRGB(COLOR_DEFAULT_TIMEX_WHITE);
    UILabel *hLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,0,_settingsTableView.frame.size.width,40)];
    hLabel.textAlignment = NSTextAlignmentCenter;
    hLabel.textColor = [UIColor grayColor];
    hLabel.font = [UIFont fontWithName: [iDevicesUtil getAppWideBoldFontName] size: M328_TABLE_HEADER_FONT_SIZE];
    hLabel.text = NSLocalizedString(@"Settings", nil);
    hLabel.backgroundColor =  UIColorFromRGB(M328_TABLEVIEW_HEADER_GRAY_COLOR);
    _settingsTableView.tableHeaderView = hLabel;
    
    UIBarButtonItem *slideMenuItem=[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"menu"] style:UIBarButtonItemStylePlain target:self action:@selector(slideMenuTapped)];
     self.navigationItem.leftBarButtonItem=slideMenuItem;
    [self slideMenuTapped];
    
}
- (void)setData {
    NSDictionary *watch = [NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObjects:NSLocalizedString(@"Sub-dial mode",nil),NSLocalizedString(@"Second hand display",nil),NSLocalizedString(@"Track sleep",nil),NSLocalizedString(@"Sensor sensitivity",nil), NSLocalizedString(@"Distance adjustment",nil),NSLocalizedString(@"Auto sync",nil), nil], NSLocalizedString(@"WATCH SETTINGS",nil), nil];
    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)
    {
        watch = [NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObjects:NSLocalizedString(@"Sub-dial time zone",nil),NSLocalizedString(@"Second hand display",nil),NSLocalizedString(@"Second hand button",nil),NSLocalizedString(@"Track sleep",nil),NSLocalizedString(@"Sensor sensitivity",nil), NSLocalizedString(@"Distance adjustment",nil),NSLocalizedString(@"Auto sync",nil), nil], NSLocalizedString(@"WATCH CONTROLS",nil), nil];
        if ([TDM329WatchSettingsUserDefaults secondHandMode] == DISPLAY_TZ3)
        {
            watch = [NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObjects:NSLocalizedString(@"Sub-dial time zone",nil),NSLocalizedString(@"Second hand display",nil),NSLocalizedString(@"3rd time zone",nil),NSLocalizedString(@"Second hand button",nil),NSLocalizedString(@"Track sleep",nil),NSLocalizedString(@"Sensor sensitivity",nil), NSLocalizedString(@"Distance adjustment",nil),NSLocalizedString(@"Auto sync",nil), nil], NSLocalizedString(@"WATCH CONTROLS",nil), nil];
        }
    }
    settingsItems = [NSArray arrayWithObjects:
                     [NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObjects:NSLocalizedString(@"First Name", nil),NSLocalizedString(@"Gender",nil),NSLocalizedString(@"Birthdate",nil),NSLocalizedString(@"Height",nil),NSLocalizedString(@"Weight",nil),NSLocalizedString(@"Bed time",nil),NSLocalizedString(@"Wake time",nil),NSLocalizedString(@"Units",nil), nil], NSLocalizedString(@"USER INFORMATION",nil), nil],
                     watch,
                     [NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObjects:NSLocalizedString(@"Align watch hands",nil),NSLocalizedString(@"Check for updates",nil),NSLocalizedString(@"Remove watch",nil),NSLocalizedString(@"Factory reset",nil),nil],NSLocalizedString(@"ADVANCED CONTROLS",nil), nil], nil];
}

#pragma  mark Button Actions

-(void)slideMenuTapped
{
    TDAppDelegate * delegate = (TDAppDelegate *)[UIApplication sharedApplication].delegate;
    SideMenuViewController *leftController = (SideMenuViewController *)((MFSideMenuContainerViewController *)delegate.window.rootViewController).leftMenuViewController;
    if (leftController == nil)
    {
        SideMenuViewController *leftController = [[SideMenuViewController alloc] init];
        ((MFSideMenuContainerViewController *)delegate.window.rootViewController).leftMenuViewController = leftController;
    } 
}

#pragma mark - TableView Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return settingsItems.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [[[[settingsItems objectAtIndex:section] allKeys] objectAtIndex:0] uppercaseString];
}
- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    if ([view isKindOfClass:[UITableViewHeaderFooterView class]]) {
        UITableViewHeaderFooterView *headerview = (UITableViewHeaderFooterView *)view;
        headerview.textLabel.font = [UIFont fontWithName: [iDevicesUtil getAppWideFontName] size: M328_SLIDE_MENU_CELL_FONT_SIZE];
        headerview.backgroundView.backgroundColor = [UIColor whiteColor];
        headerview.textLabel.textColor = UIColorFromRGB(AppColorRed);
    }
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return M328_SLIDE_MENU_CELL_HEIGHT;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[[[settingsItems objectAtIndex:section] allObjects] objectAtIndex:0] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"cellID";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:
                             cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:
                UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
    }

    NSArray *arr = [[[settingsItems objectAtIndex:indexPath.section] allObjects] objectAtIndex:0];
    cell.textLabel.text = [arr objectAtIndex:indexPath.row];
    cell.textLabel.font = [UIFont fontWithName: [iDevicesUtil getAppWideFontName] size: M328_SLIDE_MENU_CELL_FONT_SIZE];
    cell.textLabel.textColor = [UIColor darkGrayColor];
    
    if (indexPath.section == 0 || indexPath.section == 1 || (indexPath.section == 2)) {
        cell.detailTextLabel.font = [UIFont fontWithName: [iDevicesUtil getAppWideFontName] size: M328_SETTINGS_DETAIL_FONT_SIZE];
        cell.detailTextLabel.textColor = [UIColor lightGrayColor];
        
        if (indexPath.section == 0) {
            if (indexPath.row == 0) {
                cell.detailTextLabel.text = [TDM328WatchSettingsUserDefaults userName];
            } else if (indexPath.row == 1) {
                cell.detailTextLabel.text = NSLocalizedString([TDM328WatchSettingsUserDefaults getGenderStringFormat:(typeM328Gender)[TDM328WatchSettingsUserDefaults gender]], nil);
            } else if (indexPath.row == 2) {
                cell.detailTextLabel.text = [self getBirthDateString:[TDM328WatchSettingsUserDefaults dateOfBirth]];
            } else if (indexPath.row == 3) {
                NSInteger setting = [TDM328WatchSettingsUserDefaults userHeight];
                if ([iDevicesUtil isMetricSystem]) {
                    int meter = (int)setting/100;
                    int cm = (int)setting-(meter*100);
                    cell.detailTextLabel.text = [NSString stringWithFormat:@"%d.%02d m",meter,cm];
                } else {
                    float inches = roundf([iDevicesUtil convertCentimetersToInches: (float)setting]);
                    NSInteger inchesRemainder = (NSInteger)inches % 12;
                    NSInteger whole = (NSInteger)inches - inchesRemainder;
                    NSInteger feet = whole / 12;
                    cell.detailTextLabel.text = [NSString stringWithFormat: @"%ld'%ld\"", (long)feet, (long)inchesRemainder];
                }
                
            } else if (indexPath.row == 4) {
                NSInteger setting = roundf([TDM328WatchSettingsUserDefaults userWeight]);
                if ([iDevicesUtil isMetricSystem]) {
                    float kilos = roundf((float)setting / 10.0f);
                    cell.detailTextLabel.text = [NSString stringWithFormat: @"%ld %@", (long)kilos, NSLocalizedString(@"kg", nil)];
                } else {
                    float pounds = roundf([iDevicesUtil convertKilogramsToPounds: (setting / 10.0f)]);
                    cell.detailTextLabel.text = [NSString stringWithFormat: @"%d %@", (int)pounds, NSLocalizedString(@"lbs", nil)];
                }
            } else if (indexPath.row == 5) {
                if ([iDevicesUtil isSystemTimeFormat24Hr]) {
                    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
                    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
                    [timeFormat setLocale:locale];
                    [timeFormat setDateFormat:@"HH:mm"];
                    NSDate *date = [timeFormat dateFromString:[NSString stringWithFormat:@"%d:%d", (int)[TDM328WatchSettingsUserDefaults bedHour], (int)[TDM328WatchSettingsUserDefaults bedMin]]];
                    cell.detailTextLabel.text = [timeFormat stringFromDate:date];
                } else {
                    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
                    [timeFormat setDateFormat:@"h:mm a"];
                    if ((int)[TDM328WatchSettingsUserDefaults bedHour] >= 12){
                        cell.detailTextLabel.text = [timeFormat stringFromDate:[timeFormat dateFromString:[NSString stringWithFormat:@"%d:%d pm", (int)[TDM328WatchSettingsUserDefaults bedHour] - 12, (int)[TDM328WatchSettingsUserDefaults bedMin]]]];
                    } else {
                        cell.detailTextLabel.text = [timeFormat stringFromDate:[timeFormat dateFromString:[NSString stringWithFormat:@"%d:%d am", (int)[TDM328WatchSettingsUserDefaults bedHour], (int)[TDM328WatchSettingsUserDefaults bedMin]]]];
                    }
                }
            } else if (indexPath.row == 6) {
                if ([iDevicesUtil isSystemTimeFormat24Hr]) {
                    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
                    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
                    [timeFormat setLocale:locale];
                    [timeFormat setDateFormat:@"HH:mm"];
                    NSDate *date = [timeFormat dateFromString:[NSString stringWithFormat:@"%d:%d", (int)[TDM328WatchSettingsUserDefaults awakeHour], (int)[TDM328WatchSettingsUserDefaults awakeMin]]];
                    cell.detailTextLabel.text = [timeFormat stringFromDate:date];
                } else {
                    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
                    [timeFormat setDateFormat:@"h:mm a"];
                    if ((int)[TDM328WatchSettingsUserDefaults awakeHour] >= 12){
                        cell.detailTextLabel.text = [timeFormat stringFromDate:[timeFormat dateFromString:[NSString stringWithFormat:@"%d:%d pm", (int)[TDM328WatchSettingsUserDefaults awakeHour] - 12, (int)[TDM328WatchSettingsUserDefaults awakeMin]]]];
                    } else {
                        cell.detailTextLabel.text = [timeFormat stringFromDate:[timeFormat dateFromString:[NSString stringWithFormat:@"%d:%d am", (int)[TDM328WatchSettingsUserDefaults awakeHour], (int)[TDM328WatchSettingsUserDefaults awakeMin]]]];
                    }
                }
            } else {
                cell.detailTextLabel.text = NSLocalizedString([TDM328WatchSettingsUserDefaults getUnitsStringFormate:(typeM328Units)[TDM328WatchSettingsUserDefaults units]], nil);
            }
        } else if (indexPath.section == 1) {
            if (indexPath.row == 0) {
                switch ([TDM328WatchSettingsUserDefaults displaySubDial]) {
                    case M328_STEPS_PERC_GOAL:
                        cell.detailTextLabel.text = NSLocalizedString(@"Steps",nil);
                        break;
                    case M328_DISTANCE_PERC_GOAL:
                        cell.detailTextLabel.text = NSLocalizedString(@"Distance",nil);
                        break;
                    default:
                        break;
                }
            } else if (indexPath.row == 1) {
                switch ([TDM328WatchSettingsUserDefaults secondHandMode]) {
                    case M328_DISPLAY_DATE:
                        cell.detailTextLabel.text = NSLocalizedString(@"Perfect Date",nil);
                        break;
                    case M328_DISPLAY_SECONDS:
                        cell.detailTextLabel.text = NSLocalizedString(@"Seconds",nil);
                        break;
                    case M328_DISPLAY_STEPS:
                        cell.detailTextLabel.text = NSLocalizedString(@"Steps",nil);
                        break;
                    default:
                        cell.detailTextLabel.text = NSLocalizedString(@"Distance",nil);
                        break;
                }
            } else if (indexPath.row == 2) {
                if ([TDM328WatchSettingsUserDefaults trackSleep]) {
                    cell.detailTextLabel.text = NSLocalizedString(@"During Bedtime",nil);
                } else {
                    cell.detailTextLabel.text = NSLocalizedString(@"All Day",nil);
                }
            } else if (indexPath.row == 3) {
                cell.detailTextLabel.text = NSLocalizedString([TDM328WatchSettingsUserDefaults getSensitivityStringFormat:(typeM328Sensitivity)[TDM328WatchSettingsUserDefaults sensorSensitivity]], nil);
            } else if (indexPath.row == 4) {
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%d %%",(int)[TDM328WatchSettingsUserDefaults distanceAdjustment]];
            } else {
                cell.detailTextLabel.text = @"";
            }
            if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)
            {
                if (indexPath.row == 0) {
                    NSArray *citySplit = [[NSArray alloc] init];
                    citySplit = [[TDM329WatchSettingsUserDefaults TZPrimaryName2] componentsSeparatedByString:@"/"];
                    cell.detailTextLabel.text = citySplit[1];
                } else if (indexPath.row == 1) {
                    switch ([TDM329WatchSettingsUserDefaults secondHandMode]) {
                        case M329_DISPLAY_DATE:
                            cell.detailTextLabel.text = NSLocalizedString(@"Perfect Date",nil);
                            break;
                        case M329_DISPLAY_SECONDS:
                            cell.detailTextLabel.text = NSLocalizedString(@"Seconds",nil);
                            break;
                        case M329_DISPLAY_STEPS:
                            cell.detailTextLabel.text = NSLocalizedString(@"Steps",nil);
                            break;
                        case M329_DISPLAY_CALORIES:
                            cell.detailTextLabel.text = NSLocalizedString(@"Calories",nil);
                            break;
                        case M329_DISPLAY_DISTANCE:
                            cell.detailTextLabel.text = NSLocalizedString(@"Distance",nil);
                            break;
                        case DISPLAY_TZ3:
                        {
                            NSArray *citySplit = [[NSArray alloc] init];
                            citySplit = [[TDM329WatchSettingsUserDefaults TZPrimaryName3] componentsSeparatedByString:@"/"];
                            if ([citySplit[0] isEqualToString:@"GMT"])
                            {
                                cell.detailTextLabel.text = NSLocalizedString(@"GMT",nil);
                            }
                            else
                            {
                                //cell.detailTextLabel.text = citySplit[1];
                                cell.detailTextLabel.text = NSLocalizedString(@"3rd time zone",nil);
                            }
                        }
                            break;
                        default:
                            cell.detailTextLabel.text = NSLocalizedString(@"GMT",nil);
                            break;
                    }
                } else {
                    if ([TDM329WatchSettingsUserDefaults secondHandMode] == DISPLAY_TZ3)
                    {
                        if (indexPath.row == 2) {
                            NSArray *citySplit = [[NSArray alloc] init];
                            citySplit = [[TDM329WatchSettingsUserDefaults TZPrimaryName3] componentsSeparatedByString:@"/"];
                            cell.detailTextLabel.text = citySplit[1];
                        } else if (indexPath.row == 3) {
                            switch ([TDM329WatchSettingsUserDefaults PB4DisplayFunction]) {
                                case M329_DISTANCE_PERC_GOAL:
                                    cell.detailTextLabel.text = NSLocalizedString(@"Distance",nil);
                                    break;
                                default:
                                    cell.detailTextLabel.text = NSLocalizedString(@"Steps",nil);
                                    break;
                            }
                        } else if (indexPath.row == 4) {
                            if ([TDM329WatchSettingsUserDefaults trackSleep]) {
                                cell.detailTextLabel.text = NSLocalizedString(@"During Bedtime",nil);
                            } else {
                                cell.detailTextLabel.text = NSLocalizedString(@"All Day",nil);
                            }
                        } else if (indexPath.row == 5) {
                            cell.detailTextLabel.text = NSLocalizedString([TDM329WatchSettingsUserDefaults getSensitivityStringFormat:(typeM329Sensitivity)[TDM329WatchSettingsUserDefaults sensorSensitivity]], nil);
                        } else if (indexPath.row == 6) {
                            cell.detailTextLabel.text = [NSString stringWithFormat:@"%d %%",(int)[TDM329WatchSettingsUserDefaults distanceAdjustment]];
                        } else {
                            cell.detailTextLabel.text = @"";
                        }
                    } else {
                        if (indexPath.row == 2) {
                            switch ([TDM329WatchSettingsUserDefaults PB4DisplayFunction]) {
                                case M329_DISTANCE_PERC_GOAL:
                                    cell.detailTextLabel.text = NSLocalizedString(@"Distance",nil);
                                    break;
                                default:
                                    cell.detailTextLabel.text = NSLocalizedString(@"Steps",nil);
                                    break;
                            }
                        } else if (indexPath.row == 3) {
                            if ([TDM329WatchSettingsUserDefaults trackSleep]) {
                                cell.detailTextLabel.text = NSLocalizedString(@"During Bedtime",nil);
                            } else {
                                cell.detailTextLabel.text = NSLocalizedString(@"All Day",nil);
                            }
                        } else if (indexPath.row == 4) {
                            cell.detailTextLabel.text = NSLocalizedString([TDM329WatchSettingsUserDefaults getSensitivityStringFormat:(typeM329Sensitivity)[TDM329WatchSettingsUserDefaults sensorSensitivity]], nil);
                        } else if (indexPath.row == 5) {
                            cell.detailTextLabel.text = [NSString stringWithFormat:@"%d %%",(int)[TDM329WatchSettingsUserDefaults distanceAdjustment]];
                        } else {
                            cell.detailTextLabel.text = @"";
                        }
                    }
                }
            }
        } else {
            cell.detailTextLabel.text = @"";
        }
    } else {
        cell.detailTextLabel.text = @"";
    }
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    return cell;
}

- (NSString *)getBirthDateString:(NSDate *)birthDate {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"MMMM-dd-yyyy"];
    return [formatter stringFromDate:birthDate];
//    NSDate* now = [NSDate date];
//    NSDateComponents* ageComponents = [[NSCalendar currentCalendar]
//                                       components:NSCalendarUnitYear | NSCalendarUnitMonth
//                                       fromDate:birthDate
//                                       toDate:now
//                                       options:0];
//    return [NSString stringWithFormat:@"%ld %ld",(long)[ageComponents year],(long)[ageComponents month]];
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    enum SettingType type;

    if (indexPath.section == 0 || indexPath.section == 1) {
        if (indexPath.section == 0) {
            if (indexPath.row == 0) {
                type = Setting_Name;
                UIAlertController *insertName = [UIAlertController alertControllerWithTitle:nil
                                                                                      message:NSLocalizedString(@"Please enter your first name", nil)
                                                                               preferredStyle:UIAlertControllerStyleAlert];
                [insertName addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
                    textField.placeholder = NSLocalizedString(@"First Name",nil);
                    textField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
                    textField.delegate = self;
                    [textField addTarget:self action:@selector(textChanged:) forControlEvents:UIControlEventEditingChanged];
                }];
                
                [insertName addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                                 style:UIAlertActionStyleCancel
                                                               handler:^(UIAlertAction * _Nonnull action){}]];
                
                [insertName addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                                 style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction * _Nonnull action)
                                         {
                                             TDAppDelegate *appDelgate = (TDAppDelegate *)[[UIApplication sharedApplication] delegate];
                                             insertName.textFields.lastObject.text = [appDelgate removingLastSpecialCharecter:insertName.textFields.lastObject.text];
                                             [TDM328WatchSettingsUserDefaults setUserName:insertName.textFields.lastObject.text];
                                             [_settingsTableView reloadData];
                                             [customTabbar syncNeeded];
                                         }]];
                insertName.actions[1].enabled = FALSE;
                [self presentViewController:insertName animated:YES completion:nil];
            } else if (indexPath.row == 1) {
                type = Setting_Gender;
            } else if (indexPath.row == 2) {
                type = Setting_Age;
            } else if (indexPath.row == 3) {
                type = Setting_Height;
            } else if (indexPath.row == 4) {
                type = Setting_Weight;
            } else if (indexPath.row == 5) {
                type = Setting_SleepTime;
            } else if (indexPath.row == 6) {
                type = Setting_AwakeTime;
            } else {
                type = Setting_Units;
            }
        } else {
            if (indexPath.row == 0)
            {
                type = Setting_Name;
                
                SetSubDialDisplayViewController *subDialController = [[SetSubDialDisplayViewController alloc] initWithNibName:@"SetSubDialDisplayViewController" bundle:nil];
                [self.navigationController pushViewController:subDialController animated:YES];
            }
            else if (indexPath.row == 1)
            {
                type = Setting_Name;
                ConfigureSecondsViewController *configureVC = [[ConfigureSecondsViewController alloc] initWithNibName:@"ConfigureSecondsViewController" bundle:nil];
                configureVC.openedByMenu = YES;
                [self.navigationController pushViewController:configureVC animated:YES];
            } else {
                if (indexPath.row == 2) {
                    type = Setting_TrackSleep;
                }
                else if (indexPath.row == 3 )
                {
                    type = Setting_Sensitivity;
                }
                else if (indexPath.row == 4)
                {
                    type = Setting_Distance;
                }
                else
                {
                    type = Setting_Name;
                    AutoSyncViewController *autoVC = [[AutoSyncViewController alloc] initWithNibName:@"AutoSyncViewController" bundle:nil];
                    [self.navigationController pushViewController:autoVC animated:YES];
                }
            }
        }
        if (type != Setting_Name) {
            SettingsSubViewController *vc = [[SettingsSubViewController alloc] initWithNibName:@"SettingsSubViewController" bundle:nil withScreenType:type];
            [self.navigationController pushViewController:vc animated:YES];
        }
    } else {
        if ([bleManager isBLESupported] && [bleManager isBLEAvailable])
        {
            if (indexPath.row == 0) {
                CalibratingWatchViewController *newFrontController = [[CalibratingWatchViewController alloc] initWithNibName:@"CalibratingWatchViewController" bundle:nil doSettingsMenuCalibration:YES];
                if ([TDM328WatchSettingsUserDefaults numberOfCalibrations])
                {
                    [TDM328WatchSettingsUserDefaults setNumberOfCalibrations:[TDM328WatchSettingsUserDefaults numberOfCalibrations] + 1];
                }
                else
                {
                    [TDM328WatchSettingsUserDefaults setNumberOfCalibrations:1];
                }
                newFrontController.openCalibration = YES;
                [self.navigationController pushViewController:newFrontController animated:YES];
            }
            else if (indexPath.row == 1)
            {
                UpdateFirmwareViewController *updateVC = [[UpdateFirmwareViewController alloc] initWithNibName:@"UpdateFirmwareViewController" bundle:nil];
                
                updateVC.openedByMenu = YES;
                
                [self.navigationController pushViewController:updateVC animated:YES];
            }
            else if (indexPath.row == 3)
            {
                UIAlertController *factoryReset = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Please Confirm", nil)
                                                                                      message:NSLocalizedString(@"This will restore your watch to its initial factory settings.", nil)
                                                                               preferredStyle:UIAlertControllerStyleAlert];
                
                [factoryReset addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                                 style:UIAlertActionStyleCancel
                                                               handler:^(UIAlertAction * _Nonnull action){}]];
                
                [factoryReset addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                                 style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction * _Nonnull action)
                                         {
                                             [self userInitiatedWatchReset];
                                         }]];
                
                [self presentViewController:factoryReset animated:YES completion:nil];
            }
        }
        else
        {
            NSString * title = NSLocalizedString(@"Bluetooth unavailable", nil);
            NSString * msg = nil;
            if (![bleManager isBLESupported])
            {
                msg = NSLocalizedString(@"Bluetooth is not available on this device.", nil);
            }
            else if (![bleManager isBLEAvailable])
            {
                msg = NSLocalizedString(@"Bluetooth is powered off. Please turn on Bluetooth in System Settings before proceeding.", nil);
            }
            
            UIAlertView *message = [[UIAlertView alloc] initWithTitle: title
                                                              message: msg
                                                             delegate: nil
                                                    cancelButtonTitle: NSLocalizedString(@"OK", nil)
                                                    otherButtonTitles: nil];
            [message show];
        }
        if (indexPath.row == 2) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Remove Watch",nil) message:NSLocalizedString(@"Do you want to remove watch?",nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel",nil) otherButtonTitles:NSLocalizedString(@"Yes",nil), nil];
            alert.tag = 0;
            [alert show];
        }
    }
}

- (bool)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSUInteger newLength = [textField.text length] + [string length] - range.length;
    if (newLength > 64){
        [[[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"Name shouldn't exceed 64 characters",nil) delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil] show];
        return false;
    }
    return true;
}
- (void)textChanged:(UITextField *)textfield {
    UIAlertController *alertcontrl = (UIAlertController *)textfield.nextResponder;
    while (!([alertcontrl isKindOfClass:[UIAlertController class]])) {
        alertcontrl = (UIAlertController *)alertcontrl.nextResponder;
    }
    TDAppDelegate *appDelgate = (TDAppDelegate *)[[UIApplication sharedApplication] delegate];
    if ([appDelgate removingLastSpecialCharecter:textfield.text].length > 0) {
        ((UIAlertAction *)alertcontrl.actions[1]).enabled = TRUE;
    } else {
        ((UIAlertAction *)alertcontrl.actions[1]).enabled = FALSE;
    }
}
- (void) userInitiatedWatchReset
{
#if TARGET_IPHONE_SIMULATOR
    if (TRUE)
#else
        if ([bleManager isBLESupported] && [bleManager isBLEAvailable])
#endif
        {
            //[[NSNotificationCenter defaultCenter] postNotificationName: kM372WatchResetUserInitiatedNotification object:self];
            //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(watchDC:) name:kDeviceManagerDeviceLostConnectiondNotification object:nil];
            //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(watchDC:) name:kPeripheralDeviceAuthorizationFailedNotification object:nil];
            
            FactoryResetViewController *factoryController = [[FactoryResetViewController alloc] initWithNibName:@"FactoryResetViewController" bundle:nil];
            [self.navigationController pushViewController:factoryController animated:YES];
        }
        else
        {
            NSString * title = NSLocalizedString(@"Bluetooth unavailable", nil);
            NSString * msg = nil;
            if (![bleManager isBLESupported])
            {
                msg = NSLocalizedString(@"Bluetooth is not available on this device.", nil);
            }
            else if (![bleManager isBLEAvailable])
            {
                msg = NSLocalizedString(@"Bluetooth is powered off. Please turn on Bluetooth in System Settings before proceeding.", nil);
            }
            
            UIAlertView *message = [[UIAlertView alloc] initWithTitle: title
                                                              message: msg
                                                             delegate: nil
                                                    cancelButtonTitle: NSLocalizedString(@"OK", nil)
                                                    otherButtonTitles: nil];
            [message show];
        }
}

- (void)watchDC: (NSNotification*)notification
{
    double delayInSeconds = 13.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        FactoryResetViewController *factoryController = [[FactoryResetViewController alloc] initWithNibName:@"FactoryResetViewController"
                                                                                                     bundle:nil];
        [self.navigationController pushViewController:factoryController animated:YES];
    });
}

- (void)deleteDataAlert
{
    [TDM328WatchSettingsUserDefaults setSyncNeeded:NO];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Delete All Data",nil) message:NSLocalizedString(@"Do you want to delete or save existing data?",nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Delete",nil) otherButtonTitles:NSLocalizedString(@"Save",nil), nil];
    alert.tag = 1;
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 0) {
        
        if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"Yes",nil)]) {
            [self deleteDataAlert];
        }
    }
    if (alertView.tag == 1) {
        OTLog(@"WATCHED REMOVED CALLED AT Settings ViewController with alertviewaction");
        if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"Delete",nil)])
        {
            //database cleanup
            [DBManager deleteAll];
        }
        
        PeripheralDevice * connectedDevice = [iDevicesUtil getConnectedTimexDevice];
        if (connectedDevice != nil)
        {
            [[TDDeviceManager sharedInstance] forgetAndDisconnect: connectedDevice];
        }
        
        [[TDWatchProfile sharedInstance] setActiveProfile: FALSE];
        [[TDWatchProfile sharedInstance] commitChangesToDatabase];
        OTLog(@"Setting active profile to false so that it will bring us choose watch screen SettingsViewController.m");
        [TDM328WatchSettingsUserDefaults removeResets];
        
        // Removing DB file : Aruna
        NSString * sourceDbName = @"timexDatalinkDB.db";
        NSString * dbPath = [[[TimexWatchDB sharedInstance] getDataPath] stringByAppendingPathComponent:sourceDbName];
        BOOL dbExists = [[TimexWatchDB sharedInstance] doesFileExist: dbPath];
        if (dbExists) {
            [[NSFileManager defaultManager] removeItemAtPath:dbPath error:nil];
        }
        
        [TDWatchProfile resetSharedInstance]; //to force reinitialization
        
        [[TimexWatchDB sharedInstance] createBlankDatabase : dbPath];
        
        [(TimexWatchDB *)[TimexWatchDB sharedInstance] init : dbPath];
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults removeObjectForKey: kCONNECTED_DEVICE_UUID_PREF_NAME];
        //Mantis 309
        [userDefaults setBool: FALSE forKey: kBLEandBTCPairingConfirmed];
        //TestLog_sleepFiles
        [userDefaults removeObjectForKey:@USERID_USERDEFAULT];
        [userDefaults removeObjectForKey:@ALL_THE_DATA_IN_EPOCHS];
        [userDefaults removeObjectForKey:@DATA_DATAIL_BY_DAY];
        [userDefaults removeObjectForKey:@DAYS_READ_BEFORE];
        [userDefaults removeObjectForKey:@FIRST_SYNC];
        [userDefaults removeObjectForKey:@"kLAST_FIRMWARE_CHECK_DATE_NEW"];
        [userDefaults removeObjectForKey:@"NotificaitonDismissedDates"];
        
        //M328 defaults need to remove
        [self removeM328WatchSettingsInfo];
        
        //Mantis 309
        TDFlurryDataPacket * dictFlurry = [[TDFlurryDataPacket alloc] init];
        [iDevicesUtil logFlurryEvent: @"WATCH_REMOVED" withParameters: dictFlurry isTimedEvent:NO];
        
        TDAppDelegate * delegate = (TDAppDelegate *)[UIApplication sharedApplication].delegate;
        [(SideMenuViewController *)((MFSideMenuContainerViewController *)delegate.window.rootViewController).leftMenuViewController goToMain];
        [delegate.customTabbar removeObserversTosync];
        [delegate.customTabbar removeDevicesChangedNotificaiton];
        delegate.customTabbar = nil;
        
        UIAlertController *forgetWatch = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Make sure to \"Forget This Device\"", nil)
                                                                              message:NSLocalizedString(@"The watch remains paired with your phone until you remove it from Bluetooth settings.", nil)
                                                                       preferredStyle:UIAlertControllerStyleAlert];
        
        [forgetWatch addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                         style:UIAlertActionStyleCancel
                                                       handler:^(UIAlertAction * _Nonnull action){}]];
        
        [forgetWatch addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Settings", nil)
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * _Nonnull action)
                                 {
                                     [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
//                                     [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"App-Prefs:root=Bluetooth"]];
                                 }]];
        
        [self presentViewController:forgetWatch animated:YES completion:nil];
    }
}

-(void)removeM328WatchSettingsInfo{
    [TDM328WatchSettingsUserDefaults removeM328WatchSettings];
}

@end
