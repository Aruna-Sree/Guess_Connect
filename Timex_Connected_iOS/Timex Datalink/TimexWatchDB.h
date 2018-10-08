//
//  TimexWatchDB.h
//  Timex Connected
//
//  Created by Lev Verbitsky on 6/18/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import "SQLiteDBQuery.h"


const static int   KEY_UNKNOWN = -1;

enum CommitResult
{
    kCommitResult_OK = 0,
    kCommitResult_NotOK = 1
};

enum LoadResult
{
    kLoadResult_OK = 0,
    kLoadResult_NotOK = 1
};

@interface TimexWatchDB : NSObject 
{
    sqlite3  *      _db;
    NSString *      s_cachePath;         //!< app's Library\Cache path
    NSString *      s_dataPath;          //!< Directory where database will be created
    NSString *      s_servicePath;		 //!< Web service specific path
    NSString *      s_existingDBpath;
}


+ (id)                          sharedInstance;

- (NSInteger)                   init : (NSString *) path;
- (NSInteger)                   createBlankDatabase : (NSString *) path;
- (NSInteger)                   augmentExistingDatabaseForM053;
- (BOOL)                        doesFileExist: (NSString *) path;
- (NSString *)                  getCachePath;
- (NSString *)                  getDataPath;
- (BOOL)                        createDirectory : (NSString *) path;
- (TimexDatalink::IDBQuery *)   createQuery : (NSString *) expression;
- (void)performTableAlterations:(int)oldVersionNumber;

- (NSMutableDictionary*)getGoals1ForType:(NSNumber *)type;
@end
