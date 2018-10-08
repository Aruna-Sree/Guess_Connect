//
//  PCCOMMDefines.h
//  Timex BLE Agent
//
//  Created by Steve Williams on 4/17/15.
//  Copyright (c) 2015 Timex Group USA. All rights reserved.
//

#ifndef Timex_BLE_Agent_PCCOMMDefines_h
#define Timex_BLE_Agent_PCCOMMDefines_h

#define	PCCOMM_PACKET_SIZE		64
#define PCCOMM_HEADER_SIZE		8
#define PCCOMM_CRC_SIZE			2
#define PCCOMM_OVERHEAD			PCCOMM_HEADER_SIZE + PCCOMM_CRC_SIZE
#define PCCOMM_PAYLOAD_SIZE		PCCOMM_PACKET_SIZE - (PCCOMM_OVERHEAD)
#define PCCOMM_SUBPACKET_SIZE   18
#define WRITE_DATA_PAYLOAD_SIZE 48
#define READ_DATA_PAYLOAD_SIZE  48

typedef enum
{
    PC_RX_CMD_FILE_OPEN             = 0x12,
    PC_RX_CMD_FILE_CLOSE            = 0x13,
    PC_RX_CMD_FILE_WRITE            = 0x14,
    PC_RX_CMD_FILE_READ             = 0x15,
    PC_RX_CMD_FILE_SEEK             = 0x16,
    PC_RX_CMD_FILE_SIZE             = 0x17,
    PC_RX_CMD_FILE_DELETE           = 0x18,
    PC_RX_CMD_FILE_SESSION_START    = 0x19,
    PC_RX_CMD_FILE_SESSION_END      = 0x1A,
    PC_RX_CMD_FILE_START_SETTINGS   = 0x22,
    PC_RX_CMD_FILE_END_SETTINGS     = 0x23,
    PC_RX_CMD_FILE_START_FIRMWARE   = 0x24,
    PC_RX_CMD_FILE_END_FIRMWARE     = 0x25,
    PC_RX_CMD_GET_STATE_OF_CHARGE   = 0x31,
    PC_RX_CMD_FILE_START_ACTIVITY   = 0x32,
    PC_RX_CMD_FILE_END_ACTIVITY     = 0x33,
    PC_RX_CMD_FILE_START_SLEEP      = 0x37,
    PC_RX_CMD_FILE_END_SLEEP        = 0x38,
    PC_RX_CMD_REBOOT                = 0x80,
    PC_RX_CMD_FORCEBLMODE           = 0x85,
    PC_RX_CMD_WHOSTHERE             = 0xFE,
    
    PC_RX_CMD_M372_ENTER_BOOTLOADER                 = 0x35,
    PC_RX_CMD_M372_WATCH_RESET                      = 0x34,
    PC_RX_CMD_M372_FACTORY_RESET                    = 0x36,
    PC_RX_CMD_M372_GET_EXTRA_FW_REVISIONS           = 0x40,
    
    PC_RX_CMD_M328_ENTER_MODE_STATE                 = 0x41,
    PC_RX_CMD_M328_EXIT_MODE_STATE                  = 0x42,
    PC_RX_CMD_M328_MOVE_SPECIFIED_MOTOR             = 0x43,
    PC_RX_CMD_M328_STOP_SPECIFIED_MOTOR             = 0x44,
    PC_RX_CMD_M328_MOVE_SPECIFIED_MOTOR_TO_POSITION = 0x45,
    PC_RX_CMD_M328_QUERY_SPECIFIED_MOTOR_POSITION   = 0x46,
    PC_RX_CMD_M328_SET_SPECIFIED_MOTOR_POSITION     = 0x47,
    
    PC_RX_CMD_M328_START_COUNTDOWN_TIMER = 0x50,
    PC_RX_CMD_M328_STOP_COUNTDOWN_TIMER  = 0x51,
    PC_RX_CMD_M328_SET_COUNTDOWN_TIMER   = 0x52,
    PC_RX_CMD_M328_GET_COUNTDOWN_TIMER   = 0x53
} PCCOMM_Cmd_t;

typedef enum
{
    MODEL_UNKNOWN,
    MODEL_M054,
    MODEL_M372,
    MODEL_M372_SLEEP,
    MODEL_M327,
    MODEL_M328
}PCCOMM_ModelNum_t;

typedef struct _PCCOMMHeader
{
    uint16_t linkAddress;
    
    uint8_t packetLength;
    uint8_t packetNumber;
    uint8_t source;
    uint8_t command;
    uint8_t information;
    uint8_t reserved;
} PCCOMMHeader_t;

typedef struct _PCCOMMPayload
{
    union
    {
        uint8_t data[PCCOMM_PAYLOAD_SIZE];
        struct
        {
            uint8_t modeStatus;
            uint8_t unused1[4];
            uint8_t sysMajorRev;
            uint8_t sysMinorRev;
            uint8_t sysBuildNum;
            uint8_t CPMajorRev;
            uint8_t CPMinorRev;
            uint8_t CPPlatformMajorRev;
            uint8_t CPPlatformMinorRev;
            uint8_t CPRevision2;
            uint8_t CPRevision;
            uint8_t unused2[2];
            uint8_t modelNum[4];
            uint8_t productRev[4];
            uint8_t hardwareRev;
            uint8_t reserved3[7];
            uint8_t GPSRev[8];
            uint8_t serialNumber[8];
        }whosThere;
        struct
        {
            uint8_t ackOrNack;
            uint8_t N;
            uint8_t rev1[8];
            uint8_t rev2[8];
            uint8_t rev3[8];
            uint8_t rev4[8];
            uint8_t rev5[8];
        }M372_ExtraFWRevs;
        struct
        {
            uint8_t ackOrNack;
            uint8_t handle;
            uint8_t reserved;
            uint8_t statusUSB;
            float   current;
            float   charge;
            float   temperature;
            float   voltage;
        }stateOfCharge;
        struct
        {
            uint8_t accessType;
            char fileName[12];
        }openFile;
        struct
        {
            uint8_t ackOrNack;
            uint8_t fileHandle;
            uint8_t errorCode;
        }openFileResponse;
        struct
        {
            char fileName[12];
        }deleteFile;
        struct
        {
            uint8_t ackOrNack;
            uint8_t reserved;
            uint8_t errorCode;
        }deleteFileResponse;
        struct
        {
            uint8_t fileHandle;
        }closeFile;
        struct
        {
            uint8_t ackOrNack;
            uint8_t fileHandle;
            uint8_t errorCode;
        }closeFileResponse;
        struct
        {
            uint8_t fileHandle;
            uint8_t data[WRITE_DATA_PAYLOAD_SIZE];
        }writeFile;
        struct
        {
            uint8_t ackOrNack;
            uint8_t fileHandle;
            uint8_t errorCode;
        }writeFileResponse;
        struct
        {
            uint8_t fileHandle;
            uint8_t numBytes;
        }readFile;
        struct
        {
            uint8_t ackOrNack;
            uint8_t fileHandle;
            uint8_t data[READ_DATA_PAYLOAD_SIZE];
        }readFileResponse;
        struct
        {
            uint8_t fileHandle;
        }getFileSize;
        struct
        {
            uint8_t ackOrNack;
            uint8_t fileHandle;
            uint8_t fileSize[4];
        }getFileSizeResponse;
        struct
        {
            uint8_t ackOrNack;
            uint8_t reserved;
            uint8_t errorCode;
        }startFileResponse;
        struct
        {
            uint8_t ackOrNack;
            uint8_t reserved;
            uint8_t errorCode;
        }startSessionResponse;
        struct
        {
            uint8_t ackOrNack;
            uint8_t reserved;
            uint8_t errorCode;
        }endFileResponse;
        struct
        {
            uint8_t ackOrNack;
            uint8_t reserved;
            uint8_t errorCode;
        }endSessionResponse;
        struct
        {
            uint8_t mode;
            uint8_t state;
        }M328_enterOrExitModeState;
        struct
        {
            uint8_t ackOrNack;
            uint8_t errorCode;
        }M328_enterOrExitModeStateResponse;
        struct
        {
            uint8_t motor;
            uint8_t direction;
            uint16_t steps;
        }M328_moveMotor;
        struct
        {
            uint8_t ackOrNack;
            uint8_t errorCode;
        }M328_moveMotorResponse;
        struct
        {
            uint8_t motor;
        }M328_stopMotor;
        struct
        {
            uint8_t ackOrNack;
            uint8_t errorCode;
        }M328_stopMotorResponse;
        struct
        {
            uint8_t motor;
        
        }M328_getMotorPosition;
        struct
        {
            uint8_t motor;
            uint8_t mode;
            uint16_t position;
            uint8_t positionQueryActive;
        }M328_MoveMotorToPosition;
        struct
        {
            uint8_t ackOrNack;
            uint8_t errorCode;
        }M328_MoveMotorToPositionResponse;
        struct
        {
            uint8_t ackOrNack;
            uint8_t errorCode;
            uint16_t position;
        }M328_getMotorPositionResponse;
        struct
        {
            uint8_t motor;
            uint16_t position;
        }M328_setMotorPosition;
        struct
        {
            uint8_t ackOrNack;
            uint8_t errorCode;
        }M328_setMotorPositionResponse;
        struct
        {
            uint8_t timerNumber;
            uint8_t reserved;
        }M328_startCountdownTimer;
        struct
        {
            uint8_t ackOrNack;
            uint8_t timerNumberOrErrorCode;
        }M328_startCountdownTimerResponse;
        struct
        {
            uint8_t timerNumber;
            uint8_t reserved;
        }M328_stopCountdownTimer;
        struct
        {
            uint8_t ackOrNack;
            uint8_t timerNumberOrErrorCode;
        }M328_stopCountdownTimerResponse;
        struct
        {
            uint8_t hour;
            uint8_t minute;
            uint8_t second;
            uint8_t action;
            uint8_t timerNumber;
        }M328_setCountdownTimer;
        struct
        {
            uint8_t ackOrNack;
            uint8_t timerNumberOrErrorCode;
        }M328_setCountdownTimerResponse;
        struct
        {
            uint8_t timerNumber;
            uint8_t reserved;
        }M328_getCountdownTimer;
        struct
        {
            uint8_t ackOrNack;
            uint8_t hourOrErrorCode;
            uint8_t minute;
            uint8_t second;
            uint8_t state;
            uint8_t timerNumber;
            uint8_t numberOfTimers;
        }M328_getCountdownTimerResponse;
    };
} PCCOMMPayload_t;

typedef struct _PCCOMMPacket
{
    union
    {
        uint8_t	packet[PCCOMM_PACKET_SIZE];
        struct
        {
            PCCOMMHeader_t header;
            PCCOMMPayload_t payload;
            uint16_t checksum;
        }segment;
    };
} PCCOMMPacket_t;

typedef enum
{
    MSG_SOURCE_WATCH = 0x01,
    MSG_SOURCE_PC = 0x02,
    MSG_SOURCE_BLE_RADIO = 0x03,
    MSG_SOURCE_BLE_DEVICE = 0x04
} MsgSource_t;

typedef enum
{
    FILE_READ_ONLY = 0x01,
    FILE_READ_WRITE = 0x02,
    FILE_CREATE = 0x03
} PCCOMM_FileAccess_t;

typedef enum
{
    FILE_TYPE_UNKNOWN  = 0x00,
    FILE_TYPE_SETTINGS = 0x01,
    FILE_TYPE_FIRMWARE = 0x02,
    FILE_TYPE_ACTIVITY = 0x03,
    FILE_TYPE_RADIO_FW = 0x04,
    FILE_TYPE_SLEEP    = 0x05,
    FILE_TYPE_CODEPLUG = 0x06,
    FILE_TYPE_ACT_LIB  = 0x07
} PCCOMM_FileType_t;

typedef enum
{
    PC_RX_ACK = 0x00,
    PC_RX_NACK = 0x01
} AckOrNack_t;

typedef enum
{
    USB_NOT_PLUGGED_IN = 0x00,
    USB_PLUGGED_IN_NOT_ENUMERATED = 0x01,
    USB_PLUGGED_IN_ENUMERATED = 0x02,
    USB_PLUGGED_IN_ENUM_IN_PROGRESS = 0x03
} USBState_t;

typedef enum
{
    QA_MOTOR_NONE,  // 0
    QA_MOTOR_1,		// 1, MINUTE HAND
    QA_MOTOR_2,		// 2, HOUR HAND
    QA_MOTOR_3,		// 3, SUBDIAL HAND
    QA_TOD_MOTOR	// 4, SECONDS HAND
} MotorNum_t;

typedef enum
{
    QA_CW_DIR 	= 0,
    QA_CCW_DIR 	= 1	// Invalid for SECONDS
} MotorDir_t;

typedef enum
{
    QA_MOVE_CW,			// 0
    QA_MOVE_CCW,		// 1
    QA_MOVE_NORMAL,		// 2
    QA_MOVE_SPEEDOMETER,// 3
    QA_MOVE_SHORT,		// 4
    QA_MOVE_CONTINUOUS	// 5
} MotorMoveMode_t;

typedef enum
{
    PC_MODE_CALIBRATION = 1,
} PCCOMM_Mode_t;

typedef enum
{
    PC_STATE_DEFAULT = 1,
} PCCOMM_State_t;

/*
#define	PCCOMM_PACKET_SIZE		64
#define PCCOMM_HEADER_SIZE		8
#define PCCOMM_CRC_SIZE			2
#define PCCOMM_OVERHEAD			PCCOMM_HEADER_SIZE + PCCOMM_CRC_SIZE
#define PCCOMM_PAYLOAD_SIZE		PCCOMM_PACKET_SIZE - (PCCOMM_OVERHEAD)
#define PCCOMM_SUBPACKET_SIZE   18
#define WRITE_DATA_PAYLOAD_SIZE 48
#define READ_DATA_PAYLOAD_SIZE  48

typedef struct _PCCOMMHeader
{
    uint16_t linkAddress;
    
    uint8_t packetLength;
    uint8_t packetNumber;
    uint8_t source;
    uint8_t command;
    uint8_t information;
    uint8_t reserved;
} PCCOMMHeader_t;

typedef struct _PCCOMMPayload
{
    union
    {
        uint8_t data[PCCOMM_PAYLOAD_SIZE];
        struct
        {
            uint8_t accessType;
            uint8_t fileName[12];
        }openFile;
        struct
        {
            uint8_t ackOrNack;
            uint8_t fileHandle;
            uint8_t errorCode;
        }openFileResponse;
        struct
        {
            uint8_t fileHandle;
        }closeFile;
        struct
        {
            uint8_t ackOrNack;
            uint8_t fileHandle;
            uint8_t errorCode;
        }closeFileResponse;
        struct
        {
            uint8_t fileHandle;
            uint8_t data[WRITE_DATA_PAYLOAD_SIZE];
        }writeFile;
        struct
        {
            uint8_t ackOrNack;
            uint8_t fileHandle;
            uint8_t errorCode;
        }writeFileResponse;
        struct
        {
            uint8_t fileHandle;
            uint8_t numBytes;
        }readFile;
        struct
        {
            uint8_t ackOrNack;
            uint8_t fileHandle;
            uint8_t data[READ_DATA_PAYLOAD_SIZE];
        }readFileResponse;
        struct
        {
            uint8_t fileHandle;
        }getFileSize;
        struct
        {
            uint8_t ackOrNack;
            uint8_t fileHandle;
            uint8_t fileSize[4];
        }getFileSizeResponse;
        struct
        {
            uint8_t UpdateLanguage;
            uint8_t UpdateFirmware;
            uint8_t UpdateCodeplug;
        }startFileNotify;
        struct
        {
            uint8_t ackOrNack;
        }startFileNotifyResponse;
    };
    
} PCCOMMPayload_t;

typedef struct _PCCOMMPacket
{
    union
    {
        uint8_t	packet[PCCOMM_PACKET_SIZE];
        struct
        {
            PCCOMMHeader_t header;
            PCCOMMPayload_t payload;
            uint16_t checksum;
        }segment;
    };
} PCCOMMPacket_t;

typedef enum
{
    FILE_READ_ONLY = 0x01,
    FILE_READ_WRITE = 0x02,
    FILE_CREATE = 0x03
} PCCOMM_FileAccess_t;


typedef enum
{
    MSG_SOURCE_WATCH = 0x01,
    MSG_SOURCE_PC = 0x02,
    MSG_SOURCE_BLE_RADIO = 0x03,
    MSG_SOURCE_BLE_DEVICE = 0x04
} MsgSource_t;

typedef enum
{
    PC_RX_ACK = 0x00,
    PC_RX_NACK = 0x01
} AckOrNack_t;

typedef enum
{
    FILE_OPEN_CMD = 0x12,
    FILE_CLOSE_CMD = 0x13,
    FILE_WRITE_CMD = 0x14,
    FILE_READ_CMD = 0x15,
    FILE_SIZE_CMD = 0x17,
    START_SET_CMD = 0x22,
    END_SET_CMD = 0x23,
    START_FRMWRE_CMD = 0x24,
    END_FRMWRE_CMD = 0x25,
    START_WRKOUT_CMD = 0x26,
    END_WKOUT_CMD = 0x27,
    WHOSTHERE_CMD = 0xFE
} PCCOMM_LocalCmds_t;*/

#endif
