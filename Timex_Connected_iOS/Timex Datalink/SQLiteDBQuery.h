//
//  SQLiteDBQuery.h
//  Timex Connected
//
//  Created by Lev Verbitsky on 6/18/13.
//  Copyright (c) 2013 iDevices, LLC. All rights reserved.
//

#ifndef _SQLITEDBQUERY_H_
#define _SQLITEDBQUERY_H_

#include "BaseDBQuery.h"
#include <sqlite3.h>

namespace TimexDatalink
{
	class SQLiteDBQuery : public BaseDBQuery
	{   
        public:
            SQLiteDBQuery(sqlite3_stmt* statement);
		
        private:
            SQLiteDBQuery() {}
		
            void init( sqlite3_stmt * statement );
		
            int sqliteToTimexType( int type );
	};
};

#endif