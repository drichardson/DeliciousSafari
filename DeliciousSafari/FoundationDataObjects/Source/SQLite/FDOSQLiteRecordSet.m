//
//  FDSQLiteRecordset.m
//  FoundationDataObjects
//
//  Created by Doug on 1/4/09.
//  Copyright 2009 Douglas Richardson. All rights reserved.
//

#import "FDOSQLiteRecordSet.h"
#import "FDOSQLiteCommand.h"
#import "FDOSQLiteException.h"
#import "FDOSQLiteUtilities.h"
#import "FDOLog.h"

@implementation FDOSQLiteRecordSet

-(id)initWithCommand:(FDOSQLiteCommand*)command
{
	self = [super init];
	
	if(self != nil)
	{
		_command = [command retain];
		
		if(_command == nil)
		{
			[FDOException raise:kFDOInvalidArgumentException format:@"Command is nil."];
			[self release];
			return nil;
		}
		
		_isEOF = YES;
	}
	
	return self;
}

-(void)dealloc
{
	[_command release];
	[_dateFormatter release];
	[_columnNameToIndexMap release];
	[super dealloc];
}

-(void)moveFirst
{
	sqlite3_stmt *stmt = [_command stmt];
	
	if(stmt == NULL)
	{
		[FDOException raise:kFDOCommandClosedException format:@"moveFirst called with a closed command."];
		goto bail;
	}
	
	if(sqlite3_reset(stmt) != SQLITE_OK)
	{
		[FDOException raise:kFDOSQLiteAPIException format:@"[FDOSQLiteRecordSet moveFirst] - sqlite3_reset failed. %s", sqlite3_errmsg([_command db])];
		goto bail;
	}
	
	[self moveNext];
	
bail:
	;
}

-(void)moveNext
{
	sqlite3_stmt *stmt = [_command stmt];
	if(stmt == NULL)
		[FDOException raise:kFDOCommandClosedException format:@"[FDOSQLiteRecordSet moveNext] - Associated FDOCommand is closed."];
	
	int rc = sqlite3_step(stmt);
	_isEOF = rc == SQLITE_ROW ? NO : YES;
	
	if(rc != SQLITE_DONE && rc != SQLITE_ROW)
		FDOLog(LOG_INFO, "[FDOSQLiteRecordSet moveNext] - sqlite3_step returned unexpected value %d. %s", rc, sqlite3_errmsg([_command db]));
}

-(BOOL)isEOF
{
	return _isEOF;
}

-(NSString*)stringValueForColumnNumber:(int)columnNumber
{
	sqlite3_stmt *stmt = [_command stmt];
	
	if(stmt == NULL)
		[FDOException raise:kFDOCommandClosedException format:@"[FDOSQLiteRecordSet stringValueForColumnNumber:] - Associated FDOCommand is closed."];
	
	NSString *result = nil;
	const char* columnValue = (const char*)sqlite3_column_text(stmt, columnNumber);
	if(columnValue != NULL)
		result = [NSString stringWithUTF8String:columnValue];
	
	return result;
}

-(int)intValueForColumnNumber:(int)columnNumber
{
	sqlite3_stmt *stmt = [_command stmt];
	
	if(stmt == NULL)
		[FDOException raise:kFDOCommandClosedException format:@"[FDOSQLiteRecordSet intValueForColumnNumber:] - Associated FDOCommand is closed."];
	
	return sqlite3_column_int(stmt, columnNumber);
}

-(int64_t)int64ValueForColumnNumber:(int)columnNumber
{
	sqlite3_stmt *stmt = [_command stmt];
	
	if(stmt == NULL)
		[FDOException raise:kFDOCommandClosedException format:@"[FDOSQLiteRecordSet int64ValueForColumnNumber:] - Associated FDOCommand is closed."];
	
	return sqlite3_column_int64(stmt, columnNumber);
}

-(NSDate*)dateValueForColumnNumber:(int)columnNumber
{
	NSString *stringValue = [self stringValueForColumnNumber:columnNumber];
	
	if(stringValue == nil)
		return nil;
	
	if(_dateFormatter == nil)
		_dateFormatter = FDOSQLite_CreateDateFormatter();
	
	NSDate *result = [_dateFormatter dateFromString:stringValue];
	
	if(result == nil)
		[FDOException raise:kFDOTypeConversionFailedException format:@"Error converting string to date with NSDateFormatter."];
	
	return result;	
}

-(void)buildColumnNameToIndexMap
{
	sqlite3_stmt *stmt = [_command stmt];
	
	if(stmt == NULL)
		[FDOException raise:kFDOInvalidArgumentException format:@"[FDOSQLiteRecordSet stringValueForColumnNamed:] - Associated FDOCommand is closed."];
	
	if(_columnNameToIndexMap == nil)
	{
		_columnNameToIndexMap = [[NSMutableDictionary alloc] init];
		
		int count = sqlite3_column_count(stmt);
		for(int columnNumber = 0; columnNumber < count; columnNumber++)
		{
			const char* columnName = sqlite3_column_name(stmt, columnNumber);
			
			if(columnName == NULL)
			{
				[FDOException raise:kFDOSQLiteAPIException
							 format:@"[FDOSQLiteRecordSet buildColumnNameToIndexMap:] - Unexpected error. sqlite3_column_name returned NULL."];
			}
			
			[_columnNameToIndexMap setObject:[NSNumber numberWithInt:columnNumber] forKey:[NSString stringWithUTF8String:columnName]];
		}
	}
}

-(NSString*)stringValueForColumnNamed:(NSString*)columnName
{	
	if(_columnNameToIndexMap == nil)
		[self buildColumnNameToIndexMap];
	
	NSString *result = nil;
	NSNumber *columnNumber = [_columnNameToIndexMap objectForKey:columnName];
	if(columnNumber == nil)
		[FDOException raise:kFDOInvalidArgumentException format:@"[FDOSQLiteRecordSet stringValueForColumnNamed:] - Invalid column name %@", columnName];
	else
		result = [self stringValueForColumnNumber:[columnNumber intValue]];
	
	return result;
}

-(int)intValueForColumnNamed:(NSString*)columnName
{
	if(_columnNameToIndexMap == nil)
		[self buildColumnNameToIndexMap];
	
	int result = 0;
	NSNumber *columnNumber = [_columnNameToIndexMap objectForKey:columnName];
	if(columnNumber == nil)
		[FDOException raise:kFDOInvalidArgumentException format:@"[FDOSQLiteRecordSet intValueForColumnNamed:] - Invalid column name %@", columnName];
	else
		result = [self intValueForColumnNumber:[columnNumber intValue]];
	
	return result;
}

-(int64_t)int64ValueForColumnNamed:(NSString*)columnName
{
	if(_columnNameToIndexMap == nil)
		[self buildColumnNameToIndexMap];
	
	int64_t result = 0;
	NSNumber *columnNumber = [_columnNameToIndexMap objectForKey:columnName];
	if(columnNumber == nil)
		[FDOException raise:kFDOInvalidArgumentException format:@"[FDOSQLiteRecordSet int64ValueForColumnNamed:] - Invalid column name %@", columnName];
	else
		result = [self int64ValueForColumnNumber:[columnNumber intValue]];
	
	return result;
}

-(NSDate*)dateValueForColumnNamed:(NSString*)columnName
{
	if(_columnNameToIndexMap == nil)
		[self buildColumnNameToIndexMap];
	
	NSDate *result = nil;
	NSNumber *columnNumber = [_columnNameToIndexMap objectForKey:columnName];
	if(columnNumber == nil)
		[FDOException raise:kFDOInvalidArgumentException format:@"[FDOSQLiteRecordSet dateValueForColumnNamed:] - Invalid column name %@", columnName];
	else
		result = [self dateValueForColumnNumber:[columnNumber intValue]];
	
	return result;
}

-(void)commandWillClose
{
	_isEOF = YES;
	
	// Since the associated command's new statement can be anything, the name to index table has to be re-built.
	[_columnNameToIndexMap release];
	_columnNameToIndexMap = nil;
}

-(void)setIsEOF:(BOOL)isEOF
{
	_isEOF = isEOF;
}

@end
