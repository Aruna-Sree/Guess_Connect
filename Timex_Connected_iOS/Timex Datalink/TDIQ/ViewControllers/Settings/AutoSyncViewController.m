//
//  AutoSyncViewController.m
//  timex
//
//  Created by Nick Graff on 9/6/16.
//  Copyright © 2016 iDevices, LLC. All rights reserved.
//

#import "AutoSyncViewController.h"

#import "TDDefines.h"
#import "iDevicesUtil.h"
#import "AlarmTableViewCell.h"
#import "TDM328WatchSettingsUserDefaults.h"
#import "TDM329WatchSettingsUserDefaults.h"
#import "TDAppDelegate.h"
#import "SettingsSubViewController.h"
#import "TDWatchProfile.h"

@interface AutoSyncViewController ()
{
//    NSDateFormatter *timeFormat;
    TDAppDelegate *appDelegate;
    CustomTabbar *customTabbar;
}
@end

@implementation AutoSyncViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Auto Sync", nil);
    appDelegate = (TDAppDelegate *)[[UIApplication sharedApplication] delegate];

    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))  {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    NSDictionary * navBarTitleTextAttributes =  @{NSFontAttributeName : [UIFont fontWithName:[iDevicesUtil getAppWideBoldFontName] size:APP_HEADER_FONT_SIZE] };
    self.navigationController.navigationBar.titleTextAttributes = navBarTitleTextAttributes;
    UIButton *backBtn = [iDevicesUtil getBackButton];
    [backBtn addTarget:self action:@selector(backButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barBtn = [[UIBarButtonItem alloc] initWithCustomView:backBtn];
    self.navigationItem.leftBarButtonItem = barBtn;
    
    UILabel* infoLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, ScreenWidth-16, 200)];
    infoLbl.backgroundColor = [UIColor clearColor];
    infoLbl.textColor = [UIColor lightGrayColor];
    infoLbl.tag = 1;
    infoLbl.numberOfLines = 0;
    [infoLbl sizeToFit];
    infoLbl.font = topLbl.font = [UIFont fontWithName: [iDevicesUtil getAppWideFontName] size: M328_SLIDE_MENU_CELL_FONT_SIZE];

    
    UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(8, 0, ScreenWidth-16, 210)];
    [footer addSubview:infoLbl];
    syncTableView.tableFooterView = footer;
    
    syncTableView.separatorInset = UIEdgeInsetsZero;
    [syncTableView setLayoutMargins:UIEdgeInsetsZero];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self addCustomTabbar];
    [syncTableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}
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
    
    [customTabbar updateLastLblText];
}
#pragma mark - TableView Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return M328_SLIDE_MENU_CELL_HEIGHT;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
//    if (([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)?![TDM329WatchSettingsUserDefaults autoSyncMode]:![TDM328WatchSettingsUserDefaults autoSyncMode])
//    {
//        return 1;
//    }
    return 2; // return 5 //to put 4 auto sync times
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 1;
}
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIView *footerview = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, 1)];
    [footerview setBackgroundColor:[UIColor whiteColor]];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0.5, ScreenWidth, 0.5)];
    label.backgroundColor = [UIColor lightGrayColor];
    [footerview addSubview:label];
    return footerview;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"cellID";
    
    AlarmTableViewCell *cell = (AlarmTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (!cell)
    {
        [tableView registerNib:[UINib nibWithNibName:@"AlarmTableViewCell" bundle:nil] forCellReuseIdentifier:cellIdentifier];
        cell = (AlarmTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    }
    cell.userInteractionEnabled = YES;

    cell.alarmTextLbl.textColor = [UIColor blackColor];

    if (indexPath.row == 0)
    {
        cell.onOffSwitch.on = ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)?[TDM329WatchSettingsUserDefaults autoSyncMode]:[TDM328WatchSettingsUserDefaults autoSyncMode];
        [cell.onOffSwitch addTarget:self action:@selector(changeSwitch:) forControlEvents:UIControlEventValueChanged];
        cell.editButton.hidden = YES;
        
        UILabel *infoLbl = (UILabel *)[(UIView *)syncTableView.tableFooterView viewWithTag:1];
        if (([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)?[TDM329WatchSettingsUserDefaults autoSyncMode]:[TDM328WatchSettingsUserDefaults autoSyncMode])
        {
            infoLbl.text = NSLocalizedString(@"Syncing of activity data and time will occur daily at the time above.\n\nWatch and phone need to be near each other (within bluetooth range) for Auto Sync to occur. Manual sync can be done at any time.", nil);
            cell.alarmTextLbl.text = NSLocalizedString(@"ON", nil);
        }
        else
        {
            infoLbl.text = NSLocalizedString(@"To update time and activity data, syncing your watch is required. To extend battery life, a daily sync is suggested.", nil);
            cell.alarmTextLbl.text = NSLocalizedString(@"OFF", nil);
        }
        CGRect frame = infoLbl.frame;
        frame.size.height = 200;
        frame.size.width = ScreenWidth - 16;
        infoLbl.frame = frame;
        [infoLbl sizeToFit];
    }
    else
    {
        cell.onOffSwitch.hidden = YES;
        [cell.editButton addTarget:self
                            action:@selector(editTime:)
                  forControlEvents:UIControlEventTouchUpInside];
        cell.editButton.tag = indexPath.row;
        int hour = 0;
        int min = 0;
        NSString *time;
        if (indexPath.row == 1) {
            hour = ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)?(int)[TDM329WatchSettingsUserDefaults autoSyncTimes1_Hour]:(int)[TDM328WatchSettingsUserDefaults autoSyncTimes1_Hour];
            min = ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)?(int)[TDM329WatchSettingsUserDefaults autoSyncTimes1_Minute]:(int)[TDM328WatchSettingsUserDefaults autoSyncTimes1_Minute];
        } else if (indexPath.row == 2) {
            hour = ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)?(int)[TDM329WatchSettingsUserDefaults autoSyncTimes2_Hour]:(int)[TDM328WatchSettingsUserDefaults autoSyncTimes2_Hour];
            min = ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)?(int)[TDM329WatchSettingsUserDefaults autoSyncTimes2_Minute]:(int)[TDM328WatchSettingsUserDefaults autoSyncTimes2_Minute];
        } else if (indexPath.row == 3) {
            hour = ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)?(int)[TDM329WatchSettingsUserDefaults autoSyncTimes3_Hour]:(int)[TDM328WatchSettingsUserDefaults autoSyncTimes3_Hour];
            min = ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)?(int)[TDM329WatchSettingsUserDefaults autoSyncTimes3_Minute]:(int)[TDM328WatchSettingsUserDefaults autoSyncTimes3_Minute];
        } else {
            hour = ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)?(int)[TDM329WatchSettingsUserDefaults autoSyncTimes4_Hour]:(int)[TDM328WatchSettingsUserDefaults autoSyncTimes4_Hour];
            min = ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)?(int)[TDM329WatchSettingsUserDefaults autoSyncTimes4_Minute]:(int)[TDM328WatchSettingsUserDefaults autoSyncTimes4_Minute];
        }
        
        if ([iDevicesUtil isSystemTimeFormat24Hr]) {
            NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
            NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            [timeFormat setLocale:locale];
            [timeFormat setDateFormat:@"HH:mm"];
            time =  [timeFormat stringFromDate:[timeFormat dateFromString:[NSString stringWithFormat:@"%d:%d", hour, min]]];
        } else {
            NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
            [timeFormat setDateFormat:@"h:mm a"];
            if (hour >= 12)
                time = [timeFormat stringFromDate:[timeFormat dateFromString:[NSString stringWithFormat:@"%d:%d pm", hour - 12, min]]];
            else
            {
                time = [timeFormat stringFromDate:[timeFormat dateFromString:[NSString stringWithFormat:@"%d:%d am", hour, min]]];
            }
        }
        
        cell.alarmTextLbl.text = [NSString stringWithFormat:NSLocalizedString(@"Sync Time %d:  %@", nil), indexPath.row, time];
        if (([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)?![TDM329WatchSettingsUserDefaults autoSyncMode]:![TDM328WatchSettingsUserDefaults autoSyncMode])
        {
            cell.editButton.hidden = YES;
            cell.userInteractionEnabled = NO;
            cell.alarmTextLbl.textColor = [UIColor lightGrayColor];
        } else {
            cell.editButton.hidden = NO;
        }
    }
    
    cell.alarmTextLbl.font = [UIFont fontWithName: [iDevicesUtil getAppWideMediumFontName] size: M328_GOALS_SCREEN_GOALS_FONT_SIZE];
    [cell.editButton.titleLabel setFont:[UIFont fontWithName: [iDevicesUtil getAppWideFontName] size: M328_SLIDE_MENU_CELL_FONT_SIZE]];
    [cell.editButton setTitle:NSLocalizedString(cell.editButton.currentTitle, nil) forState:UIControlStateNormal];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.separatorInset = UIEdgeInsetsZero;
    cell.layoutMargins = UIEdgeInsetsZero;
    
    return cell;
}

#pragma mark - Button Actions
- (void) backButtonTapped
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) changeSwitch:(id)sender
{
    AlarmTableViewCell *cell1 = [syncTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)?[TDM329WatchSettingsUserDefaults setAutoSynchMode:cell1.onOffSwitch.on]:[TDM328WatchSettingsUserDefaults setAutoSynchMode:cell1.onOffSwitch.on];
    [appDelegate.customTabbar syncNeeded];
    [syncTableView reloadData];
}

- (void) editTime:(UIButton *)sender
{
    SettingsSubViewController *vc = [[SettingsSubViewController alloc] initWithNibName:@"SettingsSubViewController" bundle:nil withScreenType:Setting_SyncTime];
    vc.syncNumber = sender.tag;
    [self.navigationController pushViewController:vc animated:YES];
}

@end
