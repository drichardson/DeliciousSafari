//
//  FDOCommand.h
//  FoundationDataObjects
//
//  Created by Doug on 1/4/09.
//  Copyright 2009 Douglas Richardson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <inttypes.h>
#import "FDORecordSet.h"

typedef int64_t FDORowID;

@protocol FDOCommand < NSObject >

-(void)prepare:(NSString*)sql;

-(void)bindString:(NSString*)value toParameterNumber:(int)parameter;
-(void)bindInt:(int)value toParameterNumber:(int)parameter;
-(void)bindInt64:(int64_t)value toParameterNumber:(int)parameter;
-(void)bindDate:(NSDate*)value toParameterNumber:(int)parameter;

-(void)bindString:(NSString*)value toParameterNamed:(NSString*)parameter;
-(void)bindInt:(int)value toParameterNamed:(NSString*)parameter;
-(void)bindInt64:(int64_t)value toParameterNamed:(NSString*)parameter;
-(void)bindDate:(NSDate*)value toParameterNamed:(NSString*)parameter;

- (id<FDORecordSet>)executeQuery;

@end
