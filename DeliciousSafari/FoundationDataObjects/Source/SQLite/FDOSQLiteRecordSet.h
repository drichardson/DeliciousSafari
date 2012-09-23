//
//  FDSQLiteRecordSet.h
//  FoundationDataObjects
//
//  Created by Doug on 1/4/09.
//  Copyright 2009 Douglas Richardson. All rights reserved.
//

#import "FDORecordSet.h"

@class FDOSQLiteCommand;

@interface FDOSQLiteRecordSet : NSObject <FDORecordSet> {
	BOOL _isEOF;
	FDOSQLiteCommand *_command;
	NSDateFormatter *_dateFormatter;
	NSMutableDictionary *_columnNameToIndexMap;
}

-(id)initWithCommand:(FDOSQLiteCommand*)command;

-(void)commandWillClose; // Called by FDOSQLiteCommand when the associated command is closing.
-(void)setIsEOF:(BOOL)isEOF; // Called by FDOSQLiteCommand to update the isEOF flag.

@end
