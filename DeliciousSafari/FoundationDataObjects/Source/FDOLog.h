//
//  FDOLog.h
//  FoundationDataObjects
//
//  Created by Doug on 1/4/09.
//  Copyright 2009 Douglas Richardson. All rights reserved.
//

#include <syslog.h>

void FDOLog(int level, const char *format, ...) __attribute__((format(printf, 2, 3)));
