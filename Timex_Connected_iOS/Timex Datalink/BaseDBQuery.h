//
//  BaseDBQuery.h
//  Timex Connected
//
//  Created by Lev Verbitsky on 6/18/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

#ifndef _BASEDBQUERY_H_
#define _BASEDBQUERY_H_

#include <Foundation/Foundation.h>
#include "IDBQuery.h"

namespace TimexDatalink
{
	class BaseDBQuery : public IDBQuery
	{
	public:
		virtual NSUInteger      getRowCount();
		virtual NSUInteger      getColumnCount();
		virtual NSObject*       getColumnForRow( unsigned int row, NSString* columnName );
		virtual NSObject*       getColumnForRow( unsigned int row, unsigned int column );
		virtual NSString*       getColumnName( unsigned int column );
		virtual unsigned int    getUIntColumnForRow( unsigned int row, unsigned int column );
		
		virtual unsigned int    getUIntColumnForRow( unsigned int row, NSString* columnName );
		virtual int             getIntColumnForRow( unsigned int row, NSString* columnName );
		virtual double          getDoubleColumnForRow( unsigned int row, NSString* columnName );
		virtual NSString*       getStringColumnForRow( unsigned int row, NSString* columnName );
		
		virtual                 ~BaseDBQuery();
		
	protected:
		BaseDBQuery();
		void                    addSchemaField( NSString* name, unsigned int index );
		void                    addRow( NSArray* row );
        
	private:	
		NSUInteger              _rowCount;
		
		NSMutableDictionary*	_resultSchemaDict;	
		NSMutableArray*			_resultSchemaArray; 
		NSMutableArray*         _rows;		
	};
}

#endif