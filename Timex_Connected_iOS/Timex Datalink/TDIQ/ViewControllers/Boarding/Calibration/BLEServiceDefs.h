//
//  BLEServiceDefs.h
//  TimexBLEAgent
//
//  Created by Steve Williams on 4/16/15.
//  Copyright (c) 2015 Timex Group USA. All rights reserved.
//

#ifndef TimexBLEAgent_BLEServiceDefs_h
#define TimexBLEAgent_BLEServiceDefs_h

#define DEVICE_INFO_SERVICE_UUID                            @"180A"
    #define SYSTEM_ID_UUID                                  @"2A23"
    #define MODEL_NUM_UUID                                  @"2A24"
    #define SERIAL_NUM_UUID                                 @"2A25"
    #define FIRMWARE_REV_UUID                               @"2A26"
    #define HARDWARE_REV_UUID                               @"2A27"
    #define SOFTWARE_REV_UUID                               @"2A28"
    #define MANUFACTURER_NAME_UUID                          @"2A29"

// Defines for the TDLS
#define TDLS_UUID                                           @"876B199D-3504-46B2-A3EA-FD8A805B6A40"//TDLS

#define TDLS_DEVICESTATE_UUID                               @"36F8C520-ADE1-4C82-89F2-E8E6F993A2F4"//Device state
#define TDLS_DEVICESTATE_READ_LEN                           18

#define TDLS_DATA_IN_UUID1                                   @"DCB8A259-5E38-4B91-B9C7-D3F2E49EE061"//Data In 1
#define TDLS_DATA_IN_WRITE_LEN1                              18
#define TDLS_DATA_IN_UUID2                                  @"93771850-AFFF-4E93-A763-9F0CF8C576C9" ///Data In 2
#define TDLS_DATA_IN_WRITE_LEN2                             18
#define TDLS_DATA_IN_UUID3                                  @"072D8B9E-B43D-45E7-90CD-8F75A190000F" ///Data In 3
#define TDLS_DATA_IN_WRITE_LEN3                             18
#define TDLS_DATA_IN_UUID4                                  @"78383E18-5064-43D2-91DE-26B369FA435C" ///Data In 4
#define TDLS_DATA_IN_WRITE_LEN4                             10

#define TDLS_DATA_OUT_UUID1                                  @"4B67CC1C-3CE6-40B2-AD0A-B22F9FB523BB"//Data Out 1
#define TDLS_DATA_OUT_READ_LEN1                              18
#define TDLS_DATA_OUT_UUID2                                 @"CF14CE1A-1BE5-4C32-9BFF-679BCFAB9DCB" //Data Out 2
#define TDLS_DATA_OUT_READ_LEN2                             18
#define TDLS_DATA_OUT_UUID3                                 @"39EC97D0-FE59-487F-B520-8529BEF1FD7D" //Data Out 3
#define TDLS_DATA_OUT_READ_LEN3                             18
#define TDLS_DATA_OUT_UUID4                                 @"A809E205-8D93-4602-B0F6-FE40095484E3" //Data Out 4
#define TDLS_DATA_OUT_READ_LEN4                             10

//Other services Timex devices may support
#define TMS_UUID                                            @"0AAAD8B8-FEAC-4EB0-8CB1-D0BB10C407EC" //TMS
#define TNCS_UUID                                           @"41ABC25E-F9D5-4C5F-9E68-0498AA932C18" //TNCS
#define WF_FIRMWARE_UUID                                    @"A026EE01-0A7D-4AB3-97FA-F1500F9FEB8B" //WFFS
#define WF_DISPLAY_UUID                                     @"A026EE02-0A7D-4AB3-97FA-F1500F9FEB8B" //WFDS

#endif
