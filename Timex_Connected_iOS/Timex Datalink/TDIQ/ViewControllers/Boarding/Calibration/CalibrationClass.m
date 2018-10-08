//
//  CalibrationClass.m
//  timex
//
//  Created by Raghu on 05/07/16.
//  Copyright © 2016 iDevices, LLC. All rights reserved.
//

#import "CalibrationClass.h"
#import "OTLogUtil.h"

static CalibrationClass * instance = nil;

@implementation CalibrationClass

+(id) sharedInstance
{
    if (!instance)
    {
        instance = [[[self class] alloc] init];
    }
    
    return instance;
}

-(void)buildPCCOMMCalibMessage:(PCCOMM_Cmd_t)cmd
{
    NSMutableData *data = nil;
    PCCOMMHeader_t header = //Initialize parameters that are the same for all messages
    {
        .linkAddress = 0xA5A5,
        .packetNumber = 0x00,
        .source = MSG_SOURCE_PC,
        .command = cmd,
        .information = 0x81,
        .reserved = 0x00
    };
    PCCOMMPacket_t packet;
    
    switch(cmd)
    {
        case PC_RX_CMD_M328_ENTER_MODE_STATE:
        {
            header.packetLength = 0x02;
            packet.segment.payload.M328_enterOrExitModeState.mode = PC_MODE_CALIBRATION;
            packet.segment.payload.M328_enterOrExitModeState.state = PC_STATE_DEFAULT;
            break;
        }
        case PC_RX_CMD_M328_EXIT_MODE_STATE:
        {
            header.packetLength = 0x02;
            packet.segment.payload.M328_enterOrExitModeState.mode = PC_MODE_CALIBRATION;
            packet.segment.payload.M328_enterOrExitModeState.state = PC_STATE_DEFAULT;
            break;
        }
        
        case PC_RX_CMD_M328_MOVE_SPECIFIED_MOTOR:
        {
            header.packetLength = 0x04;
            packet.segment.payload.M328_moveMotor.motor = self.motorType;
            packet.segment.payload.M328_moveMotor.direction = self.motorDirection;
            packet.segment.payload.M328_moveMotor.steps = self.steps;
            break;
        }
        case PC_RX_CMD_M328_STOP_SPECIFIED_MOTOR:
        {
            header.packetLength = 0x01;
            packet.segment.payload.M328_stopMotor.motor = self.motorType;
            break;
        }
        case PC_RX_CMD_M328_MOVE_SPECIFIED_MOTOR_TO_POSITION:
        {
            header.packetLength = 0x05;
            
            break;
        }
        case PC_RX_CMD_M328_QUERY_SPECIFIED_MOTOR_POSITION:
        {
            header.packetLength = 0x01;
            packet.segment.payload.M328_getMotorPosition.motor = self.motorType;
            break;
        }
        case PC_RX_CMD_M328_SET_SPECIFIED_MOTOR_POSITION:
        {
            header.packetLength = 0x03;
            packet.segment.payload.M328_setMotorPosition.motor = self.motorType;
            packet.segment.payload.M328_setMotorPosition.position = 1;
            break;
        }
        default:
        {
            OTLog(@"Invalid PCCOMM Calibration Command");
            return;
        }
    };
    
    packet.segment.header = header;
    PCCCalculateChecksum(&packet);
    data = [NSMutableData dataWithBytes:&packet length:header.packetLength + PCCOMM_OVERHEAD]; //Build packet with data and be sure to account for overhead
    
    [self sendTDLSDataPacket:data];
}

- (void) sendTDLSDataPacket:(NSData*)data
{
    PeripheralDevice *peripheralDevice = [iDevicesUtil getConnectedTimexDevice];
    BLEPeripheral *blePeripheral = (BLEPeripheral *)peripheralDevice.peripheral;
    
    ServiceProxy* service = [blePeripheral findService: [PeripheralDevice timexDatalinkServiceId]];
    CBPeripheral *peripheral = [blePeripheral cbPeripheral];
    
    if(service == nil)
    {
        OTLog(@"Couldn't find TDLS Service on %@", peripheral.name);
    }
    
    NSData *chunk;
    CBCharacteristic *characteristic = nil;
    switch((int)(ceil(((double)data.length)/PCCOMM_SUBPACKET_SIZE)))
    {
            //Determine how many characteristics the data spans and send it accordingly
        case 4:
        {
            chunk = [data subdataWithRange:NSMakeRange((3 * PCCOMM_SUBPACKET_SIZE), (MIN((data.length - (3 * PCCOMM_SUBPACKET_SIZE)),PCCOMM_SUBPACKET_SIZE)))];
            
            BLECharacteristic* timexChar = (BLECharacteristic *)[service findCharacteristic: [CBUUID UUIDWithString:TDLS_DATA_IN_UUID4]];
            characteristic = [timexChar cbCharacteristic];
            
            if(characteristic == nil)
            {
                OTLog(@"Couldn't find DATA_IN_4 Characteristic on %@", peripheral.name);
            }
            [peripheral writeValue:chunk forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
            
            OTLog(@"Wrote %lu bytes on Characteristic 4", (unsigned long)chunk.length);
        }
        case 3:
        {
            chunk = [data subdataWithRange:NSMakeRange((2 * PCCOMM_SUBPACKET_SIZE), (MIN((data.length - (2 * PCCOMM_SUBPACKET_SIZE)),PCCOMM_SUBPACKET_SIZE)))];
            
            BLECharacteristic* timexChar = (BLECharacteristic *)[service findCharacteristic: [CBUUID UUIDWithString:TDLS_DATA_IN_UUID3]];
            characteristic = [timexChar cbCharacteristic];
            
            if(characteristic == nil)
            {
                OTLog(@"Couldn't find DATA_IN_3 Characteristic on %@", peripheral.name);
            }
            
            [peripheral writeValue:chunk forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
            
            OTLog(@"Wrote %lu bytes on Characteristic 3", (unsigned long)chunk.length);
        }
        case 2:
        {
            chunk = [data subdataWithRange:NSMakeRange((1 * PCCOMM_SUBPACKET_SIZE), (MIN((data.length - (1 * PCCOMM_SUBPACKET_SIZE)),PCCOMM_SUBPACKET_SIZE)))];
            
            ;
            
            BLECharacteristic* timexChar = (BLECharacteristic *)[service findCharacteristic: [CBUUID UUIDWithString:TDLS_DATA_IN_UUID2]];
            characteristic = [timexChar cbCharacteristic];
            if(characteristic == nil)
            {
                OTLog(@"Couldn't find DATA_IN_2 Characteristic on %@", peripheral.name);
            }
            
            [peripheral writeValue:chunk forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
            
            OTLog(@"Wrote %lu bytes on Characteristic 2", (unsigned long)chunk.length);
        }
        case 1:
        {
            chunk = [data subdataWithRange:NSMakeRange((0 * PCCOMM_SUBPACKET_SIZE), (MIN((data.length - (0 * PCCOMM_SUBPACKET_SIZE)),PCCOMM_SUBPACKET_SIZE)))];
            
            BLECharacteristic* timexChar = (BLECharacteristic *)[service findCharacteristic: [CBUUID UUIDWithString:TDLS_DATA_IN_UUID1]];
            characteristic = [timexChar cbCharacteristic];
            
            if(characteristic == nil)
            {
                OTLog(@"Couldn't find DATA_IN_2 Characteristic on %@", peripheral.name);
            }
            
            [peripheral writeValue:chunk forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
            
            OTLog(@"Wrote %lu bytes on Characteristic 1", (unsigned long)chunk.length);
        }
            
    }
}

-(void)enterCalibrationMode
{
    [self buildPCCOMMCalibMessage:PC_RX_CMD_M328_ENTER_MODE_STATE];
}

-(void)exitCalibrationMode
{
    [self buildPCCOMMCalibMessage:PC_RX_CMD_M328_EXIT_MODE_STATE];
}



-(NSInteger)getNumberOfStepsToRotate
{
    if (self.motorType == Hand_Hour)
    {
        return 20;
    }
    else if (self.motorType == Hand_Minute)
    {
        return 4;
    }
    
    else if (self.motorType == Hand_SubDial)
    {
        return 2;
    }
    
    return 1;
}

@end
