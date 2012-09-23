/*
 *  ExecuteAsRoot.c
 *  Uninstall
 *
 *  Created by Doug on 5/24/08.
 *  Copyright 2008 Douglas Richardson. All rights reserved.
 *
 * NOTE: This file must be compiled in C99 mode.
 */

#include "ExecuteAsRoot.h"
#import <Foundation/Foundation.h>
#import <SecurityFoundation/SFAuthorization.h>
#import <Security/Security.h>

FILE* ExecuteAsRoot(NSString* pathToExecutable, NSArray* arguments)
{
	FILE *result = NULL;
	
	if(pathToExecutable == nil)
	{
		NSLog(@"Error - ExecuteAsRoot got nil for the path to execute.");
		goto bail;
	}
	
	if(arguments == nil)
		arguments = [NSArray array];
	
	
	AuthorizationItem items[1];
	
	const char* tool = [pathToExecutable UTF8String];
	
	items[0].name = kAuthorizationRightExecute;
	items[0].value = (void*)tool;
	items[0].valueLength = strlen(items[0].value);
	items[0].flags = 0;
	
	AuthorizationRights rights;
	rights.count = 1;
	rights.items = items;
	
	SFAuthorization *sfAuth = [SFAuthorization authorizationWithFlags:kAuthorizationFlagInteractionAllowed | kAuthorizationFlagExtendRights
															   rights:&rights
														  environment:kAuthorizationEmptyEnvironment];
	AuthorizationRef authRef = [sfAuth authorizationRef];
	
	//NSLog(@"Got back an sfAuth = %@", sfAuth);
	//NSLog(@"Authorization reference: %p", [sfAuth authorizationRef]);
	
	if(authRef)
	{
		//NSLog(@"Executing tool as root");
		
		size_t count = [arguments count];
		const char* argv[count + 1];
		argv[count] = NULL; // Yay! C99 - variable length arrays
		
		for(size_t i = 0; i < count; ++i) // Yay! C99 - more flexible variable declaration
		{
			NSString *arg = [arguments objectAtIndex:i];
			if(![arg isKindOfClass:[NSString class]])
			{
				NSLog(@"Argument %lu is not an NSString. Skipping.", i);
				arg = @"";
			}
			
			argv[i] = [arg UTF8String];
		}
		
		OSStatus err = AuthorizationExecuteWithPrivileges([sfAuth authorizationRef], tool, kAuthorizationFlagDefaults, (char* const*)argv, &result);
		
		if(err != errAuthorizationSuccess)
			NSLog(@"Error executing tool '%s' with root privileges.", tool);
	}
	
bail:
	return result;
}
