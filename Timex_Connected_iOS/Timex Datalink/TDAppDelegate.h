//
//  TDAppDelegate.h
//  Timex Connected
//
//  Created by Lev Verbitsky on 6/18/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CustomTabbar.h"
#import "iDevicesUtil.h"

@class TDMainViewController;

@interface TDAppDelegate : UIResponder <UIApplicationDelegate>
{
   
}
@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) CustomTabbar *customTabbar;
@property (strong, nonatomic) TDMainViewController *viewController;
@property (strong, nonatomic) UIAlertView *alertView;

- (void)InitialiseCustomTabbar;
- (NSString *)removingLastSpecialCharecter:(NSString *)str;
- (NSString *)getLastSyncDate;

- (void)deleteOldAndInsertGoalOfType:(enum GoalType)type;
- (void)setNavigationBarSettingsForM328:(UINavigationController *)navigationController;
- (void)setNavigationBarSettingsForM054andM053:(UINavigationController *)navViewController;
-(void)setupDummyGoals;
-(NSMutableDictionary*)getGoalsForType:(GoalType)type;
-(void)saveGoal:(NSMutableDictionary*)goal;

- (void)showAlertWithTitle:(NSString *)title Message:(NSString *)message andButtonTitle:(NSString *)btnTitle ;

- (void)setTimerTempAfterLaunchingApp;
- (UIViewController *)welcomeViewController;
@end
