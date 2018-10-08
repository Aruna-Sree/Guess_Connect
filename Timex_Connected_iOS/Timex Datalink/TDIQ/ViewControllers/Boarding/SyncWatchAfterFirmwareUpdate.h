//
//  SyncWatchAfterFirmwareUpdate.h
//  timex
//
//  Created by Raghu on 25/01/17.
//  Copyright © 2017 iDevices, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CircleProgressBar.h"

@interface SyncWatchAfterFirmwareUpdate : UIViewController
{
    IBOutlet UILabel *titleLabel;
    IBOutlet UILabel *progressLbl;
    
    IBOutlet UIImageView *watchSetup;
    IBOutlet UIActivityIndicatorView *activityIndicator;
    
    IBOutlet NSLayoutConstraint *infoLblTopConstraint;
    IBOutlet NSLayoutConstraint *infoLblleftConstraint;
    IBOutlet NSLayoutConstraint *infoLblRightConstraint;
    IBOutlet NSLayoutConstraint *infoLblBottomContraint;
    
    IBOutlet NSLayoutConstraint *progressLblWidthContraint;
    
    IBOutlet CircleProgressBar *mainViewCircleProgress;
    IBOutlet UILabel *percentageLabel;
    IBOutlet UILabel *connectingToWatchLabel;
}

@property (nonatomic ) BOOL openedByMenu;
@property (nonatomic) BOOL openCalibration;

@end
