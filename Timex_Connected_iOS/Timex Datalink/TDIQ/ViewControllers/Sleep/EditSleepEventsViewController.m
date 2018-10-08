//
//  EditSleepEventsViewController.m
//  timex
//
//  Created by Raghu on 10/04/17.
//  Copyright © 2017 iDevices, LLC. All rights reserved.
//

#import "EditSleepEventsViewController.h"
#import "iDevicesUtil.h"
#import "TDDefines.h"
#import <QuartzCore/QuartzCore.h>
#import "SleepEventsModal.h"
#import "DBManager.h"
#import "DBModule.h"
#import "NSManagedObject+Helper.h"

@interface EditSleepEventsViewController ()

@property (strong, nonatomic) IBOutlet UILabel *sleepLengthLabel;
@property (strong, nonatomic) IBOutlet UILabel *startTimeDateLabel;
@property (strong, nonatomic) IBOutlet UILabel *startTimelabel;
@property (strong, nonatomic) IBOutlet UILabel *endTimeLabel;
@property (strong, nonatomic) IBOutlet UIDatePicker *startTimePickerView;
@property (strong, nonatomic) IBOutlet UILabel *endTimeDateLabel;
@property (strong, nonatomic) IBOutlet UIDatePicker *endTimePickerView;
@property (strong, nonatomic) IBOutlet UISegmentedControl *startTimeSegment;
@property (strong, nonatomic) IBOutlet UISegmentedControl *endTimeSegment;

@end

@implementation EditSleepEventsViewController
{
    DBSleepEvents *currentSleep;
    NSDateFormatter *formatter;
    
    NSDate *maxDate;
    NSDate *minDate;
}

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil andCurrentSleep:(DBSleepEvents *) sleep
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    currentSleep = sleep;
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.title = [NSLocalizedString(@"EDIT SLEEP",nil) uppercaseString];
    NSDictionary * navBarTitleTextAttributes =  @{NSFontAttributeName : [UIFont fontWithName:[iDevicesUtil getAppWideBoldFontName] size:APP_HEADER_FONT_SIZE] };
    self.navigationController.navigationBar.titleTextAttributes = navBarTitleTextAttributes;
    
    [_startTimelabel setBackgroundColor:UIColorFromRGB(VERY_LIGHT_GRAY_COLOR)];
    [_endTimeLabel setBackgroundColor:UIColorFromRGB(VERY_LIGHT_GRAY_COLOR)];
    
    UIButton *backBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
    [backBtn setTitle:@"Cancel" forState:UIControlStateNormal];
    [backBtn setContentEdgeInsets:UIEdgeInsetsMake(0, 0, 0, -10)];
    [backBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [backBtn addTarget:self action:@selector(backButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barBtn = [[UIBarButtonItem alloc] initWithCustomView:backBtn];
    self.navigationItem.leftBarButtonItem = barBtn;
    
    UIButton *btn = [[UIButton alloc] init];
    [btn setTitle:@"Save" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [btn setContentEdgeInsets:UIEdgeInsetsMake(0, 0, 0, -10)];
    btn.frame = CGRectMake(0, 0, 40, 40);
    [btn addTarget:self action:@selector(rightBarButtonTouched) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *updateBtn = [[UIBarButtonItem alloc] initWithCustomView:btn];
    self.navigationItem.rightBarButtonItem = updateBtn;
    
    _startTimelabel.layer.borderColor = [[UIColor blackColor] colorWithAlphaComponent:0.15].CGColor;
    _endTimeLabel.layer.borderColor = [[UIColor blackColor] colorWithAlphaComponent:0.15].CGColor;
    
    
    [_sleepLengthLabel setText:[NSString stringWithFormat:@"Length %@",[iDevicesUtil convertMinutesToStringHHMMFormat:([currentSleep.duration doubleValue]*MINUTES_PER_HOUR)]]];
    
    NSLog(@"current sleep event = %@", currentSleep);
    
    [_startTimePickerView setDate:currentSleep.startDate];
    [_endTimePickerView setDate:currentSleep.endDate];
    
    formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"EEE MMM dd"];
    
    [_startTimeDateLabel setText:[formatter stringFromDate:currentSleep.startDate]];
    [_endTimeDateLabel setText:[formatter stringFromDate:currentSleep.endDate]];
    
    [self setMinMaxDates];
    
    [_startTimePickerView setMinimumDate:minDate];
    [_startTimePickerView setMaximumDate:maxDate];
    
    [_endTimePickerView setMinimumDate:minDate];
    [_endTimePickerView setMaximumDate:maxDate];
    
    [self setSegmentsSelectedIndex];
    
    [_startTimeSegment addTarget:self
                          action:@selector(startTimeSegmentAction:)
                forControlEvents:UIControlEventValueChanged];
    
    [_endTimeSegment addTarget:self
                        action:@selector(endTimeSegmentAction:)
              forControlEvents:UIControlEventValueChanged];

}

-(void)setSegmentsSelectedIndex
{
    NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    
    int startDateDay = (int)[[gregorianCalendar components:NSCalendarUnitDay fromDate:_startTimePickerView.date] day];
    int endDateDay = (int)[[gregorianCalendar components:NSCalendarUnitDay fromDate:_endTimePickerView.date] day];
    int minDateDay = (int)[[gregorianCalendar components:NSCalendarUnitDay fromDate:minDate] day];
    int maxDateDay = (int)[[gregorianCalendar components:NSCalendarUnitDay fromDate:maxDate] day];
    
    if (startDateDay == maxDateDay && startDateDay > minDateDay)
    {
        [_startTimeSegment setSelectedSegmentIndex:1];
    }
    else
    {
        [_startTimeSegment setSelectedSegmentIndex:0];
    }
    
    if (endDateDay == maxDateDay && endDateDay > minDateDay)
    {
        [_endTimeSegment setSelectedSegmentIndex:1];
    }
    else
    {
        [_endTimeSegment setSelectedSegmentIndex:0];
    }
}

-(void)setMinMaxDates
{
    NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    
    NSDateComponents *components1 = [gregorianCalendar components:NSCalendarUnitHour
                                                         fromDate:currentSleep.startDate];
    
    if ([components1 hour] >= 15)
    {
        
        NSDateComponents *components2 = [gregorianCalendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay
                                                             fromDate:currentSleep.startDate];
        [components2 setHour:15];
        [components2 setMinute:0];
        [components2 setSecond:0];
        
        minDate = [gregorianCalendar dateFromComponents:components2];
        
        [components2 setDay:[components2 day]+1];
        
        maxDate = [gregorianCalendar dateFromComponents:components2];
    }
    else
    {
        NSDateComponents *components2 = [gregorianCalendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay
                                                             fromDate:currentSleep.startDate];
        
        [components2 setHour:15];
        [components2 setMinute:0];
        [components2 setSecond:0];
        
        maxDate = [gregorianCalendar dateFromComponents:components2];
        
        [components2 setDay:[components2 day]-1];
        
        minDate = [gregorianCalendar dateFromComponents:components2];
        
        
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)startTimePickerValueChanged:(id)sender
{
    [self setSegmentsSelectedIndex];
    
    [_startTimeDateLabel setText:[formatter stringFromDate:_startTimePickerView.date]];
    [_sleepLengthLabel setText:[NSString stringWithFormat:@"Length %@",[iDevicesUtil convertMinutesToStringHHMMFormat:([_endTimePickerView.date timeIntervalSinceDate:_startTimePickerView.date]/60)]]];
}

- (IBAction)endTimePickerValueChanged:(id)sender
{
    [self setSegmentsSelectedIndex];
    
    [_endTimeDateLabel setText:[formatter stringFromDate:_endTimePickerView.date]];
    [_sleepLengthLabel setText:[NSString stringWithFormat:@"Length %@",[iDevicesUtil convertMinutesToStringHHMMFormat:([_endTimePickerView.date timeIntervalSinceDate:_startTimePickerView.date]/60)]]];
}

- (void)startTimeSegmentAction:(id)sender
{
    NSLog(@"startTimeSegmentAction");
    
    NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    
    NSDateComponents *components1 = [gregorianCalendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond
                                                         fromDate:_startTimePickerView.date];
    
    if (_startTimeSegment.selectedSegmentIndex == 0)
    {
        [components1 setDay:[components1 day]-1];
    }
    else
    {
        [components1 setDay:[components1 day]+1];
    }
    
    NSDate *newDate = [gregorianCalendar dateFromComponents:components1];
    if (_startTimeSegment.selectedSegmentIndex == 0)
    {
        if ([newDate timeIntervalSinceDate:minDate] < 0)
        {
            [_startTimePickerView setDate:minDate];
        }
        else
        {
            [_startTimePickerView setDate:newDate];
        }
    }
    
    else if (_startTimeSegment.selectedSegmentIndex == 1)
    {
        if ([maxDate timeIntervalSinceDate:newDate] < 0)
        {
            [_startTimePickerView setDate:maxDate];
        }
        else
        {
            [_startTimePickerView setDate:newDate];
        }
    }
    
    [self startTimePickerValueChanged:nil];
    
}

- (void)endTimeSegmentAction:(id)sender
{
    NSLog(@"endTimeSegmentAction");
    
    NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    
    NSDateComponents *components1 = [gregorianCalendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond
                                                         fromDate:_endTimePickerView.date];
    
    if (_endTimeSegment.selectedSegmentIndex == 0)
    {
        [components1 setDay:[components1 day]-1];
    }
    else
    {
        [components1 setDay:[components1 day]+1];
    }
    
    NSDate *newDate = [gregorianCalendar dateFromComponents:components1];
    if (_endTimeSegment.selectedSegmentIndex == 0)
    {
        if ([newDate timeIntervalSinceDate:minDate] < 0)
        {
            [_endTimePickerView setDate:minDate];
        }
        else
        {
            [_endTimePickerView setDate:newDate];
        }
    }
    
    else if (_endTimeSegment.selectedSegmentIndex == 1)
    {
        if ([maxDate timeIntervalSinceDate:newDate] < 0)
        {
            [_endTimePickerView setDate:maxDate];
        }
        else
        {
            [_endTimePickerView setDate:newDate];
        }
    }
    
    
    [self endTimePickerValueChanged:nil];
}

-(BOOL)isValidData
{
    NSTimeInterval sleepDuration = [_endTimePickerView.date timeIntervalSinceDate:_startTimePickerView.date];
    /// End time of event should not be less than start time
    if (sleepDuration < 0)
    {
        UIAlertView *alertview = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"Sleep event end time cannot less than to its start time", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
        [alertview show];
        
        return NO;
    }
    /// Minimum sleep event time is 15 minutes
    if (sleepDuration < 15*60)
    {
        UIAlertView *alertview = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"Minimum sleep event duration should be 15 minutes", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
        [alertview show];
        
        return NO;
    }
    
    if (sleepDuration >= 24*60*60)
    {
        UIAlertView *alertview = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"Sleep event duration cannot more than 23 hours and 59 mins", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
        [alertview show];
        
        return NO;
    }
    
    // The end time cannot be moved past the time of the last data sync.
    NSDate * lastSyncDate = (NSDate *)[[NSUserDefaults standardUserDefaults] objectForKey:kLastActivityTrackerSyncSyncDate];
    if (lastSyncDate != nil && [lastSyncDate timeIntervalSinceDate:_endTimePickerView.date]<0)
    {
        UIAlertView *alertview = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"Sleep event end time cannot be more than last sync time", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
        [alertview show];
        
        return NO;
    }
    
    if(![self isActigraphyDataPresentOnDate:_startTimePickerView.date])
    {
        UIAlertView *alertview = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"No actigrapghy data present in that start time", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
        [alertview show];
        return NO;
    }
    
    if(![self isActigraphyDataPresentOnDate:_endTimePickerView.date])
    {
        UIAlertView *alertview = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"No actigrapghy data present in that end time", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
        [alertview show];
        
        return NO;
    }
    
    return YES;
    
}

-(BOOL)isActigraphyDataPresentOnDate:(NSDate *)date
{
    // Event times cannot be set to any value where there is no underlying actigraphy data present
    NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    
    NSDateComponents *components1 = [gregorianCalendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay
                                                         fromDate:date];
    
    NSDate *startDate = [gregorianCalendar dateFromComponents:components1]; // Get only year/month/day
    
    DBActivity *activity = (DBActivity*)[[DBModule sharedInstance]getEntity:@"DBActivity" columnName:@"date" value:startDate];
    
    if (activity != nil)
    {
        NSDateComponents *components2 = [gregorianCalendar components:NSCalendarUnitHour | NSCalendarUnitMinute fromDate:_startTimePickerView.date];
        
        int hour = (int)[components2 hour];
        int minute = (int)[components2 minute];
        
        
        int index = (((hour*60)+minute)/2) - 1;
        NSString *st = [[activity segments] substringWithRange:NSMakeRange(index, 1)];
        
        if ([st isEqualToString:@"F"])
        {
            return NO;
        }
        else
        {
            return YES;
        }
    }
    else
    {
        return NO;
    }
}

- (void) backButtonTapped
{
    [self.navigationController popViewControllerAnimated:YES];
}

/**
 * Called when save button is tapped.
 */
- (void)rightBarButtonTouched
{
    if ([self isValidData])
    {
        BOOL isSaved = [self saveEditedSleepEvent];
        
        if (isSaved)
        {
            UIAlertView *alertview = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Success", nil) message:NSLocalizedString(@"Sleep Event edited succcessfully", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
            [alertview show];
            
            [self checkForCrossedEvents];
        }
        else
        {
            UIAlertView *alertview = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"Failed to save edited sleep event", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
            [alertview show];
            return;
        }
        
        [self backButtonTapped];
    }
}

-(BOOL)saveEditedSleepEvent
{
    NSLog(@"saving edited sleep event");
    NSNumber *previousDuration = currentSleep.duration;
    
    if (currentSleep.startDateEndDateString == nil)
    {
        currentSleep.startDateEndDateString = [self getUniqueValueFromStartDate:currentSleep.startDate endDate:currentSleep.endDate];
    }
    currentSleep.startDate = _startTimePickerView.date;
    currentSleep.endDate = _endTimePickerView.date;
    
    if (![[NSCalendar currentCalendar] isDate:currentSleep.startDate inSameDayAsDate:currentSleep.endDate])
        currentSleep.twoDaysEvent = @0;
    else
        currentSleep.twoDaysEvent = @1;
    
    NSNumber *currentDuration = [NSNumber numberWithDouble:((double)[_endTimePickerView.date timeIntervalSinceDate:_startTimePickerView.date]/3600)];
    currentSleep.duration =currentDuration ;
    
    currentSleep.isEdited = [NSString stringWithFormat:@"%d", YES];
    
    DBActivity *activity = (DBActivity *)[[DBModule sharedInstance] getEntity:@"DBActivity" columnName:@"date" value:currentSleep.date];
   
    activity.sleep = [NSNumber numberWithDouble:([activity.sleep doubleValue] - [previousDuration doubleValue] + [currentDuration doubleValue])];
    
    
    [[DBModule sharedInstance] saveContext];
    return YES;
    
}

-(NSString *)getUniqueValueFromStartDate:(NSDate *)startDate endDate:(NSDate *)endDate
{
    return [NSString stringWithFormat:@"%@\t\t%@", startDate, endDate];
}

-(void)checkForCrossedEvents
{
    NSLog(@"checking for crossed events");
    
    NSLog(@"current sleep event after edit = %@", currentSleep);
    
    NSMutableArray *sleepDBArray = [[[DBModule sharedInstance] getSortedArrayFor:@"DBSleepEvents" predicate:nil keyString:@"endDate" isAscending:NO] mutableCopy];
    sleepDBArray = [self getOnlyValidEventsFromArray:sleepDBArray];
    
    [sleepDBArray removeObject:currentSleep];
    
    for (DBSleepEvents *sleepEvent in sleepDBArray)
    {
        if ([currentSleep.endDate compare:sleepEvent.startDate] == NSOrderedDescending &&
            ([currentSleep.startDate compare:sleepEvent.startDate] == NSOrderedAscending || [currentSleep.startDate compare:sleepEvent.startDate] == NSOrderedSame)
            )
        {
            NSLog(@"deleted event is %@", sleepEvent);
            [self deleteSleepEvent:sleepEvent];
        }
        
        else if ([currentSleep.startDate compare:sleepEvent.endDate] == NSOrderedAscending &&
                 ([currentSleep.endDate compare:sleepEvent.endDate] == NSOrderedDescending || [currentSleep.endDate compare:sleepEvent.endDate] == NSOrderedSame)
                 )
        {
            NSLog(@"deleted event is %@", sleepEvent);
            [self deleteSleepEvent:sleepEvent];
        }
    }
}


- (void)deleteSleepEvent:(DBSleepEvents *)sleepEvent
{
    sleepEvent.eventValid = @"0";
    DBActivity *activity = (DBActivity *)[[DBModule sharedInstance] getEntity:@"DBActivity" columnName:@"date" value:sleepEvent.date];
    if ([activity.sleep doubleValue] <= [sleepEvent.duration doubleValue]) {
        activity.sleep = [NSNumber numberWithDouble:0.0];
    } else {
        activity.sleep = [NSNumber numberWithDouble:([activity.sleep doubleValue] - [sleepEvent.duration doubleValue])];
    }
    [[DBModule sharedInstance] saveContext];
}

- (NSMutableArray *)getOnlyValidEventsFromArray:(NSArray *)array {
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

-(BOOL)sameCharsInString:(NSString *)str {
    if ([str length] == 0 ) return YES;
    int length = (int)[str length];
    return [[str stringByReplacingOccurrencesOfString:@"F" withString:@""] length] == length ? NO : YES;
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
