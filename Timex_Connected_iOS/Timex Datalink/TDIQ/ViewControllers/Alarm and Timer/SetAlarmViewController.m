//
//  SetAlarmViewController.m
//  Timex
//
//  Created by Aruna Kumari Yarra on 02/06/16.
//

#import "SetAlarmViewController.h"
#import "TDDefines.h"
#import "iDevicesUtil.h"
//#import "Alarm.h"
#import "TDAppDelegate.h"
#import "CustomTabbar.h"
#import "TDM328WatchSettingsUserDefaults.h"
#import "OTLogUtil.h"
#import "TDDeviceManager.h"
#import "MFSideMenuContainerViewController.h"
#import "SideMenuViewController.h"
#import "MBProgressHUD.h"

@interface SetAlarmViewController () {
    NSDate *currentAlarm;
    NSDateFormatter *dateFormatter;
    TDAppDelegate *appDelegate;
    MBProgressHUD * HUD;
    int mReconnectAttempts;
}

@end

@implementation SetAlarmViewController

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
    
    UIBarButtonItem *slideMenuItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"menu"] style:UIBarButtonItemStylePlain target:self action:@selector(slideMenuTapped)];
    self.navigationItem.leftBarButtonItem = slideMenuItem;
    
    self.navigationItem.titleView = [iDevicesUtil getNavigationTitle];
    
    if (IS_IPAD)  {
        btnWidthConstraint.constant = 350;
        btnBottomConstraint.constant = 220;
    }
    
    appDelegate = (TDAppDelegate *)[[UIApplication sharedApplication] delegate];
    // Add Notification Observers
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncFinished) name:@"SyncFinished" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncFailed) name:@"SyncFailed" object:nil];

    headerLbl.textColor = [UIColor grayColor];
    headerLbl.font = [UIFont fontWithName: [iDevicesUtil getAppWideBoldFontName] size: M328_TABLE_HEADER_FONT_SIZE];
    headerLbl.backgroundColor =  UIColorFromRGB(M328_TABLEVIEW_HEADER_GRAY_COLOR);
    
//      daysView.hidden = YES;
    [self checkForAlarmActiveOrNot];
    switchOnOff.on = [TDM328WatchSettingsUserDefaults alarmStatus];
    if (switchOnOff.on) {
        currentAlarm = [TDM328WatchSettingsUserDefaults userAlarm];
    }
    btnSetSync.hidden = true;
    
    timePicker.locale = [NSLocale currentLocale];
    dateFormatter = [[NSDateFormatter alloc]init];
    [dateFormatter setDateFormat:@"HH:mm"];
    alarmFrequencyPicker.hidden = YES;
    if (currentAlarm != nil) {
        timePicker.date = currentAlarm;
    }
    
    [headerLbl setText:NSLocalizedString(headerLbl.text, nil)];
    [alarmTitle setText:NSLocalizedString(alarmTitle.text, nil)];
    [timePicker addTarget: self action: @selector(timeChanged:) forControlEvents: UIControlEventValueChanged];
}

- (void)checkForAlarmActiveOrNot {
    NSLog(@"Curetnttime :%@ alarm Time:%@ status:%ld",[NSDate date], [TDM328WatchSettingsUserDefaults userAlarm], (long)[TDM328WatchSettingsUserDefaults alarmStatus]);
    if ((([[NSDate date] compare:[TDM328WatchSettingsUserDefaults userAlarm]] == NSOrderedSame || [[NSDate date] compare:[TDM328WatchSettingsUserDefaults userAlarm]] == NSOrderedDescending)) && ([TDM328WatchSettingsUserDefaults alarmStatus] == M328_ALARM_ARMED_1)) {// Setting alarm status manually to DISARMED when user sets alarm to "One shot" and alarm time is past than current time
        [TDM328WatchSettingsUserDefaults setAlarmStatus:M328_ALARM_DISARMED];
    }
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    appDelegate.customTabbar.autoSyncAllowed = NO;
}

- (void)confirmBtnTextChange:(BOOL)isSyncInProgress {
    if (isSyncInProgress)  {
        [btnSetSync setTitle:NSLocalizedString(@"ALARM SYNCED",nil) forState:UIControlStateNormal];
        [btnSetSync setBackgroundColor:UIColorFromRGB(MEDIUM_GRAY_COLOR)];
        btnSetSync.userInteractionEnabled = NO;
    } else {
        NSString *btnName = NSLocalizedString(@"SYNC AND SET",nil);
        if ([TDM328WatchSettingsUserDefaults alarmStatus] && ![switchOnOff isOn])
        {
            btnName = NSLocalizedString(@"SYNC AND CLEAR",nil);
        }
        [btnSetSync setTitle:btnName forState:UIControlStateNormal];
        [btnSetSync setBackgroundColor:UIColorFromRGB(AppColorRed)];
        btnSetSync.userInteractionEnabled = YES;
    }
}

- (void)customizeDayBtns:(UIButton *)btn {
    btn.layer.cornerRadius = btn.frame.size.width/2;
    btn.layer.borderWidth = 0.5;
    btn.layer.borderColor = UIColorFromRGB(MEDIUM_GRAY_COLOR).CGColor;
    btn.layer.masksToBounds = YES;
    
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btn setBackgroundImage:[iDevicesUtil imageFromColor:UIColorFromRGB(MEDIUM_GRAY_COLOR)] forState:UIControlStateNormal];
    
    [btn setTitleColor:UIColorFromRGB(AppColorRed) forState:UIControlStateSelected];
    [btn setBackgroundImage:[iDevicesUtil imageFromColor:[UIColor whiteColor]] forState:UIControlStateSelected];
}

- (void)didReceiveMemoryWarning {
     OTLog([NSString stringWithFormat:@"Recived Memory Warning  in %@ ",NSStringFromClass([self class])]);
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)clickedOnDayButton:(DayButton *)sender {
    if (sender.isSelected) {
        [(UIButton *)[daysView viewWithTag:sender.tag] setSelected:NO];
    } else {
        [sender setSelected:YES];
    }
}

- (void)slideMenuTapped {
    TDAppDelegate * delegate = (TDAppDelegate *)[UIApplication sharedApplication].delegate;
    SideMenuViewController *leftController = (SideMenuViewController *)((MFSideMenuContainerViewController *)delegate.window.rootViewController).leftMenuViewController;
    if (leftController == nil)
    {
        SideMenuViewController *leftController = [[SideMenuViewController alloc] init];
        ((MFSideMenuContainerViewController *)delegate.window.rootViewController).leftMenuViewController = leftController;
    }
}

- (IBAction)clickedOnSetSyncButton:(UIButton *)sender{
    if(sender.selected == false){
        [self clickedOnSaveBtn];
    }
    else{
        
    }
    
}

- (IBAction)clickedOnSwitch:(id)sender
{
    [self setSyncButton];
}

- (void)setSyncButton
{
    if(([switchOnOff isOn] && ![TDM328WatchSettingsUserDefaults alarmStatus]) ||
       (![switchOnOff isOn] && [TDM328WatchSettingsUserDefaults alarmStatus]) ||
       ((![switchOnOff isOn] && ![TDM328WatchSettingsUserDefaults alarmStatus]) && ([timePicker.date timeIntervalSinceNow] > 0)))
    {
        btnSetSync.hidden = false;
        [self confirmBtnTextChange:NO];
    }
    else
    {
        btnSetSync.hidden = YES;
    }
}

- (void)highlightSelectedDays {
    
    int alarmFrequency = (int)[TDM328WatchSettingsUserDefaults alarmFrequency];
    
    switch (alarmFrequency) {
            
        case M328_SUNDAY_ALARM:
           [(UIButton *)[daysView viewWithTag:9] setSelected:YES];
            break;
        case M328_MONDAY_ALARM:
             [(UIButton *)[daysView viewWithTag:3] setSelected:YES];
            break;
        case M328_TUESDAY_ALARM:
            [(UIButton *)[daysView viewWithTag:3] setSelected:YES];
            break;
        case M328_WEDNESDAY_ALARM:
            [(UIButton *)[daysView viewWithTag:3] setSelected:YES];
            break;
        case M328_THURSDAY_ALARM:
            [(UIButton *)[daysView viewWithTag:3] setSelected:YES];
            break;
        case M328_FRIDAY_ALARM:
            [(UIButton *)[daysView viewWithTag:3] setSelected:YES];
            break;
        case M328_SATURDAY_ALARM:
            [(UIButton *)[daysView viewWithTag:3] setSelected:YES];
            break;
        case M328_WEEKDAY_ALARM:
            [(UIButton *)[daysView viewWithTag:3] setSelected:YES];
            break;
        case M328_WEEKEND_ALARM:
            for (int i = 3; i < 8; i ++) {
                [(UIButton *)[daysView viewWithTag:i] setSelected:YES];
            }
            break;
        case M328_DAILY_ALARM:
            for (int i = 3; i < 10; i ++) {
                [(UIButton *)[daysView viewWithTag:i] setSelected:YES];
            }
            break;
        default:
            break;
    }
}
- (NSMutableArray *)getSelectedAlarmDays {
    NSMutableArray *daysArray = [[NSMutableArray alloc] init];
    NSMutableArray *selectedDays = [[NSMutableArray alloc] init];
    for (int i = 1; i < 8; i++) {
        if ([(UIButton *)[daysView viewWithTag:i] isSelected]) {
            [selectedDays addObject:[NSNumber numberWithInt:i]];
        }
    }
    
    if ([selectedDays containsObject:[NSNumber numberWithInt:Sunday]] &&[selectedDays containsObject:[NSNumber numberWithInt:Monday]] && [selectedDays containsObject:[NSNumber numberWithInt:Tuesday]] && [selectedDays containsObject:[NSNumber numberWithInt:WednesDay]] && [selectedDays containsObject:[NSNumber numberWithInt:Thursday]] && [selectedDays containsObject:[NSNumber numberWithInt:Friday]] && [selectedDays containsObject:[NSNumber numberWithInt:Saturday]]) {
        [selectedDays removeAllObjects];
        [daysArray addObject:[TDM328WatchSettingsUserDefaults getWeekDayName:M328_DAILY_ALARM]];
    }
    
    if ([selectedDays containsObject:[NSNumber numberWithInt:Sunday]] && [selectedDays containsObject:[NSNumber numberWithInt:Saturday]]) {
        [selectedDays removeObjectsInArray:[NSArray arrayWithObjects:[NSNumber numberWithInt:Sunday],[NSNumber numberWithInt:Saturday], nil]];
        [daysArray addObject:[TDM328WatchSettingsUserDefaults getWeekDayName:M328_WEEKEND_ALARM]];
    }
    
    if ([selectedDays containsObject:[NSNumber numberWithInt:Monday]] && [selectedDays containsObject:[NSNumber numberWithInt:Tuesday]] && [selectedDays containsObject:[NSNumber numberWithInt:WednesDay]] && [selectedDays containsObject:[NSNumber numberWithInt:Thursday]] && [selectedDays containsObject:[NSNumber numberWithInt:Friday]]) {
        [selectedDays removeObjectsInArray:[NSArray arrayWithObjects:[NSNumber numberWithInt:Monday],[NSNumber numberWithInt:Tuesday],[NSNumber numberWithInt:WednesDay],[NSNumber numberWithInt:Thursday],[NSNumber numberWithInt:Friday], nil]];
        [daysArray addObject:[TDM328WatchSettingsUserDefaults getWeekDayName:M328_WEEKDAY_ALARM]];
    }
    if (selectedDays.count > 0) {
        NSRange range = NSMakeRange(0, 0);
        if (selectedDays.count > 1 || daysArray.count > 0) {
           range = NSMakeRange(0, 3);
        }
        for (int i = 1; i < 8; i ++) {
            if ([selectedDays containsObject:[NSNumber numberWithInt:i]]) {
                if (range.length > 0) {
                    [daysArray addObject:[[TDM328WatchSettingsUserDefaults getWeekDayName:(typeM328AlarmFrequency)i] substringWithRange:range]];
                } else {
                    [daysArray addObject:[TDM328WatchSettingsUserDefaults getWeekDayName:(typeM328AlarmFrequency)i]];
                }
            }
        }
    }
    return daysArray;
}

- (void)clickedOnSaveBtn {
    [self checkForBleBeforeSync];
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"OK", nil)]) {
        [((MFSideMenuContainerViewController *)appDelegate.window.rootViewController) setPanMode:MFSideMenuPanModeNone]; // To disable the pan mode
        [self reconnectToDevice];
    } else {
    }
}

- (void)checkForBleBeforeSync {
    BLEManager *bleManager = [[TDDeviceManager sharedInstance] getBleManager];
    if ([bleManager isBLESupported] && [bleManager isBLEAvailable]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Guess Connect",nil) message:NSLocalizedString(@"Put your watch into sync mode to save alarm settings",nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel",nil) otherButtonTitles:NSLocalizedString(@"OK",nil), nil];
        [alert show];
    } else {
        NSString * title = NSLocalizedString(@"Bluetooth unavailable", nil);
        NSString * msg = nil;
        if (![bleManager isBLESupported]) {
            msg = NSLocalizedString(@"Bluetooth is not available on this device.", nil);
        } else if (![bleManager isBLEAvailable]) {
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

- (void)reconnectToDevice {
    //first, we need to CONNECT to the device again... and not just A device, but THE device
    NSString * deviceUUID = [[NSUserDefaults standardUserDefaults] objectForKey: kCONNECTED_DEVICE_UUID_PREF_NAME];
    if (deviceUUID != nil)
    {
        NSArray * adverts = [[TDDeviceManager sharedInstance] getAllConnectedAndAdvertisingDevices];
        NSUInteger idx = NSNotFound;
        idx = [adverts indexOfObjectPassingTest:
               ^ BOOL (PeripheralDevice* device, NSUInteger idx, BOOL *stop)
               {
                   return [device.peripheral.UUID.UUIDString isEqualToString: deviceUUID];
               }];
        
        if (idx != NSNotFound)
        {
            mReconnectAttempts = 0;
            PeripheralDevice * device = [adverts objectAtIndex: idx];
            if (device != NULL)
            {
                [self addObservers];
                if (HUD == nil) {
                    HUD = [[MBProgressHUD alloc] initWithView: self.navigationController.view];
                    [self.navigationController.view addSubview: HUD];
                }
                HUD.labelText = NSLocalizedString(@"Please Wait", nil);
                HUD.detailsLabelText = [NSString stringWithFormat: NSLocalizedString(@"Connecting to %@", nil), device.name == nil ? NSLocalizedString(@"Timex Watch", nil) : device.name];
                HUD.square = YES;
                [HUD show:YES];
                
                [self performSelector:@selector(connectDevice:) withObject:device afterDelay:3];
            }
        }
        else
        {
            mReconnectAttempts++;
            if (mReconnectAttempts > 30)
            {
                [HUD hide:YES];
                mReconnectAttempts = 0;
                [self confirmBtnTextChange:NO];
                [appDelegate showAlertWithTitle:NSLocalizedString(@"Error", nil) Message:NSLocalizedString(@"Device Not Connected", nil) andButtonTitle:NSLocalizedString(@"OK", nil)];
                [((MFSideMenuContainerViewController *)appDelegate.window.rootViewController) setPanMode:MFSideMenuPanModeDefault]; // Enable pan mode
            } else {
                if (HUD == nil) {
                    HUD = [[MBProgressHUD alloc] initWithView: self.navigationController.view];
                    [self.navigationController.view addSubview: HUD];
                }
                HUD.labelText = NSLocalizedString(@"Please Wait", nil);
                HUD.detailsLabelText = [NSString stringWithFormat: NSLocalizedString(@"Searching for your watch", nil)];
                HUD.square = YES;
                [HUD show:YES];
                [self performSelector:@selector(reconnectToDevice) withObject:nil afterDelay: 1.0];
            }
        }
    }
}

- (void)connectDevice:(PeripheralDevice *)device {
    [[TDDeviceManager sharedInstance] connect: device];
}

-(void)addObservers {
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(successfullyConnectedToDevice:) name: kPeripheralDeviceTimexDatalinkPrimaryCharacteristicDiscovered object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(undiscoveredPeripheral:) name:kBLEManagerUndiscoveredPeripheralNotification object:nil];
}
-(void)removeObservers {
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kPeripheralDeviceTimexDatalinkPrimaryCharacteristicDiscovered object: nil];
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kBLEManagerUndiscoveredPeripheralNotification object:nil];
}
- (void)saveAlarm {
    [TDM328WatchSettingsUserDefaults setUserAlarm:timePicker.date];
    NSArray * date = [[dateFormatter stringFromDate:timePicker.date] componentsSeparatedByString:@":"];
    [TDM328WatchSettingsUserDefaults setAlarmHour:[[date objectAtIndex:0]integerValue]];
    [TDM328WatchSettingsUserDefaults setAlarmMin:[[date objectAtIndex:1]integerValue]];
    if ([btnSetSync.titleLabel.text isEqualToString:NSLocalizedString(@"SYNC AND CLEAR",nil)]) {
        [TDM328WatchSettingsUserDefaults setAlarmStatus:M328_ALARM_DISARMED];
    } else {
        if ([switchOnOff isOn])
            [TDM328WatchSettingsUserDefaults setAlarmStatus:M328_ALARM_ARMED]; // setting sticky alarm (made this change to fix bug artf24984)
        else {
            [TDM328WatchSettingsUserDefaults setAlarmStatus:M328_ALARM_ARMED_1]; // setting one shot alarm (made this change to fix bug artf24984)
//            [TDM328WatchSettingsUserDefaults setAlarmStatus:M328_ALARM_DISARMED]; // Nick changed to this.
        }
    }

    [TDM328WatchSettingsUserDefaults setAlarmFrequency:M328_DAILY_ALARM];
}

- (void) successfullyConnectedToDevice:(NSNotification*)notification {
    [self saveAlarm];
    HUD.detailsLabelText = [NSString stringWithFormat: NSLocalizedString(@"Synchronizing data", nil)];
    [self removeObservers];
    [appDelegate.customTabbar goalsAndALramSyncStarted];
    [appDelegate.customTabbar successfullyConnectedToDevice:notification];
}
-(void)undiscoveredPeripheral:(NSNotification*)notification {
    [self removeObservers];
    [HUD hide:YES];
    [self confirmBtnTextChange:NO];
    [((MFSideMenuContainerViewController *)appDelegate.window.rootViewController) setPanMode:MFSideMenuPanModeDefault]; // enable pan mode
    [appDelegate showAlertWithTitle:NSLocalizedString(@"Error",nil) Message:NSLocalizedString(@"Device Not Connected",nil) andButtonTitle:NSLocalizedString(@"OK",nil)];
}
- (void)syncFinished {
    [self removeObservers];
    [HUD hide:YES];
    [self confirmBtnTextChange:YES];
    [((MFSideMenuContainerViewController *)appDelegate.window.rootViewController) setPanMode:MFSideMenuPanModeDefault]; // enable pan mode
}
- (void)syncFailed {
    [self removeObservers];
    [HUD hide:YES];
    [self confirmBtnTextChange:NO];
    [((MFSideMenuContainerViewController *)appDelegate.window.rootViewController) setPanMode:MFSideMenuPanModeDefault]; // enable pan mode
}

-(void) dealloc {
    [self removeObservers];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"SyncFinished" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"SyncFailed" object:nil];
    
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
#pragma mark
#pragma mark Height and Weight PickerViewDelegate and Datasource
//- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
//    return 1;
//}
//
//- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
//       return alarmFrequencyArray.count;
//}
//- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
//    return [alarmFrequencyArray objectAtIndex:row];
//}
//
//- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
//    
//}

- (IBAction)timeChanged:(id)sender
{
    if (currentAlarm == nil)
    {
        [self setSyncButton];
    }
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    appDelegate.customTabbar.autoSyncAllowed = YES;
}
@end
