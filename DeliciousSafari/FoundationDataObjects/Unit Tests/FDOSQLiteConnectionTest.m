//
//  FDOSQLiteConnectionTest.m
//  FoundationDataObjects
//
//  Created by Doug on 1/4/09.
//  Copyright 2009 Douglas Richardson. All rights reserved.
//

#import "FDOSQLiteConnectionTest.h"

#define kTestDBPath @"/tmp/FDOSQLiteConnectionTest.db"

@implementation FDOSQLiteConnectionTest

-(void)setUp
{
	[[NSFileManager defaultManager] removeFileAtPath:kTestDBPath handler:nil];
	_connection = FDOCreateSQLiteConnection(kTestDBPath);
}

-(void)tearDown
{
	[_connection release];
}

-(void)testNewCommand
{
	id <FDOCommand> command = [_connection newCommand];
	
	STAssertNotNil(command, @"Returned FDOCommand is nil");
}

-(void)testLastInsertID
{
	[_connection execute:@"CREATE TABLE table1 (id INTEGER PRIMARY KEY NOT NULL, name TEXT NOT NULL);"];
	
	[_connection execute:@"INSERT INTO table1 (name) VALUES ('Test Name 1')"];
	STAssertEquals([_connection lastInsertRowID], (FDORowID)1, @"Expected first insert to return row ID of 1");
	
	[_connection execute:@"INSERT INTO table1 (name) VALUES ('Test Name 2')"];
	STAssertEquals([_connection lastInsertRowID], (FDORowID)2, @"Expected second insert to return row ID of 2");
	
	[_connection execute:@"INSERT INTO table1 (name) VALUES ('Test Name 3')"];
	STAssertEquals([_connection lastInsertRowID], (FDORowID)3, @"Expected third insert to return row ID of 3");
}

-(int)rowCount
{
	return [[_connection execute:@"SELECT COUNT(*) FROM namelist"] intValueForColumnNamed:@"COUNT(*)"];
}

-(void)testTransactions
{
	[_connection execute:@"CREATE TABLE namelist (name TEXT NOT NULL);"];
	
	STAssertEquals([self rowCount], 0, @"Expected no rows.");
	
	// Begin a transaction to commit.
	STAssertNoThrow([_connection beginTransaction], @"beginTransaction threw an exception.");
	
	[_connection execute:@"INSERT INTO namelist (name) values ('Row1')"];
	STAssertEquals([self rowCount], 1, @"Expected one row.");
	
	[_connection execute:@"INSERT INTO namelist (name) values ('Row2')"];
	STAssertEquals([self rowCount], 2, @"Expected two rows.");
	
	STAssertNoThrow([_connection commitTransaction], @"commitTransaction threw an exception.");
	
	STAssertEquals([self rowCount], 2, @"Expected two rows after commit.");
	
	
	// Begin a transaction to rollback.
	[_connection beginTransaction];
	[_connection execute:@"DELETE FROM namelist"];
	STAssertEquals([self rowCount], 0, @"Expected zero rows after delete.");
	[_connection rollbackTransaction];
	
	STAssertEquals([self rowCount], 2, @"Expected two rows after rollback.");
	
	STAssertNoThrow([_connection beginTransaction], @"Did not expect exception here.");
	STAssertThrows([_connection beginTransaction], @"Expected an exception here because of the nested transaction.");
	
	STAssertNoThrow([_connection commitTransaction], @"Did not expect exception here.");
	STAssertThrows([_connection commitTransaction], @"Expect exception here because not in transaction.");
	
	STAssertNoThrow([_connection beginTransaction], @"Did not expect exception here.");
	STAssertNoThrow([_connection rollbackTransaction], @"Did not expect exception here.");
	STAssertThrows([_connection rollbackTransaction], @"Expect exception here because not in transaction.");
}

@end
