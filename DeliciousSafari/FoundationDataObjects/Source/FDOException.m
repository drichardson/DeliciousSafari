//
//  FDOException.m
//  FoundationDataObjects
//
//  Created by Doug on 1/4/09.
//  Copyright 2009 Douglas Richardson. All rights reserved.
//

#import "FDOException.h"
#import "FDOLog.h"

@implementation FDOException

- (id)initWithName:(NSString *)name reason:(NSString *)reason userInfo:(NSDictionary *)userInfo
{
	self = [super initWithName:name reason:reason userInfo:userInfo];
	
	if(self)
	{
		FDOLog(LOG_ERR, "FDOException thrown. Name: %s. Reason: %s", [name UTF8String], [reason UTF8String]);
	}
	
	return self;
}

@end
