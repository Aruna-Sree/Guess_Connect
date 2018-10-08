//
//  CustomTabbar.h
//  TableViewCellTest
//
//  Created by Aruna Kumari Yarra on 28/03/16.
//

#import <UIKit/UIKit.h>
#import "BLEManager.h"
#import "iDevicesUtil.h"
@interface CustomTabbar : UIView  {
    BOOL stillAnimationgButton;
    UIViewController *topVC;
    
    IBOutlet UIImageView *errorImg;
    IBOutlet UIButton *updateLaterBtn;
    IBOutlet UIButton *updateNowBtn;
    IBOutlet UIButton *cancelBtn;
    IBOutlet UILabel *warningLbl;
    IBOutlet UIButton *alignNowBtn;
    IBOutlet UIView *syncView;
    IBOutlet UILabel *syncViewBgLbl;
    IBOutlet UIView *syncFailedView;
    IBOutlet UIButton *syncImg;
    IBOutlet UIView *synImgView;
    BLEManager*   bleManager;
    BOOL mInitialSetupSynchronization;
    syncActionsEnum mCurrentSyncActionSelected;
    NSTimer *actionTimer;
    NSInteger mReconnectAttempts;
    
    // This flag will be used when other classes have own implementation of sync (ex : Timer, Setdaily goals, Alarm, Calibraiton etc.)
    BOOL autoSyncAllowed;
}
@property (nonatomic) BOOL alertBarIsUp;
@property (strong, nonatomic) IBOutlet UILabel *alertBar;
@property (strong, nonatomic) IBOutlet UILabel *lastSynLbl;
@property (strong, nonatomic) IBOutlet UIButton *syncBtn;
@property (weak, nonatomic) IBOutlet UILabel *textLbl;
@property (weak, nonatomic) IBOutlet UIImageView *headerImg;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *infoLblTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *infoLblleftConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *infoLblRightConstraint;
@property (nonatomic) BOOL autoSyncAllowed;
- (IBAction)clickedOnSync;
- (IBAction)clickedOnContactNow;
- (void)backFromGetInTouchScreen;
- (void)clickOnTimerSync;
- (void)timerSyncFinished;
- (void)updateLastLblText;
- (void)removeObserversTosync;
- (void)removeDevicesChangedNotificaiton ;
- (void)enableUserInteraction ;
- (void)alertBarUp;
- (void)syncNeeded;
- (void)goalsAndALramSyncStarted;
- (void) successfullyConnectedToDevice:(NSNotification*)notification;
- (void) launchUserInitiatedFirmwareCheck: (NSNotification*)notification;
@end
