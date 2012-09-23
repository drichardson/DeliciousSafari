//
//  DXPreferencesController.m
//  DeliciousSafari
//
//  Created by Doug on 3/14/09.
//  Copyright 2009 Douglas Richardson. All rights reserved.
//

#import "DXPreferencesController.h"
#import "DXPreferences.h"

@interface DXPreferencesController ()
- (void)populateUI;
@end

@implementation DXPreferencesController

static DXPreferencesController *_sharedController;

+(void)showPreferences
{
	if(_sharedController == nil)
		_sharedController = [[DXPreferencesController alloc] init];
	else
		[_sharedController->_window makeKeyAndOrderFront:self];
}

-(id)init
{
	self = [super init];
	
	if(self)
	{
#warning Get rid of this when I make it a window controller
		_topLevelNIBObjects = [[NSMutableArray alloc] init];
		NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"DXPreferences" ofType:@"nib"];
		
		NSDictionary *externalNameTable = [NSDictionary dictionaryWithObjectsAndKeys:
										   self, NSNibOwner,
										   _topLevelNIBObjects, NSNibTopLevelObjects,
										   nil];
		
		[NSBundle loadNibFile:path externalNameTable:externalNameTable withZone:[self zone]];
	}
	
	return self;
}

-(void)awakeFromNib
{	
	[_window center];
}

-(void)dealloc
{	
	if(_sharedController == self)
		_sharedController = nil;
	
	[_window setDelegate:nil];
	
	// Release the top level objects in the NIB.
	NSObject *nibObject;
	NSEnumerator *nibObjectEnum = [_topLevelNIBObjects objectEnumerator];
	while (nibObject = [nibObjectEnum nextObject])
		[nibObject release];
	
	[_topLevelNIBObjects release];
	
	[super dealloc];
}

-(IBAction)resetPreferences:(id)sender
{
	[[DXPreferences sharedPreferences] resetToDefaults];
	[self populateUI];
}

#define BOOLState(button) ([button state] == NSOnState ? YES : NO)

-(IBAction)preferencesChanged:(id)sender
{
	DXPreferences *prefs = [DXPreferences sharedPreferences];
	
	if(sender == _downloadFavicons)
		[prefs setShouldDownloadFavicons:BOOLState(_downloadFavicons)];
	else if(sender == _checkForBookmarksAtStart)
		[prefs setShouldCheckForBookmarksAtStart:BOOLState(_checkForBookmarksAtStart)];
	else if(sender == _checkForBookmarksEveryXMinutes)
		[prefs setShouldCheckForBookmarksAtInterval:BOOLState(_checkForBookmarksEveryXMinutes)];
	else if(sender == _xMinutes)
		[prefs setBookmarkCheckInterval:[(NSNumber*)[[_xMinutes cell] objectValue] floatValue] * 60.0];
	else if(sender == _shareBookmarksByDefault)
		[prefs setShouldShareBookmarksByDefault:BOOLState(_shareBookmarksByDefault)];
	
	[self populateUI];
}

#define BOOLToState(b) (b ? NSOnState : NSOffState)

- (void)populateUI
{
	DXPreferences *prefs = [DXPreferences sharedPreferences];
	
	[_downloadFavicons setState:BOOLToState([prefs shouldDownloadFavicons])];
	[_checkForBookmarksAtStart setState:BOOLToState([prefs shouldCheckForBookmarksAtStart])];
	
	[_checkForBookmarksEveryXMinutes setState:BOOLToState([prefs shouldCheckForBookmarksAtInterval])];
	[[_xMinutes cell] setObjectValue:[NSNumber numberWithDouble:[prefs bookmarkCheckInterval] / 60.0]];
	[_xMinutes setEnabled:[prefs shouldCheckForBookmarksAtInterval]];
	
	[_shareBookmarksByDefault setState:BOOLToState([prefs shouldShareBookmarksByDefault])];
}


#pragma mark ---- NSWindow Delegate Methods ----
- (void)windowWillClose:(NSNotification *)notification
{
	if([notification object] == _window)
	{
		// The user may have made changes to the minutes field without exiting, which means
		// preferencesChanged wouldn't be called. Call it now in case that happens.
		[self preferencesChanged:_xMinutes];
		
		// Free up the controller now that the window is closed. However, wait until the notification completes
		// before releasing, which is why an autorelease is used.
		[_window setDelegate:nil];
		[self autorelease];
	}
}

@end
