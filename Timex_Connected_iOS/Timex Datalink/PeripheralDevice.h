//
//  PeripheralDevice.h
//  TIMEX
//
//  Created by Michael Nannini on 2/22/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

#import "TDDevice.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "PeripheralProxy.h"
#import "ProfileData.h"
#import "ProfileObject.h"
#import "TDFirmwareUploadStatus.h"

#import "TDProgressFirmwareUpdate.h"

extern NSString* const kPeripheralDeviceKey;
extern NSString* const kPeripheralDeviceTimexDatalinkPrimaryCharacteristicDiscovered;
extern NSString* const kDeviceSettingsKey;
extern NSString* const kM053DataFileKey;
extern NSString* const kM372SettingsDataFileKey;
extern NSString* const kM328SettingsDataFileKey;
extern NSString* const kSYSBLOCKDataFileKey;
extern NSString* const kM372ActivitiesDataFileKey;
extern NSString* const kM372SleepSummaryFileKey;//TestLog_SleepFiles
extern NSString* const kM372SleepKeyFile;//TestLog_SleepFiles
extern NSString* const kM372ActigraphyDataFile;//TestLog_SleepFiles
extern NSString* const kM372ActigraphyStepFile;
extern NSString* const kM328ActivitiesDataFileKey;
extern NSString* const kDeviceWatchInfoKey;
extern NSString* const kDeviceWatchChargeInfoKey;
extern NSString* const kLastApptCheckTime;
extern NSString* const kLastActivityTrackerSyncSyncDate;
extern NSString* const kBLEandBTCPairingConfirmed;

extern NSString* const kM372FirmwareVersionFile1Key;
extern NSString* const kM372FirmwareVersionFile2Key;
extern NSString* const kM372FirmwareVersionFile3Key;
extern NSString* const kM372FirmwareVersionFile4Key;

@interface PeripheralDevice : TDDevice <ProfileObjectDelegate>
@property (nonatomic, strong) NSData *mFileBytes;
@property (weak, nonatomic) PeripheralProxy* peripheral;
@property (nonatomic, weak) TDFirmwareUploadStatus * progressDialog;
@property (nonatomic) int mLastSyncApptsChecksum;
@property (nonatomic) float firmwareProgress;
@property (nonatomic) BOOL skipWhosThere;
@property (nonatomic, weak) TDProgressFirmwareUpdate *progressFirmware;
@property (nonatomic) int firmwareUpgradePendingFilesCount;

+(ProfileData*) profileData;

//iDevices
+(CBUUID*) timexDatalinkServiceId;
+(CBUUID*) timexDatalinkDataIn1Id;
+(CBUUID*) timexDatalinkDataIn2Id;
+(CBUUID*) timexDatalinkDataIn3Id;
+(CBUUID*) timexDatalinkDataIn4Id;
+(CBUUID*) timexDatalinkDataOut1Id;
+(CBUUID*) timexDatalinkDataOut2Id;
+(CBUUID*) timexDatalinkDataOut3Id;
+(CBUUID*) timexDatalinkDataOut4Id;
+(CBUUID*) timexDatalinkDeviceStateId;

-(void) setDeviceState:(TDDeviceState_t)state;

-(void) setupNotConnectedDeviceWithUUID:(NSString*)uuid;
-(BOOL) hasPeripheral;

- (void) triggerWatchFinder: (BOOL) flag;
- (void) sendApptsToWatch;
- (void) readTimexWorkouts;
- (void) readTimexWatchSettings;
- (void) writeTimexWatchSettings;
- (void) requestDeviceInfo;
- (void) requestDeviceInfoForFirmware;
- (void) requestDeviceInfoForBootloaderStatus;
- (void) requestDeviceChargeInfo;
- (void) requestDeviceChargeInfoForFirmware;
- (void) requestDeviceChargeInfoForFirmwareM372;
- (void) requestWhosThereForFirmwareM328;
- (void) setUpIQForFirmwareUpgrade;
- (void) doFirmwareUpgrade: (NSArray *) upgradeInfo;
- (void) cancelFirmwareUpgrade;

- (void) readM053FullFile;
- (void) writeM053FullFile;
- (void) writeM053ApptsFile;
- (void) writeM053CurrentPhoneTimeAndEnableActivitySensor;

- (void) readTimexWatchActivityData;
- (void) readTimexWatchSleepSummary;//TestLog_SleepFiles
- (void) readTimexWatchSleepKeyFile;//TestLog_SleepFiles
- (void) readTimexWatchSleepActigraphyFiles;//TestLog_SleepFiles

- (void) readTimexWatchActigraphyStepFiles; // Actigraphy step file

- (void) clearPendingActions;

- (BOOL) isFirmwareUpgradePaused;
- (BOOL) isFirmwareUpgradeInProgress;
- (void) endFileAccessSession;
- (void) startFileAccessSession; //Added by Naresh.
- (void) startBootloaderForM372;
- (void) exitBootloaderForM372;
- (void) softResetM372Watch;
- (void) resetM372Watch;
- (void) doBootloaderFirmwareUpgrade: (NSArray *) upgradeInfo;
/**
 *  Resets the pending actions queue . Implemented as a part of
 * firmware upgrade.
 */
-(void)resetPendingActions;

-(void)invalidateAllInternalTimers;
@end
