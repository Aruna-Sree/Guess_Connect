//
//  IDBQuery.h
//  Timex Connected
//
//  Created by Lev Verbitsky on 6/18/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

#ifndef _IDBQUERY_H_
#define _IDBQUERY_H_

#include <Foundation/Foundation.h>


namespace TimexDatalink 
{
	class IDBQuery
	{
	public:
		virtual NSUInteger      getRowCount () = 0;
		virtual NSUInteger      getColumnCount () = 0;
		virtual NSObject*       getColumnForRow ( unsigned int row, NSString* columnName ) = 0;
		virtual NSObject*       getColumnForRow ( unsigned int row, unsigned int column ) = 0;
		virtual NSString*       getColumnName ( unsigned int column ) = 0;
		virtual unsigned int    getUIntColumnForRow ( unsigned int row, unsigned int column ) = 0;
		virtual unsigned int    getUIntColumnForRow ( unsigned int row, NSString* columnName ) = 0;
		virtual int             getIntColumnForRow ( unsigned int row, NSString* columnName ) = 0;
		virtual double          getDoubleColumnForRow ( unsigned int row, NSString* columnName ) = 0;
		virtual NSString*       getStringColumnForRow ( unsigned int row, NSString* columnName ) = 0;
		
		virtual ~IDBQuery() { };
	};
};

#endif