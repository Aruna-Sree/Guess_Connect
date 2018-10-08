//
//  SetGoalsViewController.m
//  Timex
//
//  Created by avemulakonda on 5/4/16.
//

#import "SetGoalsViewController.h"
#import "ConfigureSubdialViewController.h"
#import "iDevicesUtil.h"
#import "TDDefines.h"
#import "UIImage+Tint.h"
#import "GoalsCell.h"
//#import "Goals.h"
#import "TDAppDelegate.h"
#import "TDM328WatchSettingsUserDefaults.h"
#import "TDM328WatchSettings.h"
#import "OTLogUtil.h"
#import "SideMenuViewController.h"
#import "MFSideMenuContainerViewController.h"
#import "TDWatchProfile.h"

@interface SetGoalsViewController () {
    NSMutableDictionary *goal;
    enum GoalType type;
    TDAppDelegate *app;
    CustomTabbar *customTabbar;
    NSString * goalType;
    int steps;
    double distance;
    int calories;
    double hrsSleep;
}

@end

@implementation SetGoalsViewController

#pragma  mark Life Cycle Methods

- (void)viewDidLoad
{
    [super viewDidLoad];
  
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))  {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    type = Pretty;
    app = (TDAppDelegate*)[[UIApplication sharedApplication]delegate];
    goal = [[app getGoalsForType:type] mutableCopy];
    goalType =  GOAL_TYPE_PRETTY_ACTIVE;
    self.navigationItem.titleView = [iDevicesUtil getNavigationTitle];
    infoTextLbl.attributedText = [self getAttributedStrWithText:NSLocalizedString(@"Set daily goals.",nil) formatStr:NSLocalizedString(@"\nHow active do you want to be?",nil)];
    if (IS_IPAD) {
        infoTextLblTopConstraint.constant = 60;
        infoTextLblLeftConstraint.constant = 60;
        infoTextLblRightContraint.constant = 60;
        infoTextLblHeightContraint.constant = 100;
        infoTextLblBottomContraint.constant = 40;
        nextButtonBottomContraint.constant = 40;
        btnsViewBottomConstrait.constant = 45;
        goalsTypeViewWidthConstraint.constant = M328_CONFIRM_CHANGE_BUTTON_WIDTH;
    } else {
        infoTextLblTopConstraint.constant = 5;
        infoTextLblLeftConstraint.constant = 40;
        infoTextLblRightContraint.constant = 40;
        infoTextLblHeightContraint.constant = 40;
        infoTextLblBottomContraint.constant = 5;
        if (ScreenHeight > 480) {
            btnsViewBottomConstrait.constant = 30;
        }
        goalsTypeViewWidthConstraint.constant = 290;
    }

    if (_notOpenedByMenu)
    {
        UIButton *backBtn = [iDevicesUtil getBackButton];
        [backBtn addTarget:self action:@selector(backButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *barBtn = [[UIBarButtonItem alloc] initWithCustomView:backBtn];
        self.navigationItem.leftBarButtonItem = barBtn;
    }
    else
    {
        nextBtn.hidden = YES;
        UIBarButtonItem *slideMenuItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"menu"] style:UIBarButtonItemStylePlain target:self action:@selector(slideMenuTapped)];
        self.navigationItem.leftBarButtonItem = slideMenuItem;
    }
    
    progressLbl.backgroundColor = UIColorFromRGB(AppColorRed);
    progressLblWidthContraint.constant = ScreenWidth * ([iDevicesUtil getProgressBarValueBasedOnRegistrationEnum:settingGoals]);
    
    [activeBtn setImage:[[UIImage imageNamed:@"active"] imageWithTint: UIColorFromRGB(AppColorRed)] forState:UIControlStateNormal];
    [prettyActiveBtn setImage:[[UIImage imageNamed:@"prettyactive"] imageWithTint: UIColorFromRGB(AppColorRed)] forState:UIControlStateNormal];
    [veryActiveBtn setImage:[[UIImage imageNamed:@"veryactive"] imageWithTint: UIColorFromRGB(AppColorRed)] forState:UIControlStateNormal];
    activeBtn.alpha = 0.5;
    veryActiveBtn.alpha = 0.5;
    
    if ([TDM328WatchSettingsUserDefaults goalType])
    {
        switch ([TDM328WatchSettingsUserDefaults goalType])
        {
            case Normal:
                [self clickedOnGoalTypeBtns:activeBtn];
                break;
            case Pretty:
                [self clickedOnGoalTypeBtns:prettyActiveBtn];
                break;
            case Very:
                [self clickedOnGoalTypeBtns:veryActiveBtn];
                break;
            default:
                [self setToCustomGoalType];
                break;
        }
    }
    
    [activeBtn setTitle:NSLocalizedString(activeBtn.currentTitle, nil) forState:UIControlStateNormal];
    [prettyActiveBtn setTitle:NSLocalizedString(prettyActiveBtn.currentTitle, nil) forState:UIControlStateNormal];
    [veryActiveBtn setTitle:NSLocalizedString(veryActiveBtn.currentTitle, nil) forState:UIControlStateNormal];
    
    [nextBtn setTitle:[NSString stringWithFormat:@"%@  ", NSLocalizedString(@"NEXT", nil)] forState:UIControlStateNormal];
    nextBtn.transform = CGAffineTransformMakeScale(-1.0, 1.0);
    nextBtn.titleLabel.transform = CGAffineTransformMakeScale(-1.0, 1.0);
    nextBtn.imageView.transform = CGAffineTransformMakeScale(-1.0, 1.0);
    [nextBtn setTitleColor:UIColorFromRGB(AppColorRed) forState:UIControlStateNormal];
    nextBtn.tintColor = UIColorFromRGB(AppColorRed);
}

-(void)slideMenuTapped
{
    TDAppDelegate * delegate = (TDAppDelegate *)[UIApplication sharedApplication].delegate;
    SideMenuViewController *leftController = (SideMenuViewController *)((MFSideMenuContainerViewController *)delegate.window.rootViewController).leftMenuViewController;
    if (leftController == nil)
    {
        SideMenuViewController *leftController = [[SideMenuViewController alloc] init];
        ((MFSideMenuContainerViewController *)delegate.window.rootViewController).leftMenuViewController = leftController;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (!_notOpenedByMenu)
    {
        [self addCustomTabbar];
    }
}

#pragma mark
#pragma mark CustomTabbar
- (void)addCustomTabbar {
    customTabbar = app.customTabbar;
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

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
    goalsTableView.tableFooterView = nil;
    [goalsTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

- (NSAttributedString *)getAttributedStrWithText:(NSString *)textStr formatStr:(NSString *)formatStr {
    
    UIFont *textFont = [UIFont fontWithName:[iDevicesUtil getAppWideMediumFontName] size:M328_REGISTRATION_TITLE_FONTSIZE];
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:textFont, NSFontAttributeName, [UIColor blackColor],NSForegroundColorAttributeName, nil];
    NSMutableAttributedString *textAtrStr = [[NSMutableAttributedString alloc] initWithString:textStr attributes:dict];
    
    UIFont *formatFont = [UIFont fontWithName: [iDevicesUtil getAppWideFontName] size:M328_REGISTRATION_INFO_FONTSIZE];
    NSDictionary *atrsDict = [NSDictionary dictionaryWithObjectsAndKeys:formatFont, NSFontAttributeName, UIColorFromRGB(COLOR_DEFAULT_TIMEX_FONT),NSForegroundColorAttributeName, nil];
    NSAttributedString *formatAtrStr = [[NSAttributedString alloc] initWithString:formatStr attributes:atrsDict];
    [textAtrStr appendAttributedString:formatAtrStr];
    
    return textAtrStr;
}

- (void)didReceiveMemoryWarning {
     OTLog([NSString stringWithFormat:@"Recived Memory Warning  in %@ ",NSStringFromClass([self class])]);
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)clickedOnGoalTypeBtns:(UIButton *)sender {
    [self.view endEditing:NO];
    goalsTableView.tableFooterView = nil;
    [goalsTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    
    prettyActiveBtn.alpha = 1;
    veryActiveBtn.alpha = 1;
    activeBtn.alpha = 1;
    [[NSUserDefaults standardUserDefaults]setValue:goal forKey:goalType];
    if (sender == activeBtn) {
        type = Normal;
        prettyActiveBtn.alpha = 0.5;
        veryActiveBtn.alpha = 0.5;
        goalType = GOAL_TYPE_ACTIVE;
    } else if (sender == prettyActiveBtn) {
        type = Pretty;
        activeBtn.alpha = 0.5;
        veryActiveBtn.alpha = 0.5;
         goalType = GOAL_TYPE_PRETTY_ACTIVE;
    } else {
        type = Very;
        prettyActiveBtn.alpha = 0.5;
        activeBtn.alpha = 0.5;
         goalType = GOAL_TYPE_VERY_ACTIVE;
    }
    
    if ([[NSUserDefaults standardUserDefaults] valueForKey:goalType] != nil){
        goal = [[[NSUserDefaults standardUserDefaults]valueForKey:goalType] mutableCopy];
    } else {
        goal = [[app getGoalsForType:type] mutableCopy];
    }
    [goalsTableView reloadData];
}

-(void)setToCustomGoalType
{
    type = Custom;
    prettyActiveBtn.alpha = 0.5;
    veryActiveBtn.alpha = 0.5;
    activeBtn.alpha = 0.5;
    goalType = GOAL_TYPE_CUSTOM;
    
    if ([[NSUserDefaults standardUserDefaults] valueForKey:goalType] != nil){
        goal = [[[NSUserDefaults standardUserDefaults]valueForKey:goalType] mutableCopy];
    } else {
        goal = [[app getGoalsForType:type] mutableCopy];
    }
    [goalsTableView reloadData];
}

-(void)saveGoalsToUserDefaults
{
    
    steps = [(NSNumber*)[goal valueForKey:STEPS]intValue];
    distance = [(NSNumber*)[goal valueForKey:DISTANCE]doubleValue];
    calories = [(NSNumber*)[goal valueForKey:CALORIES]intValue]*10;
    hrsSleep = [(NSNumber*)[goal valueForKey:SLEEPTIME]doubleValue]*10;
    
//    if (distance > 99.9)
//    {
//        distance = 99.9;
//    }
//    if (![iDevicesUtil isMetricSystem]) //Because in goals dictionary distance is always saved in miles
//        distance = [iDevicesUtil convertMilesToKilometers:distance];
    
     [TDM328WatchSettingsUserDefaults setDailyStepGoal:steps];
     [TDM328WatchSettingsUserDefaults setDailyDistanceGoal:distance];
     [TDM328WatchSettingsUserDefaults setDailyCaloriesGoal:calories];
     [TDM328WatchSettingsUserDefaults setDailySleepGoal:hrsSleep];
     [TDM328WatchSettingsUserDefaults setGoalType:type];
    if ([iDevicesUtil isMetricSystem]){
        [TDM328WatchSettingsUserDefaults setUnits:M328_METRIC];
    } else {
        [TDM328WatchSettingsUserDefaults setUnits:M328_IMPERIAL];
    }
    [[NSUserDefaults standardUserDefaults] setValue:goal forKey:goalType];
}

#pragma  mark Button Actions

-(void) backButtonTapped
{
    //[app saveGoal:goal];
    [self saveGoalsToUserDefaults];
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)nextButtonTapped:(id)sender {
    //[app saveGoal:goal];
    [self saveGoalsToUserDefaults];
    
    ConfigureSubdialViewController *configureVC=[[ConfigureSubdialViewController alloc] initWithNibName:@"ConfigureSubdialViewController" bundle:nil];
        [self.navigationController pushViewController:configureVC animated:YES];
}

#pragma mark - TableView Methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 4;
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
    cell.goalsTextFd.returnKeyType = UIReturnKeyNext;

    if (indexPath.row == 0) {
        cell.titleLbl.attributedText = [self getTableCellAttributedStrWithText:NSLocalizedString(@"Steps",nil) formatStr:@""];
        cell.goalsTextFd.text = [NSString stringWithFormat:@"%ld",(long)[(NSNumber*)[goal valueForKey:STEPS]integerValue]];
//        cell.goalsTextFd.text = [NSString stringWithFormat:@"%d",goal.steps.intValue];
        cell.currentLabel.text = @"";
        cell.profileImageView.image = [[UIImage imageNamed:@"Welcome_Steps"] imageWithTint: UIColorFromRGB(M328_STEPS_COLOR)];;
        cell.tagLbl.text = NSLocalizedString(@"steps",nil);
    } else if (indexPath.row == 1) {
        cell.titleLbl.attributedText = [self getTableCellAttributedStrWithText:NSLocalizedString(@"Distance",nil) formatStr:@""];
        if ([iDevicesUtil isMetricSystem]) {
            cell.goalsTextFd.text = [NSString stringWithFormat:@"%.2f",[(NSNumber*)[goal valueForKey:DISTANCE] doubleValue]];
            cell.tagLbl.text = NSLocalizedString(@"km",nil);
        } else {
            cell.goalsTextFd.text = [NSString stringWithFormat:@"%.2f",[iDevicesUtil convertKilometersToMiles:[(NSNumber*)[goal valueForKey:DISTANCE] doubleValue]]];

            cell.tagLbl.text = NSLocalizedString(@"miles",nil);
        }
        
        cell.currentLabel.text = @"";
        cell.profileImageView.image = [[UIImage imageNamed:@"Welcome_Distance"] imageWithTint: UIColorFromRGB(M328_DISTANCE_COLOR)];
    } else if (indexPath.row == 2) {
        cell.titleLbl.attributedText = [self getTableCellAttributedStrWithText:NSLocalizedString(@"Calories",nil) formatStr:@""];
        cell.goalsTextFd.text = [NSString stringWithFormat:@"%ld",(long)[(NSNumber*)[goal valueForKey:CALORIES]integerValue]];
        cell.currentLabel.text = @"";
        cell.profileImageView.image = [[UIImage imageNamed:@"Welcome_Calories"] imageWithTint: UIColorFromRGB(M328_CALORIES_COLOR)];
        cell.tagLbl.text = (![iDevicesUtil isMetricSystem])?NSLocalizedString(@"Cal", nil):NSLocalizedString(@"kcal", nil);
    } else if (indexPath.row == 3) {
        
        cell.titleLbl.attributedText = [self getTableCellAttributedStrWithText:NSLocalizedString(@"Sleep",nil) formatStr:@""];
        cell.goalsTextFd.text = [NSString stringWithFormat:@"%.1f",[(NSNumber*)[goal valueForKey:SLEEPTIME]doubleValue]];
        cell.currentLabel.text = @"";
        cell.profileImageView.image = [[UIImage imageNamed:@"Welcome_Sleep"] imageWithTint: UIColorFromRGB(M328_SLEEP_COLOR)];
        cell.tagLbl.text = NSLocalizedString(@"hrs",nil);
        cell.goalsTextFd.returnKeyType = UIReturnKeyDone;

    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    GoalsCell *cell = (GoalsCell *)[tableView cellForRowAtIndexPath:indexPath];
    [cell.goalsTextFd becomeFirstResponder];
}

- (NSAttributedString *)getTableCellAttributedStrWithText:(NSString *)textStr formatStr:(NSString *)formatStr {
    
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
        goalsTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, goalsTableView.frame.size.width, 250)];
    }
    return TRUE;
}

- (void)textFieldDidBeginEditing:(GoalTextField *)textField {

    [goalsTableView scrollToRowAtIndexPath:textField.indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

- (BOOL)textField:(GoalTextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
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
                if ([result intValue] > MAXIMUM_STEPS_GOAL) {
                    return NO;
                }
                break;
            case 1: {
                NSArray *sep = [result componentsSeparatedByString:@"."];
                if([sep count] >= 2) {
                    NSString *sepStr=[NSString stringWithFormat:@"%@",[sep objectAtIndex:1]];
                    // No more than 2 decimal places
                    if([sepStr length] > 2){
                        return NO;
                    }
                }
               if ([iDevicesUtil isMetricSystem]) {
                    if ([result doubleValue] > MAXIMUM_DISTANCE_GOAL_KM) {
                        return NO;
                    }
                } else {
                    float maxInMiles = [iDevicesUtil convertKilometersToMiles: (float)MAXIMUM_DISTANCE_GOAL_KM];
                    if ([result doubleValue] > maxInMiles) {
                        return  NO;
                    }
                }
                break;
            }
            case 2:
                if ([result intValue] > MAXIMUM_CALORIES_GOAL) {
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
                if ([result doubleValue] > MAXIMUM_SLEEP_GOAL) {
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

- (void)updateEnteredOfValueOfTextField:(GoalTextField *)textField withValue:(NSString *)result {
    switch (textField.indexPath.row) {
        case 0:
            [goal setValue:[NSNumber numberWithDouble:[result doubleValue]] forKey: STEPS];
            break;
        case 1:
            if (![iDevicesUtil isMetricSystem]) {
                [goal setValue:[NSNumber numberWithDouble:[iDevicesUtil convertMilesToKilometers:[result doubleValue]]] forKey: DISTANCE];
            } else {
                [goal setValue:[NSNumber numberWithDouble:[result doubleValue]] forKey: DISTANCE];
            }
            break;
        case 2:
            [goal setValue:[NSNumber numberWithDouble:[result doubleValue]] forKey: CALORIES];
            break;
        case 3:
            [goal setValue:[NSNumber numberWithDouble:[result doubleValue]] forKey: SLEEPTIME];
            break;
        default:
            break;
    }
    [self changeGoalTypeToCustom];
}

- (bool)textFieldShouldReturn:(GoalTextField *)textField {
    if (textField.indexPath.row > 2) {
        [textField resignFirstResponder];
    } else {
        GoalsCell *nextCell = [goalsTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:textField.indexPath.row+1 inSection:0]];
        [nextCell.goalsTextFd becomeFirstResponder];
    }
    return YES;
}

- (void)textFieldDidEndEditing:(GoalTextField *)textField {
    [self updateEnteredOfValueOfTextField:textField withValue:textField.text];
    if (textField.indexPath.row == 3) {
        goalsTableView.tableFooterView = nil;
        [goalsTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
        [textField resignFirstResponder];
    }
}

- (void)keyboardNextButtonTapped:(UIButton *)keyboardBtn {
    GoalsCell *cell = [goalsTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:(keyboardBtn.tag - 1) inSection:0]];
    if (keyboardBtn.tag < 4) {
        GoalsCell *nextCell = [goalsTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:(keyboardBtn.tag) inSection:0]];
        [nextCell.goalsTextFd becomeFirstResponder];
    } else {
        [cell.goalsTextFd resignFirstResponder];
    }
}

- (void)changeGoalTypeToCustom {
    type = Custom;
    prettyActiveBtn.alpha = 0.5;
    veryActiveBtn.alpha = 0.5;
    activeBtn.alpha = 0.5;
    goalType = GOAL_TYPE_CUSTOM;
}

@end
