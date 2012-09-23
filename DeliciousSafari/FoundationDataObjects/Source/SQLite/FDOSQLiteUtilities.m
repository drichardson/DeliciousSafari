//
//  FDOSQLiteUtilities.m
//  FoundationDataObjects
//
//  Created by Doug on 1/7/09.
//  Copyright 2009 Douglas Richardson. All rights reserved.
//

#import "FDOSQLiteUtilities.h"


NSDateFormatter* FDOSQLite_CreateDateFormatter()
{
	NSDateFormatter *result = [[NSDateFormatter alloc] init];
	[result setFormatterBehavior:NSDateFormatterBehavior10_4];
	[result setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
	[result setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
	return result;
}
