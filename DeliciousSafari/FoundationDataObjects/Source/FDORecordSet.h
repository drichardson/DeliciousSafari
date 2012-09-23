//
//  FDORecordSet.h
//  FoundationDataObjects
//
//  Created by Doug on 1/4/09.
//  Copyright 2009 Douglas Richardson. All rights reserved.
//

#import <Foundation/Foundation.h>

// An FDORecordSet is associated with an FDOCommand. If you do something
// to the FDOCommand (like call prepare) any data in the FDORecordSet
// is wiped out.

@protocol FDORecordSet < NSObject >

-(void)moveFirst; // Move to the first record in the recordset.
-(void)moveNext; // Move to the next record in the recordset.
-(BOOL)isEOF; // If true, you have gone past all the last record in the recordset.

-(NSString*)stringValueForColumnNumber:(int)columnNumber;
-(int)intValueForColumnNumber:(int)columnNumber;
-(int64_t)int64ValueForColumnNumber:(int)columnNumber;
-(NSDate*)dateValueForColumnNumber:(int)columnNumber;

-(NSString*)stringValueForColumnNamed:(NSString*)columnName;
-(int)intValueForColumnNamed:(NSString*)columnName;
-(int64_t)int64ValueForColumnNamed:(NSString*)columnName;
-(NSDate*)dateValueForColumnNamed:(NSString*)columnName;

@end
