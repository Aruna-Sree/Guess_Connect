//
//  PCCOMM_Utils.h
//  Timex Profile Test Tool
//
//  Created by Steve Williams on 9/17/13.
//  Copyright (c) 2013 Timex Group USA. All rights reserved.
//

#ifndef Timex_Profile_Test_Tool_PCCOMM_Utils_h
#define Timex_Profile_Test_Tool_PCCOMM_Utils_h

#include "PCCOMMDefines.h"
#include <stdbool.h>

extern void PCCCalculateChecksum(PCCOMMPacket_t* pPacket);
extern bool PCCVerifyChecksum(PCCOMMPacket_t* pPacket);

#endif
