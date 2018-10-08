//
//  PCCommWhosThere.h
//  Timex Connected
//
//  Created by Lev Verbitsky on 1/22/14.
//  Copyright (c) 2014 iDevices, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#define PCCOMM_SIZE_WHOSTHERE 48

@interface PCCommWhosThere : NSObject

@property (nonatomic) Byte mModeStatus;
@property (nonatomic) Byte mXLinkMajorRev;
@property (nonatomic) Byte mXLinkMinorRev;
@property (nonatomic) Byte mXLinkBuildNum;
@property (nonatomic) Byte mMajorRev;
@property (nonatomic) Byte mMinorRev;
@property (nonatomic) Byte mMajorPlatform;
@property (nonatomic) Byte mMinorPlatform;
@property (nonatomic) Byte mRevision2;
@property (nonatomic) Byte mRevision;
@property (nonatomic, strong) NSString * mModelNumber;
@property (nonatomic, strong) NSString * mProductRev;
@property (nonatomic) long mGPSRev;
@property (nonatomic, strong) NSString *mSerialNumber;


- (id) init: (NSData *) data;

@end
