//
//  FDOSQLiteRecordSetTest.m
//  FoundationDataObjects
//
//  Created by Doug on 1/5/09.
//  Copyright 2009 Douglas Richardson. All rights reserved.
//

#import "FDOSQLiteRecordSetTest.h"
#import <Foundation/Foundation.h>

#define kTestDBPath @"/tmp/FDOSQLiteRecordSetTest.db"

@implementation FDOSQLiteRecordSetTest

-(void)setUp
{
	[[NSFileManager defaultManager] removeFileAtPath:kTestDBPath handler:nil];
	
	_connection = FDOCreateSQLiteConnection(kTestDBPath);
	
	[_connection execute:@"CREATE TABLE table1 (id INTEGER PRIMARY KEY NOT NULL, name TEXT NOT NULL, dateHired TIMESTAMP NOT NULL)"];
	[_connection execute:@"INSERT INTO table1 (id, name, dateHired) VALUES (1, 'Test Name 1', '2001-01-05 01:00:00')"];
	[_connection execute:@"INSERT INTO table1 (id, name, dateHired) VALUES (2, 'Test Name 2', '2002-02-15 11:10:10')"];
	[_connection execute:@"INSERT INTO table1 (id, name, dateHired) VALUES (30000000000000, 'Test Name 3', datetime('now'))"];
}

-(void)tearDown
{
	[_connection release];
}

-(void)testBasics
{
	id <FDORecordSet> recordSet = [_connection execute:@"SELECT COUNT(*) AS totalRowCount FROM table1"];
	STAssertNotNil(recordSet, @"RecordSet is nil.");
	STAssertEquals([recordSet intValueForColumnNumber:0], 3, @"Total row count doesn't equal 3.");
}

-(void)testNumberedParameters
{
	id <FDORecordSet> recordSet = [_connection execute:@"SELECT id, name, dateHired FROM table1"];
	STAssertNotNil(recordSet, @"RecordSet is nil.");
	
	int totalRowCount = 0;
	for(; ![recordSet isEOF]; [recordSet moveNext], totalRowCount++)
	{
		int intValue = [recordSet intValueForColumnNumber:0];
		int64_t int64Value = [recordSet int64ValueForColumnNumber:0];
		NSString *stringValue = [recordSet stringValueForColumnNumber:1];
		NSDate *dateValue = [recordSet dateValueForColumnNumber:2];
		
		STAssertNotNil(stringValue, @"String value from parameter by name is nil.");
		STAssertNotNil(dateValue, @"String value from parameter by name is nil.");
		
		if(totalRowCount == 0)
		{
			STAssertEquals(1, intValue, @"Expected id of 1 for the first row.");
			STAssertEqualObjects(@"Test Name 1", stringValue, @"Expected Test Name 1 for first row.");
			STAssertEqualObjects([NSDate dateWithString:@"2001-01-05 01:00:00 +0000"], dateValue, @"Didn't get expected date value.");
		}
		else if(totalRowCount == 1)
		{
			STAssertEquals(2, intValue, @"Expected id of 2 for the second row.");
			STAssertEqualObjects(@"Test Name 2", stringValue, @"Expected Test Name 2 for second row.");
			STAssertEqualObjects([NSDate dateWithString:@"2002-02-15 11:10:10 +0000"], dateValue, @"Didn't get expected date value.");
		}
		else if(totalRowCount == 2)
		{
			STAssertEquals(30000000000000, int64Value, @"Expected id of 3 for the third row.");
			STAssertEqualObjects(@"Test Name 3", stringValue, @"Expected Test Name 3 for third row.");
			STAssertTrue([dateValue compare:[NSDate date]] != NSOrderedDescending, @"Expected current date to be equal or greater than database date.");
		}
	}
	
	STAssertEquals(totalRowCount, 3, @"Did not get 3 rows as expected.");
}

-(void)testNamedParameters
{
	id <FDORecordSet> recordSet = [_connection execute:@"SELECT id, name, dateHired FROM table1"];
	STAssertNotNil(recordSet, @"RecordSet is nil.");
	
	int totalRowCount = 0;
	for(; ![recordSet isEOF]; [recordSet moveNext], totalRowCount++)
	{
		int intValue = [recordSet intValueForColumnNamed:@"id"];
		int64_t int64Value = [recordSet int64ValueForColumnNamed:@"id"];
		NSString *stringValue = [recordSet stringValueForColumnNamed:@"name"];
		NSDate *dateValue = [recordSet dateValueForColumnNamed:@"dateHired"];
		
		STAssertNotNil(stringValue, @"String value from parameter by name is nil.");
		STAssertNotNil(dateValue, @"String value from parameter by name is nil.");
		
		if(totalRowCount == 0)
		{
			STAssertEquals(1, intValue, @"Expected id of 1 for the first row.");
			STAssertEqualObjects(@"Test Name 1", stringValue, @"Expected Test Name 1 for first row.");
			STAssertEqualObjects([NSDate dateWithString:@"2001-01-05 01:00:00 +0000"], dateValue, @"Didn't get expected date value.");
		}
		else if(totalRowCount == 1)
		{
			STAssertEquals(2, intValue, @"Expected id of 2 for the second row.");
			STAssertEqualObjects(@"Test Name 2", stringValue, @"Expected Test Name 2 for second row.");
			STAssertEqualObjects([NSDate dateWithString:@"2002-02-15 11:10:10 +0000"], dateValue, @"Didn't get expected date value.");
		}
		else if(totalRowCount == 2)
		{
			STAssertEquals(30000000000000, int64Value, @"Expected id of 3 for the third row.");
			STAssertEqualObjects(@"Test Name 3", stringValue, @"Expected Test Name 3 for third row.");
			STAssertTrue([dateValue compare:[NSDate date]] != NSOrderedDescending, @"Expected current date to be equal or greater than database date.");
		}
	}
	
	STAssertEquals(totalRowCount, 3, @"Did not get 3 rows as expected.");
}

@end
