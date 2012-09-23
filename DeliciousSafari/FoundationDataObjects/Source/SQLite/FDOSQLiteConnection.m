//
//  FDOSQLiteConnection.m
//  FoundationDataObjects
//
//  Created by Doug on 1/4/09.
//  Copyright 2009 Douglas Richardson. All rights reserved.
//

#import "FDOSQLiteConnection.h"
#import "FDOSQLiteCommand.h"
#import "FDOSQLiteRecordset.h"
#import "FDOSQLiteException.h"
#import "FDOLog.h"

@interface FDOSQLiteConnection ()
-(void)closeOpenedCommands;
@end

@implementation FDOSQLiteConnection

-(id)initWithPathToDatabase:(NSString*)pathToDatabaseFile
{
	self = [super init];
	
	if(self)
	{
		if(sqlite3_open([pathToDatabaseFile UTF8String], &_db) != SQLITE_OK)
		{
			[FDOException raise:kFDOSQLiteAPIException
						 format:@"[FDOSQLiteConnection initWithPathToDatabase] failed to open database at %@.", pathToDatabaseFile];
		}
		
		_openCommands = [[NSMutableSet alloc] init];
	}
	
	return self;
}

-(void)dealloc
{
	if(_db)
		sqlite3_close(_db);
	
	[_openCommands release];
	
	[super dealloc];
}

-(sqlite3*)db
{
	return _db;
}

-(void)commandWillClose:(FDOSQLiteCommand*)command
{
	[_openCommands removeObject:command];
}

-(void)closeOpenedCommands
{
	NSEnumerator *openedCommandsEnum = [_openCommands objectEnumerator];
	FDOSQLiteCommand *command;
	
	while((command = [openedCommandsEnum nextObject]) != nil)
		[command close];
}

-(void)beginTransaction
{
	char *errmsg = NULL;

#ifdef THREAD_CHECKING
	NSLog(@"BEGIN [%@]", [NSThread currentThread] != [NSThread mainThread] ? @"NOT MAIN THREAD!!!" : @"main thread");
#endif

	if(sqlite3_exec(_db, "BEGIN", NULL, NULL, &errmsg) != SQLITE_OK)
		[FDOException raise:kFDOSQLiteAPIException format:@"Could not begin transaction. %s", errmsg];
}

-(void)commitTransaction
{
#ifdef THREAD_CHECKING
	NSLog(@"COMMIT [%@]", [NSThread currentThread] != [NSThread mainThread] ? @"NOT MAIN THREAD!!!" : @"main thread");
#endif
	
	// Before commiting a transaction, SQLite likes all opened statements to be closed.
	[self closeOpenedCommands];
	
	char *errmsg = NULL;
	if(sqlite3_exec(_db, "COMMIT", NULL, NULL, &errmsg) != SQLITE_OK)
		[FDOException raise:kFDOSQLiteAPIException format:@"Could not commit transaction. %s", errmsg];
}

-(void)rollbackTransaction
{
#ifdef THREAD_CHECKING
	NSLog(@"ROLLBACK [%@]", [NSThread currentThread] != [NSThread mainThread] ? @"NOT MAIN THREAD!!!" : @"main thread");
#endif
	
	// Before rolling back a transaction, SQLite likes all opened statements to be closed.
	[self closeOpenedCommands];
	
	char *errmsg = NULL;
	if(sqlite3_exec(_db, "ROLLBACK", NULL, NULL, &errmsg) != SQLITE_OK)
		[FDOException raise:kFDOSQLiteAPIException format:@"Could not rollback transaction. %s", errmsg];
}

-(id <FDORecordSet>)execute:(NSString*)sql
{
	FDOSQLiteCommand *command = [self newCommand];
	[command prepare:sql];
	id <FDORecordSet> result = [command executeQuery];
	
	// If there is no associated RecordSet then close the command so that the statement is finailized immediately.
	if(result == nil)
		[command close];
	
	return result;
}

// Returns a command object each time it is called. Retain it if you want to keep it around.
-(id <FDOCommand>)newCommand
{
	FDOSQLiteCommand *command = [[[FDOSQLiteCommand alloc] initWithConnection:self] autorelease];
	[_openCommands addObject:command];
	return command;
}

-(FDORowID)lastInsertRowID
{
	FDORowID result = sqlite3_last_insert_rowid(_db);
	
	if(result == 0)
	{
		[FDOException raise:kFDOSQLiteAPIException
					 format:@"[FDOSQLiteConnection lastInsertRowID] - sqlite3_last_insert_rowid returned 0. No successful inserts have occurred."];
	}
	
	return result;
}

@end
	
