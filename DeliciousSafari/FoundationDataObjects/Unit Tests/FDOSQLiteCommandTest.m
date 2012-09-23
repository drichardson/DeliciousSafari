//
//  FDOSQLiteCommandTest.m
//  FoundationDataObjects
//
//  Created by Doug on 1/4/09.
//  Copyright 2009 Douglas Richardson. All rights reserved.
//

#import "FDOSQLiteCommandTest.h"

#define kTestDBPath @"/tmp/FDOSQLiteCommandTest.db"

@implementation FDOSQLiteCommandTest

-(void)setUp
{
	[[NSFileManager defaultManager] removeFileAtPath:kTestDBPath handler:nil];
	
	_connection = FDOCreateSQLiteConnection(kTestDBPath);
	
	[_connection execute:@"CREATE TABLE table1 (id INTEGER PRIMARY KEY NOT NULL, nameVal TEXT NULL, dateHired TIMESTAMP NOT NULL)"];
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

-(void)testBindingsByParameterNumber
{
	id <FDOCommand> command = [_connection newCommand];
	
	// When you write the date test, be sure to use a value that falls exactly on a second, or else you will loose the
	// percision when you insert into the SQLite database since it is only down the the second. If you try to compare something more
	// percise with the value in the database, it probably won't match and you'll just be lucky if it does.
	NSDate *referenceDate1 = [NSDate dateWithTimeIntervalSinceReferenceDate:0];
	NSDate *referenceDate2 = [NSDate dateWithTimeIntervalSinceReferenceDate:6000.0];
	
	[command prepare:@"INSERT INTO table1 (id, nameVal, dateHired) VALUES (?1, ?2, ?3)"];
	
	[command bindInt:1 toParameterNumber:1];
	[command bindString:@"Test String 1" toParameterNumber:2];
	[command bindDate:referenceDate1 toParameterNumber:3];
	[command executeQuery];
	
	[command bindInt:2 toParameterNumber:1];
	[command bindString:@"Test String 2" toParameterNumber:2];
	[command bindDate:referenceDate2 toParameterNumber:3];
	[command executeQuery];
	
	id <FDORecordSet> recordSet = [_connection execute:@"SELECT id, nameVal, dateHired FROM table1"];
	STAssertNotNil(recordSet, @"Expected result set.");
	
	STAssertEquals([recordSet intValueForColumnNamed:@"id"], 1, @"Expected id to be 1");
	STAssertEqualObjects([recordSet stringValueForColumnNamed:@"nameVal"], @"Test String 1", @"Unexpected name value");
	STAssertEqualObjects([recordSet dateValueForColumnNamed:@"dateHired"], referenceDate1, @"Unexpected date value");
	
	STAssertNoThrow([recordSet moveNext], @"Didn't expect moveNext to throw an exception");
	
	STAssertEquals([recordSet intValueForColumnNamed:@"id"], 2, @"Expected id to be 2");
	STAssertEqualObjects([recordSet stringValueForColumnNamed:@"nameVal"], @"Test String 2", @"Unexpected name value");
	STAssertEqualObjects([recordSet dateValueForColumnNamed:@"dateHired"], referenceDate2, @"Unexpected date value");
}

-(void)testBindingsByParameterName
{
	id <FDOCommand> command = [_connection newCommand];
	
	// When you write the date test, be sure to use a value that falls exactly on a second, or else you will loose the
	// percision when you insert into the SQLite database since it is only down the the second. If you try to compare something more
	// percise with the value in the database, it probably won't match and you'll just be lucky if it does.
	NSDate *referenceDate1 = [NSDate dateWithTimeIntervalSinceReferenceDate:0];
	NSDate *referenceDate2 = [NSDate dateWithTimeIntervalSinceReferenceDate:6000.0];
	
	STAssertNoThrow([command prepare:@"INSERT INTO table1 (id, nameVal, dateHired) VALUES (:id, @nameParm, $dateHiredParm)"], @"Expected prepare to succeed");
	
	STAssertNoThrow([command bindInt:1 toParameterNamed:@":id"], @"Expected int to bind.");
	STAssertNoThrow([command bindString:@"Testing 1" toParameterNamed:@"@nameParm"], @"Expected string to bind");
	STAssertNoThrow([command bindDate:referenceDate1 toParameterNamed:@"$dateHiredParm"], @"Expected date to bind");
	STAssertNoThrow([command executeQuery], @"Expected query to complete");
	
	STAssertNoThrow([command bindInt:2 toParameterNamed:@":id"], @"Expected int to bind");
	STAssertNoThrow([command bindString:nil toParameterNamed:@"@nameParm"], @"Expected nil string to bind");
	STAssertNoThrow([command bindDate:referenceDate2 toParameterNamed:@"$dateHiredParm"], @"Expected date to bind");
	STAssertNoThrow([command executeQuery], @"Expected query to complete.");
	
	id <FDORecordSet> recordSet = [_connection execute:@"SELECT id, nameVal, dateHired FROM table1"];
	STAssertNotNil(recordSet, @"Expected result set.");
	
	STAssertEquals([recordSet intValueForColumnNamed:@"id"], 1, @"Expected id to be 1");
	STAssertEqualObjects([recordSet stringValueForColumnNamed:@"nameVal"], @"Testing 1", @"Unexpected name value");
	STAssertEqualObjects([recordSet dateValueForColumnNamed:@"dateHired"], referenceDate1, @"Unexpected date value");
	
	STAssertNoThrow([recordSet moveNext], @"Didn't expect moveNext to throw an exception");
	
	STAssertEquals([recordSet intValueForColumnNamed:@"id"], 2, @"Expected id to be 2");
	STAssertEqualObjects([recordSet stringValueForColumnNamed:@"nameVal"], nil, @"Unexpected name value");
	STAssertEqualObjects([recordSet dateValueForColumnNamed:@"dateHired"], referenceDate2, @"Unexpected date value");
}

-(void)testBindAfterException
{
	id <FDOCommand> command = [_connection newCommand];
	
	STAssertNoThrow([command prepare:@"INSERT INTO table1 (id, dateHired) values (:id, datetime('now'))"], @"Expected prepare to work.");
	
	STAssertNoThrow([command bindInt64:1 toParameterNamed:@":id"], @"Expected to be able to set id to 1 for first insert.");
	STAssertNoThrow([command executeQuery], @"Expected insert to work.");
	
	STAssertNoThrow([command bindInt64:2 toParameterNamed:@":id"], @"Expected to be able to set id to 2 for second insert.");
	STAssertNoThrow([command executeQuery], @"Expected insert to work.");
	
	STAssertNoThrow([command bindInt64:1 toParameterNamed:@":id"], @"Expected another binding of 1 to work.");
	STAssertThrows([command executeQuery], @"Expected insert to fail because of duplicate primary key.");
	
	STAssertNoThrow([command bindInt64:3 toParameterNamed:@":id"], @"Expected to be able to set id to 3 for third insert.");
	STAssertNoThrow([command executeQuery], @"Expected insert to work.");
}


@end
