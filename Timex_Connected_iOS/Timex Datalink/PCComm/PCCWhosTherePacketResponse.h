//
//  PCCWhosTherePacketResponse.h
//  Timex Connected
//
//  Created by Lev Verbitsky on 1/20/14.
//  Copyright (c) 2014 iDevices, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PCCWhosTherePacketModeStatus.h"

@interface PCCWhosTherePacketResponse : NSObject
{
    PCCWhosTherePacketModeStatus * Mode;
    
    int Rsvd;
    Byte MajorRev;
    Byte MinorRev;
    Byte Build;
    Byte CPMajor;
    Byte CPMinor;
    Byte PlatformMajor;
    Byte PlatformMinor;
    Byte CPRevision2;
    Byte CPRevision3;
    int Rsvd2;
    Byte ModelNumber;
    Byte ModelNumber2;
    Byte ModelNumber3;
    Byte ModelNumber4;
    Byte ProductRevision;
    Byte ProductRevision2;
    Byte ProductRevision3;
    Byte ProductRevision4;
    int Rsvd3;
    int Rsvd4;
    Byte GPSRevision;
    Byte GPSRevision2;
    Byte GPSRevision3;
    Byte GPSRevision4;
    Byte GPSRevision5;
    Byte GPSRevision6;
    Byte GPSRevision7;
    Byte GPSRevision8;
    Byte Serial;
    Byte Serial2;
    Byte Serial3;
    Byte Serial4;
    Byte Serial5;
    Byte Serial6;
    Byte Serial7;
    Byte Serial8;
}
@end
