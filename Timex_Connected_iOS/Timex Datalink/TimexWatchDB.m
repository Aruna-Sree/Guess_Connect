//
//  TimexWatchDB.m
//  Timex Connected
//
//  Created by Lev Verbitsky on 6/18/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

#import "TimexWatchDB.h"
#import "TDDefines.h"
//#import "iDevicesUtil.h"
#import "OTLogUtil.h"
#define STR_DEFAULT_DATAPATH @"data"

@implementation TimexWatchDB

static TimexWatchDB * instance = nil;

+(id) sharedInstance 
{
	if (!instance)
	{
		instance = [[[self class] alloc] init];
	}
	
	return instance;
}

- (NSInteger) createBlankDatabase : (NSString *) path
{
	sqlite3 * database = nil;
	int		response = SQLITE_OK;
	
    OTLog(@"DELETING DATABASE");
    
	if (sqlite3_open([path UTF8String], &database) == SQLITE_OK) 
	{	
		NSString *filePath = [[NSBundle mainBundle] pathForResource:@"timex_db_schema" ofType:@"sql"]; 
        if (filePath) 
        {  
            NSData *schemaData = [NSData dataWithContentsOfFile:filePath];
				
            NSString * content = [[NSString alloc] initWithBytes:[schemaData bytes] length:[schemaData length] encoding: NSUTF8StringEncoding];
				
            response = sqlite3_exec(database, [content UTF8String], NULL, NULL, NULL);
                
		}
	}
	sqlite3_close(database);
	
	return response;
}


/// Write another method to put up isDeleted column for workout
/// Query " ALTER TABLE Workouts ADD COLUMN isDeleted INTEGER DEFAULT 0

- (void)performTableAlterations:(int)oldVersionNumber {
    
    NSArray *updatesArray = [NSArray arrayWithObjects:@"",[NSString stringWithFormat:@"ALTER TABLE Workouts ADD COLUMN isDeleted INTEGER DEFAULT 0"], nil];
    
    for (int i = oldVersionNumber + 1; i < updatesArray.count; i++) {
        TimexDatalink::IDBQuery * query = [[TimexWatchDB sharedInstance] createQuery : [updatesArray objectAtIndex:i]];
        if (query) {
            NSLog(@"Succes performTableAlterations");
        }
        [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%d",i] forKey:@"AppOldVersionNumber"];
    }
}

- (NSInteger) augmentExistingDatabaseForM053
{
    sqlite3 * database = nil;
    int		response = SQLITE_OK;
    
    if (s_existingDBpath && sqlite3_open([s_existingDBpath UTF8String], &database) == SQLITE_OK)
    {
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"timex_db_auxillary" ofType:@"sql"];
        if (filePath)
        {
            NSData *schemaData = [NSData dataWithContentsOfFile:filePath];
            
            NSString * content = [[NSString alloc] initWithBytes:[schemaData bytes] length:[schemaData length] encoding: NSUTF8StringEncoding];
            
            response = sqlite3_exec(database, [content UTF8String], NULL, NULL, NULL);
            
        }
    }
    sqlite3_close(database);
    
    return response;
}

- (NSInteger) init : (NSString *) path
{
	int result = SQLITE_ERROR;
	
	if ( sqlite3_open( [path UTF8String], &_db ) == SQLITE_OK )
	{
        s_existingDBpath = path;
        
		result = SQLITE_OK;
	}
	
	return result;
}

- (BOOL) doesFileExist: (NSString *) path
{
	NSFileManager* fileMgr = [NSFileManager defaultManager];
	
	return [fileMgr fileExistsAtPath:path];
}

- (NSString *) getCachePath
{
	if ( s_cachePath == nil )
	{
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
		s_cachePath = [(NSString*)[paths objectAtIndex:0] stringByAppendingPathComponent:s_servicePath];
		
	}
	
	return s_cachePath;
}

- (NSString *) getDataPath
{
	if( s_dataPath == nil )
	{
		s_dataPath = [ [self getCachePath] stringByAppendingPathComponent:STR_DEFAULT_DATAPATH];
	}
	
	if ( ! [self doesFileExist: s_dataPath] )
	{
		[self createDirectory : s_dataPath];
	}
	
	return s_dataPath;
}

- (BOOL) createDirectory : (NSString *) path
{
	NSFileManager* fileMgr = [NSFileManager defaultManager];
	
	if( [self doesFileExist : path] == NO )
    {
		return [fileMgr createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
	
	return NO;
}

- (TimexDatalink::IDBQuery *) createQuery : (NSString *) expression
{
    TimexDatalink::SQLiteDBQuery    * query = NULL;
	sqlite3_stmt                    * compiledStatement;
    
	int result = sqlite3_prepare_v2(_db, [expression UTF8String], -1, &compiledStatement, NULL);
    
	if ( result == SQLITE_OK )
	{
		query = new TimexDatalink::SQLiteDBQuery( compiledStatement );
		result = sqlite3_finalize(compiledStatement);
	}
	
	if ( result != SQLITE_OK)
	{
		const char* msg = sqlite3_errmsg(_db);
		
		NSLog(@"SQLiteDB::createQuery: %s", msg);
	}
    
	return query;
}
- (NSMutableDictionary*)getGoals1ForType:(NSNumber *)type{
    NSMutableDictionary *goals = [[NSMutableDictionary alloc]init];
    NSString* sql = [NSString stringWithFormat:@"SELECT * FROM M328_Goals WHERE type = %@",type];
    const char *query_stmt = [sql UTF8String];
    sqlite3_stmt*statement;
    
    if (sqlite3_prepare_v2(_db, query_stmt, -1, &statement, nil)==SQLITE_OK) {
        
        if (sqlite3_step(statement)==SQLITE_ROW) {
            
            NSNumber *cal = [[NSNumber alloc] initWithFloat:sqlite3_column_int(statement, 1)];
            [goals setObject:cal forKey:CALORIES];
            
            NSNumber *dist = [[NSNumber alloc] initWithFloat:sqlite3_column_double(statement, 2)];
            [goals setObject:dist forKey:DISTANCE];
            
            NSNumber *lsteps = [[NSNumber alloc] initWithFloat:sqlite3_column_int(statement, 3)];
            [goals setObject:lsteps forKey:STEPS];
            
            NSNumber *sleep = [[NSNumber alloc] initWithFloat: sqlite3_column_int(statement,4)];
            [goals setObject:sleep forKey:SLEEPTIME];
            NSNumber *gtype = [[NSNumber alloc] initWithInt: sqlite3_column_int(statement,5)];
            [goals setObject:gtype forKey:GOALTYPE];
            
            
        }
        sqlite3_finalize(statement);
        
    }else {
        const char* msg = sqlite3_errmsg(_db);
        
        NSLog(@"SQLiteDB::createQuery: %s", msg);
        
    }
    //sqlite3_close(_db);
    return goals;
}

@end
