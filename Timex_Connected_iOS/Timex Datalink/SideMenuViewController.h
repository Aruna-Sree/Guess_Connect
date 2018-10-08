//
//  SideMenuViewController.h
//  Timex Connected
//
//  Created by Lev Verbitsky on 6/18/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import "UIImage+Tint.h"

enum viewNavigatorClassic
{
    viewNavigator_viewMain = 0,
    viewNavigator_viewWorkouts,
    viewNavigator_viewProgramWatch,
    viewNavigator_viewCalendar,
    viewNavigator_viewSettings,
    viewNavigator_viewAbout,
    viewNavigator_viewHelp
};

enum viewNavigatorPro
{
    viewNavigatorPro_viewMain = 0,
    viewNavigatorPro_viewWorkouts,
    viewNavigatorPro_viewProgramWatch,
    viewNavigatorPro_viewWatchFinder,
    viewNavigatorPro_viewSettings,
    viewNavigatorPro_viewAbout,
    viewNavigatorPro_viewHelp
};

enum viewNavigatorMetropolitan
{
    viewNavigatorMetropolitan_viewMain = 0,
    //viewNavigatorMetropolitan_viewProgramWatch,//TestLogRemoveAfterTest
    viewNavigatorMetropolitan_viewSetDailsGoals,
    viewNavigatorMetropolitan_viewSettings,
    viewNavigatorMetropolitan_viewHelp,
    viewNavigatorMetropolitan_viewAbout
};

enum viewNavigationIQMove {
    viewNavigatorIQ_viewMain = 0,
    viewNavigatorIQ_viewDailyGoals,
    viewNavigatorIQ_viewSubdial,
    viewNavigatorIQ_viewAlarm,
    viewNavigatorIQ_viewSettings,
    viewNavigatorIQ_viewHelp,
    viewNavigatorIQ_viewAbout
};

enum viewNavigatorFirstUse
{
    viewNavigatorFirstUse_viewMain = 0,
    viewNavigatorFirstUse_Setup,
    viewNavigatorFirstUse_viewAbout,
    viewNavigatorFirstUse_viewHelp
};

@interface SideMenuViewController : UIViewController <UITableViewDataSource, UITableViewDelegate,MFMailComposeViewControllerDelegate,MFMessageComposeViewControllerDelegate>
{
    NSMutableArray * navigationItemList;
//    UITableView    * menuTable;
}
@property (nonatomic, strong)    UITableView    * menuTable;


- (void) performConfirmedFirmwareUpgradeAfterDelayWithData: (NSDictionary *) data;

- (void) goToMain;
- (void) resetMenu;


/** iQ Move */
//- (void)gotoMainM328;
//- (void)gotoDailyGoalsM328;
//- (void)gotoSubdialM328;
//- (void)gotoAlarmM328;
//- (void)gotoSettingsM328;
//- (void)gotoHelpM328;
//- (void)gotoAboutM328;
@end
