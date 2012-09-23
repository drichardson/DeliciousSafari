//
//  SafariController.m
//  DeliciousSafari
//
//  Created by Doug on 8/29/09.
//  Copyright 2009 Douglas Richardson. All rights reserved.
//

#import "SafariController.h"

static SafariController* _sharedController;

@implementation SafariController

+(void)initialize
{
	static BOOL isInitialized = NO;
	if(!isInitialized)
	{
		isInitialized = YES;
		_sharedController = [[SafariController alloc] init];
	}
}

+(SafariController*)sharedController
{
	return _sharedController;
}

-(void)loadDeliciousSafariIntoApplication:(NSString*)applicationName
{
	//NSLog(@"Tell %@ to load delicioussafari via Apple Script additions.", applicationName);
	
	
	// tell application "Safari"
	//   do loadDeliciousSafari
	// end tell
	
	NSString *script = [NSString stringWithFormat:@"tell application \"%@\"\ndo loadDeliciousSafari\nend tell",
						applicationName];
	
	
	NSAppleScript *as = [[NSAppleScript alloc] initWithSource:script];
	NSDictionary *errorInfo = nil;
	NSAppleEventDescriptor* scriptResult = [as executeAndReturnError:&errorInfo];
	[as release];
	
	if(scriptResult == nil)
		NSLog(@"Error loading DeliciousSafari into %@. Error Info: %@", applicationName, errorInfo);
}

@end
