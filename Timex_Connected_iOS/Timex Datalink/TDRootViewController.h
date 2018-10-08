//
//  TDRootViewController.h
//  Timex Connected
//
//  Created by Lev Verbitsky on 6/18/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDConnectionStatusWindow.h"
#import "UIImage+Scaling.h"
#import <TCBlobDownload/TCBlobDownload.h>



extern NSString * const kFirmwareCheckUserInitiatedNotification;
extern NSString * const kFirmwareRequestUserInitiatedNotification;
extern NSString * const kM372WatchResetUserInitiatedNotification;

@interface TDRootViewController : UIViewController <TDConnectionStatusWindowDelegate, TCBlobDownloaderDelegate>
{
    NSMutableArray  * _mFirmwareUpgradeInfo;
}
    @property (nonatomic, readonly) BOOL bluetoothStatusPopupVisible;
@property (nonatomic) BOOL dontCheck;

    - (BOOL) viewHasContextualMenu;
    - (void) contextualMenuRequested;
    - (BOOL) viewSupportsFirmwareUpdateHandling;
    - (UIBarButtonItem *)backBarButtonItem;
    - (UIBarButtonItem *)leftMenuBarButtonItem;
    - (UIBarButtonItem *)rightMenuBarButtonItem;
    - (UIBarButtonItem *)rightMenuBarButtonItemNoMenu;

- (void) launchFirmwareCheck: (NSNotification*)notification;
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;
@end
