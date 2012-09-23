/*
 *  ExecuteAsRoot.h
 *  Uninstall
 *
 *  Created by Doug on 5/24/08.
 *  Copyright 2008 Douglas Richardson. All rights reserved.
 *
 */

#import <Foundation/Foundation.h>

// Execute a command as root with the given arguments. On success, returns
// a FILE* for the communication channel to the running program.
// On failure, returns NULL.
// If a non-NULL FILE* is returned, it must be freed using fclose.
FILE* ExecuteAsRoot(NSString* pathToExecutable, NSArray* arguments);
