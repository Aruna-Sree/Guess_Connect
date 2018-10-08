//
//  SQLiteDBQuery.cpp
//  Timex Connected
//
//  Created by Lev Verbitsky on 6/18/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//


#include "SQLiteDBQuery.h"
#include "DataLayerTypes.h"

TimexDatalink::SQLiteDBQuery::SQLiteDBQuery(sqlite3_stmt* statement)
{
	init(statement);
}

void TimexDatalink::SQLiteDBQuery::init( sqlite3_stmt* statement )
{
	int numFields = sqlite3_column_count(statement);

	for ( int i = 0; i < numFields; i++ )
	{
		const char* name = sqlite3_column_name( statement, i );
        
		NSString* nsName = [[NSString alloc] initWithUTF8String:name];
		
		addSchemaField(nsName, i );
	}
	
	while( sqlite3_step( statement ) == SQLITE_ROW )
	{
		NSMutableArray* row = [[NSMutableArray alloc] init];
		
		for( int i = 0; i < numFields; i++ )
		{
			NSObject* data=nil;
			
			switch( sqliteToTimexType(sqlite3_column_type(statement, i )))
			{
				
				case kDataType_Null:
					data = [NSNull null];
					break;
				case kDataType_Integer:
					data = [[NSNumber alloc] initWithLongLong: sqlite3_column_int64(statement, i)];
					break;
				case kDataType_Float:
					data = [[NSNumber alloc] initWithDouble:sqlite3_column_double(statement, i)];
					break;
				case kDataType_Text:
					data = [[NSString alloc] initWithUTF8String:(const char*)sqlite3_column_text( statement, i)];
					break;
				case kDataType_Binary:
					data = [[NSData alloc] initWithBytes:sqlite3_column_blob(statement, i) length:sqlite3_column_bytes(statement, i)];
					break;
				default:
					//something has gone wrong....
					break;
			}
			
			[row addObject:data];
		}
		
		addRow(row);
	}
}

int TimexDatalink::SQLiteDBQuery::sqliteToTimexType(int type)
{
	switch( type )
	{
		case SQLITE_INTEGER:
			return kDataType_Integer;
		case SQLITE_FLOAT:
			return kDataType_Float;
		case SQLITE_TEXT:
			return kDataType_Text;
		case SQLITE_BLOB:
			return kDataType_Binary;
	}
	
	return kDataType_Null;
}

