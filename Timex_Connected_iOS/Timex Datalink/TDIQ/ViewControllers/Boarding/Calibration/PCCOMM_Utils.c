//
//  PCCOMM_Utils.c
//  Timex Profile Test Tool
//
//  Created by Steve Williams on 9/17/13.
//  Copyright (c) 2013 Timex Group USA. All rights reserved.
//

#include <stdio.h>
#include "PCCOMM_Utils.h"

/* Calculates a checksum and appends it to the packet */
void PCCCalculateChecksum(PCCOMMPacket_t* pPacket)
{
	// Local variables
	uint8_t count;
	uint8_t maxCnt;
	uint8_t checksumEven = 0;
	uint8_t checksumOdd  = 0;
    
	// Get the max count of the iteration
	maxCnt = (pPacket->segment.header.packetLength + PCCOMM_HEADER_SIZE);
    
	// Iterate through the even bytes in the packet
	for (count = 1; count < maxCnt; count += 2)
	{
		// Calculate even checksum
		checksumEven ^= pPacket->packet[count];
	}
    
	// Iterate through the odd bytes in the packet
	for (count = 0; count < maxCnt; count += 2)
	{
		// Calculate odd checksum
		checksumOdd ^= pPacket->packet[count];
	}
    
	// Place the checksums in the packet
	pPacket->packet[maxCnt]     = checksumEven;
	pPacket->packet[maxCnt + 1] = checksumOdd;
}

/* Verifies a received packet checksum */
bool PCCVerifyChecksum(PCCOMMPacket_t* pPacket)
{
	// Local variables
	uint8_t count;
	uint8_t maxCnt;
	uint8_t checksumEven = 0;
	uint8_t checksumOdd  = 0;
    
	// Determine if the length specified in the packet is valid
	if (pPacket->segment.header.packetLength > PCCOMM_PAYLOAD_SIZE)
	{
		// Length parameter is invalid
		return false;
	}
	else
	{
		// Set the max count of the iteration
		maxCnt = (pPacket->segment.header.packetLength + PCCOMM_HEADER_SIZE);
	}
    
	// Iterate through the even bytes in the packet
	for (count = 1; count < maxCnt; count += 2)
	{
		// Calculate even checksum
		checksumEven ^= pPacket->packet[count];
	}
    
	// Iterate through the odd bytes in the packet
	for (count = 0; count < maxCnt; count += 2)
	{
		// Calculate odd checksum
		checksumOdd ^= pPacket->packet[count];
	}
    
	// Determine if the checksums are valid
	if ((checksumEven == pPacket->packet[maxCnt]) && (checksumOdd == pPacket->packet[maxCnt + 1]))
	{
		// Checksum is valid
		return true;
	}
	else
	{
		// Checksum is invalid
		return false;
	}
}