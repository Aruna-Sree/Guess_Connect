//
//  TDDevice.h
//  Timex Connected
//
//  Created by Lev Verbitsky on 9/12/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TDDeviceProfile;

typedef enum
{
    TDDeviceType_None = 0,
    TDDeviceType_Classic,
    TDDeviceType_Pro,
    TDDeviceType_Metropolitan,
    TDDeviceType_IQMove,
    TDDeviceType_IQTravel
} TDDeviceType;

typedef struct
{
    NSUInteger dataLogInt;
    BOOL wrappedLog;
    NSUInteger MTR;
    NSUInteger security;
} TDDeviceSettings;


typedef struct
{
    BOOL erasedLog;
    BOOL blinkedLED;
    BOOL restoredDefaults;
} TDDeviceCommands;


extern NSString* const kTDDeviceDataUpdatedNotification;
extern NSString* const kTDDeviceReadingDataUpdatedNotification;
extern NSString* const kTDDeviceSettingsChangedNotification;
extern NSString* const kTDM053ReadSuccessfullyNotification;
extern NSString* const kTDM053ReadUnsuccessfullyNotification;
extern NSString* const kTDSettingsReadSuccessfullyNotification;
extern NSString* const kTDSettingsReadUnsuccessfullyNotification;
extern NSString* const kTDM372SettingsReadSuccessfullyNotification;
extern NSString* const kTDM372SettingsReadUnsuccessfullyNotification;
extern NSString* const kTDM372ActivitiesReadSuccessfullyNotification;
extern NSString* const kTDM372ActivitiesReadUnsuccessfullyNotification;
extern NSString* const kTDM328SettingsReadSuccessfullyNotification;
extern NSString* const kTDM328SettingsReadUnsuccessfullyNotification;
extern NSString* const kTDM328ActivitiesReadSuccessfullyNotification;
extern NSString* const kTDM328ActivitiesReadUnsuccessfullyNotification;
extern NSString* const kTDSettingsWrittenSuccessfullyNotification;
extern NSString* const kTDSettingsWrittenUnsuccessfullyNotification;
extern NSString* const kTDWorkoutsReadSuccessfullyNotification;
extern NSString* const kTDWorkoutsReadUnsuccessfullyNotification;
extern NSString* const kTDSYSBLOCKReadSuccessfullyNotification;
extern NSString* const kTDSYSBLOCKReadUnsuccessfullyNotification;
extern NSString* const kTDApptsWrittenUnsuccessfullyNotification;
extern NSString* const kTDApptsWrittenSuccessfullyNotification;
extern NSString* const kTDPhoneTimeWrittenUnsuccessfullyNotification;
extern NSString* const kTDPhoneTimeWrittenSuccessfullyNotification;
extern NSString* const kTDWorkoutsAutoUploadedNotification;
extern NSString* const kTDWatchInfoReadSuccessfullyNotification;
extern NSString* const kTDWatchInfoReadUnsuccessfullyNotification;
extern NSString* const kTDWatchInfoFWReadSuccessfullyNotification;
extern NSString* const kTDWatchInfoBootloaderReadUnsuccessfullyNotification;
extern NSString* const kTDWatchInfoBootloaderReadSuccessfullyNotification;
extern NSString* const kTDWatchInfoFWReadUnsuccessfullyNotification;
extern NSString* const kTDWatchChargeInfoReadSuccessfullyNotification;
extern NSString* const kTDWatchChargeInfoReadUnsuccessfullyNotification;
extern NSString* const kTDWatchChargeInfoFWReadSuccessfullyNotification;
extern NSString* const kTDWatchChargeInfoFWReadUnsuccessfullyNotification;
extern NSString* const kTDFirmwareWrittenSuccessfullyNotification;
extern NSString* const kTDBootloaderFirmwareWrittenSuccessfullyNotification;
extern NSString* const kTDFirmwareUpdateCancelledNotification;
extern NSString* const kTDFirmwareWrittenUnsuccessfullyNotification;
extern NSString* const kTDFullPairingWithWatchConfirmed;
extern NSString* const kTDPhoneFinderCancelledNotification;
extern NSString* const kTDFirmwareUpdateResumed;
extern NSString* const kTDM372BootloaderModeRequested;
extern NSString* const kTDDeviceKey;
extern NSString* const kTDM372UnexpectedBootloaderModeDetected;
extern NSString* const kTDM372UnexpectedBootloaderModeDetectedAndApproved;

extern NSString* const kTDApptsWritingStartedNotification;
//TestLog_SleepFIles


extern NSString* const kTDM372SleepActigraphyDataSuccessfullyNotification;
extern NSString* const kTDM372SleepActigraphyDataUnsuccessfullyNotification;

extern NSString* const kTDM372SleepSummarySuccessfullyNotification;
extern NSString* const kTDM372SleepSummaryUnsuccessfullyNotification;

extern NSString* const kTDM372SleepKeyFileReadSuccessfullyNotification;
extern NSString* const kTDM372SleepKeyFileReadUnsuccessfullyNotification;
extern NSString* const kTDM328DidNotRecieveBLEResponse;
extern NSString* const kTDM328SessionStartNotification;
//TestLog_SleepFiles

// Actigraphy step file
extern NSString* const kTDM372ActigraphyStepFileDataSuccessfullyNotification;
extern NSString* const kTDM372ActigraphyStepFileDataUnsuccessfullyNotification;

extern DEBUG_CONST float kOORRSSIValue;
extern DEBUG_CONST int   kMedianRSSIEntryCount;
extern DEBUG_CONST float kBaseRSSIValue;
extern DEBUG_CONST float kBaseDistance;
extern DEBUG_CONST BOOL  kUseMedianRSSI;

typedef enum
{
    kTDDeviceState_NotConnected = 0,
    kTDDeviceState_OutOfRange,
    kTDDeviceState_Connecting,
    kTDDeviceState_Connected,
    kTDDeviceState_OTAUpgrade,
    kTDDeviceState_Total
    
} TDDeviceState_t;


@interface TDDevice : NSObject
{
    TDDeviceState_t          _deviceState;
    int                      _rssi;
    double                   _rssiVelocity;
    NSString*                _deviceID;
    int                      _updateProgress;
    float                    _range;
    TDDeviceSettings         _deviceSettings;
    NSString*                _deviceType;
    TDDeviceType             _type;
    
}

@property (nonatomic, readonly) TDDeviceState_t deviceState;
@property (strong,nonatomic)    NSString        *fwVersion;
@property (strong,nonatomic)    NSString        *moduleFWVersion;
@property (strong,nonatomic)    NSString        *manufacturer;
@property (strong,nonatomic)    NSString        *hardwareVersion;
@property (strong,nonatomic)    NSString        *model;
@property (strong,nonatomic)    NSString        *name;
@property (strong,nonatomic)    NSString        *serialnum;
@property (nonatomic, readonly) NSTimeInterval  discoveredTime;

@property (nonatomic, assign)   TDDeviceSettings deviceSettings;
@property (nonatomic, readonly) NSString         * deviceID;

@property (nonatomic, assign)   NSInteger        batteryLevel;
@property (nonatomic, readonly) int              RSSI;
@property (nonatomic, readonly) double           RSSIVelocity;
@property (nonatomic, readonly) float            range;
@property (nonatomic, readonly) float            normalRange;

@property (nonatomic, assign) TDDeviceType       type;

@property (strong,nonatomic) TDDeviceProfile     * deviceProfile;

+(NSInteger) sortValueForDeviceState:(TDDeviceState_t)state;

-(BOOL) thresholdAlertsEnabled;
-(void) disconnect;
-(void) forgetDevice;
@end
