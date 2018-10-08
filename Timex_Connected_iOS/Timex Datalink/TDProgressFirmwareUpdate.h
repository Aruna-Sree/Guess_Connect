//
//  TDProgressFirmwareUpdate.h
//  timex
//
//  Created by Diego Santiago on 6/6/16.
//  Copyright © 2016 iDevices, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CircleProgressBar.h"

@protocol TDProgressFirmwareUpdateDelegate;


@interface TDProgressFirmwareUpdate : UIView
{
    
    IBOutlet UILabel *labelCompleteText;
    
    IBOutlet UILabel *lblTitle;
    
    IBOutlet UILabel *lblMessage;
    
    IBOutlet UILabel *lblAverage;
    IBOutlet UILabel *fileLbl;
    
    IBOutlet UIView *bottomViewContainer;
    IBOutlet NSLayoutConstraint *mainViewCircleProgressHeight;
    IBOutlet NSLayoutConstraint *mainViewCircleProgressWidth;
}
@property (strong, nonatomic) IBOutlet CircleProgressBar *mainViewCircleProgress;
@property (nonatomic) float progress;
@property (nonatomic, strong) NSString *lblTitleString;
@property (nonatomic, strong) NSString *lblMessageString;
@property (nonatomic, strong) NSString *lblCompleteString;
@property (nonatomic, strong) NSString *lblAverageString;
@property (nonatomic, strong) NSString *lblFileString;

@property (nonatomic, weak) id<TDProgressFirmwareUpdateDelegate> delegate;

+ (id)  sharedInstance: (BOOL) init;

- (void) dismiss;
- (void) allowFirmwareUploadCancellation;
@end

@protocol TDProgressFirmwareUpdateDelegate


@end
