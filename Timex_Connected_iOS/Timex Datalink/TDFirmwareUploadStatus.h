//
//  TDFirmwareUploadStatus.h
//  Timex
//
//  Created by Lev Verbitsky on 8/29/14.
//  Copyright (c) 2014 iDevices, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TDFirmwareUploadStatusDelegate;


@interface TDFirmwareUploadStatus : UIView

@property (nonatomic) float progress;
@property (nonatomic, strong) NSString *progressText;
@property (nonatomic, strong) NSString *progressTextWarning;//TestLog_M372FirmwareUpdateV2
@property (nonatomic, weak) id<TDFirmwareUploadStatusDelegate> delegate;

+ (id)  sharedInstance: (BOOL) init;

- (void) dismiss;
- (void) allowFirmwareUploadCancellation;
@end

@protocol TDFirmwareUploadStatusDelegate
- (void) cancelFirmwareUpload;
@end
