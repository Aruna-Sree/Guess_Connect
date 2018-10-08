//
//  TDWorkoutDataUploadInfo.h
//  Timex Connected
//
//  Created by Lev Verbitsky on 10/4/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "iDevicesUtil.h"

@interface TDWorkoutDataUploadInfo : NSObject
{
    TimexUploadServicesOptions    uploadSite;
    NSString *                    uploadTime;
}

@property (nonatomic) TimexUploadServicesOptions  uploadSite;
@property (nonatomic, strong) NSString * uploadTime;
@end
