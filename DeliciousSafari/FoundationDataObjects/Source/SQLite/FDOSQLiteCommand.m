//
//  FDOSQLiteCommand.m
//  FoundationDataObjects
//
//  Created by Doug on 1/4/09.
//  Copyright 2009 Douglas Richardson. All rights reserved.
//

#import "FDOSQLiteCommand.h"
#import "FDOSQLiteConnection.h"
#import "FDOSQLiteRecordSet.h"
#import "FDOSQLiteException.h"
#import "FDOSQLiteUtilities.h"
#import "FDOLog.h"

// Since the v2 methods aren't available in the iphone sdk yet, we use legacy crap.
#if MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_5
#warning Using legacy sqlite3 APIs
#define USE_LEGACY_SQLITE3 1
#endif

@interface FDOSQLiteCommand ()
-(void)preBindStatementCheck;
-(int)numberFromParameterName:(NSString*)namedParameter;
@end

@implementation FDOSQLiteCommand

-(id)initWithConnection:(FDOSQLiteConnection*)connection
{
	self = [super init];
	
	if(self)
	{
		_connection = [connection retain];
		shouldResetOnBind = NO;
	}
	
	return self;
}

-(void)dealloc
{
	[self close];	
	[_connection release];
	[_recordSet release];
	[_dateFormatter release];
	[super dealloc];
}

-(void)close
{
	if(_stmt)
	{
		[_recordSet commandWillClose];
		if(sqlite3_finalize(_stmt) != SQLITE_OK)
			FDOLog(LOG_WARNING, "[FDOSQLiteCommand close] Error finalizing statement. %s", sqlite3_errmsg([_connection db]));
		
		_stmt = NULL;
		shouldResetOnBind = NO;
	}
}

-(sqlite3_stmt*)stmt
{
	return _stmt;
}

-(sqlite3*)db
{
	return [_connection db];
}

-(void)prepare:(NSString*)sql
{
	[self close];
	
	if(sql == nil)
		sql = @"";
	
#ifdef THREAD_CHECKING
	NSLog(@"PREPARE [%@] - %@", [NSThread currentThread] != [NSThread mainThread] ? @"NOT MAIN THREAD!!!" : @"main thread", sql);
#endif
	
#ifdef USE_LEGACY_SQLITE3
	int rc = sqlite3_prepare([_connection db], [sql UTF8String], -1, &_stmt, NULL);
#else
	int rc = sqlite3_prepare_v2([_connection db], [sql UTF8String], -1, &_stmt, NULL);
#endif
	
	if(rc != SQLITE_OK)
	{
		[FDOException raise:kFDOSQLiteAPIException
					 format:@"[FDOSQLiteCommand prepare:] - sqlite3_prepare/sqlite3_prepare_v2 failed. %s", sqlite3_errmsg([_connection db])];
	}
}

-(void)preBindStatementCheck
{
	if(_stmt == NULL)
	{
		[FDOException raise:kFDOInvalidArgumentException
					 format:@"[FDOSQLiteCommand preBindStatementCheck] - Cannot bind value before calling prepare"];
	}
	
	if(shouldResetOnBind)
	{		
		/*
		 Don't check sqlite3_reset's return code because it will report the error code of a previous prepare call.
		 The following is from the sqlite3 documentation:
		 
		 If the most recent call to sqlite3_step(S) for the prepared statement S returned SQLITE_ROW or SQLITE_DONE,
		 or if sqlite3_step(S) has never before been called on S, then sqlite3_reset(S) returns SQLITE_OK.
		 
		 If the most recent call to sqlite3_step(S) for the prepared statement S indicated an error,
		 then sqlite3_reset(S) returns an appropriate error code.
		 */
		
		sqlite3_reset(_stmt);
		shouldResetOnBind = NO;
	}
}

-(void)bindString:(NSString*)value toParameterNumber:(int)parameter
{
	[self preBindStatementCheck];
	
	if(value == nil)
	{
		if(sqlite3_bind_null(_stmt, parameter) != SQLITE_OK)
		{
			[FDOException raise:kFDOSQLiteAPIException
						 format:@"[FDOSQLiteCommand bindString:toParameterNumber:] - Error calling sqlite3_bind_null. %s", sqlite3_errmsg([_connection db])];
		}
	}
	else
	{
		if(sqlite3_bind_text(_stmt, parameter, [value UTF8String] , -1, SQLITE_TRANSIENT) != SQLITE_OK)
			[FDOException raise:kFDOSQLiteAPIException
						 format:@"[FDOSQLiteCommand bindString:toParameterNumber:] - Error calling sqlite3_bind_text. %s", sqlite3_errmsg([_connection db])];
	}
}

-(void)bindInt:(int)value toParameterNumber:(int)parameter
{
	[self preBindStatementCheck];
	
	if(sqlite3_bind_int(_stmt, parameter, value) != SQLITE_OK)
	{
		[FDOException raise:kFDOSQLiteAPIException
					 format:@"[FDOSQLiteCommand bindInt:toParameterNumber:] - Error calling sqlite3_bind_int. %s", sqlite3_errmsg([_connection db])];
	}
}

-(void)bindInt64:(int64_t)value toParameterNumber:(int)parameter
{
	[self preBindStatementCheck];
	
	if(sqlite3_bind_int64(_stmt, parameter, value) != SQLITE_OK)
	{
		[FDOException raise:kFDOSQLiteAPIException
					 format:@"[FDOSQLiteCommand bindInt64:toParameterNumber:] - Error calling sqlite3_bind_int64. %s", sqlite3_errmsg([_connection db])];
	}
}

-(void)bindDate:(NSDate*)value toParameterNumber:(int)parameter
{
	if(_dateFormatter == nil)
		_dateFormatter = FDOSQLite_CreateDateFormatter();
	
	NSString *stringValue = [_dateFormatter stringFromDate:value];
	
	if(stringValue == nil)
	{
		[FDOException raise:kFDOTypeConversionFailedException
					 format:@"[FDOSQLiteCommand bindDate:toParameterNamed:] - Error converting date to string."];
	}
	
	[self bindString:stringValue toParameterNumber:parameter];	
	
}

-(int)numberFromParameterName:(NSString*)namedParameter
{
	if(_stmt == NULL)
	{
		[FDOException raise:kFDOInvalidArgumentException
					 format:@"[FDOSQLiteCommand numberFromParameterName:] - Cannot bind value before calling prepare"];
	}
	
	if(namedParameter == nil)
	{
		[FDOException raise:kFDOInvalidArgumentException
					 format:@"[FDOSQLiteCommand numberFromParameterName:] - Nil parameter name"];
	}
	
	int parameterNumber = sqlite3_bind_parameter_index(_stmt, [namedParameter UTF8String]);
	
	if(parameterNumber == 0)
	{
		[FDOException raise:kFDOInvalidArgumentException
					 format:@"[FDOSQLiteCommand numberFromParameterName:] - No parameter named '%@'", namedParameter];
	}
	
	return parameterNumber;
}

-(void)bindString:(NSString*)value toParameterNamed:(NSString*)parameter
{
	int parameterNumber = [self numberFromParameterName:parameter];
	[self bindString:value toParameterNumber:parameterNumber];
}

-(void)bindInt:(int)value toParameterNamed:(NSString*)parameter
{
	int parameterNumber = [self numberFromParameterName:parameter];
	[self bindInt:value toParameterNumber:parameterNumber];
	
}

-(void)bindInt64:(int64_t)value toParameterNamed:(NSString*)parameter
{
	int parameterNumber = [self numberFromParameterName:parameter];
	[self bindInt64:value toParameterNumber:parameterNumber];
}

-(void)bindDate:(NSDate*)value toParameterNamed:(NSString*)parameter
{
	int parameterNumber = [self numberFromParameterName:parameter];
	[self bindDate:value toParameterNumber:parameterNumber];
}

-(id <FDORecordSet>)executeQuery
{
	shouldResetOnBind = YES;
	
	if(_stmt == NULL)
	{
		[FDOException raise:kFDOInvalidArgumentException
					 format:@"[FDOSQLiteCommand executeQuery] - No statement prepared."];
	}
	
#ifdef THREAD_CHECKING
	if([NSThread currentThread] != [NSThread mainThread])
		NSLog(@"EXECUTE QUERY [%@]", [NSThread currentThread] != [NSThread mainThread] ? @"NOT MAIN THREAD!!!" : @"main thread");
#endif
	
	int rc = sqlite3_step(_stmt);
	
	if(rc == SQLITE_DONE)
		return nil;
	
	if(rc == SQLITE_ROW)
	{
		if(_recordSet == nil)
			_recordSet = [[FDOSQLiteRecordSet alloc] initWithCommand:self];
		
		[_recordSet setIsEOF:NO];
		
		return _recordSet;
	}
		
	[FDOException raise:kFDOSQLiteAPIException
				 format:@"[FDOSQLiteCommand executeQuery] - Error returned from sqlite3_step %d, %s", rc, sqlite3_errmsg([_connection db])];
	return nil;
}

@end
