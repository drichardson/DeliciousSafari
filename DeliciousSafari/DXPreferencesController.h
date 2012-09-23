//
//  DXPreferencesController.h
//  DeliciousSafari
//
//  Created by Doug on 3/14/09.
//  Copyright 2009 Douglas Richardson. All rights reserved.
//

#import <Cocoa/Cocoa.h>


#warning Need to make this a NSWindowController
@interface DXPreferencesController : NSObject {
	IBOutlet NSWindow *_window;
	IBOutlet NSButton *_downloadFavicons;
	IBOutlet NSButton *_checkForBookmarksAtStart;
	IBOutlet NSButton *_checkForBookmarksEveryXMinutes;
	IBOutlet NSTextField *_xMinutes;
	IBOutlet NSButton *_shareBookmarksByDefault;
	
	NSMutableArray *_topLevelNIBObjects;
}

+(void)showPreferences;

-(IBAction)resetPreferences:(id)sender;
-(IBAction)preferencesChanged:(id)sender;

@end
