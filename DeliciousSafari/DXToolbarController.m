//
//  DXToolbarController.m
//  Safari Delicious Extension
//
//  Created by Doug on 5/9/08.
//  Copyright 2008 Douglas Richardson. All rights reserved.
//

#import "DXToolbarController.h"
#import "MethodSwizzle.h"
#import "DXUtilities.h"

static DXToolbarController* dxToolbarController = nil;

static NSString *kDXSafariBrowserWindowToolbarConfigurationKey = @"values.NSToolbar Configuration BrowserWindowToolbarIdentifier";

static NSToolbarItem*
dxToolbarItemForItemIdentifierWillBeInsertedIntoToolbar(id self, SEL _cmd, NSToolbar* toolbar, NSString* itemIdentifier, BOOL flag);

static NSArray*
dxToolbarAllowedItemIdentifiers(id self, SEL _cmd, NSToolbar* toolbar);

static NSString* MakeToolbarItemPositionKey(NSToolbarItem* toolbarItem);

@interface DXToolbarController (private)
-(NSArray*)itemIdentifiers;
@end


@implementation DXToolbarController

+(DXToolbarController*)theController
{	
	if(dxToolbarController == nil)
	{
		dxToolbarController = [[DXToolbarController alloc] init];
		
		Class toolbarControllerClass = NSClassFromString(@"ToolbarController");
		
		//
		// Add two new methods to Safari's ToolbarController that will be swizzled into place.
		// - (NSToolbarItem *)dxToolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
		// - (NSArray *)dxToolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
		//
		BOOL rc;
		rc = class_addMethod(toolbarControllerClass,
							 @selector(dxToolbar:itemForItemIdentifier:willBeInsertedIntoToolbar:),
							 (IMP)dxToolbarItemForItemIdentifierWillBeInsertedIntoToolbar,
							 "@@:@@c");
		
		if(!rc)
			NSLog(@"DeliciousSafari couldn't add dxToolbar:itemForItemIdentifier:willBeInsertedIntoToolbar: to ToolbarController. No toolbar item will be available.");
		
		rc = class_addMethod(toolbarControllerClass,
							 @selector(dxToolbarAllowedItemIdentifiers:),
							 (IMP)dxToolbarAllowedItemIdentifiers,
							 "@@:@");
		
		if(!rc)
			NSLog(@"DeliciousSafari couldn't add dxToolbarAllowedItemIdentifiers: to ToolbarController. No toolbar item will be available.");
		
		
		rc = DXMethodSwizzle(toolbarControllerClass,
							 @selector(toolbar:itemForItemIdentifier:willBeInsertedIntoToolbar:),
							 @selector(dxToolbar:itemForItemIdentifier:willBeInsertedIntoToolbar:));
		
		if(!rc)
			NSLog(@"DeliciousSafari will not be able to add toolbar items to Safari because the toolbar item method could not be swapped out.");
		else
		{
			rc = DXMethodSwizzle(toolbarControllerClass,
								 @selector(dxToolbarAllowedItemIdentifiers:),
								 @selector(toolbarAllowedItemIdentifiers:));
			
			if(!rc)
				NSLog(@"DeliciousSafari will not be able to add toolbar items to Safari because the available toolbar item method could not be swapped out.");
		}
	}
	
	return dxToolbarController;
}

-(id)init
{
	self = [super init];
	
	if(self)
	{
		mItemsDictionary = [[NSMutableDictionary alloc] init];
		
		[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
																  forKeyPath:kDXSafariBrowserWindowToolbarConfigurationKey
																	 options:NSKeyValueObservingOptionNew
																	 context:nil];
	}
	
	return self;
}

-(void)dealloc
{	
	// This shouldn't get hit. Once you swizzle the methods in, you don't want to go away.
	NSLog(@"Unexpected dealloc in DXToolbarController");
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:kDXSafariBrowserWindowToolbarConfigurationKey];
	[mBrowserWindowToolbar release];
	dxToolbarController = nil;
	[mItemsDictionary release];
	[super dealloc];
}

- (NSWindow*)findBrowserWindow
{	
	Class browserWindowClass = NSClassFromString(@"BrowserWindow");
	
	if(browserWindowClass)
	{
		for(NSWindow *window in [NSApp orderedWindows])
		{
			if([window isKindOfClass:browserWindowClass])
			{
				//NSLog(@"Found a Safari window of class: %@", [window class]);
				return window;
			}
		}
	}
	else
	{
		NSLog(@"DeliciousSafari could not find BrowserWindow class. That means the toolbar item will not be available.");
	}
	
	return nil;
}

-(void)addToolbarItem:(NSToolbarItem*)toolbarItem withDefaultPosition:(NSInteger)defaultPosition
{
	if(toolbarItem == nil)
	{
		NSLog(@"DeliciousSafari addToolbarItem: toolbarItem is nil");
		return;
	}
	
	//NSLog(@"Adding delicious safari toolbar item.");
	[mItemsDictionary setObject:toolbarItem forKey:[toolbarItem itemIdentifier]];
	
	// See if we should load this item into the toolbar.
	if(mBrowserWindowToolbar == nil)
		mBrowserWindowToolbar = [[[self findBrowserWindow] toolbar] retain];
	
	if(mBrowserWindowToolbar)
	{
		NSString *toolbarItemKey = MakeToolbarItemPositionKey(toolbarItem);
		NSNumber *position = [[NSUserDefaults standardUserDefaults] objectForKey:toolbarItemKey];
		NSInteger insertAtPosition = -1;
		
		if(position)
		{
			//NSLog(@"Inserting toolbar item into saved position %@", position);
			insertAtPosition = [position integerValue];
		}
		else
		{
			// Insert into default position.
			NSLog(@"Inserting toolbar item into default location.");
			insertAtPosition = defaultPosition;
			[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:defaultPosition] forKey:toolbarItemKey];
		}
		
		if(insertAtPosition >= 0)
		{					
			NSInteger count = [[mBrowserWindowToolbar items] count];
			if(insertAtPosition > count)
				insertAtPosition = count;
			
			//NSLog(@"Inserting toolbar at position %d", insertAtPosition);
			[mBrowserWindowToolbar insertItemWithItemIdentifier:[toolbarItem itemIdentifier] atIndex:insertAtPosition];
		}
		else
		{
			NSLog(@"Position is negative so I'm not inserting the toolbar item.");
		}
	}
}

-(NSArray*)itemIdentifiers
{
	NSArray* result = [mItemsDictionary allKeys];
	if(result == nil)
		result = [NSArray array];
	
	return result;
}

-(NSToolbarItem*)itemForIdentifier:(NSString*)itemIdentifier
{
	return [mItemsDictionary objectForKey:itemIdentifier];
}

#pragma mark Notification handlers

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	//static int x; // The changing x makes sure this shows up in console so syslog doesn't collapse it into "Previous message repeated x times...".
	//NSLog(@"Observed change: %@, %@, %d", keyPath, change, ++x);
	
	// Update the toolbar item positions in user defaults
	for(NSString *itemKey in mItemsDictionary)
	{
		NSToolbarItem *item = [mItemsDictionary objectForKey:itemKey];
		NSUInteger index = [[mBrowserWindowToolbar items] indexOfObject:item];
		NSNumber *position = [NSNumber numberWithInteger:(index == NSNotFound) ? -1 : (NSInteger)index];
		[[NSUserDefaults standardUserDefaults] setObject:position forKey:MakeToolbarItemPositionKey(item)];
	}
}

@end

// The methods in here extend the ToolbarController, which is an internal Safari class. After the methods are swizzled,
// you can call the original method by calling the new method. For instance, if [self x] was swizzled with [self y], then
// calling [self y] actually calls the original [self x]. This makes swizzling useful for playing nicely with multiple
// plug-ins, because you can keep adding to the swizzle chain.

@interface NSObject (makeWarningsGoAway)
- (NSToolbarItem*)dxToolbar:(NSToolbar*)toolbar itemForItemIdentifier:(NSString*)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag;
- (NSArray*)dxToolbarAllowedItemIdentifiers:(NSToolbar*)toolbar;
@end

static NSToolbarItem*
dxToolbarItemForItemIdentifierWillBeInsertedIntoToolbar(id self, SEL _cmd, NSToolbar* toolbar, NSString* itemIdentifier, BOOL flag)
{
	NSToolbarItem *result = [dxToolbarController itemForIdentifier:itemIdentifier];
		
	if(result != nil)
	{
		// On Tiger, if a copy of the toolbar item is not made then our toolbar item will get destroyed if the following happens:
		// 1. A second Safari window is created (an ignored exception will actually occur here)
		// 2. A Safari window is closed.
		// RESULT: The remaining Safari windows lose their DeliciousSafari toolbar button and Command keys stop working.
		if(![[DXUtilities defaultUtilities] isLeopardOrLater])
			result = [[result copy] autorelease];
	}
	else
		result = [self dxToolbar:toolbar itemForItemIdentifier:itemIdentifier willBeInsertedIntoToolbar:flag];
	
	return result;
}

static NSArray*
dxToolbarAllowedItemIdentifiers(id self, SEL _cmd, NSToolbar* toolbar)
{
	NSMutableArray *items = [[[self dxToolbarAllowedItemIdentifiers:toolbar] mutableCopy] autorelease];
		
	if(dxToolbarController)
		[items addObjectsFromArray:[dxToolbarController itemIdentifiers]];
	
	return items;
}

static NSString* MakeToolbarItemPositionKey(NSToolbarItem* toolbarItem)
{
	return [@"DXToolbarItemPosition-" stringByAppendingString:[toolbarItem itemIdentifier]];
}
