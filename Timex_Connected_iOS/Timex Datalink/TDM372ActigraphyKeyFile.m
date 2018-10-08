//
//  M372ActigraphyKeyFile.m
//  SleepTrackerFilesTool
//
//  Created by Diego Santiago on 3/14/16.
//  Copyright © 2016 Diego Santiago. All rights reserved.
//
/**
 * From the spec:
 * The reason the Actigraphy Key File exists is to make it easier for the phone to download only
 * the Actigraphy Files it needs. To minimize current and transfer time, we only want to upload
 * new files to the phone. This file is designed to act as a key to the Actigraphy Files, so the
 * phone will know the date an Actigraphy File was created without having to open up the individual
 * file and read the date from them. The name of the file will be of the form M372Kxxx.SLP,
 * where xxx is the file revision number. The file will consist of 8 records, with Record 0
 * containing the date corresponding to M372A0xx.SLP, Record 1 containing the date corresponding to
 * M372A1xx.SLP, etc.
 *
 //    typedef struct
 //            {
 //            uint8_t MaxNumFiles; // (0 - 255)
 //            uint8_t FileNameIndex; // (0 - 7)
 //            uint8_t reserved[3]; // (3)
 //            KeyRecord_t KeyRecord[8]; // (8)
 //            uint32_t checksum; // (0 – 0xFFFFFFFF)
 //            }ActigraphyKey_t ;
 //
 //     Each individual key record is structured as follows.
 //
 //    typedef struct
 //        {
 //            uint8_t Date; // (1 - 31)
 //            uint8_t Month; // (1 - 12)
 //            uint8_t Year; // (0 - 255)
 //            union
 //            {
 //                uint8_t Reg;
 //                struct
 //                {
 //                    uint8_t invalid   : 1; //!< 1 if record is invalid
 //                    uint8_t timeChanged : 1; //!< 1 if time changed
 //                    uint8_t dateChanged : 1; //!< 1 if date changed
 //                    uint8_t       : 5;
 //               }b;
 //            }status;
 //        }KeyRecord_t ;
 *
 *
 */
#import "iDevicesUtil.h"
#import "TDM372ActigraphyKeyFile.h"
#import "TDM372ActigraphyKeyFileTrackerRecord.h"
#import "TDM372ActigraphyKeyFileTrackerRecordReference.h"
#import "OTLogUtil.h"
#import "TDDefines.h"
#import "DBActivity+CoreDataClass.h"
#import "DBModule.h"

@interface TDM372ActigraphyKeyFile()
{
    Byte activitiesNumber;
    NSMutableArray * mActivities;
    uint32_t  checksum;
}
@end


@implementation TDM372ActigraphyKeyFile
- (id) init
{
    if (self = [super init])
    {
        mActivities = [[NSMutableArray alloc] init];
    }
    
    return self;
}
- (id) init: (NSData *) inData
{
    if (self = [self init])
    {
        [self readKeyRecords: inData];
    }
    
    return self;
}

-(NSUInteger)crc32:(uint8_t *)bytes
{
    uint32_t *table = (uint32_t *)malloc(sizeof(uint32_t) * 256);
    uint32_t crc = 0xffffffff;
    
    for (uint32_t i=0; i<256; i++) {
        table[i] = i;
        for (int j=0; j<8; j++) {
            if (table[i] & 1) {
                table[i] = (table[i] >>= 1) ^ 0xedb88320;
            } else {
                table[i] >>= 1;
            }
        }
    }
    
    for (int i=0; i<37; i++) {
        crc = (crc >> 8) ^ table[crc & 0xff ^ bytes[i]];
    }
    crc ^= 0xffffffff;
    
    free(table);
    return crc;
}

- (int ) readKeyRecords: (NSData *) inDataObject
{
    int error = noErr;
    
    NSMutableDictionary *result = [[NSMutableDictionary alloc]init];
    if (result.count > 0)
        [result removeAllObjects];
    
    NSMutableDictionary *toEpochs = [[NSMutableDictionary alloc]init];
    if (toEpochs.count > 0)
        [toEpochs removeAllObjects];
    
    NSUInteger len = [inDataObject length];
    Byte inData[len];
    memcpy(inData, [inDataObject bytes], len);
    
    OTLog(@"KEY RECORDS Info received");
    [iDevicesUtil dumpData: inDataObject];
    
    TDM372ActigraphyKeyFileTrackerRecordReference *newActivityReference = [[TDM372ActigraphyKeyFileTrackerRecordReference alloc]init];
    
    Byte ptrBytesInt[4];

    memset(ptrBytesInt, 0, 4);
    [inDataObject getBytes: ptrBytesInt range: NSMakeRange((int)inDataObject.length-4, 4)];
    checksum = [iDevicesUtil byteArrayToIntRevesre:ptrBytesInt];
    OTLog(@"---------------------------------------------");
    OTLog(@"ActigraphyKeyFile");
    OTLog(@"LastbytesCheckSum:%ld",checksum);
    OTLog(@"FullDatachecksum:%ld",[iDevicesUtil calculateChecksum:inData withLength:(int)inDataObject.length-6]); // this one is correct
    OTLog(@"---------------------------------------------");
    
    newActivityReference.mMaxNumFiles    = inData[0];
    newActivityReference.mFileNameIndex  = inData[1];
    
    OTLog(@"FileNameIndex:%hhu", newActivityReference.mFileNameIndex);
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"YYYYDDD"];
    OTLog(@"Actigraphy Key File Data");
    OTLog(@"MaxNumFiles: %d",newActivityReference.mMaxNumFiles);
    OTLog(@"FileNameIndex: %d",newActivityReference.mFileNameIndex);
    
    int offsetFromStart = 5;
                                 
    for ( int i = 0; i <= newActivityReference.mMaxNumFiles -1; i++ )
    {
        TDM372ActigraphyKeyFileTrackerRecord *newActivity = [[TDM372ActigraphyKeyFileTrackerRecord alloc]init];
        NSMutableDictionary *recordDictionary = [[NSMutableDictionary alloc] init];
        
        newActivity.mDay = inData[offsetFromStart];
        offsetFromStart++;
        
        newActivity.mMonth = inData[offsetFromStart];
        offsetFromStart++;
        
        newActivity.mYear = inData[offsetFromStart];
        
        offsetFromStart++;
        //newActivity.mStatus = inData[offsetFromStart];
        newActivity.mStatus = (1 == ((inData[offsetFromStart] >> 0) & 1));
        offsetFromStart++;
        
        OTLog(@"------------------------");
        OTLog(@"Record %d Date: %d/%d/%d",i,newActivity.mDay,newActivity.mMonth,1900+newActivity.mYear);
        OTLog(@"Record %d Validity: %d",i,newActivity.mStatus);
        OTLog(@"Record %d TimeChanged: %d",i,(1 == ((inData[offsetFromStart] >> 1) & 1)));
        OTLog(@"Record %d DateChanged: %d",i,(1 == ((inData[offsetFromStart] >> 2) & 1)));
        
        /* RECORD 0 -> M372A0xx.SLP
         RECORD 1 -> M372A1xx.SLP
         .
         .
         RECORD 7 -> M372A7xx.SLP
         */
        if (newActivity.mStatus == 0) {
            NSDate * date = [newActivity getActivityDate];
            NSString *tempDate = @"";
            tempDate = [NSString stringWithFormat:@"%@",[formatter stringFromDate:date]];
            
            [recordDictionary setObject:[NSString stringWithFormat:@"%@", [formatter stringFromDate:date]] forKey:@"Date"];
            [recordDictionary setObject:[NSString stringWithFormat:@"%hhu",newActivity.mStatus] forKey:@"Status"];
            [result setObject:recordDictionary forKey:[NSString stringWithFormat:@"%d",i]];
            
            /////
            
            [toEpochs setObject:[NSString stringWithFormat:@"%d",i] forKey:tempDate];
            [mActivities addObject:newActivity];
        }
        
        //}
    }
    
    memset(ptrBytesInt, 0, 4);
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    OTLog(@"toEpochs: %@",toEpochs);
    NSDictionary *newToEPcohs = [self saveEpochsAlreadyReadIt:toEpochs];
    [defaults setObject:newToEPcohs forKey:@ALL_THE_DATA_IN_EPOCHS];
    OTLog(@"ALL_THE_DATA_IN_EPOCHS:%@",newToEPcohs);
    [defaults synchronize];
    
    return error;
}
- (NSDictionary *)saveEpochsAlreadyReadIt:(NSDictionary *)toEpochs
{
    @autoreleasepool {
        
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        ////////
        NSDate *today = [NSDate date];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"YYYYDDD"];
        NSString *todayString = [NSString stringWithFormat:@"%@",[formatter stringFromDate:today]];
        
        float yesterdayFloat = [todayString floatValue];
        
        yesterdayFloat = yesterdayFloat - 1;
        NSString *yesterdayString = [NSString stringWithFormat:@"%.0f",yesterdayFloat];
        
        NSArray *keyFromEPochs = [toEpochs allKeys];
        OTLog(@"TestLogKeysFroEpochs: %@",keyFromEPochs);
        
        ///////
        
        NSMutableDictionary *result = [[NSMutableDictionary alloc]init];
        
        ////IS THE FIRST TIME /////
        
        NSString * key = @FIRST_SYNC;
//        [userDefaults removeObjectForKey:@FIRST_SYNC];
        if ([userDefaults objectForKey: key] == nil)
        {
            //[userDefaults setInteger: 0 forKey: key];
            //[userDefaults synchronize];
            OTLog(@"%@",[NSString stringWithFormat:@"TestLogFinalResult: %@",toEpochs]);
            return toEpochs;
        }
        ///////////////////////////
        
        NSArray *daysSavedInList = [userDefaults objectForKey:@DAYS_READ_BEFORE];
        daysSavedInList = [daysSavedInList sortedArrayUsingSelector:@selector(localizedCaseInsensitiveContainsString:)];
        OTLog(@"TestLogDaySavedInList: %@",daysSavedInList);
        
        if (!(daysSavedInList.count > 0))
        {
            OTLog(@"daysSavedInList is empty");
            NSMutableArray *daysReadeItEmpty = [[NSMutableArray alloc]init];
            
            for (int i = 0; i < keyFromEPochs.count; i++)
            {
                NSString *day = [NSString stringWithFormat:@"%@",[keyFromEPochs objectAtIndex:i]];
                
                if (![day isEqualToString:todayString])
                {
                    if (![day isEqualToString:yesterdayString])
                    {
                        [daysReadeItEmpty addObject:day];
                    }
                }
            }
            //NSLog(@"TestLogdaysReadeItEmpty: %@",daysReadeItEmpty);
            [userDefaults setObject:daysReadeItEmpty forKey:@DAYS_READ_BEFORE];
            [userDefaults synchronize];
            
            NSArray *final = [userDefaults objectForKey:@DAYS_READ_BEFORE];
            //NSLog(@"TestLogdaysFinalif (!(daysSavedInList.count > 0)): %@",final);
            
            
            //////creation of new toEpochs///////
            bool dateExists = false;
            NSArray *allKeysFromToEPochs = [toEpochs allKeys];
            for (int i = 0; i < allKeysFromToEPochs.count; i++)
            {
                NSString *dayInEpochs = [NSString stringWithFormat:@"%@",[allKeysFromToEPochs objectAtIndex:i]];
                
                for (int x =0; x < final.count; x++)
                {
                    NSString *dateSavedInList = [NSString stringWithFormat:@"%@",[final objectAtIndex:x]];
                    if ([dateSavedInList isEqualToString:dayInEpochs])
                    {
                        dateExists = true;
                        break;
                    }
                }
                if (!dateExists)
                {
                    [result setObject:[toEpochs objectForKey:dayInEpochs] forKey:dayInEpochs];
                }
            }
            ////////////////////////////////////
        } else {
            OTLog(@"daysSavedInList is not empty : %@",daysSavedInList);
            NSMutableArray *daysSavedInListMutable = [daysSavedInList mutableCopy];
            // Keep it in descending order.
            NSSortDescriptor* sortOrder = [NSSortDescriptor sortDescriptorWithKey: @"self" ascending: NO];
            daysSavedInListMutable = [[daysSavedInListMutable sortedArrayUsingDescriptors: [NSArray arrayWithObject: sortOrder]] mutableCopy];
            OTLog(@"daysSavedInListMutable after sorting %@",daysSavedInListMutable);
            [daysSavedInListMutable removeObjectAtIndex:0];
            OTLog(@"daysSavedInListMutable after removing %@", daysSavedInListMutable);
            for (int i = 0; i < keyFromEPochs.count; i++)
            {
                bool dayInData = false;
                
                NSString *day = [NSString stringWithFormat:@"%@",[keyFromEPochs objectAtIndex:i]];
                
                //NSLog(@"TestLog: Day%@ vs TodayString:%@",day,todayString);
                if (![day isEqualToString:todayString])
                {
                    if (![day isEqualToString:yesterdayString])
                    {
                        //NSLog(@"TestLog: Day%@ vs yesterdayString:%@",day,yesterdayString);
                        for (int x = 0; x < daysSavedInListMutable.count; x++)
                        {
                            NSString *daySavedInList = [NSString stringWithFormat:@"%@",[daysSavedInListMutable objectAtIndex:x]];
                            //NSLog(@"TestLog: Day%@ vs daySavedInList:%@",day,daySavedInList);
                            if ([day isEqualToString:daySavedInList])
                            {
                                //NSLog(@"TestLogFinal!!!: %@",day);
                                dayInData = true;
                                break;
                                //[daysReadeItMutable addObject:day];
                            }
                        }
                        if (!dayInData)
                            [daysSavedInListMutable addObject:day];
                        
                    }
                }
            }
            OTLog(@"daysSavedInListMutable after first forloop:%@",daysSavedInListMutable);
            for (int ite = 0 ; ite < daysSavedInListMutable.count; ite ++)
            {
                TCSTART
                NSString *daySaved = [daysSavedInListMutable objectAtIndex:ite];
                NSDate *activityDate = [formatter dateFromString:daySaved];
                OTLog(@"activityDate :%@",activityDate);
                if (activityDate != nil) {
                    DBActivity *activity = (DBActivity*)[[DBModule sharedInstance]getEntity:@"DBActivity" columnName:@"date" value:activityDate];
                    NSMutableString *segments = [activity.segments mutableCopy];
                    if (activity.segments != nil && activity.segments.length > 0) {
                        if ([[segments stringByReplacingOccurrencesOfString:@"F" withString:@""] length] != 720) {
                            [daysSavedInListMutable removeObject:daySaved];
                        }
                    } else {
                        [daysSavedInListMutable removeObject:daySaved];
                    }
                }
                TCEND
            }
            OTLog(@"daysSavedInListMutable after second forloop:%@",daysSavedInListMutable);
            [userDefaults setObject:daysSavedInListMutable forKey:@DAYS_READ_BEFORE];
            [userDefaults synchronize];
            OTLog(@"@DAYS_READ_BEFORE:%@",daysSavedInListMutable);
            NSArray *final = [userDefaults objectForKey:@DAYS_READ_BEFORE];
            
            NSArray *allKeysFromToEPochs = [toEpochs allKeys];
            for (int i = 0; i < allKeysFromToEPochs.count; i++)
            {
                bool dateExists = false;
                NSString *dayInEpochs = [NSString stringWithFormat:@"%@",[allKeysFromToEPochs objectAtIndex:i]];
                
                for (int x =0; x < final.count; x++)
                {
                    NSString *dateSavedInList = [NSString stringWithFormat:@"%@",[final objectAtIndex:x]];
                    
                    
                    if ([dateSavedInList isEqualToString:dayInEpochs])
                    {
                        //NSLog(@"TestLogComparations: daInEpochs: %@ \ndateSavedInList:%@",dayInEpochs,dateSavedInList);
                        dateExists = true;
                        break;
                    }
                }
                if (!dateExists)
                {
                    //NSLog(@"TestLogSetObject: %@ \nforKey: %@",[toEpochs objectForKey:dayInEpochs],dayInEpochs);
                    [result setObject:[toEpochs objectForKey:dayInEpochs] forKey:dayInEpochs];
                }
            }
            OTLog(@"daysSavedInListMutable after thrid forloop:%@",daysSavedInListMutable);
            ////////////////////////////////////
        }
        return result;
    }
}

@end
