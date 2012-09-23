//
//  FDOConnection.h
//  FoundationDataObjects
//
//  Created by Doug on 1/4/09.
//  Copyright 2009 Douglas Richardson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FDOCommand.h"

// FDO objects are not thread safe. If you want to access a database from multiple threads,
// then create an FDOConnection object from each thread. If you need to share FDO objects
// between two or more threads, then you must ensure no more than one thread is using
// the objects at a time.

// Any FDO object can throw an FDOException.

@protocol FDOConnection < NSObject >

// When committing or rolling back transactions, all FDOCommand objects associated with this connection
// will be closed (as well as any FDORecordSet objects associated with those FDOCommands).
-(void)beginTransaction;
-(void)commitTransaction;
-(void)rollbackTransaction;

// Convenience method for executing a SQL command once. If you need more flexibility (i.e. execute a
// command several times or bind parameters) then get an FDOCommand using newCommand.
-(id <FDORecordSet>)execute:(NSString*)sql;

// Returns a command object each time it is called. Retain it if you want to keep it around.
-(id <FDOCommand>)newCommand;

-(FDORowID)lastInsertRowID;
@end

// Factory function to create an SQLite FDOConnection object.
id <FDOConnection> FDOCreateSQLiteConnection(NSString* pathToDatabaseFile);
