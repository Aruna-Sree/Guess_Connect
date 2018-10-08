//
//  TDWelcomeViewViewController.m
//  Timex
//
//  Created by Diego Santiago on 5/5/16.
//  Copyright © 2016 iDevices, LLC. All rights reserved.
//

#import "TDWelcomeViewViewController.h"
#import "iDevicesUtil.h"
#import "TDDefines.h"
#import "UIImage+Tint.h"
#import "TDDefineColors.h"
#import "TDOnBoardingNameAndSexViewController.h"


@interface TDWelcomeViewViewController ()

@end

@implementation TDWelcomeViewViewController
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
   self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
 
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIImage *imgBack = [[UIImage imageNamed:@"arrow_left.png"]imageWithTint:[UIColor blackColor]];
    [backArrow setImage:imgBack];
    
    UIImage *img = [[UIImage imageNamed:@"timex_logo.png"]imageWithTint:Red];
    [timexLogo setImage:img];
    
    welcomeLabel.textAlignment = NSTextAlignmentCenter;
    welcomeLabel.adjustsFontSizeToFitWidth = true;
    welcomeLabel.minimumScaleFactor = 0.5;
    welcomeLabel.font = [UIFont fontWithName:@"Roboto-Regular" size:20];
    welcomeLabel.text = NSLocalizedString(@"Welcome!", nil);
    
    
    messageWelcome.userInteractionEnabled = false;
    messageWelcome.text = NSLocalizedString(@"Timex Connected tracks your activity level such as steps, distance, calories and sleep.", nil);
    messageWelcome.textAlignment = NSTextAlignmentCenter;
    messageWelcome.contentScaleFactor = 0.5;
    messageWelcome.font = [UIFont fontWithName:@"Roboto-Regular" size:12];

    
    
    UIImage *imgSleep       = [[UIImage imageNamed:@"sleep_icon.png"]imageWithTint:PurpleOne];
    UIImage *imgCalories    = [[UIImage imageNamed:@"calories_icon.png"]imageWithTint:OrangeOne];
    UIImage *imgDiststance  = [[UIImage imageNamed:@"distance_icon.png"]imageWithTint:BlueOne];
    UIImage *imgSteps       = [[UIImage imageNamed:@"steps_icon.png"]imageWithTint:BlueTwo];
    
    [welcomeSteps setImage:imgSteps];
    [welcomeDistance setImage:imgDiststance];
    [welcomeCalories setImage:imgCalories];
    [welcomeSleep setImage:imgSleep];
    
    
    createProfileMessage.userInteractionEnabled = false;
    createProfileMessage.text = NSLocalizedString(@"Please create your profile and set up your watch to get started.", nil);
    createProfileMessage.textAlignment = NSTextAlignmentCenter;
    createProfileMessage.contentScaleFactor = 0.5;
    createProfileMessage.font = [UIFont fontWithName:@"Roboto-Regular" size:12];
    
    getStartedLabel.textColor = Red;
    getStartedLabel.font = [UIFont fontWithName:@"Roboto-Regular" size:17];
    getStartedLabel.adjustsFontSizeToFitWidth = true;
    getStartedLabel.minimumScaleFactor = 0.5;
    getStartedLabel.text = NSLocalizedString(@"GET STARTED", nil);
    
    
    UIImage *imgRightArrow      = [[UIImage imageNamed:@"arrow_right.png"]imageWithTint:Red];
    [rightArrow setImage:imgRightArrow];
    
    
    
    
    UITapGestureRecognizer *tapBack = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapBackWelcome)];
    [tapBack setNumberOfTapsRequired:1];
    backArrow.userInteractionEnabled = YES;
    [backArrow addGestureRecognizer:tapBack];
    
    
    
    UITapGestureRecognizer *getStarter = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(getStarter)];
    [getStarter setNumberOfTapsRequired:1];
    rightArrow.userInteractionEnabled = YES;
    getStartedLabel.userInteractionEnabled = YES;
    
    [rightArrow addGestureRecognizer:getStarter];
    [getStartedLabel addGestureRecognizer:getStarter];
    
    

    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))
    {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark Selectors

- (void)tapBackWelcome
{
    [self.navigationController popViewControllerAnimated:YES];
}
-(void)getStarter
{
    TDOnBoardingNameAndSexViewController *onBoardingNameAndSex = [[TDOnBoardingNameAndSexViewController alloc] initWithNibName:@"TDOnBoardingNameAndSexViewController" bundle:nil];
    [[self navigationController] pushViewController: onBoardingNameAndSex animated: YES];

    

}
@end
