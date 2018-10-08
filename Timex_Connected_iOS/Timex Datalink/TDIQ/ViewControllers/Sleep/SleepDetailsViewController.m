//
//  SleepDetailsViewController.m
//  Timex
//
//  Created by Aruna Kumari Yarra on 20/05/16.
//

#import "SleepDetailsViewController.h"
#import "TDDefines.h"
#import "iDevicesUtil.h"
#import "SleepDetailHeaderView.h"
#import "TDAppDelegate.h"
#import "CustomTabbar.h"
#import "TDM328WatchSettingsUserDefaults.h"
#import "SleepHistoryViewController.h"
#import "OTLogUtil.h"
#import "DBModule.h"
#import "DBActivity+CoreDataClass.h"
#import "EditSleepEventsViewController.h"

@interface SleepDetailsViewController (){
    NSString *collectionViewReuseIdentifier;
    float awake;
    float mediumSleep;
    float deepSleep;
    float efficiency;
    
    int radiusSegment;
    int SegmentWidth;
    UIColor * choiceColor;
    CGFloat segementStart;
    CGFloat segementEnd;
    
    UIScrollView *scrollView;
    
    /// Array that stores the details of one particular entity of sleep
    NSMutableArray *collectionViewDetailsArray;
    
    CustomTabbar *customTabbar;
    NSInteger previousPage;
    
    UIButton *sleepPrevButton;
    UIButton *sleepNextButton;
    UIView *tableHeaderView;
}

@end

@implementation SleepDetailsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil workout: (DBSleepEvents *) sleep  sleepDetailsArray: (NSArray *) array selectedRow: (NSIndexPath *) selectedIndexPath {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        currentSleep = sleep;
        
        // Convert the initial double array
        NSMutableArray *tempArray = [@[]mutableCopy];
        int totalIndexCount  = 0;
        for (NSArray *sectionArray in array) {
            if([sectionArray count] !=0 ) {
                [tempArray addObjectsFromArray:sectionArray] ;
            }
            if([array indexOfObject:sectionArray] == selectedIndexPath.section) {
                selectedRow = totalIndexCount + selectedIndexPath.row;
            }
            totalIndexCount += [sectionArray count];
        }
        sleepDetailsArray = [NSArray arrayWithArray:tempArray];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))  {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    self.title = [NSLocalizedString(@"Sleep",nil) uppercaseString];
    NSDictionary * navBarTitleTextAttributes =  @{NSFontAttributeName : [UIFont fontWithName:[iDevicesUtil getAppWideBoldFontName] size:APP_HEADER_FONT_SIZE] };
    self.navigationController.navigationBar.titleTextAttributes = navBarTitleTextAttributes;
    
    self.view.backgroundColor = UIColorFromRGB(VERY_LIGHT_GRAY_COLOR);
    
    previousPage = 0;
    sleepDetailsArray = [[sleepDetailsArray reverseObjectEnumerator] allObjects];
    selectedRow = (sleepDetailsArray.count-1)-selectedRow;
    
    collectionViewDetailsArray = [[NSMutableArray alloc] init];
    
    sleepDetailsTableView.backgroundColor = [UIColor clearColor];
    collectionViewReuseIdentifier = @"CollectionViewCell";
    [sleepDetailsTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:collectionViewReuseIdentifier];
    sleepDetailsTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 1)];
    sleepDetailsTableView.separatorInset = UIEdgeInsetsZero;
    [sleepDetailsTableView setLayoutMargins:UIEdgeInsetsZero];
    
    
    timeLabel.font = [UIFont fontWithName:[iDevicesUtil getAppWideBoldFontName] size:M328_SLEEP_DETAILS_TABLE_TIME_FONT_SIZE];
    timeLabel.textAlignment = NSTextAlignmentCenter;
    timeLabel.backgroundColor = UIColorFromRGB(VERY_LIGHT_GRAY_COLOR);
    
    scrollView = nil;
    scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, M328_SLEEP_DETAILS_TABLE_HEADER_HEIGHT)];
    scrollView.pagingEnabled = YES;
    scrollView.delegate = self;
    scrollView.tag = 111;
    tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, M328_SLEEP_DETAILS_TABLE_HEADER_HEIGHT)];
    tableHeaderView.backgroundColor = [UIColor clearColor];
    [tableHeaderView addSubview:scrollView];
    CGFloat xval = 0.0;
    
    for (int i=0; i < sleepDetailsArray.count; i++) {
        SleepDetailHeaderView *sleepHeaderView1 = [[SleepDetailHeaderView alloc] initWithFrame:CGRectMake((ScreenWidth-M328_SLEEP_DETAILS_TABLE_HEADER_WIDTH)/2, 0, M328_SLEEP_DETAILS_TABLE_HEADER_WIDTH, M328_SLEEP_DETAILS_TABLE_HEADER_HEIGHT)];
        sleepHeaderView1.backgroundColor = [UIColor clearColor];
        UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(xval, 0, ScreenWidth , M328_SLEEP_DETAILS_TABLE_HEADER_HEIGHT)];
        headerView.backgroundColor = UIColorFromRGB(VERY_LIGHT_GRAY_COLOR);
        
        [headerView addSubview:sleepHeaderView1];
        [scrollView addSubview:headerView];
        xval = xval + ScreenWidth;
    }
    
    scrollView.contentSize = CGSizeMake(xval, M328_SLEEP_DETAILS_TABLE_HEADER_HEIGHT);
    sleepDetailsTableView.tableHeaderView = tableHeaderView;
    [sleepDetailsTableView reloadData];

    [self addNextorPreviousSleepBtns];
    
    UIButton *backBtn = [iDevicesUtil getBackButton];
    [backBtn addTarget:self action:@selector(backButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barBtn = [[UIBarButtonItem alloc] initWithCustomView:backBtn];
    self.navigationItem.leftBarButtonItem = barBtn;
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setImage:[UIImage imageNamed:@"SleepEditIcon"] forState:UIControlStateNormal];
    [btn setContentEdgeInsets:UIEdgeInsetsMake(0, 0, 0, -10)];
    btn.frame = CGRectMake(0, 0, 40, 40);
    [btn addTarget:self action:@selector(rightBarButtonTouched) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *updateBtn = [[UIBarButtonItem alloc] initWithCustomView:btn];
    self.navigationItem.rightBarButtonItem = updateBtn;
    
}
- (void)addNextorPreviousSleepBtns {
    sleepPrevButton = [UIButton buttonWithType:UIButtonTypeCustom];
    sleepPrevButton.frame = CGRectMake(10, M328_SLEEP_DETAILS_TABLE_HEADER_HEIGHT-40, 40, 40);
    [sleepPrevButton setImage:[UIImage imageNamed:@"leftarrow"] forState:UIControlStateNormal];
    [sleepPrevButton setContentEdgeInsets:UIEdgeInsetsMake(10, 10, 10, 10)];
    [sleepPrevButton addTarget:self action:@selector(sleepPrevTapped) forControlEvents:UIControlEventTouchUpInside];
    [tableHeaderView addSubview:sleepPrevButton];
    
    sleepNextButton = [UIButton buttonWithType:UIButtonTypeCustom];
    sleepNextButton.frame = CGRectMake(ScreenWidth - 50, M328_SLEEP_DETAILS_TABLE_HEADER_HEIGHT-40, 40, 40);
    [sleepNextButton setImage:[UIImage imageNamed:@"rightarrow"] forState:UIControlStateNormal];
    [sleepNextButton setContentEdgeInsets:UIEdgeInsetsMake(10, 10, 10, 10)];
    [sleepNextButton addTarget:self action:@selector(sleepNextTapped) forControlEvents:UIControlEventTouchUpInside];
    [tableHeaderView addSubview:sleepNextButton];
}
- (void)sleepPrevTapped {
    CGFloat xval = scrollView.contentOffset.x;
    [scrollView setContentOffset:CGPointMake(xval - ScreenWidth, scrollView.contentOffset.y) animated:YES];
}
- (void)sleepNextTapped {
    CGFloat xval = scrollView.contentOffset.x;
    [scrollView setContentOffset:CGPointMake(xval + ScreenWidth, scrollView.contentOffset.y) animated:YES];
}
- (void)initialLoad {
    NSArray *subviews = scrollView.subviews;
    for (int i = 0; i< subviews.count; i++) {
        if (i == selectedRow) {
            UIView *subv = subviews[i];
            SleepDetailHeaderView *sleepHeaderView1 = [subv.subviews firstObject];
            [sleepHeaderView1 layoutIfNeeded];
            currentSleep = [sleepDetailsArray objectAtIndex:i];
            [self executeSegments:currentSleep.segmentsByEvent andSide:true sleepHeaderView:sleepHeaderView1];
            [self fillDetails:sleepHeaderView1];
            OTLog(@"Draw Arc initialLoad");
            break;
        }
    }
    [sleepDetailsTableView reloadData];
}
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self addCustomTabbar];
    [self initialLoad];
    [scrollView setContentOffset:CGPointMake(selectedRow * ScreenWidth, scrollView.contentOffset.y) animated:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
//    if (selectedRow == 0) {
//        [self initialLoad];
//    }
//    scrollView.contentOffset = CGPointMake(selectedRow * ScreenWidth, M328_SLEEP_DETAILS_TABLE_HEADER_HEIGHT);
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
    
    tableViewBottomConstraint.constant = customTabbar.frame.size.height-30+5;
    [customTabbar updateLastLblText];
}

- (NSComparisonResult)compareDateOnly:(NSDate *)firstDate AndEndDate:(NSDate *)secondDate {
    if (firstDate != nil && secondDate != nil) {
        NSUInteger dateFlags = NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay;
        NSCalendar *gregorianCalendar = [NSCalendar currentCalendar];
        NSDateComponents *selfComponents = [gregorianCalendar components:dateFlags fromDate:firstDate];
        NSDate *selfDateOnly = [gregorianCalendar dateFromComponents:selfComponents];
        
        NSDateComponents *otherCompents = [gregorianCalendar components:dateFlags fromDate:secondDate];
        NSDate *otherDateOnly = [gregorianCalendar dateFromComponents:otherCompents];
        return [selfDateOnly compare:otherDateOnly];
    }
    return NO;
}
-(void)fillDetails:(SleepDetailHeaderView *)sleepHeaderView1
{
    [collectionViewDetailsArray removeAllObjects];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"MMM. dd yyyy"];
    timeLabel.text = [formatter stringFromDate: currentSleep.date];
    
    if([self compareDateOnly:currentSleep.date AndEndDate:[iDevicesUtil todayDateAtMidnight]] == NSOrderedSame) {
        timeLabel.text = NSLocalizedString(@"TODAY", nil);
    }
    if([self compareDateOnly:currentSleep.date AndEndDate:[iDevicesUtil yesterdayDateAtMidnight]] == NSOrderedSame) {
        timeLabel.text = NSLocalizedString(@"YESTERDAY", nil);
    }
    NSDateFormatter *timeFormatter = [[NSDateFormatter alloc] init];
    [timeFormatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];
    [timeFormatter setDateFormat:@"h:mm a"];
    
    [sleepHeaderView1 setTotalTimeWithText:[iDevicesUtil convertMinutesToStringHHDecimalFormat:([currentSleep.duration doubleValue]*MINUTES_PER_HOUR)]];
    [sleepHeaderView1 setStartTimeWithText:[timeFormatter stringFromDate:currentSleep.startDate]];
    [sleepHeaderView1 setEndTimeWithText:[timeFormatter stringFromDate:currentSleep.endDate]];
    float sleepTimeInMinutes = [currentSleep.duration floatValue]*MINUTES_PER_HOUR ; // This is measured in hours. So convert.
    deepSleep = (float)(deepSleep * 2);
    mediumSleep = (float)(mediumSleep * 2);
    if ((sleepTimeInMinutes - (deepSleep+mediumSleep)) >= 0) {// to fix artf25218
        awake = (sleepTimeInMinutes - (deepSleep+mediumSleep));
    } else {
        awake = 0;
    }
//    efficiency = ((deepSleep+mediumSleep)-awake)/(sleepTimeInMinutes) * 100; //deep epoch count + light epoch count / total epochs for sleep event
    efficiency = (deepSleep+mediumSleep)/(sleepTimeInMinutes)*100;
    
    NSDictionary *goalsDict = [[NSUserDefaults standardUserDefaults] valueForKey: [iDevicesUtil getGoalTypeStringFormat:(GoalType)[TDM328WatchSettingsUserDefaults goalType]]];
    CGFloat timeGoals = [[goalsDict objectForKey:SLEEPTIME] floatValue];
    [collectionViewDetailsArray insertObject:[iDevicesUtil convertMinutesToStringHHDecimalFormat:deepSleep] atIndex:0];
    [collectionViewDetailsArray insertObject:[iDevicesUtil convertMinutesToStringHHDecimalFormat:mediumSleep] atIndex:1];
    [collectionViewDetailsArray insertObject:[iDevicesUtil convertMinutesToStringHHDecimalFormat:awake] atIndex:2];
    [collectionViewDetailsArray insertObject:[NSString stringWithFormat: @"%.1f", efficiency] atIndex:3];
    [collectionViewDetailsArray insertObject:[iDevicesUtil convertMinutesToStringHHDecimalFormat:timeGoals*MINUTES_PER_HOUR] atIndex:4];
    [collectionViewDetailsArray insertObject:[self getAverageSleepForEachDay] atIndex:5];
    
    [self showOrHidePreviousAndNextBtns];
}
- (NSNumber *) getAverageSleepForEachDay {
    NSArray *sleepDBArray = [[DBModule sharedInstance] getSortedArrayFor:@"DBSleepEvents" predicate:nil keyString:@"endDate" isAscending:NO];
    sleepDBArray = [self getOnlyValidEventsFromArray:sleepDBArray];
    //NSArray *filtered = [sleepDBArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"%K==%@", @"date",currentSleep.date]];
    double totalTimeInHrs = 0;
    NSMutableArray *datesArray = [[NSMutableArray alloc] init];
    for (DBSleepEvents *sleepEvent in sleepDBArray) {
        totalTimeInHrs += [sleepEvent.duration doubleValue];
        if(![datesArray containsObject:sleepEvent.date])
            [datesArray addObject:sleepEvent.date];
    }
    
    return [NSNumber numberWithDouble:(totalTimeInHrs/datesArray.count)];
}
- (NSArray *)getOnlyValidEventsFromArray:(NSArray *)array {
    NSMutableArray *sleepEvents = [array mutableCopy];
    NSMutableArray *evtns = [[NSMutableArray alloc] init];
    for (DBSleepEvents *sleepEvent in sleepEvents) {
        if (sleepEvent.duration.doubleValue > 0 &&
            sleepEvent.segmentsByEvent != nil &&
            sleepEvent.segmentsByEvent.length > 0 &&
            [sleepEvent.eventValid boolValue] &&
            [self sameCharsInString:sleepEvent.segmentsByEvent] == NO
            ) {
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

- (void)showOrHidePreviousAndNextBtns {
    sleepNextButton.hidden = NO;
    sleepPrevButton.hidden = NO;
    if ([sleepDetailsArray indexOfObject:currentSleep] == (sleepDetailsArray.count-1)) {
        sleepNextButton.hidden = YES;
    } else {
        sleepNextButton.hidden = NO;
    }
    if ([sleepDetailsArray indexOfObject:currentSleep] == 0) {
        sleepPrevButton.hidden = YES;
    } else {
        sleepPrevButton.hidden = NO;
    }
    if (sleepDetailsArray.count <= 1) {
        sleepPrevButton.hidden = YES;
        sleepNextButton.hidden = YES;
    }
}
#pragma mark
#pragma mark Scrollview delegate methods
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView_ {
    if (scrollView_.tag == 111) {
        sleepPrevButton.hidden = YES;
        sleepNextButton.hidden = YES;
    }
}
- (void)scrollViewDidScroll:(UIScrollView *)scrollView_ {
    if (scrollView_.tag == 111) {
        CGFloat pageWidth = ScreenWidth;
        float fractionalPage = scrollView_.contentOffset.x / pageWidth;
        NSInteger page = lround(fractionalPage);
        if (previousPage != page) {
            /* Page did change */
            NSArray *subviews = scrollView_.subviews;
            for (int i = 0; i < subviews.count; i++) {
                if (i == page && i < sleepDetailsArray.count) {
                    previousPage = page;
                    UIView *subv = subviews[i];
                    SleepDetailHeaderView *sleepHeaderView1 = [subv.subviews firstObject];
                    [sleepHeaderView1 layoutIfNeeded];
                    currentSleep = [sleepDetailsArray objectAtIndex:i];
                    [self executeSegments:currentSleep.segmentsByEvent andSide:true sleepHeaderView:sleepHeaderView1];
                    [self fillDetails:sleepHeaderView1];
                    OTLog(@"Draw Arc Scrollviewdidscroll");
                    break;
                }
            }
            [sleepDetailsTableView reloadData];
        } else {
            [self showOrHidePreviousAndNextBtns];
        }
    }
}

- (void)didReceiveMemoryWarning {
     OTLog([NSString stringWithFormat:@"Recived Memory Warning  in %@ ",NSStringFromClass([self class])]);
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma  mark Button Actions

- (void) backButtonTapped {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark UITableViewDelegate and DataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return M328_SLEEP_COLLECTION_VIEW_HEIGHT;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:collectionViewReuseIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:collectionViewReuseIdentifier];
    }
    if (!collectionVC) {
        collectionVC = [[CustomCollectionViewController alloc] initWithNibName:@"CustomCollectionViewController" bundle:nil];
    }
    [self removeAllSubviewsOfContentView:cell];
    [cell.contentView addSubview:collectionVC.view];
    collectionVC.view.frame = CGRectMake(-0.3, 0, (tableView.contentSize.width)+0.6, M328_SLEEP_COLLECTION_VIEW_HEIGHT);
    [collectionVC.view layoutIfNeeded];
    [collectionVC.view layoutSubviews];
    collectionVC.view.tag = 1;
    [collectionVC reloadCollectionView:collectionViewDetailsArray];
    
    cell.separatorInset = UIEdgeInsetsZero;
    cell.layoutMargins = UIEdgeInsetsZero;
    cell.accessoryType = UITableViewCellAccessoryNone;
    return cell;
}

- (void)removeAllSubviewsOfContentView :(UITableViewCell *)cell {
    for (UIView *view in cell.contentView.subviews) {
        [view removeFromSuperview];
    }
}


- (void)executeSegments:(NSString *)information andSide:(BOOL)side  sleepHeaderView:(SleepDetailHeaderView *)sleepHeaderView1 {
    if (information.length > 0) {
        awake = 0;
        mediumSleep = 0;
        deepSleep = 0;
        CAShapeLayer *arc = [CAShapeLayer layer];
        if (sleepHeaderView1.progressView.layer.sublayers.count > 1)
        {
            NSMutableArray *arcsToDelete = [[NSMutableArray alloc]init];
            for (arc in sleepHeaderView1.progressView.layer.sublayers)
            {
                [arcsToDelete addObject:arc];
            }
            for (int x = 0; x < arcsToDelete.count; x++)
            {
                CAShapeLayer *arc = [arcsToDelete objectAtIndex:x];
                [arc removeFromSuperlayer];
            }
        }
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
            
            //Radius of circle * number 30 is to set center the arc, it could be chhanged
            //Segment Width
            SegmentWidth = M328_SLEEP_DETAILS_ARC_SEGMENT_WIDTH;
            radiusSegment = sleepHeaderView1.progressView.frame.size.width - M328_SLEEP_DETAILS_ARC_SEGMENT_WIDTH;
            
            //Sgment Color
            NSString * newString = [information substringWithRange:NSMakeRange(0, 1)];
            if ([newString isEqualToString:M328_SLEEP_AWAKE_STR]) {
                choiceColor = M328_HOME_SLEEP_AWAKE_COLOR;
                
            } else if ([newString isEqualToString:M328_SLEEP_LIGHT_STR]) {
                choiceColor = M328_HOME_SLEEP_LIGHT_COLOR;
                
            } else if ([newString isEqualToString:M328_SLEEP_DEEP_STR]) {
                choiceColor = M328_HOME_SLEEP_DARK_COLOR;
            }
            
            //Start and End points
            segementStart = 0.5f;
            segementEnd   = 1.0f;
            
            //number of segments
            for (int i = 0; i < information.length; i++) {
                
                //Background Thread
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    
                    //Draw segment
                    [self addSegement:SegmentWidth andArcRadius:radiusSegment andStrokeStart:segementStart andStrokeEnd:segementEnd  andShadowRadius:0.0 andShadowOpacity:0.0 andShadowOffsset:CGSizeZero andChoiceColor:choiceColor andSide:side sleepHeaderView:sleepHeaderView1];
                    
                    //Set new values
                    float result = .5 / information.length;
                    
                    segementStart = segementStart + result;//0.6f;
                    segementEnd   = segementEnd + result;//0.7f;
                    
                    NSString * newString = [information substringWithRange:NSMakeRange(i, 1)];
                    
                    if ([newString isEqualToString:M328_SLEEP_AWAKE_STR]) {
                        choiceColor = M328_HOME_SLEEP_AWAKE_COLOR;
                        
                    } else if ([newString isEqualToString:M328_SLEEP_LIGHT_STR]) {
                        choiceColor = M328_HOME_SLEEP_LIGHT_COLOR;
                        
                    } else if ([newString isEqualToString:M328_SLEEP_DEEP_STR]) {
                        choiceColor = M328_HOME_SLEEP_DARK_COLOR;
                    }
                });
            }
        });
        
        for (int i=0; i < information.length; i++) {
            
            NSString * newString = [information substringWithRange:NSMakeRange(i, 1)];
            
            if ([newString isEqualToString:M328_SLEEP_DEEP_STR])
            {
                deepSleep = deepSleep + 1;
            }
            
            else if ([newString isEqualToString:M328_SLEEP_LIGHT_STR])
            {
                mediumSleep = mediumSleep +1;
            }
        }
    }
}

- (void)addSegement:(CGFloat)lineWidth andArcRadius:(int)ArcRadius andStrokeStart:(CGFloat)StrokeStart andStrokeEnd:(CGFloat)StrokeEnd andShadowRadius:(CGFloat)ShadowRadius andShadowOpacity:(CGFloat)ShadowOpacity andShadowOffsset:(CGSize)ShadowOffsset andChoiceColor:(UIColor *)colorBar andSide:(BOOL)side sleepHeaderView:(SleepDetailHeaderView *)sleepHeaderView1 {
    
    //Cordinate
    int X = (sleepHeaderView1.progressView.frame.size.width - ArcRadius)/2;
    int Y = sleepHeaderView1.progressView.frame.origin.y + lineWidth/2;
    
    //Create the layer to put inthere the segment
    CAShapeLayer *arc = [CAShapeLayer layer];
    
    //Add figure inthere
    [arc setPath:[[UIBezierPath bezierPathWithOvalInRect:CGRectMake(X, Y, ArcRadius, ArcRadius)] CGPath]];
    
    
    //Set up the layer
    arc.lineWidth     = lineWidth;
    arc.strokeStart   = StrokeStart;
    arc.strokeEnd     = StrokeEnd;
    arc.strokeColor   = [colorBar CGColor];
    arc.fillColor     = [UIColor clearColor].CGColor;
    arc.shadowColor   = [UIColor darkGrayColor].CGColor;
    arc.shadowOpacity = ShadowOpacity;
    arc.shadowOffset  = ShadowOffsset;
    arc.shadowRadius  = ShadowRadius;
    
    [sleepHeaderView1.progressView.layer addSublayer:arc];
}

#pragma mark SleepEvent updation
- (void)rightBarButtonTouched {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:NSLocalizedString(@"Delete",nil) otherButtonTitles:NSLocalizedString(@"Edit",nil), NSLocalizedString(@"Cancel",nil), nil];
    if (IS_IPAD) {
        [actionSheet showFromBarButtonItem:self.navigationItem.rightBarButtonItem animated:YES];
    } else {
        [actionSheet showInView:self.view];
    }
}
- (void)actionSheet:(UIActionSheet *)ActionTag clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0:
            [self deleteTouched];
            break;
        case 1:
            [self editSleepClicked];
        default:
            break;
    }
}

-(void)editSleepClicked
{
    EditSleepEventsViewController *editSleepVC = [[EditSleepEventsViewController alloc] initWithNibName:@"EditSleepEventsViewController" bundle:nil andCurrentSleep:currentSleep];
    [self.navigationController pushViewController:editSleepVC animated:YES];
}

- (void)deleteTouched {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Delete",nil) message:NSLocalizedString(@"Are you sure?",nil) delegate:self cancelButtonTitle:NSLocalizedString(@"No",nil) otherButtonTitles:NSLocalizedString(@"Yes",nil), nil];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [self deleteSleepEvent];
    }
}


- (void)deleteSleepEvent {
    currentSleep.eventValid = @"0";
    DBActivity *activity = (DBActivity *)[[DBModule sharedInstance] getEntity:@"DBActivity" columnName:@"date" value:currentSleep.date];
    if ([activity.sleep doubleValue] <= [currentSleep.duration doubleValue]) {
        activity.sleep = [NSNumber numberWithDouble:0.0];
    } else {
        activity.sleep = [NSNumber numberWithDouble:([activity.sleep doubleValue] - [currentSleep.duration doubleValue])];
    }
    [[DBModule sharedInstance] saveContext];
    [(SleepHistoryViewController *)self.caller syncDone];
    [self backButtonTapped];
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
