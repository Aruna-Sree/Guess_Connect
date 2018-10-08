//
//  SYSBLOCKSettings.h
//  timex
//
//  Created by Nick Graff on 10/14/16.
//  Copyright © 2016 iDevices, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SYSBLOCKSettings : NSObject
{
    int sChecksum;
    int sBootLoaderState;
    long sModelNumber;
    short sRevision;
    long sBoardSerialNumber;
    int sBootLoaderRevision;
    short sSystemHealthRevision;
    short sWatchdogResets;
    short sPowerOnResets;
    short sLowPowerResets;
    short sSystemResets;
}

- (id) init: (NSData *) inData;
@end
