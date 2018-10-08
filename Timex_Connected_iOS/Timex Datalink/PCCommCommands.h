//
//  PCCommCommands.h
//  Timex Connected
//
//  Created by Lev Verbitsky on 1/20/14.
//  Copyright (c) 2014 iDevices, LLC. All rights reserved.
//

#ifndef Timex_Datalink_PCCommCommands_h
#define Timex_Datalink_PCCommCommands_h

#define Unrecognized                0xFF
#define ReadMemory                  0x81
#define WriteRAM                    0x82
#define INTEEPROM                   0x83
#define ExternalDevice              0x84
#define ForceBootloader             0x85
#define SystemLog                   0x86
#define BulkTransfer                0x87
#define DataLink                    0x89
#define GetStatus                   0xC0
#define EraseProgramMemory          0xC1
#define WriteProgramMemory          0xC2
#define EraseCodeplugMemory         0xC3
#define WriteCodeplugMemory         0xC4
#define WhosThere                   0xFE
#define ExtenderCmdOpen             0x12
#define ExtenderCmdClose            0x13
#define ExtenderCmdWrite            0x14
#define ExtenderCmdRead             0x15
#define ExtenderCmdSeek             0x16
#define ExtenderCmdFileSize         0x17
#define ExtenderCmdDelete           0x18
#define ExtenderCmdFileSessionStart 0x19
#define ExtenderCmdFileSessionEnd   0x1A
#define ExtenderCmdSetSettings      0x21
#define ExtenderCmdStartSettings    0x22
#define ExtenderCmdEndSettings      0x23
#define ExtenderCmdStartFirmware    0x24
#define ExtenderCmdEndFirmware      0x25
#define ExtenderCmdStartWorkout     0x26
#define ExtenderCmdEndWorkout       0x27
#define ExtenderCmdRestartFirmware  0x28
#define ExtenderCmdPauseFirmware    0x29
#define ExtenderCmdCancelFirmware   0x2A
#define ExtenderCmdReadChargeInfo   0x31
#define ExtenderCmdStartActivity    0x32
#define ExtenderCmdEndActivity      0x33
//TestLog_SleepFiles
#define ExtenderCmdStartSleepSummary    0x37
#define ExtenderCmdEndSleepSummary      0x38
#define ExtenderCmdStartSleepKeyFile    0x39
#define ExtenderCmdEndSleepKeyFile      0x3A
#define ExtenderCmdStartActigraphyFile  0x41 // Calibration enter command for M328
#define ExtenderCmdEndActigraphyFile    0x42 // Calibration exit command for M328
//TestLog_SleepFiles
#define ExtenderCmdWatchReset                   0x34
#define ExtenderCmdEnterBootloaderMode          0x35
#define ExtenderCmdFactoryReset                 0x36
#define ExtenderCmdGetExtraFirmwareRevisions    0x40
#define ExtenderCmdForceBootloaderModeExit      0x85
#define ExtenderCmdReboot                       0x80

#define PCCCommandInfoCommand       0x01
#define PCCCommandInfoMultiPacket   0x02
#define PCCCommandInfoNack          0x08
#define PCCCommandInfoBulkTransfer  0x20
#define PCCCommandInfoLastPacket    0x80

#define PACKET_SOURCE_WATCH         0x01
#define PACKET_SOURCE_PC            0x02
#define PACKET_SOURCE_BLE_RADIO     0x03
#define PACKET_SOURCE_BLE_DEVICE    0x04

#define PCC_LINKADDRESS_USB         0x0
#define PCC_LINKADDRESS_NFC         0x1
#define PCC_LINKADDRESS_BLUETOOTH   0x2
#define PCC_LINKADDRESS_BLE         0xA5A5

#define ACTION_READ_SETTINGS_FILE   1
#define ACTION_READ_CHRONOS_FILE    2
#define ACTION_WRITE_SETTINGS_FILE  3
#define ACTION_WRITE_APPT_FILE      4
#define ACTION_WRITE_FIRMWARE_FILE  5
#define ACTION_WRITE_LANGUAGE_FILE  6
#define ACTION_WRITE_CODEPLUG_FILE  7
#define ACTION_WRITE_TIMEOFDAY      8
#define ACTION_GET_DEVICE_INFO      9
#define ACTION_READ_M053_FULL_FILE   10
#define ACTION_WRITE_M053_FULL_FILE  11
#define ACTION_WRITE_M053_APPTS_FILE 12
#define ACTION_WRITE_M053_TIME       13
#define ACTION_GET_DEVICE_CHARGE_INFO 14
#define ACTION_PAUSE_FIRMWARE         15
#define ACTION_RESUME_FIRMWARE        16
#define ACTION_GET_DEVICE_INFO_FIRMWARE 17
#define ACTION_GET_DEVICE_CHARGE_INFO_FIRMWARE 18
#define ACTION_READ_M372_ACTIVITY_DATA 19
#define ACTION_WRITE_BOOTLOADER_FILE 20
#define ACTION_GET_DEVICE_INFO_BOOTLOADER_STATUS 21
#define ACTION_READ_M372_PRE_FIRMWARE_CHARGE_INFO 22
#define ACTION_READ_M372_SLEEP_SUMMARY 23//TestLog_SleepFiles
#define ACTION_READ_M372_SLEEP_KEY_FILE 24//TestLog_SleepFiles
#define ACTION_READ_M372_ACTIGRAPHY_FILES 25//TestLog_SleepFiles
#define ACTION_READ_M372_HOUR_DATA 26//TestLog_SleepFiles
#define ACTION_READ_M328_ACTIVITY_DATA 27
#define ACTION_READ_M328_PRE_FIRMWARE_CHARGE_INFO 28
#define ACTION_READ_SYSBLOCK_FILE   29

#define SUBACTION_NEW               0
#define SUBACTION_WHOS_THERE        1
#define SUBACTION_START             2
#define SUBACTION_OPEN_FILE         3
#define SUBACTION_GET_FILE_SIZE     4
#define SUBACTION_SEEK_FILE         5
#define SUBACTION_FILE_IO           6
#define SUBACTION_CLOSE_FILE        7
#define SUBACTION_END               8
#define SUBACTION_DELETE_FILE       9
#define SUBACTION_SET_SETTINGS      10
#define SUBACTION_CANCEL_FILE_IO    11
#define SUBACTION_GET_CHARGE_INFO   12
#define SUBACTION_START_FILE_SESSION_M372 13
#define SUBACTION_END_FILE_SESSION_M372   14
#define SUBACTION_GET_EXTENDED_FIRMWARE_VERSION_INFO 15
#define SUBACTION_REBOOT            16
#define SUBACTION_DONE              100

#define SETTINGS_VERSION            005
#define APPOINTMENTS_VERSION        003
#define CHRONOS_VERSION             001

#define M372_SETTINGS_VERSION       001
#define M372_ACTIVITY_VERSION       001

#define M328_SETTINGS_VERSION       3
#define M328_ACTIVITY_VERSION       001

//TestLog_sleepFiles
#define M372_SLEEP_SUMMARY_VERSION  002
#define M372_SLEEP_KEY_VERSION      001
#define M372_SLEEP_ACT_DATA_VERSION 01

#define M328_SLEEP_SUMMARY_VERSION  002
#define M328_SLEEP_KEY_VERSION      001
#define M328_SLEEP_ACT_DATA_VERSION 01


#define FILE_ACCESS_READ_ONLY       0x1
#define FILE_ACCESS_READ_WRITE      0x2
#define FILE_ACCESS_CREATE          0x3

#define BTS_CHARACTERISTIC_SIZE     18
#define PCC_PACKET_HEADER_SIZE      10
#define PCC_PACKET_PAYLOAD_SIZE_MAX 48

#define ERROR_NULL_DEVICE           -100
#define ERROR_NOT_CONNECTED         -101
#define ERROR_TIMEOUT               -102

#endif
