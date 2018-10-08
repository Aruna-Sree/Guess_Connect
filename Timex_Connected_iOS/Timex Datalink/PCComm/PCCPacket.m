//
//  PCCPacket.m
//  Timex Connected
//
//  Created by Lev Verbitsky on 1/20/14.
//  Copyright (c) 2014 iDevices, LLC. All rights reserved.
//

#import "PCCPacket.h"
#import "TDDefines.h"
#import "PCCommCommands.h"
#import "PCCommWhosThere.h"
#import "PCCommChargeInfo.h"
#import "PCCommExtendedFirmwareVersionInfo.h"
#import "iDevicesUtil.h"

extern const int ChecksumLength        = 2;
extern const int RebootRespBytes       = ([PCCHeader size] + ChecksumLength);
extern const int DatalinkNFCRespBytes  = ([PCCHeader size] + 1 + ChecksumLength);
extern const int ExtenderBLERespBytes  = ([PCCHeader size] + 3 + ChecksumLength);
extern const int WhosThereNumRespBytes = ([PCCHeader size] + PCCOMM_SIZE_WHOSTHERE + ChecksumLength);
extern const int ChargeInfoNumRespBytes = ([PCCHeader size] + PCCOMM_SIZE_CHARGEINFO + ChecksumLength);
extern const int ExtraFirmwareRevisionsInfoNumRespBytes = ([PCCHeader size] + PCCOMM_SIZE_EXTENDED_VERSION_INFO + ChecksumLength); //for M372 only

@implementation PCCPacket

@synthesize isValid = _isValid;
@synthesize mExtenderReadCount = _mExtenderReadCount;
@synthesize mUpdateLanguage = _mUpdateLanguage;
@synthesize mUpdateFirmware = _mUpdateFirmware;
@synthesize mUpdateCodePlug = _mUpdateCodePlug;
@synthesize mSectorStart = _mSectorStart;
@synthesize mSectorEnd = _mSectorEnd;
@synthesize mPayload = _mPayload;
@synthesize mRawData = _mRawData;
@synthesize mChecksum = _mChecksum;
@synthesize mNumRespBytes = _mNumRespBytes;
@synthesize mResponse = _mResponse;
@synthesize mCommandPacket = _mCommandPacket;
@synthesize mCommand = _mCommand;
@synthesize mExtenderFileAccessType = _mExtenderFileAccessType;
@synthesize mSubCmd = _mSubCmd;
@synthesize mExtenderFileName = _mExtenderFileName;
@synthesize mExtenderFileHandle = _mExtenderFileHandle;
@synthesize mExtenderFilePointer = _mExtenderFilePointer;

- (id) init: (Byte) cmd accessType: (Byte) extenderFileAccessType extenderFile: (NSString *) filename
{
    if (self == [self _init])
    {
        _mCommand = [[PCCCommand alloc] init: cmd];
        _mExtenderFileAccessType = extenderFileAccessType;
        _mExtenderFileName = [NSString stringWithString: filename];
    }
    
    if ([self ValidatePacket])
    {
        [self CreateCommandRawData];
        [self CalculateChecksum: FALSE];
        
        return self;
    }
    else
    {
        return nil;
    }
}
- (id) init: (Byte) cmd fileHandle: (Byte) extenderFileHandle readCount: (int) readCount
{
    if (self == [self _init])
    {
        _mCommand = [[PCCCommand alloc] init: cmd];
        _mExtenderFileHandle = extenderFileHandle;
        _mExtenderReadCount = readCount;
    }
    
    if ([self ValidatePacket])
    {
        [self CreateCommandRawData];
        [self CalculateChecksum: FALSE];
        
        return self;
    }
    else
    {
        return nil;
    }
}
- (id) init: (Byte) cmd fileHandle: (Byte) extenderFileHandle filePointer: (int) extenderFilePointer
{
    if (self == [self _init])
    {
        _mCommand = [[PCCCommand alloc] init: cmd];
        _mExtenderFileHandle = extenderFileHandle;
        _mExtenderFilePointer = extenderFilePointer;
    }
    
    if ([self ValidatePacket])
    {
        [self CreateCommandRawData];
        [self CalculateChecksum: FALSE];
        
        return self;
    }
    else
    {
        return nil;
    }
}
- (id) init: (Byte) cmd fileHandle: (Byte) extenderFileHandle rawData: (NSData *) rData
{
    if (self == [self _init])
    {
        _mCommand = [[PCCCommand alloc] init: cmd];
        _mExtenderFileHandle = extenderFileHandle;
        _mRawData = [NSData dataWithData: rData];
    }
    
    if ([self ValidatePacket])
    {
        [self CreateCommandRawData];
        [self CalculateChecksum: FALSE];
        
        return self;
    }
    else
    {
        return nil;
    }
}
- (id) initWithResponseRawData: (NSData *) rData
{
    if (self == [self _init])
    {
        _mRawData = [NSData dataWithData: rData];
    }
    
    [self CreateResponseRawData];
    return self;
}
- (id) init: (Byte) cmd
{
    if (self == [self _init])
    {
        _mCommand = [[PCCCommand alloc] init: cmd];
    }
    
    if ([self ValidatePacket])
    {
        [self CreateCommandRawData];
        [self CalculateChecksum: FALSE];
        
        return self;
    }
    else
    {
        return nil;
    }
}

- (id) init: (Byte) cmd firmwareFlag: (BOOL) fFlag codeplugFlag: (BOOL) cFlag languageFlag: (BOOL) lFlag
{
    if (self == [self _init])
    {
        _mCommand = [[PCCCommand alloc] init: cmd];
        
        _mUpdateCodePlug = cFlag;
        _mUpdateFirmware = fFlag;
        _mUpdateLanguage = lFlag;
    }
    
    if ([self ValidatePacket])
    {
        [self CreateCommandRawData];
        [self CalculateChecksum: FALSE];
                
        return self;
    }
    else
    {
        return nil;
    }
}

- (id) _init
{
    if (self = [super init])
    {
        _mCommand = nil;
        _mCommandPacket = [[PCCCommandPacket alloc] init];
        _mResponse = [[PCCResponsePacket alloc] init];

        _mPayload = nil;
        
        _mSubCmd = 0;
        _mSectorStart = 0;
        _mSectorEnd = 0;
        _mChecksum = 0;
        _mExtenderFileAccessType = 0;
        _mExtenderFileName = @"";
        _mExtenderFileHandle = 0;
        _mExtenderFilePointer = 0;
        _mExtenderReadCount = 0;
        _mUpdateLanguage = 0;
        _mUpdateFirmware = 0;
        _mUpdateCodePlug = 0;
        
        _isValid = FALSE;
    }
    
    return self;
}

- (BOOL) ValidateCommand
{
    BOOL valid = true;
    
    Byte command = [_mCommand Get];
    switch ( command )
    {
        case DataLink:
        {
            // Determine link address
            PCCHeader * header = [_mCommandPacket getHeader];
            PCCLinkAddress * linkAddress = [header linkAddress];
            if ([linkAddress Get] == PCC_LINKADDRESS_NFC)
           {
                _mNumRespBytes = DatalinkNFCRespBytes;
           }
        }
            break;
            
        case WhosThere:
            // Set the number of response bytes expected
            _mNumRespBytes = WhosThereNumRespBytes;
            break;
            
        case ExtenderCmdReadChargeInfo:
            // Set the number of response bytes expected
            _mNumRespBytes = ChargeInfoNumRespBytes;
            break;
        case ExtenderCmdGetExtraFirmwareRevisions:
            // Set the number of response bytes expected
            _mNumRespBytes = ExtraFirmwareRevisionsInfoNumRespBytes;
            break;
        case ExtenderCmdOpen:
            if ( nil != _mExtenderFileName )
            {
                NSInteger length = [_mExtenderFileName length];
                Byte payloadData[ length + 1];
                payloadData[0] = _mExtenderFileAccessType;
                [self setData: payloadData fromSource: (Byte *)[_mExtenderFileName UTF8String] fromIndex: 1 withSize: _mExtenderFileName.length];
                _mPayload = [[NSData alloc] initWithBytes: payloadData length: length + 1];
            }
            break;
        case ExtenderCmdClose:
        case ExtenderCmdFileSize:
        {
            Byte payloadData[1];
            payloadData[0] = _mExtenderFileHandle;
            _mPayload = [NSData dataWithBytes: payloadData length: 1];
        }
            break;
        case ExtenderCmdForceBootloaderModeExit:
        {
            Byte payloadData[1];
            payloadData[0] = 0x0;
            _mPayload = [[NSData alloc] initWithBytes: payloadData length: 1];
        }
            break;
        case ExtenderCmdWrite:
        {
            if ( nil != _mRawData )
            {
                Byte payloadData[_mRawData.length + 1];
                payloadData[0] = _mExtenderFileHandle;
                
                Byte rawDataBuffer[_mRawData.length];
                [_mRawData getBytes: rawDataBuffer length: _mRawData.length];
                [self setData: payloadData fromSource: rawDataBuffer fromIndex: 1 withSize: _mRawData.length];
                _mPayload = [[NSData alloc] initWithBytes: payloadData length: _mRawData.length + 1];
            }
        }
            break;
        case ExtenderCmdRead:
        {
            Byte payloadData[2];
            payloadData[0] = _mExtenderFileHandle;
            payloadData[1] = _mExtenderReadCount;
            _mPayload = [NSData dataWithBytes: payloadData length: 2];
        }
            break;
        case ExtenderCmdSeek:
        {
            Byte payloadData[5];
            payloadData[0] = _mExtenderFileHandle;
            
            NSData * ptrData = [iDevicesUtil intToByteArray: _mExtenderFilePointer];
            Byte ptrBytes[4];
            [ptrData getBytes: ptrBytes length: 4];
            
            [self setData: payloadData fromSource: ptrBytes fromIndex: 1 withSize: 5];
            _mPayload = [[NSData alloc] initWithBytes: payloadData length: 5];
        }
            break;
        case ExtenderCmdDelete:
        {
            if ( nil != _mExtenderFileName )
            {
                Byte payloadData[12];
                [self setData: payloadData fromSource: (Byte *)[_mExtenderFileName UTF8String] fromIndex: 0 withSize: 12];
                _mPayload = [[NSData alloc] initWithBytes: payloadData length: 12];
            }
        }
            break;
        case ExtenderCmdSetSettings:
        {
            Byte payloadData[_mRawData.length];
            Byte rawDataBuffer[_mRawData.length];
            [_mRawData getBytes: rawDataBuffer length: _mRawData.length];
            [self setData: payloadData fromSource: rawDataBuffer fromIndex: 0 withSize: _mRawData.length];
            _mPayload = [[NSData alloc] initWithBytes: payloadData length: _mRawData.length];
        }
            break;
        case ExtenderCmdStartFirmware:
        {
            Byte payloadData[3];
            
            payloadData[0] = _mUpdateLanguage;
            payloadData[1] = _mUpdateFirmware;
            payloadData[2] = _mUpdateCodePlug;
            
            _mPayload = [NSData dataWithBytes: payloadData length: 3];
        }
            break;
        case ExtenderCmdStartSettings:
        case ExtenderCmdEndSettings:
        case ExtenderCmdStartActivity:
        case ExtenderCmdEndActivity:
            //TestLog_SleepFiles
        case ExtenderCmdStartSleepSummary:
        case ExtenderCmdEndSleepSummary:
        case ExtenderCmdStartSleepKeyFile:
        case ExtenderCmdEndSleepKeyFile:
        case ExtenderCmdStartActigraphyFile:
        case ExtenderCmdEndActigraphyFile:
            //TestLog_SleepFiles
        case ExtenderCmdEndFirmware:
        case ExtenderCmdCancelFirmware:
        case ExtenderCmdStartWorkout:
        case ExtenderCmdEndWorkout:
        case ExtenderCmdRestartFirmware:
        case ExtenderCmdPauseFirmware:
        case ExtenderCmdFileSessionStart:
        case ExtenderCmdFileSessionEnd:
        case ExtenderCmdEnterBootloaderMode:
        case ExtenderCmdFactoryReset:
        case ExtenderCmdWatchReset:
        case ExtenderCmdReboot:
        {
            _mPayload = nil;
        }
            break;
            
        default:
            valid = false;
            break;
    }
    return valid;
}

- (void) setData: (Byte *) dest fromSource: (Byte *) src fromIndex: (int) destStartIndex withSize: (NSInteger) size
{
    if ( nil != dest && nil != src )
    {
        memcpy(&dest[destStartIndex], src, size);
    }
}

- (BOOL) CalculateChecksum: (BOOL) verify
{
    BOOL result = false;
    // Get the checksum calculation length
    NSInteger numBytes = (_mRawData.length - ChecksumLength);
    
    // Initialize variables
    Byte checksumEven = 0;
    Byte checksumOdd  = 0;
    
    // Iterate through all the even Bytes in the packet
    NSInteger rawDataLength = _mRawData.length;
    Byte rawData[rawDataLength];
    [_mRawData getBytes: rawData length: rawDataLength];
    
    for (int count = 1; count < numBytes; count += 2)
    {
        // Calculate even checksum
        checksumEven ^= rawData[count];
    }
    
    // Iterate through all the odd Bytes in the packet
    for (int count = 0; count < numBytes; count += 2)
    {
        // Calculate odd checksum
        checksumOdd ^= rawData[count];
    }
    
    // Determine if this is a verify operation or a copy operation
    if (verify == false)
    {
        // Place the checksum in the packet
        rawData[rawDataLength - ChecksumLength] = checksumEven;
        rawData[rawDataLength - ChecksumLength + 1] = checksumOdd;
        
        _mRawData = [[NSData alloc] initWithBytes: rawData length: rawDataLength];
        
        // Return true
        result = true;
    }
    else
    {
        // Determine if the checksum is correct
        if ((rawData[(rawDataLength - ChecksumLength)]     == checksumEven) &&
            (rawData[(rawDataLength - ChecksumLength + 1)] == checksumOdd))
        {
            // Return good checksum
            result =  true;
        }
        else
        {
            // Return bad checksum
            result =  false;
        }
    }
    return result;
}

- (void) SetLinkAddress: (PCCLinkAddress *) address
{
    // Set the new link address
    PCCHeader * header = [_mCommandPacket getHeader];
    [header setLinkAddress: address];
    
    // Create the raw data for the packet
    [self CreateCommandRawData];
}

- (BOOL) ValidatePacket
{
    // Initialize variables
    BOOL commandFound = [self ValidateCommand];
    if ( commandFound )
    {
        commandFound = [self ValidateSubCommand];
    }
    // Determine is the command was found
    if ( true == commandFound )
    {
        // Set valid flag
        _isValid = true;
        
        // Initialize the packet
        [self InitPacket];
    }
    
    return commandFound;
}

- (int) getPacketNumber
{
    int number = 0;
    if ( nil != _mCommandPacket )
    {
        number = [_mCommandPacket getHeader].PacketNumber;
    }
    else if ( nil != _mResponse )
    {
        number = [_mResponse getHeader].PacketNumber;
    }
    return number;
}

- (void) InitPacket
{
    // Set up initial header
    PCCHeader * header = [_mCommandPacket getHeader];
    
    header.Command      = _mCommand;
    header.PacketNumber = 0;
    
    [header.Info Set: (Byte)(PCCCommandInfoCommand | PCCCommandInfoLastPacket)];
    
    // Determine the source
    switch ([_mCommand Get])
    {
        case DataLink:
            header.Source = [[PCCPacketSource alloc] init: PACKET_SOURCE_PC ];
            break;
        case WhosThere:
        case ExtenderCmdOpen:
        case ExtenderCmdClose:
        case ExtenderCmdWrite:
        case ExtenderCmdRead:
        case ExtenderCmdSeek:
        case ExtenderCmdFileSize:
        case ExtenderCmdDelete:
        case ExtenderCmdSetSettings:
        case ExtenderCmdStartSettings:
        case ExtenderCmdEndSettings:
        case ExtenderCmdStartActivity:
        case ExtenderCmdEndActivity:
            //TestLog_SleepFiles
        case ExtenderCmdStartSleepSummary:
        case ExtenderCmdEndSleepSummary:
        case ExtenderCmdStartSleepKeyFile:
        case ExtenderCmdEndSleepKeyFile:
        case ExtenderCmdStartActigraphyFile:
        case ExtenderCmdEndActigraphyFile:
            //TestLog_SleepFIles
        case ExtenderCmdStartFirmware:
        case ExtenderCmdEndFirmware:
        case ExtenderCmdCancelFirmware:
        case ExtenderCmdStartWorkout:
        case ExtenderCmdEndWorkout:
        case ExtenderCmdRestartFirmware:
        case ExtenderCmdPauseFirmware:
        case ExtenderCmdFileSessionStart:
        case ExtenderCmdFileSessionEnd:
        case ExtenderCmdReadChargeInfo:
        case ExtenderCmdGetExtraFirmwareRevisions:
        case ExtenderCmdEnterBootloaderMode:
        case ExtenderCmdFactoryReset:
        case ExtenderCmdWatchReset:
        case ExtenderCmdForceBootloaderModeExit:
        case ExtenderCmdReboot:
            header.Source = [[PCCPacketSource alloc] init: PACKET_SOURCE_BLE_DEVICE ];
            break;
    }
}

- (void) CreateCommandRawData
{
    // Set the payload length in the packet
    NSInteger payloadLength = 0;
    
    if ( nil != _mPayload )
    {
        payloadLength = _mPayload.length;
    }
    [_mCommandPacket getHeader].PacketLength = payloadLength;
    
    // Create raw data buffer
    NSInteger rawDataBufferSize = [PCCHeader size] + payloadLength + ChecksumLength;
    Byte rawDataBuffer[rawDataBufferSize];
    
    // Copy the link address to the raw data manually to ensure endianness of the 2 Byte value
    rawDataBuffer[0] = (Byte)([[_mCommandPacket getHeader].linkAddress Get] >> 8);
    rawDataBuffer[1] = (Byte)[[_mCommandPacket getHeader].linkAddress Get];
    
    // Get a Byte pointer to the packet
    NSData * pPacketData = [_mCommandPacket get];
    if (pPacketData)
    {
        Byte packetDataBuffer[pPacketData.length];
        [pPacketData getBytes: packetDataBuffer];

        // Iterate through all the packet data: We start at offset 2, because the link address has already been copied to the raw data buffer
        for (int count = 2; count < [PCCHeader size]; count++)
        {
            // Copy the packet data into the buffer
            rawDataBuffer[count] = packetDataBuffer[count];
        }
    }
    // Iterate through the payload data
    
    Byte payloadBuffer[_mPayload.length];
    [_mPayload getBytes: payloadBuffer];

    for (int count = 0; count < payloadLength; count++)
    {
        // Copy the payload data to the raw data packet
        rawDataBuffer[(count + [PCCHeader size])] = payloadBuffer[count];
    }
    
    _mRawData = [NSData dataWithBytes: rawDataBuffer length: rawDataBufferSize];
}

- (BOOL) ValidateSubCommand
{
    BOOL valid = false;
    // Make sure there is at least one input parameter
    if ( _mSubCmd == 0 )
    {
        int value = [_mCommand Get];
        switch(value)
        {
            case WhosThere:
            case ExtenderCmdOpen:
            case ExtenderCmdClose:
            case ExtenderCmdWrite:
            case ExtenderCmdRead:
            case ExtenderCmdSeek:
            case ExtenderCmdFileSize:
            case ExtenderCmdDelete:
            case ExtenderCmdSetSettings:
            case ExtenderCmdStartSettings:
            case ExtenderCmdEndSettings:
            case ExtenderCmdStartActivity:
            case ExtenderCmdEndActivity:
                //TestLog_SleepFiles
            case ExtenderCmdStartSleepSummary:
            case ExtenderCmdEndSleepSummary:
            case ExtenderCmdStartSleepKeyFile:
            case ExtenderCmdEndSleepKeyFile:
            case ExtenderCmdStartActigraphyFile:
            case ExtenderCmdEndActigraphyFile:
                //TestLog_SleepFiles
            case ExtenderCmdStartFirmware:
            case ExtenderCmdEndFirmware:
            case ExtenderCmdCancelFirmware:
            case ExtenderCmdStartWorkout:
            case ExtenderCmdEndWorkout:
            case ExtenderCmdRestartFirmware:
            case ExtenderCmdPauseFirmware:
            case ExtenderCmdFileSessionStart:
            case ExtenderCmdFileSessionEnd:
            case ExtenderCmdReadChargeInfo:
            case ExtenderCmdGetExtraFirmwareRevisions:
            case ExtenderCmdEnterBootloaderMode:
            case ExtenderCmdFactoryReset:
            case ExtenderCmdWatchReset:
            case ExtenderCmdForceBootloaderModeExit:
            case ExtenderCmdReboot:
                valid = true;
                break;
            default: // Command is not valid
                valid = false;
                break;
        }
    }
    else
    {
        // The command should only be used by datalink layers, therefore the link address has been set by this point.
        switch([[_mCommandPacket getHeader].linkAddress Get])
        {                
            default:
                // Command is invalid
                valid = false;
                break;
        }
    }
    return valid;
}

- (void) CreateResponseRawData
{
    if ( _mRawData.length > PCCOMM_MAX_PACKET_LENGTH )
    {
        _isValid = false;
    }
    else
    {
        // Set packet as valid
        _isValid = true;
        [_mResponse set: _mRawData ];
    }
    
    // Determine if the packet is valid
    if (_isValid == true)
    {
        // Verify the checksum
        _isValid = [self CalculateChecksum: true];
    }
}
@end
