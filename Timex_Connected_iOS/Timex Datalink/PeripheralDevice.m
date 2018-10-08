//
//  PeripheralDevice.m
//  Kestrel
//
//  Created by Michael Nannini on 2/22/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

#import "PeripheralDevice.h"
#import "BatteryService.h"
#import "DeviceInformationService.h"
#import "BLEManager.h"
#import "iDevicesUtil.h"
#import "TDDeviceManager.h"
#import "TDDeviceProfile.h"
#import "CharacteristicProxy.h"
#import "ServiceProxy.h"
#import "BLECharacteristic.h"
#import "PeripheralUtility.h"
#import "PCCPacket.h"
#import "PCCHeader.h"
#import "NSData+AES128.h"
#import "NSString+HexString.h"
#import "PCCommCommands.h"
#import "TDM053WatchData.h"
#import "TDDatacastWatchSettings.h"
#import "TDDatacastWorkoutsParser.h"
#import "TDDatacastApptsParser.h"
#import "PCCommWhosThere.h"
#import "PCCommChargeInfo.h"
#import "PCCommExtendedFirmwareVersionInfo.h"
#import "TDAudioPlayer.h"
#import "TDDatacastFirmwareUpgradeInfo.h"
#import "TDConnectionStatusWindow.h"
#import "TDWatchProfile.h"
#import "TDFlurryDataPacket.h"
#import "TDM372WatchSettings.h"
#import "TDM372WatchActivity.h"
#import <AudioToolbox/AudioServices.h>
//TestLog_SleepFiles
#import "TDM372SleepSummaryFile.h"
#import "TDM372ActigraphyKeyFile.h"
#import "TDM372ActigraphyDataFile.h"
//TestLog_SleepFiles
#import "TDM328WatchSettings.h"
#import "TDM329WatchSettings.h"
#import "OTLogUtil.h"
#import "SYSBLOCKSettings.h"
#import "TDM372ActigraphyStepFile.h"
//IDevices Services
#define TIMEX_SERVICE_LOCALID (0x19730000)

#define TIMEX_SERVICE_DATAIN1_LOCALID (0x19730001)
#define TIMEX_SERVICE_DATAIN2_LOCALID (0x19730002)
#define TIMEX_SERVICE_DATAIN3_LOCALID (0x19730003)
#define TIMEX_SERVICE_DATAIN4_LOCALID (0x19730004)
#define TIMEX_SERVICE_DATAOUT1_LOCALID (0x19730005)
#define TIMEX_SERVICE_DATAOUT2_LOCALID (0x19730006)
#define TIMEX_SERVICE_DATAOUT3_LOCALID (0x19730007)
#define TIMEX_SERVICE_DATAOUT4_LOCALID (0x19730008)
#define TIMEX_SERVICE_DEVICESTATE_LOCALID (0x19730009)

#define UPDATE_DELAY (0)
#define ACK_NO_ERROR 0

#if DEBUG

#define SKIP_SERIAL_NUMBER (0)

#endif

NSString* const kPeripheralDeviceTimexDatalinkPrimaryCharacteristicDiscovered = @"kPeripheralDeviceTimexDatalinkPrimaryCharacteristicDiscovered";
NSString* const kPeripheralDeviceKey = @"kPeripheralDeviceKey";
NSString* const kM053DataFileKey = @"kM053DataFileKey";
NSString* const kM372SettingsDataFileKey = @"kM372SettingsDataFileKey";
NSString* const kM328SettingsDataFileKey = @"kM328SettingsDataFileKey";
NSString* const kSYSBLOCKDataFileKey = @"kSYSBLOCKDataFileKey";
NSString* const kM372ActivitiesDataFileKey = @"kM372ActivitiesDataFileKey";
NSString* const kM328ActivitiesDataFileKey = @"kM328ActivitiesDataFileKey";
NSString* const kM372SleepSummaryFileKey = @"kM372SleepSummaryFileKey";//TestLog_SleepFiles
NSString* const kM372SleepKeyFile = @"kM372SleepKeyFile";//TestLog_SleepFiles
NSString* const kM372ActigraphyDataFile = @"kM372ActigraphyDataFile";//TestLog_SleepFiles
NSString* const kM372ActigraphyStepFile = @"kM372ActigraphyStepFile";
NSString* const kDeviceSettingsKey = @"kDeviceSettingsKey";
NSString* const kDeviceWatchInfoKey = @"kDeviceWatchInfoKey";
NSString* const kDeviceWatchChargeInfoKey = @"kDeviceWatchChargeInfoKey";
NSString* const kLastApptCheckTime = @"kLastApptCheckTime";
NSString* const kLastActivityTrackerSyncSyncDate = @"kLastActivityTrackerSyncSyncDate";
NSString* const kBLEandBTCPairingConfirmed = @"kBLEandBTCPairingConfirmed";
NSString* const kM372FirmwareVersionFile1Key = @"kM372FirmwareVersionFile1Key";
NSString* const kM372FirmwareVersionFile2Key = @"kM372FirmwareVersionFile2Key";
NSString* const kM372FirmwareVersionFile3Key = @"kM372FirmwareVersionFile3Key";
NSString* const kM372FirmwareVersionFile4Key = @"kM372FirmwareVersionFile4Key";

//Services
static CBUUID*  s_TimexDatalinkService;

//Chars
static CBUUID*  s_timexDatalinkDataIn1Id;
static CBUUID*  s_timexDatalinkDataIn2Id;
static CBUUID*  s_timexDatalinkDataIn3Id;
static CBUUID*  s_timexDatalinkDataIn4Id;
static CBUUID*  s_timexDatalinkDataOut1Id;
static CBUUID*  s_timexDatalinkDataOut2Id;
static CBUUID*  s_timexDatalinkDataOut3Id;
static CBUUID*  s_timexDatalinkDataOut4Id;
static CBUUID*  s_timexDatalinkDeviceStateId;

static ProfileData* s_profileData;

@interface RSSIEntry : NSObject

@property (nonatomic, assign) int value;
@property (nonatomic, assign) NSTimeInterval timeStamp;

@end

@implementation RSSIEntry

@synthesize value;
@synthesize timeStamp;

@end

typedef enum
{
    kPeripheralDeviceState_Connecting = 0,
    kPeripheralDeviceState_Authenticating,
    kPeripheralDeviceState_ValidatingKey,
    kPeripheralDeviceState_ValidatingFirmware,
    kPeripheralDeviceState_Ready,
    
    kPeripheralDeviceState_Total
} PeripheralDeviceState;



@interface PeripheralDevice () <BatteryServiceDelegate, TDConnectionStatusWindowDelegate, UIAlertViewDelegate>
{
    __weak PeripheralProxy*         _peripheral;
    
    BatteryService*                 _batteryService;
    DeviceInformationService*       _deviceInfoService;
    ProfileObject*                  _profileObject;
    NSTimer*                        _rssiTimer;
    NSTimer*                        _myTempTimer;
    NSMutableArray*                 _rssiHistory;
    NSMutableArray*                 _firmwareBinary;
    NSInteger                       _updateTotalSize;
    
    TDDeviceProfile *               _deviceData;
    PeripheralDeviceState           _perphState;

    
    NSMutableArray *                _mPacketHandle;
    NSMutableArray *                _mReceivePackets;
    NSMutableArray *                _mTransmitPackets;
    PCCommWhosThere *               _mPCCommWhosThereInfo;
    int                             _mAction;
    int                             _mFileSize;
    Byte                            _mFileHandle;
    int                             _mStatus;
    int                             _mCharacteristicCount;
    
    NSMutableArray *                _mFirmwareUpgradePendingFiles;
    NSInteger                       _mFirmwareUpgradeProcessedFileIndex;
    BOOL                            _mFirmwareUpgradeCancelled;
    BOOL                            _mFirmwareUpgradePaused;
    NSInteger                       _mFirmwareTotalPacketsCount;
    
    NSMutableArray *                _mPendingActions;
    NSTimer *                       _mBLEREsponseTimer;
    
    TDConnectionStatusWindow *      _mPhoneFinderStatus;
    UIAlertView    *                _bootloaderModeOnAlert;
}

-(void) _updateValues;

-(void) _peripheralConnected:(PeripheralProxy*)peripheral;

-(void) _peripheralDisconnected:(PeripheralProxy*) peripheral;

-(void) _blePeripheralConnected:(NSNotification*)notification;

-(void) _blePeripheralDisconnected:(NSNotification*)notification;

-(void) _retrieveCharacteristics:(ServiceProxy*)service;

-(void) _readCharacteristic:(CharacteristicProxy*)characteristic;

-(void) _rssiUpdated:(PeripheralProxy*)peripheral;

-(void) _calcuateRSSIVelocity;

-(void) _upgradeWriteNextLine:(CharacteristicProxy*)characteristic;

-(void) _loadStoredDeviceData;

@end

@implementation PeripheralDevice

@synthesize peripheral=_peripheral;
@synthesize mLastSyncApptsChecksum = _mLastSyncApptsChecksum;
@synthesize progressDialog = _progressDialog;

@synthesize progressFirmware = _progressFirmware;

-(BOOL) hasPeripheral
{
    OTLog(@"PeripheralDevice hasPeripheral");
    if (_peripheral)
        return YES;
    
    return NO;
}

+(ProfileData*) profileData
{
    OTLog(@"PeripheralDevice profileData");
    if ( s_profileData == nil )
    {
        s_profileData = [ProfileData loadProfileData:@"ProfileData"];
    }
    
    return s_profileData;
}

#pragma mark - iDevices Module Services

+(CBUUID*) timexDatalinkServiceId
{
    if ( s_TimexDatalinkService == nil )
    {
        ProfileData* profileData = [PeripheralDevice profileData];
        ServiceData* service = [profileData serviceDataForLocalId:[NSNumber numberWithUnsignedInt:TIMEX_SERVICE_LOCALID]];
        s_TimexDatalinkService = service.uuid;
    }
    
    return s_TimexDatalinkService;
}

+(CBUUID*) timexDatalinkDataIn1Id
{
    if ( s_timexDatalinkDataIn1Id == nil )
    {
        ProfileData* profileData = [PeripheralDevice profileData];
        ServiceData* service = [profileData serviceDataForLocalId:[NSNumber numberWithUnsignedInt:TIMEX_SERVICE_LOCALID]];
        CharacteristicData* charData = [service characteristicDataForLocalId:[NSNumber numberWithUnsignedInt:TIMEX_SERVICE_DATAIN1_LOCALID]];
        
        s_timexDatalinkDataIn1Id = charData.uuid;
    }
    
    return s_timexDatalinkDataIn1Id;
}

+(CBUUID*) timexDatalinkDataIn2Id
{
    if ( s_timexDatalinkDataIn2Id == nil )
    {
        ProfileData* profileData = [PeripheralDevice profileData];
        ServiceData* service = [profileData serviceDataForLocalId:[NSNumber numberWithUnsignedInt:TIMEX_SERVICE_LOCALID]];
        CharacteristicData* charData = [service characteristicDataForLocalId:[NSNumber numberWithUnsignedInt:TIMEX_SERVICE_DATAIN2_LOCALID]];
        
        s_timexDatalinkDataIn2Id = charData.uuid;
    }
    
    return s_timexDatalinkDataIn2Id;
}

+(CBUUID*) timexDatalinkDataIn3Id
{
    if ( s_timexDatalinkDataIn3Id == nil )
    {
        ProfileData* profileData = [PeripheralDevice profileData];
        ServiceData* service = [profileData serviceDataForLocalId:[NSNumber numberWithUnsignedInt:TIMEX_SERVICE_LOCALID]];
        CharacteristicData* charData = [service characteristicDataForLocalId:[NSNumber numberWithUnsignedInt:TIMEX_SERVICE_DATAIN3_LOCALID]];
        
        s_timexDatalinkDataIn3Id = charData.uuid;
    }
    
    return s_timexDatalinkDataIn3Id;
}

+(CBUUID*) timexDatalinkDataIn4Id
{
    if ( s_timexDatalinkDataIn4Id == nil )
    {
        ProfileData* profileData = [PeripheralDevice profileData];
        ServiceData* service = [profileData serviceDataForLocalId:[NSNumber numberWithUnsignedInt:TIMEX_SERVICE_LOCALID]];
        CharacteristicData* charData = [service characteristicDataForLocalId:[NSNumber numberWithUnsignedInt:TIMEX_SERVICE_DATAIN4_LOCALID]];
        
        s_timexDatalinkDataIn4Id = charData.uuid;
    }
    
    return s_timexDatalinkDataIn4Id;
}

+(CBUUID*) timexDatalinkDataOut1Id
{
    if ( s_timexDatalinkDataOut1Id == nil )
    {
        ProfileData* profileData = [PeripheralDevice profileData];
        ServiceData* service = [profileData serviceDataForLocalId:[NSNumber numberWithUnsignedInt:TIMEX_SERVICE_LOCALID]];
        CharacteristicData* charData = [service characteristicDataForLocalId:[NSNumber numberWithUnsignedInt:TIMEX_SERVICE_DATAOUT1_LOCALID]];
        
        s_timexDatalinkDataOut1Id = charData.uuid;
    }
    
    return s_timexDatalinkDataOut1Id;
}

+(CBUUID*) timexDatalinkDataOut2Id
{
    if ( s_timexDatalinkDataOut2Id == nil )
    {
        ProfileData* profileData = [PeripheralDevice profileData];
        ServiceData* service = [profileData serviceDataForLocalId:[NSNumber numberWithUnsignedInt:TIMEX_SERVICE_LOCALID]];
        CharacteristicData* charData = [service characteristicDataForLocalId:[NSNumber numberWithUnsignedInt:TIMEX_SERVICE_DATAOUT2_LOCALID]];
        
        s_timexDatalinkDataOut2Id = charData.uuid;
    }
    
    return s_timexDatalinkDataOut2Id;
}

+(CBUUID*) timexDatalinkDataOut3Id
{
    if ( s_timexDatalinkDataOut3Id == nil )
    {
        ProfileData* profileData = [PeripheralDevice profileData];
        ServiceData* service = [profileData serviceDataForLocalId:[NSNumber numberWithUnsignedInt:TIMEX_SERVICE_LOCALID]];
        CharacteristicData* charData = [service characteristicDataForLocalId:[NSNumber numberWithUnsignedInt:TIMEX_SERVICE_DATAOUT3_LOCALID]];
        
        s_timexDatalinkDataOut3Id = charData.uuid;
    }
    
    return s_timexDatalinkDataOut3Id;
}

+(CBUUID*) timexDatalinkDataOut4Id
{
    if ( s_timexDatalinkDataOut4Id == nil )
    {
        ProfileData* profileData = [PeripheralDevice profileData];
        ServiceData* service = [profileData serviceDataForLocalId:[NSNumber numberWithUnsignedInt:TIMEX_SERVICE_LOCALID]];
        CharacteristicData* charData = [service characteristicDataForLocalId:[NSNumber numberWithUnsignedInt:TIMEX_SERVICE_DATAOUT4_LOCALID]];
        
        s_timexDatalinkDataOut4Id = charData.uuid;
    }
    
    return s_timexDatalinkDataOut4Id;
}

+(CBUUID*) timexDatalinkDeviceStateId
{
    if ( s_timexDatalinkDeviceStateId == nil )
    {
        ProfileData* profileData = [PeripheralDevice profileData];
        ServiceData* service = [profileData serviceDataForLocalId:[NSNumber numberWithUnsignedInt:TIMEX_SERVICE_LOCALID]];
        CharacteristicData* charData = [service characteristicDataForLocalId:[NSNumber numberWithUnsignedInt:TIMEX_SERVICE_DEVICESTATE_LOCALID]];
        
        s_timexDatalinkDeviceStateId = charData.uuid;
    }
    
    return s_timexDatalinkDeviceStateId;
}


#pragma end

#pragma mark - methods

-(void) setDeviceState:(TDDeviceState_t)state
{
    OTLog(@"PeripheralDevice setDeviceState");
    _deviceState = state;
    [[NSNotificationCenter defaultCenter] postNotificationName:kTDDeviceDataUpdatedNotification object:self];
}

-(NSString *) model
{
    OTLog(@"PeripheralDevice model");
    switch (self.type) {
        case TDDeviceType_Classic:
            return @"Classic";
            break;
            
        case TDDeviceType_Pro:
            return @"Pro";
            break;
            
        case TDDeviceType_Metropolitan:
            return @"Metropolitan";
            break;

        case TDDeviceType_IQMove:
            return @"IQMove";
            break;
        case TDDeviceType_IQTravel:
            return @"IQTravel";
            break;
        default:
            return @"N/A";
            break;
    }
}

-(TDDeviceType) type
{
    OTLog(@"PeripheralDevice type");
    if (!_deviceType)
    {
        _deviceType = _deviceInfoService.modelNumber;
        
        if ([_deviceType isEqualToString:@"Classic"])
            _type= TDDeviceType_Classic;
        else if ([_deviceType isEqualToString:@"Pro"])
            _type =  TDDeviceType_Pro;
        else if ([_deviceType isEqualToString:@"Metropolitan"])
            _type =  TDDeviceType_Metropolitan;
        else if ([_deviceType isEqualToString:@"IQMove"])
            _type =  TDDeviceType_IQMove;
        else if ([_deviceType isEqualToString:@"IQTravel"])
            _type =  TDDeviceType_IQTravel;
    }
    
    return _type;
    
}

-(NSString *)manufacturer
{
    return _deviceInfoService.manufacturerName;
}

-(NSString *)hardwareVersion
{
    return _deviceInfoService.hardwareRevision;
}

-(NSString *)serialnum
{
    return _deviceInfoService.serialNumber;
}

-(NSString *)fwVersion
{
    return _deviceInfoService.firmwareRevision;
}

-(NSInteger) batteryLevel
{
    return _batteryService.batteryLevel;
}

-(TDDeviceProfile *) deviceProfile
{
    return _deviceData;
}


-(TDDeviceSettings) deviceSettings
{
    return _deviceSettings;
}

-(id) init
{
    self = [super init];
    
    if ( self )
    {
        _mLastSyncApptsChecksum = 0;
        _batteryService = [[BatteryService alloc] init];
        _batteryService.delegate = self;
        [_batteryService enableBatterLevelNotify:YES];
        
        _deviceInfoService = [[DeviceInformationService alloc] init];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_blePeripheralConnected:) name:kBLEManagerConnectedPeripheralNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_blePeripheralDisconnected:) name:kBLEManagerDisconnectedPeripheralNotification object:nil];
        
        _rssiHistory = [[NSMutableArray alloc] init];
        
        _profileObject = [[ProfileObject alloc] initWithFile: @"ProfileData"];
        
        OTLog(@"Removing all pending actions");
        _mPendingActions = [[NSMutableArray alloc] init];
        
        _mFirmwareUpgradeCancelled = FALSE;
        _mFirmwareUpgradePaused = FALSE;
        _mFirmwareUpgradeProcessedFileIndex = NSIntegerMax;
        _mPhoneFinderStatus = nil;
       
    }
    
    return self;
}

-(void)invalidateAllInternalTimers
{
    [_rssiTimer invalidate];
    _rssiTimer = nil;
    
    [_myTempTimer invalidate];
    _myTempTimer = nil;
    
    [_mBLEREsponseTimer invalidate];
    _mBLEREsponseTimer = nil;
}


-(void) setupNotConnectedDeviceWithUUID:(NSString*)uuid
{
    OTLog(@"PeripheralDevice setupNotConnectedDeviceWithUUID");
     _deviceID = uuid;
    [self _loadStoredDeviceData];
}
 
-(void) setPeripheral:(PeripheralProxy *)peripheral
{
    OTLog(@"PeripheralDevice setPeripheral");
    
    _peripheral = peripheral;
    
    
    // Store these so we know what the source type was if the
    // peripheral source gets disconnected
    // Also because peripheral is a weak reference and will become nil if the
    // instance is released
    if ( peripheral )
    {
        self.name = peripheral.name;
        
        
        if ( _peripheral.UUID )
        {
            _deviceID = [_peripheral.UUID.data description];
            
            [self _loadStoredDeviceData];
        }
        
        
        if ( peripheral.isConnected )
        {
            
            if ( _deviceState == kTDDeviceState_NotConnected )
            {
                [self _peripheralConnected:peripheral];
            }
            
        }
        
    }
}

#pragma mark -
#pragma mark - TIMEX DATALINK PCCOMM
- (void) requestDeviceInfoForFirmware
{
    OTLog(@"requestDeviceInfoForFirmware PeripheralDevice.m");
    if ([self isFirmwareUpgradeInProgress])
    {
        //pause firmware
        _mFirmwareUpgradePaused = TRUE;
    }
    //regardless whether this action is processed immediately or queued to be processed later, add it to the queue so should the next one come in we know that
    //something is happening
    [_mPendingActions addObject: [NSNumber numberWithInteger: ACTION_GET_DEVICE_INFO_FIRMWARE]];
    
    if (_mFirmwareUpgradePaused)
    {
        //this is to make sure that firmware resumes
        [_mPendingActions addObject: [NSNumber numberWithInteger: ACTION_RESUME_FIRMWARE]];
    }
    
    if (_mPendingActions.count == 1) //if there is nothing but the action that we just added
    {
        [self requestDeviceInfoPrivate: ACTION_GET_DEVICE_INFO_FIRMWARE];
    }
}
- (void) requestDeviceInfoForBootloaderStatus
{
    OTLog(@"requestDeviceInfoForBootloaderStatus PeripheralDevice.m");
    OTLog([NSString stringWithFormat:@"Pending actions for Request DeviceInfo For BootloaderStatus. %@",_mPendingActions]);
    //regardless whether this action is processed immediately or queued to be processed later, add it to the queue so should the next one come in we know that
    //something is happening
    [_mPendingActions removeAllObjects];
    [_mPendingActions addObject: [NSNumber numberWithInteger: ACTION_GET_DEVICE_INFO_BOOTLOADER_STATUS]];
    
    if (_mPendingActions.count == 1) //if there is nothing but the action that we just added
    {
        [self requestDeviceInfoPrivate: ACTION_GET_DEVICE_INFO_BOOTLOADER_STATUS];
    }
}
- (void) requestDeviceInfo
{
     OTLog(@"requestDeviceInfo PeripheralDevice.m");
    if ([self isFirmwareUpgradeInProgress])
    {
        //pause firmware
        _mFirmwareUpgradePaused = TRUE;
    }
    //regardless whether this action is processed immediately or queued to be processed later, add it to the queue so should the next one come in we know that
    //something is happening
    [_mPendingActions addObject: [NSNumber numberWithInteger: ACTION_GET_DEVICE_INFO]];
    
    if (_mFirmwareUpgradePaused)
    {
        //this is to make sure that firmware resumes
        [_mPendingActions addObject: [NSNumber numberWithInteger: ACTION_RESUME_FIRMWARE]];
    }
    
    if (_mPendingActions.count == 1) //if there is nothing but the action that we just added
    {
        [self requestDeviceInfoPrivate: ACTION_GET_DEVICE_INFO];
    }
}
- (void) requestDeviceChargeInfoForFirmware
{
    OTLog(@"requestDeviceChargeInfoForFirmware PeripheralDevice.m");
    if ([self isFirmwareUpgradeInProgress])
    {
        //pause firmware
        _mFirmwareUpgradePaused = TRUE;
    }
    
    //regardless whether this action is processed immediately or queued to be processed later, add it to the queue so should the next one come in we know that
    //something is happening
    [_mPendingActions addObject: [NSNumber numberWithInteger: ACTION_GET_DEVICE_CHARGE_INFO_FIRMWARE]];
    
    if (_mFirmwareUpgradePaused)
    {
        //this is to make sure that firmware resumes
        [_mPendingActions addObject: [NSNumber numberWithInteger: ACTION_RESUME_FIRMWARE]];
    }
    
    if (_mPendingActions.count == 1) //if there is nothing but the action that we just added
    {
        [self requestDeviceChargeInfoPrivate: ACTION_GET_DEVICE_CHARGE_INFO_FIRMWARE];
    }
}
- (void) requestDeviceChargeInfoForFirmwareM372
{
    OTLog(@"requestDeviceChargeInfoForFirmwareM372 PeripheralDevice.m");
    //currently there is nnothing being processed....
    _mStatus = ERROR_NOT_CONNECTED;
    _mAction = ACTION_READ_M372_PRE_FIRMWARE_CHARGE_INFO;
    
    [self doTimexBluetoothSmart: SUBACTION_WHOS_THERE];
}
- (void) requestWhosThereForFirmwareM328
{
    OTLog(@"requestWhosThereForFirmwareM328 PeripheralDevice.m");
    _mStatus = ERROR_NOT_CONNECTED;
    _mAction = ACTION_WRITE_FIRMWARE_FILE;
    
    [self doTimexBluetoothSmart: SUBACTION_WHOS_THERE];
}
- (void) requestDeviceChargeInfo
{
     OTLog(@"requestDeviceChargeInfo PeripheralDevice.m");
    if ([self isFirmwareUpgradeInProgress])
    {
        //pause firmware
        _mFirmwareUpgradePaused = TRUE;
    }
    
    //regardless whether this action is processed immediately or queued to be processed later, add it to the queue so should the next one come in we know that
    //something is happening
    [_mPendingActions addObject: [NSNumber numberWithInteger: ACTION_GET_DEVICE_CHARGE_INFO]];
    
    if (_mFirmwareUpgradePaused)
    {
        //this is to make sure that firmware resumes
        [_mPendingActions addObject: [NSNumber numberWithInteger: ACTION_RESUME_FIRMWARE]];
    }
    
    if (_mPendingActions.count == 1) //if there is nothing but the action that we just added
    {
        [self requestDeviceChargeInfoPrivate: ACTION_GET_DEVICE_CHARGE_INFO];
    }
}
- (void) triggerWatchFinder: (BOOL) flag
{
    OTLog(@"triggerWatchFinder PeripheralDevice.m");
    ServiceProxy* service = [_peripheral findService: [PeripheralDevice timexDatalinkServiceId]];
    if (service)
    {
        TDFlurryDataPacket * dictFlurry = [[TDFlurryDataPacket alloc] init];
        Byte buffer[16];
        memset(&buffer[0], 0, 16);
        
        if (flag)
        {
            [dictFlurry setValue: @"Watch Finder On" forKey: @"Sync_Action"];
            buffer[0] = (Byte)0x82;
        }
        else
        {
            [dictFlurry setValue: @"Watch Finder Off" forKey: @"Sync_Action"];
            buffer[0] = (Byte)0x80;
        }
        [iDevicesUtil logFlurryEvent: @"BLE_SYNC" withParameters:dictFlurry isTimedEvent:NO];
        
        NSData * newBuffData = [NSData dataWithBytes: buffer length: 16];
        
        CBUUID * charIDToUse = [PeripheralDevice timexDatalinkDeviceStateId];
        
        CharacteristicProxy* timexChar = [service findCharacteristic: charIDToUse];
        
        __weak PeripheralDevice* weakSelf = self;
        [timexChar writeValue: newBuffData responseBlock:^(CharacteristicProxy *characteristic)
         {
             PeripheralDevice* strongSelf = weakSelf;
             if ( strongSelf )
             {
                 //we don't really have to do anything here... we can send notification?
             }
         }];
    }
}
- (void) sendApptsToWatch
{
    OTLog(@"PeripheralDevice sendApptsToWatch");
    BOOL actionNotNeeded = FALSE;
    
    //regardless whether this action is processed immediately or queued to be processed later, add it to the queue so should the next one come in we know that
    //something is happening
    [_mPendingActions addObject: [NSNumber numberWithInteger: ACTION_WRITE_APPT_FILE]];
    
    //record that we are doing an appts update check now
    [[NSUserDefaults standardUserDefaults] setObject: [NSDate date] forKey: kLastApptCheckTime];
    
    NSLog(@"\n\n\n\nPending actions :%@ and count :%d in sendApptsToWatch\n\n\n\n",_mPendingActions, (int)_mPendingActions.count);
    if (_mPendingActions.count == 1) //if there is nothing but the action that we just added
    {
        actionNotNeeded = [self sendApptsToWatchPrivate];
        if (actionNotNeeded)
        {
            //it is concievable that while we were processing appointments and determining if any
            //action is needed, there has been another item added to the queue... so process it
            //properly.
            [self processNextCommandInQueueIfAny];
        }
    }
}
- (void) readTimexWorkouts
{
    OTLog(@"readTimexWorkouts PeripheralDevice.m");
    if ([self isFirmwareUpgradeInProgress])
    {
        //pause firmware
        _mFirmwareUpgradePaused = TRUE;
    }
    
    //regardless whether this action is processed immediately or queued to be processed later, add it to the queue so should the next one come in we know that
    //something is happening
    [_mPendingActions addObject: [NSNumber numberWithInteger: ACTION_READ_CHRONOS_FILE]];
    
    if (_mFirmwareUpgradePaused)
    {
        //this is to make sure that firmware resumes
        [_mPendingActions addObject: [NSNumber numberWithInteger: ACTION_RESUME_FIRMWARE]];
    }
    
    OTLog(@"Pending actions %@",_mPendingActions);
    
    if (_mPendingActions.count == 1) //if there is nothing but the action that we just added
    {
        [self readTimexWorkoutsPrivate];
    }
}

- (void) readSYSBLOCK
{
    OTLog(@"readSYSBLOCK PeripheralDevice.m");
    if ([self isFirmwareUpgradeInProgress])
    {
        //pause firmware
        _mFirmwareUpgradePaused = TRUE;
    }
    
    //regardless whether this action is processed immediately or queued to be processed later, add it to the queue so should the next one come in we know that
    //something is happening
    [_mPendingActions addObject: [NSNumber numberWithInteger: ACTION_READ_SYSBLOCK_FILE]];
    
    if (_mFirmwareUpgradePaused)
    {
        //this is to make sure that firmware resumes
        [_mPendingActions addObject: [NSNumber numberWithInteger: ACTION_RESUME_FIRMWARE]];
    }
    
    if (_mPendingActions.count == 1) //if there is nothing but the action that we just added
    {
        [self readSYSBLOCKPrivate];
    }
}

//TestLog_SleepFiles
- (void) readTimexWatchSleepActigraphyFiles
{
    OTLog(@"readTimexWatchSleepActigraphyFiles PeripheralDevice.m");
    if ([self isFirmwareUpgradeInProgress])
    {
        //pause firmware
        _mFirmwareUpgradePaused = TRUE;
    }
    
    //regardless whether this action is processed immediately or queued to be processed later, add it to the queue so should the next one come in we know that
    //something is happening
    
    [_mPendingActions addObject: [NSNumber numberWithInteger: ACTION_READ_M372_ACTIGRAPHY_FILES]];
    
    if (_mFirmwareUpgradePaused)
    {
        //this is to make sure that firmware resumes
        [_mPendingActions addObject: [NSNumber numberWithInteger: ACTION_RESUME_FIRMWARE]];
    }
    
    if (_mPendingActions.count == 1) //if there is nothing but the action that we just added
    {
        [self readTimexWatchSleepActigraphyFilesPrivate];//TestLog_SleepFiles
    }
}
- (void) readTimexWatchActigraphyStepFiles
{
    OTLog(@"readTimexWatchActigraphyStepFiles PeripheralDevice.m");
    if ([self isFirmwareUpgradeInProgress])
    {
        //pause firmware
        _mFirmwareUpgradePaused = TRUE;
    }
    
    //regardless whether this action is processed immediately or queued to be processed later, add it to the queue so should the next one come in we know that
    //something is happening
    
    [_mPendingActions addObject: [NSNumber numberWithInteger: ACTION_READ_M372_HOUR_DATA]];
    
    if (_mFirmwareUpgradePaused)
    {
        //this is to make sure that firmware resumes
        [_mPendingActions addObject: [NSNumber numberWithInteger: ACTION_RESUME_FIRMWARE]];
    }
    
    if (_mPendingActions.count == 1) //if there is nothing but the action that we just added
    {
        [self readTimexWatchActigraphyStepFilesPrivate];//TestLog_SleepFiles
    }
}

- (void) readTimexWatchSleepSummary
{
    OTLog(@"readTimexWatchSleepSummary PeripheralDevice.m");
    if ([self isFirmwareUpgradeInProgress])
    {
        //pause firmware
        _mFirmwareUpgradePaused = TRUE;
    }
    
    //regardless whether this action is processed immediately or queued to be processed later, add it to the queue so should the next one come in we know that
    //something is happening
    
    [_mPendingActions addObject: [NSNumber numberWithInteger: ACTION_READ_M372_SLEEP_SUMMARY]];
    
    if (_mFirmwareUpgradePaused)
    {
        //this is to make sure that firmware resumes
        [_mPendingActions addObject: [NSNumber numberWithInteger: ACTION_RESUME_FIRMWARE]];
    }
    
    if (_mPendingActions.count == 1) //if there is nothing but the action that we just added
    {
        [self readTimexWatchSleepSummaryDataPrivate];//TestLog_SleepFiles
    }
}

- (void) readTimexWatchSleepKeyFile
{
    OTLog(@"readTimexWatchSleepKeyFile PeripheralDevice.m");
    if ([self isFirmwareUpgradeInProgress])
    {
        //pause firmware
        _mFirmwareUpgradePaused = TRUE;
    }
    
    //regardless whether this action is processed immediately or queued to be processed later, add it to the queue so should the next one come in we know that
    //something is happening
    
    [_mPendingActions addObject: [NSNumber numberWithInteger: ACTION_READ_M372_SLEEP_KEY_FILE]];
    
    if (_mFirmwareUpgradePaused)
    {
        //this is to make sure that firmware resumes
        [_mPendingActions addObject: [NSNumber numberWithInteger: ACTION_RESUME_FIRMWARE]];
    }
    
    if (_mPendingActions.count == 1) //if there is nothing but the action that we just added
    {
        [self readTimexWatchSleepKeyFilePrivate];//TestLog_SleepFiles
    }
}
//TestLog_SleepFiles
- (void) readTimexWatchActivityData
{
    OTLog(@"readTimexWatchActivityData PeripheralDevice.m");
    if ([self isFirmwareUpgradeInProgress])
    {
        //pause firmware
        _mFirmwareUpgradePaused = TRUE;
    }
    
    //regardless whether this action is processed immediately or queued to be processed later, add it to the queue so should the next one come in we know that
    //something is happening
    [_mPendingActions addObject: [NSNumber numberWithInteger: ACTION_READ_M372_ACTIVITY_DATA]];
    
    
    if (_mFirmwareUpgradePaused)
    {
        //this is to make sure that firmware resumes
        [_mPendingActions addObject: [NSNumber numberWithInteger: ACTION_RESUME_FIRMWARE]];
    }
    
    if (_mPendingActions.count == 1) //if there is nothing but the action that we just added
    {
        [self readTimexWatchActivityDataPrivate];
    }
}
- (void) readTimexWatchSettings {
    OTLog(@"readTimexWatchSettings PeripheralDevice.m");
    if ([self isFirmwareUpgradeInProgress])
    {
        //pause firmware
        _mFirmwareUpgradePaused = TRUE;
    }
    
    //regardless whether this action is processed immediately or queued to be processed later, add it to the queue so should the next one come in we know that
    //something is happening
    [_mPendingActions addObject: [NSNumber numberWithInteger: ACTION_READ_SETTINGS_FILE]];
    
    if (_mFirmwareUpgradePaused)
    {
        //this is to make sure that firmware resumes
        [_mPendingActions addObject: [NSNumber numberWithInteger: ACTION_RESUME_FIRMWARE]];
    }
    
    if (_mPendingActions.count == 1) //if there is nothing but the action that we just added
    {
        [self readTimexWatchSettingsPrivate];
    }
}
- (void) writeTimexWatchSettings
{
    OTLog(@"writeTimexWatchSettings PeripheralDevice.m");
    if ([self isFirmwareUpgradeInProgress])
    {
        //pause firmware
        _mFirmwareUpgradePaused = TRUE;
    }
    
    //regardless whether this action is processed immediately or queued to be processed later, add it to the queue so should the next one come in we know that
    //something is happening
    [_mPendingActions addObject: [NSNumber numberWithInteger: ACTION_WRITE_SETTINGS_FILE]];
    
    if (_mFirmwareUpgradePaused)
    {
        //this is to make sure that firmware resumes
        [_mPendingActions addObject: [NSNumber numberWithInteger: ACTION_RESUME_FIRMWARE]];
    }
    
    if (_mPendingActions.count == 1) //if there is nothing but the action that we just added
    {
        [self writeTimexWatchSettingsPrivate];
    }
}

- (void) setUpIQForFirmwareUpgrade
{
    OTLog(@"setUpIQForFirmwareUpgrade PeripheralDevice.m");
    _mAction = ACTION_WRITE_FIRMWARE_FILE;
    
    [_mPendingActions removeAllObjects];
    [[NSNotificationCenter defaultCenter] postNotificationName: kTDM328SessionStartNotification object: self];
}

- (void) clearPendingActions
{
    OTLog(@"Clearing all pending actions");
    _mPendingActions = [[NSMutableArray alloc] init];
}

- (void) doFirmwareUpgrade: (NSArray *) upgradeInfo
{
    OTLog(@"doFirmwareUpgrade PeripheralDevice.m");
    _mFirmwareUpgradeCancelled = FALSE;
    _mFirmwareUpgradePaused = FALSE;
    _firmwareUpgradePendingFilesCount = (int)upgradeInfo.count;
    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQ || [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)
    {
        _mFirmwareUpgradePendingFiles = [[NSMutableArray alloc] init];
        NSArray *info;
        for (info in upgradeInfo)
        {
            [_mFirmwareUpgradePendingFiles addObject:info];
        }
    }
    else {
        _mFirmwareUpgradePendingFiles = [NSMutableArray new];
        NSArray *info;
        for (info in upgradeInfo)
        {
            [_mFirmwareUpgradePendingFiles addObject:info];
        }
    }
    
    //regardless whether this action is processed immediately or queued to be processed later, add it to the queue so should the next one come in we know that
    //something is happening
    [_mPendingActions addObject: [NSNumber numberWithInteger: ACTION_WRITE_FIRMWARE_FILE]];
    
    if (_mPendingActions.count == 1) //if there is nothing but the action that we just added
    {
        [self doFirmwareUpgradePrivate];
    }
}

- (void) doBootloaderFirmwareUpgrade: (NSArray *) upgradeInfo
{
    OTLog(@"doBootloaderFirmwareUpgrade PeripheralDevice.m");
    _mFirmwareUpgradeCancelled = FALSE;
    _mFirmwareUpgradePaused = FALSE;
    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQ || [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)
    {
        _mFirmwareUpgradePendingFiles = [NSMutableArray new];
        NSArray *info;
        for (info in upgradeInfo)
        {
            [_mFirmwareUpgradePendingFiles addObject:info];
        }
    }
    else {
        _mFirmwareUpgradePendingFiles = [NSMutableArray new];
        NSArray *info;
        for (info in upgradeInfo)
        {
            [_mFirmwareUpgradePendingFiles addObject:info];
        }
        _firmwareUpgradePendingFilesCount = (int)upgradeInfo.count;
    }
    //regardless whether this action is processed immediately or queued to be processed later, add it to the queue so should the next one come in we know that
    //something is happening
    [_mPendingActions removeAllObjects];
    [_mPendingActions addObject: [NSNumber numberWithInteger: ACTION_WRITE_BOOTLOADER_FILE]];
    
    if (_mPendingActions.count == 1) //if there is nothing but the action that we just added
    {
        [self doBootloaderFirmwareUpgradePrivate];
    }
}

- (BOOL) isFirmwareUpgradeInProgress
{
    OTLog(@"isFirmwareUpgradeInProgress PeripheralDevice.m");
    BOOL weAreFirmwareUpgrading = FALSE;
    
    if (_mFirmwareUpgradePendingFiles != nil && _mTransmitPackets != nil && [_mTransmitPackets count] != 0) //make sure that we are in the middle of firmware transmission
    {
        if (_mPendingActions.count > 0 && ([[_mPendingActions objectAtIndex: 0] integerValue] == ACTION_WRITE_FIRMWARE_FILE || [[_mPendingActions objectAtIndex: 0] integerValue] == ACTION_RESUME_FIRMWARE || [[_mPendingActions objectAtIndex: 0] integerValue] == ACTION_WRITE_BOOTLOADER_FILE))
        {
            weAreFirmwareUpgrading = TRUE;
        }
    }
    
    return weAreFirmwareUpgrading;
}
- (BOOL) isFirmwareUpgradePaused
{
    OTLog(@"isFirmwareUpgradePaused PeripheralDevice.m");
    BOOL returnVal = FALSE;
    
    if (_mPendingActions && [_mPendingActions containsObject: [NSNumber numberWithInteger: ACTION_RESUME_FIRMWARE]])
    {
        returnVal = TRUE;
    }
    
    return returnVal;
}
- (void) cancelFirmwareUpgrade
{
    OTLog(@"cancelFirmwareUpgrade PeripheralDevice.m");
    if ([self isFirmwareUpgradeInProgress])
    {
        TDFlurryDataPacket * dictFlurry = [[TDFlurryDataPacket alloc] initWithValue: @"Cancel Firmware" forKey: @"Sync_Action"];
        [iDevicesUtil logFlurryEvent: @"BLE_SYNC" withParameters:dictFlurry isTimedEvent:NO];
        
        _mFirmwareUpgradeCancelled = TRUE;
        
        if (_progressDialog != nil)
        {
            NSString * currentText = _progressDialog.progressText;
            NSArray * currentTextSubstrings = [currentText componentsSeparatedByCharactersInSet: [NSCharacterSet characterSetWithCharactersInString:@"\n"]];
            _progressDialog.progressText = [NSString stringWithFormat: @"%@\n%@", [currentTextSubstrings objectAtIndex: 0] , NSLocalizedString(@"Cancelling...", nil)];
        }
    }
}
- (void) readM053FullFile
{
    OTLog(@"readM053FullFile PeripheralDevice.m");
    //regardless whether this action is processed immediately or queued to be processed later, add it to the queue so should the next one come in we know that
    //something is happening
    [_mPendingActions addObject: [NSNumber numberWithInteger: ACTION_READ_M053_FULL_FILE]];
    
    if (_mPendingActions.count == 1) //if there is nothing but the action that we just added
    {
        [self readM053FullFilePrivate];
    }
}
- (void) writeM053FullFile
{
    OTLog(@"writeM053FullFile PeripheralDevice.m");
    //regardless whether this action is processed immediately or queued to be processed later, add it to the queue so should the next one come in we know that
    //something is happening
    [_mPendingActions addObject: [NSNumber numberWithInteger: ACTION_WRITE_M053_FULL_FILE]];
    
    if (_mPendingActions.count == 1) //if there is nothing but the action that we just added
    {
        [self writeM053FullFilePrivate: FALSE];
    }
}
- (void) writeM053ApptsFile
{
    OTLog(@"writeM053ApptsFile PeripheralDevice.m");
    //regardless whether this action is processed immediately or queued to be processed later, add it to the queue so should the next one come in we know that
    //something is happening
    [_mPendingActions addObject: [NSNumber numberWithInteger: ACTION_WRITE_M053_APPTS_FILE]];
    
    if (_mPendingActions.count == 1) //if there is nothing but the action that we just added
    {
        [self writeM053ApptsFilePrivate: FALSE];
    }
}
- (void) writeM053CurrentPhoneTimeAndEnableActivitySensor
{
    //regardless whether this action is processed immediately or queued to be processed later, add it to the queue so should the next one come in we know that
    //something is happening
    OTLog(@"writeM053CurrentPhoneTimeAndEnableActivitySensor PeripheralDevice.m");

    [_mPendingActions addObject: [NSNumber numberWithInteger: ACTION_WRITE_M053_TIME]];
    
    if (_mPendingActions.count == 1) //if there is nothing but the action that we just added
    {
        [self writeM053CurrentPhoneTimeAndEnableActivitySensorPrivate: FALSE];
    }
}
#pragma mark -
#pragma mark - Timex Device Settings

-(void) disconnect
{
    OTLog(@"disconnect PeripheralDevice.m");

    [super disconnect];
    
    if ( _rssiTimer )
    {
        [_rssiTimer invalidate];
        
        _rssiTimer = nil;
    }
    
    if ( _myTempTimer )
    {
        [_myTempTimer invalidate];
        
        _myTempTimer = nil;
    }
    
    if (_mPhoneFinderStatus)
    {
        [_mPhoneFinderStatus closePopupWindow];
    }
}

-(void) _updateValues
{
    if ( _peripheral )
    {
        _profileObject.delegate = self;
        _profileObject.peripheral = _peripheral;
    }
}


-(void) _peripheralConnected:(PeripheralProxy*)peripheral
{
    OTLog(@"_peripheralConnected PeripheralDevice.m");

    if ( peripheral == _peripheral )
    {
        
        _deviceState = kTDDeviceState_Connecting;
        
        _perphState = kPeripheralDeviceState_Connecting;
        
        _deviceID = [_peripheral.UUID.data description];
        
        [self _loadStoredDeviceData];
        
        if ( _rssiTimer )
        {
            [_rssiTimer invalidate];
            _rssiTimer = nil;
        }
        
        if ( _myTempTimer )
        {
            [_myTempTimer invalidate];
            _myTempTimer = nil;
        }
        
        
        [self performSelector:@selector(_updateValues) withObject:nil afterDelay:UPDATE_DELAY];
        
        _rssiTimer = [NSTimer scheduledTimerWithTimeInterval: 2.0 target: self
                                                    selector: @selector(updateRSSI) userInfo: nil repeats: YES];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kTDDeviceDataUpdatedNotification object:self];
        
        
    }
    
}

-(void) _loadStoredDeviceData
{
    OTLog(@"_loadStoredDeviceData PeripheralDevice.m");

    if ( _deviceData == nil )
    {
        _deviceData = [[TDDeviceManager sharedInstance] loadDeviceDataForId:_deviceID];
        
        if ( !_deviceData.deviceType )
        {
            // Set when authKey is read
        }
    }
}


-(void) _peripheralDisconnected:(PeripheralProxy*) peripheral
{
    OTLog(@"_peripheralDisconnected PeripheralDevice.m");

    if ( peripheral == _peripheral )
    {
        
        [[TDDeviceManager sharedInstance] saveDeviceProfileData:_deviceData];
        
        //time to clean up
        if ( _deviceState == kTDDeviceState_Connecting && _perphState <= kPeripheralDeviceState_Authenticating )
        {
            [[TDDeviceManager sharedInstance] disconnect:self];
            [[NSNotificationCenter defaultCenter] postNotificationName:kPeripheralDeviceAuthorizationFailedNotification object:nil];
            
            return;
        }
        else if ( _deviceState == kTDDeviceState_Connected )
        {
            [[TDDeviceManager sharedInstance] disconnect:self];
            _deviceState = kTDDeviceState_NotConnected;
            [[NSNotificationCenter defaultCenter] postNotificationName:kDeviceManagerDeviceLostConnectiondNotification object:nil];
        }
        else
        {
            _deviceState = kTDDeviceState_NotConnected;
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:kDeviceManagerDeviceLostConnectiondNotification object:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:kTDDeviceDataUpdatedNotification object:nil];
        
    }
}

-(void) _blePeripheralConnected:(NSNotification *)notification
{
    OTLog(@"_blePeripheralConnected PeripheralDevice.m");

    PeripheralProxy* peripheral = [notification.userInfo objectForKey:kBLEManagerPeripheralKey];
    
    [self _peripheralConnected:peripheral];
}

-(void) _blePeripheralDisconnected:(NSNotification *)notification
{
    OTLog(@"_blePeripheralDisconnected PeripheralDevice.m");

    PeripheralProxy* peripheral = [notification.userInfo objectForKey:kBLEManagerPeripheralKey];
    
    [self _peripheralDisconnected:peripheral];
}

-(void) _retrieveCharacteristics:(ServiceProxy*)service
{
    OTLog(@"_retrieveCharacteristics PeripheralDevice.m");

    if ( [service.UUID isEqual:[BatteryService batteryServiceID]] )
    {
        [_batteryService setPeripheral:_peripheral];
        
        return;
    }
    
    if ( [service.UUID isEqual:[DeviceInformationService deviceInformationServiceID]] )
    {
        [_deviceInfoService setPeripheral:_peripheral];
        
        return;
    }
}

#pragma mark - Read Characteristic
-(void) _readCharacteristic:(CharacteristicProxy*)characteristic
{
    OTLog(@"_readCharacteristic PeripheralDevice.m");

    if( [characteristic.UUID isEqual:[PeripheralDevice timexDatalinkDeviceStateId]] )
    {
        OTLog([NSString stringWithFormat:@"Characteristic %@ recognized: Timex Device State", characteristic.UUID]);
        [characteristic removeValueObserver:self forSelector: nil];
        [characteristic addValueObserver:self withSelector:@selector(_timexDeviceStatusNotify:)];
        [characteristic enableNotification:YES];
        
        //we read this characteristic... notify the First Use Setup that we can proceed
        NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:self, kPeripheralDeviceKey, nil];
        [[NSNotificationCenter defaultCenter] postNotificationName: kPeripheralDeviceTimexDatalinkPrimaryCharacteristicDiscovered object:self userInfo:userInfo];
    }
    else if( [characteristic.UUID isEqual:[PeripheralDevice timexDatalinkDataIn1Id]] )
    {
        OTLog([NSString stringWithFormat:@"Characteristic %@ recognized: Timex Data In 1", characteristic.UUID ]);
    }
    else if( [characteristic.UUID isEqual:[PeripheralDevice timexDatalinkDataIn2Id]] )
    {
        OTLog([NSString stringWithFormat:@"Characteristic %@ recognized: Timex Data In 2", characteristic.UUID ]);
    }
    else if( [characteristic.UUID isEqual:[PeripheralDevice timexDatalinkDataIn3Id]] )
    {
        OTLog([NSString stringWithFormat:@"Characteristic %@ recognized: Timex Data In 3", characteristic.UUID ]);
    }
    else if( [characteristic.UUID isEqual:[PeripheralDevice timexDatalinkDataIn4Id]] )
    {
        OTLog([NSString stringWithFormat:@"Characteristic %@ recognized: Timex Data In 4", characteristic.UUID]);
    }
    else if( [characteristic.UUID isEqual:[PeripheralDevice timexDatalinkDataOut1Id]] )
    {
        OTLog([NSString stringWithFormat:@"Characteristic %@ recognized: Timex Data Out 1", characteristic.UUID]);
        
        [characteristic removeValueObserver:self forSelector: nil];
        [characteristic addValueObserver:self withSelector:@selector(_timexDeviceReadDataSector1:)];
        [characteristic enableNotification:YES];
    }
    else if( [characteristic.UUID isEqual:[PeripheralDevice timexDatalinkDataOut2Id]] )
    {
        OTLog([NSString stringWithFormat:@"Characteristic %@ recognized: Timex Data Out 2", characteristic.UUID]);
        
        [characteristic removeValueObserver:self forSelector: nil];
        [characteristic addValueObserver:self withSelector:@selector(_timexDeviceReadDataSector2:)];
        [characteristic enableNotification:YES];
    }
    else if( [characteristic.UUID isEqual:[PeripheralDevice timexDatalinkDataOut3Id]] )
    {
       OTLog([NSString stringWithFormat:@"Characteristic %@ recognized: Timex Data Out 3", characteristic.UUID]);
        
        [characteristic removeValueObserver:self forSelector: nil];
        [characteristic addValueObserver:self withSelector:@selector(_timexDeviceReadDataSector3:)];
        [characteristic enableNotification:YES];
    }
    else if( [characteristic.UUID isEqual:[PeripheralDevice timexDatalinkDataOut4Id]] )
    {
       OTLog([NSString stringWithFormat:@"Characteristic %@ recognized: Timex Data Out 4", characteristic.UUID ]);
        
        [characteristic removeValueObserver:self forSelector: nil];
        [characteristic addValueObserver:self withSelector:@selector(_timexDeviceReadDataSector4:)];
        [characteristic enableNotification:YES];
    }
    else
    {
#if DEBUG
        OTLog([NSString stringWithFormat:@"Read unknown characteristic %@", characteristic.UUID]);
        if ( [characteristic isKindOfClass:[BLECharacteristic class]])
        {
            BLECharacteristic* bleChar = (BLECharacteristic*)characteristic;
            OTLog([NSString stringWithFormat:@"Properties %lX", (unsigned long)bleChar.cbCharacteristic.properties]);
        }
#endif
    }
    
}

-(void) _rssiUpdated:(PeripheralProxy*)peripheral
{

    if ( peripheral == _peripheral )
    {
        RSSIEntry* entry = [[RSSIEntry alloc] init];
        
        entry.value = peripheral.RSSI;
        entry.timeStamp = [[NSDate date] timeIntervalSince1970];
        
        [_rssiHistory insertObject:entry atIndex:0];
        
        [self _calcuateRSSIVelocity];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kTDDeviceDataUpdatedNotification object:self];
    }
}

-(void) _calcuateRSSIVelocity
{
    int sum = 0;
    //NSTimeInterval time = 0;
    //const NSTimeInterval maxTime = 10;
    // average out the last 10 seconds
    _rssiVelocity = 0;
    const int maxEntries = kMedianRSSIEntryCount;
    
    if ( _rssiHistory.count > 1 )
    {
        if  ( !kUseMedianRSSI )
        {
            RSSIEntry* current = [_rssiHistory objectAtIndex:0];
            RSSIEntry* first = nil;
            
            int i = 0;
            int count = 0;
            for ( i = 0; (i < _rssiHistory.count); i++ )
            {
                
                if ( i >= maxEntries )
                    break;
                
                count++;
                
                first = [_rssiHistory objectAtIndex:i];
                
                sum += first.value;
            }
            
            //Weight the most recent more
            sum += current.value;
            count++;
            
            if ( count > 0 )
                _rssi  = sum / count;
        }
        else
        {
            NSRange startRange;
            startRange.location = 0;
            startRange.length = MIN( maxEntries, _rssiHistory.count);
            
            NSArray* sorted = [[_rssiHistory subarrayWithRange:startRange] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2)
            {
                RSSIEntry* entry1 = (RSSIEntry*)obj1;
                RSSIEntry* entry2 = (RSSIEntry*)obj2;
                
                if ( entry1.value < entry2.value )
                    return NSOrderedAscending;
                
                if ( entry1.value > entry2.value )
                    return NSOrderedDescending;
                
                return NSOrderedSame;
            }];
            
            NSInteger idx = sorted.count / 2;
            
            RSSIEntry* median = [sorted objectAtIndex:idx];
            
            _rssi = median.value;
        }
        
        // Delete remaining entries
        
        if ( _rssiHistory.count > maxEntries )
        {
            NSRange range;
            range.location = maxEntries;
            range.length = _rssiHistory.count - maxEntries;
            
            [_rssiHistory removeObjectsInRange:range];
        }
    }
    
    
    {
        float diff = _rssi - kBaseRSSIValue;
        float exp = diff / 6.f;
        float factor = powf(0.5, exp);
        
        _range = kBaseDistance * factor;
    }
}



-(void) _timexDeviceStatusNotify:(CharacteristicProxy*)deviceStatus
{
    OTLog(@"_timexDeviceStatusNotify PeripheralDevice.m");

    //------------------------->
    //LV 11/06/2014 - Mantis 648: we could be connected to two watches via iOS, but the app can be connected to one and only one watch. So, if we are getting a command from
    //SOME watch, check that its UUID matches the UUID of the watch that the app is connected to, otherwise, ignore.
    PeripheralDevice * timexDevice = [iDevicesUtil getConnectedTimexDevice];
    if (timexDevice == nil || [timexDevice.peripheral isEqual: deviceStatus.service.peripheral] == FALSE)
        return;
    //<-------------------------
    
    NSData * value = [NSData dataWithBytes: deviceStatus.value.bytes length: deviceStatus.value.length];
    if (value)
    {
        Byte inData[value.length];
        [value getBytes: inData];
        
        Byte PhoneFinderByte = inData[0];
        Byte WatchStatusByte = inData[1];
        
        if (PhoneFinderByte)
        {
            Byte PhoneFinderValue = PhoneFinderByte & 0x1;
            if (PhoneFinderValue)
            {
                    NSString * key = [iDevicesUtil createKeyForAppSettingsPropertyWithClass: appSettings_PropertyClass_PhoneFinder andIndex: appSettings_PropertyClass_PhoneFinder_PhoneFinderCurrentRingtone];
                    NSInteger soundIndex = DEFAULT_TIMEX_RINGTONE_SETTING;
                    if ([[NSUserDefaults standardUserDefaults] objectForKey: key] != nil)
                    {
                        soundIndex = [[NSUserDefaults standardUserDefaults] integerForKey: key];
                    }
                
                    OTLog(@"Timex Connected Watch Finder is active");
                    UIApplicationState state = [[UIApplication sharedApplication] applicationState];
                    if (state == UIApplicationStateBackground || state == UIApplicationStateInactive)
                    {
                        _mPhoneFinderStatus = nil;
                        //if we are on background, show local notification
                        [[UIApplication sharedApplication] cancelAllLocalNotifications];
                        
                        UILocalNotification* phoneFinderNotification =[[UILocalNotification alloc] init];
                        [phoneFinderNotification setAlertBody: NSLocalizedString(@"You found me!", nil)];
                        phoneFinderNotification.fireDate = [NSDate date];
                        phoneFinderNotification.repeatInterval = 0; //do not repeat
                        
                        NSString * soundName = [NSString stringWithFormat: @"%@.%@", [iDevicesUtil convertTimexRingtoneSettingToString: (appSettings_PropertyClass_PhoneFinderTimexRingtoneEnum)soundIndex], @"mp3"];
                        phoneFinderNotification.soundName = soundName;
                        
                        [[UIApplication sharedApplication] presentLocalNotificationNow: phoneFinderNotification];
                    }
                    else
                    {
                        _mPhoneFinderStatus = [[TDConnectionStatusWindow alloc] initFor: TDConnectionStatus_PurposePhoneFinderStatus];
                        _mPhoneFinderStatus.delegate = self;
                        [_mPhoneFinderStatus show];
                        
                        NSURL* soundPath = [NSURL fileURLWithPath: [[NSBundle mainBundle]
                                                                    pathForResource: [iDevicesUtil convertTimexRingtoneSettingToString: (appSettings_PropertyClass_PhoneFinderTimexRingtoneEnum)soundIndex]
                                                                    ofType:@"mp3"]];
                        if (soundPath != nil)
                        {
                            [[TDAudioPlayer sharedPlayer] initWithURL: soundPath andRepeatCount: -1 andVolume: 1.0 previewOnly: FALSE delegate: nil];
                        }
                    }
            }
        }
        else
        {
            UIApplicationState state = [[UIApplication sharedApplication] applicationState];
            if (state == UIApplicationStateBackground || state == UIApplicationStateInactive)
            {
                [[UIApplication sharedApplication] cancelAllLocalNotifications];
            }
            
            [[NSNotificationCenter defaultCenter] postNotificationName: kTDPhoneFinderCancelledNotification object: self];
            if (_mPhoneFinderStatus)
            {
                [_mPhoneFinderStatus closePopupWindow];
            }
            else
            {
                [[TDAudioPlayer sharedPlayer] stop];
            }
        }
        
        if (WatchStatusByte & 0x2) //BLE is paired
        {
            //to satisfy Mantis defect 309, the Firmware check will not be performed unless both BLE and BTC are paired.
            //at the moment, it seems that WatchStatusByte is the only reliable method for us to get this information:
            BOOL firstPING = FALSE;
            if ([[NSUserDefaults standardUserDefaults] objectForKey: kBLEandBTCPairingConfirmed] == nil)
                firstPING = TRUE;
            
            [[NSUserDefaults standardUserDefaults] setBool: TRUE forKey: kBLEandBTCPairingConfirmed];
            
            NSInteger minimumSecsBetweenChecks = 59; //do not do appointment checks less then 1 minute (60 seconds) apart
            NSDate * now = [NSDate date];
            NSDate * lastApptsCheckDate = [[NSUserDefaults standardUserDefaults] objectForKey: kLastApptCheckTime];
            if (lastApptsCheckDate == nil || [now timeIntervalSinceDate: lastApptsCheckDate] > minimumSecsBetweenChecks)
            {
                NSLog(@"\n\n\n\nCalling sendApptsToWatch from here \n\n\n\n");
                [self sendApptsToWatch];
            }
            
            if (firstPING)
            {
                [[NSNotificationCenter defaultCenter] postNotificationName: kTDFullPairingWithWatchConfirmed object: self];
            }
        }
    }
}

-(void) _timexDeviceReadDataSector1:(CharacteristicProxy*)deviceStatus
{
    OTLog(@"PeripheralDevice _timexDeviceReadDataSector1");
    NSData * value = [NSData dataWithBytes: deviceStatus.value.bytes length: deviceStatus.value.length];
    if (value)
    {
        OTLog(@"Timex Connected DataSector1 received");
        OTLog(@"raw Data:");
        [iDevicesUtil dumpData: value];
        
        if (_mPacketHandle == nil)
        {
            _mPacketHandle = [[NSMutableArray alloc] init];
        }
    
        if (_mPacketHandle)
        {
            [_mPacketHandle addObject: value];
            if ([_mPacketHandle count] > 1)
            {
                NSArray* reversed = [[_mPacketHandle reverseObjectEnumerator] allObjects];
                _mPacketHandle = [NSMutableArray arrayWithArray: reversed];
            }
            
            PCCPacket * newPacket = [self assemblePacket];
            if (newPacket != nil)
            {
                [self doResponse: newPacket];
            }
        }
    }
}

-(void) _timexDeviceReadDataSector2:(CharacteristicProxy*)deviceStatus
{
    OTLog(@"PeripheralDevice _timexDeviceReadDataSector2");
    NSData * value = [NSData dataWithBytes: deviceStatus.value.bytes length: deviceStatus.value.length];
    if (value)
    {
        OTLog(@"Timex Connected DataSector2 received");
        OTLog(@"raw Data:");
        [iDevicesUtil dumpData: value];
        
        if (_mPacketHandle == nil)
        {
            _mPacketHandle = [[NSMutableArray alloc] init];
        }
        
        if (_mPacketHandle)
        {
            [_mPacketHandle addObject: value];
        }
    }
}
-(void) _timexDeviceReadDataSector3:(CharacteristicProxy*)deviceStatus
{
    OTLog(@"PeripheralDevice _timexDeviceReadDataSector3");
    NSData * value = [NSData dataWithBytes: deviceStatus.value.bytes length: deviceStatus.value.length];
    if (value)
    {
        OTLog(@"Timex Connected DataSector3 received");
        OTLog(@"raw Data:");
        [iDevicesUtil dumpData: value];

        
        if (_mPacketHandle == nil)
        {
            _mPacketHandle = [[NSMutableArray alloc] init];
        }
        
        if (_mPacketHandle)
        {
            [_mPacketHandle addObject: value];
        }
    }
}
-(void) _timexDeviceReadDataSector4:(CharacteristicProxy*)deviceStatus
{
    OTLog(@"PeripheralDevice _timexDeviceReadDataSector4");
    NSData * value = [NSData dataWithBytes: deviceStatus.value.bytes length: deviceStatus.value.length];
    if (value)
    {
        OTLog(@"Timex Connected DataSector4 received");
        OTLog(@"raw Data:");
        [iDevicesUtil dumpData: value];
        
        if (_mPacketHandle == nil)
        {
            _mPacketHandle = [[NSMutableArray alloc] init];
        }
        
        if (_mPacketHandle)
        {
            [_mPacketHandle addObject: value];
        }
    }
}

-(void) _upgradeWriteNextLine:(CharacteristicProxy*)characteristic
{
    OTLog(@"PeripheralDevice _upgradeWriteNextLine");
    if (_firmwareBinary.count == 0 )
    {
        if (_peripheral.isConnected )
        {
            _deviceState = kTDDeviceState_Connected;
        }
        else
        {
            [self setDeviceState:kTDDeviceState_NotConnected];
        }
        return;
    }
    
    NSData *data = [_firmwareBinary objectAtIndex:0];
    
    [_firmwareBinary removeObjectAtIndex:0];
    
    uint8_t *dataBytes = (uint8_t *)[data bytes];
    uint16_t addr = (dataBytes[1]<<8) + dataBytes[2];
    int type = dataBytes[3];
    if ((type == 0) && (addr < 0x4c0))
    {
        [self _upgradeWriteNextLine:characteristic];
        return; // skip SS loading
    }
    
    // patch up address
    addr -= 0x4c0;

    dataBytes[1] = (addr&0xff00)>>8;
    dataBytes[2] = (addr&0xff);
    
    // Cut off checksum
    NSData* writeData = [NSData dataWithBytes:dataBytes length:data.length - 1];
    
    _updateProgress = (_firmwareBinary.count * 100) / _updateTotalSize;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kTDDeviceDataUpdatedNotification object:self];
    
    if ( _peripheral )
    {
        [characteristic writeValue:writeData response:@selector(_upgradeWriteNextLine:) target:self];
        return;
    }
    
    // If we got this far then something went wrong
    if (_peripheral.isConnected )
    {
        _deviceState = kTDDeviceState_Connected;
    }
    else
    {
        [self setDeviceState:kTDDeviceState_NotConnected];
    }
}

-(void) updateRSSI
{
    [_peripheral updateRSSI:@selector(_rssiUpdated:) target:self];
}

#pragma mark - BatteryServiceDelegate

-(void) batteryService:(BatteryService *)service batteryLevelUpdated:(NSInteger)level
{
    OTLog(@"PeripheralDevice batteryService");
    if ( service == _batteryService )
    {
        [self updateRSSI];
        self.batteryLevel = level;
    }
}
#pragma end

#pragma mark - ProfileObjectDelegate

-(void) profileObject:(ProfileObject*)profileObject discoveredService:(ServiceProxy*)service
{
    OTLog([NSString stringWithFormat:@"I found a service!  %@", service.UUID]);

    [self _retrieveCharacteristics:service];
}

-(void) profileObject:(ProfileObject *)profileObject discoveredCharacteristic:(CharacteristicProxy*)characteristic
{
    OTLog([NSString stringWithFormat:@"I found a characteristic!  %@", characteristic.UUID]);
    [self _readCharacteristic:characteristic];
}

#pragma end
-(void)peripheralDidInvalidateServices:(CBPeripheral *)peripheral
{
    OTLog(@"Peripheral Did Invalidate Services invoked.");
}

- (void) whosThere: (PCCommWhosThere *) inWhosThere
{
    OTLog(@"whosThere PeripheranDevice.m");

    if (_mAction == ACTION_GET_DEVICE_INFO)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName: kTDWatchInfoReadSuccessfullyNotification object: self userInfo: [NSDictionary dictionaryWithObject: inWhosThere forKey: kDeviceWatchInfoKey]];
    }
    else if (_mAction == ACTION_GET_DEVICE_INFO_FIRMWARE)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName: kTDWatchInfoFWReadSuccessfullyNotification object: self userInfo: [NSDictionary dictionaryWithObject: inWhosThere forKey: kDeviceWatchInfoKey]];
    }
    else if (_mAction == ACTION_GET_DEVICE_INFO_BOOTLOADER_STATUS)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName: kTDWatchInfoBootloaderReadSuccessfullyNotification object: self userInfo: [NSDictionary dictionaryWithObject: inWhosThere forKey: kDeviceWatchInfoKey]];
    }
    else
    {
        if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_Metropolitan || [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQ || [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel) {
            [[NSNotificationCenter defaultCenter] postNotificationName: kTDWatchInfoReadSuccessfullyNotification object: self userInfo: [NSDictionary dictionaryWithObject: inWhosThere forKey: kDeviceWatchInfoKey]];
        }
    }
}

- (void) readFirmwareVersions: (PCCommExtendedFirmwareVersionInfo *) versionsInfo {
    OTLog(@"readFirmwareVersions PeripheralDevice.m");

    if (versionsInfo)
    {
        OTLog(@"Firmware Version Info from watch %@",versionsInfo);
        [[NSUserDefaults standardUserDefaults] setObject: versionsInfo.mVersion1 forKey: kM372FirmwareVersionFile1Key];
        [[NSUserDefaults standardUserDefaults] setObject: versionsInfo.mVersion2 forKey: kM372FirmwareVersionFile2Key];
        [[NSUserDefaults standardUserDefaults] setObject: versionsInfo.mVersion3 forKey: kM372FirmwareVersionFile3Key];
        [[NSUserDefaults standardUserDefaults] setObject: versionsInfo.mVersion4 forKey: kM372FirmwareVersionFile4Key];
    }
}

- (void) readChargeInfo: (PCCommChargeInfo *) chargeInfo
{
    OTLog(@"readChargeInfo PeripheralDevice.m");

    if (_mAction == ACTION_GET_DEVICE_CHARGE_INFO)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName: kTDWatchChargeInfoReadSuccessfullyNotification object: self userInfo: [NSDictionary dictionaryWithObject: chargeInfo forKey: kDeviceWatchChargeInfoKey]];
    }
    else if (_mAction == ACTION_GET_DEVICE_CHARGE_INFO_FIRMWARE)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName: kTDWatchChargeInfoFWReadSuccessfullyNotification object: self userInfo: [NSDictionary dictionaryWithObject: chargeInfo forKey: kDeviceWatchChargeInfoKey]];
    }
    else
    {
        if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_Metropolitan)
        {
            [[NSNotificationCenter defaultCenter] postNotificationName: kTDWatchChargeInfoReadSuccessfullyNotification object: self userInfo: [NSDictionary dictionaryWithObject: chargeInfo forKey: kDeviceWatchChargeInfoKey]];
        } else if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQ || [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)
        {
            [[NSNotificationCenter defaultCenter] postNotificationName: kTDWatchChargeInfoReadSuccessfullyNotification object: self userInfo: [NSDictionary dictionaryWithObject: chargeInfo forKey: kDeviceWatchChargeInfoKey]];
        }
    }
}
#pragma mark -
- (void) doResponse: (PCCPacket *) receivedPacket
{
    OTLog(@"PeripheralDevice doResponse");
    BOOL PCCommHeaderNack = FALSE;
    BOOL statusCallback = true;
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    if ( nil != receivedPacket )
    {
        if (_mBLEREsponseTimer != nil)
        {
            //invalidate the fail/safe mechanism... we have received the response so we are OK
            [_mBLEREsponseTimer invalidate];
        }
        
        Byte cmd = [[[[receivedPacket getResponsePacket] getHeader] Command] Get];
        PCCommHeaderNack = [[[[receivedPacket getResponsePacket] getHeader] Info] isNack];
        
        _mStatus = [[receivedPacket getResponsePacket] getExtenderResponseCode];
#ifdef  DEBUG
        OTLog([NSString stringWithFormat:@"Do response Command %d and mAction is %d",cmd,_mAction]);

#endif
    
        switch( cmd )
        {
            case WhosThere:
                if ( ACK_NO_ERROR == _mStatus )
                {
                    _mPCCommWhosThereInfo = [[PCCommWhosThere alloc] init: [[receivedPacket getResponsePacket] getPayload]];
                    if ( _mPCCommWhosThereInfo)
                    {
                        BOOL canContinue = YES;
                        
                        if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_Metropolitan || [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQ || [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel) // Not sure about this.
                        {
                            if ((_mAction != ACTION_GET_DEVICE_INFO_BOOTLOADER_STATUS && _mAction != ACTION_WRITE_BOOTLOADER_FILE) || _mAction == ACTION_WRITE_FIRMWARE_FILE)
                            {
                                if (_mPCCommWhosThereInfo.mModeStatus == 1)
                                {
                                    OTLog([NSString stringWithFormat:@"Bootloader Status detected for action %d", _mAction]);

                                    //we are not supposed to be in bootloader mode, but we are! Shit.....
                                    canContinue = NO;
                                    if (_mPendingActions.count > 0)
                                    {
                                        OTLog(@"Removing first pending action , %@",_mPendingActions);
                                        [_mPendingActions removeObjectAtIndex: 0];
                                    }
                                    
                                    [[NSNotificationCenter defaultCenter] postNotificationName: kTDM372UnexpectedBootloaderModeDetected object: self];
                                    
                                    if (_mAction == ACTION_WRITE_FIRMWARE_FILE && [[TDWatchProfile sharedInstance] watchStyle] != timexDatalinkWatchStyle_IQ && [[TDWatchProfile sharedInstance] watchStyle] != timexDatalinkWatchStyle_IQTravel)
                                    {
                                        //we are already in the process of firmware update. No need to display the message, go straight into the recovery
                                        OTLog(@"Not displaying bootloader alert since the user already requested firmware update");
                                        [self performSelector:@selector(initiateBootloadRecovery) withObject: nil afterDelay: 1.0];
                                    }
                                    else
                                    {
                                        _bootloaderModeOnAlert = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"Unable to sync", @"Modification Date: 09/03/2015")
                                                                                    message: NSLocalizedString(@"The firmware update did not complete successfully. You will not be able to track your activity or sync your watch to the app until the firmware update process is complete. Would you like to perform the firmware update now?", @"Modification Date: 09/03/2015")
                                                                                   delegate: self cancelButtonTitle: nil otherButtonTitles: NSLocalizedString(@"OK", nil), nil];
                                        [_bootloaderModeOnAlert show];
                                    }
                                }
                            }
                            if (([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQ || [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel) && _mAction == ACTION_WRITE_FIRMWARE_FILE)
                            {
                                canContinue = NO;
                            }
                        }
                        
                        if (canContinue)
                        {
                            [self whosThere: _mPCCommWhosThereInfo];
                            [self doTimexBluetoothSmart: [self nextSubAction: SUBACTION_WHOS_THERE]];
                        }
                    }
                }
                else
                {
                    OTLog(@"DiegoSleep1");
                    [self _flurryResponseError: cmd];
                    [self handleError: SUBACTION_WHOS_THERE withStatus: _mStatus];
                }
                
                break;
            case ExtenderCmdGetExtraFirmwareRevisions:
                if ( ACK_NO_ERROR == _mStatus )
                {
                    OTLog(@"ExtenderCmdGetExtraFirmwareRevisions");
                    PCCommExtendedFirmwareVersionInfo * dataGot = [[PCCommExtendedFirmwareVersionInfo alloc] init: [[receivedPacket getResponsePacket] getPayload]];
                    if ( dataGot)
                    {
                        [self readFirmwareVersions: dataGot];
                        [self doTimexBluetoothSmart: [self nextSubAction: SUBACTION_GET_EXTENDED_FIRMWARE_VERSION_INFO]];
                    }
//                    else{
//                        OTLog(@"No data got from watch");
//                    }
                }
                else
                {
                    OTLog(@"DiegoSleep2");
                    [self _flurryResponseError: cmd];
                    [self handleError: SUBACTION_GET_EXTENDED_FIRMWARE_VERSION_INFO withStatus: _mStatus];
                }
                break;
            case ExtenderCmdForceBootloaderModeExit:
                if ( ACK_NO_ERROR == _mStatus )
                {
                    OTLog(@"Bootloader Mode Exit Requested Successfully!");
                    [self doTimexBluetoothSmart: SUBACTION_REBOOT];
                }
                else
                {
                    OTLog(@"DiegoSleep3");
                    OTLog(@"Bootloader Mode Exit Request Failed!");
                    [self _flurryResponseError: cmd];
                    [self doTimexBluetoothSmart: SUBACTION_REBOOT]; //reboot anyway
                }
                break;
            case ExtenderCmdReadChargeInfo:
                if ( ACK_NO_ERROR == _mStatus )
                {
                    PCCommChargeInfo * dataGot = [[PCCommChargeInfo alloc] init: [[receivedPacket getResponsePacket] getPayload]];
                    if ( dataGot)
                    {
                        [self readChargeInfo: dataGot];
                        [self doTimexBluetoothSmart: [self nextSubAction: SUBACTION_GET_CHARGE_INFO]];
                    }
                }
                else
                {
                    OTLog(@"DiegoSleep4");
                    [self _flurryResponseError: cmd];
                    [self handleError: SUBACTION_GET_CHARGE_INFO withStatus: _mStatus];
                }
                
                break;
            case ExtenderCmdOpen:
                if ( ACK_NO_ERROR == _mStatus )
                {
                    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_ActivityTracker && PCCommHeaderNack == TRUE)
                    {
                        
                        OTLog(@"NACK received during ExtenderCmdOpen for M053");
                       
                        //we have received NACK while transmitting a packet... according to M053 development team, we need to send the same packet again
                        [self doTimexBluetoothSmart: SUBACTION_OPEN_FILE];
                    }
                    else if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_Metropolitan && PCCommHeaderNack == TRUE)
                    {
                        
                        OTLog(@"NACK received during ExtenderCmdOpen for M372");
                       
                        //we have received NACK while transmitting a packet... according to M053 development team, we need to send the same packet again
                        [self doTimexBluetoothSmart: SUBACTION_OPEN_FILE];
                    } else if (([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQ || [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel) && PCCommHeaderNack == TRUE) {
                        
                        OTLog(@"NACK received during ExtenderCmdOpen for M328");
                        
                        //we have received NACK while transmitting a packet... according to M053 development team, we need to send the same packet again
                        [self doTimexBluetoothSmart: SUBACTION_OPEN_FILE];
                    } else {
                        NSData * respData = [[receivedPacket getResponsePacket] getExtenderResponseData];
                        Byte buff[[respData length]];
                        [respData getBytes: buff];
                        _mFileHandle = buff[0];
                        [self doTimexBluetoothSmart: [self nextSubAction: SUBACTION_OPEN_FILE]];
                    }
                }
                else
                {
    
                    [self _flurryResponseError: cmd];
                    [self handleError: SUBACTION_OPEN_FILE withStatus: _mStatus];
                }
                break;
            case ExtenderCmdClose:
                if ( ACK_NO_ERROR == _mStatus )
                {
                    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_ActivityTracker && PCCommHeaderNack == TRUE)
                    {
                        
                        OTLog(@"NACK received during ExtenderCmdClose for M053");
                        
                        //we have received NACK while transmitting a packet... according to M053 development team, we need to send the same packet again
                        [self doTimexBluetoothSmart: SUBACTION_CLOSE_FILE];
                    }
                    else if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_Metropolitan && PCCommHeaderNack == TRUE)
                    {
                        
                        OTLog(@"NACK received during ExtenderCmdClose for M372");
                        
                        //we have received NACK while transmitting a packet... according to M053 development team, we need to send the same packet again
                        [self doTimexBluetoothSmart: SUBACTION_CLOSE_FILE];
                    } else if (([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQ || [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel) && PCCommHeaderNack == TRUE)
                    {
                        
                        OTLog(@"NACK received during ExtenderCmdClose for M328");
                        
                        //we have received NACK while transmitting a packet... according to M053 development team, we need to send the same packet again
                        [self doTimexBluetoothSmart: SUBACTION_CLOSE_FILE];
                    }
                    else
                    {
                        if ( nil != _mTransmitPackets )
                        {
                            [_mTransmitPackets removeAllObjects];
                            _mTransmitPackets = nil;
                        }
                        _mFileHandle = 0;
                        
                        [self doTimexBluetoothSmart: [self nextSubAction: SUBACTION_CLOSE_FILE]];
                    }
                }
                else
                {
                    OTLog(@"DiegoSleep6");
                    [self _flurryResponseError: cmd];
                    [self handleError: SUBACTION_CLOSE_FILE withStatus: _mStatus];
                }
                break;
            case ExtenderCmdFileSize:
                if ( ACK_NO_ERROR == _mStatus )
                {
                    NSData * respData = [[receivedPacket getResponsePacket] getPayload];
                    Byte buff[[respData length]];
                    [respData getBytes: buff];
                    _mFileSize = CFSwapInt32(*(int *)&buff[2]);
                    
                    [self doTimexBluetoothSmart: [self nextSubAction: SUBACTION_GET_FILE_SIZE]];
                }
                else
                {
                    OTLog(@"DiegoSleep7");
                    [self _flurryResponseError: cmd];
                    [self handleError: SUBACTION_GET_FILE_SIZE withStatus: _mStatus];
                }
                break;
            case ExtenderCmdDelete:
                if ( ACK_NO_ERROR == _mStatus )
                {
                    [self doTimexBluetoothSmart: [self nextSubAction: SUBACTION_DELETE_FILE]];
                }
                else
                {
                    OTLog(@"DiegoSleep8");
                    [self _flurryResponseError: cmd];
                    [self handleError: SUBACTION_DELETE_FILE withStatus: _mStatus];
                }
                break;
            case ExtenderCmdSeek:
                if ( ACK_NO_ERROR == _mStatus )
                {
                    [self doTimexBluetoothSmart: [self nextSubAction: SUBACTION_SEEK_FILE]];
                }
                else
                {
                    OTLog(@"DiegoSleep9");
                    [self _flurryResponseError: cmd];
                    [self handleError: SUBACTION_SEEK_FILE withStatus: _mStatus];
                }
                break;
            case ExtenderCmdWrite:
                statusCallback = false;
                
                if ( ACK_NO_ERROR == _mStatus )
                {
                    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_ActivityTracker && PCCommHeaderNack == TRUE)
                    {
                        
                        OTLog(@"NACK received during ExtenderCmdWrite for M053");
                        
                        //we have received NACK while transmitting a packet... according to M053 development team, we need to send the same packet again
                        [self transmitPacket];
                    }
                    else if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_Metropolitan && PCCommHeaderNack == TRUE)
                    {
                        
                        OTLog(@"NACK received during ExtenderCmdWrite for M372");
                        
                        //we have received NACK while transmitting a packet... according to M053 development team, we need to send the same packet again
                        [self transmitPacket];
                    } else if (([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQ || [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel) && PCCommHeaderNack == TRUE)
                    {
                        
                        OTLog(@"NACK received during ExtenderCmdWrite for M328");
                        
                        //we have received NACK while transmitting a packet... according to M053 development team, we need to send the same packet again
                        [self transmitPacket];
                    }
                    else
                    {
                        NSInteger remainingData = [self popTransmitPacket];
                        if (remainingData > 0 && _mFirmwareUpgradeCancelled == FALSE && _mFirmwareUpgradePaused == FALSE)
                        {
                            // continue writing
                            [self transmitPacket];
                        }
                        else
                        {                            
                            //we've sent everything there was to send, OR the user canceled/paused mid-transfer
                            [self doTimexBluetoothSmart: [self nextSubAction: SUBACTION_FILE_IO]];
                        }
                    }
                }
                else
                {
                    OTLog(@"DiegoSleep10");
                    [self _flurryResponseError: cmd];
                    [self handleError: SUBACTION_FILE_IO withStatus: _mStatus];
                }
                break;
            case ExtenderCmdRead:
                statusCallback = false;
                
                if ( ACK_NO_ERROR == _mStatus )
                {
                    if (_mReceivePackets == nil)
                    {
                        _mReceivePackets = [[NSMutableArray alloc] init];
                    }
                    [_mReceivePackets addObject: receivedPacket];
                    if ([self popTransmitPacket] > 0 )
                    {
                        // continue reading
                        [self transmitPacket];
                    }
                    else
                    {
                        //we read everything there was to read
                        _mFileBytes = [self assembleFile];
                        [self doTimexBluetoothSmart: [self nextSubAction: SUBACTION_FILE_IO]];
                    }
                }
                else
                {
                    OTLog(@"DiegoSleep11");
                    [self _flurryResponseError: cmd];
                    [self handleError: SUBACTION_FILE_IO withStatus: _mStatus];
                }
                break;
            case ExtenderCmdSetSettings:
                if ( ACK_NO_ERROR == _mStatus )
                {
                    [self doTimexBluetoothSmart: [self nextSubAction: SUBACTION_SET_SETTINGS]];
                }
                else
                {
                    OTLog(@"DiegoSleep12");
                    [self _flurryResponseError: cmd];
                    [self handleError: SUBACTION_SET_SETTINGS withStatus: _mStatus];
                }
                break;
            case ExtenderCmdFileSessionStart:
                if ( ACK_NO_ERROR == _mStatus )
                {
                    if (PCCommHeaderNack == TRUE)
                    {
                        
                        OTLog(@"NACK received during ExtenderCmdFileSessionStart");
                        
                        
                        [self doTimexBluetoothSmart: SUBACTION_START];
                    }
                    else
                    {
//                        if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_Metropolitan)
                        if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_Metropolitan ||[[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQ || [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel ){
                            if (([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQ || [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel) && _mAction == ACTION_WRITE_FIRMWARE_FILE)
                            {
                                [[NSNotificationCenter defaultCenter] postNotificationName: kTDM328SessionStartNotification object: self];
                                break;
                            }
                            else
                                [self doTimexBluetoothSmart: [self nextSubAction: SUBACTION_START_FILE_SESSION_M372]];
                            // For calibration
                              [[NSNotificationCenter defaultCenter] postNotificationName: kTDM328SessionStartNotification object: self];
                            
                        }
                        else{
                            [self doTimexBluetoothSmart: [self nextSubAction: SUBACTION_START]];
                        }
                    }
                }
                else
                {
                    OTLog(@"DiegoSleep13");
                    [self _flurryResponseError: cmd];
                    [self handleError: SUBACTION_START withStatus: _mStatus];
                }
                break;
            case ExtenderCmdStartSettings:
            case ExtenderCmdStartFirmware:
            case ExtenderCmdStartWorkout:
            case ExtenderCmdStartActivity:
            case ExtenderCmdStartSleepSummary://TestLog_SleepFiles
            case ExtenderCmdStartSleepKeyFile://TestLog_SleepFiles
//            case ExtenderCmdStartActigraphyFile://TestLog_SleepFiles
                if ( ACK_NO_ERROR == _mStatus )
                {
                    [self doTimexBluetoothSmart: [self nextSubAction: SUBACTION_START]];
                }
                else
                {
                    OTLog(@"DiegoSleep14");
                    [self _flurryResponseError: cmd];
                    [self handleError: SUBACTION_START withStatus: _mStatus];
                }
                break;
            case ExtenderCmdReboot:
                if ( ACK_NO_ERROR == _mStatus )
                {
                    OTLog(@"Reboot performed with no error");
                }
                else
                {
                    OTLog(@"DiegoSleep15");
                    OTLog(@"Reboot performed with errors");
                }
                break;
            case ExtenderCmdFileSessionEnd:
                if ( ACK_NO_ERROR == _mStatus )
                {
                    if (PCCommHeaderNack == TRUE)
                    {
                        
                        OTLog(@"NACK received during ExtenderCmdFileSessionEnd");
                        
                        
                        [self doTimexBluetoothSmart: SUBACTION_END];
                    }
                    else
                    {
//                        if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_Metropolitan)
                         if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_Metropolitan ||
                            [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQ
                              || [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)
                        {
                            [self doTimexBluetoothSmart: [self nextSubAction: SUBACTION_END_FILE_SESSION_M372]];
                        }
                        else
                        {
                            [self doTimexBluetoothSmart: SUBACTION_DONE];
                        }
                    }
                }
                else
                {
                    OTLog(@"DiegoSleep16");
                    [self _flurryResponseError: cmd];
                    [self handleError: SUBACTION_END withStatus: _mStatus];
                }
                break;
            case ExtenderCmdEndSettings:
            case ExtenderCmdEndWorkout:
            case ExtenderCmdEndActivity:
            case ExtenderCmdEndSleepSummary://TestLog_SleepFiles
            case ExtenderCmdEndSleepKeyFile://TestLog_SleepFiles
//            case ExtenderCmdEndActigraphyFile://TestLog_SleepFiles

                if ( ACK_NO_ERROR == _mStatus )
                {
                    if(_mAction == ACTION_WRITE_SETTINGS_FILE
                       && ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQ || [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_Metropolitan || [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)) {
                        [self processReceivedFileData]; // Works?? May be.
                    }
                    else{
                         [self doTimexBluetoothSmart: [self nextSubAction: SUBACTION_END]];
                    }
                }
                else
                {
                    OTLog(@"DiegoSleep17");
                    [self _flurryResponseError: cmd];
                    [self handleError: SUBACTION_END withStatus: _mStatus];
                }
                break;
            case ExtenderCmdEndFirmware:
                if ( ACK_NO_ERROR == _mStatus )
                {
                    [[NSNotificationCenter defaultCenter] postNotificationName: kTDFirmwareWrittenSuccessfullyNotification object: self];
                    [self doTimexBluetoothSmart: [self nextSubAction: SUBACTION_END]];
                }
                else
                {
                    OTLog(@"DiegoSleep18");
                    [self _flurryResponseError: cmd];
                    [self handleError: SUBACTION_END withStatus: _mStatus];
                }
                break;
            case ExtenderCmdRestartFirmware:
                if ( ACK_NO_ERROR == _mStatus )
                {
                    [self doTimexBluetoothSmart: [self nextSubAction: SUBACTION_START]];
                }
                else
                {
                    OTLog(@"DiegoSleep19");
                    [self _flurryResponseError: cmd];
                    [self handleError: SUBACTION_END withStatus: _mStatus];
                }
                break;
                break;
            case ExtenderCmdCancelFirmware:
            case ExtenderCmdPauseFirmware:
                if ( ACK_NO_ERROR == _mStatus )
                {
                    [self doTimexBluetoothSmart: [self nextSubAction: SUBACTION_CANCEL_FILE_IO]];
                }
                else
                {
                    OTLog(@"DiegoSleep20");
                    [self _flurryResponseError: cmd];
                    [self handleError: SUBACTION_CANCEL_FILE_IO withStatus: _mStatus];
                }
                break;
            default:
                break;
        }
    }
}
#pragma mark -
- (void) _flurryResponseError: (int) cmd
{
    OTLog(@"_flurryResponseError PeripheralDevice.m");

    TDFlurryDataPacket * dictFlurry = [[TDFlurryDataPacket alloc] initWithValue: [NSNumber numberWithInt: _mStatus] forKey: @"Error_Code"];
    [dictFlurry setValue: [NSNumber numberWithInt: cmd] forKey: @"PCComm Command"];
    [iDevicesUtil logFlurryEvent: @"BLE_SYNC_ERROR" withParameters:dictFlurry isTimedEvent: NO];
}

- (int) nextSubAction: (int) inSubAction
{
    OTLog(@"nextSubAction PeripheralDevice.m");
    OTLog(@"next Subaction %d for mAction %d",inSubAction,_mAction);
    int subAction = SUBACTION_DONE;
    switch( inSubAction )
    {
        case SUBACTION_NEW:
            switch ( _mAction )
            {
                case ACTION_RESUME_FIRMWARE:
                    subAction = SUBACTION_START;
                    break;
                default:
                    subAction = SUBACTION_WHOS_THERE;
                    break;
            }
            break;
        case SUBACTION_WHOS_THERE:
            switch ( _mAction )
            {
                case ACTION_WRITE_APPT_FILE:
                case ACTION_READ_SYSBLOCK_FILE:
                    subAction = SUBACTION_OPEN_FILE;
                    break;
                case ACTION_WRITE_FIRMWARE_FILE:
                case ACTION_WRITE_LANGUAGE_FILE:
                case ACTION_WRITE_CODEPLUG_FILE:
                case ACTION_READ_M053_FULL_FILE:
                case ACTION_WRITE_M053_FULL_FILE:
                case ACTION_WRITE_M053_APPTS_FILE:
                case ACTION_WRITE_M053_TIME:
                    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_Metropolitan
                        ||[[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQ
                         || [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel
                        )
                        subAction = SUBACTION_START_FILE_SESSION_M372;
                    else
                        subAction = SUBACTION_START;
                    break;
                case ACTION_WRITE_BOOTLOADER_FILE:
                    subAction = SUBACTION_START;
                    break;
                case ACTION_WRITE_TIMEOFDAY:
                    subAction = SUBACTION_SET_SETTINGS;
                    break;
                case ACTION_GET_DEVICE_INFO:
                case ACTION_GET_DEVICE_INFO_FIRMWARE:
                case ACTION_GET_DEVICE_INFO_BOOTLOADER_STATUS:
                    subAction = SUBACTION_DONE;
                    break;
                case ACTION_WRITE_SETTINGS_FILE:
                case ACTION_READ_SETTINGS_FILE:
                case ACTION_READ_M372_ACTIVITY_DATA:
                case ACTION_READ_M372_SLEEP_SUMMARY://TestLog_SleepFiles
                case ACTION_READ_M372_SLEEP_KEY_FILE://TestLog_SleepFiles
                case ACTION_READ_M372_ACTIGRAPHY_FILES://TestLog_SleepFiles
                case ACTION_READ_M372_HOUR_DATA:
                case ACTION_READ_M372_PRE_FIRMWARE_CHARGE_INFO:
                    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_Metropolitan
                        ||[[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQ
                         || [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)
                        subAction = SUBACTION_GET_CHARGE_INFO;
                    else
                        subAction = SUBACTION_START;
                    break;
                default:
                    subAction = SUBACTION_START;
                    break;
            }
            break;
        case SUBACTION_START_FILE_SESSION_M372:
            subAction = SUBACTION_START;
            break;
        case SUBACTION_END_FILE_SESSION_M372:
            if (_mAction == ACTION_WRITE_BOOTLOADER_FILE)
                subAction = SUBACTION_END;
            else
                subAction = SUBACTION_DONE;
            break;
        case SUBACTION_GET_CHARGE_INFO:
            if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_Metropolitan
                || [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQ
                 || [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)
            {
                if (_mAction != ACTION_READ_M372_PRE_FIRMWARE_CHARGE_INFO){
                    subAction = SUBACTION_GET_EXTENDED_FIRMWARE_VERSION_INFO;
                }
                else{
                    subAction = SUBACTION_DONE;
                }
            }
//            else if([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQ){
//                subAction = SUBACTION_START_FILE_SESSION_M372;
//            }
            else
                subAction = SUBACTION_DONE;
            break;
        case SUBACTION_GET_EXTENDED_FIRMWARE_VERSION_INFO:
            if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_Metropolitan ||
                [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQ
                 || [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)
            {
                subAction = SUBACTION_START_FILE_SESSION_M372;
            }
            else
                subAction = SUBACTION_DONE;
            break;
        case SUBACTION_START:
            subAction = SUBACTION_OPEN_FILE;
            break;
        case SUBACTION_DELETE_FILE:
            //right now, only being used when we delete file after reading workouts
            subAction = SUBACTION_DONE;
            break;
        case SUBACTION_OPEN_FILE:
            switch ( _mAction )
            {
                case ACTION_READ_M053_FULL_FILE:
                    subAction = SUBACTION_GET_FILE_SIZE;
                    break;
                
                case ACTION_WRITE_M053_FULL_FILE:
                case ACTION_WRITE_M053_APPTS_FILE:
                case ACTION_WRITE_M053_TIME:
                case ACTION_WRITE_FIRMWARE_FILE:
                case ACTION_WRITE_LANGUAGE_FILE:
                case ACTION_WRITE_CODEPLUG_FILE:
                case ACTION_WRITE_APPT_FILE:
                case ACTION_WRITE_BOOTLOADER_FILE:
                case ACTION_GET_DEVICE_INFO_BOOTLOADER_STATUS:
                    subAction = SUBACTION_FILE_IO;
                    break;
                case ACTION_RESUME_FIRMWARE:
                    subAction = SUBACTION_GET_FILE_SIZE;
                    break;
                default:
                    subAction = SUBACTION_SEEK_FILE;
                    break;
            }
            break;
        case SUBACTION_SEEK_FILE:
            switch ( _mAction )
            {
                case ACTION_RESUME_FIRMWARE:
                    subAction = SUBACTION_FILE_IO;
                    break;
                default:
                    subAction = SUBACTION_GET_FILE_SIZE;
                    break;
            }
                break;
            break;
        case SUBACTION_GET_FILE_SIZE:
            switch ( _mAction )
            {
                case ACTION_RESUME_FIRMWARE:
                    subAction = SUBACTION_SEEK_FILE;
                    break;
                default:
                    subAction = SUBACTION_FILE_IO;
                    break;
            }
            break;
        case SUBACTION_FILE_IO:
            subAction = SUBACTION_CLOSE_FILE;
            break;
        case SUBACTION_CLOSE_FILE:
            switch ( _mAction )
            {
                case ACTION_WRITE_FIRMWARE_FILE:
                case ACTION_WRITE_LANGUAGE_FILE:
                case ACTION_WRITE_CODEPLUG_FILE:
                    //we may need to repeat....
                    if (_mFirmwareUpgradeProcessedFileIndex < _mFirmwareUpgradePendingFiles.count - 1 && _mFirmwareUpgradeCancelled == FALSE && _mFirmwareUpgradePaused == FALSE)
                    {
                        if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_Metropolitan ||[[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQ || [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)
                        {
                            //we just successfully wrote some file to the watch... let's update the settings
                            [self recordM372FirmwareFileUpgrade: [_mFirmwareUpgradePendingFiles objectAtIndex: _mFirmwareUpgradeProcessedFileIndex]];
                        }
                        
                        _mFileBytes = nil;
                        _mFirmwareUpgradeProcessedFileIndex++;
                        [self prepNextFirmwareUpgradeFileForShipment];
                        
                        subAction = SUBACTION_OPEN_FILE;
                    }
                    else
                    {
                        if (_mFirmwareUpgradePaused != TRUE)
                        {
                            if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_Metropolitan)
                            {
                                //we just successfully wrote some file to the watch... let's update the settings
                                [self recordM372FirmwareFileUpgrade: [_mFirmwareUpgradePendingFiles objectAtIndex: _mFirmwareUpgradeProcessedFileIndex]];
                            }
                            
                            //either we have reached the end with no more files to transfer to the watch, OR the user canceled mid-transfer
                            //if the user paused, hang on to these because we'll attempt to restart
                            _mFirmwareUpgradeProcessedFileIndex = NSIntegerMax;
                            _mFirmwareUpgradePendingFiles = nil;
                        }
                        
                        //do not reset _mFirmwareUpgradeCancelled yet... we'll need it later to determine whether to send END or CANCEL command to the watch
                        
                        subAction = SUBACTION_END;
                    }
                    break;
                case ACTION_WRITE_BOOTLOADER_FILE:
                {
                    //we may need to repeat....
                    if (_mFirmwareUpgradeProcessedFileIndex < _mFirmwareUpgradePendingFiles.count - 1 && _mFirmwareUpgradeCancelled == FALSE && _mFirmwareUpgradePaused == FALSE)
                    {
                        if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_Metropolitan)
                        {
                            //we just successfully wrote some file to the watch... let's update the settings
                            [self recordM372FirmwareFileUpgrade: [_mFirmwareUpgradePendingFiles objectAtIndex: _mFirmwareUpgradeProcessedFileIndex]];
                        }
                        
                        _mFileBytes = nil;
                        _mFirmwareUpgradeProcessedFileIndex++;
                        [self prepNextFirmwareUpgradeFileForShipment];
                        
                        subAction = SUBACTION_OPEN_FILE;
                    }
                    else
                    {
                        if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_Metropolitan)
                        {
                            //we just successfully wrote some file to the watch... let's update the settings
                            [self recordM372FirmwareFileUpgrade: [_mFirmwareUpgradePendingFiles objectAtIndex: _mFirmwareUpgradeProcessedFileIndex]];
                        }
                        
                        //do not reset _mFirmwareUpgradeCancelled yet... we'll need it later to determine whether to send END or CANCEL command to the watch
                        subAction = SUBACTION_DONE;
                    }
                }
                    break;
                case ACTION_READ_SYSBLOCK_FILE:
                {
                    OTLog(@"PeripheralDevice ACTION_READ_SYSBLOCK_FILE");
                    [self processReceivedFileData];
                    
                    _mAction = ACTION_READ_M372_SLEEP_KEY_FILE;//TestLog_SleepFiles
                    subAction = SUBACTION_START;
                }
                    break;
                default:
                    subAction = SUBACTION_END;
                    break;
            }
            break;
        case SUBACTION_SET_SETTINGS:
        {
            subAction = SUBACTION_DONE;
        }
            break;
        case SUBACTION_CANCEL_FILE_IO:
            subAction = SUBACTION_DONE;
            break;
        case SUBACTION_END:
            switch ( _mAction )
            {
                case ACTION_READ_CHRONOS_FILE:
                {
                    NSString * key = [iDevicesUtil createKeyForAppSettingsPropertyWithClass: appSettings_PropertyClass_Workouts andIndex: appSettings_PropertyClass_Workouts_DeleteAfterSync];
                    
                    BOOL deleteAfter = [[NSUserDefaults standardUserDefaults] boolForKey: key];
                    
                    if (deleteAfter)
                        subAction = SUBACTION_DELETE_FILE;
                    else
                        subAction = SUBACTION_DONE;
                }
                    break;
                default:
                    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_Metropolitan
                        || [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQ
                         || [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel
                        )
                    {
                        OTLog(@"PeripheralDevice nextSubAction default");
                        // MOST IMPORTANT FOR AUTOSYNC-- NARESH
                        //you think we are done? HAHA.... Not even close. Time to read Activity Data....
                        if (_mAction == ACTION_READ_SETTINGS_FILE)
                        {
                            OTLog(@"PeripheralDevice ACTION_READ_SETTINGS_FILE");
                            [self processReceivedFileData];
                            
                            _mAction = ACTION_READ_M372_ACTIVITY_DATA;
                            subAction = SUBACTION_START;
                        }
                        else if (_mAction == ACTION_READ_M372_ACTIVITY_DATA)
                        {
                            OTLog(@"PeripheralDevice ACTION_READ_M372_ACTIVITY_DATA");
                          [self processReceivedFileData];
                            long firmwareVersion2 = [[[[NSUserDefaults standardUserDefaults] objectForKey: kM372FirmwareVersionFile3Key] stringByReplacingOccurrencesOfString:@"M328F" withString:@""] integerValue];
                            NSString *firmwareVersion = [[[NSUserDefaults standardUserDefaults] stringForKey:@"kM372FirmwareVersionFile3Key"] stringByReplacingOccurrencesOfString:@"M372F" withString:@""];
                            if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQ && (firmwareVersion2 >= 12))
                            {
                                _mAction = ACTION_READ_SYSBLOCK_FILE;
                                subAction = SUBACTION_OPEN_FILE;
                            }
                            else if ([firmwareVersion integerValue] >= 100 || [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQ  || [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)
                            {
                                _mAction = ACTION_READ_M372_SLEEP_KEY_FILE;//TestLog_SleepFiles
                                subAction = SUBACTION_START;
                            }
                            else
                            {
                                OTLog(@"Skipping actigraphy files for Metro from Activity data");
                                TDM372WatchSettings * watchSettings = [[TDM372WatchSettings alloc] init];
                                if (watchSettings != nil)
                                {
                                    _mFileBytes = [watchSettings toByteArray];
                                    _mAction = ACTION_WRITE_SETTINGS_FILE;
                                    subAction = SUBACTION_START;
                                }
                            }
                        }
                        //TestLog_SleepFiles
                        else if (_mAction == ACTION_READ_M372_SLEEP_KEY_FILE)
                        {
                            OTLog(@"PeripheralDevice ACTION_READ_M372_SLEEP_KEY_FILE");
                            [self processReceivedFileData];
                            _mAction = ACTION_READ_M372_SLEEP_SUMMARY;
                            subAction = SUBACTION_START;
                        }
                        
                        else if (_mAction == ACTION_READ_M372_ACTIGRAPHY_FILES)
                        {
                            OTLog(@"PeripheralDevice ACTION_READ_M372_ACTIGRAPHY_FILES");
                            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                            NSMutableArray *tempKeysArray = [[NSMutableArray alloc]init];
                            
                            tempKeysArray = [[defaults objectForKey:@"fakeEpochs"] mutableCopy];
                            OTLog(@"TestLogTempKeysArray: %@",tempKeysArray);
                            
                            [self processReceivedFileData];
                            
                            if (tempKeysArray.count > 0)
                            {
                                _mAction = ACTION_READ_M372_ACTIGRAPHY_FILES;//TestLog_SleepFiles
                                subAction = SUBACTION_START;
                                OTLog(@"Need to read actigraphy files");
                            }
                            else {
                                [[NSUserDefaults standardUserDefaults] setObject:@[@"0",@"1",@"2",@"3",@"4",@"5",@"6",@"7"] forKey:@"ActigraphyStepFileNames"];
                                [[NSUserDefaults standardUserDefaults] synchronize];
                                if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_Metropolitan || [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQ || [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel) {
                                    _mAction = ACTION_READ_M372_HOUR_DATA;//TestLog_SleepFiles
                                    subAction = SUBACTION_START;
                                }
                            }
                        }
                        else if (_mAction == ACTION_READ_M372_HOUR_DATA) {
                            OTLog(@"PeripheralDevice ACTION_READ_M372_HOUR_DATA");
                            [self processReceivedFileData];
                            if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"ActigraphyStepFileNames"] count] > 0)
                            {
                                _mAction = ACTION_READ_M372_HOUR_DATA;//TestLog_SleepFiles
                                subAction = SUBACTION_START;
                                OTLog(@"Need to read actigraphy files");
                            } else {
                                // Probably have to check for iQ + watch here and do the sync
                                if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_Metropolitan){
                                    TDM372WatchSettings * watchSettings = [[TDM372WatchSettings alloc] init];
                                    if (watchSettings != nil)
                                    {
                                        _mFileBytes = [watchSettings toByteArray];
                                        _mAction = ACTION_WRITE_SETTINGS_FILE;
                                        subAction = SUBACTION_START;
                                    }
                                }
                                else if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQ)
                                {
                                    TDM328WatchSettings * watchSettings = [[TDM328WatchSettings alloc] init];
                                    if (watchSettings != nil)
                                    {
                                        _mFileBytes = [watchSettings toByteArray];
                                        _mAction = ACTION_WRITE_SETTINGS_FILE;
                                        subAction = SUBACTION_START;
                                    }
                                }
                                else if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)
                                {
                                    TDM329WatchSettings * watchSettings = [[TDM329WatchSettings alloc] init];
                                    if (watchSettings != nil)
                                    {
                                        _mFileBytes = [watchSettings toByteArray];
                                        _mAction = ACTION_WRITE_SETTINGS_FILE;
                                        subAction = SUBACTION_START;
                                    }
                                }
                            }
                        }
                        //TestLog_SleepFiles
                        else if (_mAction == ACTION_READ_M372_SLEEP_SUMMARY)
                        {
                            OTLog(@"PeripheralDevice ACTION_READ_M372_SLEEP_SUMMARY");
                            [self processReceivedFileData];
                            
                            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                            NSMutableArray *tempKeysArray = [[NSMutableArray alloc]init];
                            
                            tempKeysArray = [[defaults objectForKey:@"fakeEpochs"] mutableCopy];
                            OTLog(@"TestLogTempKeysArrayCount: %@",tempKeysArray);
                            if (tempKeysArray.count > 0 )
                            {
                                OTLog(@"Need to read actigraphy files");
                                _mAction = ACTION_READ_M372_ACTIGRAPHY_FILES;
                                subAction = SUBACTION_START;

                            }
                            else
                            {
                                [[NSUserDefaults standardUserDefaults] setObject:@[@"0",@"1",@"2",@"3",@"4",@"5",@"6",@"7"] forKey:@"ActigraphyStepFileNames"];
                                [[NSUserDefaults standardUserDefaults] synchronize];
                                if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_Metropolitan || [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQ || [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel){
                                    OTLog(@"Skipping actigraphy files from sleep summary");
                                    _mAction = ACTION_READ_M372_HOUR_DATA;//TestLog_SleepFiles
                                    subAction = SUBACTION_START;
                                }
                            }
                        }
                        else
                        {
                            if (_mAction != ACTION_WRITE_FIRMWARE_FILE)
                                subAction = SUBACTION_END_FILE_SESSION_M372;
                        }
                    }
                    else
                        subAction = SUBACTION_DONE;
                    break;
            }
            break;
    }
    OTLog(@"Test");
    return subAction;
}

- (NSInteger) popTransmitPacket
{
    OTLog(@"PeripheralDevice popTransmitPacket");
    NSInteger size = 0;
    if ( nil != _mTransmitPackets )
    {
        size = [_mTransmitPackets count];
        if ( size > 0 )
        {
            [_mTransmitPackets removeObjectAtIndex: 0];
            size -= 1;
        }
        if ( size == 0 )
        {
            _mTransmitPackets = nil;
        }
    }
    return size;
}

- (PCCPacket *) assemblePacket
{
    OTLog(@"PeripheralDevice assemblePacket");
    PCCPacket * receivedPacket = nil;
    
    if ([((NSData *)[_mPacketHandle objectAtIndex: 0]) length] > 0 )
    {
        NSData * dataZero = [_mPacketHandle objectAtIndex: 0];
        Byte bufferZero[[dataZero length]];
        [dataZero getBytes: bufferZero];
        
        Byte packetLength = bufferZero[2];
        Byte psize = (Byte)(packetLength + [PCCHeader size]);
        if ( psize < 18 )
        {
            psize = 18;
        }
        
        int bufferLength = 18 * 4;
        Byte buffer[ bufferLength];
        int i, length = 0;
        NSInteger initialNumberOfPackets = [_mPacketHandle count];
        for ( i = 0; i < initialNumberOfPackets; i++ )
        {
            NSData * dataX = [_mPacketHandle objectAtIndex: 0];
            if ( [dataX length] > 0 )
            {
                Byte rawdata[[dataX length]];
                [dataX getBytes: rawdata];
                memcpy( &buffer[length], rawdata, [dataX length]);
                
                length += [dataX length];
                
                [_mPacketHandle removeObjectAtIndex: 0];
            }
        }
        
        Byte completeRawData[length];
        memcpy( completeRawData, buffer, length);
  
        receivedPacket = [[PCCPacket alloc] initWithResponseRawData: [NSData dataWithBytes: completeRawData length: length]];
    }
    return receivedPacket;
}

- (void) doTimexBluetoothSmart: (int) inSubAction
{
    OTLog(@"doTimexBluetoothSmart PeripheralDevice.m");
    OTLog(@"Subaction %d and mAction %d",inSubAction,_mAction);

    switch( inSubAction )
    {
        case SUBACTION_WHOS_THERE:
            [self whosThere];
            break;
        case SUBACTION_GET_CHARGE_INFO:
            [self getBatteryInfo];
            break;
        case SUBACTION_GET_EXTENDED_FIRMWARE_VERSION_INFO:
            [self getExtendedFirmwareVersionsInfo];
            break;
        case SUBACTION_START:
            [self start];
            break;
        case SUBACTION_START_FILE_SESSION_M372:
            [self startFileAccessSession];
            break;
        case SUBACTION_END_FILE_SESSION_M372:
            [self endFileAccessSession];
            break;
        case SUBACTION_OPEN_FILE:
            [self openFile: _mAction];
            break;
        case SUBACTION_SEEK_FILE:
            switch (_mAction)
            {
                case ACTION_RESUME_FIRMWARE:
                   [self doSeekFile: _mFileSize];
                    break;
                default:
                    [self doSeekFile: 0];
                    break;
            }
            break;
        case SUBACTION_GET_FILE_SIZE:
            [self getFileSize];
            break;
        case SUBACTION_FILE_IO:
            [self doFileIO];
            break;
        case SUBACTION_CLOSE_FILE:
            [self closeFile];
            break;
        case SUBACTION_END:
            [self _end];
            break;
        case SUBACTION_DELETE_FILE:
             [self deleteFile: [self getFileName : _mAction]];
            break;
        case SUBACTION_SET_SETTINGS:
            break;
        case SUBACTION_REBOOT:
            [self _reboot];
            break;
        case SUBACTION_DONE:
            [self processReceivedFileData];
            [self processNextCommandInQueueIfAny];
            break;
    }
}
- (void) whosThere
{
    OTLog(@"whosThere PeripheralDevice.m");

    PCCPacket * whosTherePacket = [[PCCPacket alloc] init: WhosThere];
    if ( nil != whosTherePacket )
    {
        [self writePCCommPacket: whosTherePacket];
    }
}

- (void) getBatteryInfo
{
    OTLog(@"getBatteryInfo PeripheralDevice.m");

    PCCPacket * whosTherePacket = [[PCCPacket alloc] init: ExtenderCmdReadChargeInfo];
    if ( nil != whosTherePacket )
    {
        [self writePCCommPacket: whosTherePacket];
    }
}
- (void) getExtendedFirmwareVersionsInfo
{
    OTLog(@"PeripheralDevice getExtendedFirmwareVersionsInfo");
    PCCPacket * whosTherePacket = [[PCCPacket alloc] init: ExtenderCmdGetExtraFirmwareRevisions];
    if ( nil != whosTherePacket )
    {
        [self writePCCommPacket: whosTherePacket];
    }
}
- (void) startFileAccessSession
{
    OTLog(@"PeripheralDevice startFileAccessSession");
    PCCPacket * newPacket = [[PCCPacket alloc] init: ExtenderCmdFileSessionStart];
    if ( nil != newPacket )
    {
        [self writePCCommPacket: newPacket];
    }
}
- (void) endFileAccessSession
{
    OTLog(@"PeripheralDevice endFileAccessSession");
    PCCPacket * newPacket = [[PCCPacket alloc] init: ExtenderCmdFileSessionEnd];
    if ( nil != newPacket )
    {
        [self writePCCommPacket: newPacket];
    }
}
- (void) startSettings
{
    OTLog(@"PeripheralDevice startSettings");
    PCCPacket * newPacket = [[PCCPacket alloc] init: ExtenderCmdStartSettings];
    if ( nil != newPacket )
    {
        [self writePCCommPacket: newPacket];
    }
}
- (void) endSettings
{
    OTLog(@"PeripheralDevice endSettings");
    PCCPacket * newPacket = [[PCCPacket alloc] init: ExtenderCmdEndSettings];
    if ( nil != newPacket )
    {
        [self writePCCommPacket: newPacket];
    }
}
- (void) startActivity
{
    OTLog(@"PeripheralDevice startActivity");
    PCCPacket * newPacket = [[PCCPacket alloc] init: ExtenderCmdStartActivity];
    if ( nil != newPacket )
    {
        [self writePCCommPacket: newPacket];
    }
}
- (void) endActivity
{
    OTLog(@"PeripheralDevice endActivity");
    PCCPacket * newPacket = [[PCCPacket alloc] init: ExtenderCmdEndActivity];
    if ( nil != newPacket )
    {
        [self writePCCommPacket: newPacket];
    }
}

//TestLog_SleepFiles
- (void) startSleepSummaryKeyFile
{
    OTLog(@"startSleepSummaryKeyFile PeripheralDevice.m");

    OTLog(@"DiegoTest1");
    PCCPacket * newPacket = [[PCCPacket alloc] init: ExtenderCmdStartSleepSummary];
    
    //PCCPacket * newPacket = [[PCCPacket alloc] init: ExtenderCmdStartSleepKeyFile]; REAL
    if ( nil != newPacket )
    {OTLog(@"DiegoTest2");
        [self writePCCommPacket: newPacket];
    }
}
- (void) endSleepSummaryKeyFile
{
    OTLog(@"endSleepSummaryKeyFile PeripheralDevice.m");
    OTLog(@"DiegoTest3");
    PCCPacket * newPacket = [[PCCPacket alloc] init: ExtenderCmdEndSleepSummary];
    
    //PCCPacket * newPacket = [[PCCPacket alloc] init: ExtenderCmdEndSleepKeyFile]; REAL
    if ( nil != newPacket )
    {
        OTLog(@"DiegoTest4");
        [self writePCCommPacket: newPacket];
    }
}

- (void) startSleepSummary
{
    OTLog(@"startSleepSummary PeripheralDevice.m");
    PCCPacket * newPacket = [[PCCPacket alloc] init: ExtenderCmdStartSleepSummary];
    
    //PCCPacket * newPacket = [[PCCPacket alloc] init: ExtenderCmdStartSleepSummary]; REAL
    if ( nil != newPacket )
    {
        [self writePCCommPacket: newPacket];
    }
}
- (void) endSleepSummary
{
    OTLog(@"endSleepSummary PeripheralDevice.m");
    PCCPacket * newPacket = [[PCCPacket alloc] init: ExtenderCmdEndSleepSummary];
    
    //PCCPacket * newPacket = [[PCCPacket alloc] init: ExtenderCmdEndSleepSummary]; REAL
    if ( nil != newPacket )
    {
        [self writePCCommPacket: newPacket];
    }
}

- (void) startSleepSummaryActigraphyFile
{
    OTLog(@"startSleepSummaryActigraphyFile PeripheralDevice.m");

    PCCPacket * newPacket = [[PCCPacket alloc] init: ExtenderCmdStartSleepSummary];
    
    //PCCPacket * newPacket = [[PCCPacket alloc] init: ExtenderCmdStartSleepSummary];REAL
    if ( nil != newPacket )
    {
        [self writePCCommPacket: newPacket];
    }
}
- (void) endSleepSummaryActigraphyFile
{
    OTLog(@"endSleepSummaryActigraphyFile PeripheralDevice.m");
    PCCPacket * newPacket = [[PCCPacket alloc] init: ExtenderCmdEndSleepSummary];
    
    //PCCPacket * newPacket = [[PCCPacket alloc] init: ExtenderCmdEndSleepSummary];REAL
    if ( nil != newPacket )
    {
        [self writePCCommPacket: newPacket];
    }
}
- (void) startActigraphyStepFile
{
    OTLog(@"startActigraphyStepFile PeripheralDevice.m");
    
    PCCPacket * newPacket = [[PCCPacket alloc] init: ExtenderCmdStartSleepSummary];
    
    if ( nil != newPacket )
    {
        [self writePCCommPacket: newPacket];
    }
}
- (void) endActigraphyStepFile
{
    OTLog(@"endActigraphyStepFile PeripheralDevice.m");
    PCCPacket * newPacket = [[PCCPacket alloc] init: ExtenderCmdEndSleepSummary];
    
    if ( nil != newPacket )
    {
        [self writePCCommPacket: newPacket];
    }
}
//TestLog_SleepFiles
- (void) startFirmware
{
    OTLog(@"startFirmware PeripheralDevice.m");

    BOOL firmwareFlag = FALSE;
    BOOL codeplugFlag = FALSE;
    BOOL languageFlag = FALSE;
    
//    if ([[TDWatchProfile sharedInstance] watchStyle] != timexDatalinkWatchStyle_Metropolitan)
     if ([[TDWatchProfile sharedInstance] watchStyle] != timexDatalinkWatchStyle_Metropolitan || [[TDWatchProfile sharedInstance]watchStyle] == timexDatalinkWatchStyle_IQ || [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)
    {
        for (TDDatacastFirmwareUpgradeInfo * downloadInfo in _mFirmwareUpgradePendingFiles)
        {
            if (downloadInfo.type == TDDatacastFirmwareUpgradeInfoType_Firmware)
                firmwareFlag = TRUE;
            else if (downloadInfo.type == TDDatacastFirmwareUpgradeInfoType_Language)
                languageFlag = TRUE;
            else if (downloadInfo.type == TDDatacastFirmwareUpgradeInfoType_Codeplug)
                codeplugFlag = TRUE;
        }
    }
    
    PCCPacket * newPacket = [[PCCPacket alloc] init: ExtenderCmdStartFirmware firmwareFlag: firmwareFlag codeplugFlag: codeplugFlag languageFlag: languageFlag];
    if ( nil != newPacket )
    {
        [self writePCCommPacket: newPacket];
    }
}
- (void) resumeFirmware
{
    OTLog(@"resumeFirmware PeripheralDevice.m");

    BOOL firmwareFlag = FALSE;
    BOOL codeplugFlag = FALSE;
    BOOL languageFlag = FALSE;
    
    for (TDDatacastFirmwareUpgradeInfo * downloadInfo in _mFirmwareUpgradePendingFiles)
    {
        if (downloadInfo.type == TDDatacastFirmwareUpgradeInfoType_Firmware)
            firmwareFlag = TRUE;
        else if (downloadInfo.type == TDDatacastFirmwareUpgradeInfoType_Language)
            languageFlag = TRUE;
        else if (downloadInfo.type == TDDatacastFirmwareUpgradeInfoType_Codeplug)
            codeplugFlag = TRUE;
    }
    
    PCCPacket * newPacket = [[PCCPacket alloc] init: ExtenderCmdRestartFirmware firmwareFlag: firmwareFlag codeplugFlag: codeplugFlag languageFlag: languageFlag];
    if ( nil != newPacket )
    {
        [self writePCCommPacket: newPacket];
    }
}
- (void) endFirmware
{
    OTLog(@"endFirmware PeripheralDevice.m");

    PCCPacket * newPacket = [[PCCPacket alloc] init: ExtenderCmdEndFirmware];
    if ( nil != newPacket )
    {
        [self writePCCommPacket: newPacket];
    }
}
- (void) cancelFirmware
{
    OTLog(@"cancelFirmware PeripheralDevice.m");

    PCCPacket * newPacket = [[PCCPacket alloc] init: ExtenderCmdCancelFirmware];
    if ( nil != newPacket )
    {
        [self writePCCommPacket: newPacket];
    }
}
- (void) pauseFirmware
{
    OTLog(@"pauseFirmware PeripheralDevice.m");

    PCCPacket * newPacket = [[PCCPacket alloc] init: ExtenderCmdPauseFirmware];
    if ( nil != newPacket )
    {
        [self writePCCommPacket: newPacket];
    }
}
- (void) startWorkout
{
    OTLog(@"startWorkout PeripheralDevice.m");
    PCCPacket * newPacket = [[PCCPacket alloc] init: ExtenderCmdStartWorkout];
    if ( nil != newPacket )
    {
        [self writePCCommPacket: newPacket];
    }
}
- (void) endWorkout
{
    OTLog(@"endWorkout PeripheralDevice.m");
    PCCPacket * newPacket = [[PCCPacket alloc] init: ExtenderCmdEndWorkout];
    if ( nil != newPacket )
    {
        [self writePCCommPacket: newPacket];
    }
}
- (void) doFileIO
{
    OTLog(@"PeripheralDevice doFileIO");
    switch( _mAction )
    {
        case ACTION_READ_M053_FULL_FILE:
        case ACTION_READ_SETTINGS_FILE:
        case ACTION_READ_M372_ACTIVITY_DATA:
        case ACTION_READ_M372_SLEEP_SUMMARY: //TestLog_SleepFiles
        case ACTION_READ_M372_ACTIGRAPHY_FILES:
        case ACTION_READ_M372_HOUR_DATA:
        case ACTION_READ_M372_SLEEP_KEY_FILE: //TestLog_SleepFiles
        case ACTION_READ_CHRONOS_FILE:
        case ACTION_READ_SYSBLOCK_FILE:
            [self readFile: _mFileHandle withFileSize: _mFileSize];
            break;
        case ACTION_WRITE_M053_FULL_FILE:
        case ACTION_WRITE_M053_APPTS_FILE:
        case ACTION_WRITE_M053_TIME:
        case ACTION_WRITE_SETTINGS_FILE:
        case ACTION_WRITE_APPT_FILE:
        case ACTION_WRITE_FIRMWARE_FILE:
        case ACTION_WRITE_LANGUAGE_FILE:
        case ACTION_WRITE_CODEPLUG_FILE:
        case ACTION_WRITE_BOOTLOADER_FILE:
            [self writeFile: _mFileHandle];
            break;
        case ACTION_RESUME_FIRMWARE:
            [self restartFirmwareFile: _mFileHandle];
            break;
    }
}
- (void) start
{
    OTLog(@"start PeripheralDevice.m");

    switch( _mAction )
    {
        case ACTION_READ_SETTINGS_FILE:
        case ACTION_WRITE_SETTINGS_FILE:
            [self startSettings];
            break;
        case ACTION_READ_M372_ACTIVITY_DATA:
            [self startActivity];
            break;
        case ACTION_READ_M372_SLEEP_SUMMARY: //TestLog_SleepFiles
            [self startSleepSummary];
            break;
        case ACTION_READ_M372_SLEEP_KEY_FILE: //TestLog_SleepFiles
            [self startSleepSummaryKeyFile];
            break;
        case ACTION_READ_M372_ACTIGRAPHY_FILES: //TestLog_SleepFiles
            [self startSleepSummaryActigraphyFile];
            break;
        case ACTION_READ_M372_HOUR_DATA:
            [self startActigraphyStepFile];
            break;
        case ACTION_WRITE_APPT_FILE:
            break;
        case ACTION_READ_M053_FULL_FILE:
        case ACTION_WRITE_M053_FULL_FILE:
        case ACTION_WRITE_M053_APPTS_FILE:
        case ACTION_WRITE_M053_TIME:
            [self startFileAccessSession];
            break;
        
        case ACTION_WRITE_FIRMWARE_FILE:
        case ACTION_WRITE_LANGUAGE_FILE:
        case ACTION_WRITE_CODEPLUG_FILE:
            [self startFirmware];
            break;
        case ACTION_WRITE_BOOTLOADER_FILE:
            [self openFile: _mAction];
            break;
        case ACTION_RESUME_FIRMWARE:
            [self resumeFirmware];
            break;
        case ACTION_READ_CHRONOS_FILE:
            [self startWorkout];
            break;
    }
}
             
 - (NSString * ) getFileName: (int) inAction
{
    OTLog(@"getFileName PeripheralDevice.m");
    NSString * name = nil;
    int currentAction = inAction;
    if (inAction == ACTION_RESUME_FIRMWARE)
    {
        TDDatacastFirmwareUpgradeInfo * downloadInfo = [_mFirmwareUpgradePendingFiles objectAtIndex: _mFirmwareUpgradeProcessedFileIndex];
        switch (downloadInfo.type)
        {
            case TDDatacastFirmwareUpgradeInfoType_Firmware:
                currentAction = ACTION_WRITE_FIRMWARE_FILE;
                break;
            case TDDatacastFirmwareUpgradeInfoType_Codeplug:
                currentAction = ACTION_WRITE_CODEPLUG_FILE;
                break;
            case TDDatacastFirmwareUpgradeInfoType_Language:
                currentAction = ACTION_WRITE_LANGUAGE_FILE;
                break;
        }
    }
    
    switch ( currentAction )
    {
        case ACTION_WRITE_M053_TIME:
            name = [NSString stringWithFormat: @"SETTINGS.BIN"];
            break;
        case ACTION_READ_M053_FULL_FILE:
        case ACTION_WRITE_M053_FULL_FILE:
            name = [NSString stringWithFormat: @"FULLFILE.BIN"];
            break;
        case ACTION_WRITE_M053_APPTS_FILE:
            name = [NSString stringWithFormat: @"APPTMNTS.BIN"];
            break;
        case ACTION_READ_M372_ACTIVITY_DATA:
        {
            if([[TDWatchProfile sharedInstance]watchStyle] == timexDatalinkWatchStyle_IQ){
                name = [NSString stringWithFormat: @"M328A%03d.ACT",M328_ACTIVITY_VERSION]; // Chaning name of this stuff.
            }
            else if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel) {
                name = [NSString stringWithFormat: @"M329A%03d.ACT",M328_ACTIVITY_VERSION];
            }
            else{
                name = [NSString stringWithFormat: @"M372A%03d.ACT", M372_ACTIVITY_VERSION];
            }
            OTLog(@"ACTIVITY DATA Started Reading: %@",name);
        }
            break;
            //TestLog_SleepFiles
        case ACTION_READ_M372_SLEEP_SUMMARY:{
            if([[TDWatchProfile sharedInstance]watchStyle] == timexDatalinkWatchStyle_IQ){
                name = [NSString stringWithFormat: @"M328S%03d.SLP",M328_SLEEP_SUMMARY_VERSION]; // Chaning name of this stuff.
            }
            else if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel) {
                name = [NSString stringWithFormat: @"M329S%03d.SLP",M328_SLEEP_SUMMARY_VERSION];
            }
            else{
                name = [NSString stringWithFormat: @"M372S%03d.SLP",M372_SLEEP_SUMMARY_VERSION];
            }
            OTLog(@"SLEEP SUMMARY FILES Started Reading: %@",name);
        }
            
            break;
        case ACTION_READ_M372_SLEEP_KEY_FILE:{
            if([[TDWatchProfile sharedInstance]watchStyle] == timexDatalinkWatchStyle_IQ){
                name = [NSString stringWithFormat: @"M328K%03d.SLP",M328_SLEEP_KEY_VERSION]; // Chaning name of this stuff.
            }
            else if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel) {
                name = [NSString stringWithFormat: @"M329K%03d.SLP",M328_SLEEP_KEY_VERSION];
            }
            else{
                name = [NSString stringWithFormat: @"M372K%03d.SLP",M372_SLEEP_KEY_VERSION];
            }
            OTLog(@"SLEEP KEY FILES Started Reading: %@",name);
        }
            
            break;
        case ACTION_READ_M372_ACTIGRAPHY_FILES:
        {
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            NSMutableArray *tempKeysArray = nil;
            
            tempKeysArray = [[defaults objectForKey:@"fakeEpochs"]mutableCopy];
            OTLog(@"ACTIGRAPHY_FILES: %@",tempKeysArray);
            NSString *tempString = @"";
            if (tempKeysArray.count > 0)
                tempString = [NSString stringWithFormat:@"%@",[tempKeysArray objectAtIndex:0]];
            
            else
                tempString = [NSString stringWithFormat:@"0"];
            
            [defaults removeObjectForKey:@"dataFake"];
            
            [defaults setInteger:[tempString intValue] forKey:@"dataFake"];
            //////
            name = [NSString stringWithFormat: @"M372A%@01.SLP",tempString];
            
            if([[TDWatchProfile sharedInstance]watchStyle] == timexDatalinkWatchStyle_IQ){
                name = [NSString stringWithFormat: @"M328A%@01.SLP",tempString];//@"M328A%@01.SLP";
            }
            else if ([[TDWatchProfile sharedInstance]watchStyle] == timexDatalinkWatchStyle_IQTravel)
            {
                name = [NSString stringWithFormat: @"M329A%@01.SLP",tempString];
            }
            OTLog(@"ACTIGRAPHY FILES Started Reading: %@",name);
            [defaults setObject:name forKey:@"fileName"];
            /////
            if(tempKeysArray.count >0)
                [tempKeysArray removeObjectAtIndex:0];
            
            [defaults setObject:tempKeysArray forKey:@"fakeEpochs"];
            [defaults synchronize];
        }
            break;
        case ACTION_READ_M372_HOUR_DATA:
        {
            NSUserDefaults *userdefaults = [NSUserDefaults standardUserDefaults];
            NSMutableArray *namesArray = [[userdefaults objectForKey:@"ActigraphyStepFileNames"] mutableCopy];
            if (namesArray.count > 0) {
                NSString *tempString = [namesArray objectAtIndex:0];
                //////
                name = [NSString stringWithFormat: @"M372R%@01.SLP",tempString];
                
                if([[TDWatchProfile sharedInstance]watchStyle] == timexDatalinkWatchStyle_IQ){
                    name = [NSString stringWithFormat: @"M328R%@01.SLP",tempString];//@"M328A%@01.SLP";
                }
                else if ([[TDWatchProfile sharedInstance]watchStyle] == timexDatalinkWatchStyle_IQTravel)
                {
                    name = [NSString stringWithFormat: @"M329R%@01.SLP",tempString];
                }
                OTLog(@"ACTIGRAPHY STEP FILES Started Reading: %@",name);
                /////
                if(namesArray.count >0)
                    [namesArray removeObjectAtIndex:0];
                
                [userdefaults setObject:namesArray forKey:@"ActigraphyStepFileNames"];
                [userdefaults synchronize];
            }
        }
            break;
            //TestLog_SleepFiles
        case ACTION_READ_SETTINGS_FILE:
        case ACTION_WRITE_SETTINGS_FILE:
        {
            if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_Metropolitan){
                name = [NSString stringWithFormat: @"M372S%03d.SET", M372_SETTINGS_VERSION];
            }
            else if([[TDWatchProfile sharedInstance]watchStyle] == timexDatalinkWatchStyle_IQ){
                name = [NSString stringWithFormat: @"M328S003.SET"]; // Hard coded.
            }
            else if([[TDWatchProfile sharedInstance]watchStyle] == timexDatalinkWatchStyle_IQTravel){
                name = [NSString stringWithFormat: @"M329S004.SET"]; // Hard coded.
            }
            else
                name = [NSString stringWithFormat: @"M054S%03d.SET", SETTINGS_VERSION];
            
            OTLog(@"ACTION WRITE SETTINGS FILE Started Reading: %@",name);
        }
            break;
        case ACTION_WRITE_APPT_FILE:
            name = [NSString stringWithFormat: @"M054A%03d.ADB", APPOINTMENTS_VERSION ];
            break;
        case ACTION_READ_CHRONOS_FILE:
            name = [NSString stringWithFormat: @"M054W%03d.WDB", CHRONOS_VERSION ];
            break;
        case ACTION_READ_SYSBLOCK_FILE:
            name = [NSString stringWithFormat: @"SYSBLOCK.BIN"];
            break;
        case ACTION_WRITE_BOOTLOADER_FILE:
        case ACTION_WRITE_FIRMWARE_FILE:
        {
            if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_Metropolitan)
            {
                NSInteger version = ((TDM372FirmwareUpgradeInfo *)[_mFirmwareUpgradePendingFiles objectAtIndex: _mFirmwareUpgradeProcessedFileIndex]).version;
                
                
                if (((TDM372FirmwareUpgradeInfo *)[_mFirmwareUpgradePendingFiles objectAtIndex: _mFirmwareUpgradeProcessedFileIndex]).type == TDM372FirmwareUpgradeInfoType_Radio)
                    name = [NSString stringWithFormat: @"M372R%03ld.BIN", (long)version ];
                
                
                else if (((TDM372FirmwareUpgradeInfo *)[_mFirmwareUpgradePendingFiles objectAtIndex: _mFirmwareUpgradeProcessedFileIndex]).type == TDM372FirmwareUpgradeInfoType_Firmware)
                    name = [NSString stringWithFormat: @"M372F%03ld.BIN", (long)version ];
                else if (((TDM372FirmwareUpgradeInfo *)[_mFirmwareUpgradePendingFiles objectAtIndex: _mFirmwareUpgradeProcessedFileIndex]).type == TDM372FirmwareUpgradeInfoType_Activity)
                    name = [NSString stringWithFormat: @"M372A%03ld.BIN", (long)version ];
                else if (((TDM372FirmwareUpgradeInfo *)[_mFirmwareUpgradePendingFiles objectAtIndex: _mFirmwareUpgradeProcessedFileIndex]).type == TDM372FirmwareUpgradeInfoType_Codeplug)
                    name = [NSString stringWithFormat: @"M372C%03ld.BIN", (long)version ];
            }
            else if([[TDWatchProfile sharedInstance]watchStyle] == timexDatalinkWatchStyle_IQ)
            {
                NSInteger version = ((TDM372FirmwareUpgradeInfo *)[_mFirmwareUpgradePendingFiles objectAtIndex: _mFirmwareUpgradeProcessedFileIndex]).version;
                
                
                if (((TDM372FirmwareUpgradeInfo *)[_mFirmwareUpgradePendingFiles objectAtIndex: _mFirmwareUpgradeProcessedFileIndex]).type == TDM372FirmwareUpgradeInfoType_Radio)
                    name = [NSString stringWithFormat: @"M328R%03ld.BIN", (long)version ];
                
                
                else if (((TDM372FirmwareUpgradeInfo *)[_mFirmwareUpgradePendingFiles objectAtIndex: _mFirmwareUpgradeProcessedFileIndex]).type == TDM372FirmwareUpgradeInfoType_Firmware)
                    name = [NSString stringWithFormat: @"M328F%03ld.BIN", (long)version ];
                else if (((TDM372FirmwareUpgradeInfo *)[_mFirmwareUpgradePendingFiles objectAtIndex: _mFirmwareUpgradeProcessedFileIndex]).type == TDM372FirmwareUpgradeInfoType_Activity)
                    name = [NSString stringWithFormat: @"M328A%03ld.BIN", (long)version ]; // Activity bin file name is same.
                else if (((TDM372FirmwareUpgradeInfo *)[_mFirmwareUpgradePendingFiles objectAtIndex: _mFirmwareUpgradeProcessedFileIndex]).type == TDM372FirmwareUpgradeInfoType_Codeplug)
                    name = [NSString stringWithFormat: @"M328C%03ld.BIN", (long)version ];
            }
            else if([[TDWatchProfile sharedInstance]watchStyle] == timexDatalinkWatchStyle_IQTravel)
            {
                NSInteger version = ((TDM372FirmwareUpgradeInfo *)[_mFirmwareUpgradePendingFiles objectAtIndex: _mFirmwareUpgradeProcessedFileIndex]).version;
                
                
                if (((TDM372FirmwareUpgradeInfo *)[_mFirmwareUpgradePendingFiles objectAtIndex: _mFirmwareUpgradeProcessedFileIndex]).type == TDM372FirmwareUpgradeInfoType_Radio)
                    name = [NSString stringWithFormat: @"M329R%03ld.BIN", (long)version ];
                
                
                else if (((TDM372FirmwareUpgradeInfo *)[_mFirmwareUpgradePendingFiles objectAtIndex: _mFirmwareUpgradeProcessedFileIndex]).type == TDM372FirmwareUpgradeInfoType_Firmware)
                    name = [NSString stringWithFormat: @"M329F%03ld.BIN", (long)version ];
                else if (((TDM372FirmwareUpgradeInfo *)[_mFirmwareUpgradePendingFiles objectAtIndex: _mFirmwareUpgradeProcessedFileIndex]).type == TDM372FirmwareUpgradeInfoType_Activity)
                    name = [NSString stringWithFormat: @"M329A%03ld.BIN", (long)version ]; // Activity bin file name is same.
                else if (((TDM372FirmwareUpgradeInfo *)[_mFirmwareUpgradePendingFiles objectAtIndex: _mFirmwareUpgradeProcessedFileIndex]).type == TDM372FirmwareUpgradeInfoType_Codeplug)
                    name = [NSString stringWithFormat: @"M329C%03ld.BIN", (long)version ];
            }
            else
            {
                NSInteger version = ((TDDatacastFirmwareUpgradeInfo *)[_mFirmwareUpgradePendingFiles objectAtIndex: _mFirmwareUpgradeProcessedFileIndex]).version;
                name = [NSString stringWithFormat: @"M054F%03ld.BIN", (long)version ];
            }
        }
            break;
        case ACTION_WRITE_LANGUAGE_FILE:
        {
            NSInteger version = ((TDDatacastFirmwareUpgradeInfo *)[_mFirmwareUpgradePendingFiles objectAtIndex: _mFirmwareUpgradeProcessedFileIndex]).version;
            name = [NSString stringWithFormat: @"M054L%@%02ld.BIN", @"A", (long)version ];
        }
            break;
        case ACTION_WRITE_CODEPLUG_FILE:
        {
            NSInteger version = ((TDDatacastFirmwareUpgradeInfo *)[_mFirmwareUpgradePendingFiles objectAtIndex: _mFirmwareUpgradeProcessedFileIndex]).version;
            name = [NSString stringWithFormat: @"M054C%03ld.BIN", (long)version ];
        }
            break;
    }
    OTLog([NSString stringWithFormat:@"getFileName PeripheralDevice.m %@",name]);
    
    return name;
 }
- (void) openFile: (int) inAction
{
    
    #if DEBUG
    OTLog([NSString stringWithFormat:@"Opening file with action %d",inAction]); //
 //
    #endif

    switch( inAction )
    {
        case ACTION_READ_M053_FULL_FILE:
        case ACTION_READ_SETTINGS_FILE:
        case ACTION_READ_CHRONOS_FILE:
        case ACTION_READ_SYSBLOCK_FILE:
        case ACTION_READ_M372_ACTIVITY_DATA:
        case ACTION_READ_M372_SLEEP_SUMMARY://TestLog_SleepFiles
        case ACTION_READ_M372_SLEEP_KEY_FILE://TestLog_SleepFiles
        case ACTION_READ_M372_ACTIGRAPHY_FILES://TestLog_SleepFiles
        case ACTION_READ_M372_HOUR_DATA:
            [self openRead: [self getFileName : inAction]];
            break;
        case ACTION_WRITE_M053_TIME:
        case ACTION_WRITE_M053_APPTS_FILE:
        case ACTION_WRITE_M053_FULL_FILE:
        case ACTION_WRITE_SETTINGS_FILE:
        case ACTION_RESUME_FIRMWARE:
            [self openWrite: [self getFileName : inAction]];
            break;
        case ACTION_WRITE_APPT_FILE:
        case ACTION_WRITE_FIRMWARE_FILE:
        case ACTION_WRITE_LANGUAGE_FILE:
        case ACTION_WRITE_CODEPLUG_FILE:
        case ACTION_WRITE_BOOTLOADER_FILE:
            [self openCreate: [self getFileName : inAction]];
            break;
    }
}

- (BOOL) readFile: (Byte) inFileHandle withFileSize: (int) fileSize
{
    OTLog(@"readFile PeripheralDevice.m");

    BOOL started = false;
    
    [self generateTransmitPacketsForRead: inFileHandle withFileSize: fileSize ];
        
    [self transmitPacket];

    return started;
}
                 
 - (void) writeFile: (Byte) inFileHandle
{
    OTLog(@"Write file getting called"); //
    [self generateTransmitPacketsForWrite: inFileHandle];
    
    [self transmitPacket];
}

- (void) restartFirmwareFile: (Byte) inFileHandle
{
    OTLog(@"restartFirmwareFile PeripheralDevice.m");

    NSString * path = ((TDDatacastFirmwareUpgradeInfo *)[_mFirmwareUpgradePendingFiles objectAtIndex: _mFirmwareUpgradeProcessedFileIndex]).pathToDownloadedFile;
    NSData * fullFile = [NSData dataWithContentsOfFile: path];
    NSInteger size = fullFile.length;
    NSInteger newSize = size - _mFileSize;
    _mFileBytes = [fullFile subdataWithRange: NSMakeRange(_mFileSize, newSize)];
    
    [self generateTransmitPacketsForWrite: inFileHandle];
    
    //at this point, we can continue just like normal firmware upgrade... so, replace _mAction value
    //do it ONLY after call to generateTransmitPacketsForWrite(); otherwise the total packet count will be reset there and we don't want that for the restart firmware file
    TDDatacastFirmwareUpgradeInfo * downloadInfo = [_mFirmwareUpgradePendingFiles objectAtIndex: _mFirmwareUpgradeProcessedFileIndex];
    switch (downloadInfo.type)
    {
        case TDDatacastFirmwareUpgradeInfoType_Firmware:
            _mAction = ACTION_WRITE_FIRMWARE_FILE;
            break;
        case TDDatacastFirmwareUpgradeInfoType_Codeplug:
            _mAction = ACTION_WRITE_CODEPLUG_FILE;
            break;
        case TDDatacastFirmwareUpgradeInfoType_Language:
            _mAction = ACTION_WRITE_LANGUAGE_FILE;
            break;
    }
    
    
    [self transmitPacket];
    
    [[NSNotificationCenter defaultCenter] postNotificationName: kTDFirmwareUpdateResumed object: self];
}

- (void) deleteFile: (NSString *) inFilename
{
    OTLog(@"PeripheralDevice deleteFile");
    PCCPacket * deleteFilePacket = [[PCCPacket alloc] init: ExtenderCmdDelete accessType: FILE_ACCESS_CREATE extenderFile: inFilename];
    if ( nil != deleteFilePacket )
    {
        [self writePCCommPacket: deleteFilePacket];
    }
}
- (void) doSeekFile: (int) inSeek
{
    OTLog(@"PeripheralDevice doSeekFile");
    PCCPacket * newPacket = [[PCCPacket alloc] init: ExtenderCmdSeek fileHandle: _mFileHandle filePointer: inSeek];
    if ( nil != newPacket )
    {
        [self writePCCommPacket: newPacket];
    }
}

- (void) openCreate: (NSString *) inFilename
{
    OTLog(@"PeripheralDevice openCreate");
    PCCPacket * openFilePacket = [[PCCPacket alloc] init: ExtenderCmdOpen accessType: FILE_ACCESS_CREATE extenderFile: inFilename];
    if ( nil != openFilePacket )
    {
         [self writePCCommPacket: openFilePacket];
     }
 }
- (void) openRead: (NSString *) inFilename
{
    OTLog(@"PeripheralDevice openRead");
     PCCPacket * openFilePacket = [[PCCPacket alloc] init: ExtenderCmdOpen accessType: FILE_ACCESS_READ_ONLY extenderFile: inFilename];
     if ( nil != openFilePacket )
     {
         [self writePCCommPacket: openFilePacket];
     }
 }
- (void) openWrite: (NSString *) inFilename
{
    OTLog(@"PeripheralDevice openWrite");
    PCCPacket * openFilePacket = [[PCCPacket alloc] init: ExtenderCmdOpen accessType: FILE_ACCESS_READ_WRITE extenderFile: inFilename];
    if ( nil != openFilePacket )
    {
        [self writePCCommPacket: openFilePacket];
    }
 }
- (void) getFileSize
{
    OTLog(@"PeripheralDevice getFileSize");
    PCCPacket * newPacket = [[PCCPacket alloc] init: ExtenderCmdFileSize fileHandle: _mFileHandle filePointer: 0];
    if ( nil != newPacket )
    {
        [self writePCCommPacket: newPacket];
    }
}

- (NSData *) assembleFile
{
    OTLog(@"PeripheralDevice assembleFile");
    NSData * returnData = nil;
    int offset = 0, dataLen;
    if ( nil != _mReceivePackets )
    {
        if ( [_mReceivePackets count] > 0 )
        {
            //determine the total size
            PCCPacket * last = [_mReceivePackets lastObject];
            PCCHeader * lastHeader = [[last getResponsePacket] getHeader];
            int lastHeaderPacketLength = lastHeader.PacketLength;
            NSInteger dataSize = (([_mReceivePackets count] - 1) * PCC_PACKET_PAYLOAD_SIZE_MAX) + (lastHeaderPacketLength - 2);
            Byte file[dataSize];
            
            for ( PCCPacket * p in _mReceivePackets )
            {
                NSData * payload = [[p getResponsePacket] getPayload];
                Byte payloadBuff[payload.length];
                [payload getBytes: payloadBuff];
                
                dataLen = [[p getResponsePacket] getHeader].PacketLength - 2;
                if ( offset < dataSize  && offset + dataLen <= dataSize && dataLen <= payload.length )
                {
                    memcpy(&file[offset], &payloadBuff[2], dataLen);
                }
                offset += dataLen;
            }
            
            [_mReceivePackets removeAllObjects];
            _mReceivePackets = nil;
            
            returnData = [NSData dataWithBytes: file length: dataSize];
        }
    }
    return returnData;
}

- (void) _end
{
    OTLog(@"PeripheralDevice _end");
    switch( _mAction )
    {
        case ACTION_READ_SETTINGS_FILE:
        case ACTION_WRITE_SETTINGS_FILE:
            [self endSettings];
            break;
        case ACTION_READ_M372_ACTIVITY_DATA:
            [self endActivity];
            break;
        case ACTION_READ_M372_SLEEP_SUMMARY://TestLog_SleepFiles
            [self endSleepSummary];
            break;
        case ACTION_READ_M372_SLEEP_KEY_FILE://TestLog_SleepFiles
            [self endSleepSummaryKeyFile];
            break;
        case ACTION_READ_M372_ACTIGRAPHY_FILES://TestLog_SleepFiles
            [self endSleepSummaryActigraphyFile];
            break;
        case ACTION_READ_M372_HOUR_DATA:
            [self endActigraphyStepFile];
            break;
        case ACTION_READ_CHRONOS_FILE:
            [self endWorkout];
            break;
        case ACTION_WRITE_M053_TIME:
        case ACTION_WRITE_M053_APPTS_FILE:
        case ACTION_WRITE_M053_FULL_FILE:
        case ACTION_READ_M053_FULL_FILE:
        {
            BOOL endSession = TRUE;
            //check... is there anything else M053-related down the pipe? if yes... then don't close the session
            if ([_mPendingActions count] > 1)
            {
                NSNumber * currentAction = [_mPendingActions objectAtIndex: 1];
                if ([currentAction integerValue] == ACTION_WRITE_M053_FULL_FILE ||
                    [currentAction integerValue] == ACTION_WRITE_M053_APPTS_FILE ||
                    [currentAction integerValue] == ACTION_READ_M053_FULL_FILE ||
                    [currentAction integerValue] == ACTION_WRITE_M053_TIME)
                {
                    endSession = FALSE;
                }
            }
            
            if (endSession)
            {
                //there is nothing... end the session
                [self endFileAccessSession];
            }
            else
            {
                //continue the existing session and do the next action that is awayting in the array
                [self doTimexBluetoothSmart: [self nextSubAction: SUBACTION_END]];
            }
        }
            break;
        case ACTION_WRITE_APPT_FILE:
            [self doTimexBluetoothSmart: SUBACTION_DONE];
            break;
        case ACTION_WRITE_FIRMWARE_FILE:
        case ACTION_WRITE_CODEPLUG_FILE:
        case ACTION_WRITE_LANGUAGE_FILE:
            if (_mFirmwareUpgradeCancelled == FALSE && _mFirmwareUpgradePaused == FALSE)
            {
                [self endFirmware];
                OTLog(@"Firmware files written successfully to watch");
                
                _mFirmwareTotalPacketsCount = 0;
            }
            else if (_mFirmwareUpgradeCancelled == TRUE)
            {
                //NOW we can reset it....
                _mFirmwareUpgradeCancelled = FALSE;
                
                [self cancelFirmware];
                OTLog(@"Firmware update was cancelled");
                
                _mFirmwareTotalPacketsCount = 0;
                [[NSNotificationCenter defaultCenter] postNotificationName: kTDFirmwareUpdateCancelledNotification object: self];
            }
            else if (_mFirmwareUpgradePaused == TRUE)
            {
                //NOW we can reset it....
                _mFirmwareUpgradePaused = FALSE;
                
                [self pauseFirmware];
                OTLog(@"Firmware update was paused");
            }
            break;
    }
}
- (void) closeFile
{
    OTLog(@"PeripheralDevice closeFile");
    PCCPacket * closeFilePacket = [[PCCPacket alloc] init: ExtenderCmdClose  fileHandle: _mFileHandle filePointer: 0];
    if ( nil != closeFilePacket )
    {
        [self writePCCommPacket: closeFilePacket];
    }
}
- (void) finish: (int) inStatus
{
    OTLog(@"PeripheralDevice finish");
}

- (void) generateTransmitPacketsForWrite: (Byte) inFileHandle
{
    OTLog(@"PeripheralDevice generateTransmitPacketsForWrite");
    _mTransmitPackets = [[NSMutableArray alloc] init];
    int offset = 0;
    NSInteger chunkLength = PCC_PACKET_PAYLOAD_SIZE_MAX;
    

    NSInteger bufferLength = _mFileBytes.length;
    OTLog(@"Creating internal buffer of length %ld", (long)bufferLength);
    Byte inData[bufferLength];
    [_mFileBytes getBytes: inData];
    
    // organize the data into packets
    while ( offset < _mFileBytes.length )
    {
        if ( _mFileBytes.length - offset < chunkLength )
        {
            chunkLength = _mFileBytes.length - offset;
        }
        Byte chunk[ chunkLength ];
        memcpy(chunk, &inData[offset], chunkLength);
        offset += chunkLength;
        
        NSData * chunkData = [NSData dataWithBytes: chunk length: chunkLength];
        
        PCCPacket * writePacket = [[PCCPacket alloc] init: ExtenderCmdWrite fileHandle: inFileHandle rawData: chunkData];
        
        [_mTransmitPackets addObject: writePacket];
    }
    
    switch (_mAction)
    {
        case ACTION_WRITE_CODEPLUG_FILE:
        case ACTION_WRITE_FIRMWARE_FILE:
        case ACTION_WRITE_LANGUAGE_FILE:
            _mFirmwareTotalPacketsCount = [_mTransmitPackets count];
            if (_progressDialog != nil)
            {
                [_progressDialog allowFirmwareUploadCancellation];
            }
            break;
        case ACTION_WRITE_BOOTLOADER_FILE:
            _mFirmwareTotalPacketsCount = [_mTransmitPackets count]; 
            break;
        default:
            break;
    }
}

- (void) generateTransmitPacketsForRead: (Byte) inFileHandle withFileSize: (int) fileSize
{
    OTLog(@"PeripheralDevice generateTransmitPacketsForRead");
    _mTransmitPackets = [[NSMutableArray alloc] init];
    int offset = 0;
    int chunkLength = PCC_PACKET_PAYLOAD_SIZE_MAX;
    
    while ( offset < fileSize )
    {
        if ( fileSize - offset < chunkLength )
        {
            chunkLength = fileSize - offset;
        }
        
        PCCPacket * newPacket = [[PCCPacket alloc] init: ExtenderCmdRead fileHandle: inFileHandle readCount: chunkLength];
        
        [_mTransmitPackets addObject: newPacket];
        offset += chunkLength;
    }
}

- (BOOL) transmitPacket
{
    OTLog(@"PeripheralDevice transmitPacket");
    BOOL transmit = false;
    if ( nil != _mTransmitPackets && [_mTransmitPackets count] > 0 )
    {
        switch (_mAction)
        {
            case ACTION_WRITE_FIRMWARE_FILE:
            case ACTION_WRITE_CODEPLUG_FILE:
            case ACTION_WRITE_LANGUAGE_FILE:
            case ACTION_WRITE_BOOTLOADER_FILE:
            {
                if (_progressDialog != nil)
                {
                    float progressPercentage = 0;
                    progressPercentage = 1.00 - ((float)[_mTransmitPackets count] / (float)_mFirmwareTotalPacketsCount);
                    float currentProgress = _progressDialog.progress;
                    if (progressPercentage - currentProgress >= 0.001 || currentProgress == MAXFLOAT)
                    {
                        _progressDialog.progress = progressPercentage;
                        
                        float percentageComplete = progressPercentage * 100.0;
                        NSString * currentText = _progressDialog.progressText;
                        NSArray * currentTextSubstrings = [currentText componentsSeparatedByCharactersInSet: [NSCharacterSet characterSetWithCharactersInString:@"\n"]];
                        _progressDialog.progressText = [NSString stringWithFormat: @"%@\n%0.1f%% %@", [currentTextSubstrings objectAtIndex: 0], percentageComplete, NSLocalizedString(@"complete", nil)];
                    }
                }
                if (_progressFirmware != nil)
                {
                    float progressPercentage = 0;
                    progressPercentage = 1.00 - ((float)[_mTransmitPackets count] / (float)_mFirmwareTotalPacketsCount);
                    float currentProgress = _progressFirmware.progress;
                    if (progressPercentage - currentProgress >= 0.001 || currentProgress == MAXFLOAT)
                    {
                        _progressFirmware.progress = progressPercentage;
                        float percentageComplete = progressPercentage * 100.0;
                        
                        _progressFirmware.lblAverageString = [NSString stringWithFormat: @"%0.1f%%",percentageComplete];
                    }
                    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_Metropolitan) {
                        int filesLeft = 0;
                        filesLeft = _firmwareUpgradePendingFilesCount;
                        filesLeft = ((int)_mFirmwareUpgradePendingFiles.count - filesLeft);
                        _progressFirmware.lblFileString = [NSString stringWithFormat:NSLocalizedString(@"File %d of %d",nil),filesLeft,(int)_mFirmwareUpgradePendingFiles.count]; // To fix artf26857
                    }
                }
                if ([[TDWatchProfile sharedInstance]watchStyle] == timexDatalinkWatchStyle_IQ || [[TDWatchProfile sharedInstance]watchStyle] == timexDatalinkWatchStyle_IQTravel)
                {
                    float progressPercentage = 0;
                    progressPercentage = 1.00 - ((float)[_mTransmitPackets count] / (float)_mFirmwareTotalPacketsCount);
                    float currentProgress = _progressFirmware.progress;
                    if (progressPercentage - currentProgress >= 0.001 || currentProgress == MAXFLOAT)
                    {
                        _firmwareProgress = progressPercentage;
                        float percentageComplete = progressPercentage * 100.0;
                        
                        _progressFirmware.lblAverageString = [NSString stringWithFormat: @"%0.1f%%",percentageComplete];
                    }
                }
            }
                break;
            default:
                break;
        }
        PCCPacket * newPacket = [_mTransmitPackets objectAtIndex: 0];
        [self writePCCommPacket: newPacket];
        
        transmit = true;
    }
    else
    {
        _mTransmitPackets = nil;
    }
    
    return transmit;
}

- (void) writePCCommPacket: (PCCPacket *) inPacket
{
    OTLog(@"PeripheralDevice writePCCommPacket");
    if ( nil != inPacket)
    {
        OTLog(@"Test5");
        if (inPacket.mCommand.value != ExtenderCmdEnterBootloaderMode && inPacket.mCommand.value != ExtenderCmdFactoryReset && inPacket.mCommand.value != ExtenderCmdWatchReset && inPacket.mCommand.value != 0xFF) //bootloader/reset commands do not return an ACK or NACK....
        {
            OTLog(@"Test6");
            //create a time to fire within 15 seconds.... we should receive a response within 15 seconds; if we don't that means something is wrong so no point waiting for it any longer
            // NARESH- Changed it to 30 seconds
            [_mBLEREsponseTimer invalidate];
            _mBLEREsponseTimer = [NSTimer scheduledTimerWithTimeInterval: 30.0 target:self selector:@selector(_didNotReceiveBLEResponse) userInfo:nil repeats:NO];
        }
        
        [self _sendPacketData: [inPacket getRawData]];
    }
}
- (void) _didNotReceiveBLEResponse
{
    OTLog(@"PeripheralDevice _didNotReceiveBLEResponse");
    [[NSNotificationCenter defaultCenter]postNotificationName:kTDM328DidNotRecieveBLEResponse object:nil];
    OTLog(@"_didNotReceiveBLEResponse");
    [_mBLEREsponseTimer invalidate];
    _mBLEREsponseTimer = nil;
    
    [self _flurryResponseError: Unrecognized];
    [self handleError: SUBACTION_WHOS_THERE withStatus: _mStatus];
}
- (void) _sendPacketData: (NSData *) rawData
{
    OTLog(@"PeripheralDevice _sendPacketData");
    ServiceProxy* service = [_peripheral findService: [PeripheralDevice timexDatalinkServiceId]];
    if (service)
    {
#if DEBUG
        OTLog(@"Timex Connected Data sent:");
//        [iDevicesUtil dumpData: rawData];
#endif
        
        Byte dataPassedIn[[rawData length]];
        [rawData getBytes: dataPassedIn];
        NSInteger dataSize = [rawData length];
        
        NSInteger characteristicsPerData = (dataSize / BTS_CHARACTERISTIC_SIZE);
        int remainder = dataSize % BTS_CHARACTERISTIC_SIZE;
        if (remainder)
            characteristicsPerData += 1;
        
        NSInteger offset =  0;
        if (dataSize > BTS_CHARACTERISTIC_SIZE && remainder == 0)
            offset = dataSize - BTS_CHARACTERISTIC_SIZE;
        else if (dataSize > BTS_CHARACTERISTIC_SIZE && remainder > 0)
            offset = dataSize - remainder;
        
        int dataLengthBuff = BTS_CHARACTERISTIC_SIZE;
        if (remainder > 0)
            dataLengthBuff = remainder;
        
        Byte buffer[dataLengthBuff];
        memcpy(buffer, &dataPassedIn[offset], dataLengthBuff);
        NSData * newBuffData = [NSData dataWithBytes: buffer length: dataLengthBuff];
            
        CBUUID * charIDToUse = nil;
        
        if (characteristicsPerData == 4)
            charIDToUse = [PeripheralDevice timexDatalinkDataIn4Id];
        else if (characteristicsPerData == 3)
            charIDToUse = [PeripheralDevice timexDatalinkDataIn3Id];
        else if (characteristicsPerData == 2)
            charIDToUse = [PeripheralDevice timexDatalinkDataIn2Id];
        else if (characteristicsPerData == 1)
            charIDToUse = [PeripheralDevice timexDatalinkDataIn1Id];
        
        CharacteristicProxy* timexChar = [service findCharacteristic: charIDToUse];

        if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_M054)
        {
            [timexChar writeValue: newBuffData]; // Not waiting for response block. will be looked into

            NSInteger remainingData = dataSize - dataLengthBuff;
            if (remainingData > 0)
            {
                Byte buffer[remainingData];
                Byte dataPassedIn[[rawData length]];
                [rawData getBytes: dataPassedIn];
                memcpy(buffer, &dataPassedIn, remainingData);
                
                NSData * remainingDataToSend = [NSData dataWithBytes: buffer length: remainingData];
                
                [self _sendPacketData: remainingDataToSend];
            }
        }
        else if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_ActivityTracker)
         {
             __weak PeripheralDevice* weakSelf = self;
             [timexChar writeValue: newBuffData responseBlock:^(CharacteristicProxy *characteristic)
              {
                  PeripheralDevice* strongSelf = weakSelf;
                  if ( strongSelf )
                  {
                      NSInteger remainingData = dataSize - dataLengthBuff;
                      if (remainingData > 0)
                      {
                          Byte buffer[remainingData];
                          Byte dataPassedIn[[rawData length]];
                          [rawData getBytes: dataPassedIn];
                          memcpy(buffer, &dataPassedIn, remainingData);
                          
                          NSData * remainingDataToSend = [NSData dataWithBytes: buffer length: remainingData];
                          
                          [self _sendPacketData: remainingDataToSend];
                      }
                  }
              }];
         }
        else if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_Metropolitan || [[TDWatchProfile sharedInstance] watchStyle] ==  timexDatalinkWatchStyle_IQ || [[TDWatchProfile sharedInstance]watchStyle] == timexDatalinkWatchStyle_IQTravel)
        {
            [timexChar writeValue: newBuffData];
            
            NSInteger remainingData = dataSize - dataLengthBuff;
            if (remainingData > 0)
            {
                Byte buffer[remainingData];
                Byte dataPassedIn[[rawData length]];
                [rawData getBytes: dataPassedIn];
                memcpy(buffer, &dataPassedIn, remainingData);
                
                NSData * remainingDataToSend = [NSData dataWithBytes: buffer length: remainingData];
                
                [self _sendPacketData: remainingDataToSend];
                OTLog(@"Test8");
            }
        }
    }
}

- (void) processReceivedFileData
{
    OTLog(@"processReceivedFileData");

    switch( _mAction )
    {
        case ACTION_READ_M053_FULL_FILE:
        {
            TDM053WatchData * watchData = [[TDM053WatchData alloc] init: _mFileBytes];
            _mFileBytes = nil;
            
            if (watchData)
            {
                OTLog(@"Timex M053 Full File read successfully");
                
                [[NSNotificationCenter defaultCenter] postNotificationName: kTDM053ReadSuccessfullyNotification object: self userInfo: [NSDictionary dictionaryWithObject: watchData forKey: kM053DataFileKey]];
            }
        }
            break;
        case ACTION_READ_M372_ACTIVITY_DATA:
        {
            TDM372WatchActivity * newActivities = [[TDM372WatchActivity alloc] init: _mFileBytes];
            _mFileBytes = nil;
                
            if (newActivities)
            {
//                OTLog(@"Timex M372 Activity Data read successfully");
                [[NSNotificationCenter defaultCenter] postNotificationName: kTDM372ActivitiesReadSuccessfullyNotification object: self userInfo: [NSDictionary dictionaryWithObject: newActivities forKey: kM372ActivitiesDataFileKey]];
            }
        }
            break;
            
        //TestLog_SleepFiles
        case ACTION_READ_M372_SLEEP_SUMMARY:
        {
            TDM372SleepSummaryFile *newActivity =[[TDM372SleepSummaryFile alloc]init:_mFileBytes];
            _mFileBytes = nil;
            
            if (newActivity)
            {
                OTLog(@"Timex M372 Sleep summary Data read successfully");
               [[NSNotificationCenter defaultCenter] postNotificationName: kTDM372SleepSummarySuccessfullyNotification object: self userInfo: [NSDictionary dictionaryWithObject: newActivity forKey: kM372SleepSummaryFileKey]];
            }
        
        }
            break;
            
        case ACTION_READ_M372_ACTIGRAPHY_FILES:
        {
            TDM372ActigraphyDataFile *newActivity = [[TDM372ActigraphyDataFile alloc]init:_mFileBytes];
            _mFileBytes = nil;
            
            if (newActivity)
            {
                OTLog(@"Timex M372 SleepActigraphyData Data read successfully");
                [[NSNotificationCenter defaultCenter] postNotificationName: kTDM372SleepActigraphyDataSuccessfullyNotification object: self userInfo: [NSDictionary dictionaryWithObject: newActivity forKey: kM372ActigraphyDataFile]];
            }
        }
            break;
        case ACTION_READ_M372_HOUR_DATA:
        {
            TDM372ActigraphyStepFile *newActivity = [[TDM372ActigraphyStepFile alloc]init:_mFileBytes];
            _mFileBytes = nil;
            
            if (newActivity)
            {
                OTLog(@"Timex M372 ActigraphyStep file Data read successfully");
                [[NSNotificationCenter defaultCenter] postNotificationName: kTDM372ActigraphyStepFileDataSuccessfullyNotification object: self userInfo: [NSDictionary dictionaryWithObject: newActivity forKey: kM372ActigraphyStepFile]];
            }
        }
            break;
        case ACTION_READ_M372_SLEEP_KEY_FILE:
        {
            TDM372ActigraphyKeyFile *newActivity =[[TDM372ActigraphyKeyFile alloc]init:_mFileBytes];
            _mFileBytes = nil;
            
            if (newActivity)
            {
                OTLog(@"Timex M372 Sleep Key File read successfully");
                [[NSNotificationCenter defaultCenter] postNotificationName: kTDM372SleepKeyFileReadSuccessfullyNotification object: self userInfo: [NSDictionary dictionaryWithObject: newActivity forKey: kM372SleepKeyFile]];
            }
        }
            break;
        //TestLog_SleepFiles
        case ACTION_READ_SETTINGS_FILE:
        {
            if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_Metropolitan)
            {
                TDM372WatchSettings * newSettings = [[TDM372WatchSettings alloc] init: _mFileBytes];
                _mFileBytes = nil;
                
                if (newSettings)
                {
                    OTLog(@"Timex M372 Settings read successfully");
                    [[NSNotificationCenter defaultCenter] postNotificationName: kTDM372SettingsReadSuccessfullyNotification object: self userInfo: [NSDictionary dictionaryWithObject: newSettings forKey: kM372SettingsDataFileKey]];
                }
            }
            else if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQ){
                OTLog([NSString stringWithFormat:@"_mFileBytes %@",_mFileBytes]);

                TDM328WatchSettings * newSettings = [[TDM328WatchSettings alloc] init: _mFileBytes];
                _mFileBytes = nil;
                
                if (newSettings)
                {
                    OTLog(@"Timex M328 Settings read successfully");
                    //TODO .. Have to write our own notification stuff.
                [[NSNotificationCenter defaultCenter] postNotificationName: kTDM328SettingsReadSuccessfullyNotification object: self userInfo: [NSDictionary dictionaryWithObject: newSettings forKey: kM328SettingsDataFileKey]];
                }
                
            }
            else if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel){
                OTLog([NSString stringWithFormat:@"_mFileBytes %@",_mFileBytes]);
                
                TDM329WatchSettings * newSettings = [[TDM329WatchSettings alloc] init: _mFileBytes];
                _mFileBytes = nil;
                
                if (newSettings)
                {
                    OTLog(@"Timex M329 Settings read successfully");
                    //TODO .. Have to write our own notification stuff.
                    [[NSNotificationCenter defaultCenter] postNotificationName: kTDM328SettingsReadSuccessfullyNotification object: self userInfo: [NSDictionary dictionaryWithObject: newSettings forKey: kM328SettingsDataFileKey]];
                }
                
            }
            else
            {
                TDDatacastWatchSettings * newSettings = [[TDDatacastWatchSettings alloc] init: _mFileBytes];
                _mFileBytes = nil;
                
                if (newSettings)
                {
                    OTLog(@"Timex Settings read successfully");
                    [[NSNotificationCenter defaultCenter] postNotificationName: kTDSettingsReadSuccessfullyNotification object: self userInfo: [NSDictionary dictionaryWithObject: newSettings forKey: kDeviceSettingsKey]];
                }
            }
        }
            break;
        case ACTION_READ_CHRONOS_FILE:
        {
            TDDatacastWorkoutsParser * newWorkoutsParser = [[TDDatacastWorkoutsParser alloc] init: _mFileBytes];
            if (newWorkoutsParser)
            {
                OTLog(@"Timex Workouts read successfully");
                NSArray * newWorkouts = [newWorkoutsParser serializeToDB];
                if (newWorkouts != nil)
                {
                    //autoupload them!
//                    [[TDWorkoutUploadsManager sharedManager] AutoUpload: newWorkouts];
                }
            }
            
            [[NSNotificationCenter defaultCenter] postNotificationName: kTDWorkoutsReadSuccessfullyNotification object: self];
        }
            break;
        case ACTION_READ_SYSBLOCK_FILE:
        {
            OTLog([NSString stringWithFormat:@"_mFileBytes %@",_mFileBytes]);
            
            SYSBLOCKSettings * newSettings = [[SYSBLOCKSettings alloc] init: _mFileBytes];
            _mFileBytes = nil;
            
            if (newSettings)
            {
                OTLog(@"SYSBLOCK read successfully");
                //TODO .. Have to write our own notification stuff.
                [[NSNotificationCenter defaultCenter] postNotificationName: kTDSYSBLOCKReadSuccessfullyNotification object: self userInfo: [NSDictionary dictionaryWithObject: newSettings forKey: kSYSBLOCKDataFileKey]];
            }
            
            [[NSNotificationCenter defaultCenter] postNotificationName: kTDSYSBLOCKReadSuccessfullyNotification object: self];
        }
            break;
        case ACTION_WRITE_M053_FULL_FILE:
            OTLog(@"Timex M053 Full File written successfully to watch");
            [[NSNotificationCenter defaultCenter] postNotificationName: kTDSettingsWrittenSuccessfullyNotification object: self]; //reuse this
            break;
        case ACTION_WRITE_SETTINGS_FILE:
            OTLog(@"Timex Settings written successfully to watch");
            [[NSNotificationCenter defaultCenter] postNotificationName: kTDSettingsWrittenSuccessfullyNotification object: self];
            break;
        case ACTION_WRITE_M053_APPTS_FILE:
        case ACTION_WRITE_APPT_FILE:
            OTLog(@"Timex Appts written successfully to watch");
            [[NSNotificationCenter defaultCenter] postNotificationName: kTDApptsWrittenSuccessfullyNotification object: self];
            break;
        case ACTION_WRITE_M053_TIME:
        {
            OTLog(@"Current Time written successfully to Timex Watch!");
             [[NSNotificationCenter defaultCenter] postNotificationName: kTDPhoneTimeWrittenSuccessfullyNotification object: self];
        }
            break;
        case ACTION_WRITE_BOOTLOADER_FILE:
            if (_mFirmwareUpgradeCancelled == FALSE && _mFirmwareUpgradePaused == FALSE)
            {
                OTLog(@"Bootloader file(s) written successfully to watch");
                
                _mFirmwareTotalPacketsCount = 0;
                [[NSNotificationCenter defaultCenter] postNotificationName: kTDBootloaderFirmwareWrittenSuccessfullyNotification object: self];
            }
            else if (_mFirmwareUpgradeCancelled == TRUE)
            {
                //NOW we can reset it....
                _mFirmwareUpgradeCancelled = FALSE;
                OTLog(@"Bootloader update was cancelled");
                
                _mFirmwareTotalPacketsCount = 0;
                [[NSNotificationCenter defaultCenter] postNotificationName: kTDFirmwareUpdateCancelledNotification object: self];
            }
            break;
        default:
            break;
    }
}

- (void) handleError: (int) inSubCommand withStatus: (int) inStatus
{
    switch( inSubCommand )
    {
        case SUBACTION_DELETE_FILE:
        {
            switch( _mAction )
            {
                case ACTION_READ_CHRONOS_FILE:
                {
                    OTLog(@"Timex Workouts read successfully but Workouts File was not deleted: Error %d", inStatus);
                    [self processReceivedFileData];
                }
                    break;
            }
        }
            break;
        case SUBACTION_CANCEL_FILE_IO:
        {
            switch( _mAction )
            {
                case ACTION_WRITE_FIRMWARE_FILE:
                case ACTION_WRITE_LANGUAGE_FILE:
                case ACTION_WRITE_CODEPLUG_FILE:
                case ACTION_WRITE_BOOTLOADER_FILE:
                {
                    _mFirmwareUpgradePendingFiles = nil;
                    _mFirmwareUpgradeProcessedFileIndex = NSIntegerMax;

                    NSLog(@"Firmware Upgrade cancelled but there was an error during cancelation: Error %d", inStatus);
                    
                    _mFirmwareTotalPacketsCount = 0;
                    [[NSNotificationCenter defaultCenter] postNotificationName: kTDFirmwareUpdateCancelledNotification object: self];
                }
                    break;
            }
        }
            break;
        case SUBACTION_WHOS_THERE:
        case SUBACTION_GET_CHARGE_INFO:
        case SUBACTION_GET_EXTENDED_FIRMWARE_VERSION_INFO:
        case SUBACTION_CLOSE_FILE:
        case SUBACTION_START:
        case SUBACTION_END:
            {
                //May fix error 5s on the watch
                if (inStatus == 5) {
                    [self softResetM372Watch];
                }
                switch( _mAction )
                {
                    case ACTION_READ_SETTINGS_FILE:
                    {
                        OTLog(@"Error reading Timex Settings File!");
                        if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_Metropolitan)
                            [[NSNotificationCenter defaultCenter] postNotificationName: kTDM372SettingsReadUnsuccessfullyNotification object: self];
                        else
                            [[NSNotificationCenter defaultCenter] postNotificationName: kTDSettingsReadUnsuccessfullyNotification object: self];
                    }
                        break;
                    case ACTION_READ_M372_ACTIVITY_DATA:
                    {
                        OTLog(@"Error writing Timex M372 Activity File!");
                        [[NSNotificationCenter defaultCenter] postNotificationName: kTDM372ActivitiesReadUnsuccessfullyNotification object: self];
                    }
                        break;
                    case ACTION_WRITE_M053_FULL_FILE:
                    {
                        OTLog(@"Error writing Timex M053 Full File!");
                        [[NSNotificationCenter defaultCenter] postNotificationName: kTDSettingsWrittenUnsuccessfullyNotification object: self];
                    }
                        break;
                    case ACTION_WRITE_SETTINGS_FILE:
                    {
                        OTLog(@"Error writing Timex Settings File!");
                        [[NSNotificationCenter defaultCenter] postNotificationName: kTDSettingsWrittenUnsuccessfullyNotification object: self];
                    }
                        break;
                    case ACTION_WRITE_M053_TIME:
                    {
                        OTLog(@"Error writing Current Time to Timex Watch!");
                        [[NSNotificationCenter defaultCenter] postNotificationName: kTDPhoneTimeWrittenUnsuccessfullyNotification object: self];
                    }
                        break;
                    case ACTION_WRITE_M053_APPTS_FILE:
                    case ACTION_WRITE_APPT_FILE:
                    {
                        OTLog(@"Error writing Timex Appts File!");
                        //reset the checksum... writing of appts did not complete
                        _mLastSyncApptsChecksum = 0;
                        [[NSNotificationCenter defaultCenter] postNotificationName: kTDApptsWrittenUnsuccessfullyNotification object: self];
                    }
                        break;
                    case ACTION_READ_CHRONOS_FILE:
                    {
                        OTLog(@"Error reading Timex Chronos File!");
                        [[NSNotificationCenter defaultCenter] postNotificationName: kTDWorkoutsReadUnsuccessfullyNotification object: self];
                    }
                        break;
                    case ACTION_READ_SYSBLOCK_FILE:
                    {
                        OTLog(@"Error reading SYSBLOCK File!");
                        [[NSNotificationCenter defaultCenter] postNotificationName: kTDSYSBLOCKReadUnsuccessfullyNotification object: self];
                    }
                        break;
                    case ACTION_GET_DEVICE_INFO:
                    {
                        OTLog(@"Error reading Timex Watch Info!");
                        [[NSNotificationCenter defaultCenter] postNotificationName: kTDWatchInfoReadUnsuccessfullyNotification object: self];
                    }
                        break;
                    case ACTION_GET_DEVICE_INFO_FIRMWARE:
                    {
                        OTLog(@"Error reading Timex Watch Info!");
                        [[NSNotificationCenter defaultCenter] postNotificationName: kTDWatchInfoFWReadUnsuccessfullyNotification object: self];
                    }
                        break;
                    case ACTION_GET_DEVICE_INFO_BOOTLOADER_STATUS:
                    {
                        OTLog(@"Error reading Timex M372 Watch Info!");
                        [[NSNotificationCenter defaultCenter] postNotificationName: kTDWatchInfoBootloaderReadUnsuccessfullyNotification object: self];
                    }
                        break;
                    case ACTION_GET_DEVICE_CHARGE_INFO:
                    {
                        OTLog(@"Error reading Timex Battery Charge Info!");
                        [[NSNotificationCenter defaultCenter] postNotificationName: kTDWatchChargeInfoReadUnsuccessfullyNotification object: self];
                    }
                        break;
                    case ACTION_GET_DEVICE_CHARGE_INFO_FIRMWARE:
                    {
                        OTLog(@"Error reading Timex Battery Charge Info!");
                        [[NSNotificationCenter defaultCenter] postNotificationName: kTDWatchChargeInfoFWReadUnsuccessfullyNotification object: self];
                    }
                        break;
                    case ACTION_WRITE_FIRMWARE_FILE:
                    case ACTION_WRITE_LANGUAGE_FILE:
                    case ACTION_WRITE_CODEPLUG_FILE:
                    case ACTION_RESUME_FIRMWARE:
                    case ACTION_WRITE_BOOTLOADER_FILE:
                    {
                        [self cancelFirmwareUpgradeDueToError];
                    }
                        break;
                }
            }
            break;
        case SUBACTION_OPEN_FILE:
        case SUBACTION_FILE_IO:
        case SUBACTION_SEEK_FILE:
        case SUBACTION_GET_FILE_SIZE:
            {
                switch( _mAction )
                {
                    case ACTION_READ_SETTINGS_FILE:
                    {
                        if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_Metropolitan)
                            [[NSNotificationCenter defaultCenter] postNotificationName: kTDM372SettingsReadUnsuccessfullyNotification object: self];
                        else
                            [[NSNotificationCenter defaultCenter] postNotificationName: kTDSettingsReadUnsuccessfullyNotification object: self];
                    }
                        break;
                    case ACTION_WRITE_M053_FULL_FILE:
                    {
                        [[NSNotificationCenter defaultCenter] postNotificationName: kTDSettingsWrittenUnsuccessfullyNotification object: self]; //reuse
                    }
                        break;
                    case ACTION_WRITE_SETTINGS_FILE:
                    {
                        [[NSNotificationCenter defaultCenter] postNotificationName: kTDSettingsWrittenUnsuccessfullyNotification object: self];
                    }
                        break;
                    case ACTION_READ_CHRONOS_FILE:
                    {
                        
                        [[NSNotificationCenter defaultCenter] postNotificationName: kTDWorkoutsReadUnsuccessfullyNotification object: self];
                    }
                        break;
                    case ACTION_READ_SYSBLOCK_FILE:
                    {
                        
                        [[NSNotificationCenter defaultCenter] postNotificationName: kTDSYSBLOCKReadSuccessfullyNotification object: self];
                    }
                        break;
                    case ACTION_WRITE_FIRMWARE_FILE:
                    case ACTION_WRITE_LANGUAGE_FILE:
                    case ACTION_WRITE_CODEPLUG_FILE:
                    case ACTION_RESUME_FIRMWARE:
                    case ACTION_WRITE_BOOTLOADER_FILE:
                    {
                        [self cancelFirmwareUpgradeDueToError];
                    }
                        break;
                    case ACTION_READ_M053_FULL_FILE:
                    {
                        [[NSNotificationCenter defaultCenter] postNotificationName: kTDM053ReadUnsuccessfullyNotification object: self];
                    }
                    case ACTION_WRITE_M053_TIME:
                    {
                        [[NSNotificationCenter defaultCenter] postNotificationName: kTDPhoneTimeWrittenUnsuccessfullyNotification object: self];
                    }
                        break;
                    case ACTION_READ_M372_ACTIVITY_DATA:
                    {
                        [[NSNotificationCenter defaultCenter] postNotificationName: kTDM372ActivitiesReadUnsuccessfullyNotification object: self];
                    }
                        break;
                    //TestLog_SleepFiles
                    case ACTION_READ_M372_SLEEP_SUMMARY:
                    {
                        [[NSNotificationCenter defaultCenter] postNotificationName: kTDM372ActivitiesReadUnsuccessfullyNotification object: self];
                    }
                        break;
                        
                    case ACTION_READ_M372_SLEEP_KEY_FILE:
                    {
                        [[NSNotificationCenter defaultCenter] postNotificationName: kTDM372SleepKeyFileReadUnsuccessfullyNotification object: self];
                    }
                        break;
                        
                    case ACTION_READ_M372_ACTIGRAPHY_FILES:
                    {
                        [[NSNotificationCenter defaultCenter] postNotificationName: kTDM372SleepActigraphyDataUnsuccessfullyNotification object: self];
                    }
                        break;
                    case ACTION_READ_M372_HOUR_DATA:
                    {
                        [[NSNotificationCenter defaultCenter] postNotificationName: kTDM372ActigraphyStepFileDataUnsuccessfullyNotification object: self];
                    }
                        break;
                    //TestLog_SleepFiles
                    case ACTION_WRITE_M053_APPTS_FILE:
                    case ACTION_WRITE_APPT_FILE:
                    {
                        //reset the checksum... writing of appts did not complete
                        _mLastSyncApptsChecksum = 0;
                        [[NSNotificationCenter defaultCenter] postNotificationName: kTDApptsWrittenUnsuccessfullyNotification object: self];
                    }
                        break;
                }
            }
            break;
    }
    
    //LV 11/03/14 - Fix for Mantis 631: If the error to any sync action while we were in "firmware paused" state, tough luck... we are cancelling the firmware too.
    //Otherwise, we can't really know whether we can continue the firmware upload or not. We can't rely on the watch connection status - we may have disconnected
    //and reconnected again.
    if ([self isFirmwareUpgradePaused])
    {
        [_mPendingActions removeObject: [NSNumber numberWithInteger: ACTION_RESUME_FIRMWARE]];
        [self cancelFirmwareUpgradeDueToError];
    }
    
    
    [self processNextCommandInQueueIfAny];
}

- (void) prepNextFirmwareUpgradeFileForShipment
{
    OTLog(@"PeripheralDevice prepNextFirmwareUpgradeFileForShipment");
//    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_Metropolitan)
    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_Metropolitan)
    {
        _progressFirmware.progress = 0;
        _progressFirmware.lblAverageString = [NSString stringWithFormat: @"0.0%%"];
        _firmwareUpgradePendingFilesCount--;
        TDM372FirmwareUpgradeInfo * downloadInfo = [_mFirmwareUpgradePendingFiles objectAtIndex: _mFirmwareUpgradeProcessedFileIndex];
        switch (downloadInfo.type)
        {
            case TDM372FirmwareUpgradeInfoType_Radio:
                _mAction = ACTION_WRITE_FIRMWARE_FILE;
                break;
            case TDM372FirmwareUpgradeInfoType_Firmware:
            case TDM372FirmwareUpgradeInfoType_Activity:
            case TDM372FirmwareUpgradeInfoType_Codeplug:
                _mAction = ACTION_WRITE_BOOTLOADER_FILE;
                break; // Added missing break statement here
        }
    } else if ([[TDWatchProfile sharedInstance]watchStyle] == timexDatalinkWatchStyle_IQ || [[TDWatchProfile sharedInstance]watchStyle] == timexDatalinkWatchStyle_IQTravel){
        _firmwareUpgradePendingFilesCount--;
        TDM372FirmwareUpgradeInfo * downloadInfo = [_mFirmwareUpgradePendingFiles objectAtIndex: _mFirmwareUpgradeProcessedFileIndex];
        switch (downloadInfo.type)
        {
            case TDM372FirmwareUpgradeInfoType_Radio:
            case TDM372FirmwareUpgradeInfoType_Firmware:
            case TDM372FirmwareUpgradeInfoType_Activity:
            case TDM372FirmwareUpgradeInfoType_Codeplug:
                 _mAction = ACTION_WRITE_FIRMWARE_FILE;
                break; // Added missing break statement here
        }

    }
    else
    {
        TDDatacastFirmwareUpgradeInfo * downloadInfo = [_mFirmwareUpgradePendingFiles objectAtIndex: _mFirmwareUpgradeProcessedFileIndex];
        switch (downloadInfo.type)
        {
            case TDDatacastFirmwareUpgradeInfoType_Firmware:
                _mAction = ACTION_WRITE_FIRMWARE_FILE;
                break;
            case TDDatacastFirmwareUpgradeInfoType_Codeplug:
                _mAction = ACTION_WRITE_CODEPLUG_FILE;
                break;
            case TDDatacastFirmwareUpgradeInfoType_Language:
                _mAction = ACTION_WRITE_LANGUAGE_FILE;
                break;
        }
    }
    NSString * path = ((TDDatacastFirmwareUpgradeInfo *)[_mFirmwareUpgradePendingFiles objectAtIndex: _mFirmwareUpgradeProcessedFileIndex]).pathToDownloadedFile;
    _mFileBytes = [NSData dataWithContentsOfFile: path];
}

- (void) readM053FullFilePrivate
{
    OTLog(@"readM053FullFilePrivate PeripheralDevice.m");

    TDFlurryDataPacket * dictFlurry = [[TDFlurryDataPacket alloc] initWithValue: @"Read Full M053 File" forKey: @"Sync_Action"];
    [iDevicesUtil logFlurryEvent: @"BLE_SYNC" withParameters:dictFlurry isTimedEvent:NO];
    
    //currently there is nnothing being processed....
    _mStatus = ERROR_NOT_CONNECTED;
    _mAction = ACTION_READ_M053_FULL_FILE;
    
    [self doTimexBluetoothSmart:[self nextSubAction: SUBACTION_WHOS_THERE]];
}

- (void) writeM053CurrentPhoneTimeAndEnableActivitySensorPrivate: (BOOL) partOfAnotherSession
{
    OTLog(@"writeM053CurrentPhoneTimeAndEnableActivitySensorPrivate PeripheralDevice.m");

    //currently there is nnothing being processed....
    _mStatus = ERROR_NOT_CONNECTED;
    _mAction = ACTION_WRITE_M053_TIME;
    
    //enable sensor:
    NSString * key = [iDevicesUtil createKeyForWatchControlPropertyWithClass: programWatchM053_PropertyClass_ActivityTracking andIndex: programWatchM053_PropertyClass_ActivityTracking_SensorStatus];
    [[NSUserDefaults standardUserDefaults] setBool: TRUE forKey: key];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    
    TDM053WatchData * watchSettings = [[TDM053WatchData alloc] init];
    if (watchSettings != nil)
    {
        _mFileBytes = [watchSettings currentTimeAndSetupSettingsToByteArray];
        if (_mFileBytes)
        {
            TDFlurryDataPacket * dictFlurry = [[TDFlurryDataPacket alloc] initWithValue: @"Write M053 Current Phone Time" forKey: @"Sync_Action"];
            [iDevicesUtil logFlurryEvent: @"BLE_SYNC" withParameters:dictFlurry isTimedEvent:NO];
            
            if (partOfAnotherSession)
                [self doTimexBluetoothSmart: [self nextSubAction: SUBACTION_START]];
            else
                [self doTimexBluetoothSmart: [self nextSubAction: SUBACTION_WHOS_THERE]];
        }
    }
}

- (void) writeM053FullFilePrivate: (BOOL) partOfAnotherSession
{
    OTLog(@"writeM053FullFilePrivate PeripheralDevice.m");

    //currently there is nothing being processed....
    _mStatus = ERROR_NOT_CONNECTED;
    _mAction = ACTION_WRITE_M053_FULL_FILE;
    
    TDDatacastApptsParser * apptsParser = [[TDDatacastApptsParser alloc] init : MAX_NUMBER_APPTS_TO_SEND_CONNECT1_5];
    if (apptsParser != nil)
    {
        __weak PeripheralDevice * weakSelf = self;
        void (^completionBlock)(void) = ^(void)
        {
            PeripheralDevice * strongSelf = weakSelf;
            TDM053WatchData * watchSettings = [[TDM053WatchData alloc] init];
            if (watchSettings != nil)
            {
                _mFileBytes = [watchSettings settingsAndApptsToByteArray: apptsParser];
                if (_mFileBytes)
                {
                    TDFlurryDataPacket * dictFlurry = [[TDFlurryDataPacket alloc] initWithValue: @"Write M053 Full File" forKey: @"Sync_Action"];
                    [iDevicesUtil logFlurryEvent: @"BLE_SYNC" withParameters:dictFlurry isTimedEvent:NO];
                    
                    if (partOfAnotherSession)
                        [strongSelf doTimexBluetoothSmart: [self nextSubAction: SUBACTION_START]];
                    else
                        [strongSelf doTimexBluetoothSmart: [self nextSubAction: SUBACTION_WHOS_THERE]];
                }
            }
        };
        
        [apptsParser reloadCalendarData: completionBlock];
    }
}
- (void) writeM053ApptsFilePrivate: (BOOL) partOfAnotherSession
{
    OTLog(@"writeM053ApptsFilePrivate PeripheralDevice.m");

    //currently there is nnothing being processed....
    _mStatus = ERROR_NOT_CONNECTED;
    _mAction = ACTION_WRITE_M053_APPTS_FILE;
    
    TDDatacastApptsParser * apptsParser = [[TDDatacastApptsParser alloc] init : MAX_NUMBER_APPTS_TO_SEND_CONNECT1_5];
    if (apptsParser != nil)
    {
        __weak PeripheralDevice * weakSelf = self;
        void (^completionBlock)(void) = ^(void)
        {
            PeripheralDevice * strongSelf = weakSelf;
            _mFileBytes = [apptsParser toM053ByteArray];
            if (_mFileBytes)
            {
                TDFlurryDataPacket * dictFlurry = [[TDFlurryDataPacket alloc] initWithValue: @"Write M053 Appts" forKey: @"Sync_Action"];
                [iDevicesUtil logFlurryEvent: @"BLE_SYNC" withParameters:dictFlurry isTimedEvent:NO];
                
                if (partOfAnotherSession)
                    [strongSelf doTimexBluetoothSmart: [self nextSubAction: SUBACTION_START]];
                else
                    [strongSelf doTimexBluetoothSmart: [self nextSubAction: SUBACTION_WHOS_THERE]];
            }
        };
        
        [apptsParser reloadCalendarData: completionBlock];
    }
}

- (void) requestDeviceInfoPrivate: (int) action
{
    OTLog(@"requestDeviceInfoPrivate PeripheralDevice.m");

    TDFlurryDataPacket * dictFlurry = [[TDFlurryDataPacket alloc] initWithValue: @"Device Info" forKey: @"Sync_Action"];
    [iDevicesUtil logFlurryEvent: @"BLE_SYNC" withParameters:dictFlurry isTimedEvent:NO];
    
    //currently there is nothing being processed....
    _mStatus = ERROR_NOT_CONNECTED;
    _mAction = action;
    
    [self doTimexBluetoothSmart: SUBACTION_WHOS_THERE];
}

- (void) requestDeviceChargeInfoPrivate: (int) action
{
    OTLog(@"requestDeviceChargeInfoPrivate PeripheralDevice.m");

    TDFlurryDataPacket * dictFlurry = [[TDFlurryDataPacket alloc] initWithValue: @"Device Charge Info" forKey: @"Sync_Action"];
    [iDevicesUtil logFlurryEvent: @"BLE_SYNC" withParameters:dictFlurry isTimedEvent:NO];
    
    //currently there is nnothing being processed....
    _mStatus = ERROR_NOT_CONNECTED;
    _mAction = action;
    
    [self doTimexBluetoothSmart: SUBACTION_GET_CHARGE_INFO];
}

- (void) readTimexWatchSettingsPrivate
{
    OTLog(@"readTimexWatchSettingsPrivate PeripheralDevice.m");

    TDFlurryDataPacket * dictFlurry = [[TDFlurryDataPacket alloc] initWithValue: @"Read Watch Settings" forKey: @"Sync_Action"];
    [iDevicesUtil logFlurryEvent: @"BLE_SYNC" withParameters:dictFlurry isTimedEvent:NO];
    
    //currently there is nnothing being processed....
    _mStatus = ERROR_NOT_CONNECTED;
    _mAction = ACTION_READ_SETTINGS_FILE;
    
    [self doTimexBluetoothSmart: [self nextSubAction: SUBACTION_NEW]];
}

- (void) readTimexWatchActivityDataPrivate
{
    OTLog(@"readTimexWatchActivityDataPrivate PeripheralDevice.m");

    TDFlurryDataPacket * dictFlurry = [[TDFlurryDataPacket alloc] initWithValue: @"Read Watch Activity Data" forKey: @"Sync_Action"];
    [iDevicesUtil logFlurryEvent: @"BLE_SYNC" withParameters:dictFlurry isTimedEvent:NO];
    
    //currently there is nnothing being processed....
    _mStatus = ERROR_NOT_CONNECTED;
    _mAction = ACTION_READ_M372_ACTIVITY_DATA;
    
    [self doTimexBluetoothSmart: [self nextSubAction: SUBACTION_NEW]];
}

//TestLog_SleepFiles
- (void) readTimexWatchSleepSummaryDataPrivate
{
    OTLog(@"readTimexWatchSleepSummaryDataPrivate PeripheralDevice.m");

    TDFlurryDataPacket * dictFlurry = [[TDFlurryDataPacket alloc] initWithValue: @"Read Watch Sleep Summary Data" forKey: @"Sync_Action"];
    [iDevicesUtil logFlurryEvent: @"BLE_SYNC" withParameters:dictFlurry isTimedEvent:NO];
    
    //currently there is nnothing being processed....
    _mStatus = ERROR_NOT_CONNECTED;
    _mAction = ACTION_READ_M372_SLEEP_SUMMARY;
    
    [self doTimexBluetoothSmart: [self nextSubAction: SUBACTION_NEW]];
}

- (void) readTimexWatchSleepKeyFilePrivate
{
    OTLog(@"readTimexWatchSleepKeyFilePrivate PeripheralDevice.m");
    TDFlurryDataPacket * dictFlurry = [[TDFlurryDataPacket alloc] initWithValue: @"Read Watch Sleep Key" forKey: @"Sync_Action"];
    [iDevicesUtil logFlurryEvent: @"BLE_SYNC" withParameters:dictFlurry isTimedEvent:NO];
    
    //currently there is nnothing being processed....
    _mStatus = ERROR_NOT_CONNECTED;
    _mAction = ACTION_READ_M372_SLEEP_KEY_FILE;
    
    [self doTimexBluetoothSmart: [self nextSubAction: SUBACTION_NEW]];
}
- (void) readTimexWatchSleepActigraphyFilesPrivate
{
    OTLog(@"readTimexWatchSleepActigraphyFilesPrivate PeripheralDevice.m");
    TDFlurryDataPacket * dictFlurry = [[TDFlurryDataPacket alloc] initWithValue: @"Read Watch Sleep Actigraphy Data" forKey: @"Sync_Action"];
    [iDevicesUtil logFlurryEvent: @"BLE_SYNC" withParameters:dictFlurry isTimedEvent:NO];
    
    //currently there is nnothing being processed....
    _mStatus = ERROR_NOT_CONNECTED;
    _mAction = ACTION_READ_M372_ACTIGRAPHY_FILES;
    
    [self doTimexBluetoothSmart: [self nextSubAction: SUBACTION_NEW]];
}

- (void) readTimexWatchActigraphyStepFilesPrivate
{
    OTLog(@"readTimexWatchActigraphyStepFilesPrivate PeripheralDevice.m");
    TDFlurryDataPacket * dictFlurry = [[TDFlurryDataPacket alloc] initWithValue: @"Read Watch Actigraphy step Data" forKey: @"Sync_Action"];
    [iDevicesUtil logFlurryEvent: @"BLE_SYNC" withParameters:dictFlurry isTimedEvent:NO];
    
    //currently there is nnothing being processed....
    _mStatus = ERROR_NOT_CONNECTED;
    _mAction = ACTION_READ_M372_HOUR_DATA;
    
    [self doTimexBluetoothSmart: [self nextSubAction: SUBACTION_NEW]];
}

//TestLog_SleepFiles

- (void) writeTimexWatchSettingsPrivate
{
    OTLog(@"writeTimexWatchSettingsPrivate PeripheralDevice.m");
    TDFlurryDataPacket * dictFlurry = [[TDFlurryDataPacket alloc] initWithValue: @"Write Watch Settings" forKey: @"Sync_Action"];
    [iDevicesUtil logFlurryEvent: @"BLE_SYNC" withParameters:dictFlurry isTimedEvent:NO];
    
    //currently there is nnothing being processed....
    _mStatus = ERROR_NOT_CONNECTED;
    _mAction = ACTION_WRITE_SETTINGS_FILE;
    
    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_Metropolitan)
    {
         TDM372WatchSettings * watchSettings = [[TDM372WatchSettings alloc] init];
        if (watchSettings != nil)
        {
            _mFileBytes = [watchSettings toByteArray];
            if (_mFileBytes)
            {
                [self doTimexBluetoothSmart: [self nextSubAction: SUBACTION_NEW]];
            }
        }
    }
    else if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQ)
    {
        TDM328WatchSettings * watchSettings = [[TDM328WatchSettings alloc] init];
        if (watchSettings != nil)
        {
            _mFileBytes = [watchSettings toByteArray];
            if (_mFileBytes)
            {
                [self doTimexBluetoothSmart: [self nextSubAction: SUBACTION_NEW]];
            }
        }
    }
    else if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)
    {
        TDM329WatchSettings * watchSettings = [[TDM329WatchSettings alloc] init];
        if (watchSettings != nil)
        {
            _mFileBytes = [watchSettings toByteArray];
            if (_mFileBytes)
            {
                [self doTimexBluetoothSmart: [self nextSubAction: SUBACTION_NEW]];
            }
        }
    }
    else
    {
        TDDatacastWatchSettings * watchSettings = [[TDDatacastWatchSettings alloc] init];
        if (watchSettings != nil)
        {
            _mFileBytes = [watchSettings toByteArray];
            if (_mFileBytes)
            {
                [self doTimexBluetoothSmart: [self nextSubAction: SUBACTION_NEW]];
            }
        }
    }
}

- (void) readTimexWorkoutsPrivate
{
    OTLog(@"readTimexWorkoutsPrivate PeripheralDevice.m");
    TDFlurryDataPacket * dictFlurry = [[TDFlurryDataPacket alloc] initWithValue: @"Read Workouts" forKey: @"Sync_Action"];
    [iDevicesUtil logFlurryEvent: @"BLE_SYNC" withParameters:dictFlurry isTimedEvent:NO];
    
    //currently there is nnothing being processed....
    _mStatus = ERROR_NOT_CONNECTED;
    _mAction = ACTION_READ_CHRONOS_FILE;
    
    [self doTimexBluetoothSmart: [self nextSubAction: SUBACTION_NEW]];
}

- (void) readSYSBLOCKPrivate
{
    OTLog(@"readSYSBLOCKPrivate PeripheralDevice.m");
    TDFlurryDataPacket * dictFlurry = [[TDFlurryDataPacket alloc] initWithValue: @"Read SYSBLOCK" forKey: @"Sync_Action"];
    [iDevicesUtil logFlurryEvent: @"BLE_SYNC" withParameters:dictFlurry isTimedEvent:NO];
    
    //currently there is nnothing being processed....
    _mStatus = ERROR_NOT_CONNECTED;
    _mAction = ACTION_READ_SYSBLOCK_FILE;
    
    [self doTimexBluetoothSmart: [self nextSubAction: SUBACTION_NEW]];
}

- (void) doFirmwareUpgradePrivate
{
    OTLog(@"doFirmwareUpgradePrivate PeripheralDevice.m");
    TDFlurryDataPacket * dictFlurry = [[TDFlurryDataPacket alloc] initWithValue: @"Firmware Upgrade" forKey: @"Sync_Action"];
    [iDevicesUtil logFlurryEvent: @"BLE_SYNC" withParameters:dictFlurry isTimedEvent:NO];
    
    _mFirmwareUpgradeProcessedFileIndex = 0;
    _mStatus = ERROR_NOT_CONNECTED;
    
    [self prepNextFirmwareUpgradeFileForShipment];
    if (_mFileBytes)
    {
        if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQ || [[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_IQTravel)
            [self doTimexBluetoothSmart: [self nextSubAction: SUBACTION_START_FILE_SESSION_M372]];
        else
            [self doTimexBluetoothSmart: [self nextSubAction: SUBACTION_NEW]];
    }
}

- (void) doBootloaderFirmwareUpgradePrivate
{
    OTLog(@"doBootloaderFirmwareUpgradePrivate PeripheralDevice.m");
    TDFlurryDataPacket * dictFlurry = [[TDFlurryDataPacket alloc] initWithValue: @"Bootloader Firmware Upgrade" forKey: @"Sync_Action"];
    [iDevicesUtil logFlurryEvent: @"BLE_SYNC" withParameters:dictFlurry isTimedEvent:NO];
    
    _mFirmwareUpgradeProcessedFileIndex = 0;
    _mStatus = ERROR_NOT_CONNECTED;
    
    [self prepNextFirmwareUpgradeFileForShipment];
    if (_mFileBytes)
    {
        if (_skipWhosThere)
        {
            [self doTimexBluetoothSmart: [self nextSubAction: SUBACTION_WHOS_THERE]];
        }
        else
        {
            [self doTimexBluetoothSmart: [self nextSubAction: SUBACTION_NEW]];
        }
    }
}

- (void) doFirmwareResumePrivate
{
    OTLog(@"doFirmwareResumePrivate PeripheralDevice.m");
    TDFlurryDataPacket * dictFlurry = [[TDFlurryDataPacket alloc] initWithValue: @"Firmware Resume" forKey: @"Sync_Action"];
    [iDevicesUtil logFlurryEvent: @"BLE_SYNC" withParameters:dictFlurry isTimedEvent:NO];
    
    _mStatus = ERROR_NOT_CONNECTED;
    _mAction = ACTION_RESUME_FIRMWARE;
    
    [self doTimexBluetoothSmart: [self nextSubAction: SUBACTION_NEW]];
}

- (BOOL) sendApptsToWatchPrivate
{
    OTLog(@"sendApptsToWatchPrivate PeripheralDevice.m");
    __block BOOL actionNotNeeded = FALSE;
    
    //currently there is nnothing being processed....
    _mStatus = ERROR_NOT_CONNECTED;
    OTLog(@"Sending action as Appt file write");
    _mAction = ACTION_WRITE_APPT_FILE;
    
    TDDatacastApptsParser * apptsParser = [[TDDatacastApptsParser alloc] init : MAX_NUMBER_APPTS_TO_SEND_DATACAST];
    if (apptsParser != nil)
    {
        __weak PeripheralDevice * weakSelf = self;
        void (^completionBlock)(void) = ^(void)
        {
            PeripheralDevice * strongSelf = weakSelf;
            _mFileBytes = [apptsParser toByteArray];
            if (_mFileBytes)
            {
                if (_mLastSyncApptsChecksum == 0 || _mLastSyncApptsChecksum != apptsParser.mLastChecksum)
                {
                    TDFlurryDataPacket * dictFlurry = [[TDFlurryDataPacket alloc] initWithValue: @"Write Appts" forKey: @"Sync_Action"];
                    [iDevicesUtil logFlurryEvent: @"BLE_SYNC" withParameters:dictFlurry isTimedEvent:NO];
                    
                    _mLastSyncApptsChecksum = apptsParser.mLastChecksum;
                    [strongSelf doTimexBluetoothSmart: [self nextSubAction: SUBACTION_NEW]];
                    
                    if ([[TDWatchProfile sharedInstance] watchStyle] == timexDatalinkWatchStyle_M054)
                        [[NSNotificationCenter defaultCenter] postNotificationName:kTDApptsWritingStartedNotification object:nil];
                }
                else
                {
                    actionNotNeeded = TRUE;
                    OTLog(@"There are no new appointments to send!");
                }
            }
            else
                actionNotNeeded = TRUE;
        };
        
        [apptsParser reloadCalendarData: completionBlock];
    }
    
    return actionNotNeeded;
}

- (void) processNextCommandInQueueIfAny
{
    OTLog(@"Process Next command in queue");
    
    if (_mPendingActions.count > 0)
    {
        OTLog(@"Removing action from pending pile %@",_mPendingActions);
        [_mPendingActions removeObjectAtIndex: 0];
      
    }
    
    if (_mPendingActions.count > 0)
    {
        NSNumber * currentAction = [_mPendingActions objectAtIndex: 0];
        
        switch ([currentAction integerValue])
        {
            case ACTION_READ_SETTINGS_FILE:
                [self readTimexWatchSettingsPrivate];
                break;
            case ACTION_WRITE_SETTINGS_FILE:
                [self writeTimexWatchSettingsPrivate];
                break;
            case ACTION_READ_CHRONOS_FILE:
                [self readTimexWorkoutsPrivate];
                break;
            case ACTION_READ_SYSBLOCK_FILE:
                [self readSYSBLOCKPrivate];
                break;
            case ACTION_READ_M372_ACTIVITY_DATA:
                [self readTimexWatchActivityDataPrivate];
                break;
            //TestLog_SleepFiles
            case ACTION_READ_M372_SLEEP_SUMMARY:
                //[self readTimexWatchSleepSummaryDataPrivate];
                break;
            case ACTION_READ_M372_SLEEP_KEY_FILE:
                //[self readTimexWatchSleepKeyFilePrivate];
                break;
            case ACTION_READ_M372_ACTIGRAPHY_FILES:
            case ACTION_READ_M372_HOUR_DATA:
                //[self readTimexWatchSleepActigraphyFilesPrivate];
                break;
            //TestLog_SleepFiles
            case ACTION_WRITE_APPT_FILE:
                {
                    BOOL actionNotNeeded = [self sendApptsToWatchPrivate];
                    if (actionNotNeeded)
                    {
                        //we are not sending appointments as there is nothing to send.....
                        [self processNextCommandInQueueIfAny];
                    }
                }
                break;
            case ACTION_GET_DEVICE_INFO:
            case ACTION_GET_DEVICE_INFO_FIRMWARE:
            case ACTION_GET_DEVICE_INFO_BOOTLOADER_STATUS:
                [self requestDeviceInfoPrivate: [currentAction intValue]];
                break;
            case ACTION_GET_DEVICE_CHARGE_INFO:
            case ACTION_GET_DEVICE_CHARGE_INFO_FIRMWARE:
                [self requestDeviceChargeInfoPrivate: [currentAction intValue]];
                break;
            case ACTION_WRITE_CODEPLUG_FILE:
            case ACTION_WRITE_FIRMWARE_FILE:
                [self doFirmwareUpgradePrivate];
                break;
            case ACTION_WRITE_BOOTLOADER_FILE:
                [self doBootloaderFirmwareUpgradePrivate];
                break;
            case ACTION_RESUME_FIRMWARE:
                [self doFirmwareResumePrivate];
                break;
            case ACTION_READ_M053_FULL_FILE:
                [self readM053FullFilePrivate];
                break;
            case ACTION_WRITE_M053_FULL_FILE:
                [self writeM053FullFilePrivate: TRUE];
                break;
            case ACTION_WRITE_M053_APPTS_FILE:
                [self writeM053ApptsFilePrivate: TRUE];
                break;
            case ACTION_WRITE_M053_TIME:
                [self writeM053CurrentPhoneTimeAndEnableActivitySensorPrivate: TRUE];
            default:
                break;
        }
    }
    
}
- (void) softResetM372Watch
{
    PCCPacket * bootloaderPacket = [[PCCPacket alloc] init: ExtenderCmdWatchReset];
    if ( nil != bootloaderPacket )
    {
        OTLog(@"M372 WATCH RESET REQUESTED!");
        [self writePCCommPacket: bootloaderPacket];
    }
}
- (void) resetM372Watch
{
    PCCPacket * bootloaderPacket = [[PCCPacket alloc] init: ExtenderCmdFactoryReset];
    if ( nil != bootloaderPacket )
    {
        OTLog(@"M372 WATCH RESET REQUESTED!");
        [self writePCCommPacket: bootloaderPacket];
    }
}
- (void) startBootloaderForM372
{
    PCCPacket * bootloaderPacket = [[PCCPacket alloc] init: ExtenderCmdEnterBootloaderMode];
    if ( nil != bootloaderPacket )
    {
         OTLog(@"BOOTLOADER MODE REQUESTED!");
        [self writePCCommPacket: bootloaderPacket];
        
        [[NSNotificationCenter defaultCenter] postNotificationName: kTDM372BootloaderModeRequested object: self];
    }
}
- (void) exitBootloaderForM372
{
    PCCPacket * bootloaderPacket = [[PCCPacket alloc] init: ExtenderCmdForceBootloaderModeExit];
    if ( nil != bootloaderPacket )
    {
        OTLog(@"BOOTLOADER MODE EXIT REQUESTED!");
        [self writePCCommPacket: bootloaderPacket];
    }
}
- (void) _reboot
{
    PCCPacket * rebootPacket = [[PCCPacket alloc] init: ExtenderCmdReboot];
    if ( nil != rebootPacket )
    {
        OTLog(@"REBOOT REQUESTED!");
        [self writePCCommPacket: rebootPacket];
    }
}
- (void) startVibrating
{
    if (_mPhoneFinderStatus != nil)
    {
        AudioServicesAddSystemSoundCompletion(kSystemSoundID_Vibrate, nil, nil, vibrationFinished, (__bridge void*) self);
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    }
}
- (void) cancelFirmwareUpgradeDueToError
{
    OTLog(@"cancelFirmwareUpgradeDueToError PeripheralDevice.m");

    _mFirmwareUpgradePendingFiles = nil;
    _mFirmwareUpgradeProcessedFileIndex = NSIntegerMax;
    _mFirmwareTotalPacketsCount = 0;
    [[NSNotificationCenter defaultCenter] postNotificationName: kTDFirmwareWrittenUnsuccessfullyNotification object: self];
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView == _bootloaderModeOnAlert)
    {
        if (alertView.cancelButtonIndex != buttonIndex)
        {
            [self initiateBootloadRecovery];
        }
    }
}

- (void) initiateBootloadRecovery
{
    [[NSNotificationCenter defaultCenter] postNotificationName: kTDM372UnexpectedBootloaderModeDetectedAndApproved object: self];
}

- (void) recordM372FirmwareFileUpgrade: (TDM372FirmwareUpgradeInfo *) downloadInfo
{
    OTLog(@"recordM372FirmwareFileUpgrade PeripheralDevice.m");
    NSString * existingString = nil;
    
    if (!downloadInfo)
        return;
    OTLog(@"Firmware Upgrade : We just successfully wrote some file to the watch... let's update the settings");
    existingString = [[NSUserDefaults standardUserDefaults] objectForKey: kM372FirmwareVersionFile1Key];
    if (existingString && downloadInfo.type == [self _extractM372TypeFrom: existingString] && downloadInfo.filename)
    {
        OTLog([NSString stringWithFormat:@"--> Updated %@ firmware file name with %@", existingString, downloadInfo.filename]);

        [[NSUserDefaults standardUserDefaults] setObject: downloadInfo.filename forKey: kM372FirmwareVersionFile1Key];
    }
    else
    {
        existingString = [[NSUserDefaults standardUserDefaults] objectForKey: kM372FirmwareVersionFile2Key];
        if (existingString && downloadInfo.type == [self _extractM372TypeFrom: existingString] && downloadInfo.filename)
        {
            OTLog([NSString stringWithFormat:@"--> Updated %@ firmware file name with %@", existingString, downloadInfo.filename]);

            [[NSUserDefaults standardUserDefaults] setObject: downloadInfo.filename forKey: kM372FirmwareVersionFile2Key];
        }
        else
        {
            existingString = [[NSUserDefaults standardUserDefaults] objectForKey: kM372FirmwareVersionFile3Key];
            if (existingString && downloadInfo.type == [self _extractM372TypeFrom: existingString] && downloadInfo.filename)
            {
                OTLog([NSString stringWithFormat:@"--> Updated %@ firmware file name with %@", existingString, downloadInfo.filename]);

                [[NSUserDefaults standardUserDefaults] setObject: downloadInfo.filename forKey: kM372FirmwareVersionFile3Key];
            }
            else
            {
                existingString = [[NSUserDefaults standardUserDefaults] objectForKey: kM372FirmwareVersionFile4Key];
                if (existingString && downloadInfo.type == [self _extractM372TypeFrom: existingString] && downloadInfo.filename)
                {
                    OTLog([NSString stringWithFormat:@"--> Updated %@ firmware file name with %@", existingString, downloadInfo.filename]);

                    [[NSUserDefaults standardUserDefaults] setObject: downloadInfo.filename forKey: kM372FirmwareVersionFile4Key];
                }
            }
        }
    }
}
- (TDM372FirmwareUpgradeInfoType) _extractM372TypeFrom: (NSString *) fileName
{
    OTLog(@"PeripheralDevice _extractM372TypeFrom");
    NSRange letterRange = NSMakeRange(fileName.length - 4, 1);
    NSString * letterCode = [fileName substringWithRange: letterRange];
    
    TDM372FirmwareUpgradeInfoType typeToProcess = TDM372FirmwareUpgradeInfoType_Uninitialized;
    
    if ([letterCode isEqualToString: @"F"])
    {
        typeToProcess = TDM372FirmwareUpgradeInfoType_Firmware;
    }
    else if ([letterCode isEqualToString: @"C"])
    {
        typeToProcess = TDM372FirmwareUpgradeInfoType_Codeplug;
    }
    else if ([letterCode isEqualToString: @"A"])
    {
        typeToProcess = TDM372FirmwareUpgradeInfoType_Activity;
    }
    else if ([letterCode isEqualToString: @"R"])
    {
        typeToProcess = TDM372FirmwareUpgradeInfoType_Radio;
    }
    
    return typeToProcess;
}
#pragma mark -
#pragma mark TDConnectionStatusWindowDelegate methods

- (void) didShowTDConnectionStatusWindow:(TDConnectionStatusWindow*)sender
{
    OTLog(@"PeripheralDevice didShowTDConnectionStatusWindow");
    [self startVibrating];
}
- (void) willCloseTDConnectionStatusWindow:(TDConnectionStatusWindow*)sender
{
    OTLog(@"PeripheralDevice willCloseTDConnectionStatusWindow");
    [[TDAudioPlayer sharedPlayer] stop];
    
    //that works for both watch finder and phone finder
    [self triggerWatchFinder: FALSE];
    _mPhoneFinderStatus = nil;
}
- (void) didCloseTDConnectionStatusWindow:(TDConnectionStatusWindow*)sender
{
    OTLog(@"PeripheralDevice didCloseTDConnectionStatusWindow");
    _mPhoneFinderStatus = nil;
}
#pragma mark -
#pragma mark AudioServicesAddSystemSoundCompletion methods
static void vibrationFinished (SystemSoundID sound, void * data)
{
    OTLog(@"PeripheralDevice vibrationFinished");
    AudioServicesRemoveSystemSoundCompletion(sound);
    AudioServicesDisposeSystemSoundID(sound);
    
    [(__bridge PeripheralDevice *)data performSelector:@selector(startVibrating) withObject: nil afterDelay: 1.0];
}

/**
 *  Resets the pending actions.
 */
-(void)resetPendingActions{
    OTLog(@"PeripheralDevice resetPendingActions");
    if(_mPendingActions && _mPendingActions.count > 0){
        [_mPendingActions removeAllObjects];
    }
}

@end
