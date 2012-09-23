//
//  AppController.m
//  DeliciousSafari
//
//  Created by Doug on 8/29/09.
//  Copyright 2009 Douglas Richardson. All rights reserved.
//

#import "AppController.h"
#import "SafariController.h"

@implementation AppController

-(id)init
{
	self = [super init];
	if(self)
		_supportedApplicationArray = [[NSArray alloc] initWithObjects:@"com.apple.Safari", @"org.webkit.nightly.WebKit", nil];
	return self;
}

-(void)dealloc
{
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
	[_supportedApplicationArray release];
	[super dealloc];
}

- (void)noticedApplication:(NSRunningApplication*)runningApp
{
	//NSLog(@"Noticed application: %@, localized name: %@", runningApp.bundleIdentifier, runningApp.localizedName);
	
    NSString* bundleID = runningApp.bundleIdentifier;
    
    if(bundleID && [_supportedApplicationArray containsObject:bundleID])
	{
		//NSLog(@"Try to load Delicioussafari in %@", runningApp.bundleIdentifier);
		[[SafariController sharedController] loadDeliciousSafariIntoApplication:runningApp.localizedName];
	}
}

-(void)applicationDidFinishLaunching:(NSNotification*)notification
{
    // Watch for application launch notifications.
	[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
														   selector:@selector(applicationLaunchedNotification:)
															   name:NSWorkspaceDidLaunchApplicationNotification
															 object:nil];
    
    // If Safari (or one of the other _supportedApplications is already running, load DeliciousSafari into it
    [[[NSWorkspace sharedWorkspace] runningApplications] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [self noticedApplication:(NSRunningApplication*)obj];
    }];
    
}

-(void)applicationLaunchedNotification:(NSNotification*)notification
{
	NSRunningApplication *runningApp = [[notification userInfo] objectForKey:NSWorkspaceApplicationKey];
    [self noticedApplication:runningApp];
	
}

@end
