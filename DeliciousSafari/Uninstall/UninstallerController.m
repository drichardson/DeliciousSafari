//
//  UninstallerController.m
//  Uninstall
//
//  Created by Douglas Richardson on 10/5/07.
//  Copyright 2007 Douglas Richardson. All rights reserved.
//

#import "UninstallerController.h"
#import "ExecuteAsRoot.h"

@implementation UninstallerController

- (void)awakeFromNib
{
	[window center];
	[window setDelegate:self];
}

-(void)dealloc
{
	[window setDelegate:nil];
	[super dealloc];
}

// This method must be run on the main thread.
-(void)uninstallSucceeded
{
	[uninstallSuccessfulImageView setHidden:NO];
	[uninstallSuccessfulTextField setHidden:NO];
	
	[cancelButton setTitle:@"Quit"];
	[cancelButton setEnabled:YES];
	[cancelButton setKeyEquivalent:@"\r"];
	[window makeFirstResponder:cancelButton];
	
	[[NSSound soundNamed:@"Glass"] play];
}

-(void)uninstallFailedOrCancelled
{
	[uninstallButton setEnabled:YES];
	[cancelButton setEnabled:YES];
}

-(void)performUninstall:(id)arg
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	BOOL succeeded = NO;

	// Unload the launchd plist in the user's session.
	system("launchctl unload -S Aqua /Library/LaunchAgents/com.delicioussafari.DeliciousSafariAgent.plist");
	
	NSString *dsUninstallerToolPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Contents/Support/DSUninstaller"];
	NSMutableArray *args = [NSMutableArray array];
	
	const char* homeDir = getenv("HOME");
	if(homeDir)
	{
		[args addObject:[NSString stringWithUTF8String:homeDir]];
	}
	
	FILE* fpIO = ExecuteAsRoot(dsUninstallerToolPath, args);
	while(fpIO != NULL && !feof(fpIO))
	{
		char buf[512];
		char *result = fgets(buf, sizeof(buf), fpIO);
		if(result && strcmp(result, "OK\n") == 0)
		{
			NSLog(@"DeliciousSafari uninstalled successfully.");
			succeeded = YES;
		}
	}

	
	if(succeeded)
		[self performSelectorOnMainThread:@selector(uninstallSucceeded) withObject:nil waitUntilDone:NO];
	else
		[self performSelectorOnMainThread:@selector(uninstallFailedOrCancelled) withObject:nil waitUntilDone:NO];
	
	[pool release];
}

- (IBAction)uninstall:(id)sender
{
	[uninstallButton setEnabled:NO];
	[cancelButton setEnabled:NO];
	[NSThread detachNewThreadSelector:@selector(performUninstall:) toTarget:self withObject:nil];
}

- (IBAction)cancel:(id)sender
{
	[window orderOut:self];
	[NSApp terminate:self];
}

- (void)windowWillClose:(NSNotification *)notification
{
	[window setDelegate:nil];
	[NSApp terminate:self];
}

@end
