//
//  FDOLog.m
//  FoundationDataObjects
//
//  Created by Doug on 1/4/09.
//  Copyright 2009 Douglas Richardson. All rights reserved.
//

#import "FDOLog.h"
#import <stdarg.h>
#import <Foundation/Foundation.h>

void FDOLog(int level, const char *format, ...)
{
	va_list va;
	va_start(va, format);
	
	char buf[1000];
	vsnprintf(buf, sizeof(buf), format, va);
	
	syslog(level, "%s", buf);
	
	va_end(va);
}
