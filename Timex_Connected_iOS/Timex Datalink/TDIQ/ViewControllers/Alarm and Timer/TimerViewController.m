//
//  TimerViewController.m
//  Timex
//
//  Created by Raghu on 08/07/16.
//  Copyright © 2016 innominds. All rights reserved.
//

#import "TimerViewController.h"
#import "iDevicesUtil.h"
#import "SideMenuViewController.h"
#import "MFSideMenuContainerViewController.h"
#import "TDAppDelegate.h"
#import "PCCOMM_Utils.h"
#import "CalibrationClass.h"
#import "TDDeviceManager.h"
#import "TDM328WatchSettingsUserDefaults.h"
#import "OTLogUtil.h"
#import "MBProgressHUD.h"

static  NSTimer* countTimer;

@interface TimerViewController ()
{
    PCCOMM_Cmd_t command;
    CustomTabbar *customTabbar;
    BOOL isStartTimer;
    MBProgressHUD           * HUD;
}
@end

@implementation TimerViewController
{
    int hours;
    int minutes;
    int seconds;
    BLEManager*   bleManager;
//    NSTimer *labelUpdateTimer;
    typeM328TimerDefinitions timerSettings;
    NSInteger mReconnectAttempts;
    uint8_t timerNum;
    TDAppDelegate *appDelegate;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    appDelegate = (TDAppDelegate *)[UIApplication sharedApplication].delegate;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [_pickerView selectRow:15 inComponent:2 animated:NO];
    });
    
    if (ScreenHeight <= 480) {
        startBtnBottomConstraint.constant = 80;
        stopBtnBottomConstraint.constant = 80;
    } else if (IS_IPAD) {
        startBtnBottomConstraint.constant = 220;
        stopBtnBottomConstraint.constant = 220;
        startbtnWidthConstraint.constant = 350;
        stopbtnWidthConstraint.constant = 350;
    }

    headerLbl.textAlignment = NSTextAlignmentCenter;
    headerLbl.textColor = [UIColor grayColor];
    headerLbl.font = [UIFont fontWithName: [iDevicesUtil getAppWideBoldFontName] size: M328_TABLE_HEADER_FONT_SIZE];
    headerLbl.text = NSLocalizedString(@"Set Timer",nil);
    headerLbl.backgroundColor =  UIColorFromRGB(M328_TABLEVIEW_HEADER_GRAY_COLOR);
    
    UIBarButtonItem *slideMenuItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"menu"] style:UIBarButtonItemStylePlain target:self action:@selector(slideMenuTapped)];
    self.navigationItem.leftBarButtonItem = slideMenuItem;
    self.navigationItem.titleView = [iDevicesUtil getNavigationTitle];
    
    [self.syncAndStartBtn setTitle:NSLocalizedString(self.syncAndStartBtn.currentTitle, nil) forState:UIControlStateNormal];
    self.syncAndStartBtn.layer.cornerRadius = 25;
    self.syncAndStopBtn.layer.cornerRadius = 25;
    [self.syncAndStartBtn setBackgroundColor:UIColorFromRGB(AppColorRed)];
    [self.syncAndStopBtn setBackgroundColor:UIColorFromRGB(AppColorRed)];
    [appDelegate setTimerTempAfterLaunchingApp];
    NSLog(@"TimerStatus :%ld",(long)[TDM328WatchSettingsUserDefaults timerStatus]); // 0 -- off, 1 -- running
    if ([TDM328WatchSettingsUserDefaults timerTemp] > 0 && [TDM328WatchSettingsUserDefaults timerStatus] == 1) { // Timer status 1 indicates running and 0 indicates off
        [self updateCountDownLabel];
        [self timerStarted:YES];
    } else {
        [self timerStarted:NO];
    }
    //initialize arrays
    timerNum = 0;
    hoursArray = [[NSMutableArray alloc] init];
    minsArray = [[NSMutableArray alloc] init];
    secsArray = [[NSMutableArray alloc] init];
    NSString *strVal = nil;
    
    for(int i=0; i<60; i++) {
        if (i < 10){
            strVal = [NSString stringWithFormat:@"0%d", i];
        }else{
            strVal = [NSString stringWithFormat:@"%d", i];
        }
        
        if (i < 24)
        {
            [hoursArray addObject:strVal];
        }
        [minsArray addObject:strVal];
        [secsArray addObject:strVal];
    }
    
    bleManager = [[TDDeviceManager sharedInstance] getBleManager];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    TDAppDelegate *appdel = (TDAppDelegate *)[[UIApplication sharedApplication] delegate];
    appdel.customTabbar.autoSyncAllowed = NO;
}
-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:YES];
    TDAppDelegate *appdel = (TDAppDelegate *)[[UIApplication sharedApplication] delegate];
    appdel.customTabbar.autoSyncAllowed = YES;
}
- (void)didReceiveMemoryWarning {
    OTLog([NSString stringWithFormat:@"Recived Memory Warning  in %@ ",NSStringFromClass([self class])]);
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

-(void)slideMenuTapped {
    SideMenuViewController *leftController = (SideMenuViewController *)((MFSideMenuContainerViewController *)appDelegate.window.rootViewController).leftMenuViewController;
    if (leftController == nil) {
        leftController = [[SideMenuViewController alloc] init];
        ((MFSideMenuContainerViewController *)appDelegate.window.rootViewController).leftMenuViewController = leftController;
    }
}

#pragma mark
#pragma mark Sync and Start/Stop timer
- (void)checkForBleBeforeSync {
    if ([bleManager isBLESupported] && [bleManager isBLEAvailable]) {
        NSString *msg;
        if (isStartTimer) {
            msg = NSLocalizedString(@"Put your watch into sync mode to activate your timer",nil);
        } else {
            msg = NSLocalizedString(@"Put your watch into sync mode to cancel your active timer",nil);
        }
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Guess Connect",nil) message:msg delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel",nil) otherButtonTitles:NSLocalizedString(@"OK",nil), nil];
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
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"OK", nil)]) {
        [self startSync];
    } else {

    }
}
- (void)startSync {
    if (isStartTimer) {
        self.syncAndStartBtn.userInteractionEnabled = FALSE;
        [self syncWatch:PC_RX_CMD_M328_SET_COUNTDOWN_TIMER];
    } else {
        self.syncAndStopBtn.userInteractionEnabled = FALSE;
        [self syncWatch:PC_RX_CMD_M328_STOP_COUNTDOWN_TIMER];
    }
}
- (IBAction)syncAndStartAction:(id)sender
{
    isStartTimer = YES;
    [self checkForBleBeforeSync];
}


- (IBAction)syncAndStopAction:(id)sender
{
    isStartTimer = NO;
    [self checkForBleBeforeSync];
}

-(void)syncWatch:(PCCOMM_Cmd_t)cmd {
    command = cmd;
    customTabbar = appDelegate.customTabbar;
    [((MFSideMenuContainerViewController *)appDelegate.window.rootViewController) setPanMode:MFSideMenuPanModeNone]; // Diable pan mode
    [self reconnectToDevice];
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
                self.syncAndStartBtn.userInteractionEnabled = true;
                self.syncAndStopBtn.userInteractionEnabled = true;
                [customTabbar timerSyncFinished];
                [appDelegate showAlertWithTitle:NSLocalizedString(@"Error",nil) Message:NSLocalizedString(@"Device Not Connected",nil) andButtonTitle:NSLocalizedString(@"OK",nil)];
                [((MFSideMenuContainerViewController *)appDelegate.window.rootViewController) setPanMode:MFSideMenuPanModeDefault]; // enable pan mode
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
-(void) successfullyConnectedToDevice:(NSNotification*)notification {
    [HUD hide:YES];
    customTabbar.lastSynLbl.text=[NSString stringWithFormat: @"%@", NSLocalizedString(@"Syncing...", nil)];
    if (command == PC_RX_CMD_M328_SET_COUNTDOWN_TIMER){
        timerSettings.TimerHour = (int)[[hoursArray objectAtIndex:[_pickerView selectedRowInComponent:0]]integerValue];
        timerSettings.TimerMinute = (int)[[minsArray objectAtIndex:[_pickerView selectedRowInComponent:1]]integerValue];
        timerSettings.TimerSeconds = (int)[[secsArray objectAtIndex:[_pickerView selectedRowInComponent:2]]integerValue];
        timerSettings.TimerAction = M328_TIMER_STOPATEND;
        
        [self buildPCCOMMTimerMessage:PC_RX_CMD_M328_SET_COUNTDOWN_TIMER];
        [self buildPCCOMMTimerMessage:PC_RX_CMD_M328_START_COUNTDOWN_TIMER];
        
        hours = (int)[[hoursArray objectAtIndex:[_pickerView selectedRowInComponent:0]]integerValue];
        minutes = (int)[[minsArray objectAtIndex:[_pickerView selectedRowInComponent:1]]integerValue];
        seconds = (int)[[secsArray objectAtIndex:[_pickerView selectedRowInComponent:2]]integerValue];
        [TDM328WatchSettingsUserDefaults setTimerTemp:(hours*3600)+(minutes *60)+seconds];
        self.countdownLbl.text = [NSString stringWithFormat:@"%02i:%02i:%02i", hours, minutes, seconds];
        [self timerStarted:YES];
    } else if(command == PC_RX_CMD_M328_STOP_COUNTDOWN_TIMER){
        [self buildPCCOMMTimerMessage:PC_RX_CMD_M328_STOP_COUNTDOWN_TIMER];
        [self timerStarted:NO];
    }
    [customTabbar timerSyncFinished];
    [self performSelector:@selector(exitSyncModeManually) withObject:nil afterDelay:0.2];
    [self removeObservers];
    [((MFSideMenuContainerViewController *)appDelegate.window.rootViewController) setPanMode:MFSideMenuPanModeDefault]; // enable pan mode
}

-(void)exitSyncModeManually
{
    // Logic here is to start and end the session if not present.
    // This will disconnect the watch.
    // Observe for notification on start of session
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(didStartFileAccessSession:) name:kTDM328SessionStartNotification object:nil];
    
    PeripheralDevice * timexDevice = [iDevicesUtil getConnectedTimexDevice];
    if(timexDevice)
    {
        [timexDevice startFileAccessSession];
    }
}

-(void)didStartFileAccessSession:(NSNotification*)notification
{
    // Remove observer.
    [[NSNotificationCenter defaultCenter]removeObserver:self name:kTDM328SessionStartNotification object:nil];
    
    PeripheralDevice * timexDevice = [iDevicesUtil getConnectedTimexDevice];
    if(timexDevice)
    {
        [timexDevice endFileAccessSession];
    }
}


- (void)timerStarted:(BOOL)start {
    if (start) {
        self.syncAndStopBtn.hidden = NO;
        self.syncAndStartBtn.hidden = YES;
        self.syncAndStartBtn.userInteractionEnabled = true;
        
        self.countdownLbl.hidden = NO;
        self.pickerView.hidden = YES;
        supportTextPickerView.hidden = YES;
        
        [self countdownTimerStart];
        [TDM328WatchSettingsUserDefaults setTimerStatus:M328_TIMER__RUN];
    } else {
        self.syncAndStopBtn.hidden = YES;
        self.syncAndStartBtn.hidden = NO;
        self.syncAndStopBtn.userInteractionEnabled = true;
        
        self.countdownLbl.hidden = YES;
        self.pickerView.hidden = NO;
        supportTextPickerView.hidden = NO;
        
        [countTimer invalidate];
        countTimer = nil;
        [TDM328WatchSettingsUserDefaults setTimerTemp:0];
        [TDM328WatchSettingsUserDefaults setTimerStatus:M328_TIMER_OFF];
    }
}
-(void)undiscoveredPeripheral:(NSNotification*)notification {
    OTLog(@"undiscoveredPeripheral");
    [HUD hide:YES];
    self.syncAndStartBtn.userInteractionEnabled = true;
    self.syncAndStopBtn.userInteractionEnabled = true;
    [customTabbar timerSyncFinished];
    
    [appDelegate showAlertWithTitle:NSLocalizedString(@"Error",nil) Message:NSLocalizedString(@"Device Not Connected",nil) andButtonTitle:NSLocalizedString(@"OK",nil)];
    [((MFSideMenuContainerViewController *)appDelegate.window.rootViewController) setPanMode:MFSideMenuPanModeDefault]; // enable pan mode
}
-(void) buildPCCOMMTimerMessage:(PCCOMM_Cmd_t)cmd {
    NSMutableData *data = nil;
    PCCOMMHeader_t header = //Initialize parameters that are the same for all messages
    {
        .linkAddress = 0xA5A5,
        .packetNumber = 0x00,
        .source = MSG_SOURCE_PC,
        .command = cmd,
        .information = 0x81,
        .reserved = 0x00
    };
    PCCOMMPacket_t packet;
    
    switch(cmd)
    {
        case PC_RX_CMD_M328_START_COUNTDOWN_TIMER:
        {
            header.packetLength = 0x02;
            packet.segment.payload.M328_startCountdownTimer.timerNumber = timerNum;
            packet.segment.payload.M328_startCountdownTimer.reserved = 0;
            break;
        }
        case PC_RX_CMD_M328_STOP_COUNTDOWN_TIMER:
        {
            header.packetLength = 0x02;
            packet.segment.payload.M328_stopCountdownTimer.timerNumber = timerNum;
            packet.segment.payload.M328_stopCountdownTimer.reserved = 0;
            break;
        }
        case PC_RX_CMD_M328_SET_COUNTDOWN_TIMER:
        {
            header.packetLength = 0x05;
            packet.segment.payload.M328_setCountdownTimer.hour = timerSettings.TimerHour;
            packet.segment.payload.M328_setCountdownTimer.minute = timerSettings.TimerMinute;
            packet.segment.payload.M328_setCountdownTimer.second = timerSettings.TimerSeconds;
            packet.segment.payload.M328_setCountdownTimer.action = timerSettings.TimerAction;
            packet.segment.payload.M328_setCountdownTimer.timerNumber = timerNum;
            
            break;
        }
        case PC_RX_CMD_M328_GET_COUNTDOWN_TIMER:
        {
            header.packetLength = 0x02;
            packet.segment.payload.M328_getCountdownTimer.timerNumber = timerNum;
            packet.segment.payload.M328_getCountdownTimer.reserved = 0;
            break;
        }
        default:
        {
            OTLog(@"Invalid PCCOMM Timer Command");
            return;
        }
    };
    
    packet.segment.header = header;
    PCCCalculateChecksum(&packet);
    data = [NSMutableData dataWithBytes:&packet length:header.packetLength + PCCOMM_OVERHEAD]; //Build packet with data and be sure to account for overhead
    
    [self sendTDLSDataPacket:data];
}
- (void) sendTDLSDataPacket:(NSData*)data {
    PeripheralDevice *peripheralDevice = [iDevicesUtil getConnectedTimexDevice];
    BLEPeripheral *blePeripheral = (BLEPeripheral *)peripheralDevice.peripheral;
    
    
    // ServiceProxy* service = [blePeripheral findService: [PeripheralDevice timexDatalinkServiceId]];
    CBPeripheral *peripheral = [blePeripheral cbPeripheral];
    CBService *service = [self findServiceWithUUID:[PeripheralDevice timexDatalinkServiceId] peripheral:peripheral];
    if(service == nil)
    {
        OTLog([NSString stringWithFormat:@"Couldn't find TDLS Service on %@", peripheral.name]);
    }
    
    NSData *chunk;
    CBCharacteristic *characteristic;
    switch((int)(ceil(((double)data.length)/PCCOMM_SUBPACKET_SIZE)))
    {
            //Determine how many characteristics the data spans and send it accordingly
        case 4:
        {
            chunk = [data subdataWithRange:NSMakeRange((3 * PCCOMM_SUBPACKET_SIZE), (MIN((data.length - (3 * PCCOMM_SUBPACKET_SIZE)),PCCOMM_SUBPACKET_SIZE)))];
            characteristic = [self findCharacteristicWithUUID:[CBUUID UUIDWithString:TDLS_DATA_IN_UUID4] service:service];
            if(characteristic == nil)
            {
                OTLog([NSString stringWithFormat:@"Couldn't find DATA_IN_4 Characteristic on %@", peripheral.name]);
            }
            
            [peripheral writeValue:chunk forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
            
            OTLog([NSString stringWithFormat:@"Wrote %lu bytes on Characteristic 4", (unsigned long)chunk.length]);
        }
        case 3:
        {
            chunk = [data subdataWithRange:NSMakeRange((2 * PCCOMM_SUBPACKET_SIZE), (MIN((data.length - (2 * PCCOMM_SUBPACKET_SIZE)),PCCOMM_SUBPACKET_SIZE)))];
            characteristic = [self findCharacteristicWithUUID:[CBUUID UUIDWithString:TDLS_DATA_IN_UUID3] service:service];
            if(characteristic == nil)
            {
                OTLog([NSString stringWithFormat:@"Couldn't find DATA_IN_3 Characteristic on %@", peripheral.name]);
            }
            
            [peripheral writeValue:chunk forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
            OTLog([NSString stringWithFormat:@"Wrote %lu bytes on Characteristic 3", (unsigned long)chunk.length]);
        }
        case 2:
        {
            chunk = [data subdataWithRange:NSMakeRange((1 * PCCOMM_SUBPACKET_SIZE), (MIN((data.length - (1 * PCCOMM_SUBPACKET_SIZE)),PCCOMM_SUBPACKET_SIZE)))];
            characteristic = [self findCharacteristicWithUUID:[CBUUID UUIDWithString:TDLS_DATA_IN_UUID2] service:service];
            if(characteristic == nil)
            {
                OTLog([NSString stringWithFormat:@"Couldn't find DATA_IN_2 Characteristic on %@", peripheral.name]);
            }
            
            [peripheral writeValue:chunk forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
            OTLog([NSString stringWithFormat:@"Wrote %lu bytes on Characteristic 2", (unsigned long)chunk.length]);
        }
        case 1:
        {
            chunk = [data subdataWithRange:NSMakeRange((0 * PCCOMM_SUBPACKET_SIZE), (MIN((data.length - (0 * PCCOMM_SUBPACKET_SIZE)),PCCOMM_SUBPACKET_SIZE)))];
            characteristic = [self findCharacteristicWithUUID:[CBUUID UUIDWithString:TDLS_DATA_IN_UUID1] service:service];
            if(characteristic == nil)
            {
                OTLog([NSString stringWithFormat:@"Couldn't find DATA_IN_2 Characteristic on %@", peripheral.name]);
            }
            
            [peripheral writeValue:chunk forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
            
            OTLog([NSString stringWithFormat:@"Wrote %lu bytes on Characteristic 1", (unsigned long)chunk.length]);
        }
    }
}

-(CBCharacteristic *) findCharacteristicWithUUID:(CBUUID *)UUID service:(CBService*)service
{
    for (CBCharacteristic *characteristic in service.characteristics)
    {
        if ([characteristic.UUID isEqual:UUID])
        {
            return characteristic;
        }
    }
    return nil; //Characteristic not found on this service
}
-(CBService *) findServiceWithUUID:(CBUUID *)UUID peripheral:(CBPeripheral *)peripheral
{
    for (CBService *service in peripheral.services)
    {
        if ([service.UUID isEqual:UUID])
        {
            return service;
        }
    }
    return nil; //Service not found on this peripheral
}


- (void)countdownTimerStart
{
    [countTimer invalidate];
    countTimer = nil;
    if (!countTimer) {
        countTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(countDown) userInfo:nil repeats:YES];
    }
}

- (void)invalidateTimer {
    [countTimer invalidate];
    countTimer = nil;
}
- (void)countDown {
    [TDM328WatchSettingsUserDefaults setTimerTemp:[TDM328WatchSettingsUserDefaults timerTemp] - 1];
    hours = (int)[TDM328WatchSettingsUserDefaults timerTemp]/3600;
    minutes = ([TDM328WatchSettingsUserDefaults timerTemp]/60) % 60;
    seconds = [TDM328WatchSettingsUserDefaults timerTemp] % 60;
    
    self.countdownLbl.text = [NSString stringWithFormat:@"%02i:%02i:%02i", hours, minutes, seconds];
    if ([TDM328WatchSettingsUserDefaults timerTemp] <= 0) {
        [TDM328WatchSettingsUserDefaults setTimerTemp:0];
        [countTimer invalidate];
        countTimer = nil;
        [self timerStarted:NO];
    }
}

-(void)updateCountDownLabel
{
    hours = (int)[TDM328WatchSettingsUserDefaults timerTemp]/3600;
    minutes = ([TDM328WatchSettingsUserDefaults timerTemp]/60) % 60;
    seconds = [TDM328WatchSettingsUserDefaults timerTemp] % 60;
    self.countdownLbl.text = [NSString stringWithFormat:@"%02i:%02i:%02i", hours, minutes, seconds];
    if ([TDM328WatchSettingsUserDefaults timerTemp] <= 0) {
        [self timerStarted:NO];
    }
}

#pragma mark
#pragma mark CustomTabbar
- (void)addCustomTabbar {
    customTabbar = appDelegate.customTabbar;
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

#pragma mark 
#pragma mark PickerView for dates
//Method to define how many columns/dials to show
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 3;
}


// Method to define the numberOfRows in a component using the array.
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent :(NSInteger)component
{
    if (pickerView.tag == 1) {
        return 1;
    }
    if (component==0)
    {
        return [hoursArray count];
    }
    else if (component==1)
    {
        return [minsArray count];
    }
    else
    {
        return [secsArray count];
    }
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(nullable UIView *)view {
    UILabel *textLbl = nil;
    if (view == nil) {
        view = [[UIView alloc] init];
        textLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth/3, 40)];
        textLbl.tag = 1;
        textLbl.textAlignment = NSTextAlignmentCenter;
        [view addSubview:textLbl];
    }
    if (textLbl == nil) {
        textLbl = (UILabel *)[view viewWithTag:1];
    }
    switch (component)
    {
        case 0:
            if (pickerView.tag == 1) {
                textLbl.text = [NSString stringWithFormat:@"              %@", NSLocalizedString(@"hour", nil)];
            } else {
                textLbl.text = [hoursArray objectAtIndex:row];
            }
            break;
        case 1:
            if (pickerView.tag == 1) {
                textLbl.text = [NSString stringWithFormat:@"            %@", NSLocalizedString(@"min", nil)];
            } else {
                textLbl.text = [minsArray objectAtIndex:row];
            }
            break;
        case 2:
            if (pickerView.tag == 1) {
                textLbl.text = [NSString stringWithFormat:@"            %@", NSLocalizedString(@"sec", nil)];
            } else {
                textLbl.text = [secsArray objectAtIndex:row];
            }
            break;
    }
    return view;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if ([_pickerView selectedRowInComponent:0] == 0 &&
        [_pickerView selectedRowInComponent:1] == 0 &&
        [_pickerView selectedRowInComponent:2] < 15)
    {
        [_pickerView selectRow:15 inComponent:2 animated:YES];
    }
}
//// Method to show the title of row for a component.
//- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
//{
//    switch (component)
//    {
//        case 0:
//            if (pickerView.tag == 1) {
//                return @"   hour";
//            } else {
//                return [NSString stringWithFormat:@"%@ %@",[hoursArray objectAtIndex:row],@"    "];
//            }
//            break;
//        case 1:
//            if (pickerView.tag == 1) {
//                return @"   min";
//            } else {
//                return [NSString stringWithFormat:@"%@ %@",[minsArray objectAtIndex:row],@"   "];
//            }
//            break;
//        case 2:
//            if (pickerView.tag == 1) {
//                return @"   sec";
//            } else {
//                return [NSString stringWithFormat:@"%@ %@",[secsArray objectAtIndex:row],@"   "];
//            }
//            break;
//    }
//    return nil;
//}
//
@end
