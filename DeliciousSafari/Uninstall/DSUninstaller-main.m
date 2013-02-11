//
//  DSUninstaller-main.m
//  DeliciousSafari
//
//  Created by Doug on 9/2/09.
//  Copyright 2009 Douglas Richardson. All rights reserved.
//

#import <Foundation/Foundation.h>

static void removeFiles(NSArray* files);

int main(int argc, char **argv)
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
	NSMutableArray *pathsToRemove = [NSMutableArray arrayWithObjects:
									 // Snow Leopard files
									 @"/Library/Application Support/DeliciousSafari",
									 @"/Library/LaunchAgents/com.delicioussafari.DeliciousSafariAgent.plist",
									 @"/Library/ScriptingAdditions/DeliciousSafari Addition.osax",
									 
									 // Post-SIMBL DeliciousSafari files
									 @"/Library/InputManagers/DeliciousSafari",
									 									 
									 nil];
	
	
	if(argc >= 2)
	{
		// Old SIMBL per-user DeliciousSafari files
		NSString *userHome = [NSString stringWithUTF8String:argv[1]];
		[pathsToRemove addObject:[userHome stringByAppendingPathComponent:@"/Library/Application Support/SIMBL/Plugins/DeliciousSafari.bundle"]];
		[pathsToRemove addObject:[userHome stringByAppendingPathComponent:@"/Library/Preferences/com.delicioussafari.DeliciousSafari.plist"]];
		[pathsToRemove addObject:[userHome stringByAppendingPathComponent:@"/Library/Application Support/DeliciousSafari"]];
	}
	
	removeFiles(pathsToRemove);	
		
	[pool release];
	
	printf("OK\n"); // Tells the parent app we are done.	
	return 0;
}

static void removeFiles(NSArray* paths)
{
	NSFileManager *fm = [NSFileManager defaultManager];
	
	for(NSString *path in paths)
	{
		NSLog(@"Removing '%@'", path);
        NSError* error = nil;
        BOOL success = [fm removeItemAtPath:path error:&error];
        if ( !success )
        {
            NSLog(@"Error removing %@. %@", path, error);
        }
        
	}
}
