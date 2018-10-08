//
//  TDDevice.m
//  Timex Connected
//
//  Created by Lev Verbitsky on 9/12/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

#import <pthread.h>

#import "TDDevice.h"
#import "iDevicesUtil.h"
#import "TDDeviceManager.h"
#import "OTLogUtil.h"

NSString* const kTDDeviceDataUpdatedNotification = @"kTDDeviceDataUpdatedNotification";

NSString* const kTDDeviceReadingDataUpdatedNotification = @"kTDDeviceReadingDataUpdatedNotification";
NSString* const kTDDeviceSettingsChangedNotification = @"kTDDeviceSettingsChangedNotification";
NSString* const kTDDeviceKey = @"kTDDeviceKey";

NSString* const kTDM053ReadSuccessfullyNotification = @"kTDM053ReadSuccessfullyNotification";
NSString* const kTDM053ReadUnsuccessfullyNotification = @"kTDM053ReadUnsuccessfullyNotification";
NSString* const kTDSettingsReadSuccessfullyNotification = @"kTDSettingsReadSuccessfullyNotification";
NSString* const kTDSettingsReadUnsuccessfullyNotification = @"kTDSettingsReadUnsuccessfullyNotification";
NSString* const kTDM372SettingsReadSuccessfullyNotification = @"kTDM372SettingsReadSuccessfullyNotification";
NSString* const kTDM372SettingsReadUnsuccessfullyNotification = @"kTDM372SettingsReadUnsuccessfullyNotification";
NSString* const kTDM372ActivitiesReadSuccessfullyNotification = @"kTDM372ActivitiesReadSuccessfullyNotification";
NSString* const kTDM372ActivitiesReadUnsuccessfullyNotification = @"kTDM372ActivitiesReadUnsuccessfullyNotification";
NSString* const kTDM328SettingsReadSuccessfullyNotification = @"kTDM328SettingsReadSuccessfullyNotification";
NSString* const kTDM328SettingsReadUnsuccessfullyNotification = @"kTDM328SettingsReadUnsuccessfullyNotification";
NSString* const kTDM328ActivitiesReadSuccessfullyNotification = @"kTDM328ActivitiesReadSuccessfullyNotification";
NSString* const kTDM328ActivitiesReadUnsuccessfullyNotification = @"kTDM328ActivitiesReadUnsuccessfullyNotification";
NSString* const kTDSettingsWrittenSuccessfullyNotification = @"kTDSettingsWrittenSuccessfullyNotification";
NSString* const kTDSettingsWrittenUnsuccessfullyNotification = @"kTDSettingsWrittenUnsuccessfullyNotification";
NSString* const kTDWorkoutsReadSuccessfullyNotification = @"kTDWorkoutsReadSuccessfullyNotification";
NSString* const kTDWorkoutsReadUnsuccessfullyNotification = @"kTDWorkoutsReadUnsuccessfullyNotification";
NSString* const kTDSYSBLOCKReadSuccessfullyNotification = @"kTDSYSBLOCKReadSuccessfullyNotification";
NSString* const kTDSYSBLOCKReadUnsuccessfullyNotification = @"kTDSYSBLOCKReadUnsuccessfullyNotification";
NSString* const kTDWorkoutsAutoUploadedNotification = @"kTDWorkoutsAutoUploadedNotification";
NSString* const kTDApptsWrittenUnsuccessfullyNotification = @"kTDApptsWrittenUnsuccessfullyNotification";
NSString* const kTDApptsWrittenSuccessfullyNotification = @"kTDApptsWrittenSuccessfullyNotification";
NSString* const kTDPhoneTimeWrittenUnsuccessfullyNotification = @"kTDPhoneTimeWrittenUnsuccessfullyNotification";
NSString* const kTDPhoneTimeWrittenSuccessfullyNotification = @"kTDPhoneTimeWrittenSuccessfullyNotification";
NSString* const kTDWatchInfoReadSuccessfullyNotification = @"kTDWatchInfoReadSuccessfullyNotification";
NSString* const kTDWatchInfoReadUnsuccessfullyNotification = @"kTDWatchInfoReadUnsuccessfullyNotification";
NSString* const kTDWatchInfoFWReadSuccessfullyNotification = @"kTDWatchInfoFWReadSuccessfullyNotification";
NSString* const kTDWatchInfoBootloaderReadUnsuccessfullyNotification = @"kTDWatchInfoBootloaderReadUnsuccessfullyNotification";
NSString* const kTDWatchInfoBootloaderReadSuccessfullyNotification = @"kTDWatchInfoBootloaderReadSuccessfullyNotification";
NSString* const kTDWatchInfoFWReadUnsuccessfullyNotification = @"kTDWatchInfoFWReadUnsuccessfullyNotification";
NSString* const kTDWatchChargeInfoReadSuccessfullyNotification = @"kTDWatchChargeInfoReadSuccessfullyNotification";
NSString* const kTDWatchChargeInfoReadUnsuccessfullyNotification = @"kTDWatchChargeInfoReadUnsuccessfullyNotification";
NSString* const kTDWatchChargeInfoFWReadSuccessfullyNotification = @"kTDWatchChargeInfoFWReadSuccessfullyNotification";
NSString* const kTDWatchChargeInfoFWReadUnsuccessfullyNotification = @"kTDWatchChargeInfoFWReadUnsuccessfullyNotification";
NSString* const kTDFirmwareWrittenSuccessfullyNotification = @"kTDFirmwareWrittenSuccessfullyNotification";
NSString* const kTDBootloaderFirmwareWrittenSuccessfullyNotification = @"kTDBootloaderFirmwareWrittenSuccessfullyNotification";
NSString* const kTDFirmwareUpdateCancelledNotification = @"kTDFirmwareUpdateCancelledNotification";
NSString* const kTDFirmwareWrittenUnsuccessfullyNotification = @"kTDFirmwareWrittenUnsuccessfullyNotification";
NSString* const kTDFullPairingWithWatchConfirmed = @"kTDFullPairingWithWatchConfirmed";
NSString* const kTDPhoneFinderCancelledNotification = @"kTDPhoneFinderCancelledNotification";
NSString* const kTDM372BootloaderModeRequested = @"kTDM372BootloaderModeRequested";
NSString* const kTDFirmwareUpdateResumed = @"kTDFirmwareUpdateResumed";
NSString* const kTDM372UnexpectedBootloaderModeDetected = @"kTDM372UnexpectedBootloaderModeDetected";
NSString* const kTDM328UnexpectedBootloaderModeDetected = @"kTDM328UnexpectedBootloaderModeDetected";
NSString* const kTDM372UnexpectedBootloaderModeDetectedAndApproved = @"kTDM372UnexpectedBootloaderModeDetectedAndApproved";

NSString* const kTDApptsWritingStartedNotification = @"kTDApptsWritingStartedNotification";

//TestLog_SleepFiles
NSString* const kTDM372SleepActigraphyDataSuccessfullyNotification = @"kTDM372SleepActigraphyDataSuccessfullyNotification";
NSString* const kTDM372SleepActigraphyDataUnsuccessfullyNotification = @"kTDM372SleepActigraphyDataUnsuccessfullyNotification";

NSString* const kTDM372SleepSummarySuccessfullyNotification = @"kTDM372SleepSummarySuccessfullyNotification";
NSString* const kTDM372SleepSummaryUnsuccessfullyNotification = @"kTDM372SleepSummaryUnsuccessfullyNotification";

NSString* const kTDM372SleepKeyFileReadSuccessfullyNotification = @"kTDM372SleepKeyFileReadSuccessfullyNotification";
NSString* const kTDM372SleepKeyFileReadUnsuccessfullyNotification = @"kTDM372SleepKeyFileReadUnsuccessfullyNotification";
NSString* const kTDM328DidNotRecieveBLEResponse = @"kTDM328DidNotRecieveBLEResponse";

NSString* const kTDM372ActigraphyStepFileDataSuccessfullyNotification = @"kTDM372ActigraphyStepFileDataSuccessfullyNotification";
NSString* const kTDM372ActigraphyStepFileDataUnsuccessfullyNotification = @"kTDM372ActigraphyStepFileDataUnsuccessfullyNotification";

// For M328 Session start
NSString* const kTDM328SessionStartNotification = @"kTDM328SessionStartNotification"; // When session starts.

//TestLog_SleepFiles

DEBUG_CONST float kOORRSSIValue = -94.f;
DEBUG_CONST int   kMedianRSSIEntryCount = 5;
DEBUG_CONST float kBaseRSSIValue = -100.f;
DEBUG_CONST float kBaseDistance = 100.f;
DEBUG_CONST BOOL  kUseMedianRSSI = YES;

@interface TDDevice ()
{
    BOOL _thresholdAlertsEnabled;
}

@end

@implementation TDDevice

@synthesize fwVersion = _fwVersion;
@synthesize name = _name;
@synthesize serialnum = _serialnum;
@synthesize moduleFWVersion = _moduleFWVersion;
@synthesize manufacturer = _manufacturer;
@synthesize hardwareVersion = _hardwareVersion;
@synthesize model = _model;
@synthesize type = _type;
@synthesize deviceState=_deviceState;
@synthesize batteryLevel;
@synthesize RSSIVelocity= _rssiVelocity;
@synthesize range=_range;
@synthesize deviceProfile = _deviceProfile;

@synthesize deviceSettings = _deviceSettings;


@class TDDeviceProfile;

+(NSInteger) sortValueForDeviceState:(TDDeviceState_t)state
{
    static const NSInteger values[kTDDeviceState_Total] = {20, 2, 3, 1, 10};
    
    if ( state < kTDDeviceState_Total )
    {
        return values[state];
    }
    
    return 1000;
}

-(NSString *)serialnum
{
    return nil;
}

-(NSString*) deviceID
{
    return _deviceID;
}

-(int) RSSI
{
    return _rssi;
}

-(NSString*) name
{
    return _name;
}

-(float) normalRange
{
    float range;
    
    range = _range / kBaseDistance;
    
    range = 1.f - range;
    
    range = MAX( range, 0.f );
    range = MIN( range, 1.f);
    
    return range;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        _deviceState = kTDDeviceState_NotConnected;
        _rssiVelocity = 0;
        _rssi = 0;
        _range = kBaseDistance;
        _deviceID = @"MISSING";
    }
    return self;
}
-(void) dealloc
{
    OTLog(@"TDDevice Dealloc");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setSerialnum:(NSString *)serialnum
{
    _serialnum  = serialnum;
    [[NSNotificationCenter defaultCenter] postNotificationName:kTDDeviceDataUpdatedNotification object:self];
}

- (void)setFwVersion:(NSString *)fwVersion
{
    _fwVersion = fwVersion;
    [[NSNotificationCenter defaultCenter] postNotificationName:kTDDeviceDataUpdatedNotification object:self];
}

- (void)setModuleFWVersion:(NSString *)moduleFWVersion
{
    _moduleFWVersion = moduleFWVersion;
    [[NSNotificationCenter defaultCenter] postNotificationName:kTDDeviceDataUpdatedNotification object:self];
}

-(void) setBatteryLevel:(NSInteger)bl
{
    batteryLevel = bl;
    [[NSNotificationCenter defaultCenter] postNotificationName:kTDDeviceDataUpdatedNotification object:self];
    
}

-(void) setDeviceSettings:(TDDeviceSettings)deviceSettings
{
    _deviceSettings = deviceSettings;
    [[NSNotificationCenter defaultCenter] postNotificationName:kTDDeviceDataUpdatedNotification object:self];
    
}

- (void)setType:(TDDeviceType)type
{
    _type = type;
    [[NSNotificationCenter defaultCenter] postNotificationName:kTDDeviceDataUpdatedNotification object:self];
}

-(BOOL) thresholdAlertsEnabled
{
    return _thresholdAlertsEnabled;
}

-(void) forgetDevice
{
}

-(void) disconnect
{
    _deviceState = kTDDeviceState_NotConnected;
}

-(TDDeviceType) type
{
    return _type;
}

-(TDDeviceSettings) deviceSettings
{
    return _deviceSettings;
}




@end
