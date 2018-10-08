//
//  SleepHistoryViewController.m
//  Timex
//
//  Created by Aruna Kumari Yarra on 19/05/16.
//

#import "SleepHistoryViewController.h"
#import "iDevicesUtil.h"
#import "TDDefines.h"
//#import "Sleep.h"
#import "SleepHistoryTableViewCell.h"
#import "TDAppDelegate.h"
#import "SleepDetailsViewController.h"
#import <objc/runtime.h>
#import "CustomTabbar.h"
#import "TDM328WatchSettingsUserDefaults.h"
#import "TimexWatchDB.h"
#import "OTLogUtil.h"
#import "DBModule.h"
#import "DBSleepEvents.h"
#import "TDHomeViewController.h"
#import "UIImage+Tint.h"
#include <math.h>

#define kBorderWidth 1.0
#define kCornerRadius _dayButton.frame.size.height/2.0

/**
 *  Defines the number of entries that are added
 * to make scrolling easier for the graphs.
 * Currently its 3 because the maximum limit for
 * bars on screen is 7.
 */
#define ExtraRecords 3

@interface SleepHistoryViewController ()
{
    CustomTabbar *customTabbar;
    NSInteger segmentedindex;
//    NSDateFormatter *utilsDateFormatter; // Formatter to convert from storage to required and required to storage. Eg. 2016195
    /**
     *  Describes whether the pan gesture is active or not.
     */
    BOOL panGestureState;
    NSInteger highlightedIndex;
    
    NSMutableArray *xValues;
    NSMutableArray *yValues;
    NSMutableArray *datesArray;
    NSMutableDictionary *sleepDBChartDict;
    NSDate *dateSelected;
    
    IBOutlet UIView *limitLineView;
    IBOutlet NSLayoutConstraint *limitLineHeightConstraints;
    
    IBOutlet NSLayoutConstraint *limitLineLeftConstarint;
    IBOutlet NSLayoutConstraint *limitLineTopConstarint;
    double goal_dbl;

}
@end

@implementation SleepHistoryViewController
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
    OTLog(@"viewDidLoad sleepHistoryViewcontroller");
    panGestureState = NO; // Default state to be no.
    [backgroundImgView setImage:[[UIImage imageNamed: @"Charts_Sleep"] imageWithTint: UIColorFromRGB(M328_SLEEP_GRAPH_COLOR)]];
    noDataDescriptionLabl.hidden = YES;
    noDataDescriptionLabl.font = [UIFont fontWithName:[iDevicesUtil getAppWideMediumFontName] size:15];
    noDataDescriptionLabl.textColor = AppColorDarkGray;
    chatDisplayView.hidden = NO;
//    utilsDateFormatter = [[NSDateFormatter alloc]init];
//    utilsDateFormatter.dateFormat = @"YYYYDDD";
//    [utilsDateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))  {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    self.title = [NSLocalizedString(@"Sleep",nil) uppercaseString];
    NSDictionary * navBarTitleTextAttributes =  @{NSFontAttributeName : [UIFont fontWithName:[iDevicesUtil getAppWideBoldFontName] size:APP_HEADER_FONT_SIZE] };
    self.navigationController.navigationBar.titleTextAttributes = navBarTitleTextAttributes;
    
    UIButton *backBtn = [iDevicesUtil getBackButton];
    [backBtn addTarget:self action:@selector(backButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barBtn = [[UIBarButtonItem alloc] initWithCustomView:backBtn];
    self.navigationItem.leftBarButtonItem = barBtn;
    
    sleepTable.backgroundColor = UIColorFromRGB(COLOR_DEFAULT_TIMEX_WHITE);
    [sleepTable setSeparatorColor: UIColorFromRGB(COLOR_LIGHT_GRAY)];
    sleepTable.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, sleepTable.frame.size.width, 1)];
    
    headerView.backgroundColor = UIColorFromRGB(M328_TABLEVIEW_HEADER_GRAY_COLOR);
    
    [self segmentedControlCustomization];
    
    [self customizeChartsView];
    
    [self syncDone];
    
    // Add Notification Observers
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncDataFinished:) name:@"SyncDataFinished" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)appDidBecomeActive:(NSNotification *)notification {
    [self syncDataFinished:nil];
}
- (void)syncDone {
    [self setupDataSource];
    [self segmentDidChange:rangeSegments];
}

- (void)syncDataFinished:(NSNotification *)notification {
    [self syncDone];
    [self performSelector:@selector(customizeLimitLine) withObject:nil afterDelay:0.1];
}

//- (void)handleDataModelChange:(NSNotification *)notification {
//    NSLog(@"handleDataModelChange");
//    if ([[[notification userInfo] objectForKey:NSInsertedObjectsKey] count] > 0  || [[[notification userInfo] objectForKey:NSUpdatedObjectsKey] count] > 0) {
//        [self syncDone];
//    }
//}



- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated]; // Adding super method
    [self addCustomTabbar];
    [self setupDataSource];
    [sleepTable reloadData];
    // DB changes notification
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDataModelChange:) name:NSManagedObjectContextDidSaveNotification object:[[DBModule sharedInstance] managedObjectContext]];
}


#pragma mark
#pragma mark CustomTabbar
- (void)addCustomTabbar {
    customTabbar = [(TDAppDelegate *)[[UIApplication sharedApplication] delegate] customTabbar];
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
    
    tableViewBottomConstraint.constant = customTabbar.frame.size.height-30+5;
    [customTabbar updateLastLblText];
}

- (IBAction)segmentDidChange:(id)sender {
    segmentedindex = [sender selectedSegmentIndex];
    if (segmentedindex == 0) {
        [self reloadSleepTableData];
        sleepTable.hidden = NO;
        chatDisplayView.hidden = YES;
        if (sleepHistoryArray.count > 0) {
            [self performSelector:@selector(scrollAfterDelay) withObject:nil afterDelay:0.5];
        }
    } else {
        sleepTable.hidden = YES;
        chatDisplayView.hidden = NO;
        [self setUpChart]; // setup the chart .
        [self setDataCount]; // Change the data count first
        
        [self performSelector:@selector(customizeLimitLine) withObject:nil afterDelay:0.1];
    }
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
    
    if (segmentedindex == 1 || segmentedindex == 2) {
        if (xValues.count == 0) {
            [limitLineView setHidden:YES];
        } else {
            [limitLineView setHidden:NO];
        }
    } else {
        [limitLineView setHidden:YES];
    }
}


- (void)scrollAfterDelay {
    [sleepTable scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:[self getSelectedIndex]] atScrollPosition:UITableViewScrollPositionTop animated:YES];
}
#pragma  mark Button Actions
- (void) backButtonTapped {
    if (datesArray.count > highlightedIndex) {
        if ([datesArray objectAtIndex:highlightedIndex] != nil && segmentedindex == 1) {
            ((TDHomeViewController *)_caller).dateSelected = [datesArray objectAtIndex:highlightedIndex];
        }
    }
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning {
     OTLog([NSString stringWithFormat:@"Recived Memory Warning  in %@ ",NSStringFromClass([self class])]);
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)segmentedControlCustomization {
    // Segmented control with scrolling
    rangeSegments = [[HMSegmentedControl alloc] initWithSectionTitles:@[@"EVENTS", @"DAY", @"WEEK", @"MONTH", @"YEAR"]];
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

- (void)reloadSleepTableData {
    if (sleepHistoryArray.count == 0) {
        noDataDescriptionLabl.hidden = NO;
        chatDisplayView.hidden = YES;
    } else{
        noDataDescriptionLabl.hidden = YES;
        chatDisplayView.hidden = NO;
    }
    [sleepTable reloadData];
}


#pragma mark
#pragma mark UITableviewDelegate and Datasoruce
- (NSArray *)getOnlyValidEventsFromArray:(NSArray *)array {
    NSMutableArray *sleepEvents = [array mutableCopy];
    NSMutableArray *evtns = [[NSMutableArray alloc] init];
    for (DBSleepEvents *sleepEvent in sleepEvents) {
        if (sleepEvent.duration.doubleValue > 0 &&
            sleepEvent.segmentsByEvent != nil &&
            sleepEvent.segmentsByEvent.length > 0 &&
            [sleepEvent.eventValid boolValue] &&
            [self sameCharsInString:sleepEvent.segmentsByEvent] == NO) {
            [evtns addObject:sleepEvent];
        }
    }
    return evtns;
}


/**
 *  Validates if the sleep segment has only F in all of its data and returns YES or no
 *
 *  @param str sleep segment string
 *
 *  @return YES if it has all the same characters. NO if any of the characters is not F
 */
-(BOOL)sameCharsInString:(NSString *)str {
    if ([str length] == 0 ) return YES;
    int length = (int)[str length];
    return [[str stringByReplacingOccurrencesOfString:@"F" withString:@""] length] == length ? NO : YES;
}



- (void) setupDataSource {
    OTLog(@ "setupDataSource SleepHistoryViewController ");
    sleepDBChartDict = [NSMutableDictionary dictionary];
    sleepHistoryArray = [NSMutableArray new];

    NSArray *sleepDBArray = [[DBModule sharedInstance] getSortedArrayFor:@"DBSleepEvents" predicate:nil keyString:@"endDate" isAscending:NO];
    sleepDBArray = [self getOnlyValidEventsFromArray:sleepDBArray];
//    if (segmentedindex == 0) { // EVENTS
        if (sleepDBArray.count > 0) {
            int section = 0;
            [sleepHistoryArray addObject:[NSMutableArray array]]; //Adding first section
            
            for (int i = 0; i < sleepDBArray.count - 1; i++) {
                DBSleepEvents *firstObject = sleepDBArray[i];
                DBSleepEvents *secondObject = sleepDBArray[i+1];
                
                NSString *firstDate = [self getSleepDateInDayFormat:firstObject.date];
                NSString *secondDate = [self getSleepDateInDayFormat:secondObject.date];
                
                NSMutableArray *sectionArray = sleepHistoryArray[section];
                
                if (![sectionArray containsObject:firstObject]) {
                    [sectionArray addObject:firstObject];
                }
                if (!([firstDate compare:secondDate] == NSOrderedSame)) {
                    NSMutableArray *newSection = [NSMutableArray array];
                    [newSection addObject:secondObject];
                    [sleepHistoryArray addObject:newSection];
                    section++;
                }
            }
            // Adding last object to last section
            if (![sleepHistoryArray.lastObject containsObject:sleepDBArray.lastObject]) {
                [sleepHistoryArray.lastObject addObject:sleepDBArray.lastObject];
            }
            
            //Parse the data to get light and deep sleep to display in charts
            for (DBSleepEvents *sleepEvent in sleepDBArray) {
                double lightSleepInHrs = 0;
                double deepSleepInHrs = 0;
                double totalTimeInHrs = 0;
                if ([sleepDBChartDict objectForKey:sleepEvent.date] != nil) {
                    NSDictionary *dict = [sleepDBChartDict objectForKey:sleepEvent.date];
                    lightSleepInHrs = [[dict objectForKey:@"lightSleep"] doubleValue];
                    deepSleepInHrs = [[dict objectForKey:@"deepSleep"] doubleValue];
                    totalTimeInHrs = [[dict objectForKey:@"totalTime"] doubleValue];
                }
                double deepSleep = 0;
                double lightSleep = 0;
                for (int i=0; i < sleepEvent.segmentsByEvent.length; i++) {
                    NSString * newString = [sleepEvent.segmentsByEvent substringWithRange:NSMakeRange(i, 1)];
                    
                    if ([newString isEqualToString:M328_SLEEP_DEEP_STR]) {
                        deepSleep = deepSleep + 1;
                    } else if ([newString isEqualToString:M328_SLEEP_LIGHT_STR]) {
                        lightSleep = lightSleep +1;
                    }
                }
                lightSleepInHrs += (lightSleep*2)/MINUTES_PER_HOUR;
                deepSleepInHrs += (deepSleep*2)/MINUTES_PER_HOUR;
                totalTimeInHrs += [sleepEvent.duration doubleValue];
                
                NSDictionary *sleepChartRelatedDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:totalTimeInHrs],@"totalTime",[NSNumber numberWithDouble:lightSleepInHrs],@"lightSleep",[NSNumber numberWithDouble:deepSleepInHrs],@"deepSleep",sleepEvent.date,@"sleepDate", nil];
                [sleepDBChartDict setObject:sleepChartRelatedDict forKey:sleepEvent.date];
            }
            [self calculateAverageSleepForEachDayInArray:sleepDBArray];
        }
//    }
}

- (void) calculateAverageSleepForEachDayInArray:(NSArray *)sleepDBArray {
    NSArray *arr = [sleepDBChartDict allKeys];
    for (NSDate *date in arr) {
        NSArray *filtered = [sleepDBArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"%K==%@", @"date",date]];
        double totalTimeInHrs = 0;
        for (DBSleepEvents *sleepEvent in filtered) {
            totalTimeInHrs += [sleepEvent.duration doubleValue];
        }
        NSMutableDictionary *dict = [[sleepDBChartDict objectForKey:date] mutableCopy];
        [dict setObject:[NSNumber numberWithDouble:(totalTimeInHrs/filtered.count)] forKey:@"averageSleep"];
        [sleepDBChartDict setObject:dict forKey:date];
    }
}

- (NSInteger)getSelectedIndex {
    for (NSArray *array in sleepHistoryArray) {
        for (DBSleepEvents *sleepEvent in array) {
            if ([sleepEvent.date compare:dateSelected] == NSOrderedSame) {
                return [sleepHistoryArray indexOfObject:array];
            }
        }
    }
    return 0;
}
#pragma mark
#pragma mark TableView Delegate and Datasource methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [sleepHistoryArray count];
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (segmentedindex == 0) {
        DBSleepEvents * currentSleep = [[sleepHistoryArray objectAtIndex: section] objectAtIndex:0];
        return [[self getSleepDateInDayFormat:currentSleep.date] uppercaseString];
    }
    return @"";
}

- (NSString *)getSleepDateInDayFormat:(NSDate *)sleepDate {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"EEE MMM dd"];
    NSString *date = [formatter stringFromDate:sleepDate];
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.timeStyle = NSDateFormatterNoStyle;
    df.dateStyle = NSDateFormatterShortStyle;
    df.doesRelativeDateFormatting = YES;
    NSString *datestr = [df stringFromDate:sleepDate];
    if ([datestr caseInsensitiveCompare:NSLocalizedString(@"today", nil)] == NSOrderedSame || [datestr caseInsensitiveCompare:NSLocalizedString(@"yesterday", nil)] == NSOrderedSame) {
        date = datestr;
    }
    return date;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    if ([view isKindOfClass:[UITableViewHeaderFooterView class]]) {
        UITableViewHeaderFooterView *headerview = (UITableViewHeaderFooterView *)view;
        headerview.textLabel.font = [UIFont fontWithName: [iDevicesUtil getAppWideFontName] size: M328_MAIN_SCREEN_FONT_SIZE];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[sleepHistoryArray objectAtIndex: section] count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return M328_SLEEP_LIST_CELL_HEIGHT;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SleepHistoryTableViewCell * cell = NULL;
    cell = (SleepHistoryTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"cell"];
    
    if (!cell) {
        [tableView registerNib:[UINib nibWithNibName:@"SleepHistoryTableViewCell" bundle:nil] forCellReuseIdentifier:@"cell"];
        cell = (SleepHistoryTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"cell"];
    }
    
    cell.progessView.hidden = YES;
    
    NSDateFormatter *timeFormatter = [[NSDateFormatter alloc] init];
    [timeFormatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];
    [timeFormatter setDateFormat:@"h:mm a"];
    
    NSDateFormatter *inputFormatter = [[NSDateFormatter alloc]init];
    [inputFormatter setDateFormat:@"YYYY-MM-DD/HH:mm:ss"];
    if (segmentedindex == 0) {
        /** Dictionary example output.
         Duration = "1.47";
         EndDate = "2016-07-11/20:56:00";
         EventValid = 1;
         SegmentsByEvent = CAAAAAAAAAABAAAAABAAACCAAABAAAABAAAAAAAAAABC;
         StartDate = "2016-07-11/19:28:00";
         TwoDaysEvent = 1;
         */
        DBSleepEvents * currentSleep = [[sleepHistoryArray objectAtIndex: indexPath.section] objectAtIndex:indexPath.row];
//        NSDate *startDate = [inputFormatter dateFromString:[currentSleep objectForKey:@"StartDate"]];
//        NSDate *endDate = [inputFormatter dateFromString:[currentSleep objectForKey:@"EndDate"]];
        cell.sleepDetailLbl.attributedText = [self getAttributedStrWithText:[iDevicesUtil convertMinutesToStringHHDecimalFormat:[currentSleep.duration doubleValue]*MINUTES_PER_HOUR] formatStr:[NSString stringWithFormat:@" %@  ", NSLocalizedString(@"hrs", nil)] highlightedFormatStr:[[NSString stringWithFormat:@"%@ - %@",[timeFormatter stringFromDate: currentSleep.startDate], [timeFormatter stringFromDate:currentSleep.endDate]] lowercaseString]];
        float floattime = [currentSleep.duration floatValue];
        
        if (floattime > 0) {
            cell.progessView.hidden = NO;
            if (currentSleep.segmentsByEvent.length > 0) {
                [cell executeSegments:currentSleep.segmentsByEvent andSide:TRUE hours:floattime];
            }
        } else {
            cell.progessView.hidden = YES;
        }
    }
    
    tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    cell.separatorInset = UIEdgeInsetsZero;
    cell.layoutMargins = UIEdgeInsetsZero;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
   
    OTLog(@"didSelectRowAtIndexPath SleepHistoryViewController");
    if (segmentedindex == 0) {
        DBSleepEvents * currentSleep = [[sleepHistoryArray objectAtIndex: indexPath.section] objectAtIndex:indexPath.row];
        SleepDetailsViewController *vc = [[SleepDetailsViewController alloc] initWithNibName:@"SleepDetailsViewController" bundle:nil workout:currentSleep sleepDetailsArray:[sleepHistoryArray copy] selectedRow:indexPath];
        [self.navigationController pushViewController:vc animated:YES];
        [vc setCaller:self];
    } else {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}
- (NSAttributedString *)getAttributedStrWithText:(NSString *)totalTime formatStr:(NSString *)hrsStr highlightedFormatStr:(NSString *)formatStr {
    
    UIFont *totalTimeFont = [UIFont fontWithName:[iDevicesUtil getAppWideFontName] size:M328_SLEEPHISTORY_SCREEN_TIME_FONT_SIZE];
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:totalTimeFont, NSFontAttributeName, [UIColor blackColor],NSForegroundColorAttributeName, nil];
    NSMutableAttributedString *totalAtrTime = [[NSMutableAttributedString alloc] initWithString:totalTime attributes:dict];
    
    UIFont *hrsFont = [UIFont fontWithName: [iDevicesUtil getAppWideFontName] size: M328_SLEEPHISTORY_SCREEN_HRS_FONT_SIZE];
    NSDictionary *atrsDict = [NSDictionary dictionaryWithObjectsAndKeys:hrsFont, NSFontAttributeName, UIColorFromRGB(COLOR_DEFAULT_TIMEX_FONT),NSForegroundColorAttributeName, nil];
    NSAttributedString *hrsAtrStr = [[NSAttributedString alloc] initWithString:hrsStr attributes:atrsDict];
    [totalAtrTime appendAttributedString:hrsAtrStr];
    
    UIFont *timeFormatFont = [UIFont fontWithName: [iDevicesUtil getAppWideFontName] size: M328_SLEEPHISTORY_SCREEN_FORMAT_FONT_SIZE];
    NSDictionary *highatrsDict = [NSDictionary dictionaryWithObjectsAndKeys:timeFormatFont, NSFontAttributeName, UIColorFromRGB(COLOR_DEFAULT_TIMEX_FONT),NSForegroundColorAttributeName, nil];
    NSAttributedString *formatAtrStr = [[NSAttributedString alloc] initWithString:formatStr attributes:highatrsDict];
    [totalAtrTime appendAttributedString:formatAtrStr];
    
    return totalAtrTime;
}

#pragma mark
#pragma mark Charts
- (void)customizeChartsView {
    NSDictionary *goalsDict = [[NSUserDefaults standardUserDefaults] valueForKey: [iDevicesUtil getGoalTypeStringFormat:(GoalType)[TDM328WatchSettingsUserDefaults goalType]]];
    limit = [[goalsDict objectForKey:SLEEPTIME] doubleValue];
    goal_dbl = limit;
    [self setUpChart];
}

- (void)setUpChart {
    [self setupBarLineChartView:chartView];
    
    chartView.delegate = self;
    //chartView.dragDecelerationEnabled = false;
    
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
    //xAxis.spaceBetweenLabels = 0.2;
    xAxis.labelWidth = 10;
    xAxis.valueFormatter = self;
    
    ChartYAxis *leftAxis = chartView.leftAxis;
    leftAxis.labelFont = [UIFont fontWithName:[iDevicesUtil getAppWideFontName] size:10];
    NSNumberFormatter *numberFormat = [[NSNumberFormatter alloc] init];
    numberFormat.minimumFractionDigits = 0;
    numberFormat.maximumFractionDigits = 0;
    numberFormat.roundingMode = NSNumberFormatterRoundCeiling;
    numberFormat.zeroSymbol = NSLocalizedString(@"0", nil);
    //leftAxis.valueFormatter = [[ChartDefaultAxisValueFormatter alloc] initWithFormatter:numberFormat];
    leftAxis.valueFormatter = [[ChartDefaultAxisValueFormatter alloc] initWithFormatter:numberFormat];
//    leftAxis.valueFormatter.positiveSuffix = NSLocalizedString(@"hrs", nil);
    leftAxis.labelPosition = YAxisLabelPositionOutsideChart;
    leftAxis.spaceTop = 0.15;
    leftAxis.axisMinValue = 0; // this replaces startAtZero = YES
    leftAxis.granularityEnabled = true;
    
    ChartYAxis *rightAxis = chartView.rightAxis;
    rightAxis.enabled = NO;
    rightAxis.drawGridLinesEnabled = NO;
    rightAxis.spaceTop = 0.15;
}

- (void)setDataCount {
    
    highlightedIndex = 0;
    NSMutableArray *histogramData = [[NSMutableArray alloc] init];
    
    // Need the days sorted to ensure the latest day comes first.
    NSArray *daysSorted = [[sleepDBChartDict allKeys] sortedArrayUsingComparator:^NSComparisonResult(NSString*  _Nonnull obj1, NSString*  _Nonnull obj2) {
        return [obj2 compare:obj1];
    }];
    NSDate *startDate = [daysSorted lastObject];
    NSDate *endDate = [daysSorted firstObject];
    NSDate *currentDate = [iDevicesUtil todayDateAtMidnight];
    
    if (startDate != nil && endDate != nil) {
        if (segmentedindex == 1) {
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
                if ([ref objectForKey:@"totalTime"] != nil) {
                    totalValue = [[ref objectForKey:@"totalTime"] doubleValue];
                }
                NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:dateToAdd,@"date",str,@"Xvalue",[NSNumber numberWithDouble:totalValue],@"Yvalue", nil];
                [histogramData addObject:dict];
            }
        } else if (segmentedindex == 2) {
            int noOfWeeks = (int)[iDevicesUtil getWeekCountBetweenDates:[iDevicesUtil getWeekStartDate:startDate] enddate:[iDevicesUtil getWeekEndDate:endDate]];
            
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
                
                if ([ref objectForKey:@"totalTime"] != nil) {
                    totalValue = [[ref objectForKey:@"totalTime"] doubleValue];
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
        } else if (segmentedindex == 3) {
            
            int noOfMonths = (int)[iDevicesUtil getMonthCountBetweenDates:[iDevicesUtil getFirstDateInMonth:startDate] enddate:[iDevicesUtil getLastDateInMonth:endDate]];
            
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
                if ([ref objectForKey:@"totalTime"] != nil) {
                    totalValue = [[ref objectForKey:@"totalTime"] doubleValue];
                }
                NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:monthStartDate,@"date",str,@"Xvalue",[NSNumber numberWithDouble:totalValue],@"Yvalue", nil];
                [histogramData addObject:dict];
                monthStartDate = [iDevicesUtil getFirstDateOfNextMonth:monthStartDate];
                monthEndDate = [iDevicesUtil getLastDateInMonth:monthStartDate];
                
            }
        } else if (segmentedindex == 4) {
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
                if ([ref objectForKey:@"totalTime"] != nil) {
                    totalValue = [[ref objectForKey:@"totalTime"] doubleValue];
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
        
        UIColor *color = UIColorFromRGB(M328_SLEEP_GRAPH_COLOR);
        [colorsArr addObject:color];
        color = UIColorFromRGB(M328_SLEEP_COLOR);
        [highlightColorsArr addObject:color];
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
            //        set1 = [[BarChartDataSet alloc] initWithYVals:yVals label:nil];
            set1 = [[BarChartDataSet alloc] initWithValues:yVals];
            //set1.barSpace = 0.7;
            set1.drawValuesEnabled = false;
            
            [set1 setColors:colorsArr];
            if (highlightColorsArr.count > 0) {
                [set1 setHighlightColor:highlightColorsArr[0]];
            }
            NSMutableArray *dataSets = [[NSMutableArray alloc] init];
            [dataSets addObject:set1];
            
            BarChartData *data = [[BarChartData alloc] initWithDataSet:set1];
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
        NSDate *date;
        if (dateSelected != nil) {
            if (segmentedindex == 1) {
                date = dateSelected;
            } else if (segmentedindex == 2) {
                date = [iDevicesUtil getWeekStartDate:dateSelected];
            } else if (segmentedindex == 3) {
                date = [iDevicesUtil getFirstDateInMonth:dateSelected];
            } else if (segmentedindex == 4) {
                date = [iDevicesUtil getFirstDateInYear:dateSelected];
            }
        }
        if (date != nil && [datesArray containsObject:date]) {
             highlightedIndex = [datesArray indexOfObject:date];
        } else {
            highlightedIndex = (int)(yVals.count-1)-ExtraRecords;
        }
//        for (int i = (int)(yVals.count-1); i >= 0; i--) {
//            BarChartDataEntry *data = [yVals objectAtIndex:i];
//            if (data.value > 0) {
//                highlightedIndex = i;
//                break;
//            }
//        }
    }
    chartView.legend.enabled = false;
    if (segmentedindex == 2) { //  weekly goal (daily goal x 7) cloned from artf26851
        limit = goal_dbl * 7;
    } else {
        limit = goal_dbl;
    }
    
    ChartLimitLine *limitline = [[ChartLimitLine alloc] initWithLimit:limit label:@""];
    limitline.labelPosition = ChartLimitLabelPositionRightBottom;
    limitline.lineWidth = 4;
    [limitline setLineColor:[UIColor clearColor]];
    [chartView.leftAxis addLimitLine:limitline];
    
    [self setupBarLineChartView:chartView];
    
    [chartView moveViewToX:xValues.count];
    
    [chartView animateWithXAxisDuration:0 yAxisDuration:0.5];
    
    if (xValues.count > 0 && [xValues objectAtIndex:highlightedIndex] != nil && [[xValues objectAtIndex:highlightedIndex] length] > 0) {
        [chartView highlightValueWithX:highlightedIndex dataSetIndex:0 callDelegate:YES];
    }
}

- (NSInteger)getHighestValue {
    if (segmentedindex == 2) { //  weekly goal (daily goal x 7) cloned from artf26851
        limit = goal_dbl * 7;
    } else {
        limit = goal_dbl;
    }
    NSInteger value = ceil(limit);
    NSArray *values = [yValues copy];
    NSSortDescriptor* sortOrder = [NSSortDescriptor sortDescriptorWithKey: @"self"
                                                                ascending: NO];
    values = [values sortedArrayUsingDescriptors: [NSArray arrayWithObject: sortOrder]];
    
    if ((segmentedindex == 1 || segmentedindex == 2)) {
        if (((values.count > 0)?([[values objectAtIndex:0] doubleValue]):0) > value) {
            value = (values.count > 0)?(ceil([[values objectAtIndex:0] doubleValue])):ceil(limit);
        }
    } else {
        if (values.count > 0) {
            value = ceil([[values objectAtIndex:0] doubleValue]);
        }
    }
    
    if (value <= ceil(limit) && (segmentedindex == 1 || segmentedindex == 2)) {
        value = ceil(limit);
    }
    if (value <= 9) {
        return value;
    }
    int n = (int)((value/9.0)*9);
    while (value > n) {
        n = n + 1;
    }
    return value;
}

- (void)setupBarLineChartView:(BarLineChartViewBase *)chartView_ {
    
    chartView_.descriptionText = @"";
    if (xValues.count == 0) {
        chartView_.data = nil;
        chartView_.noDataText = @"";
        noDataDescriptionLabl.hidden = NO;
        chatDisplayView.hidden = YES;
    } else {
        noDataDescriptionLabl.hidden = YES;
        chatDisplayView.hidden = NO;
    }
    chartView_.drawGridBackgroundEnabled = NO;
    
    chartView_.dragEnabled = YES;
    chartView_.userInteractionEnabled = YES;
    
    [chartView_ setScaleEnabled:NO];
    
    ChartXAxis *xAxis = chartView_.xAxis;
    xAxis.labelPosition = XAxisLabelPositionBottom;
    
    chartView_.rightAxis.enabled = NO;
    
    ChartYAxis *leftAxis = chartView_.leftAxis;
    leftAxis.forceLabelsEnabled = YES;
    leftAxis.axisMinValue = 0;
    NSInteger max = [self getHighestValue];
    leftAxis.axisMaxValue = max;
    if (max > 9) {
        leftAxis.labelCount = 9;
    } else {
        leftAxis.labelCount = max;
    }
    leftAxis.labelFont = [UIFont fontWithName:[iDevicesUtil getAppWideFontName] size:10];
    [chartView setVisibleXRangeWithMinXRange:7 maxXRange:7];
    [chartView notifyDataSetChanged];
    [chartView setNeedsDisplay];
    dashedLeftConstraint.constant = chartView.centerOffsets.x - (CGFloat)0.5; // 0.5 is dashedLineWidth/2
    dashedLineBottomConstraint.constant = (chartView.frame.size.height - (chartView.centerOffsets.y * 2))+10;
}


- (NSDictionary *)getRecordForTheDate: (NSDate *)date {
    OTLog(@"getRecordForTheDate ");
    if ([sleepDBChartDict objectForKey:date] != nil) {
        return [sleepDBChartDict objectForKey:date];
    }
    return nil;
}


- (NSDictionary *)getRecordsInBetween:(NSDate *)start EndDate:(NSDate *)end {
    OTLog([NSString stringWithFormat:@"getRecordsInBetween %@,%@",start,end]);
    NSArray *pr = [[sleepDBChartDict allKeys] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF >= %@ AND SELF <= %@",start,end]];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:start forKey:@"sleepDate"];
    double lightSleepInHrs = 0;
    double deepSleepInHrs = 0;
    double totalTimeInHrs = 0;
    double averageSleepInHrs = 0;
    for (NSString *dateStr in pr) {
        if ([sleepDBChartDict objectForKey:dateStr] != nil) {
            NSDictionary *dict = [sleepDBChartDict objectForKey:dateStr];
            lightSleepInHrs += [[dict objectForKey:@"lightSleep"] doubleValue];
            deepSleepInHrs += [[dict objectForKey:@"deepSleep"] doubleValue];
            totalTimeInHrs += [[dict objectForKey:@"totalTime"] doubleValue];
            averageSleepInHrs += [[dict objectForKey:@"averageSleep"] doubleValue];
        }
    }
    [dict setObject:[NSNumber numberWithDouble:totalTimeInHrs] forKey:@"totalTime"];
    [dict setObject:[NSNumber numberWithDouble:lightSleepInHrs] forKey:@"lightSleep"];
    [dict setObject:[NSNumber numberWithDouble:deepSleepInHrs] forKey:@"deepSleep"];
    [dict setObject:[NSNumber numberWithDouble:(averageSleepInHrs/pr.count)] forKey:@"averageSleep"];
    return dict;
}

- (CGFloat)getPercentageWithActual:(CGFloat)actual withGoals:(CGFloat)goals {
    CGFloat percentage = 0.0;
    percentage = actual / goals;
    return percentage * 100.0f;
}

- (NSString *)getcustomWeekString:(NSDate *)startDate andEndDate:(NSDate *)endDate {
    NSDateFormatter *df = [NSDateFormatter new];
//    [df setTimeZone:[NSTimeZone systemTimeZone]];
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

- (void)fillDayDetails:(NSDate *)selectedDate andEndDate:(NSDate *)endDate isWeek:(BOOL)isWeek isMonth:(BOOL)isMonth isYear:(BOOL)isYear {
    
    NSDictionary *ref1 = nil;
    float sleepAvgOfSevenRecords = 0;
    
    if (!isWeek && !isMonth && !isYear) {
        // Day
        ref1 = [self getRecordForTheDate:selectedDate];
        sleepAvgOfSevenRecords  = [self getAverageSleepForDaysOnDate:selectedDate];
    } else  {
        ref1 = [self getRecordsInBetween:selectedDate EndDate:endDate];
        
        if (isWeek)
            sleepAvgOfSevenRecords = [self getAverageSleepForWeeksOrMonthsOrYearsWithStartDate:selectedDate andEndDate:endDate isWeek:YES isMonth:NO isYear:NO];
        
        else if (isMonth)
            sleepAvgOfSevenRecords = [self getAverageSleepForWeeksOrMonthsOrYearsWithStartDate:selectedDate andEndDate:endDate isWeek:NO isMonth:YES isYear:NO];
        
        else if(isYear)
            sleepAvgOfSevenRecords = [self getAverageSleepForWeeksOrMonthsOrYearsWithStartDate:selectedDate andEndDate:endDate isWeek:NO isMonth:NO isYear:YES];
    }
    
    
    double lightSleep = [[ref1 objectForKey:@"lightSleep"] doubleValue] * MINUTES_PER_HOUR;
    double deepSleep = [[ref1 objectForKey:@"deepSleep"] doubleValue] * MINUTES_PER_HOUR;
    //double averageSleep = [[ref1 objectForKey:@"averageSleep"] doubleValue] * MINUTES_PER_HOUR;
    NSString * totalTime = [iDevicesUtil convertMinutesToStringHHDecimalFormat: [[ref1 objectForKey:@"totalTime"] doubleValue] * MINUTES_PER_HOUR];
    NSString * averageTimeStr = [iDevicesUtil convertMinutesToStringHHDecimalFormat:sleepAvgOfSevenRecords];
    double efficiency = (deepSleep+lightSleep)/([[ref1 objectForKey:@"totalTime"] doubleValue] * MINUTES_PER_HOUR) * 100;
    
    if (!isWeek && !isMonth && !isYear) { // Day
        if([iDevicesUtil compareDateOnly:selectedDate AndEndDate:[iDevicesUtil yesterdayDateAtMidnight]] == NSOrderedSame) {
            middleLabel.attributedText = [self getAttributedStrWithText:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"YESTERDAY", nil)] formatStr:totalTime hrsText:@"\nhrs"];
        } else if([iDevicesUtil compareDateOnly:selectedDate AndEndDate:[iDevicesUtil todayDateAtMidnight]] == NSOrderedSame) {
            middleLabel.attributedText = [self getAttributedStrWithText:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"TODAY", nil)] formatStr:totalTime  hrsText:@"\nhrs"];
        } else {
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"MM/dd/yyyy"];
            NSString * formattedDateStr = [dateFormatter stringFromDate:selectedDate];
            
            middleLabel.attributedText = [self getAttributedStrWithText:[NSString stringWithFormat:@"%@\n", formattedDateStr] formatStr:totalTime  hrsText:@"\nhrs"];
        }
    } else if (isWeek) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"MMM dd yyyy"];
        [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];

        NSString * formattedStartDateStr = [dateFormatter stringFromDate:selectedDate];
        NSString * formattedEndDateStr = [dateFormatter stringFromDate:endDate];
        NSDate *lastWeekStartDate = [[iDevicesUtil getWeekStartDate:[iDevicesUtil todayDateAtMidnight]] dateByAddingTimeInterval: -(7 * SECONDS_PER_DAY)];
        if([iDevicesUtil compareDateOnly:[iDevicesUtil getWeekStartDate:[iDevicesUtil todayDateAtMidnight]] AndEndDate:selectedDate] == NSOrderedSame) {
            middleLabel.attributedText = [self getAttributedStrWithText:[[NSString stringWithFormat:@"%@\n", NSLocalizedString([self getCamelCaseString:@"THIS WEEK"], nil)] uppercaseString] formatStr:totalTime  hrsText:@"\nhrs"];
        } else if([iDevicesUtil compareDateOnly:lastWeekStartDate AndEndDate:selectedDate] == NSOrderedSame) {
            middleLabel.attributedText = [self getAttributedStrWithText:[[NSString stringWithFormat:@"%@\n", NSLocalizedString([self getCamelCaseString:@"LAST WEEK"], nil)] uppercaseString] formatStr:totalTime  hrsText:@"\nhrs"];
        } else {
            middleLabel.attributedText = [self getAttributedStrWithText:[NSString stringWithFormat:@"%@ - %@\n", formattedStartDateStr, formattedEndDateStr] formatStr:totalTime  hrsText:@"\nhrs"];
        }
    } else if (isMonth) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"MMM yyyy"];
        NSString * formattedStartDateStr = [dateFormatter stringFromDate:selectedDate];
        if([iDevicesUtil compareDateOnly:[iDevicesUtil getFirstDateInMonth:[iDevicesUtil todayDateAtMidnight]] AndEndDate:selectedDate] == NSOrderedSame) {
            formattedStartDateStr = [NSLocalizedString([self getCamelCaseString:@"THIS MONTH"], nil) uppercaseString];
        } else if([iDevicesUtil compareDateOnly:[iDevicesUtil getFirstDateOfPreviousMonth:[iDevicesUtil todayDateAtMidnight]] AndEndDate:selectedDate] == NSOrderedSame) {
            formattedStartDateStr = [NSLocalizedString([self getCamelCaseString:@"LAST MONTH"], nil) uppercaseString];
        }
        middleLabel.attributedText = [self getAttributedStrWithText:[NSString stringWithFormat:@"%@\n", formattedStartDateStr] formatStr:totalTime  hrsText:@"\nhrs"];
    } else {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy"];
        NSString * formattedStartDateStr = [dateFormatter stringFromDate:selectedDate];
        if([iDevicesUtil compareDateOnly:[iDevicesUtil getFirstDateInYear:[iDevicesUtil todayDateAtMidnight]] AndEndDate:selectedDate] == NSOrderedSame) {
            formattedStartDateStr = [NSLocalizedString([self getCamelCaseString:@"THIS YEAR"], nil) uppercaseString];
        } else if([iDevicesUtil compareDateOnly:[iDevicesUtil getFirstDateOfPreviousYear:[iDevicesUtil todayDateAtMidnight]] AndEndDate:selectedDate] == NSOrderedSame) {
            formattedStartDateStr = [NSLocalizedString([self getCamelCaseString:@"LAST YEAR"], nil) uppercaseString];
        }
        middleLabel.attributedText = [self getAttributedStrWithText:[NSString stringWithFormat:@"%@\n", formattedStartDateStr] formatStr:totalTime  hrsText:@"\nhrs"];
    }
    
    rightLabel.attributedText = [self getAttributedStrWithText2:[NSString stringWithFormat:@"\n%@\n", NSLocalizedString(@"AVERAGE", nil)] formatStr:averageTimeStr];
    
    leftLabel.attributedText = [self getAttributedStrWithText2:[NSString stringWithFormat:@"\n%@\n", NSLocalizedString(@"EFFICIENCY", nil)] formatStr:[NSString stringWithFormat: @"%.1f %%", efficiency]];
    
    
}

-(float)getAverageSleepForDaysOnDate:(NSDate *)date
{
    int noOfRecords = 0;
    float sleepTotal = [[[self getRecordForTheDate:date] objectForKey:@"totalTime"] doubleValue] * MINUTES_PER_HOUR;
    
    if(sleepTotal > 0)
        noOfRecords++;
    
    for (int i = 1; i <= 3; i++)
    {
        NSDate *nextDate = [date dateByAddingTimeInterval:i*24*60*60];
        NSDictionary *dict = [self getRecordForTheDate:nextDate];
        if (dict != nil && !isnan([[dict objectForKey:@"totalTime"] doubleValue]) && [[dict objectForKey:@"totalTime"] doubleValue] > 0)
        {
            sleepTotal = sleepTotal + [[dict objectForKey:@"totalTime"] doubleValue] * MINUTES_PER_HOUR;
            noOfRecords++;
        }
        
        NSDate *previousDate = [date dateByAddingTimeInterval:-i*24*60*60];
        NSDictionary *dict2 = [self getRecordForTheDate:previousDate];
        if (dict2 != nil && !isnan([[dict2 objectForKey:@"totalTime"] doubleValue]) && [[dict2 objectForKey:@"totalTime"] doubleValue] > 0)
        {
            sleepTotal = sleepTotal + [[dict2 objectForKey:@"totalTime"] doubleValue] * MINUTES_PER_HOUR;
            noOfRecords++;
        }
    }
    
    float sleepAverage = 0;
    
    if (noOfRecords > 0) {
        sleepAverage = sleepTotal/noOfRecords;
    }
    
    return sleepAverage;
}


-(float)getAverageSleepForWeeksOrMonthsOrYearsWithStartDate:(NSDate *)startDate andEndDate:(NSDate *)endDate isWeek:(BOOL)isWeek isMonth:(BOOL)isMonth isYear:(BOOL)isYear
{
    int noOfRecords = 1;
    float sleepTotal = [[[self getRecordsInBetween:startDate EndDate:endDate] objectForKey:@"totalTime"] doubleValue] * MINUTES_PER_HOUR;
    
    for (int i = 1; i <= 3; i++)
    {
        NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
        
        if (isWeek)
            [dateComponents setDay:i*7];
        else if (isMonth)
            [dateComponents setMonth:i];
        else if(isYear)
            [dateComponents setYear:i];
        
        NSCalendar *nextcalendar = [NSCalendar currentCalendar];
        
        NSDate *nextStartDate = [nextcalendar dateByAddingComponents:dateComponents toDate:startDate options:0];
        NSDate *nextEndDate = [nextcalendar dateByAddingComponents:dateComponents toDate:endDate options:0];
        NSDictionary *dict = [self getRecordsInBetween:nextStartDate EndDate:nextEndDate];
        if (dict != nil && !isnan([[dict objectForKey:@"totalTime"] doubleValue]) && [[dict objectForKey:@"totalTime"] doubleValue] > 0)
        {
            sleepTotal = sleepTotal + [[dict objectForKey:@"totalTime"] doubleValue] * MINUTES_PER_HOUR;
            noOfRecords++;
        }
        
        NSDateComponents *dateComponents2 = [[NSDateComponents alloc] init];
        if (isWeek)
            [dateComponents2 setDay:-i*7];
        else if (isMonth)
            [dateComponents2 setMonth:-i];
        else if(isYear)
            [dateComponents2 setYear:-i];
        
        NSCalendar *prevcalendar = [NSCalendar currentCalendar];
        
        NSDate *prevStartDate = [prevcalendar dateByAddingComponents:dateComponents2 toDate:startDate options:0];
        NSDate *prevEndDate = [prevcalendar dateByAddingComponents:dateComponents2 toDate:endDate options:0];
        NSDictionary *dict2 = [self getRecordsInBetween:prevStartDate EndDate:prevEndDate];
        if (dict2 != nil && !isnan([[dict2 objectForKey:@"totalTime"] doubleValue]) && [[dict2 objectForKey:@"totalTime"] doubleValue] > 0)
        {
            sleepTotal = sleepTotal + [[dict2 objectForKey:@"totalTime"] doubleValue] * MINUTES_PER_HOUR;
            noOfRecords++;
        }
    }
    
    float sleepAverage = sleepTotal/noOfRecords;
    
    return sleepAverage;
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

// Shall we move these to utils??
// TODO
- (NSAttributedString *)getAttributedStrWithText:(NSString *)firstText formatStr:(NSString *)formattext hrsText:(NSString *)hrsText {
    
    UIFont *maxCalDayFont = [UIFont fontWithName:[iDevicesUtil getAppWideMediumFontName] size:M328_SLEEP_DETAILS_CELL_TITLE_FONT_SIZE];
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:maxCalDayFont, NSFontAttributeName, AppColorLightGray,NSForegroundColorAttributeName, nil];
    NSMutableAttributedString *totalAtrTime = [[NSMutableAttributedString alloc] initWithString:firstText attributes:dict];
    
    UIFont *maxCalFont = [UIFont fontWithName:[iDevicesUtil getAppWideMediumFontName] size:M328_STEPS_SCREEN_STEPS_FONT_SIZE];
    NSDictionary *dict2 = [NSDictionary dictionaryWithObjectsAndKeys:maxCalFont, NSFontAttributeName, [UIColor blackColor],NSForegroundColorAttributeName, nil];
    NSMutableAttributedString *totalAtrTime2 = [[NSMutableAttributedString alloc] initWithString:formattext attributes:dict2];
    
    [totalAtrTime appendAttributedString:totalAtrTime2];
    
    if (hrsText != nil && hrsText.length > 0) {
        [totalAtrTime appendAttributedString:[[NSAttributedString alloc] initWithString:hrsText attributes:dict]];
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


#pragma mark - ChartViewDelegate
- (void)chartValueSelected:(ChartViewBase *)chartView entry:(ChartDataEntry *)entry highlight:(ChartHighlight *)highlight
{
    if ([xValues objectAtIndex:entry.x] != nil && [[xValues objectAtIndex:entry.x] length] > 0) {
        if (segmentedindex == 1) {
            
            NSDate *selectedDate = [datesArray objectAtIndex:entry.x];
            
            [self fillDayDetails:selectedDate andEndDate:nil isWeek:NO isMonth:NO isYear:NO];
        } else if (segmentedindex == 2) {
            NSDate *selectedDate = [datesArray objectAtIndex:entry.x];
            
            NSDate *endDate = [selectedDate dateByAddingTimeInterval:6*SECONDS_PER_DAY];
            
            [self fillDayDetails:selectedDate andEndDate:endDate isWeek:YES isMonth:NO isYear:NO];
        } else if (segmentedindex == 3) {
            NSDate *selectedDate = [datesArray objectAtIndex:entry.x];
            
            NSDate *endDate = [iDevicesUtil getLastDateInMonth:selectedDate];
            
            [self fillDayDetails:selectedDate andEndDate:endDate isWeek:NO isMonth:YES isYear:NO];
        } else if (segmentedindex == 4) {
            
            NSDate *selectedDate = [datesArray objectAtIndex:entry.x];
            
            NSDate *endDate = [iDevicesUtil getLastDateInYear:selectedDate];
            
            [self fillDayDetails:selectedDate andEndDate:endDate isWeek:NO isMonth:NO isYear:YES];
            
        }
        highlightedIndex = entry.x;
        
        //[chartView setCenter:CGPointMake(highlightedIndex, 0)];
        dashedLeftConstraint.constant = self->chartView.centerOffsets.x - (CGFloat)0.5; // 0.5 is dashedLineWidth/2
        dashedLineBottomConstraint.constant = (self->chartView.frame.size.height - (self->chartView.centerOffsets.y * 2))+10;
        [self->chartView moveViewToX:entry.x - 3.5];
    } else {
        if (xValues.count > 0 && [xValues objectAtIndex:highlightedIndex] != nil && [[xValues objectAtIndex:highlightedIndex] length] > 0) {
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
    
    OTLog(@"chartTranslated sleephistoryviewcontroller");
    for(UIGestureRecognizer *gesture in chartView.gestureRecognizers) {
        if([gesture isKindOfClass:[UIPanGestureRecognizer class]]) {
            if (gesture.state == UIGestureRecognizerStateChanged) {
                panGestureState = YES;
            }
            if (gesture.state == UIGestureRecognizerStatePossible && panGestureState) {
                panGestureState = NO;
                ChartDataEntry *entry = [chartView getEntryByTouchPointWithPoint:chartView.center];
                if ([xValues objectAtIndex:entry.x] != nil && [[xValues objectAtIndex:entry.x] length] > 0) {
                    highlightedIndex = entry.x;
                }
                if (xValues.count > 0 && [xValues objectAtIndex:highlightedIndex] != nil && [[xValues objectAtIndex:highlightedIndex] length] > 0) {
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


/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
