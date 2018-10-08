//
//  BaseDBQuery.cpp
//  Timex Connected
//
//  Created by Lev Verbitsky on 6/18/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

#include "BaseDBQuery.h"
#include "DataLayerTypes.h"

@interface SchemaEntry : NSObject
{
	unsigned int    _index;
	NSString        * _name;
}

@property unsigned int _index;
@property (strong) NSString* _name;
@end

@implementation SchemaEntry

@synthesize _index;
@synthesize _name;


@end

NSUInteger TimexDatalink::BaseDBQuery::getRowCount()
{
	return _rowCount;
}

NSUInteger TimexDatalink::BaseDBQuery::getColumnCount()
{
	return [_resultSchemaArray count];
}

NSObject* TimexDatalink::BaseDBQuery::getColumnForRow( unsigned int row, NSString* columnName )
{
	if ( row < _rowCount )
	{
		SchemaEntry* entry = (SchemaEntry*)[_resultSchemaDict valueForKey:columnName];
		
		if ( entry )
		{
			unsigned int index = entry._index;
			NSObject* value = [[_rows objectAtIndex:row] objectAtIndex:index];
			
			return value;
		}
	}
	
	return nil;
}

NSObject* TimexDatalink::BaseDBQuery::getColumnForRow( unsigned int row, unsigned int column )
{
	if ( row < _rowCount && column < [_resultSchemaArray count] )
	{
		NSObject* value = [[_rows objectAtIndex:row] objectAtIndex:column];
		
		return value;
	}
	
	return nil;
}

NSString* TimexDatalink::BaseDBQuery::getColumnName( unsigned int column )
{
	NSString* name = nil;

	if ( column < [_resultSchemaArray count] )
	{
		SchemaEntry* entry = (SchemaEntry*)[_resultSchemaArray objectAtIndex:column];
		name = entry._name;

	}
	
	return name;
}


unsigned int TimexDatalink::BaseDBQuery::getUIntColumnForRow( unsigned int row, unsigned int column )
{
	unsigned int result = 0;
	
	NSObject* obj = getColumnForRow(row, column);
	
	if ( [obj isKindOfClass:[NSNumber class]] )
	{
		return [(NSNumber*)obj unsignedIntValue];
	}
	
	return result;
}

unsigned int TimexDatalink::BaseDBQuery::getUIntColumnForRow( unsigned int row, NSString* columnName )
{
	NSObject* obj = getColumnForRow(row, columnName);
	
	if ( [obj isKindOfClass:[NSNumber class] ] )
	{
		return [(NSNumber*)obj unsignedIntValue];
	}
	
	return 0;
}

int TimexDatalink::BaseDBQuery::getIntColumnForRow( unsigned int row, NSString* columnName )
{
	NSObject* obj = getColumnForRow(row, columnName);
	
	if ( [obj isKindOfClass:[NSNumber class] ] )
	{
		return [(NSNumber*)obj intValue];
	}
	
	return 0;
}

double TimexDatalink::BaseDBQuery::getDoubleColumnForRow( unsigned int row, NSString* columnName )
{
	NSObject* obj = getColumnForRow(row, columnName);
	
	if ( [obj isKindOfClass:[NSNumber class] ] )
	{
		return [(NSNumber*)obj doubleValue];
	}
	
	return 0.f;
}

NSString* TimexDatalink::BaseDBQuery::getStringColumnForRow( unsigned int row, NSString* columnName )
{
	NSObject* obj = getColumnForRow(row, columnName);
	
	if ( [obj isKindOfClass:[NSString class] ] )
	{
		return (NSString*)obj;
	}
	
	return @"";
}

TimexDatalink::BaseDBQuery::~BaseDBQuery()
{
	_resultSchemaDict = nil;
	_resultSchemaArray = nil;
	
	_rows = nil;
	
	_rowCount = 0;
}


TimexDatalink::BaseDBQuery::BaseDBQuery() : _rowCount(0)
{
	_resultSchemaDict = [[NSMutableDictionary alloc] init];
	_resultSchemaArray = [[NSMutableArray alloc] init];
	
	_rows = [[NSMutableArray alloc] init];
}

void TimexDatalink::BaseDBQuery::addSchemaField( NSString* name, unsigned int index )
{
	// make sure field name not already exists
	if ( [_resultSchemaDict valueForKey:name] == nil )
	{
		NSEnumerator* enumerator = [_resultSchemaDict objectEnumerator];
		SchemaEntry* value = nil;
		BOOL add = YES;
		
		// Make sure the index isn't already used
		while( value = (SchemaEntry*)[enumerator nextObject] )
		{
			if ( value._index == index )
			{
				add = NO;
				break;
			}
		}
		
		if ( add && index != [_resultSchemaArray count] )
		{
			add = NO;
		}
		
		if ( add )
		{
			NSString* local = [[NSString alloc] initWithString:name];
			SchemaEntry* entry = [[SchemaEntry alloc] init];
			
			entry._index = index;
			entry._name = local;
			
			[_resultSchemaDict setValue:entry forKey:local];
			[_resultSchemaArray addObject:entry];
			
		}
	}
}

void TimexDatalink::BaseDBQuery::addRow( NSArray* row )
{
	if ( [_resultSchemaArray count] != [row count] )
	{
		NSLog(@"TimexDatalink::BaseDBQuery::addRow: Row does not contain the same number of elements (%ld) as the database schema (%ld)", (long)[row count], (long)[_resultSchemaArray count]);
	}
	
	[_rows addObject:row];
    _rowCount = [_rows count];
}
