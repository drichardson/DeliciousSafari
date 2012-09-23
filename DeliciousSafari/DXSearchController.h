//
//  DXSearchController.h
//  DeliciousSafari
//
//  Created by Doug on 9/16/09.
//  Copyright 2009 Douglas Richardson. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DXSearchController : NSWindowController
{
	IBOutlet NSTableView*	tableView;
	IBOutlet NSSearchField*	searchField;
	IBOutlet NSTextField*	resultTextField;
	
	NSMenu*		_searchMenu;
		
	NSArray*	_searchResults;
	NSImage*	defaultFavicon;
	BOOL		completePosting;
    BOOL		commandHandling;
	NSInteger	searchScope;
	BOOL		keepResultsOpen;
}

+ (DXSearchController*)sharedController;

- (id)init;

- (IBAction)performSearch:(id)sender;
- (IBAction)openURLsForSelectedItems:(id)sender;

@property(retain) NSImage *defaultFavicon;

@end
