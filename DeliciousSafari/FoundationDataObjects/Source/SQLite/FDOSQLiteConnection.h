//
//  FDOSQLiteConnection.h
//  FoundationDataObjects
//
//  Created by Doug on 1/4/09.
//  Copyright 2009 Douglas Richardson. All rights reserved.
//

#import "FDOConnection.h"
#import <sqlite3.h>

@class FDOSQLiteCommand;

@interface FDOSQLiteConnection : NSObject < FDOConnection > {
	sqlite3 *_db;
	NSMutableSet *_openCommands; // All open commands associated with this connection.
}

-(id)initWithPathToDatabase:(NSString*)pathToDatabaseFile;
-(sqlite3*)db;
-(void)commandWillClose:(FDOSQLiteCommand*)command;

@end
