//
//  TDHomeViewController.m
//  Timex
//
//  Created by Aruna Kumari Yarra on 28/03/16.
//  Copyright © 2016 iDevices, LLC. All rights reserved.
//

#import "TDHomeViewController.h"

#import "TimexWatchDB.h"
#import "OTLogUtil.h"
#import "TDCustomHomeTableViewCell.h"
#import "UIImage+Tint.h"
#import "TDDefines.h"
#import "iDevicesUtil.h"
#import "StepsViewController.h"
//#import "Activity.h"
//#import "Goals.h"
#import "TDDefines.h"
#import "SleepHistoryViewController.h"
//#import "Sleep.h"
#import "CustomTabbar.h"
#import "TDAppDelegate.h"
#import "MFSideMenuContainerViewController.h"
#import "SideMenuViewController.h"
#import "TDM328WatchSettingsUserDefaults.h"
#import "TDM328WatchSettings.h"
#import "TDM329WatchSettingsUserDefaults.h"
#import "TDM329WatchSettings.h"
#import "DBModule.h"
#import "DBActivity+CoreDataClass.h"
#import "DBM372Migration.h"

@interface TDHomeViewController () {
    NSString *reuseIdentifier;
    NSMutableArray *tableInfoArray;
    NSArray *workoutsArray;
    
    TDAppDelegate *appDelegate;
    CustomTabbar *customTabbar;
    NSMutableArray *notificaitonDismissedDates;
    BOOL isInitialSync;

}

@end

@implementation TDHomeViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil doFirmwareCheck: (BOOL) firmwareCheckRequested initialSync:(BOOL)isInitialSync_
{    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        isInitialSync = isInitialSync_;
        if (firmwareCheckRequested) {
            [self performSelector:@selector(launchFirmwareCheck:) withObject: [NSNotification notificationWithName: UIApplicationDidFinishLaunchingNotification object: nil] afterDelay: 1.0];
        }
    }
    return self;
}

- (void) launchFirmwareCheck: (NSNotification*)notification
{
    [customTabbar launchUserInitiatedFirmwareCheck:notification];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    if ([[NSUserDefaults standardUserDefaults] objectForKey:WATCHID_COREDATA_MIGRATION_DONE] == nil || [[[NSUserDefaults standardUserDefaults] objectForKey:WATCHID_COREDATA_MIGRATION_DONE] isEqualToString:@"0"]) { // Adding watchID to already stored data in DB for first item only.
        [DBM372Migration setWatchIDForAllEntitiesINCoreData];
    }
    self.view.frame = [[UIScreen mainScreen] bounds];
    self.navigationController.navigationBarHidden = NO;
    appDelegate = (TDAppDelegate *)[[UIApplication sharedApplication] delegate];
    self.navigationItem.titleView = [iDevicesUtil getNavigationTitle];
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))  {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    tableInfoArray = [[NSMutableArray alloc] init];
    workoutsArray = [[NSArray alloc] init];
    reuseIdentifier = @"cell";
    _homeTableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0.1)];
    _homeTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0.6)];
    _homeTableView.separatorInset = UIEdgeInsetsZero;
    [_homeTableView setLayoutMargins:UIEdgeInsetsZero];
    
    notificaitonDismissedDates = [[[NSUserDefaults standardUserDefaults] objectForKey:@"NotificaitonDismissedDates"] mutableCopy];
    if (notificaitonDismissedDates == nil) {
        notificaitonDismissedDates = [[NSMutableArray alloc] init];
    }
    
    _notificaitonHConstraint.constant = 0;
    notificationView.hidden = YES;
    
    [self customizeCalenderSelectionView];
    [self setMinAndMaxDate];
    [self initializeWorkoutsArray];

    //gesture
    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(slideToRightWithGestureRecognizer:)];
    swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
    
    UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(slideToLeftWithGestureRecognizer:)];
    swipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;
    
    [self.view addGestureRecognizer:swipeRight];
    [self.view addGestureRecognizer:swipeLeft];
    
    [((MFSideMenuContainerViewController *)appDelegate.window.rootViewController) setPanMode:MFSideMenuPanModeNone];
    
    // Add Notification Observers
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncDataFinished:) name:@"SyncDataFinished" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
}
- (void)appDidBecomeActive:(NSNotification *)notification {
    [self syncDataFinished:nil];
    if (_calendarContentView != nil) {
        [self calendarButtonTapped:nil];
        [self calendarButtonTapped:nil];
    }
}
- (void)slideMenuTapped {
    SideMenuViewController *leftController = (SideMenuViewController *)((MFSideMenuContainerViewController *)appDelegate.window.rootViewController).leftMenuViewController;
    if (leftController == nil) {
        leftController = [[SideMenuViewController alloc] init];
        ((MFSideMenuContainerViewController *)appDelegate.window.rootViewController).leftMenuViewController = leftController;
    }
    if (isInitialSync) {
        // After removing watch sidemenu array list is set to initialsetup list so we need to reset that menulist once when we are successfully connected to iQ watch
        [leftController resetMenu];
    }
    [leftController.menuTable selectRowAtIndexPath: [NSIndexPath indexPathForRow: viewNavigatorIQ_viewMain inSection: 0] animated: YES scrollPosition: UITableViewScrollPositionNone];
}

- (void)didReceiveMemoryWarning {
     OTLog([NSString stringWithFormat:@"Recived Memory Warning  in %@ ",NSStringFromClass([self class])]);
    [super didReceiveMemoryWarning];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];

    [self slideMenuTapped];

    self.view.backgroundColor = [UIColor whiteColor];
    
    [self notificationViewCustomization];
    [self addCustomTabbar];
    
    // If it is initialsync then we need to refresh data and view also
    if (isInitialSync) {
        isInitialSync = NO;
        [self setMinAndMaxDate];
        [self initializeWorkoutsArray];
    } else {
        //When sleep events deleted/getting new updates
        [self updateDateScroll:_dateSelected];
    }
}

- (void)syncDataFinished:(NSNotification *)notification {
    [self setMinAndMaxDate];
    [self initializeWorkoutsArray];
}


- (BOOL) viewHasContextualMenu {
    return TRUE;
}


- (UIBarButtonItem *)rightMenuBarButtonItem {
    if (_calendarButtonItem == nil) {
        UIButton *calendarButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [calendarButton.titleLabel setFont:[UIFont systemFontOfSize:14.0]];
        [calendarButton setTitleEdgeInsets:UIEdgeInsetsMake(5, 0, 0, 0)];
        [calendarButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        [calendarButton setFrame:CGRectMake(0, 0, 35, 35)];
        [calendarButton addTarget:self action:@selector(calendarButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        
        _calendarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:calendarButton];
        [self setImageForRightBarButtonItem:@"calendar_icon_Sleep_Tracker.png"];
        [self setSeletedDateForCalendarButton];
        
    }
    return _calendarButtonItem;
}

-(void)setImageForRightBarButtonItem:(NSString *)imageName
{
    UIImage *calendarImage = [[UIImage imageNamed:imageName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    if ([imageName isEqualToString:@"cross"]) {
        [(UIButton *)[_calendarButtonItem customView] setBackgroundImage:nil forState:UIControlStateNormal];
        [(UIButton *)[_calendarButtonItem customView] setImage:calendarImage forState:UIControlStateNormal];
    } else {
        [(UIButton *)[_calendarButtonItem customView] setImage:nil forState:UIControlStateNormal];
        [(UIButton *)[_calendarButtonItem customView] setBackgroundImage:calendarImage forState:UIControlStateNormal];
    }
}

-(void)setSeletedDateForCalendarButton
{
    if (_dateSelected == nil) {
        return;
    }
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitDay fromDate:_dateSelected];
    
    [(UIButton *)[_calendarButtonItem customView] setTitle:[NSString stringWithFormat:@"%ld", (long)[components day]] forState:UIControlStateNormal];
}

#pragma mark
#pragma mark Swipe
- (void)slideToRightWithGestureRecognizer:(UISwipeGestureRecognizer *)gestureRecognizer{
    if (_calendarContentView == nil && [((MFSideMenuContainerViewController *)appDelegate.window.rootViewController) menuState] == MFSideMenuStateClosed) {
        if ([gestureRecognizer locationOfTouch:0 inView:self.view].x <= 20) {
            ((MFSideMenuContainerViewController *)appDelegate.window.rootViewController).menuState = MFSideMenuStateLeftMenuOpen;
        } else {
            @autoreleasepool {
                __block UIImage *forTheEffect;
                __block UIImageView *dot =[[UIImageView alloc] initWithFrame:CGRectMake(0,0,self.view.frame.size.width,self.view.frame.size.height)];
                if (![_leftBtn isHidden]) {
                    forTheEffect = [self snapshot:self.view];
                    [UIView animateWithDuration:0.5 animations:^{
                        dot.image = forTheEffect;
                        [self.view addSubview:dot];
                        dot.frame = CGRectOffset(dot.frame, ScreenWidth, 0.0);
                        [self clickedOnDateBtn:_leftBtn];
                    }completion:^(BOOL finished) {
                        [dot removeFromSuperview];
                    }];
                }
            }
        }
    }
}

- (void)slideToLeftWithGestureRecognizer:(UISwipeGestureRecognizer *)gestureRecognizer {
    if (_calendarContentView == nil && [((MFSideMenuContainerViewController *)appDelegate.window.rootViewController) menuState] == MFSideMenuStateClosed) {
        @autoreleasepool {
            __block UIImage *forTheEffect;
            __block UIImageView *dot = [[UIImageView alloc] initWithFrame:CGRectMake(0,0,self.view.frame.size.width,self.view.frame.size.height)];
            if (![_rightBtn isHidden]) {
                forTheEffect = [self snapshot:self.view];
                [UIView animateWithDuration:0.5 animations:^{
                    dot.image = forTheEffect;
                    [self.view addSubview:dot];
                    dot.frame = CGRectOffset(dot.frame, -ScreenWidth, 0.0);
                    [self clickedOnDateBtn:_rightBtn];
                } completion:^(BOOL finished) {
                    [dot removeFromSuperview];
                }];
            }
        }
    }
}

#pragma mark SnapShoot
- (UIImage *)snapshot:(UIView *)view {
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, YES, 0);
    [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:YES];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

#pragma mark
#pragma mark CustomTabbar
- (void)addCustomTabbar {
    if ([appDelegate customTabbar] == nil) {
        [appDelegate InitialiseCustomTabbar];
    }
    customTabbar = [appDelegate customTabbar];
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

- (void)notificationViewCustomization {
    higerBtn.layer.cornerRadius = 15.0f;
    higerBtn.layer.masksToBounds = YES;
    
    dismissBtn.layer.cornerRadius = 15.0f;
    dismissBtn.layer.borderWidth = 0.3f;
    dismissBtn.layer.borderColor = [UIColor lightGrayColor].CGColor;
    dismissBtn.layer.masksToBounds = YES;
}

- (IBAction)notificationBtnSelected:(UIButton *)sender {
    [notificaitonDismissedDates addObject:_dateSelected];
    [[NSUserDefaults standardUserDefaults] setObject:notificaitonDismissedDates forKey:@"NotificaitonDismissedDates"];
    if (sender.tag == 1) {
        SideMenuViewController *leftController = (SideMenuViewController *)((MFSideMenuContainerViewController *)appDelegate.window.rootViewController).leftMenuViewController;
        [leftController tableView:leftController.menuTable didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
        [leftController.menuTable selectRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0] animated:YES scrollPosition:UITableViewScrollPositionTop];
    } else {
        _notificaitonHConstraint.constant = 0;
        notificationView.hidden = YES;
    }
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear: animated];
}

#pragma mark - Button Actions
- (void)calendarButtonTapped:(id)sender {
    if (_calendarContentView==nil)
    {
        [self setImageForRightBarButtonItem:@"cross"];
        [(UIButton *)[_calendarButtonItem customView] setTitle:@"" forState:UIControlStateNormal];
        
        _calendarMenuView=[[JTCalendarMenuView alloc]initWithFrame:CGRectMake(0,10,ScreenWidth,44)];
        _calendarContentView=[[JTHorizontalCalendarView alloc]initWithFrame:CGRectMake(0,54,ScreenWidth,ScreenWidth-60)];
        
        _calendarMenuView.backgroundColor = [UIColor whiteColor];
        _calendarContentView.backgroundColor = [UIColor whiteColor];
        
        _calendarContentView.delegate=self;
        
        _calBgView = [[UIView alloc] initWithFrame:self.view.frame];
        _calBgView.backgroundColor = [UIColor whiteColor];
        CGRect rect = _calBgView.frame;
        rect.origin.y -= 64;
        _calBgView.frame = rect;
        
        //[self.view addSubview:_calendarContentView];
        [_calBgView addSubview:_calendarContentView];
        [self.view addSubview:_calBgView];
        
        _calPrevButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _calPrevButton.frame = CGRectMake(10, 0, 40, 40);
        [_calPrevButton setImage:[UIImage imageNamed:@"leftarrow"] forState:UIControlStateNormal];
        [_calPrevButton setContentEdgeInsets:UIEdgeInsetsMake(10, 10, 10, 10)];
        [_calPrevButton addTarget:self action:@selector(calPrevTapped) forControlEvents:UIControlEventTouchUpInside];
        
        _calNextButton = [UIButton buttonWithType:UIButtonTypeCustom];
        
        _calNextButton.frame = CGRectMake(ScreenWidth - 50, 0, 40, 40);
        [_calNextButton setImage:[UIImage imageNamed:@"rightarrow"] forState:UIControlStateNormal];
        [_calNextButton setContentEdgeInsets:UIEdgeInsetsMake(10, 10, 10, 10)];
        [_calNextButton addTarget:self action:@selector(calNextTapped) forControlEvents:UIControlEventTouchUpInside];
        
        
        _calTodayButton = [UIButton buttonWithType:UIButtonTypeCustom];
        
        _calTodayButton.frame = CGRectMake(ScreenWidth - 130, _calendarContentView.frame.origin.y + _calendarContentView.frame.size.height + 10, 120, 40);
        [_calTodayButton setTitle:NSLocalizedString(@"Back to Today >",nil) forState:UIControlStateNormal];
        [_calTodayButton setTitleColor:UIColorFromRGB(AppColorRed) forState:UIControlStateNormal];
        //[_calTodayButton.titleLabel setFont:[UIFont boldSystemFontOfSize:14.0]];
        [_calTodayButton.titleLabel setFont:[UIFont fontWithName: [iDevicesUtil getAppWideBoldFontName] size: M328_HOME_TODAY_BUTTON_FONT_SIZE]];
        
        [_calTodayButton addTarget:self action:@selector(calTodayTapped) forControlEvents:UIControlEventTouchUpInside];
        
        
        [_calendarMenuView addSubview:_calPrevButton];
        [_calendarMenuView addSubview:_calNextButton];
        
        [_calBgView addSubview:_calTodayButton];
        //[self.view addSubview:_calTodayButton];
        
        // [self.view addSubview:_calendarMenuView];
        [_calBgView addSubview:_calendarMenuView];
        _calendarManager = [JTCalendarManager new];
        _calendarManager.delegate = self;
        
        [self createRandomEvents];
        
        _yearLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, 18)];
        _yearLabel.textAlignment = NSTextAlignmentCenter;
        _yearLabel.font = [UIFont systemFontOfSize:12.0];
        _yearLabel.textColor = AppColorLightGray;
        _yearLabel.text = [self getCurrentYear:_dateSelected];
        [_calendarMenuView addSubview:_yearLabel];
        
        [_calendarManager setMenuView:_calendarMenuView];
        [_calendarManager setContentView:_calendarContentView];
        
        if (!_dateSelected) {
            _calNextButton.enabled = NO;
            _calTodayButton.hidden = YES;
            [_calendarManager setDate:[iDevicesUtil todayDateAtMidnight]];
        } else if(_dateSelected && [_calendarManager.dateHelper date:_dateSelected isTheSameDayThan:[iDevicesUtil todayDateAtMidnight]]) {
            _calTodayButton.hidden = YES;
            [_calendarManager setDate:_dateSelected];
        } else {
            _calNextButton.enabled = YES;
            _calTodayButton.hidden = NO;
            [_calendarManager setDate:_dateSelected];
        }
        
        if(_dateSelected && [_calendarManager.dateHelper date:_dateSelected isTheSameMonthThan:[iDevicesUtil todayDateAtMidnight]]) {
            _calNextButton.enabled = NO;
        }
        if ([_calendarManager.dateHelper date:_minDate isTheSameMonthThan:[iDevicesUtil todayDateAtMidnight]]) {
            _calPrevButton.enabled = NO;
        } else {
            if ([_calendarManager.dateHelper date:_minDate isTheSameMonthThan:_dateSelected]) {
                _calPrevButton.enabled = NO;
            } else {
                _calPrevButton.enabled = YES;
            }
        }
    }
    else
    {
        [self setImageForRightBarButtonItem:@"calendar_icon_Sleep_Tracker.png"];
        [self setSeletedDateForCalendarButton];
        
        [_calBgView removeFromSuperview];
        //[_calendarContentView removeFromSuperview];
        _calendarContentView=nil;
        [_calendarMenuView removeFromSuperview];
        _calendarMenuView=nil;
        [_calTodayButton removeFromSuperview];
        _calTodayButton = nil;
        
    }
}

-(NSString *)getCurrentYear:(NSDate *)date
{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"yyyy"];
    NSString *year = [df stringFromDate:date];
    return year;
}
-(NSString *)getCurrentMonth:(NSDate *)date
{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"MMMM"];
    NSString *year = [df stringFromDate:date];
    return year;
}

- (void)calTodayTapped {
    _dateSelected = [iDevicesUtil todayDateAtMidnight];
    [self setSeletedDateForCalendarButton];
    
    [_calendarManager setDate:_dateSelected];
    [_calendarManager reload];
    _yearLabel.text = [self getCurrentYear:_dateSelected];
    _calNextButton.enabled = NO;
    _calPrevButton.enabled = NO;
    _calTodayButton.hidden = YES;
    
    [self calendarButtonTapped:_calendarButtonItem];
    
    [self updateDateScroll:_dateSelected];
}

- (void)calPrevTapped {
    [_calendarContentView loadPreviousPage];
    [_calendarManager reload];
    _yearLabel.text = [self getCurrentYear:_calendarManager.date];
    [self enableOrDisbleCalenderButtons];
}

- (void)calNextTapped {
    [_calendarContentView loadNextPage];
    [_calendarManager reload];
    _yearLabel.text = [self getCurrentYear:_calendarManager.date];
    [self enableOrDisbleCalenderButtons];
}
- (void)enableOrDisbleCalenderButtons {
    //Today Button
    if([_calendarManager.dateHelper date:_calendarManager.date isTheSameDayThan:[iDevicesUtil todayDateAtMidnight]]) {
        _calTodayButton.hidden = YES;
    } else {
        _calTodayButton.hidden = NO;
        DBActivity *activity = (DBActivity*)[[DBModule sharedInstance]getEntity:@"DBActivity" columnName:@"date" value:[iDevicesUtil todayDateAtMidnight]];
        if (activity == nil) {
            _calTodayButton.hidden = YES;
        }
    }
    
    //Next Button
    if ([_calendarManager.dateHelper date:_maxDate isTheSameMonthThan:_calendarManager.date]) {
        _calNextButton.enabled = NO;
    } else {
        _calNextButton.enabled = YES;
    }
    
    //PreviousButton
    if ([_calendarManager.dateHelper date:_minDate isTheSameMonthThan:_calendarManager.date]) {
        _calPrevButton.enabled = NO;
    } else {
        if ([_calendarManager.dateHelper date:_minDate isEqualOrBefore:_calendarManager.date]) {
            _calPrevButton.enabled = YES;
        } else {
            _calPrevButton.enabled = NO;
        }
    }
}

#pragma mark - CalendarManager delegate - Page mangement
- (void)calendar:(JTCalendarManager *)calendar prepareDayView:(JTCalendarDayView *)dayView
{
    if(!_dateSelected && [_calendarManager.dateHelper date:[iDevicesUtil todayDateAtMidnight] isTheSameDayThan:dayView.date]){
        dayView.circleView.hidden = NO;
        dayView.circleView.backgroundColor = [UIColor redColor]; //blue color to distinguish current day from other dates
        //dayView.dotView.backgroundColor = [UIColor whiteColor];
        dayView.textLabel.textColor = [UIColor whiteColor];
    }
    // Selected date
    else if(_dateSelected && [_calendarManager.dateHelper date:_dateSelected isTheSameDayThan:dayView.date]){
        dayView.circleView.hidden = NO;
        dayView.circleView.backgroundColor = [UIColor redColor];
        //dayView.dotView.backgroundColor = [UIColor whiteColor];
        dayView.textLabel.textColor = [UIColor whiteColor];
    }
    // Other month
    else if(![_calendarManager.dateHelper date:_calendarContentView.date isTheSameMonthThan:dayView.date]){
        dayView.circleView.hidden = YES;
        //dayView.dotView.backgroundColor = [UIColor redColor];
        dayView.textLabel.textColor = [UIColor blackColor];
    }
    // Another day of the current month
    else{
        dayView.circleView.hidden = YES;
        dayView.textLabel.textColor = [UIColor blackColor];
        dayView.userInteractionEnabled = YES;
    }
    if([self compareDateOnly:dayView.date AndEndDate:[iDevicesUtil todayDateAtMidnight]] == NSOrderedDescending)
    {
        dayView.userInteractionEnabled = NO;
        dayView.textLabel.textColor = [UIColor lightGrayColor];
        dayView.circleView.hidden = YES;
    }
    
    if (![_calendarManager.dateHelper date:dayView.date isEqualOrAfter:_minDate andEqualOrBefore:_maxDate]) {
        dayView.userInteractionEnabled = NO;
        dayView.textLabel.textColor = [UIColor lightGrayColor];
        dayView.circleView.hidden = YES;
    }
    
    [self enableOrDisbleCalenderButtons];
}


- (void)calendar:(JTCalendarManager *)calendar didTouchDayView:(JTCalendarDayView *)dayView
{
    _dateSelected = dayView.date;
    [self setSeletedDateForCalendarButton];
    
    // Animation for the circleView
    dayView.circleView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.1, 0.1);
    [UIView transitionWithView:dayView
                      duration:.3
                       options:0
                    animations:^{
                        dayView.circleView.transform = CGAffineTransformIdentity;
                        [_calendarManager reload];
                    } completion:nil];
    
    
    // Load the previous or next page if touch a day from another month
    
    if(![_calendarManager.dateHelper date:_calendarContentView.date isTheSameMonthThan:dayView.date]){
        if([_calendarContentView.date compare:dayView.date] == NSOrderedAscending){
            [_calendarContentView loadNextPageWithAnimation];
        }
        else{
            [_calendarContentView loadPreviousPageWithAnimation];
        }
    }
    
    [self calendarButtonTapped:_calendarButtonItem];
    [self updateDateScroll:_dateSelected];
    
}


// Used to limit the date for the calendar, optional
- (BOOL)calendar:(JTCalendarManager *)calendar canDisplayPageWithDate:(NSDate *)date
{
    return [_calendarManager.dateHelper date:date isEqualOrAfter:_minDate andEqualOrBefore:_maxDate];
}

- (void)calendarDidLoadNextPage:(JTCalendarManager *)calendar
{
}

- (void)calendarDidLoadPreviousPage:(JTCalendarManager *)calendar
{
}


#pragma mark - Dummy data

//Setting min and max dates to enable in calender
- (void)setMinAndMaxDate {
    NSArray *dbArray = [[DBModule sharedInstance] getSortedArrayFor:@"DBActivity" predicate:nil keyString:@"date" isAscending:YES];
    
    if (dbArray.count > 0) {
//        DBActivity *activityStart = [dbArray firstObject];
        DBActivity *activityEnd = [dbArray lastObject];
        _minDate = [self findMinDate:dbArray];
        NSCalendar *gregorian = [NSCalendar currentCalendar];
        NSDateComponents *components = [gregorian components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:[NSDate date]];
        components.day += 1;
        NSDate *maxDate = [gregorian dateFromComponents:components];
        if ([maxDate timeIntervalSinceDate:activityEnd.date] < 0)
        {
            OTLog(@"Database has an invalid date");
            _maxDate = [NSDate date];
        }
        else
        {
            _maxDate = activityEnd.date;
        }
    } else {
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSDateComponents *components = [NSDateComponents new];
        
        // Min date will be today
        components.month = 0;
        _minDate = [calendar dateByAddingComponents:components toDate:[iDevicesUtil todayDateAtMidnight] options:0];
        // Max date will be today
        components.month = 0;
        _maxDate = [calendar dateByAddingComponents:components toDate:[iDevicesUtil todayDateAtMidnight] options:0];
    }
    _dateSelected = _maxDate;
    [self setSeletedDateForCalendarButton];
    
    [self updateDateScroll:_dateSelected];
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

// Used only to have a key for _eventsByDate
- (NSDateFormatter *)dateFormatter
{
    static NSDateFormatter *dateFormatter;
    if(!dateFormatter){
        dateFormatter = [NSDateFormatter new];
        dateFormatter.dateFormat = @"dd-MM-yyyy";
    }
    
    return dateFormatter;
}

- (BOOL)haveEventForDay:(NSDate *)date
{
    NSString *key = [[self dateFormatter] stringFromDate:date];
    
    if(_eventsByDate[key] && [_eventsByDate[key] count] > 0){
        return YES;
    }
    
    return NO;
    
}

- (void)createRandomEvents
{
    _eventsByDate = [NSMutableDictionary new];
    
    for(int i = 0; i < 30; ++i){
        // Generate 30 random dates between now and 60 days later
        NSDate *randomDate = [NSDate dateWithTimeInterval:(rand() % (3600 * 24 * 60)) sinceDate:[iDevicesUtil todayDateAtMidnight]];
        
        // Use the date as key for eventsByDate
        NSString *key = [[self dateFormatter] stringFromDate:randomDate];
        
        if(!_eventsByDate[key]){
            _eventsByDate[key] = [NSMutableArray new];
        }
        
        [_eventsByDate[key] addObject:randomDate];
        
    }
}

#pragma mark Workouts
- (double)getPercentageWithActual:(double)actual withGoals:(double)goals {
    double percentage = 0.0;
    percentage = actual / goals;
    return percentage * 100.0f;
}

- (void) initializeWorkoutsArray {
    [tableInfoArray removeAllObjects];
    
    NSDictionary *goalsDict = [[NSUserDefaults standardUserDefaults] valueForKey: [iDevicesUtil getGoalTypeStringFormat:(GoalType)[TDM328WatchSettingsUserDefaults goalType]]];
    NSInteger totalSteps = 0;
    NSInteger stepsGoals = [[goalsDict objectForKey:STEPS] integerValue];
    
    double activityDistance = 0.0;
    double distanceGoals = [[goalsDict objectForKey:DISTANCE] doubleValue];
    
    double totalCal = 0;
    double calgoals = [[goalsDict objectForKey:CALORIES] doubleValue];
    
    double hrs = 0.0;
    double timeGoals = [[goalsDict objectForKey:SLEEPTIME] doubleValue];
    
    

    NSArray *activityArray = [[DBModule sharedInstance] getArrayFor:[NSPredicate predicateWithFormat: @"%K==%@",@"date",_dateSelected] entityName:@"DBActivity"];
    for (DBActivity *activity in activityArray) {
        totalSteps += activity.steps.integerValue;
        activityDistance += activity.distance.integerValue;
        totalCal += activity.calories.integerValue;
        if (activity.sleepEvents.allObjects.count > 0 && activity.segments.length > 0) {
            hrs += activity.sleep.doubleValue;
        }
    }
    activityDistance = activityDistance/100.0;
    totalCal = totalCal/10.0;

    // Steps
    NSString *stepsStr = [NSString stringWithFormat:@"%ld",(long)totalSteps];
    double stepspercentage = [self getPercentageWithActual:totalSteps withGoals:stepsGoals];
    NSString * stepsImgName = @"steps";
    NSMutableDictionary *stepsDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:stepsStr,@"actual",[NSNumber numberWithInteger:stepsGoals],@"goals",[NSNumber numberWithDouble:stepspercentage],@"percentage",stepsImgName,@"imagename", nil];
    [tableInfoArray addObject:stepsDict];
    
    // Distance
    if (![iDevicesUtil isMetricSystem]) {
        activityDistance = [iDevicesUtil convertKilometersToMiles:activityDistance];
        distanceGoals = [iDevicesUtil convertKilometersToMiles:distanceGoals];
    }
    double distncepercentage = [self getPercentageWithActual:activityDistance withGoals:distanceGoals];

    NSString * distImgName = @"distance";
    NSMutableDictionary *distanceDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:activityDistance],@"actual",[NSNumber numberWithDouble:distanceGoals],@"goals",[NSNumber numberWithDouble:distncepercentage],@"percentage",distImgName,@"imagename", nil];
    [tableInfoArray addObject:distanceDict];
    
    // Calories
    double calpercentage = [self getPercentageWithActual:totalCal withGoals:calgoals];
    NSString * calImgName = @"calories";
    NSDictionary *calDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%ld",(long)floorf(totalCal)],@"actual",[NSNumber numberWithDouble:calgoals],@"goals",[NSNumber numberWithDouble:calpercentage],@"percentage",calImgName,@"imagename", nil];
    [tableInfoArray addObject:calDict];
    
    //hours
    NSString * timeImgName = @"sleep";
    double timePercentage = [self getPercentageWithActual:hrs withGoals:timeGoals];
    NSDictionary *hoursDict = [NSDictionary dictionaryWithObjectsAndKeys:[iDevicesUtil convertMinutesToStringHHDecimalFormat:hrs*MINUTES_PER_HOUR],@"actual",[iDevicesUtil convertMinutesToStringHHDecimalFormat:timeGoals*MINUTES_PER_HOUR],@"goals",[NSNumber numberWithDouble:timePercentage],@"percentage",timeImgName,@"imagename", nil];
    [tableInfoArray addObject:hoursDict];
    
    
    if ((totalSteps >= stepsGoals ||  activityDistance >= distanceGoals || totalCal >= calgoals) && !([notificaitonDismissedDates containsObject:_dateSelected])) {
        _notificaitonHConstraint.constant = 100;
        notificationView.hidden = NO;
        if (totalSteps >= stepsGoals) {
            goalDescLbl.attributedText = [self getAttributedStrWithText:NSLocalizedString(@"Steps ",nil) formatStr:[NSString stringWithFormat:@"%ld",(long)totalSteps]];
            [goalImgView setImage:[[UIImage imageNamed: @"Congrats"] imageWithTint: [iDevicesUtil getActivityColorBasedOnPercentage: stepspercentage andType:@"steps"]]];
        } else if (activityDistance >= distanceGoals) {
            goalDescLbl.attributedText = [self getAttributedStrWithText:NSLocalizedString(@"Distance ",nil) formatStr:[NSString stringWithFormat:@"%.1f",distanceGoals]];
            [goalImgView setImage:[[UIImage imageNamed: @"Congrats"] imageWithTint: [iDevicesUtil getActivityColorBasedOnPercentage: distncepercentage andType:@"distance"]]];
        } else if (totalCal >= calgoals) {
            goalDescLbl.attributedText = [self getAttributedStrWithText:NSLocalizedString(@"Calories ",nil) formatStr:[NSString stringWithFormat:@"%ld %@",(long)calgoals,[iDevicesUtil isMetricSystem]?NSLocalizedString(@"kcal", nil):NSLocalizedString(@"Cal", nil)]];
            [goalImgView setImage:[[UIImage imageNamed: @"Congrats"] imageWithTint: [iDevicesUtil getActivityColorBasedOnPercentage: calpercentage andType:@"calories"]]];
        } else {
            goalDescLbl.attributedText = [self getAttributedStrWithText:NSLocalizedString(@"Time ",nil) formatStr:[NSString stringWithFormat:@"%.2f sleep",timeGoals]];
            [goalImgView setImage:[[UIImage imageNamed: @"Congrats"] imageWithTint: [iDevicesUtil getActivityColorBasedOnPercentage: timePercentage andType:@"sleep"]]];
        }
    } else {
        _notificaitonHConstraint.constant = 0;
        notificationView.hidden = YES;
    }
    
    [_homeTableView reloadData];
}

- (NSAttributedString *)getAttributedStrWithText:(NSString *)textStr formatStr:(NSString *)formatStr {
    
    UIFont *formatFont = [UIFont fontWithName: [iDevicesUtil getAppWideMediumFontName] size:17];
    NSDictionary *atrsDict = [NSDictionary dictionaryWithObjectsAndKeys:formatFont, NSFontAttributeName, [UIColor blackColor],NSForegroundColorAttributeName, nil];
    NSMutableAttributedString *formatAtrStr = [[NSMutableAttributedString alloc] initWithString:textStr attributes:atrsDict];
    
    
    UIFont *textFont = [UIFont fontWithName:[iDevicesUtil getAppWideBoldFontName] size:22];
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:textFont, NSFontAttributeName, [UIColor blackColor],NSForegroundColorAttributeName, nil];
    NSAttributedString *textAtrStr = [[NSMutableAttributedString alloc] initWithString:formatStr attributes:dict];
    [formatAtrStr appendAttributedString:textAtrStr];
    
    return formatAtrStr;
}

#pragma mark
#pragma mark UITableViewDelegate and DataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    
    return tableInfoArray.count;
}


-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return M328_HOME_SCREEN_ROW_HEIGHT;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TDCustomHomeTableViewCell * cell = NULL;
    
    cell = (TDCustomHomeTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell)
    {
        [tableView registerNib:[UINib nibWithNibName:@"TDCustomHomeTableViewCell" bundle:nil] forCellReuseIdentifier:@"cell"];
        cell = (TDCustomHomeTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"cell"];
    }
    
    cell.progressView.hidden = false;
    
    cell.progressViewWidthConstraint.constant = M328_HOME_SCREEN_ROW_HEIGHT-20;
    cell.imgViewWidthConstraint.constant = M328_HOME_SCREEN_ROW_HEIGHT;
    
    [cell setSelectionStyle: UITableViewCellSelectionStyleNone];
    
    cell.subdialView.hidden = YES;
    
    typeM328ActivityDisplay calibrationType = (typeM328ActivityDisplay)[TDM328WatchSettingsUserDefaults displaySubDial];
    typeM329SecondHandOperation calibrationTypeTravel = (typeM329SecondHandOperation)[TDM329WatchSettingsUserDefaults PB4DisplayFunction];
    typeM329PB4DisplayFunction PB4TypeTravel = (typeM329PB4DisplayFunction)[TDM329WatchSettingsUserDefaults PB4DisplayFunction];
    timexDatalinkWatchStyle existingStyle = [iDevicesUtil getActiveWatchProfileStyle];
    
    NSDictionary *dict = [tableInfoArray objectAtIndex:indexPath.row];
    if (indexPath.row == 0) {
        //Steps
        [self setStepsDataToCell:cell withDictionary:dict];
        if (calibrationType == M328_STEPS_PERC_GOAL && existingStyle == timexDatalinkWatchStyle_IQ)
            cell.subdialView.hidden = NO;
        if (calibrationTypeTravel == M329_DISPLAY_STEPS && existingStyle == timexDatalinkWatchStyle_IQTravel)
        {
            cell.subdialView.hidden = NO;
            cell.subdialImg.image = [UIImage imageNamed:@"TravelSecondMain"];
        }
        else if (PB4TypeTravel == STEPS_PERC_GOAL_PB4 && existingStyle == timexDatalinkWatchStyle_IQTravel)
        {
            cell.subdialView.hidden = NO;
            cell.subdialImg.image = [UIImage imageNamed:@"TravelPB4"];
        }
        
    } else if (indexPath.row == 1) {
        //Distance
        [self setDistanceDataToCell:cell withDictionary:dict];
        
        if (calibrationType == M328_DISTANCE_PERC_GOAL && existingStyle == timexDatalinkWatchStyle_IQ)
            cell.subdialView.hidden = NO;
        if (calibrationTypeTravel == M329_DISPLAY_DISTANCE && existingStyle == timexDatalinkWatchStyle_IQTravel)
        {
            cell.subdialView.hidden = NO;
            cell.subdialImg.image = [UIImage imageNamed:@"TravelSecondMain"];
        }
        else if (PB4TypeTravel == DISTANCE_PERC_GOAL_PB4 && existingStyle == timexDatalinkWatchStyle_IQTravel)
        {
            cell.subdialView.hidden = NO;
            cell.subdialImg.image = [UIImage imageNamed:@"TravelPB4"];
        }
        
    } else if (indexPath.row == 2) {
        // Calories
        [self setCaloriesDataToCell:cell withDictionary:dict];
        
        if (calibrationType == M328_CALORIES_PERC_GOAL && existingStyle == timexDatalinkWatchStyle_IQ)
        {
            cell.subdialView.hidden = NO;
            cell.subdialImg.image = [UIImage imageNamed:@"TravelSecondMain"];
        }
        
    } else {
        // Time
        [self setTimeDataToCell:cell withDictionary:dict];
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    cell.separatorInset = UIEdgeInsetsZero;
    cell.layoutMargins = UIEdgeInsetsZero;
    
    return cell;
}

- (void)setStepsDataToCell:(TDCustomHomeTableViewCell *)cell withDictionary:(NSDictionary *)dict {
    NSString * imgName = [dict objectForKey:@"imagename"];
    NSInteger goals = [[dict objectForKey:@"goals"] integerValue];
    NSString *stepsStr = [dict objectForKey:@"actual"];
    double percentage = [[dict objectForKey:@"percentage"] doubleValue];
    
    UIColor *color = [iDevicesUtil getActivityColorBasedOnPercentage: percentage andType:@"steps"];
    
    [cell.cellImgView setImage:[[UIImage imageNamed:imgName] imageWithTint: color]];
    [cell.progressView setProgressColor:color];
    [cell.progressView setProgressStrokeColor:color];
    [cell.progressView setValue:(percentage > 100)?100:percentage];
    cell.titleLabel.attributedText = [self getAttributedStrWithText:[NSString stringWithFormat:@"%@ ",stepsStr] formatStr:[NSString stringWithFormat:@"%@\n%@ ", NSLocalizedString(@"steps", nil), NSLocalizedString(@"Goal", nil)] highlightedFormatStr:[NSString stringWithFormat:@"%ld",(long)goals]];

}

- (void)setDistanceDataToCell:(TDCustomHomeTableViewCell *)cell withDictionary:(NSDictionary *)dict{
    NSString * imgName = [dict objectForKey:@"imagename"];
    double goals = [[dict objectForKey:@"goals"] doubleValue];
    double percentage = [[dict objectForKey:@"percentage"] doubleValue];
    double actual = [[dict objectForKey:@"actual"] doubleValue];
    
    UIColor *color = [iDevicesUtil getActivityColorBasedOnPercentage: percentage andType:@"distance"];
    [cell.cellImgView setImage:[[UIImage imageNamed: imgName] imageWithTint: color]];
    [cell.progressView setProgressColor:color];
    [cell.progressView setProgressStrokeColor:color];
    [cell.progressView setValue:(percentage > 100)?100:percentage];
    cell.titleLabel.attributedText = [self getAttributedStrWithText:[NSString stringWithFormat:@"%.2f",actual] formatStr:[NSString stringWithFormat:@" %@\n%@ ",(![iDevicesUtil isMetricSystem])?NSLocalizedString(@"miles", nil):NSLocalizedString(@"km", nil), NSLocalizedString(@"Goal", nil)] highlightedFormatStr:[NSString stringWithFormat:@"%.2f",goals]];
    
}
- (void) align:(UIView *) handView withValue:(int)selectedValue {
    
    CGFloat angleInDegrees = selectedValue * (DEGREES/M328_SubdialHandRows);
    
    CGFloat angleInRadians = angleInDegrees * (M_PI / 180);
    
    [UIView animateWithDuration:0.3 animations:^{
        handView.transform = CGAffineTransformRotate(CGAffineTransformIdentity, angleInRadians);
    }];
    
    //    CABasicAnimation *imageRotation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    //    imageRotation.fromValue = [NSNumber numberWithDouble:(((0 * (DEGREES/120))*M_PI)/ + 180)];
    //    imageRotation.toValue = [NSNumber numberWithDouble:(((selectedValue * (DEGREES/120))*M_PI)/ + 180)];
    //
    //    imageRotation.duration = 0.0;
    //
    //    imageRotation.removedOnCompletion = NO;
    //    imageRotation.autoreverses = NO;
    //    imageRotation.fillMode = kCAFillModeForwards;
    //
    //    handImgView.layer.anchorPoint = CGPointMake(0.5, 0.5);
    //    [handImgView layoutIfNeeded];
    //    [handImgView.layer addAnimation:imageRotation forKey:@"imageRotation"];
}

- (void)setCaloriesDataToCell:(TDCustomHomeTableViewCell *)cell withDictionary:(NSDictionary *)dict{
    NSString * imgName = [dict objectForKey:@"imagename"];
    NSInteger goals = [[dict objectForKey:@"goals"] integerValue];
    NSString *calStr = [dict objectForKey:@"actual"];
    double caloriesFloat = [calStr doubleValue];
    double currentData = caloriesFloat;
    
   
    double percentage = [[dict objectForKey:@"percentage"] doubleValue];
     UIColor *color = [iDevicesUtil getActivityColorBasedOnPercentage: percentage andType:@"calories"];
    [cell.cellImgView setImage:[[UIImage imageNamed: imgName] imageWithTint:color ]];
    [cell.progressView setProgressColor:color];
    [cell.progressView setProgressStrokeColor:color];
    [cell.progressView setValue:(percentage > 100)?100:percentage];
    
    cell.titleLabel.attributedText = [self getAttributedStrWithText:[NSString stringWithFormat: @"%ld ", (long)currentData] formatStr:[NSString stringWithFormat:@"%@\n%@ ", (![iDevicesUtil isMetricSystem])?NSLocalizedString(@"Cal", nil):NSLocalizedString(@"kcal", nil), NSLocalizedString(@"Goal", nil)] highlightedFormatStr:[NSString stringWithFormat:@"%ld",(long)goals]];
    //    cell.subdialView.hidden = YES;
}

- (void)setTimeDataToCell:(TDCustomHomeTableViewCell *)cell withDictionary:(NSDictionary *)dict{
    NSString * imgName = [dict objectForKey:@"imagename"];
    NSString  *goalsStr = [dict objectForKey:@"goals"];
    NSString *timeStr = [dict objectForKey:@"actual"];
    double percentage = [[dict objectForKey:@"percentage"] doubleValue];
    
    UIColor *color = [iDevicesUtil getActivityColorBasedOnPercentage: percentage andType:@"sleep"];
    [cell.cellImgView setImage:[[UIImage imageNamed: imgName] imageWithTint: [iDevicesUtil getActivityColorBasedOnPercentage: percentage andType:@"sleep"]]];
    [cell.progressView setProgressColor:color];
    [cell.progressView setProgressStrokeColor:color];
    [cell.progressView setValue:(percentage > 100)?100:percentage];
    cell.titleLabel.attributedText = [self getAttributedStrWithText:timeStr formatStr:[NSString stringWithFormat:@" %@\n%@ ",NSLocalizedString(@"hrs", nil), NSLocalizedString(@"Goal", nil)] highlightedFormatStr:goalsStr];
    //    cell.subdialView.hidden = YES;
}

- (NSAttributedString *)getAttributedStrWithText:(NSString *)textStr formatStr:(NSString *)formatStr highlightedFormatStr:(NSString *)highlightedFormatStr {
    
    UIFont *textFont = [UIFont fontWithName:[iDevicesUtil getAppWideFontName] size:M328_HOME_SCREEN_TITLE_LABEL_FONT_SIZE];
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:textFont, NSFontAttributeName, [UIColor blackColor],NSForegroundColorAttributeName, nil];
    NSMutableAttributedString *textAtrStr = [[NSMutableAttributedString alloc] initWithString:textStr attributes:dict];
    
    UIFont *formatFont = [UIFont fontWithName: [iDevicesUtil getAppWideFontName] size: M328_HOME_SCREEN_FORMAT_STRING_FONT_SIZE];
    NSDictionary *atrsDict = [NSDictionary dictionaryWithObjectsAndKeys:formatFont, NSFontAttributeName, UIColorFromRGB(COLOR_DEFAULT_TIMEX_FONT),NSForegroundColorAttributeName, nil];
    NSAttributedString *formatAtrStr = [[NSAttributedString alloc] initWithString:formatStr attributes:atrsDict];
    [textAtrStr appendAttributedString:formatAtrStr];
    
    UIFont *highLighttedFormatFont = [UIFont fontWithName: [iDevicesUtil getAppWideBoldFontName] size: M328_HOME_SCREEN_FORMAT_STRING_FONT_SIZE];
    NSDictionary *highatrsDict = [NSDictionary dictionaryWithObjectsAndKeys:highLighttedFormatFont, NSFontAttributeName, UIColorFromRGB(COLOR_DEFAULT_TIMEX_FONT),NSForegroundColorAttributeName, nil];
    NSAttributedString *highformatAtrStr = [[NSAttributedString alloc] initWithString:highlightedFormatStr attributes:highatrsDict];
    [textAtrStr appendAttributedString:highformatAtrStr];
    
    return textAtrStr;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath: (NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.row == 0 || indexPath.row == 1 || indexPath.row == 2) {
        StepsViewController *stepsVC = [[StepsViewController alloc] initWithNibName:@"StepsViewController" bundle:nil selectedDate:_dateSelected];
        stepsVC.selectedRow = indexPath.row;
        stepsVC.caller = self;
        [self.navigationController pushViewController:stepsVC animated:YES];
    } else if (indexPath.row == 3) {
        SleepHistoryViewController *sleepVC = [[SleepHistoryViewController alloc] initWithNibName:@"SleepHistoryViewController" bundle:nil selectedDate:_dateSelected];
        sleepVC.caller = self;
        [self.navigationController pushViewController:sleepVC animated:YES];
    }
}

#pragma mark
#pragma mark Customize CalenderSelectionView
- (void)customizeCalenderSelectionView {
    UIFont *font = [UIFont fontWithName: [iDevicesUtil getAppWideBoldFontName] size: M328_HOME_SCREEN_CALENDER_VIEW_FONT_SIZE];
    
    // Left btn
    [_leftBtn setTitleColor:UIColorFromRGB(MEDIUM_GRAY_COLOR) forState:UIControlStateNormal];
    _leftBtn.titleLabel.font = font;
    
    // Center btn
    [_centerBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    _centerBtn.titleLabel.font = font;
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, _centerBtn.frame.size.height-1.5, [UIScreen mainScreen].bounds.size.width/3, 1.5)];
    lineView.backgroundColor = [UIColor blackColor];
    [_centerBtn addSubview:lineView];
    
    // Right Btn
    [_rightBtn setTitleColor:UIColorFromRGB(MEDIUM_GRAY_COLOR) forState:UIControlStateNormal];
    _rightBtn.titleLabel.font = font;
}


//- (IBAction)clickedOnDateBtn:(UIButton *)sender {
//    if (sender == _leftBtn) {
//        [existingPtr clickedOnPreviousButton];
//    } else if (sender == _centerBtn) {
//
//    } else {
//        [existingPtr clickedOnNextButton];
//    }
//}


- (IBAction)clickedOnDateBtn:(UIButton *)sender {
    
    NSDate *dateTosend = nil;
    NSString *datestr = sender.titleLabel.text;
    
    if ([datestr isEqualToString:NSLocalizedString(@"TODAY",nil)]) {
        
        dateTosend = [iDevicesUtil todayDateAtMidnight];
    }
    else if ([datestr isEqualToString:NSLocalizedString(@"YESTERDAY",nil)]) {
        
        dateTosend = [self getPreviousDate:[iDevicesUtil todayDateAtMidnight] WithMultiplier:1];
    }
    else
    {
        dateTosend = [self getDatefromStr:datestr];
    }
    
    [self updateDateScroll:dateTosend];
}

-(NSDate *)getDatefromStr:(NSString *)datestr
{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"MM/dd/yyyy"];
    NSDate *dt = [df dateFromString:datestr];
    return dt;
}

-(NSString *)getStrFromDate:(NSDate *)date
{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"MM/dd/yyyy"];
    NSString *dtstr = [df stringFromDate:date];
    return dtstr;
}


- (void)updateDateScroll:(NSDate *)date {
    date = [iDevicesUtil onlyDateFormat:date];
    if (([date compare:_minDate] == NSOrderedSame || [date compare:_minDate] == NSOrderedDescending) && ([date compare:_maxDate] == NSOrderedSame || [date compare:_maxDate] == NSOrderedAscending)) {
        NSDate *yesterday = [self getPreviousDate:[iDevicesUtil todayDateAtMidnight] WithMultiplier:1];
        NSDate *daybeforeyesterday = [self getPreviousDate:[iDevicesUtil todayDateAtMidnight] WithMultiplier:2];
        _leftBtn.hidden = NO;
        _rightBtn.hidden = NO;
        if (date != nil && [self compareDateOnly:date AndEndDate:_minDate] == NSOrderedSame) {
            _leftBtn.hidden = YES;
        }
        if (date != nil && [self compareDateOnly:date AndEndDate:_maxDate] == NSOrderedSame) {
            _rightBtn.hidden = YES;
        }
        if([self compareDateOnly:date AndEndDate:[iDevicesUtil todayDateAtMidnight]] == NSOrderedSame) //today
        {
            _rightBtn.hidden = YES;
            [_leftBtn setTitle:NSLocalizedString(@"YESTERDAY",nil) forState:UIControlStateNormal];
            [_centerBtn setTitle:NSLocalizedString(@"TODAY",nil) forState:UIControlStateNormal];
        }
        else if([self compareDateOnly:date AndEndDate:yesterday] == NSOrderedSame) //YESTERDAY
        {
            
            [_leftBtn setTitle:[self getStrFromDate:[self getPreviousDate:yesterday WithMultiplier:1]] forState:UIControlStateNormal];
            [_rightBtn setTitle:NSLocalizedString(@"TODAY",nil) forState:UIControlStateNormal];
            [_centerBtn setTitle:NSLocalizedString(@"YESTERDAY",nil) forState:UIControlStateNormal];
            
        }
        else if([self compareDateOnly:date AndEndDate:daybeforeyesterday] == NSOrderedSame) {
            
            [_leftBtn setTitle:[self getStrFromDate:[self getPreviousDate:daybeforeyesterday WithMultiplier:1]] forState:UIControlStateNormal];
            [_rightBtn setTitle:NSLocalizedString(@"YESTERDAY",nil) forState:UIControlStateNormal];
            [_centerBtn setTitle:[self getStrFromDate:daybeforeyesterday] forState:UIControlStateNormal];
        } else {
            [_leftBtn setTitle:[self getStrFromDate:[self getPreviousDate:date WithMultiplier:1]] forState:UIControlStateNormal];
            [_centerBtn setTitle:[self getStrFromDate: date] forState:UIControlStateNormal];
            [_rightBtn setTitle:[self getStrFromDate:[self getNextDate:date WithMultiplier:1]] forState:UIControlStateNormal];
        }
        _dateSelected = date;
        [self setSeletedDateForCalendarButton];
        
        [self initializeWorkoutsArray];
    } else {
        [appDelegate showAlertWithTitle:nil Message:NSLocalizedString(@"No data to display",nil) andButtonTitle:NSLocalizedString(@"Ok",nil)];
    }
}

- (NSComparisonResult)compareDateOnly:(NSDate *)firstDate AndEndDate:(NSDate *)secondDate {
    NSUInteger dateFlags = NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay;
    NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *selfComponents = [gregorianCalendar components:dateFlags fromDate:firstDate];
    NSDate *selfDateOnly = [gregorianCalendar dateFromComponents:selfComponents];
    
    NSDateComponents *otherCompents = [gregorianCalendar components:dateFlags fromDate:secondDate];
    NSDate *otherDateOnly = [gregorianCalendar dateFromComponents:otherCompents];
    return [selfDateOnly compare:otherDateOnly];
}


-(NSDate *)getPreviousDate:(NSDate *)date WithMultiplier:(NSInteger)multiplier
{
    NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
    dayComponent.day = -multiplier;
    
    NSCalendar *theCalendar = [NSCalendar currentCalendar];
    NSDate *previousDay = [theCalendar dateByAddingComponents:dayComponent toDate:date options:0];
    return previousDay;
}

- (NSDate *)getNextDate:(NSDate *)date WithMultiplier:(NSInteger)multiplier
{
    NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
    dayComponent.day = multiplier;
    
    NSCalendar *theCalendar = [NSCalendar currentCalendar];
    NSDate *nextDay = [theCalendar dateByAddingComponents:dayComponent toDate:date options:0];
    return nextDay;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

-(void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"SyncDataFinished" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}


#pragma mark Orientation
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return UIInterfaceOrientationIsPortrait(interfaceOrientation);
}

//- (void)viewDidLayoutSubviews {
//    [super viewDidLayoutSubviews];
//}

@end
