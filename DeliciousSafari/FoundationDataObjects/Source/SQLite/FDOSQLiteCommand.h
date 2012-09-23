//
//  FDOSQLiteCommand.h
//  FoundationDataObjects
//
//  Created by Doug on 1/4/09.
//  Copyright 2009 Douglas Richardson. All rights reserved.
//

#import "FDOCommand.h"
#import <sqlite3.h>

@class FDOSQLiteConnection;
@class FDOSQLiteRecordSet;

@interface FDOSQLiteCommand : NSObject <FDOCommand> {
	FDOSQLiteConnection *_connection;
	FDOSQLiteRecordSet *_recordSet;
	sqlite3_stmt *_stmt;
	NSDateFormatter *_dateFormatter;
	BOOL shouldResetOnBind;
}

-(id)initWithConnection:(FDOSQLiteConnection*)connection;
-(sqlite3_stmt*)stmt;
-(sqlite3*)db;
- (void)close;

@end
