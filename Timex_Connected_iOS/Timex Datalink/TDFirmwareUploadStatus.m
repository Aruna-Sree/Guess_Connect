//
//  TDFirmwareUploadStatus.m
//  Timex
//
//  Created by Lev Verbitsky on 8/29/14.
//  Copyright (c) 2014 iDevices, LLC. All rights reserved.
//

#import "TDFirmwareUploadStatus.h"
#import "iDevicesUtil.h"

static TDFirmwareUploadStatus * instance = nil;

@interface TDFirmwareUploadStatus()
{
    IBOutlet UIProgressView *progressView;
    IBOutlet UIImageView    *pauseButton;
    IBOutlet UILabel        *progressDialogText;
    IBOutlet UILabel        *progressDialogWarning;//TestLog_M372FirmwareUpdateV2
    
    BOOL                    cancellationAllowed;
}
@end



@implementation TDFirmwareUploadStatus

@synthesize progress = _progress;
@synthesize progressText = _progressText;
@synthesize progressTextWarning = _progressTextWarning;;
@synthesize delegate = _delegate;

+(id) sharedInstance: (BOOL) init
{
	if (!instance && init == TRUE)
	{
		instance = [[[NSBundle mainBundle] loadNibNamed: [iDevicesUtil getViewControllerToPush: [TDFirmwareUploadStatus class]] owner:self options:nil] objectAtIndex:0];
        
        CGRect frame = instance.frame;
        frame.origin.y -= frame.size.height;
        instance.frame = frame;
        
        [instance->pauseButton setHidden: TRUE];//TestLog_M372FirmwareUpdateV2_changedTheValue
        instance->_progress = MAXFLOAT;
        instance->cancellationAllowed = FALSE;//TestLog_M372FirmwareUpdateV2_changedTheValue
	}
	
	return instance;
}
- (void) allowFirmwareUploadCancellation
{
    [instance->pauseButton setHidden: FALSE];
    cancellationAllowed = TRUE;
}
- (void) dismiss
{
    __weak TDFirmwareUploadStatus * weakSelf = self;
    
    [UIView animateWithDuration: 0.5f animations:^
     {
         TDFirmwareUploadStatus * strongSelf = weakSelf;
         
         CGRect frame = strongSelf.frame;
         frame.origin.y -= frame.size.height;
         strongSelf.frame = frame;
     }
     completion:^(BOOL finished)
     {
         TDFirmwareUploadStatus * strongSelf = weakSelf;
         
         [strongSelf removeFromSuperview];
         instance = nil;
     }];
}

-(IBAction) CancelFirmwareUpload
{
    if (_delegate != nil && cancellationAllowed)
    {
        [_delegate cancelFirmwareUpload];
    }
}

- (void) setProgress:(float)progress
{
    _progress = progress;
    progressView.progress = _progress;
}

- (void) setProgressText:(NSString *)progressText
{
    _progressText = progressText;
    progressDialogText.text = progressText;
}

//TestLog_M372FirmwareUpdateV2 start
- (void) setProgressTextWarning:(NSString *)progressTextWarning
{
    _progressTextWarning = progressTextWarning;
    progressDialogWarning.text = progressTextWarning;
}
//TestLog_M372FirmwareUpdateV2 end

@end
