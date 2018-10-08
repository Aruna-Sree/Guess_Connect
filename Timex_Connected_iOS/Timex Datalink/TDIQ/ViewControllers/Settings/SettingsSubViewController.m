//
//  SettingsSubViewController.m
//  Timex
//
//  Created by Aruna Kumari Yarra on 03/06/16.
//

#import "SettingsSubViewController.h"
#import "iDevicesUtil.h"
#import "TDDefines.h"
#import "TDAppDelegate.h"
#import "TDM328WatchSettings.h"
#import "TDM328WatchSettingsUserDefaults.h"
#import "TDM329WatchSettingsUserDefaults.h"
#import "OTLogUtil.h"
#import "TDWatchProfile.h"
#import "TDStoredWatchUserDefaults.h"
#import "TDDevice.h"

@interface SettingsSubViewController () {
    enum SettingType viewType;
    NSMutableArray *tableNPickerArray;
    TDAppDelegate *appDelgate;
    CustomTabbar *customTabbar;
    
    NSMutableDictionary *heightDict;
    NSArray *sortKeyArray;
    NSDateFormatter *timeFormat;
    
    int previousSelectedInches;
}

@end

@implementation SettingsSubViewController
@synthesize  user = _user;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil withScreenType:(int)type {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        viewType = (SettingType)type;
    }
    return self;
}

- (void)viewDidLoad {
    TCSTART
    [super viewDidLoad];
    self.title = NSLocalizedString([iDevicesUtil getSettingType:viewType], nil);
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))  {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    TDAppDelegate *appdel = (TDAppDelegate *)[[UIApplication sharedApplication] delegate];
    customTabbar = appdel.customTabbar;
    
    NSDictionary * navBarTitleTextAttributes =  @{NSFontAttributeName : [UIFont fontWithName:[iDevicesUtil getAppWideBoldFontName] size:APP_HEADER_FONT_SIZE] };
    self.navigationController.navigationBar.titleTextAttributes = navBarTitleTextAttributes;
    UIButton *backBtn = [iDevicesUtil getBackButton];
    [backBtn addTarget:self action:@selector(backButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barBtn = [[UIBarButtonItem alloc] initWithCustomView:backBtn];
    self.navigationItem.leftBarButtonItem = barBtn;
    
   // appDelgate = (TDAppDelegate *)[[UIApplication sharedApplication] delegate];
    //user = [appDelgate getUser];
    timeFormat = [[NSDateFormatter alloc] init];
    [timeFormat setDateFormat:@"HH:mm"];
    
    detailPickerView.hidden = YES;
    ageDatePickerView.hidden = YES;
    genderTableView.hidden = YES;
    autoSyncEnableView.hidden = YES;
    autoSyncViewHeightConstraint.constant = 0;
    if (viewType == Setting_Gender || viewType == Setting_Units || viewType == Setting_Goals || viewType == Setting_Sensitivity || viewType == Setting_TrackSleep || viewType == Setting_ChangeWatch) {
        genderTableView.hidden = NO;
        self.view.backgroundColor = UIColorFromRGB(VERY_LIGHT_GRAY_COLOR);
    } else if (viewType == Setting_Height || viewType == Setting_Weight || viewType == Setting_Distance) {
        detailPickerView.hidden = NO;
        self.view.backgroundColor = [UIColor whiteColor];
    } else if (viewType == Setting_Age) {
        infoLbl.text = NSLocalizedString(@"Enter your birthdate",nil);
        ageDatePickerView.datePickerMode = UIDatePickerModeDate;
        ageDatePickerView.hidden = NO;
        //        dateWithTimeIntervalSinceReferenceDate
        ageDatePickerView.date = [TDM328WatchSettingsUserDefaults dateOfBirth];//[NSDate dateWithTimeIntervalSince1970:[(NSNumber*)[user valueForKey:USER_BDATE]doubleValue]];
        self.view.backgroundColor = [UIColor whiteColor];
        
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSDateComponents *componentsMax = [calendar components:(NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear) fromDate:[NSDate date]];
        componentsMax.year = componentsMax.year - M328_USER_DATA_AGE_MINIMUM;
        
        
        NSDateComponents *componentsMin = [calendar components:(NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear) fromDate:[NSDate date]];
        componentsMin.year = componentsMin.year - M328_USER_DATA_AGE_MAXIMUM;
        
        [ageDatePickerView setMinimumDate:[calendar dateFromComponents:componentsMin]];
        [ageDatePickerView setMaximumDate:[calendar dateFromComponents:componentsMax]];
    } else if (viewType == Setting_SleepTime) {
        infoLbl.text = NSLocalizedString(@"Average Bed Time",nil);
        ageDatePickerView.hidden = NO;
        ageDatePickerView.datePickerMode = UIDatePickerModeTime;
        if ([iDevicesUtil isSystemTimeFormat24Hr]) {
            NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            [timeFormat setLocale:locale];
            [timeFormat setDateFormat:@"HH:mm"];
            NSDate *date = [timeFormat dateFromString:[NSString stringWithFormat:@"%d:%d", (int)[TDM328WatchSettingsUserDefaults bedHour], (int)[TDM328WatchSettingsUserDefaults bedMin]]];
            ageDatePickerView.date = date;
        } else {
            [timeFormat setDateFormat:@"h:mm a"];
            if ((int)[TDM328WatchSettingsUserDefaults bedHour] >= 12){
                ageDatePickerView.date = [timeFormat dateFromString:[NSString stringWithFormat:@"%d:%d pm",
                                                                     (int)[TDM328WatchSettingsUserDefaults bedHour] - 12,
                                                                     (int)[TDM328WatchSettingsUserDefaults bedMin]]];
            } else {
                ageDatePickerView.date = [timeFormat dateFromString:[NSString stringWithFormat:@"%d:%d am",
                                                                     (int)[TDM328WatchSettingsUserDefaults bedHour],
                                                                     (int)[TDM328WatchSettingsUserDefaults bedMin]]];
            }
        }
        
    } else if (viewType == Setting_AwakeTime) {
        infoLbl.text = NSLocalizedString(@"Average Wake Time",nil);
        ageDatePickerView.hidden = NO;
        ageDatePickerView.datePickerMode = UIDatePickerModeTime;
        if ([iDevicesUtil isSystemTimeFormat24Hr]) {
            NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            [timeFormat setLocale:locale];
            [timeFormat setDateFormat:@"HH:mm"];
            NSDate *date = [timeFormat dateFromString:[NSString stringWithFormat:@"%d:%d", (int)[TDM328WatchSettingsUserDefaults awakeHour], (int)[TDM328WatchSettingsUserDefaults awakeMin]]];
            ageDatePickerView.date = date;
        } else {
            [timeFormat setDateFormat:@"h:mm a"];
            if ((int)[TDM328WatchSettingsUserDefaults awakeHour] >= 12){
                ageDatePickerView.date =  [timeFormat dateFromString:[NSString stringWithFormat:@"%d:%d pm", (int)[TDM328WatchSettingsUserDefaults awakeHour] - 12, (int)[TDM328WatchSettingsUserDefaults awakeMin]]];
            } else {
                ageDatePickerView.date =  [timeFormat dateFromString:[NSString stringWithFormat:@"%d:%d am", (int)[TDM328WatchSettingsUserDefaults awakeHour], (int)[TDM328WatchSettingsUserDefaults awakeMin]]];
            }
        }
    } else if (viewType == Setting_SyncTime) {
        infoLbl.text = [NSString stringWithFormat:@"%@ %ld",NSLocalizedString(@"Set auto sync time",nil), (long)_syncNumber];
        enableLbl.text = NSLocalizedString(@"Enable", nil);
        ageDatePickerView.hidden = NO;
        ageDatePickerView.datePickerMode = UIDatePickerModeTime;
        autoSyncEnableView.hidden = NO;
        autoSyncViewHeightConstraint.constant = 40;
        int hour = 12;
        int min = 0;
        
        if (_syncNumber == 1)
        {
            hour = ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)?(int)[TDM329WatchSettingsUserDefaults autoSyncTimes1_Hour]:(int)[TDM328WatchSettingsUserDefaults autoSyncTimes1_Hour];
            min = ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)?(int)[TDM329WatchSettingsUserDefaults autoSyncTimes1_Minute]:(int)[TDM328WatchSettingsUserDefaults autoSyncTimes1_Minute];
            autoSyncSwitch.on = ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)?[TDM329WatchSettingsUserDefaults autoSyncTimes1_TimeEnabled]:[TDM328WatchSettingsUserDefaults autoSyncTimes1_TimeEnabled];
        }
        else if (_syncNumber == 2)
        {
            hour = ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)?(int)[TDM329WatchSettingsUserDefaults autoSyncTimes2_Hour]:(int)[TDM328WatchSettingsUserDefaults autoSyncTimes2_Hour];
            min = ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)?(int)[TDM329WatchSettingsUserDefaults autoSyncTimes2_Minute]:(int)[TDM328WatchSettingsUserDefaults autoSyncTimes2_Minute];
            autoSyncSwitch.on = ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)?[TDM329WatchSettingsUserDefaults autoSyncTimes2_TimeEnabled]:[TDM328WatchSettingsUserDefaults autoSyncTimes2_TimeEnabled];
        }
        else if (_syncNumber == 3)
        {
            hour = ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)?(int)[TDM329WatchSettingsUserDefaults autoSyncTimes3_Hour]:(int)[TDM328WatchSettingsUserDefaults autoSyncTimes3_Hour];
            min = ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)?(int)[TDM329WatchSettingsUserDefaults autoSyncTimes3_Minute]:(int)[TDM328WatchSettingsUserDefaults autoSyncTimes3_Minute];
            autoSyncSwitch.on = ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)?[TDM329WatchSettingsUserDefaults autoSyncTimes3_TimeEnabled]:[TDM328WatchSettingsUserDefaults autoSyncTimes3_TimeEnabled];
        }
        else
        {
            hour = ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)?(int)[TDM329WatchSettingsUserDefaults autoSyncTimes4_Hour]:(int)[TDM328WatchSettingsUserDefaults autoSyncTimes4_Hour];
            min = ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)?(int)[TDM329WatchSettingsUserDefaults autoSyncTimes4_Minute]:(int)[TDM328WatchSettingsUserDefaults autoSyncTimes4_Minute];
            autoSyncSwitch.on = ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)?[TDM329WatchSettingsUserDefaults autoSyncTimes4_TimeEnabled]:[TDM328WatchSettingsUserDefaults autoSyncTimes4_TimeEnabled];
        }
    
        if ([iDevicesUtil isSystemTimeFormat24Hr]) {
            NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            [timeFormat setLocale:locale];
            [timeFormat setDateFormat:@"HH:mm"];
            ageDatePickerView.date =  [timeFormat dateFromString:[NSString stringWithFormat:@"%d:%d", hour, min]];
        } else {
            [timeFormat setDateFormat:@"h:mm a"];
            if (hour >= 12)
                ageDatePickerView.date = [timeFormat dateFromString:[NSString stringWithFormat:@"%d:%d pm", hour - 12, min]];
            else
            {
                ageDatePickerView.date = [timeFormat dateFromString:[NSString stringWithFormat:@"%d:%d am", hour, min]];
            }
        }
    }

    
    if (viewType == Setting_Gender) {
        infoLbl.text = NSLocalizedString(@"Enter your gender",nil);
        tableNPickerArray = [NSMutableArray arrayWithObjects:NSLocalizedString(@"Male",nil),NSLocalizedString(@"Female",nil), nil];
    } else if (viewType == Setting_Units) {
        infoLbl.text = NSLocalizedString(@"Which units do you use?",nil);
        tableNPickerArray = [NSMutableArray arrayWithObjects:NSLocalizedString(@"Imperial",nil),NSLocalizedString(@"Metric",nil), nil];
    } else if (viewType == Setting_Goals) {
        infoLbl.text = NSLocalizedString(@"Enter your activity",nil);
        tableNPickerArray = [NSMutableArray arrayWithObjects:NSLocalizedString(@"Active",nil),NSLocalizedString(@"Pretty Active",nil), NSLocalizedString(@"Very Active",nil), nil];
    } else if (viewType == Setting_Sensitivity) {
        infoLbl.text = NSLocalizedString(@"If your step count measures higher than it should be, select Low sensitivity. If it’s lower than it should be, select High sensitivity",nil);
        tableNPickerArray = [NSMutableArray arrayWithObjects:NSLocalizedString(@"Low",nil),NSLocalizedString(@"Medium",nil), NSLocalizedString(@"High",nil), nil];
    } else if (viewType == Setting_TrackSleep) {
        infoLbl.text = NSLocalizedString(@"Track your sleep activity",nil);
        tableNPickerArray = [NSMutableArray arrayWithObjects:NSLocalizedString(@"All Day",nil),NSLocalizedString(@"During Bedtime",nil), nil];
    } else if (viewType == Setting_Distance) {
        infoLbl.text = NSLocalizedString(@"If your distance calculation is off, you can fine tune it here. If too low, increase the percentage or if too high, decrease the percentage",nil);
        tableNPickerArray = [[NSMutableArray alloc] init];
        for (int i = M328_USER_DATA_DISTANCEADJUSTMENT_MINIMUM_PERCENTAGE; i <= M328_USER_DATA_DISTANCEADJUSTMENT_MAXIMUM_PERCENTAGE; i++) {
            [tableNPickerArray addObject:[NSNumber numberWithInt:i]];
        }
    } else if (viewType == Setting_ChangeWatch) {
        infoLbl.text = NSLocalizedString(@"Choose your watch",nil);
        tableNPickerArray = [[NSMutableArray alloc] init];
        PeripheralDevice * connectedDevice = [iDevicesUtil getConnectedTimexDevice];
        if (connectedDevice != nil)
        {
            if (![[TDStoredWatchUserDefaults storedPeripherals] containsObject:connectedDevice]) {
                [tableNPickerArray addObject:NSLocalizedString(@"Save this watch",nil)];
            }
        }
        [tableNPickerArray addObject:[TDStoredWatchUserDefaults storedPeripherals]];
    } else if (viewType == Setting_Height) {
        infoLbl.text = NSLocalizedString(@"Enter your height",nil);
        heightDict = [[NSMutableDictionary alloc] init];
        if ([iDevicesUtil isMetricSystem]) {
            int min = [self getMinHeight];
            int max = roundf([self getMaxHeight]);
            int minmeter = min/100;
            int mincm = min%100;
            int maxmeter = max/100;
            int maxcm = max%100;
            for (int i = minmeter; i <= maxmeter; i++) {
                if (i == minmeter) {
                    NSMutableArray *minArray = [NSMutableArray array];
                    for (int j = mincm; j <= 99 ; j++) {
                        [minArray addObject:[NSNumber numberWithInt:j]];
                    }
                    [heightDict setObject:minArray forKey:[NSNumber numberWithInt:i]];
                } else if (i == maxmeter) {
                    NSMutableArray *maxArray = [NSMutableArray array];
                    for (int j = 0; j <= maxcm; j++) {
                        [maxArray addObject:[NSNumber numberWithInt:j]];
                    }
                    [heightDict setObject:maxArray forKey:[NSNumber numberWithInt:i]];
                }
            }
        } else {
            float min = roundf([self getMinHeight]);
            float max = roundf([self getMaxHeight]);
            int minin = (int)min%12;
            int minft = (min - minin)/12;
            
            int maxin = (int)max%12;
            int maxft = (max - maxin)/12;
            
            for (int i = minft; i <= maxft; i++) {
                if (i == minft) {
                    NSMutableArray *minArray = [NSMutableArray array];
                    for (int j = minin; j <= 11; j++) {
                        [minArray addObject:[NSNumber numberWithInt:j]];
                    }
                    [heightDict setObject:minArray forKey:[NSNumber numberWithInt:i]];
                } else if (i == maxft) {
                    NSMutableArray *maxArray = [NSMutableArray array];
                    for (int j = 0; j <= maxin; j++) {
                        [maxArray addObject:[NSNumber numberWithInt:j]];
                    }
                    [heightDict setObject:maxArray forKey:[NSNumber numberWithInt:i]];
                } else {
                    NSMutableArray *array = [NSMutableArray array];
                    for (int j = 0; j <= 11; j++) {
                        [array addObject:[NSNumber numberWithInt:j]];
                    }
                    [heightDict setObject:array forKey:[NSNumber numberWithInt:i]];
                }
            }
        }
        sortKeyArray = [NSArray arrayWithArray:[heightDict allKeys]];
        NSSortDescriptor* sortOrder = [NSSortDescriptor sortDescriptorWithKey: @"self"
                                                                    ascending: YES];
        sortKeyArray = [sortKeyArray sortedArrayUsingDescriptors: [NSArray arrayWithObject: sortOrder]];
    } else if (viewType == Setting_Weight) {
        infoLbl.text = NSLocalizedString(@"Enter your weight",nil);
        tableNPickerArray = [[NSMutableArray alloc] init];
        int min = [self getMinWeight];
        int max = [self getMaxWeight];
        for (int i = min; i <= max; i++) {
            [tableNPickerArray addObject:[NSNumber numberWithInt:i]];
        }
    }
    infoLbl.font = enableLbl.font = [UIFont fontWithName:[iDevicesUtil getAppWideFontName] size:GENERIC_TABLE_CELL_FONT_SIZE];
    infoLbl.textColor = enableLbl.textColor = [UIColor darkGrayColor];
    infoLbl.backgroundColor = enableLbl.backgroundColor = [UIColor clearColor];
    self.view.backgroundColor = UIColorFromRGB(GROUPED_TABLEVIEW_BACKGROUND_COLOR);
    [ageDatePickerView setBackgroundColor:[UIColor whiteColor]];
    TCEND
}

- (NSNumber *)getUserWeight {
    TCSTART
    if ([iDevicesUtil isMetricSystem]) {
        return [NSNumber numberWithInteger:roundf([TDM328WatchSettingsUserDefaults userWeight]/10.0f)];
    } else {
        float weight = roundf([iDevicesUtil convertKilogramsToPounds:[TDM328WatchSettingsUserDefaults userWeight]/10.0f]);
        return [NSNumber numberWithInteger:(int)weight];
    }
    TCEND
}
- (void)viewDidAppear:(BOOL)animated {
    TCSTART
    [super viewDidAppear:animated];
    if (viewType == Setting_Height) {
        int userHeightCm = (int)[TDM328WatchSettingsUserDefaults userHeight];
        if ([iDevicesUtil isMetricSystem]) {
            int meter = userHeightCm/100;
            int cm = userHeightCm-(meter*100);
            if ([sortKeyArray containsObject:[NSNumber numberWithInt:meter]]) {
                [detailPickerView selectRow:[sortKeyArray indexOfObject:[NSNumber numberWithInt:meter]] inComponent:0 animated:YES];
                [detailPickerView reloadComponent:1];
                NSArray *sub = [heightDict objectForKey:[NSNumber numberWithInt:meter]];
                if ([sub containsObject:[NSNumber numberWithInt:cm]]) {
                    [detailPickerView selectRow:[sub indexOfObject:[NSNumber numberWithInt:cm]] inComponent:1 animated:YES];
                }
            }
        } else {
            float inches = roundf([iDevicesUtil convertCentimetersToInches: (float)userHeightCm]);
            int inch = (int)inches % 12;
            int ft = (inches - inch)/12;
            if ([sortKeyArray containsObject:[NSNumber numberWithInt:ft]]) {
                [detailPickerView selectRow:[sortKeyArray indexOfObject:[NSNumber numberWithInt:ft]] inComponent:0 animated:YES];
                [detailPickerView reloadComponent:1];
                NSArray *sub = [heightDict objectForKey:[NSNumber numberWithInt:ft]];
                if ([sub containsObject:[NSNumber numberWithInt:inch]]) {
                    [detailPickerView selectRow:[sub indexOfObject:[NSNumber numberWithInt:inch]] inComponent:1 animated:YES];
                }
                
                previousSelectedInches = inch;
            }
        }
    } else if (viewType == Setting_Weight && [tableNPickerArray containsObject:[self getUserWeight]]) {
        [detailPickerView selectRow:[tableNPickerArray indexOfObject:[self getUserWeight]] inComponent:0 animated:YES];
    } else if (viewType == Setting_Distance && [tableNPickerArray containsObject:[NSNumber numberWithInt:(int)[TDM328WatchSettingsUserDefaults distanceAdjustment]]]) {
        [detailPickerView selectRow:[tableNPickerArray indexOfObject:[NSNumber numberWithInt:(int)[TDM328WatchSettingsUserDefaults distanceAdjustment]]] inComponent:0 animated:YES];
    }
    TCEND
}

- (int)getMinHeight {
    TCSTART
    if ([iDevicesUtil isMetricSystem]) {
        return M328_USER_DATA_HEIGHT_MINIMUM_CENTIEMTERS;
    } else {
        return [iDevicesUtil convertCentimetersToInches:M328_USER_DATA_HEIGHT_MINIMUM_CENTIEMTERS];
    }
    TCEND
}

- (float)getMaxHeight {
    TCSTART
    if ([iDevicesUtil isMetricSystem]) {
        return M328_USER_DATA_HEIGHT_MAXIMUM_CENTIEMTERS;
    } else {
        return [iDevicesUtil convertCentimetersToInches:M328_USER_DATA_HEIGHT_MAXIMUM_CENTIEMTERS];
    }
    TCEND
}

- (int)getMinWeight {
    TCSTART
    if ([iDevicesUtil isMetricSystem]) {
        return M328_USER_DATA_WEIGHT_MINIMUM_KILOS/10;
    } else {
        return [iDevicesUtil convertKilogramsToPounds:M328_USER_DATA_WEIGHT_MINIMUM_KILOS/10];
    }
    TCEND
}

- (int)getMaxWeight {
    TCSTART
    if ([iDevicesUtil isMetricSystem]) {
        return M328_USER_DATA_WEIGHT_MAXIMUM_KILOS/10;
    } else {
        return roundf([iDevicesUtil convertKilogramsToPounds:M328_USER_DATA_WEIGHT_MAXIMUM_KILOS/10]);
    }
    TCEND
}

#pragma  mark Button Actions
- (void) backButtonTapped {
    TCSTART
    if (viewType == Setting_Age) {
        [self saveYears];
    }
    if (viewType == Setting_SleepTime || viewType == Setting_AwakeTime || viewType == Setting_SyncTime) {
        [self saveTime];
    }
    [self.navigationController popViewControllerAnimated:YES];
    TCEND
}
- (void)saveYears
{
    TCSTART
    NSDate *dateA = ageDatePickerView.date;
    NSDate *dateB = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay
                                               fromDate:dateA
                                                 toDate:dateB
                                                options:0];
    [TDM328WatchSettingsUserDefaults setAge:(int)components.year];
    [TDM328WatchSettingsUserDefaults setDateOfBirth:ageDatePickerView.date];
    [customTabbar syncNeeded];
    TCEND
}

- (void)saveTime
{
    TCSTART
    NSDate *time = ageDatePickerView.date;
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:(NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:time];
    NSInteger hour = [components hour];
    NSInteger minute = [components minute];
    
    if (viewType == Setting_SleepTime)
    {
        [TDM328WatchSettingsUserDefaults setBedHour:hour];
        [TDM328WatchSettingsUserDefaults setBedMin:minute];
    }
    else if (viewType == Setting_AwakeTime)
    {
        [TDM328WatchSettingsUserDefaults setAwakeHour:hour];
        [TDM328WatchSettingsUserDefaults setAwakeMin:minute];
    }
    else
    {
        if (_syncNumber == 1)
        {
            ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)?[TDM329WatchSettingsUserDefaults setAutoSyncTimes1_Hour:hour]:[TDM328WatchSettingsUserDefaults setAutoSyncTimes1_Hour:hour];
            ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)?[TDM329WatchSettingsUserDefaults setAutoSyncTimes1_Minute:minute]:[TDM328WatchSettingsUserDefaults setAutoSyncTimes1_Minute:minute];
            ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)?[TDM329WatchSettingsUserDefaults setAutoSyncTimes1_TimeEnabled:autoSyncSwitch.on]:[TDM328WatchSettingsUserDefaults setAutoSyncTimes1_TimeEnabled:autoSyncSwitch.on];
        }
        else if (_syncNumber == 2)
        {
            ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)?[TDM329WatchSettingsUserDefaults setAutoSyncTimes2_Hour:hour]:[TDM328WatchSettingsUserDefaults setAutoSyncTimes2_Hour:hour];
            ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)?[TDM329WatchSettingsUserDefaults setAutoSyncTimes2_Minute:minute]:[TDM328WatchSettingsUserDefaults setAutoSyncTimes2_Minute:minute];
            ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)?[TDM329WatchSettingsUserDefaults setAutoSyncTimes2_TimeEnabled:autoSyncSwitch.on]:[TDM328WatchSettingsUserDefaults setAutoSyncTimes2_TimeEnabled:autoSyncSwitch.on];
        }
        else if (_syncNumber == 3)
        {
            ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)?[TDM329WatchSettingsUserDefaults setAutoSyncTimes3_Hour:hour]:[TDM328WatchSettingsUserDefaults setAutoSyncTimes3_Hour:hour];
            ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)?[TDM329WatchSettingsUserDefaults setAutoSyncTimes3_Minute:minute]:[TDM328WatchSettingsUserDefaults setAutoSyncTimes3_Minute:minute];
            ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)?[TDM329WatchSettingsUserDefaults setAutoSyncTimes3_TimeEnabled:autoSyncSwitch.on]:[TDM328WatchSettingsUserDefaults setAutoSyncTimes3_TimeEnabled:autoSyncSwitch.on];
        }
        else
        {
            ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)?[TDM329WatchSettingsUserDefaults setAutoSyncTimes4_Hour:hour]:[TDM328WatchSettingsUserDefaults setAutoSyncTimes4_Hour:hour];
            ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)?[TDM329WatchSettingsUserDefaults setAutoSyncTimes4_Minute:minute]:[TDM328WatchSettingsUserDefaults setAutoSyncTimes4_Minute:minute];
            ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)?[TDM329WatchSettingsUserDefaults setAutoSyncTimes4_TimeEnabled:autoSyncSwitch.on]:[TDM328WatchSettingsUserDefaults setAutoSyncTimes4_TimeEnabled:autoSyncSwitch.on];
        }
    }
    [customTabbar syncNeeded];
    TCEND
    
}

- (void)didReceiveMemoryWarning {
     OTLog([NSString stringWithFormat:@"Recived Memory Warning  in %@ ",NSStringFromClass([self class])]);
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)timeIsChanged:(id)sender
{
    TCSTART
    if (viewType == Setting_SyncTime)
    {
        [customTabbar syncNeeded];
    }
    TCEND
}


#pragma mark
#pragma mark UITableView Delegate and Datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return tableNPickerArray.count;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 1;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"";
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TCSTART
    NSString *cellId = @"cellid";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellId];
    }
    cell.textLabel.font = [UIFont fontWithName: [iDevicesUtil getAppWideFontName] size: M328_SLIDE_MENU_CELL_FONT_SIZE];
    cell.textLabel.textColor = [UIColor blackColor];
    
    if (viewType == Setting_Gender || viewType == Setting_Units || viewType == Setting_Goals || viewType == Setting_Sensitivity || viewType == Setting_TrackSleep) {
        cell.textLabel.text = [tableNPickerArray objectAtIndex:indexPath.row];
    } else if (viewType == Setting_ChangeWatch) {
        if ([[tableNPickerArray objectAtIndex:indexPath.row] isEqualToString:NSLocalizedString(@"Save this watch",nil)]) {
            cell.textLabel.text = [tableNPickerArray objectAtIndex:indexPath.row];
        } else {
            PeripheralDevice *peripheral = [tableNPickerArray objectAtIndex:indexPath.row];
            cell.textLabel.text = [NSString stringWithFormat:@"%@: %@", peripheral.model, peripheral.name];
        }
    }
    
    
    UIButton *accessoryBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    accessoryBtn.frame = CGRectMake(0, 0, 20, 20);
    
    [accessoryBtn addTarget:self action:@selector(clickedOnAccessoryBtn:) forControlEvents:UIControlEventTouchUpInside];
    accessoryBtn.tag = indexPath.row ;
    cell.accessoryView = accessoryBtn;
    int val = (viewType == Setting_Gender)?(int)[TDM328WatchSettingsUserDefaults gender]:(int)[TDM328WatchSettingsUserDefaults units];
    if (viewType == Setting_TrackSleep) {
        val = (int)[TDM328WatchSettingsUserDefaults trackSleep];
    }
    if (viewType == Setting_Goals) {
        val = (int)[TDM328WatchSettingsUserDefaults goalType];
    }
    if (viewType == Setting_Sensitivity) {
        val = (int)[TDM328WatchSettingsUserDefaults sensorSensitivity];
    }
    if (val == indexPath.row) {
        [accessoryBtn setImage:[UIImage imageNamed:@"checkbox_checked_icon"] forState:UIControlStateNormal];
    } else {
        [accessoryBtn setImage:[UIImage imageNamed:@""] forState:UIControlStateNormal];
    }
    return cell;
    TCEND
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    TCSTART
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (viewType == Setting_ChangeWatch) {
        PeripheralDevice * connectedDevice = [iDevicesUtil getConnectedTimexDevice];
        if ([cell.textLabel.text isEqualToString:NSLocalizedString(@"Save this watch",nil)] && connectedDevice != nil) {
            NSMutableArray *storedWatches = [[NSMutableArray alloc] initWithArray:[TDStoredWatchUserDefaults storedPeripherals]];
            [storedWatches addObject:connectedDevice];
            [TDStoredWatchUserDefaults setStoredPeripherals:storedWatches];
            [tableView reloadData];
        } else {
            [TDStoredWatchUserDefaults changeHomeScreen:[tableNPickerArray objectAtIndex:indexPath.row]];
        }
    } else {
        UIButton *btn = (UIButton *)[cell accessoryView];
        [self clickedOnAccessoryBtn:btn];
        [customTabbar syncNeeded];
    }
    TCEND
}
- (void)clickedOnAccessoryBtn:(UIButton *)sender {
    TCSTART
    if (viewType == Setting_Gender) {
        [TDM328WatchSettingsUserDefaults setGender:(int)sender.tag];
    } else if (viewType == Setting_Units) {
        [TDM328WatchSettingsUserDefaults setUnits:(int)sender.tag];
    } else if (viewType == Setting_Sensitivity){
        [TDM328WatchSettingsUserDefaults setSensorSensitivity:(int)sender.tag];
    } else if (viewType == Setting_TrackSleep){
        [TDM328WatchSettingsUserDefaults setTrackSleep:(int)sender.tag];
    }
    [genderTableView reloadData];
    [self backButtonTapped];
    [customTabbar syncNeeded];
    TCEND
}

#pragma mark
#pragma mark Height and Weight PickerViewDelegate and Datasource
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    TCSTART
    if (viewType == Setting_Height) {
        return 2;
    }
    return 1;
    TCEND
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
TCSTART
    if (viewType == Setting_Height) {
        if (component == 0) {
            return [sortKeyArray count];
        } else {
            int selectedRowinCom = (int)[pickerView selectedRowInComponent:0];
            return [[heightDict objectForKey:[sortKeyArray objectAtIndex:selectedRowinCom]] count];
        }
    }
    return tableNPickerArray.count;
    TCEND
}
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    TCSTART
    if (viewType == Setting_Height) {
        if ([iDevicesUtil isMetricSystem]) {
            if (component == 0) {
                return [NSString stringWithFormat:@"%d",(int)[[sortKeyArray objectAtIndex:row] intValue]];
            } else {
                TCSTART
                NSNumber *key = [sortKeyArray objectAtIndex:[pickerView selectedRowInComponent:0]];
                NSNumber *num = [[heightDict objectForKey:key] objectAtIndex:row];
                return [NSString stringWithFormat:@".%02d m",(int)num.intValue];
                TCEND
            }
        } else {
            if (component == 0) {
                return [NSString stringWithFormat:NSLocalizedString(@"%d ft",nil),(int)[[sortKeyArray objectAtIndex:row] intValue]];
            } else {
                TCSTART
                NSNumber *key = [sortKeyArray objectAtIndex:[pickerView selectedRowInComponent:0]];
                NSNumber *num = [[heightDict objectForKey:key] objectAtIndex:row];
                return [NSString stringWithFormat:NSLocalizedString(@"%d in",nil),(int)num.intValue];
                TCEND
            }
        }
    } else {
        if (viewType == Setting_Height) {
            return [NSString stringWithFormat:NSLocalizedString(@"%d inches",nil),[[tableNPickerArray objectAtIndex:row] intValue]];
        } else if (viewType == Setting_Weight) {
            return [NSString stringWithFormat:@"%d %@",[[tableNPickerArray objectAtIndex:row] intValue],[iDevicesUtil isMetricSystem]?NSLocalizedString(@"kg",nil):NSLocalizedString(@"lbs",nil)];
        } else if (viewType == Setting_Distance) {
            return [NSString stringWithFormat:@"%d %%",[[tableNPickerArray objectAtIndex:row] intValue]];
        }
    }
    
    return @"";
    TCEND
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    TCSTART
    if (viewType == Setting_Height) {
        if (component == 0) {
            [pickerView reloadComponent:1];
            [self adjustInchesInComponent:row];
        } else {
            [pickerView reloadComponent:0];
        }
        NSNumber *key = [sortKeyArray objectAtIndex:[pickerView selectedRowInComponent:0]];
        NSNumber *value = [[heightDict objectForKey:key] objectAtIndex:[pickerView selectedRowInComponent:1]];
        
        previousSelectedInches = [value intValue];
        
        if ([iDevicesUtil isMetricSystem]) {
            int meter = (int)key.intValue;
            int cm = (int)(meter * 100);
            float whole = cm + (value.intValue % 100);
            [TDM328WatchSettingsUserDefaults setUserHeight:(int)roundf(whole)];
        } else {
            int ft = (int)key.intValue;
            int inch = (int)(ft*12 + value.intValue);
            
            [TDM328WatchSettingsUserDefaults setUserHeight:(int)[iDevicesUtil convertInchesToCentimeters:inch]];
        }
    } else if (viewType == Setting_Weight) {
        if ([iDevicesUtil isMetricSystem]) {
            [TDM328WatchSettingsUserDefaults setUserWeight:[[tableNPickerArray objectAtIndex:row] integerValue]*10];
        } else {            
            float eight =[iDevicesUtil convertPoundsToKilograms:[[tableNPickerArray objectAtIndex:row] floatValue]];
            int userweight = eight*10;
            [TDM328WatchSettingsUserDefaults setUserWeight:userweight];
        }
    } else if (viewType == Setting_Distance) {
        [TDM328WatchSettingsUserDefaults setDistanceAdjustment:[[tableNPickerArray objectAtIndex:row]intValue]];
    }
    [customTabbar syncNeeded];
    TCEND
}

-(void)adjustInchesInComponent:(NSInteger) row
{
    NSArray *inches = [heightDict objectForKey:[sortKeyArray objectAtIndex:row]];
    
    for (int i = 0; i < inches.count; i++)
    {
        if([[inches objectAtIndex:i] intValue] == previousSelectedInches)
        {
            [detailPickerView selectRow:i inComponent:1 animated:NO];
            return;
        }
    }
    
    [detailPickerView selectRow:0 inComponent:1 animated:YES];
}

@end
