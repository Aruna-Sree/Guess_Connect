//
//  StepsViewController.m
//  Timex
//
//  Created by avemulakonda on 5/11/16.
//

#import "StepsViewController.h"
#import "TDDefines.h"
#import "iDevicesUtil.h"
//#import "Activity.h"
//#import "Goals.h"
#import "CustomTabbar.h"
#import "TDAppDelegate.h"
#import "TimexWatchDB.h"
#import "TDM328WatchSettingsUserDefaults.h"
#import "OTLogUtil.h"
#import "TDHomeViewController.h"
#import "DBModule.h"
#import "DBActivity+CoreDataClass.h"
#import "DBHourActivity+CoreDataClass.h"
#import "MBProgressHUD.h"
#import "UIImage+Tint.h"

#define ExtraRecords 3 //  adding extra records to make chartview scroll
@interface StepsViewController ()
{
    
    CustomTabbar *customTabbar;
    TDAppDelegate *appdel;
    
    NSInteger highlightedIndex;
    NSMutableArray *xValues;
    NSMutableArray *yValues;
    NSMutableArray *datesArray;
    NSMutableDictionary *hoursDict;

    BOOL panGestureStateChanged;
    MBProgressHUD *HUD;
    
    NSDate *dateSelected;
    
    IBOutlet UIView *limitLineView;
    IBOutlet NSLayoutConstraint *limitLineHeightConstraints;
    
    IBOutlet NSLayoutConstraint *limitLineLeftConstarint;
    IBOutlet NSLayoutConstraint *limitLineTopConstarint;
    
    double goal_dbl;
}
@end

@implementation StepsViewController
@synthesize caller;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil selectedDate:(NSDate *)date
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        dateSelected = date;
    }
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    chartView.hidden = YES;
    headerView.hidden = YES;
    appdel = (TDAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))  {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    NSDictionary *goalsDict = [[NSUserDefaults standardUserDefaults] valueForKey: [iDevicesUtil getGoalTypeStringFormat:(GoalType)[TDM328WatchSettingsUserDefaults goalType]]];
    NSInteger stepsGoals = [[goalsDict objectForKey:STEPS] integerValue];
    CGFloat distanceGoals = [[goalsDict objectForKey:DISTANCE] floatValue];
    CGFloat calgoals = [[goalsDict objectForKey:CALORIES] floatValue];
    
    if (_selectedRow == 0) {
        self.title = [NSLocalizedString(@"Steps",nil) uppercaseString];
        limit = stepsGoals;
        [backgroundImgView setImage:[[UIImage imageNamed: @"Charts_Steps"] imageWithTint: UIColorFromRGB(M328_STEPS_GRAPH_COLOR)]];
    } else if (_selectedRow == 1) {
        self.title = [NSLocalizedString(@"Distance",nil) uppercaseString];
        if (![iDevicesUtil isMetricSystem]) {
            limit = [iDevicesUtil convertKilometersToMiles:distanceGoals];
        } else {
            limit = distanceGoals;
        }
        [backgroundImgView setImage:[[UIImage imageNamed: @"Charts_Distance"] imageWithTint: UIColorFromRGB(M328_DISTANCE_GRAPH_COLOR)]];
    } else {
        self.title = [NSLocalizedString(@"Calories",nil) uppercaseString];
        limit = calgoals;
        [backgroundImgView setImage:[[UIImage imageNamed: @"Charts_Claories"] imageWithTint: UIColorFromRGB(M328_CALORIES_GRAPH_COLOR)]];
    }
     
    goal_dbl = limit;
    
    NSDictionary * navBarTitleTextAttributes =  @{NSFontAttributeName : [UIFont fontWithName:[iDevicesUtil getAppWideBoldFontName] size:APP_HEADER_FONT_SIZE] };
    self.navigationController.navigationBar.titleTextAttributes = navBarTitleTextAttributes;
    [self segmentedControlCustomization];
    
    headerView.backgroundColor = UIColorFromRGB(M328_TABLEVIEW_HEADER_GRAY_COLOR);
    
    
    UIButton *backBtn = [iDevicesUtil getBackButton];
    [backBtn addTarget:self action:@selector(backButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barBtn = [[UIBarButtonItem alloc] initWithCustomView:backBtn];
    self.navigationItem.leftBarButtonItem = barBtn;
    
    // Add Notification Observers
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncDataFinished:) name:@"SyncDataFinished" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [self displayLoadingView];

}

- (void)didReceiveMemoryWarning {
     OTLog([NSString stringWithFormat:@"Recived Memory Warning  in %@ ",NSStringFromClass([self class])]);
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)appDidBecomeActive:(NSNotification *)notification {
    [self syncDataFinished:nil];
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self syncData];
    [self addCustomTabbar];
    
    chartView.hidden = NO;
    headerView.hidden = NO;
    //[chartView centerViewToAnimatedWithXValue:highlightedIndex yValue:0 axis:AxisDependencyLeft duration:0];  //crashes
    _dashedLeftConstraint.constant = chartView.centerOffsets.x - (CGFloat)0.5; // 0.5 is dashedLineWidth/2
    dashedLineBottomConstraint.constant = (chartView.frame.size.height - (chartView.centerOffsets.y * 2))+10;
    [HUD hide:YES];
    
    [self performSelector:@selector(customizeLimitLine) withObject:nil afterDelay:0.1];
}

-(void)customizeLimitLine
{
    CGPoint point = [chartView pixelForValuesWithX:0 y:limit axis:AxisDependencyLeft];
    
    CGFloat y = point.y;
    
    CGFloat x = chartView.contentRect.origin.x;
    
    limitLineLeftConstarint.constant = x;
    if (!isnan(y - limitLineHeightConstraints.constant/2)) {
        limitLineTopConstarint.constant = y - limitLineHeightConstraints.constant/2;
    }
    
    if (_segmentedindex == 1 || _segmentedindex == 2) {
        if (xValues.count == 0) {
            [limitLineView setHidden:YES];
        } else {
            [limitLineView setHidden:NO];
        }
    } else {
        [limitLineView setHidden:YES];
    }
}

- (void)displayLoadingView {
    HUD = [[MBProgressHUD alloc] initWithView: self.navigationController.view];
    [self.navigationController.view addSubview: HUD];
    HUD.labelText = NSLocalizedString(@"Please Wait", nil);
    HUD.detailsLabelText =  NSLocalizedString(@"Loading...", nil);
    HUD.square = YES;
    [HUD show:YES];
}

- (void)syncData {
    [self setUpChart];
    [self setDataCount];//:6 range:10];
}

- (void)syncDataFinished:(NSNotification *)notification {
    [self syncData];
    
    [self performSelector:@selector(customizeLimitLine) withObject:nil afterDelay:0.1];
}

#pragma mark
#pragma mark CustomTabbar
- (void)addCustomTabbar {
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
    
    chartBottomConstraint.constant = customTabbar.frame.size.height-30+5;
    [customTabbar updateLastLblText];
}

#pragma  mark Button Actions
- (void) backButtonTapped {
    if (datesArray.count > highlightedIndex) {
        if ([datesArray objectAtIndex:highlightedIndex] != nil && (_segmentedindex == 1 || _segmentedindex == 0)) {
            if (_segmentedindex == 0) {
                ((TDHomeViewController *)caller).dateSelected = [iDevicesUtil onlyDateFormat:[datesArray objectAtIndex:highlightedIndex]];
            } else {
                ((TDHomeViewController *)caller).dateSelected = [datesArray objectAtIndex:highlightedIndex];
            }
        }
    }
    [self.navigationController popViewControllerAnimated:YES];
}

- (NSAttributedString *)getAttributedStrWithText:(NSString *)firstText formatStr:(NSString *)formattext tagStr:(NSString *)tagstr{
    
    UIFont *maxCalDayFont = [UIFont fontWithName:[iDevicesUtil getAppWideMediumFontName] size:M328_SLEEP_DETAILS_CELL_TITLE_FONT_SIZE];
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:maxCalDayFont, NSFontAttributeName, AppColorLightGray,NSForegroundColorAttributeName, nil];
    NSMutableAttributedString *totalAtrTime = [[NSMutableAttributedString alloc] initWithString:firstText attributes:dict];
    
    UIFont *maxCalFont = [UIFont fontWithName:[iDevicesUtil getAppWideMediumFontName] size:M328_STEPS_SCREEN_STEPS_FONT_SIZE];
    NSDictionary *dict2 = [NSDictionary dictionaryWithObjectsAndKeys:maxCalFont, NSFontAttributeName, [UIColor blackColor],NSForegroundColorAttributeName, nil];
    NSMutableAttributedString *totalAtrTime2 = [[NSMutableAttributedString alloc] initWithString:formattext attributes:dict2];
    
    [totalAtrTime appendAttributedString:totalAtrTime2];
    
    if (tagstr.length > 0) {
        NSMutableAttributedString *totalAtrTime3 = [[NSMutableAttributedString alloc] initWithString:tagstr attributes:dict];
        [totalAtrTime appendAttributedString:totalAtrTime3];
    }
    
    return totalAtrTime;
}



- (NSAttributedString *)getAttributedStrWithText2:(NSString *)firstText formatStr:(NSString *)formattext{
    
    UIFont *maxCalDayFont = [UIFont fontWithName:[iDevicesUtil getAppWideMediumFontName] size:M328_SLEEP_DETAILS_CELL_TITLE_FONT_SIZE];
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:maxCalDayFont, NSFontAttributeName, AppColorLightGray,NSForegroundColorAttributeName, nil];
    NSMutableAttributedString *totalAtrTime = [[NSMutableAttributedString alloc] initWithString:firstText attributes:dict];
    
    UIFont *maxCalFont = [UIFont fontWithName:[iDevicesUtil getAppWideMediumFontName] size:M328_STEPS_SCREEN_DISTANCE_FONT_SIZE];
    NSDictionary *dict2 = [NSDictionary dictionaryWithObjectsAndKeys:maxCalFont, NSFontAttributeName, [UIColor blackColor],NSForegroundColorAttributeName, nil];
    NSMutableAttributedString *totalAtrTime2 = [[NSMutableAttributedString alloc] initWithString:formattext attributes:dict2];
    
    [totalAtrTime appendAttributedString:totalAtrTime2];
    return totalAtrTime;
}


- (void)segmentedControlCustomization {
    // Segmented control with scrolling
    rangeSegments = [[HMSegmentedControl alloc] initWithSectionTitles:@[@"HOUR",@"DAY", @"WEEK", @"MONTH", @"YEAR"]];
    rangeSegments.frame = CGRectMake(0, 0, self.view.frame.size.width, 40);
    rangeSegments.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth;
    rangeSegments.selectionStyle = HMSegmentedControlSelectionStyleFullWidthStripe;
    rangeSegments.selectionIndicatorLocation = HMSegmentedControlSelectionIndicatorLocationDown;
    rangeSegments.selectionIndicatorColor = [UIColor blackColor];
    rangeSegments.selectionIndicatorHeight = 1.5f;
    rangeSegments.verticalDividerEnabled = NO;
    rangeSegments.titleTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:UIColorFromRGB(MEDIUM_GRAY_COLOR),NSForegroundColorAttributeName,[UIFont fontWithName: [iDevicesUtil getAppWideBoldFontName] size: M328_HOME_SCREEN_CALENDER_VIEW_FONT_SIZE],NSFontAttributeName, nil];
    rangeSegments.selectedTitleTextAttributes = @{NSForegroundColorAttributeName : [UIColor blackColor]};
    rangeSegments.selectedSegmentIndex = 0;
    [rangeSegments addTarget:self action:@selector(segmentDidChange:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:rangeSegments];
}

- (IBAction)segmentDidChange:(id)sender {
    
    _segmentedindex = [sender selectedSegmentIndex];
    [self setDataCount]; //:6 range:10];
    
    [self performSelector:@selector(customizeLimitLine) withObject:nil afterDelay:0.1];
}

- (void)setDataCount {
    // Activitydistance always getting as KM
    highlightedIndex = 0;
    NSMutableArray *histogramData = [[NSMutableArray alloc] init];
    hoursDict = [[NSMutableDictionary alloc] init];

    NSDate *startDate;
    NSDate *endDate;

    NSArray *dbArray = [[DBModule sharedInstance] getSortedArrayFor:@"DBActivity" predicate:nil keyString:@"date" isAscending:YES];
    
    DBActivity *activityEnd = [dbArray lastObject];
    startDate = [self findMinDate:dbArray];
    endDate = activityEnd.date;
    NSDate *currentDate = [iDevicesUtil todayDateAtMidnight];
    
    if (startDate != nil && endDate != nil) {
        if (_segmentedindex == 0) {
            int noOfDays = (int)[iDevicesUtil getDayCountBetweenDates:startDate enddate:endDate];
            for (int i = 0; i < noOfDays; i++) {
                NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
                dayComponent.day = i;
                
                NSCalendar *theCalendar = [NSCalendar currentCalendar];
                NSDate *dateToAdd = [theCalendar dateByAddingComponents:dayComponent toDate:startDate options:0];
                
                if ([currentDate timeIntervalSinceDate:dateToAdd] < 0)
                {
                    break;
                }
                
                DBActivity *activity = (DBActivity *)[[DBModule sharedInstance] getEntity:@"DBActivity" withPredicate:[NSPredicate predicateWithFormat: @"%K==%@",@"date",dateToAdd]];
                if (activity != nil) {
                    NSMutableArray *hrsArray = [[NSMutableArray alloc] init];
                    NSSortDescriptor *timedIdDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"timeID" ascending:YES];
                    NSArray *sortedActivitiesArray2 = [activity.hourActivities sortedArrayUsingDescriptors:[NSArray arrayWithObject:timedIdDescriptor]];
                    for (DBHourActivity *hourActivity in sortedActivitiesArray2) {
                        if ([iDevicesUtil compareDateOnly:dateToAdd AndEndDate:[iDevicesUtil todayDateAtMidnight]] == NSOrderedSame) {
                            if (hourActivity.timeID.intValue > [iDevicesUtil getHourFromDate:[NSDate date]].intValue) {
                                break;
                            }
                        }
                        NSString *str = [iDevicesUtil getTimeFromHrValue:hourActivity.timeID.intValue formatInNewLine:YES];
                        double totalValue = 0;
                        if (_selectedRow == 0) {
                            totalValue = hourActivity.steps.doubleValue;
                        } else if (_selectedRow == 1) {
                            totalValue = (![iDevicesUtil isMetricSystem]?[iDevicesUtil convertKilometersToMiles:(hourActivity.distance.floatValue/100.0)]:(hourActivity.distance.floatValue/100.0));
                        } else if (_selectedRow == 2) {
                            totalValue = hourActivity.calories.floatValue/10.0;
                        }
                        dayComponent.hour = hourActivity.timeID.integerValue;
                        NSDate *newDate = [theCalendar dateByAddingComponents:dayComponent toDate:startDate options:0];
                        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:newDate,@"date",str,@"Xvalue",[NSNumber numberWithDouble:totalValue],@"Yvalue",hourActivity.timeID,@"time", nil];
                        [histogramData addObject:dict];
                        [hrsArray addObject:hourActivity.timeID];
                    }
                    [hoursDict setObject:hrsArray forKey:activity.date];
                }
            }
        } else if (_segmentedindex == 1) {
            int noOfDays = (int)[iDevicesUtil getDayCountBetweenDates:startDate enddate:endDate];
            for (int i = 0; i < noOfDays; i++) {
                NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
                dayComponent.day = i;
                
                NSCalendar *theCalendar = [NSCalendar currentCalendar];
                NSDate *dateToAdd = [theCalendar dateByAddingComponents:dayComponent toDate:startDate options:0];
                
                if ([currentDate timeIntervalSinceDate:dateToAdd] < 0)
                {
                    break;
                }
                NSString *str = [iDevicesUtil getFirstLetterofTheDay:dateToAdd];
                if([iDevicesUtil compareDateOnly:dateToAdd AndEndDate:[iDevicesUtil todayDateAtMidnight]] == NSOrderedSame) {
                    str = NSLocalizedString(@"TODAY", nil);
                }
                
                double totalValue = 0;
                
                NSDictionary *ref = [self getRecordForTheDate:dateToAdd];
                if (_selectedRow == 0) {
                    totalValue = [ref[@"steps"] doubleValue];
                }
                else if (_selectedRow == 1) {
                    totalValue = (![iDevicesUtil isMetricSystem]?[iDevicesUtil convertKilometersToMiles:[ref[@"distance"] doubleValue]]:[ref[@"distance"] doubleValue]);
                }
                else if (_selectedRow == 2) {
                    totalValue = [ref[@"calories"] doubleValue];
                }
                
                NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:dateToAdd,@"date",str,@"Xvalue",[NSNumber numberWithDouble:totalValue],@"Yvalue", nil];
                [histogramData addObject:dict];
            }
        }
        else if (_segmentedindex == 2) {
            int noOfWeeks = (int)[iDevicesUtil getWeekCountBetweenDates:[iDevicesUtil getWeekStartDate:startDate] enddate:[iDevicesUtil getWeekEndDate:endDate]];
            
            // To display latest week first
            NSDate *weekStartDate = [iDevicesUtil getWeekStartDate:startDate];
            NSDate *weekEndDate = [iDevicesUtil getWeekEndDate:startDate];
            NSDate *currentWeek = [iDevicesUtil getWeekStartDate:currentDate];
            
            for (int i = 0; i < noOfWeeks; i++) {
                
                if ([currentWeek timeIntervalSinceDate:weekStartDate] < 0)
                {
                    break;
                }
                
                NSString *str = [self getcustomWeekString:weekStartDate andEndDate:weekEndDate];
                
                NSDictionary *ref = [self getRecordsInBetween:weekStartDate EndDate:weekEndDate];
                double totalValue = 0;
                
                if (_selectedRow == 0) {
                    totalValue = [ref[@"steps"] doubleValue];
                } else if (_selectedRow == 1) {
                    totalValue = (![iDevicesUtil isMetricSystem]?[iDevicesUtil convertKilometersToMiles:[ref[@"distance"] doubleValue]]:[ref[@"distance"] doubleValue]);
                } else if (_selectedRow == 2) {
                    totalValue = [ref[@"calories"] doubleValue];
                }
                
                NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:weekStartDate,@"date",str,@"Xvalue",[NSNumber numberWithDouble:totalValue],@"Yvalue", nil];
                [histogramData addObject:dict];
                
                NSCalendar *gregorian = [NSCalendar currentCalendar];
                NSDateComponents *components = [gregorian components:NSCalendarUnitWeekday | NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:weekStartDate];
                components.day += 7;
                
                NSDate *prevWeekDate1 = [gregorian dateFromComponents:components];
                weekStartDate = [iDevicesUtil getWeekStartDate:prevWeekDate1];
                weekEndDate = [iDevicesUtil getWeekEndDate:prevWeekDate1];
            }
        }
        
        else if (_segmentedindex == 3) {
            
            int noOfMonths = (int)[iDevicesUtil getMonthCountBetweenDates:[iDevicesUtil getFirstDateInMonth:startDate] enddate:[iDevicesUtil getLastDateInMonth:endDate]];
            
            // To display latest month first
            NSDate *monthStartDate = [iDevicesUtil getFirstDateInMonth:startDate];
            NSDate *monthEndDate = [iDevicesUtil getLastDateInMonth:startDate];
            NSDate *currentMonthDate = [iDevicesUtil getFirstDateInMonth:currentDate];
            
            for (int i = 0; i < noOfMonths; i++) {
                
                if ([currentMonthDate timeIntervalSinceDate:monthStartDate] < 0)
                {
                    break;
                }
                
                NSString *str = [self getcustomMonthString:monthStartDate];
                
                NSDictionary *ref = [self getRecordsInBetween:monthStartDate EndDate:monthEndDate];
                double totalValue = 0;
                if (_selectedRow == 0) {
                    totalValue = [ref[@"steps"] doubleValue];
                } else if (_selectedRow == 1) {
                    totalValue = (![iDevicesUtil isMetricSystem]?[iDevicesUtil convertKilometersToMiles:[ref[@"distance"] doubleValue]]:[ref[@"distance"] doubleValue]);
                } else if (_selectedRow == 2) {
                    totalValue = [ref[@"calories"] doubleValue];
                }
                
                NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:monthStartDate,@"date",str,@"Xvalue",[NSNumber numberWithDouble:totalValue],@"Yvalue", nil];
                [histogramData addObject:dict];
                
                monthStartDate = [iDevicesUtil getFirstDateOfNextMonth:monthStartDate];
                monthEndDate = [iDevicesUtil getLastDateInMonth:monthStartDate];
            }
        }
        
        else if (_segmentedindex == 4) {
            
            int noOfYears = (int)[iDevicesUtil getYearCountBetweenDates:[iDevicesUtil getFirstDateInYear:startDate] enddate:[iDevicesUtil getLastDateInYear:endDate]];
            
            // To display latest Year first
            NSDate *yearStartDate = [iDevicesUtil getFirstDateInYear:startDate];
            NSDate *yearEndDate = [iDevicesUtil getLastDateInYear:startDate];
            NSDate *currentYearDate = [iDevicesUtil getFirstDateInYear:currentDate];
            
            for (int i = 0; i < noOfYears; i++) {
                
                if ([currentYearDate timeIntervalSinceDate:yearStartDate] < 0)
                {
                    break;
                }
                
                NSString *str = [self getcustomYearString:yearEndDate];
                
                NSDictionary *ref = [self getRecordsInBetween:yearStartDate EndDate:yearEndDate];
                double totalValue = 0;
                if (_selectedRow == 0) {
                    totalValue = [ref[@"steps"] doubleValue];
                } else if (_selectedRow == 1) {
                    totalValue = (![iDevicesUtil isMetricSystem]?[iDevicesUtil convertKilometersToMiles:[ref[@"distance"] doubleValue]]:[ref[@"distance"] doubleValue]);
                } else if (_selectedRow == 2) {
                    totalValue = [ref[@"calories"] doubleValue];
                }
                NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:yearStartDate,@"date",str,@"Xvalue",[NSNumber numberWithDouble:totalValue],@"Yvalue", nil];
                [histogramData addObject:dict];

                yearStartDate = [iDevicesUtil getFirstDateOfNextYear:yearStartDate];
                yearEndDate = [iDevicesUtil getLastDateInYear:yearStartDate];
            }
        }
    }
    
    xValues = nil;
    yValues = nil;
    datesArray = nil;
    
    xValues = [[histogramData valueForKey:@"Xvalue"] mutableCopy];
    yValues = [[histogramData valueForKey:@"Yvalue"] mutableCopy];
    datesArray = [[histogramData valueForKey:@"date"] mutableCopy];
    
    if (xValues.count > 0) {
        // adding extra records to make chartview scroll
        int front = ExtraRecords;
        int back = ExtraRecords;
        for (int i = 0; i < front; i++) {
            [xValues insertObject:@"" atIndex:i];
            [yValues insertObject:[NSNumber numberWithDouble:0] atIndex:i];
            [datesArray insertObject:@"" atIndex:i];
        }
        for (int i = 0; i < back; i ++) {
            [xValues addObject:@""];
            [yValues addObject:[NSNumber numberWithDouble:0]];
            [datesArray addObject:@""];
        }
    }
    NSMutableArray *xVals = [[NSMutableArray alloc] init];
    [xVals addObjectsFromArray:xValues];
    
    NSMutableArray *yVals = [NSMutableArray array];
    NSMutableArray *colorsArr = [[NSMutableArray alloc] init];
    NSMutableArray *highlightColorsArr = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < yValues.count; i++) {
        NSNumber *num = yValues[i];
        
        BarChartDataEntry *data = [[BarChartDataEntry alloc] initWithX:i yValues:@[num] label:xVals[i]];
        [yVals addObject:data];
        
        if (_selectedRow == 0) {
            
            UIColor *color = UIColorFromRGB(M328_STEPS_GRAPH_COLOR);
            [colorsArr addObject:color];
            color = UIColorFromRGB(M328_STEPS_COLOR);
            [highlightColorsArr addObject:color];
            
        } else if (_selectedRow == 1) {
            
            UIColor *color = UIColorFromRGB(M328_DISTANCE_GRAPH_COLOR);
            [colorsArr addObject:color];
            color = UIColorFromRGB(M328_DISTANCE_COLOR);
            [highlightColorsArr addObject:color];
        }
        else {
            
            UIColor *color = UIColorFromRGB(M328_CALORIES_GRAPH_COLOR);
            [colorsArr addObject:color];
            color = UIColorFromRGB(M328_CALORIES_COLOR);
            [highlightColorsArr addObject:color];
        }
    }
    
    BarChartDataSet *set1 = nil;
    if (yVals.count > 0) {
        if (chartView.data.dataSetCount > 0) {
            set1 = (BarChartDataSet *)chartView.data.dataSets[0];
            set1.values = yVals;
            [set1 setColors:colorsArr];
            if (highlightColorsArr.count > 0) {
                [set1 setHighlightColor:highlightColorsArr[0]];
            }
            BarChartData *data = [[BarChartData alloc] initWithDataSet:set1];
            data.barWidth = 0.4;
            chartView.data = data;
            [chartView notifyDataSetChanged];
        } else {
            set1 = [[BarChartDataSet alloc] initWithValues:yVals label:nil];
            
            set1.drawValuesEnabled = false;
            [set1 setColors:colorsArr];
            if (highlightColorsArr.count > 0) {
                [set1 setHighlightColor:highlightColorsArr[0]];
            }
            NSMutableArray *dataSets = [[NSMutableArray alloc] init];
            [dataSets addObject:set1];
            
            BarChartData *data = [[BarChartData alloc] initWithDataSets:dataSets];
            data.barWidth = 0.4;
            [data setValueFont:[UIFont fontWithName:[iDevicesUtil getAppWideFontName] size:10]];
            
            chartView.data = data;
        }
    } else {
        [chartView clear];
        [chartView setNeedsDisplay];
        [chartView notifyDataSetChanged];
    }
    
    if (chartView.data.dataSetCount > 0 && yVals.count > 0) {
        if (_segmentedindex == 0) {
            if (dateSelected == nil) {
                dateSelected = [iDevicesUtil todayDateAtMidnight];
            }
            if (dateSelected != nil && [[hoursDict allKeys] containsObject:dateSelected]) {
                NSArray *hrsArray = [hoursDict objectForKey:dateSelected];
                NSSortDescriptor* sortOrder = [NSSortDescriptor sortDescriptorWithKey: @"self" ascending: NO];
                hrsArray = [hrsArray sortedArrayUsingDescriptors: [NSArray arrayWithObject: sortOrder]];
                dateSelected = [iDevicesUtil getHourDate:dateSelected withSelectedTime:[hrsArray firstObject]];
                highlightedIndex = [datesArray indexOfObject:dateSelected];
            } else {
                highlightedIndex = (int)(yVals.count-1)-ExtraRecords;
            }
        } else {
            if (dateSelected != nil && [datesArray containsObject:dateSelected]) {
                highlightedIndex = [datesArray indexOfObject:dateSelected];
            } else {
                highlightedIndex = (int)(yVals.count-1)-ExtraRecords;
            }
        }
        NSDate *date;
        if (dateSelected != nil) {
            if (_segmentedindex == 0) {
                date = dateSelected;
            } else if (_segmentedindex == 1) {
                dateSelected = [iDevicesUtil onlyDateFormat:dateSelected];
                date = dateSelected;
            } else if (_segmentedindex == 2) {
                date = [iDevicesUtil getWeekStartDate:dateSelected];
            } else if (_segmentedindex == 3) {
                date = [iDevicesUtil getFirstDateInMonth:dateSelected];
            } else if (_segmentedindex == 4) {
                date = [iDevicesUtil getFirstDateInYear:dateSelected];
            }
        }
        if (date != nil && [datesArray containsObject:date]) {
            highlightedIndex = [datesArray indexOfObject:date];
        } else {
            highlightedIndex = (int)(yVals.count-1)-ExtraRecords;
        }
    }
    chartView.legend.enabled = false;
    if (_segmentedindex == 2) { //  weekly goal (daily goal x 7) cloned from artf26851
        limit = goal_dbl * 7;
    } else {
        limit = goal_dbl;
    }
    NSString *limitStr;
    if (_selectedRow == 0) {
        //steps
        limitStr = [NSString stringWithFormat:@"%d", (int)limit];
    } else if (_selectedRow == 1) {
        //distance
        limitStr = [NSString stringWithFormat:@"%.2f", limit];
    } else {
        //calories
        limitStr = [NSString stringWithFormat:@"%d", (int)limit];
    }
    ChartLimitLine *limitline = [[ChartLimitLine alloc] initWithLimit:[limitStr floatValue] label:@""];
    limitline.labelPosition = ChartLimitLabelPositionRightBottom;
    limitline.lineWidth = 4;
    [limitline setLineColor:[UIColor clearColor]];
    [chartView.leftAxis addLimitLine:limitline];
    
    [self setupBarLineChartView:chartView];
    
    [chartView moveViewToX:xValues.count];
    [chartView animateWithXAxisDuration:0 yAxisDuration:0.5];
    if (xValues.count > 0) {
        dashedLine.hidden = NO;
        headerViewHeightConstraint.constant = 100;
        headerView.hidden = NO;
        if (xValues.count > 0 &&[xValues objectAtIndex:highlightedIndex] != nil && [[xValues objectAtIndex:highlightedIndex] length] > 0) {
            [chartView highlightValueWithX:highlightedIndex dataSetIndex:0 callDelegate:YES];
        } else {
            NSDate *selectedDate;
            if (dateSelected == nil) {
                selectedDate = [iDevicesUtil todayDateAtMidnight];
            } else {
                selectedDate = dateSelected;
            }
            if (_segmentedindex == 0) {
                [self fillHourDetails:selectedDate];
            } else if (_segmentedindex == 1) {
                [self fillDayDetails:selectedDate];
            } else if (_segmentedindex == 2) {
                NSDate *endDate = [selectedDate dateByAddingTimeInterval:6*SECONDS_PER_DAY];
                [self fillWeekDetails:selectedDate andEndDate:endDate];
            } else if (_segmentedindex == 3) {
                NSDate *endDate = [iDevicesUtil getLastDateInMonth:selectedDate];
                [self fillMonthOrYearDetails:selectedDate andEndDate:endDate isMonth:YES];
            } else if (_segmentedindex == 4) {
                NSDate *endDate = [iDevicesUtil getLastDateInYear:selectedDate];
                [self fillMonthOrYearDetails:selectedDate andEndDate:endDate isMonth:NO];
            }
        }
    } else {
        dashedLine.hidden = YES;
        headerViewHeightConstraint.constant = 0;
        headerView.hidden = YES;
    }
}

-(NSDate *)findMinDate:(NSArray *)dbArray
{
    NSArray *sortedArray = [dbArray sortedArrayUsingComparator:^NSComparisonResult(DBActivity *activity1, DBActivity *activity2) {
        NSDate *first = [activity1 date];
        NSDate *second = [activity2 date];
        return [first compare:second];
    }];
    
    for (DBActivity *activity in sortedArray)
    {
        if (([activity steps]>0 || [activity calories]>0 || [activity distance]>0) || ([activity sleep]>0 && [[activity segments] length]>0))
        {
            return [activity date];
        }
    }
    
    return nil;
}

- (CGFloat)getPercentageWithActual:(CGFloat)actual withGoals:(CGFloat)goals {
    CGFloat percentage = 0.0;
    percentage = actual / goals;
    return percentage * 100.0f;
}

- (NSString *)getcustomWeekString:(NSDate *)startDate andEndDate:(NSDate *)endDate {
    NSDateFormatter *df = [NSDateFormatter new];
    [df setTimeZone:[NSTimeZone systemTimeZone]];
    [df setDateFormat:@"MMM-dd"];
    NSString *start = [df stringFromDate:startDate];
    
    NSString *customString = [NSString stringWithFormat:@"%@", start];
    return customString;
}

- (NSString *)getcustomMonthString:(NSDate *)startDate {
    NSDateFormatter *df = [NSDateFormatter new];
    [df setDateFormat:@"MMM"];
    NSString *start = [df stringFromDate:startDate];
    
    return start;
}
- (NSString *)getcustomYearString:(NSDate *)startDate {
    NSDateFormatter *df = [NSDateFormatter new];
    [df setDateFormat:@"yyyy"];
    NSString *start = [df stringFromDate:startDate];
    
    return start;
}

#pragma mark Setupchart
- (void)setUpChart {
    
    [self setupBarLineChartView:chartView];
    
    chartView.delegate = self;
    
    chartView.drawBarShadowEnabled = NO;
    chartView.drawValueAboveBarEnabled = NO;
    chartView.autoScaleMinMaxEnabled = YES;
    chartView.drawBordersEnabled = YES;
    chartView.borderLineWidth = 0.5;
    
    ChartXAxis *xAxis = chartView.xAxis;
    xAxis.labelPosition = XAxisLabelPositionBottom;
    xAxis.labelFont = [UIFont fontWithName:[iDevicesUtil getAppWideFontName] size:10];
    xAxis.drawGridLinesEnabled = NO;
    xAxis.drawAxisLineEnabled = NO;
    xAxis.labelWidth = 10;
    xAxis.valueFormatter = self;
    
    ChartYAxis *leftAxis = chartView.leftAxis;
    leftAxis.labelFont = [UIFont fontWithName:[iDevicesUtil getAppWideFontName] size:10];
    NSNumberFormatter *numberFormat = [[NSNumberFormatter alloc] init];
    numberFormat.minimumFractionDigits = 0;
    if (_selectedRow == 1) {
        numberFormat.maximumFractionDigits = 1;
    } else {
        numberFormat.maximumFractionDigits = 0;
    }
    numberFormat.roundingMode = NSNumberFormatterRoundCeiling;
    numberFormat.zeroSymbol = NSLocalizedString(@"0", nil);
    leftAxis.valueFormatter = [[ChartDefaultAxisValueFormatter alloc] initWithFormatter:numberFormat];
    /*if (_selectedRow == 1) {
        leftAxis.valueFormatter.positiveSuffix = [iDevicesUtil isMetricSystem]?NSLocalizedString(@"k", nil):NSLocalizedString(@"mi", nil);
    } else if (_selectedRow == 2) {
        leftAxis.valueFormatter.positiveSuffix = (![iDevicesUtil isMetricSystem])?NSLocalizedString(@"Cal", nil):NSLocalizedString(@"kcal", nil);
    } else {
        leftAxis.valueFormatter.positiveSuffix = nil;
    }*/
    leftAxis.labelPosition = YAxisLabelPositionOutsideChart;
    leftAxis.spaceTop = 0.15;
    leftAxis.axisMinValue = 0.0; // this replaces startAtZero = YES
    if (_selectedRow == 1) {
        NSInteger max = [self getHighestValue];
        if (max < 11) {
            leftAxis.axisMaxValue = max;
            leftAxis.labelCount = max;
        } else {
            leftAxis.axisMaxValue = max;
            leftAxis.labelCount = 11;
        }
    } else {
        leftAxis.axisMaxValue = [self getHighestValue];
        leftAxis.labelCount = 11;
    }
    leftAxis.granularityEnabled = true;
    
    ChartYAxis *rightAxis = chartView.rightAxis;
    rightAxis.enabled = NO;
    rightAxis.drawGridLinesEnabled = NO;
    rightAxis.spaceTop = 0.15;
    
}

- (NSInteger)getHighestValue {
    NSInteger value;
    if (_segmentedindex == 2) { //  weekly goal (daily goal x 7) cloned from artf26851
        limit = goal_dbl * 7;
    } else {
        limit = goal_dbl;
    }
    value = ceil(limit);
    NSArray *values = [yValues copy];
    NSSortDescriptor* sortOrder = [NSSortDescriptor sortDescriptorWithKey: @"self"
                                                                ascending: NO];
    values = [values sortedArrayUsingDescriptors: [NSArray arrayWithObject: sortOrder]];
    
    if (values.count > 0) {
        value = ceil([[values objectAtIndex:0] doubleValue]);
    }
    
    if (value < 11) {
        if (_selectedRow == 1) {
            if (value == 0) {
                return 3;
            }
            return value;
        }
        value = 11;
    }
    
    int n = value*(1.25);
    
    if (_segmentedindex != 0  && n < limit)
    {
        n = limit*1.25;
    }
    return n;
}

- (void)setupBarLineChartView:(BarLineChartViewBase *)chartView_ {
    chartView_.descriptionText = @"";
    chartView_.noDataText = @"You need to provide data for the chart.";
    chartView_.drawGridBackgroundEnabled = NO;
    
    chartView_.dragEnabled = YES;
    chartView_.userInteractionEnabled = YES;
    
    [chartView_ setScaleEnabled:NO];
    
    ChartXAxis *xAxis = chartView_.xAxis;
    xAxis.labelPosition = XAxisLabelPositionBottom;
    
    chartView_.rightAxis.enabled = NO;
    ChartYAxis *leftAxis = chartView_.leftAxis;
    leftAxis.forceLabelsEnabled = YES;
    leftAxis.axisMinValue = 0.0; // this replaces startAtZero = YES
    if (_selectedRow == 1) {
        NSInteger max = [self getHighestValue];
        if (max < 11) {
            leftAxis.axisMaxValue = max;
            leftAxis.labelCount = max;
        } else {
            leftAxis.axisMaxValue = max;
            leftAxis.labelCount = 11;
        }
    } else {
        leftAxis.axisMaxValue = [self getHighestValue];
        leftAxis.labelCount = 11;
    }
    leftAxis.labelFont = [UIFont fontWithName:[iDevicesUtil getAppWideFontName] size:10];
    [chartView setVisibleXRangeWithMinXRange:7 maxXRange:7];
    [chartView notifyDataSetChanged];
    [chartView setNeedsDisplay];
    _dashedLeftConstraint.constant = chartView.centerOffsets.x - (CGFloat)0.5; // 0.5 is dashedLineWidth/2
    dashedLineBottomConstraint.constant = (chartView.frame.size.height - (chartView.centerOffsets.y * 2))+10;
}

#pragma mark Header updation
- (void)fillHourDetails:(NSDate *)selectedDate {
    NSDate *onlyDate = [iDevicesUtil onlyDateFormat:selectedDate];
    NSNumber *hour = [iDevicesUtil getHourFromDate:selectedDate];
    
    NSDictionary *ref1 = [self getRecordForTheDate:onlyDate andTime:[NSString stringWithFormat:@"%i",hour.intValue]];
    double miles = 0;
    double km = 0;
    NSString *steps = NSLocalizedString(@"0", nil);
    int calories = 0;
    if (ref1.allKeys.count) {
        km = [ref1[@"distance"] floatValue];
        miles = [iDevicesUtil convertKilometersToMiles:km];
        steps = [ref1[@"steps"] stringValue];
        calories = [ref1[@"calories"] intValue];
    }
    NSString *time = [iDevicesUtil getTimeFromHrValue:hour.intValue formatInNewLine:NO];
    if (_selectedRow == 0) {
        if([iDevicesUtil compareDateOnly:selectedDate AndEndDate:[iDevicesUtil yesterdayDateAtMidnight]] == NSOrderedSame) {
            _middleLabel.attributedText = [self getAttributedStrWithText:[NSString stringWithFormat:@"%@ - %@\n", NSLocalizedString(@"YESTERDAY", nil),time] formatStr:steps tagStr:nil];
        } else if([iDevicesUtil compareDateOnly:selectedDate AndEndDate:[iDevicesUtil todayDateAtMidnight]] == NSOrderedSame) {
            _middleLabel.attributedText = [self getAttributedStrWithText:[NSString stringWithFormat:@"%@ - %@\n", NSLocalizedString(@"TODAY", nil),time] formatStr:steps tagStr:nil];
        } else {
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"MM/dd/yyyy"];
            NSString * formattedDateStr = [dateFormatter stringFromDate:selectedDate];
            _middleLabel.attributedText = [self getAttributedStrWithText:[NSString stringWithFormat:@"%@ - %@\n", formattedDateStr,time] formatStr:steps tagStr:nil];
        }
        _rightLabel.attributedText = [self getAttributedStrWithText2:[NSString stringWithFormat:@"\n%@\n", NSLocalizedString(@"CALORIES", nil)] formatStr:[NSString stringWithFormat:@"%d %@", calories, (![iDevicesUtil isMetricSystem])?NSLocalizedString(@"Cal", nil):NSLocalizedString(@"kcal", nil)]];
        _leftLabel.attributedText = [self getAttributedStrWithText2:[NSString stringWithFormat:@"\n%@\n", NSLocalizedString(@"DISTANCE", nil)] formatStr:[NSString stringWithFormat:@"%.2f %@",[iDevicesUtil isMetricSystem]?km:miles,[iDevicesUtil isMetricSystem]?NSLocalizedString(@"km", nil):NSLocalizedString(@"miles", nil)]];
    } else if (_selectedRow == 1) {
        if([iDevicesUtil compareDateOnly:selectedDate AndEndDate:[iDevicesUtil yesterdayDateAtMidnight]] == NSOrderedSame) {
            _middleLabel.attributedText = [self getAttributedStrWithText:[NSString stringWithFormat:@"%@ - %@\n", NSLocalizedString(@"YESTERDAY", nil),time] formatStr:[NSString stringWithFormat:@"%.2f",[iDevicesUtil isMetricSystem]?km:miles] tagStr:[iDevicesUtil isMetricSystem]?[NSString stringWithFormat:@"\n%@", NSLocalizedString(@"km", nil)]:[NSString stringWithFormat:@"\n%@", NSLocalizedString(@"miles", nil)]];
        } else if([iDevicesUtil compareDateOnly:selectedDate AndEndDate:[iDevicesUtil todayDateAtMidnight]] == NSOrderedSame) {
            _middleLabel.attributedText = [self getAttributedStrWithText:[NSString stringWithFormat:@"%@ - %@\n", NSLocalizedString(@"TODAY", nil),time] formatStr:[NSString stringWithFormat:@"%.2f",[iDevicesUtil isMetricSystem]?km:miles] tagStr:[iDevicesUtil isMetricSystem]?[NSString stringWithFormat:@"\n%@", NSLocalizedString(@"km", nil)]:[NSString stringWithFormat:@"\n%@", NSLocalizedString(@"miles", nil)]];
        } else {
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"MM/dd/yyyy"];
            NSString * formattedDateStr = [dateFormatter stringFromDate:selectedDate];
            _middleLabel.attributedText = [self getAttributedStrWithText:[NSString stringWithFormat:@"%@- %@\n", formattedDateStr,time] formatStr:[NSString stringWithFormat:@"%.2f",[iDevicesUtil isMetricSystem]?km:miles] tagStr:[iDevicesUtil isMetricSystem]?[NSString stringWithFormat:@"\n%@", NSLocalizedString(@"km", nil)]:[NSString stringWithFormat:@"\n%@", NSLocalizedString(@"miles", nil)]];
        }
        _rightLabel.attributedText = [self getAttributedStrWithText2:[NSString stringWithFormat:@"\n%@\n", NSLocalizedString(@"CALORIES", nil)] formatStr:[NSString stringWithFormat:@"%d %@",calories, (![iDevicesUtil isMetricSystem])?NSLocalizedString(@"Cal", nil):NSLocalizedString(@"kcal", nil)]];
        _leftLabel.attributedText = [self getAttributedStrWithText2:[NSString stringWithFormat:@"\n%@\n", NSLocalizedString(@"STEPS", nil)] formatStr:steps];
    } else if (_selectedRow == 2) {
        if([iDevicesUtil compareDateOnly:selectedDate AndEndDate:[iDevicesUtil yesterdayDateAtMidnight]] == NSOrderedSame) {
            _middleLabel.attributedText = [self getAttributedStrWithText:[NSString stringWithFormat:@"%@ - %@\n", NSLocalizedString(@"YESTERDAY", nil),time] formatStr:[NSString stringWithFormat:@"%d",calories] tagStr:[NSString stringWithFormat:@"\n%@", (![iDevicesUtil isMetricSystem])?NSLocalizedString(@"Cal", nil):NSLocalizedString(@"kcal", nil)]];
        } else if([iDevicesUtil compareDateOnly:selectedDate AndEndDate:[iDevicesUtil todayDateAtMidnight]] == NSOrderedSame) {
            _middleLabel.attributedText = [self getAttributedStrWithText:[NSString stringWithFormat:@"%@ - %@\n", NSLocalizedString(@"TODAY", nil),time] formatStr:[NSString stringWithFormat:@"%d",calories]tagStr:[NSString stringWithFormat:@"\n%@", (![iDevicesUtil isMetricSystem])?NSLocalizedString(@"Cal", nil):NSLocalizedString(@"kcal", nil)]];
        } else {
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"MM/dd/yyyy"];
            NSString * formattedDateStr = [dateFormatter stringFromDate:selectedDate];
            _middleLabel.attributedText = [self getAttributedStrWithText:[NSString stringWithFormat:@"%@ - %@\n", formattedDateStr,time] formatStr:[NSString stringWithFormat:@"%d",calories] tagStr:[NSString stringWithFormat:@"\n%@", (![iDevicesUtil isMetricSystem])?NSLocalizedString(@"Cal", nil):NSLocalizedString(@"kcal", nil)]];
        }
        _rightLabel.attributedText = [self getAttributedStrWithText2:[NSString stringWithFormat:@"\n%@\n", NSLocalizedString(@"DISTANCE", nil)] formatStr:[NSString stringWithFormat:@"%.2f %@",[iDevicesUtil isMetricSystem]?km:miles,[iDevicesUtil isMetricSystem]?NSLocalizedString(@"km", nil):NSLocalizedString(@"miles", nil)]];
        _leftLabel.attributedText = [self getAttributedStrWithText2:[NSString stringWithFormat:@"\n%@\n", NSLocalizedString(@"STEPS", nil)] formatStr:steps];
    }
    
}

- (void)fillDayDetails:(NSDate *)selectedDate {
    NSDictionary *ref1 = nil;
    ref1 = [self getRecordForTheDate:selectedDate];
    double miles = 0;
    double km = 0;
    NSString *steps = NSLocalizedString(@"0", nil);
    int calories = 0;
    if (ref1.allKeys.count) {
        km = [ref1[@"distance"] doubleValue];
        miles = [iDevicesUtil convertKilometersToMiles:km];
        steps = [ref1[@"steps"] stringValue];
        calories = [ref1[@"calories"] intValue];
    }
    if (_selectedRow == 0) {
        if([iDevicesUtil compareDateOnly:selectedDate AndEndDate:[iDevicesUtil yesterdayDateAtMidnight]] == NSOrderedSame) {
            _middleLabel.attributedText = [self getAttributedStrWithText:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"YESTERDAY", nil)] formatStr:steps tagStr:nil];
        } else if([iDevicesUtil compareDateOnly:selectedDate AndEndDate:[iDevicesUtil todayDateAtMidnight]] == NSOrderedSame) {
            _middleLabel.attributedText = [self getAttributedStrWithText:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"TODAY", nil)] formatStr:steps tagStr:nil];
        } else {
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"MM/dd/yyyy"];
            NSString * formattedDateStr = [dateFormatter stringFromDate:selectedDate];
            _middleLabel.attributedText = [self getAttributedStrWithText:[NSString stringWithFormat:@"%@\n", formattedDateStr] formatStr:steps tagStr:nil];
        }
        _rightLabel.attributedText = [self getAttributedStrWithText2:[NSString stringWithFormat:@"\n%@\n", NSLocalizedString(@"CALORIES", nil)] formatStr:[NSString stringWithFormat:@"%d %@",calories, (![iDevicesUtil isMetricSystem])?NSLocalizedString(@"Cal", nil):NSLocalizedString(@"kcal", nil)]];
        _leftLabel.attributedText = [self getAttributedStrWithText2:[NSString stringWithFormat:@"\n%@\n", NSLocalizedString(@"DISTANCE", nil)] formatStr:[NSString stringWithFormat:@"%.2f %@",[iDevicesUtil isMetricSystem]?km:miles,[iDevicesUtil isMetricSystem]?NSLocalizedString(@"km", nil):NSLocalizedString(@"miles", nil)]];
    } else if (_selectedRow == 1) {
        if([iDevicesUtil compareDateOnly:selectedDate AndEndDate:[iDevicesUtil yesterdayDateAtMidnight]] == NSOrderedSame) {
            _middleLabel.attributedText = [self getAttributedStrWithText:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"YESTERDAY", nil)] formatStr:[NSString stringWithFormat:@"%.2f",[iDevicesUtil isMetricSystem]?km:miles] tagStr:[iDevicesUtil isMetricSystem]?[NSString stringWithFormat:@"\n%@", NSLocalizedString(@"km", nil)]:[NSString stringWithFormat:@"\n%@", NSLocalizedString(@"miles", nil)]];
        } else if([iDevicesUtil compareDateOnly:selectedDate AndEndDate:[iDevicesUtil todayDateAtMidnight]] == NSOrderedSame) {
            _middleLabel.attributedText = [self getAttributedStrWithText:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"TODAY", nil)] formatStr:[NSString stringWithFormat:@"%.2f",[iDevicesUtil isMetricSystem]?km:miles] tagStr:[iDevicesUtil isMetricSystem]?[NSString stringWithFormat:@"\n%@", NSLocalizedString(@"km", nil)]:[NSString stringWithFormat:@"\n%@", NSLocalizedString(@"miles", nil)]];
        } else {
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"MM/dd/yyyy"];
            NSString * formattedDateStr = [dateFormatter stringFromDate:selectedDate];
            _middleLabel.attributedText = [self getAttributedStrWithText:[NSString stringWithFormat:@"%@\n", formattedDateStr] formatStr:[NSString stringWithFormat:@"%.2f",[iDevicesUtil isMetricSystem]?km:miles] tagStr:[iDevicesUtil isMetricSystem]?[NSString stringWithFormat:@"\n%@", NSLocalizedString(@"km", nil)]:[NSString stringWithFormat:@"\n%@", NSLocalizedString(@"miles", nil)]];
        }
        _rightLabel.attributedText = [self getAttributedStrWithText2:[NSString stringWithFormat:@"\n%@\n", NSLocalizedString(@"CALORIES", nil)] formatStr:[NSString stringWithFormat:@"%d %@",calories, (![iDevicesUtil isMetricSystem])?NSLocalizedString(@"Cal", nil):NSLocalizedString(@"kcal", nil)]];
        _leftLabel.attributedText = [self getAttributedStrWithText2:[NSString stringWithFormat:@"\n%@\n", NSLocalizedString(@"STEPS", nil)] formatStr:steps];
    } else if (_selectedRow == 2) {
        if([iDevicesUtil compareDateOnly:selectedDate AndEndDate:[iDevicesUtil yesterdayDateAtMidnight]] == NSOrderedSame) {
            _middleLabel.attributedText = [self getAttributedStrWithText:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"YESTERDAY", nil)] formatStr:[NSString stringWithFormat:@"%d",calories] tagStr:[NSString stringWithFormat:@"\n%@", (![iDevicesUtil isMetricSystem])?NSLocalizedString(@"Cal", nil):NSLocalizedString(@"kcal", nil)]];
        } else if([iDevicesUtil compareDateOnly:selectedDate AndEndDate:[iDevicesUtil todayDateAtMidnight]] == NSOrderedSame) {
            _middleLabel.attributedText = [self getAttributedStrWithText:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"TODAY", nil)] formatStr:[NSString stringWithFormat:@"%d",calories]tagStr:[NSString stringWithFormat:@"\n%@", (![iDevicesUtil isMetricSystem])?NSLocalizedString(@"Cal", nil):NSLocalizedString(@"kcal", nil)]];
        } else {
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"MM/dd/yyyy"];
            NSString * formattedDateStr = [dateFormatter stringFromDate:selectedDate];
            _middleLabel.attributedText = [self getAttributedStrWithText:[NSString stringWithFormat:@"%@\n", formattedDateStr] formatStr:[NSString stringWithFormat:@"%d",calories] tagStr:[NSString stringWithFormat:@"\n%@", (![iDevicesUtil isMetricSystem])?NSLocalizedString(@"Cal", nil):NSLocalizedString(@"kcal", nil)]];
        }
        _rightLabel.attributedText = [self getAttributedStrWithText2:[NSString stringWithFormat:@"\n%@\n", NSLocalizedString(@"DISTANCE", nil)] formatStr:[NSString stringWithFormat:@"%.2f %@",[iDevicesUtil isMetricSystem]?km:miles,[iDevicesUtil isMetricSystem]?NSLocalizedString(@"km", nil):NSLocalizedString(@"miles", nil)]];
        _leftLabel.attributedText = [self getAttributedStrWithText2:[NSString stringWithFormat:@"\n%@\n", NSLocalizedString(@"STEPS", nil)] formatStr:steps];
    }
    
}

- (void)fillWeekDetails:(NSDate *)selectedDate andEndDate:(NSDate *)endDate {
    NSDictionary *ref1 = [self getRecordsInBetween:selectedDate EndDate:endDate];
    double miles = 0;
    double km = 0;
    NSString *steps = NSLocalizedString(@"0", nil);
    int calories = 0;
    if (ref1.allKeys.count) {
        km = [ref1[@"distance"] doubleValue];
        miles = [iDevicesUtil convertKilometersToMiles:km];
        steps = [ref1[@"steps"] stringValue];
        calories = [ref1[@"calories"] intValue];
    }
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MMM dd yyyy"];
    [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
    
    NSString * formattedStartDateStr = [dateFormatter stringFromDate:selectedDate];
    NSString * formattedEndDateStr = [dateFormatter stringFromDate:endDate];
    
    NSDate *lastWeekStartDate = [[iDevicesUtil getWeekStartDate:[iDevicesUtil todayDateAtMidnight]] dateByAddingTimeInterval: -(7 * SECONDS_PER_DAY)];
    if (_selectedRow == 0) {
        if([iDevicesUtil compareDateOnly:[iDevicesUtil getWeekStartDate:[iDevicesUtil todayDateAtMidnight]] AndEndDate:selectedDate] == NSOrderedSame) {
            _middleLabel.attributedText = [self getAttributedStrWithText:[[NSString stringWithFormat:@"%@\n", NSLocalizedString([self getCamelCaseString:@"THIS WEEK"], nil)] uppercaseString] formatStr:steps tagStr:nil];
        } else if([iDevicesUtil compareDateOnly:lastWeekStartDate AndEndDate:selectedDate] == NSOrderedSame) {
            _middleLabel.attributedText = [self getAttributedStrWithText:[[NSString stringWithFormat:@"%@\n", NSLocalizedString([self getCamelCaseString:@"LAST WEEK"], nil)] uppercaseString] formatStr:steps tagStr:nil];
        } else {
            _middleLabel.attributedText = [self getAttributedStrWithText:[NSString stringWithFormat:@"%@ - %@\n", formattedStartDateStr, formattedEndDateStr] formatStr:steps tagStr:nil];
        }
        
        _rightLabel.attributedText = [self getAttributedStrWithText2:[NSString stringWithFormat:@"\n%@\n", NSLocalizedString(@"CALORIES", nil)] formatStr:[NSString stringWithFormat:@"%d %@",calories, (![iDevicesUtil isMetricSystem])?NSLocalizedString(@"Cal", nil):NSLocalizedString(@"kcal", nil)]];
        _leftLabel.attributedText = [self getAttributedStrWithText2:[NSString stringWithFormat:@"\n%@\n", NSLocalizedString(@"DISTANCE", nil)] formatStr:[NSString stringWithFormat:@"%.2f %@",[iDevicesUtil isMetricSystem]?km:miles,[iDevicesUtil isMetricSystem]?NSLocalizedString(@"km", nil):NSLocalizedString(@"miles", nil)]];
    } else if (_selectedRow == 1) {
        if([iDevicesUtil compareDateOnly:[iDevicesUtil getWeekStartDate:[iDevicesUtil todayDateAtMidnight]] AndEndDate:selectedDate] == NSOrderedSame) {
            _middleLabel.attributedText = [self getAttributedStrWithText:[[NSString stringWithFormat:@"%@\n", NSLocalizedString([self getCamelCaseString:@"THIS WEEK"], nil)] uppercaseString] formatStr:[NSString stringWithFormat:@"%.2f",[iDevicesUtil isMetricSystem]?km:miles] tagStr:[iDevicesUtil isMetricSystem]?[NSString stringWithFormat:@"\n%@", NSLocalizedString(@"km", nil)]:[NSString stringWithFormat:@"\n%@", NSLocalizedString(@"miles", nil)]];
        } else if([iDevicesUtil compareDateOnly:lastWeekStartDate AndEndDate:selectedDate] == NSOrderedSame) {
            _middleLabel.attributedText = [self getAttributedStrWithText:[[NSString stringWithFormat:@"%@\n", NSLocalizedString([self getCamelCaseString:@"LAST WEEK"], nil)] uppercaseString] formatStr:[NSString stringWithFormat:@"%.2f",[iDevicesUtil isMetricSystem]?km:miles] tagStr:[iDevicesUtil isMetricSystem]?[NSString stringWithFormat:@"\n%@", NSLocalizedString(@"km", nil)]:[NSString stringWithFormat:@"\n%@", NSLocalizedString(@"miles", nil)]];
        } else {
            _middleLabel.attributedText = [self getAttributedStrWithText:[NSString stringWithFormat:@"%@ - %@\n", formattedStartDateStr, formattedEndDateStr] formatStr:[NSString stringWithFormat:@"%.2f",[iDevicesUtil isMetricSystem]?km:miles] tagStr:[iDevicesUtil isMetricSystem]?[NSString stringWithFormat:@"\n%@", NSLocalizedString(@"km", nil)]:[NSString stringWithFormat:@"\n%@", NSLocalizedString(@"miles", nil)]];
        }
        
        _rightLabel.attributedText = [self getAttributedStrWithText2:[NSString stringWithFormat:@"\n%@\n", NSLocalizedString(@"CALORIES", nil)] formatStr:[NSString stringWithFormat:@"%d %@",calories, (![iDevicesUtil isMetricSystem])?NSLocalizedString(@"Cal", nil):NSLocalizedString(@"kcal", nil)]];
        _leftLabel.attributedText = [self getAttributedStrWithText2:[NSString stringWithFormat:@"\n%@\n", NSLocalizedString(@"STEPS", nil)] formatStr:steps];
    } else if (_selectedRow == 2) {
        if([iDevicesUtil compareDateOnly:[iDevicesUtil getWeekStartDate:[iDevicesUtil todayDateAtMidnight]] AndEndDate:selectedDate] == NSOrderedSame) {
            _middleLabel.attributedText = [self getAttributedStrWithText:[[NSString stringWithFormat:@"%@\n", NSLocalizedString([self getCamelCaseString:@"THIS WEEK"], nil)] uppercaseString] formatStr:[NSString stringWithFormat:@"%d",calories] tagStr:[NSString stringWithFormat:@"\n%@", (![iDevicesUtil isMetricSystem])?NSLocalizedString(@"Cal", nil):NSLocalizedString(@"kcal", nil)]];
        } else if([iDevicesUtil compareDateOnly:lastWeekStartDate AndEndDate:selectedDate] == NSOrderedSame) {
            _middleLabel.attributedText = [self getAttributedStrWithText:[[NSString stringWithFormat:@"%@\n", NSLocalizedString([self getCamelCaseString:@"LAST WEEK"], nil)] uppercaseString] formatStr:[NSString stringWithFormat:@"%d",calories] tagStr:[NSString stringWithFormat:@"\n%@", (![iDevicesUtil isMetricSystem])?NSLocalizedString(@"Cal", nil):NSLocalizedString(@"kcal", nil)]];
        } else {
            _middleLabel.attributedText = [self getAttributedStrWithText:[NSString stringWithFormat:@"%@ - %@\n", formattedStartDateStr, formattedEndDateStr] formatStr:[NSString stringWithFormat:@"%d",calories] tagStr:[NSString stringWithFormat:@"\n%@", (![iDevicesUtil isMetricSystem])?NSLocalizedString(@"Cal", nil):NSLocalizedString(@"kcal", nil)]];
        }
        
        _rightLabel.attributedText = [self getAttributedStrWithText2:[NSString stringWithFormat:@"\n%@\n", NSLocalizedString(@"DISTANCE", nil)] formatStr:[NSString stringWithFormat:@"%.2f %@",[iDevicesUtil isMetricSystem]?km:miles,[iDevicesUtil isMetricSystem]?NSLocalizedString(@"km", nil):NSLocalizedString(@"miles", nil)]];
        _leftLabel.attributedText = [self getAttributedStrWithText2:[NSString stringWithFormat:@"\n%@\n", NSLocalizedString(@"STEPS", nil)] formatStr:steps];
    }
}

-(void)fillMonthOrYearDetails:(NSDate *)selectedDate andEndDate:(NSDate *)endDate isMonth:(BOOL)isMonth {
    NSDictionary *ref1 = [self getRecordsInBetween:selectedDate EndDate:endDate];
    double miles = 0;
    double km = 0;
    NSString *steps = @"0";
    int calories = 0;
    if (ref1.allKeys.count) {
        km = [ref1[@"distance"] doubleValue];
        miles = [iDevicesUtil convertKilometersToMiles:km];
        steps = [ref1[@"steps"] stringValue];
        calories = [ref1[@"calories"] intValue];
    }
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    if(isMonth) {
        [dateFormatter setDateFormat:@"MMMM-yyyy"];
    } else {
        [dateFormatter setDateFormat:@"yyyy"];
    }
    [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
    NSString * formattedStartDateStr = [dateFormatter stringFromDate:selectedDate];
    if (isMonth) {
        if([iDevicesUtil compareDateOnly:[iDevicesUtil getFirstDateInMonth:[iDevicesUtil todayDateAtMidnight]] AndEndDate:selectedDate] == NSOrderedSame) {
            formattedStartDateStr = [NSLocalizedString([self getCamelCaseString:@"THIS MONTH"], nil) uppercaseString];
        } else if([iDevicesUtil compareDateOnly:[iDevicesUtil getFirstDateOfPreviousMonth:[iDevicesUtil todayDateAtMidnight]] AndEndDate:selectedDate] == NSOrderedSame) {
            formattedStartDateStr = [NSLocalizedString([self getCamelCaseString:@"LAST MONTH"], nil) uppercaseString];
        }
    } else {
        if([iDevicesUtil compareDateOnly:[iDevicesUtil getFirstDateInYear:[iDevicesUtil todayDateAtMidnight]] AndEndDate:selectedDate] == NSOrderedSame) {
            formattedStartDateStr = [NSLocalizedString([self getCamelCaseString:@"THIS YEAR"], nil) uppercaseString];
        } else if([iDevicesUtil compareDateOnly:[iDevicesUtil getFirstDateOfPreviousYear:[iDevicesUtil todayDateAtMidnight]] AndEndDate:selectedDate] == NSOrderedSame) {
            formattedStartDateStr = [NSLocalizedString([self getCamelCaseString:@"LAST YEAR"], nil) uppercaseString];
        }
    }
    
    
    if (_selectedRow == 0) {
        _middleLabel.attributedText = [self getAttributedStrWithText:[NSString stringWithFormat:@"%@\n", formattedStartDateStr] formatStr:steps tagStr:nil];
        _rightLabel.attributedText = [self getAttributedStrWithText2:[NSString stringWithFormat:@"\n%@\n", NSLocalizedString(@"CALORIES", nil)] formatStr:[NSString stringWithFormat:@"%d %@",calories, (![iDevicesUtil isMetricSystem])?NSLocalizedString(@"Cal", nil):NSLocalizedString(@"kcal", nil)]];
        _leftLabel.attributedText = [self getAttributedStrWithText2:[NSString stringWithFormat:@"\n%@\n", NSLocalizedString(@"DISTANCE", nil)] formatStr:[NSString stringWithFormat:@"%.2f %@",[iDevicesUtil isMetricSystem]?km:miles,[iDevicesUtil isMetricSystem]?NSLocalizedString(@"km", nil):NSLocalizedString(@"miles", nil)]];
    } else if (_selectedRow == 1) {
        _middleLabel.attributedText = [self getAttributedStrWithText:[NSString stringWithFormat:@"%@\n", formattedStartDateStr] formatStr:[NSString stringWithFormat:@"%.2f",[iDevicesUtil isMetricSystem]?km:miles] tagStr:[iDevicesUtil isMetricSystem]?[NSString stringWithFormat:@"\n%@", NSLocalizedString(@"km", nil)]:[NSString stringWithFormat:@"\n%@", NSLocalizedString(@"miles", nil)]];
        _rightLabel.attributedText = [self getAttributedStrWithText2:[NSString stringWithFormat:@"\n%@\n", NSLocalizedString(@"CALORIES", nil)] formatStr:[NSString stringWithFormat:@"%d %@",calories, (![iDevicesUtil isMetricSystem])?NSLocalizedString(@"Cal", nil):NSLocalizedString(@"kcal", nil)]];
        _leftLabel.attributedText = [self getAttributedStrWithText2:[NSString stringWithFormat:@"\n%@\n", NSLocalizedString(@"STEPS", nil)] formatStr:steps];
    } else if (_selectedRow == 2) {
        _middleLabel.attributedText = [self getAttributedStrWithText:[NSString stringWithFormat:@"%@\n", formattedStartDateStr] formatStr:[NSString stringWithFormat:@"%d",calories] tagStr:[NSString stringWithFormat:@"\n%@", (![iDevicesUtil isMetricSystem])?NSLocalizedString(@"Cal", nil):NSLocalizedString(@"kcal", nil)]];
        _rightLabel.attributedText = [self getAttributedStrWithText2:[NSString stringWithFormat:@"\n%@\n", NSLocalizedString(@"DISTANCE", nil)] formatStr:[NSString stringWithFormat:@"%.2f %@",[iDevicesUtil isMetricSystem]?km:miles,[iDevicesUtil isMetricSystem]?NSLocalizedString(@"km", nil):NSLocalizedString(@"miles", nil)]];
        _leftLabel.attributedText = [self getAttributedStrWithText2:[NSString stringWithFormat:@"\n%@\n", NSLocalizedString(@"STEPS", nil)] formatStr:steps];
    }
}

-(NSString *)getCamelCaseString:(NSString *)word
{
    NSMutableString *camelCaseString = [NSMutableString string];
    
    NSArray *words = [word componentsSeparatedByString:@" "];
    for (NSString *singleWord in words)
    {
        for (int i = 0; i<singleWord.length; i++)
        {
            NSString *ch = [singleWord substringWithRange:NSMakeRange(i, 1)];
            i == 0 ? [camelCaseString appendString:[ch uppercaseString]] : [camelCaseString appendString:[ch lowercaseString]];
        }
        
        if (![singleWord isEqualToString:[words lastObject]])
        {
            [camelCaseString appendString:@" "];
        }
    }
    
    return camelCaseString;
}
- (NSDictionary *)getRecordForTheDate:(NSDate *)start andTime:(NSString *)timeId {
    NSInteger totalSteps = 0;
    CGFloat activityDistance = 0.0;
    CGFloat totalCal = 0;
    NSDictionary *data = nil;
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(%K==%@) AND (timeID==%@)",@"date",start,[NSString stringWithFormat:@"%02i",timeId.intValue]];
    DBHourActivity *hourActivity = (DBHourActivity *)[[DBModule sharedInstance] getEntity:@"DBHourActivity" withPredicate:predicate];
    
    totalSteps = hourActivity.steps.integerValue;
    activityDistance = hourActivity.distance.integerValue;
    totalCal = hourActivity.calories.integerValue;
    
    activityDistance = activityDistance/100.0;
    totalCal = totalCal/10.0;
    
    //    activityDistance = [iDevicesUtil convertKilometersToMiles:activityDistance];
    
    data = @{
             @"steps":[NSNumber numberWithInteger:totalSteps],
             @"calories":[NSNumber numberWithInteger:totalCal],
             @"distance":[NSNumber numberWithDouble:activityDistance],
             };
    return data;
}

- (NSDictionary *)getRecordForTheDate:(NSDate *)start {
    NSInteger totalSteps = 0;
    CGFloat activityDistance = 0.0;
    CGFloat totalCal = 0;
    NSDictionary *data = nil;


    NSArray *activityArray = [[DBModule sharedInstance] getArrayFor:[NSPredicate predicateWithFormat: @"%K==%@",@"date",start] entityName:@"DBActivity"];

    
    for (DBActivity *activity in activityArray) {
        totalSteps += activity.steps.integerValue;
        activityDistance += activity.distance.integerValue;
        totalCal += activity.calories.integerValue;
    }
    activityDistance = activityDistance/100.0;
    totalCal = totalCal/10.0;
    
    data = @{
             @"steps":[NSNumber numberWithInteger:totalSteps],
             @"calories":[NSNumber numberWithInteger:totalCal],
             @"distance":[NSNumber numberWithFloat:activityDistance],
             };
    return data;
}

- (NSDictionary *)getRecordsInBetween:(NSDate *)start EndDate:(NSDate *)end {
    
    NSInteger totalSteps = 0;
    CGFloat activityDistance = 0.0;
    CGFloat totalCal = 0;
    NSDictionary *data = nil;
    
    start = [iDevicesUtil onlyDateFormat:start];
    end = [iDevicesUtil onlyDateFormat:end];
    NSArray *activityArray = [[DBModule sharedInstance] getArrayFor:[NSPredicate predicateWithFormat: @"(%K>=%@) AND (%K<=%@)",@"date",start,@"date",end] entityName:@"DBActivity"];
    
    for (DBActivity *activity in activityArray) {
        totalSteps += activity.steps.integerValue;
        activityDistance += activity.distance.integerValue;
        totalCal += activity.calories.integerValue;
    }
    activityDistance = activityDistance/100.0;
    totalCal = totalCal/10.0;
    
    data = @{
             @"steps":[NSNumber numberWithInteger:totalSteps],
             @"calories":[NSNumber numberWithInteger:totalCal],
             @"distance":[NSNumber numberWithFloat:activityDistance],
             };
    return data;
    
}



#pragma mark - ChartViewDelegate

- (void)chartValueSelected:(ChartViewBase *)chartView entry:(ChartDataEntry *)entry highlight:(ChartHighlight *)highlight
{
    
    if ([xValues objectAtIndex:entry.x] != nil && [[xValues objectAtIndex:entry.x] length] > 0) {
        if (_segmentedindex == 0) {
            
            NSDate *selectedDate = [datesArray objectAtIndex:entry.x];
            
            [self fillHourDetails:selectedDate];
            
        }
        else if (_segmentedindex == 1) {
            
            NSDate *selectedDate = [datesArray objectAtIndex:entry.x];
            
            [self fillDayDetails:selectedDate];
            
        }
        else if (_segmentedindex == 2) {
            
            NSDate *selectedDate = [datesArray objectAtIndex:entry.x];
            
            NSDate *endDate = [selectedDate dateByAddingTimeInterval:6*SECONDS_PER_DAY];
            
            [self fillWeekDetails:selectedDate andEndDate:endDate];
            
        }
        else if (_segmentedindex == 3) {
            
            NSDate *selectedDate = [datesArray objectAtIndex:entry.x];
            
            NSDate *endDate = [iDevicesUtil getLastDateInMonth:selectedDate];
            
            [self fillMonthOrYearDetails:selectedDate andEndDate:endDate isMonth:YES];
            
        }
        else if (_segmentedindex == 4) {
            
            NSDate *selectedDate = [datesArray objectAtIndex:entry.x];
            
            NSDate *endDate = [iDevicesUtil getLastDateInYear:selectedDate];
            
            [self fillMonthOrYearDetails:selectedDate andEndDate:endDate isMonth:NO];
        }
        
        highlightedIndex = entry.x;
        if (datesArray.count > highlightedIndex && [datesArray objectAtIndex:highlightedIndex] != nil && (_segmentedindex == 0 || _segmentedindex == 1)) {
            dateSelected = [iDevicesUtil onlyDateFormat:[datesArray objectAtIndex:highlightedIndex]];
        }
        //[chartView centerViewToAnimatedWithXValue:highlightedIndex yValue:0 axis:AxisDependencyLeft duration:0];
        _dashedLeftConstraint.constant = self->chartView.centerOffsets.x - (CGFloat)0.5; // 0.5 is dashedLineWidth/2
        dashedLineBottomConstraint.constant = (self->chartView.frame.size.height - (self->chartView.centerOffsets.y * 2))+10;
        [self->chartView moveViewToX:entry.x - 3.5];
    } else {
        if (xValues.count > 0 &&[xValues objectAtIndex:highlightedIndex] != nil && [[xValues objectAtIndex:highlightedIndex] length] > 0) {
            [self->chartView highlightValueWithX:highlightedIndex dataSetIndex:0 callDelegate:YES];
        }
    }
}

- (void)chartValueNothingSelected:(ChartViewBase * __nonnull)chartView_
{
    if (xValues.count > 0 &&[xValues objectAtIndex:highlightedIndex] != nil && [[xValues objectAtIndex:highlightedIndex] length] > 0) {
        [chartView highlightValueWithX:highlightedIndex dataSetIndex:0 callDelegate:YES];
    }
}

- (void)chartTranslated:(ChartViewBase * _Nonnull)_chartView dX:(CGFloat)dX dY:(CGFloat)dY {
    for(UIGestureRecognizer *gesture in chartView.gestureRecognizers) {
        if([gesture isKindOfClass:[UIPanGestureRecognizer class]]) {
            if (gesture.state == UIGestureRecognizerStateChanged) {
                panGestureStateChanged = YES;
            }
            if (gesture.state == UIGestureRecognizerStatePossible && panGestureStateChanged) {
                panGestureStateChanged = NO;
                ChartDataEntry *entry = [chartView getEntryByTouchPointWithPoint:chartView.center];
                if ([xValues objectAtIndex:entry.x] != nil && [[xValues objectAtIndex:entry.x] length] > 0) {
                    highlightedIndex = entry.x;
                }
                if (xValues.count > 0 &&[xValues objectAtIndex:highlightedIndex] != nil && [[xValues objectAtIndex:highlightedIndex] length] > 0) {
                    [chartView highlightValueWithX:highlightedIndex dataSetIndex:0 callDelegate:YES];
                }
                [chartView stopDeceleration];
            }
        }
    }
}

-(NSString *)stringForValue:(double)value axis:(ChartAxisBase *)axis {
    return xValues[(int)value % xValues.count];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextDidSaveNotification object:nil];
}

-(void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"SyncDataFinished" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

@end
