//
//  SetDailyGoalsViewController.m
//  Timex
//
//  Created by kpasupuleti on 5/4/16.
//

#import "SetDailyGoalsViewController.h"
#import "TDDefines.h"
#import "UIImage+Tint.h"
#import "iDevicesUtil.h"
//#import "Goals.h"
#import "TDAppDelegate.h"
#import "MFSideMenuContainerViewController.h"
#import "SideMenuViewController.h"
#import "TDAppDelegate.h"
#import "TDM328WatchSettingsUserDefaults.h"
#import "TDDeviceManager.h"
#import "TDWatchProfile.h"
#import "MBProgressHUD.h"

@interface SetDailyGoalsViewController () {

    NSMutableDictionary *goal;
    NSMutableArray *goalInfoArray;
    TDAppDelegate *app;
    UIView *tableFooterView;
    enum GoalType type;
    NSString * goalType;
    NSInteger mReconnectAttempts;
    MBProgressHUD           * HUD;
    UIButton *confirmBtn;
    BOOL isTextfieldEditing;
}

@end

@implementation SetDailyGoalsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setViewProperties];
    // Add Notification Observers
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncFinished) name:@"SyncFinished" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncFailed) name:@"SyncFailed" object:nil];
    if (IS_IPAD) {
        goalsTypeViewWidthConstraint.constant = M328_CONFIRM_CHANGE_BUTTON_WIDTH;
    } else {
        goalsTypeViewWidthConstraint.constant = 290;
    }
    
    [headerLbl setText:NSLocalizedString(headerLbl.text, nil)];
    
    [activeBtn setTitle:NSLocalizedString(activeBtn.currentTitle, nil) forState:UIControlStateNormal];
    [prettyActiveBtn setTitle:NSLocalizedString(prettyActiveBtn.currentTitle, nil) forState:UIControlStateNormal];
    [veryActiveBtn setTitle:NSLocalizedString(veryActiveBtn.currentTitle, nil) forState:UIControlStateNormal];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    app.customTabbar.autoSyncAllowed = NO;
}
-(void)setViewProperties {
    app = (TDAppDelegate *)[[UIApplication sharedApplication] delegate];
    type = (GoalType)[TDM328WatchSettingsUserDefaults goalType];
    [activeBtn setImage:[[UIImage imageNamed:@"active"] imageWithTint: UIColorFromRGB(AppColorRed)] forState:UIControlStateNormal];
    [prettyActiveBtn setImage:[[UIImage imageNamed:@"prettyactive"] imageWithTint: UIColorFromRGB(AppColorRed)] forState:UIControlStateNormal];
    [veryActiveBtn setImage:[[UIImage imageNamed:@"veryactive"] imageWithTint: UIColorFromRGB(AppColorRed)] forState:UIControlStateNormal];
    [self initialiseGoalsArray];
    [self updateUIAsPerGoalsType];

    
    self.navigationItem.titleView = [iDevicesUtil getNavigationTitle];
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))  {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    self.view.backgroundColor = UIColorFromRGB(COLOR_DEFAULT_TIMEX_WHITE);
    tblView.backgroundColor = UIColorFromRGB(COLOR_DEFAULT_TIMEX_WHITE);
    
    UIBarButtonItem *slideMenuItem=[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"menu"] style:UIBarButtonItemStylePlain target:self action:@selector(slideMenuTapped)];
    self.navigationItem.leftBarButtonItem=slideMenuItem;
    [self headerAndFooterUI];
    [self slideMenuTapped];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapOnTableView)];
    [tblView addGestureRecognizer:tap];
    
}

- (void)updateUIAsPerGoalsType {
    if (type == Normal) {
        prettyActiveBtn.alpha = 0.5;
        veryActiveBtn.alpha = 0.5;
        goalType = @"1";
    } else if (type == Pretty) {
        activeBtn.alpha = 0.5;
        veryActiveBtn.alpha = 0.5;
        goalType = @"2";
    } else if (type == Very) {
        prettyActiveBtn.alpha = 0.5;
        activeBtn.alpha = 0.5;
        goalType = @"3";
    } else {
        prettyActiveBtn.alpha = 0.5;
        activeBtn.alpha = 0.5;
        veryActiveBtn.alpha = 0.5;
        goalType = @"4";
    }
    NSDictionary *goalDict = [NSDictionary dictionaryWithObjectsAndKeys:
                              [goalInfoArray objectAtIndex:0],STEPS,
                              [goalInfoArray objectAtIndex:1],DISTANCE,
                              [goalInfoArray objectAtIndex:2],CALORIES,
                              [goalInfoArray objectAtIndex:3],SLEEPTIME,nil];
    [[NSUserDefaults standardUserDefaults] setValue:goalDict forKey:goalType]; // temp goals: edited values
}

- (void)initialiseGoalsArray {
    [goalInfoArray removeAllObjects];
    goalInfoArray = nil;
    goalInfoArray = [[NSMutableArray alloc] init];
    if (type == Normal || type == Pretty || type == Very) {
        goal = [[app getGoalsForType:type] mutableCopy];
    } else {
        if (goalType != nil && [[NSUserDefaults standardUserDefaults] valueForKey:goalType] != nil) {
            goal = [[NSUserDefaults standardUserDefaults] valueForKey:goalType];
        } else {
            goal = [[NSUserDefaults standardUserDefaults] valueForKey: [iDevicesUtil getGoalTypeStringFormat:type]];
        }
        if (goal == nil) {
            goal = [app getGoalsForType:type];
        }
    }
    goalInfoArray = [[NSMutableArray alloc] initWithObjects:[goal objectForKey:STEPS],[goal objectForKey:DISTANCE],[goal objectForKey:CALORIES],[goal objectForKey:SLEEPTIME], nil];
    [tblView reloadData];
}

- (void)headerAndFooterUI {
    headerLbl.textColor = [UIColor grayColor];
    headerLbl.font = [UIFont fontWithName: [iDevicesUtil getAppWideBoldFontName] size: M328_TABLE_HEADER_FONT_SIZE];
    headerLbl.backgroundColor =  UIColorFromRGB(M328_TABLEVIEW_HEADER_GRAY_COLOR);
    
    confirmBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    confirmBtn.frame = CGRectMake(([[UIScreen mainScreen] bounds].size.width - M328_CONFIRM_CHANGE_BUTTON_WIDTH)/2, 20, M328_CONFIRM_CHANGE_BUTTON_WIDTH, 50);
    [confirmBtn setTitle:NSLocalizedString(@"SAVE AND SYNC",nil) forState:UIControlStateNormal];
    [confirmBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [confirmBtn.titleLabel setFont:[UIFont fontWithName: [iDevicesUtil getAppWideMediumFontName] size: M328_FOOTER_BUTTON_FONT_SIZE]];
    [confirmBtn addTarget:self action:@selector(confirmChange) forControlEvents:UIControlEventTouchUpInside];
    [confirmBtn setBackgroundColor:UIColorFromRGB(AppColorRed)];
    confirmBtn.layer.cornerRadius = 25;
    confirmBtn.layer.masksToBounds = YES;
    
    tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tblView.frame.size.width, 70)];
    [tableFooterView addSubview:confirmBtn];
}


- (IBAction)clickedOnGoalTypeBtns:(UIButton *)sender {
    [self.view endEditing:NO];
    tblView.tableFooterView = tableFooterView;
    prettyActiveBtn.alpha = 1;
    veryActiveBtn.alpha = 1;
    activeBtn.alpha = 1;
    
    if (sender == activeBtn) {
        type = Normal;
        prettyActiveBtn.alpha = 0.5;
        veryActiveBtn.alpha = 0.5;
        goalType = @"1";
    } else if (sender == prettyActiveBtn) {
        type = Pretty;
        activeBtn.alpha = 0.5;
        veryActiveBtn.alpha = 0.5;
        goalType = @"2";
    } else {
        type = Very;
        prettyActiveBtn.alpha = 0.5;
        activeBtn.alpha = 0.5;
        goalType = @"3";
    }
    [self initialiseGoalsArray];
    
    NSDictionary *goalDict = [NSDictionary dictionaryWithObjectsAndKeys:
                              [goalInfoArray objectAtIndex:0],STEPS,
                              [goalInfoArray objectAtIndex:1],DISTANCE,
                              [goalInfoArray objectAtIndex:2],CALORIES,
                              [goalInfoArray objectAtIndex:3],SLEEPTIME,nil];
    [[NSUserDefaults standardUserDefaults] setValue:goalDict forKey:goalType];
    
    [self confirmBtnTextChange:NO];
}

- (void)confirmChange {
    [self.view endEditing:NO];
    [self checkForBleBeforeSync];
}

- (void)checkForBleBeforeSync {
    BLEManager *bleManager = [[TDDeviceManager sharedInstance] getBleManager];
    if ([bleManager isBLESupported] && [bleManager isBLEAvailable]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Guess Connect",nil) message:NSLocalizedString(@"Put your watch into sync mode to save your daily goals",nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel",nil) otherButtonTitles:NSLocalizedString(@"OK",nil), nil];
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
    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"OK",nil)]) {
        [((MFSideMenuContainerViewController *)app.window.rootViewController) setPanMode:MFSideMenuPanModeNone]; // To disable the pan mode
        [self reconnectToDevice];
    } else {
        
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
                [app showAlertWithTitle:NSLocalizedString(@"Error",nil) Message:NSLocalizedString(@"Device Not Connected",nil) andButtonTitle:NSLocalizedString(@"OK",nil)];
                [((MFSideMenuContainerViewController *)app.window.rootViewController) setPanMode:MFSideMenuPanModeDefault]; // Enable pan mode
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
- (void)confirmBtnTextChange:(BOOL)isSyncInProgress {
    if (isSyncInProgress) {
        [confirmBtn setTitle:NSLocalizedString(@"GOALS SYNCED",nil) forState:UIControlStateNormal];
        [confirmBtn setBackgroundColor:UIColorFromRGB(MEDIUM_GRAY_COLOR)];
        confirmBtn.userInteractionEnabled = NO;
//        tblView.userInteractionEnabled = NO;
//        goalsTypeView.userInteractionEnabled = NO;
    } else {
        [confirmBtn setTitle:NSLocalizedString(@"SAVE AND SYNC",nil) forState:UIControlStateNormal];
        [confirmBtn setBackgroundColor:UIColorFromRGB(AppColorRed)];
        confirmBtn.userInteractionEnabled = YES;
        tblView.userInteractionEnabled = YES;
        goalsTypeView.userInteractionEnabled = YES;
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
- (void)saveGoals {
    int steps = [[goalInfoArray objectAtIndex:0] intValue];
    double distance = [[goalInfoArray objectAtIndex:1] doubleValue];
    int calories = [[goalInfoArray objectAtIndex:2] intValue]*10;
    double hrsSleep = [[goalInfoArray objectAtIndex:3] doubleValue]*10;
   
//    if (distance > 99.9)
//    {
//        distance = 99.9;
//    }
    
//    distance = [iDevicesUtil convertMilesToKilometers:distance];
    
    [TDM328WatchSettingsUserDefaults setDailyStepGoal:steps];
    [TDM328WatchSettingsUserDefaults setDailyDistanceGoal:distance];
    [TDM328WatchSettingsUserDefaults setDailyCaloriesGoal:calories];
    [TDM328WatchSettingsUserDefaults setDailySleepGoal:hrsSleep];
    [TDM328WatchSettingsUserDefaults setGoalType:type];
   
    NSDictionary *goalDict = [NSDictionary dictionaryWithObjectsAndKeys:
                              [goalInfoArray objectAtIndex:0],STEPS,
                              [goalInfoArray objectAtIndex:1],DISTANCE,
                              [goalInfoArray objectAtIndex:2],CALORIES,
                              [goalInfoArray objectAtIndex:3],SLEEPTIME,nil];
    [[NSUserDefaults standardUserDefaults] setValue:goalDict forKey:[iDevicesUtil getGoalTypeStringFormat:(GoalType)[TDM328WatchSettingsUserDefaults goalType]]];
}

- (void) successfullyConnectedToDevice:(NSNotification*)notification {
    [self saveGoals];
    HUD.detailsLabelText = [NSString stringWithFormat: NSLocalizedString(@"Synchronizing data", nil)];
    [self removeObservers];
    [app.customTabbar goalsAndALramSyncStarted];
    [app.customTabbar successfullyConnectedToDevice:notification];
}
-(void)undiscoveredPeripheral:(NSNotification*)notification {
    [self removeObservers];
    [HUD hide:YES];
    [self confirmBtnTextChange:NO];
    [((MFSideMenuContainerViewController *)app.window.rootViewController) setPanMode:MFSideMenuPanModeDefault]; // enable pan mode
    [app showAlertWithTitle:NSLocalizedString(@"Error",nil) Message:NSLocalizedString(@"Device Not Connected",nil) andButtonTitle:NSLocalizedString(@"OK",nil)];
}
- (void)syncFinished {
    [self removeObservers];
    [HUD hide:YES];
    [self confirmBtnTextChange:YES];
    [((MFSideMenuContainerViewController *)app.window.rootViewController) setPanMode:MFSideMenuPanModeDefault]; // enable pan mode
}
- (void)syncFailed {
    [self removeObservers];
    [HUD hide:YES];
    [self confirmBtnTextChange:NO];
    [((MFSideMenuContainerViewController *)app.window.rootViewController) setPanMode:MFSideMenuPanModeDefault]; // enable pan mode
}

-(void)slideMenuTapped {
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
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    
    return goalInfoArray.count;
    
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return 70.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"cellID";
    
    GoalsCell *cell = (GoalsCell *)[tableView dequeueReusableCellWithIdentifier:
                                  cellIdentifier];
    
    if (!cell) {
        [tableView registerNib:[UINib nibWithNibName:@"GoalsCell" bundle:nil] forCellReuseIdentifier:cellIdentifier];
        cell = (GoalsCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    }
    cell.goalsTextFd.indexPath = indexPath;
    cell.goalsTextFd.delegate = self;
//    [cell inputAccessoryviewForTextfield];
    
    int text = [[goalInfoArray objectAtIndex:indexPath.row] intValue];
    cell.goalsTextFd.text = [NSString stringWithFormat:@"%d",text];
    cell.currentLabel.text = [NSString stringWithFormat:NSLocalizedString(@"current %d",nil),text];
    cell.goalsTextFd.returnKeyType = UIReturnKeyNext;
    if (indexPath.row == 0) {
        cell.titleLbl.attributedText = [self getAttributedStrWithText:NSLocalizedString(@"Steps",nil) formatStr:@""];
        cell.profileImageView.image = [[UIImage imageNamed:@"Welcome_Steps"] imageWithTint: UIColorFromRGB(M328_STEPS_COLOR)];;
        cell.tagLbl.text = NSLocalizedString(@"steps", nil);
        if ([TDM328WatchSettingsUserDefaults displaySubDial] == 0 && [[TDWatchProfile sharedInstance] watchStyle] != timexDatalinkWatchStyle_IQTravel)
             cell.subdialImg.hidden = NO;
    } else if (indexPath.row == 1) {
        float km = [[goalInfoArray objectAtIndex:indexPath.row] doubleValue];

        float miles = [iDevicesUtil convertKilometersToMiles:km];
        cell.goalsTextFd.text = [NSString stringWithFormat:@"%.2f",([iDevicesUtil isMetricSystem])?km:miles];
        cell.currentLabel.text = [NSString stringWithFormat:NSLocalizedString(@"current %.2f",nil),[iDevicesUtil isMetricSystem]?km:miles];

        cell.titleLbl.attributedText = [self getAttributedStrWithText:NSLocalizedString(@"Distance",nil) formatStr:@""];
        cell.profileImageView.image = [[UIImage imageNamed:@"Welcome_Distance"] imageWithTint: UIColorFromRGB(M328_DISTANCE_COLOR)];
        cell.tagLbl.text = [iDevicesUtil isMetricSystem]?NSLocalizedString(@"km", nil):NSLocalizedString(@"miles", nil);
        if ([TDM328WatchSettingsUserDefaults displaySubDial] == 1 && [[TDWatchProfile sharedInstance] watchStyle] != timexDatalinkWatchStyle_IQTravel)
            cell.subdialImg.hidden = NO;
    } else if (indexPath.row == 2) {
        cell.titleLbl.attributedText = [self getAttributedStrWithText:NSLocalizedString(@"Calories",nil) formatStr:@""];
        cell.profileImageView.image = [[UIImage imageNamed:@"Welcome_Calories"] imageWithTint: UIColorFromRGB(M328_CALORIES_COLOR)];
        cell.tagLbl.text = (![iDevicesUtil isMetricSystem])?NSLocalizedString(@"Cal", nil):NSLocalizedString(@"kcal", nil);
    } else if (indexPath.row == 3) {
        double sleep = [[goalInfoArray objectAtIndex:indexPath.row] doubleValue];
        cell.goalsTextFd.text = [NSString stringWithFormat:@"%.1f",sleep];
        cell.currentLabel.text = [NSString stringWithFormat:NSLocalizedString(@"current %.1f",nil),sleep];
        
        cell.titleLbl.attributedText = [self getAttributedStrWithText:NSLocalizedString(@"Sleep",nil) formatStr:@""];
        cell.profileImageView.image = [[UIImage imageNamed:@"Welcome_Sleep"] imageWithTint: UIColorFromRGB(M328_SLEEP_COLOR)];
        cell.tagLbl.text = NSLocalizedString(@"hrs",nil);
        cell.subdialImg.hidden = YES;
        cell.goalsTextFd.returnKeyType = UIReturnKeyDone;
    }
    cell.currentLabel.text = @"";
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    GoalsCell *cell = (GoalsCell *)[tableView cellForRowAtIndexPath:indexPath];
    [cell.goalsTextFd becomeFirstResponder];
}

- (NSAttributedString *)getAttributedStrWithText:(NSString *)textStr formatStr:(NSString *)formatStr {
    
    UIFont *textFont = [UIFont fontWithName:[iDevicesUtil getAppWideMediumFontName] size:M328_GOALS_SCREEN_TITLE_FONT_SIZE];
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:textFont, NSFontAttributeName, [UIColor blackColor],NSForegroundColorAttributeName, nil];
    NSMutableAttributedString *textAtrStr = [[NSMutableAttributedString alloc] initWithString:textStr attributes:dict];
    
    UIFont *formatFont = [UIFont fontWithName: [iDevicesUtil getAppWideFontName] size: M328_GOALS_SCREEN_TAG_FONT_SIZE];
    NSDictionary *atrsDict = [NSDictionary dictionaryWithObjectsAndKeys:formatFont, NSFontAttributeName, UIColorFromRGB(COLOR_DEFAULT_TIMEX_FONT),NSForegroundColorAttributeName, nil];
    NSAttributedString *formatAtrStr = [[NSAttributedString alloc] initWithString:formatStr attributes:atrsDict];
    [textAtrStr appendAttributedString:formatAtrStr];
    
    
    return textAtrStr;
}

#pragma mark -
#pragma mark UITextFieldDelegate Methods

- (BOOL)textFieldShouldBeginEditing:(GoalTextField *)textField {
    if (!IS_IPAD) {
        tblView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tblView.frame.size.width, 250)]; // For tableview to scroll top to visible lastcell above keyboard
    }
    isTextfieldEditing = YES;
    return TRUE;
}

- (void)textFieldDidBeginEditing:(GoalTextField *)textField {
    [tblView scrollToRowAtIndexPath:textField.indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
}
- (BOOL)textField:(GoalTextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    prettyActiveBtn.alpha = 0.5;
    veryActiveBtn.alpha = 0.5;
    activeBtn.alpha = 0.5;
    type = Custom;
    goalType = GOAL_TYPE_CUSTOM;
    if ([string isEqualToString:@""]) {
        NSString *result = [textField.text stringByReplacingCharactersInRange:range withString:string];
        [self updateEnteredOfValueOfTextField:textField withValue:result];
        return YES;
    }
    
    NSCharacterSet *numbers;
    if (textField.indexPath.row == 1 || textField.indexPath.row == 3) {
        numbers = [NSCharacterSet characterSetWithCharactersInString:@"0123456789."];
    } else {
        numbers = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];
    }
    if ([string rangeOfCharacterFromSet:numbers].location != NSNotFound) {
        NSString *result = [textField.text stringByReplacingCharactersInRange:range withString:string];
        switch (textField.indexPath.row) {
            case 0:
                if ([result intValue] > M328_MAXIMUM_STEPS_GOAL) {
                    return NO;
                }
                break;
            case 1:
            {
                NSArray *sep = [result componentsSeparatedByString:@"."];
                if([sep count] >= 2) {
                    NSString *sepStr=[NSString stringWithFormat:@"%@",[sep objectAtIndex:1]];
                    // No more than 2 decimal places
                    if([sepStr length] > 2){
                        return NO;
                    }
                }
                if ([iDevicesUtil isMetricSystem]) {
                    if ([result doubleValue] > M328_MAXIMUM_DISTANCE_GOAL_KM) {
                        return NO;
                    }
                } else {
                    float maxInMiles = [iDevicesUtil convertKilometersToMiles: (float)M328_MAXIMUM_DISTANCE_GOAL_KM];
                    if ([result doubleValue] > maxInMiles) {
                        return  NO;
                    }
                }
                break;
            }
            case 2:
                if ([result intValue] > M328_MAXIMUM_CALORIES_GOAL) {
                    return NO;
                }
                break;
            case 3: {
                NSArray *sep = [result componentsSeparatedByString:@"."];
                if([sep count] >= 2) {
                    NSString *sepStr=[NSString stringWithFormat:@"%@",[sep objectAtIndex:1]];
                    // No more than 2 decimal places
                    if([sepStr length] > 1){
                        return NO;
                    }
                }
                if ([result doubleValue] > M328_MAXIMUM_SLEEP_GOAL) {
                    return NO;
                }
                break;
            }
            default:
                break;
        }
        
        [self updateEnteredOfValueOfTextField:textField withValue:result];
        return YES;
    }
    return NO;
}
- (void)textFieldDidEndEditing:(GoalTextField *)textField {
    [self updateEnteredOfValueOfTextField:textField withValue:textField.text];
    if (textField.indexPath.row > 2) {
        tblView.tableFooterView = tableFooterView;
        [tblView scrollToRowAtIndexPath:textField.indexPath atScrollPosition:UITableViewScrollPositionNone animated:YES];
        [textField resignFirstResponder];
    }
    [self confirmBtnTextChange:NO];
}

- (bool)textFieldShouldReturn:(GoalTextField *)textField {
    if (textField.indexPath.row > 2) {
        [textField resignFirstResponder];
    } else {
        GoalsCell *nextCell = [tblView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:textField.indexPath.row+1 inSection:0]];
        [nextCell.goalsTextFd becomeFirstResponder];
    }
    return YES;
}
- (void)keyboardNextButtonTapped:(UIButton *)keyboardBtn {
    GoalsCell *cell = [tblView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:(keyboardBtn.tag - 1) inSection:0]];
    if (keyboardBtn.tag < 4) {
        GoalsCell *nextCell = [tblView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:(keyboardBtn.tag) inSection:0]];
        [nextCell.goalsTextFd becomeFirstResponder];
    } else {
        [cell.goalsTextFd resignFirstResponder];
    }
}

- (void)updateEnteredOfValueOfTextField:(GoalTextField *)textField withValue:(NSString *)result {
    
    if (textField.indexPath.row == 1) {
        if ([iDevicesUtil isMetricSystem]) {
            [goalInfoArray replaceObjectAtIndex:textField.indexPath.row withObject:[NSNumber numberWithDouble:[result doubleValue]]];
        } else {
            [goalInfoArray replaceObjectAtIndex:textField.indexPath.row withObject:[NSNumber numberWithDouble:[iDevicesUtil convertMilesToKilometers:[result doubleValue]]]];
        }
        
    } else {
        [goalInfoArray replaceObjectAtIndex:textField.indexPath.row withObject:[NSNumber numberWithDouble:[result doubleValue]]];
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self didTapOnTableView];
}
- (void)didTapOnTableView {
    if (isTextfieldEditing) {
        tblView.tableFooterView = tableFooterView;
        isTextfieldEditing = NO;
    }
    [self.view endEditing:YES];
    [tblView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionNone animated:YES];
}
- (void) dealloc {
    [self removeObservers];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"SyncFinished" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"SyncFailed" object:nil];
    
    //Remove temp goals
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"1"] != nil) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"1"];
    }
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"2"] != nil) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"2"];
    }
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"3"] != nil) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"3"];
    }
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"4"] != nil) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"4"];
    }
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    app.customTabbar.autoSyncAllowed = YES;
}
@end
