//
//  TDProgressFirmwareUpdate.m
//  timex
//
//  Created by Diego Santiago on 6/6/16.
//  Copyright © 2016 iDevices, LLC. All rights reserved.
//

#import "TDProgressFirmwareUpdate.h"
#import "iDevicesUtil.h"
#import "UIImage+Tint.h"
#import "TDDefines.h"



static TDProgressFirmwareUpdate * instance = nil;
@interface TDProgressFirmwareUpdate()
{

}
@end

@implementation TDProgressFirmwareUpdate
@synthesize mainViewCircleProgress;
@synthesize progress = _progress;
@synthesize delegate = _delegate;
@synthesize lblCompleteString = _lblCompleteString;
@synthesize lblMessageString = _lblMessageString;
@synthesize lblTitleString = _lblTitleString;
@synthesize lblAverageString = _lblAverageString;
@synthesize lblFileString = _lblFileString;

+(id) sharedInstance: (BOOL) init
{
    if (!instance && init == TRUE)
    {
        instance = [[[NSBundle mainBundle] loadNibNamed: @"TDProgressFirmwareUpdate" owner:self options:nil] objectAtIndex:0];
        
        CGRect frame = instance.frame;
        frame.origin.y -= frame.size.height;
        instance.frame = frame;
        
        instance->_progress = MAXFLOAT;
    }
    return instance;
}
- (void) dismiss
{
    __weak TDProgressFirmwareUpdate * weakSelf = self;
    
    [UIView animateWithDuration: 0.5f animations:^
     {
         TDProgressFirmwareUpdate * strongSelf = weakSelf;
         
         CGRect frame = strongSelf.frame;
         frame.origin.y -= frame.size.height;
         strongSelf.frame = frame;
     }
                     completion:^(BOOL finished)
     {
         TDProgressFirmwareUpdate * strongSelf = weakSelf;
         
         [strongSelf removeFromSuperview];
         instance = nil;
     }];
}
- (void) setProgress:(float)progress
{
    _progress = progress;
   
    [bottomViewContainer setHidden:NO];
    [mainViewCircleProgress setProgress:_progress animated:YES];
    [mainViewCircleProgress setHintHidden:YES];
    [mainViewCircleProgress setProgressBarProgressColor:UIColorFromRGB(M328_PROGRESS_GREEN_COLOR)];
    [mainViewCircleProgress setProgressBarTrackColor:UIColorFromRGB(COLOR_LIGHT_GRAY)];
    [mainViewCircleProgress setProgressBarWidth: 13.0];
    [mainViewCircleProgress setStartAngle: -80.0];
    
    [mainViewCircleProgressWidth setConstant:150];
    [mainViewCircleProgressHeight setConstant:150];
    
    if (IS_IPAD)
    {
        [mainViewCircleProgressWidth setConstant:200];
        [mainViewCircleProgressHeight setConstant:200];
    }
}

- (void) allowFirmwareUploadCancellation
{
    
}

- (void) setLblTitleString:(NSString *)lblTitleString
{
    _lblTitleString = lblTitleString;
    
    lblTitle.adjustsFontSizeToFitWidth = true;
    lblTitle.minimumScaleFactor = 0.5;
    lblTitle.font = [UIFont fontWithName:@"Roboto-Regular" size:30];
    
    lblTitle.text = _lblTitleString;
}

- (void) setLblMessageString:(NSString *)lblMessageString
{
    _lblMessageString = lblMessageString;
    
    lblMessage.adjustsFontSizeToFitWidth = true;
    lblMessage.minimumScaleFactor = 0.5;
    lblMessage.font = [UIFont fontWithName:@"Roboto-Light" size:20];

    
    
    lblMessage.text = _lblMessageString;
}

- (void) setLblCompleteString:(NSString *)lblCompleteString
{
    _lblCompleteString = lblCompleteString;
    
    labelCompleteText.adjustsFontSizeToFitWidth = true;
    labelCompleteText.minimumScaleFactor = 0.5;
    labelCompleteText.font = [UIFont fontWithName:@"Roboto-Light" size:20];
    
    
    labelCompleteText.text = _lblCompleteString;
}

- (void) setLblAverageString:(NSString *)lblAverageString
{
    _lblAverageString = lblAverageString;
    
    lblAverage.adjustsFontSizeToFitWidth = true;
    lblAverage.minimumScaleFactor = 0.5;
    lblAverage.font = [UIFont fontWithName:@"Roboto-Light" size:20];
    
    if (IS_IPAD)
    {
        lblAverage.font = [UIFont fontWithName:@"Roboto-Light" size:40];
    }
    
    lblAverage.text = _lblAverageString;
}

- (void) setLblFileString:(NSString *)lblFileString
{
    _lblFileString = lblFileString;
    
    fileLbl.adjustsFontSizeToFitWidth = true;
    fileLbl.minimumScaleFactor = 0.5;
    fileLbl.font = [UIFont fontWithName:@"Roboto-Light" size:15];
    
    fileLbl.text = _lblFileString;
}

@end
