//
//  FDOConnection.m
//  FoundationDataObjects
//
//  Created by Doug on 1/4/09.
//  Copyright 2009 Douglas Richardson. All rights reserved.
//

#import "FDOConnection.h"
#import "FDOSQLiteConnection.h"
#import "FDOLog.h"

id <FDOConnection> FDOCreateSQLiteConnection(NSString* pathToDatabaseFile)
{
	return [[FDOSQLiteConnection alloc] initWithPathToDatabase:pathToDatabaseFile];
}
