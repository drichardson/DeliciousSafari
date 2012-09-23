//
//  DXSearchController.m
//  DeliciousSafari
//
//  Created by Doug on 9/16/09.
//  Copyright 2009 Douglas Richardson. All rights reserved.
//

#import "DXSearchController.h"
#import "DXSearchResultCell.h"
#import "DXDeliciousDatabase.h"
#import "DXFaviconDatabase.h"
#import "DXUtilities.h"

#define SEARCH_RESULT_COUNT_LIMIT 10000

#define kSearchByTagsTag	1
#define kSearchByTitlesTag	2
#define kKeepResultsOpenTag	3

#define kSearchScopeKey		@"DXSearchScope"
#define kKeepResultsOpenKey	@"DXKeepSearchResultsOpen"

@interface DXSearchController ()
- (void)performSearch;
- (NSMenu*)buildSearchMenu;

@property(retain) NSArray* searchResults;

@end

@implementation DXSearchController

@synthesize defaultFavicon, searchResults=_searchResults;

+ (DXSearchController*)sharedController
{
	static DXSearchController* controller;
	
	if(controller == nil)
	{
		controller = [DXSearchController new];
	}
	
	return controller;
}

- (id)init
{
	self = [super initWithWindowNibName:@"DXSearch" owner:self];
	
	if(self)
	{
		self.searchResults = [NSArray array];
		searchScope = kSearchByTagsTag;
	}
	
	return self;
}

- (void)dealloc
{
	self.searchResults = nil;
	self.defaultFavicon = nil;
	[super dealloc];
}

- (void)awakeFromNib
{
	NSNumber *searchScopeNum = [[NSUserDefaults standardUserDefaults] objectForKey:kSearchScopeKey];
	if(searchScopeNum && [searchScopeNum isKindOfClass:[NSNumber class]])
	{
		searchScope = [searchScopeNum intValue];
	}
	
	keepResultsOpen = [[NSUserDefaults standardUserDefaults] boolForKey:kKeepResultsOpenKey];
	
	_searchMenu = [self buildSearchMenu];
	[[searchField cell] setSearchMenuTemplate:_searchMenu];
	[[searchField cell] setMaximumRecents:20];
	
	[tableView setRowHeight:[DXSearchResultCell defaultCellHeight]];
	//[tableView setDoubleAction:@selector(openURLsForSelectedItems:)];
	[tableView setAction:@selector(openURLsForSelectedItems:)];
	
	[resultTextField setStringValue:@""];
	
	[[self window] center];
}

- (NSMenu*)buildSearchMenu
{
	// add the searchMenu to this control, allowing recent searches to be added.
	//
	// note that we could build this menu inside our nib, but for clarity we're
	// building the menu in code to illustrate the use of tags:
	//		NSSearchFieldRecentsTitleMenuItemTag, NSSearchFieldNoRecentsMenuItemTag, etc.
	//
	NSMenu* searchMenu = [[[NSMenu alloc] initWithTitle:@"Search Menu"] autorelease];
	[searchMenu setAutoenablesItems:YES];
	
	// first add our custom menu item (Important note: "action" MUST be valid or the menu item is disabled)
	NSMenuItem* findByTagsItem = [[NSMenuItem alloc] initWithTitle:@"Find by Tags" action:@selector(selectScope:) keyEquivalent:@""];
	[findByTagsItem setTarget:self];
	[findByTagsItem setTag:kSearchByTagsTag];
	[findByTagsItem setState:searchScope == kSearchByTagsTag ? NSOnState : NSOffState];
	[searchMenu addItem:findByTagsItem];
	[findByTagsItem release];
	
	NSMenuItem* findByTitleItem = [[NSMenuItem alloc] initWithTitle:@"Find by Title" action:@selector(selectScope:) keyEquivalent:@""];
	[findByTitleItem setTarget:self];
	[findByTitleItem setTag:kSearchByTitlesTag];
	[findByTitleItem setState:searchScope == kSearchByTitlesTag ? NSOnState : NSOffState];
	[searchMenu addItem:findByTitleItem];
	[findByTitleItem release];
	
	[searchMenu addItem:[NSMenuItem separatorItem]];
	NSMenuItem* keepSearchResultsOpenItem = [[NSMenuItem alloc] initWithTitle:@"Keep Open" action:@selector(keepSearchResultWindowOpen:) keyEquivalent:@""];
	[keepSearchResultsOpenItem setTarget:self];
	[keepSearchResultsOpenItem setTag:kKeepResultsOpenTag];
	[keepSearchResultsOpenItem setState:keepResultsOpen ? NSOnState : NSOffState];
	[searchMenu addItem:keepSearchResultsOpenItem];
	[keepSearchResultsOpenItem release];
	
#if 0
	[searchMenu addItem:[NSMenuItem separatorItem]];
		
	NSMenuItem* recentsTitleItem = [[NSMenuItem alloc] initWithTitle:@"Recent Searches" action:nil keyEquivalent:@""];
	// tag this menu item so NSSearchField can use it and respond to it appropriately
	[recentsTitleItem setTag:NSSearchFieldRecentsTitleMenuItemTag];
	[searchMenu addItem:recentsTitleItem];
	[recentsTitleItem release];
	
	NSMenuItem* norecentsTitleItem = [[NSMenuItem alloc] initWithTitle:@"No recent searches" action:nil keyEquivalent:@""];
	// tag this menu item so NSSearchField can use it and respond to it appropriately
	[norecentsTitleItem setTag:NSSearchFieldNoRecentsMenuItemTag];
	[searchMenu addItem:norecentsTitleItem];
	[norecentsTitleItem release];
	
	NSMenuItem* recentsItem = [[NSMenuItem alloc] initWithTitle:@"Recents" action:nil keyEquivalent:@""];
	// tag this menu item so NSSearchField can use it and respond to it appropriately
	[recentsItem setTag:NSSearchFieldRecentsMenuItemTag];
	[searchMenu addItem:recentsItem];
	[recentsItem release];
	
	NSMenuItem* separatorItem = (NSMenuItem*)[NSMenuItem separatorItem];
	// tag this menu item so NSSearchField can use it, by hiding/show it appropriately:
	[separatorItem setTag:NSSearchFieldRecentsTitleMenuItemTag];
	[searchMenu addItem:separatorItem];
	
	NSMenuItem* clearItem = [[NSMenuItem alloc] initWithTitle:@"Clear" action:nil keyEquivalent:@""];
	[clearItem setTag:NSSearchFieldClearRecentsMenuItemTag];	// tag this menu item so NSSearchField can use it
	[searchMenu addItem:clearItem];
	[clearItem release];
#endif
	
	return searchMenu;
}

- (void)performSearch
{
	NSString *searchString = [searchField stringValue];
		
	if(searchString && [searchString length] > 0)
	{
		switch (searchScope)
		{
			case kSearchByTagsTag:
			{
				NSMutableArray *tags = [[[searchString componentsSeparatedByString:@" "] mutableCopy] autorelease];
				[tags removeObject:@""];
				if(tags)
				{
					//NSLog(@"Searching for tags: %@", [tags componentsJoinedByString:@","]);
					self.searchResults = [[DXDeliciousDatabase defaultDatabase] postsForTagArray:tags];
				}
				else
				{
					self.searchResults = nil;
				}
				
				break;
			}
				
			case kSearchByTitlesTag:
			{
				self.searchResults = [[DXDeliciousDatabase defaultDatabase] findBookmarksWithTitlesContaining:searchString
																							  withResultLimit:SEARCH_RESULT_COUNT_LIMIT];
				break;
			}
				
			default:
			{
				NSLog(@"DeliciousSafari: Invalid search scope.");
				self.searchResults = nil;
				
				break;
			}
		}
		
		NSString *resultCount = [NSString stringWithFormat:DXLocalizedString(@"%d results", @"Result count format string for search window."), [_searchResults count]];
		[resultTextField setStringValue:resultCount];
	}
	else
	{
		self.searchResults = [NSArray array];
		[resultTextField setStringValue:@""];
	}
	
	[tableView reloadData];
}

- (IBAction)performSearch:(id)sender
{	
	[self performSearch];
}

- (IBAction)openURLsForSelectedItems:(id)sender
{	
	NSIndexSet *indexSet = [tableView selectedRowIndexes];
	
	if(indexSet == nil)
		return;
	
	NSInteger index;
	for(index = [indexSet firstIndex]; index != NSNotFound; index = [indexSet indexGreaterThanIndex:index]) 
	{
		NSDictionary *postDictionary = [_searchResults objectAtIndex:index];
		NSString *urlString = [postDictionary objectForKey:kDXPostURLKey];
		[[DXUtilities defaultUtilities] goToURL:urlString];
		if(!keepResultsOpen)
			[self close];
	}	
}

- (void)selectScope:(id)sender
{
	NSInteger newScope = [(NSMenuItem*)sender tag];
	if(searchScope != newScope)
	{
		searchScope = newScope;
		[[NSUserDefaults standardUserDefaults] setInteger:searchScope forKey:kSearchScopeKey];
		[self performSearch];
	}
}

- (void)keepSearchResultWindowOpen:(id)sender
{
	keepResultsOpen = !keepResultsOpen;
	[[NSUserDefaults standardUserDefaults] setBool:keepResultsOpen forKey:kKeepResultsOpenKey];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	switch([menuItem tag])
	{
		case kSearchByTagsTag:
		case kSearchByTitlesTag:
			[menuItem setState:searchScope == [menuItem tag] ? NSOnState : NSOffState];
			return YES;
			
		case kKeepResultsOpenTag:
			[menuItem setState:keepResultsOpen ? NSOnState : NSOffState];
			return YES;
	}
	
	return [super validateMenuItem:menuItem];
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)command
{
	//NSLog(@"doCommand: %@", NSStringFromSelector(command));
	
	if(control == searchField)
	{		
		if(command == @selector(moveDown:) || command == @selector(moveDownAndModifySelection:) ||
		   command == @selector(moveUp:) || command == @selector(moveUpAndModifySelection:) ||
		   command == @selector(insertNewline:))
		{
			//[tableView performSelector:command withObject:self];
			[tableView keyDown:[NSApp currentEvent]];
			return YES;
		}
		else if(command == @selector(scrollToEndOfDocument:) || command == @selector(moveToEndOfDocument:) ||
				command == @selector(scrollToBeginningOfDocument:) || command == @selector(moveToBeginningOfDocument:))
		{
			NSInteger rowCount = [tableView numberOfRows];
			if(rowCount > 0)
			{
				NSInteger row;
				if(command == @selector(scrollToEndOfDocument:) || command == @selector(moveToEndOfDocument:))
					row = rowCount - 1;
				else
					row = 0;

				
				[tableView scrollRowToVisible:row];
				[tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
			}
				
			return YES;
		}
		else if(command == @selector(scrollPageUp:) || command == @selector(scrollPageDown:))
		{
			NSRange visibleRows = [tableView rowsInRect:[tableView visibleRect]];
			if(visibleRows.location != NSNotFound && visibleRows.length > 0)
			{
				NSInteger newTopRow;
				if(command == @selector(scrollPageUp:))
					newTopRow = visibleRows.location - visibleRows.length + 1;
				else
					newTopRow = visibleRows.location + visibleRows.length * 2 - 2;

				newTopRow = MAX(0, MIN(newTopRow, [tableView numberOfRows] - 1));
				if(newTopRow < [tableView numberOfRows])
				{
					[tableView scrollRowToVisible:newTopRow];
					[tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:newTopRow] byExtendingSelection:NO];
				}
			}
			
			return YES;
		}
		
		if([textView respondsToSelector:command])
		{
			commandHandling = YES;
			[textView performSelector:command withObject:nil];
			commandHandling = NO;
			return YES;
		}
	}
	
	return NO;
}

// -------------------------------------------------------------------------------
//	control:textView:completions:forPartialWordRange:indexOfSelectedItem
//
//	Use this method to override NSFieldEditor's default matches (which is a much bigger
//	list of keywords).  By not implementing this method, you will then get back
//	NSSearchField's default feature.
// -------------------------------------------------------------------------------
- (NSArray*)control:(NSControl*)control textView:(NSTextView *)textView completions:(NSArray*)words forPartialWordRange:(NSRange)charRange indexOfSelectedItem:(NSInteger*)index
{
	if(control == searchField && searchScope == kSearchByTagsTag)
	{
		// TODO: Use FDO to search this instead of filtering an array.
		NSString* partialString = [[textView string] substringWithRange:charRange];
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF beginswith[cd] %@", partialString];
		return [[[DXDeliciousDatabase defaultDatabase] tags] filteredArrayUsingPredicate:predicate];
	}
	
	return [NSArray array];
}

// -------------------------------------------------------------------------------
//	controlTextDidChange:obj
//
//	The text in NSSearchField has changed, try to attempt type completion.
// -------------------------------------------------------------------------------
- (void)controlTextDidChange:(NSNotification*)obj
{
	NSTextView* textView = [[obj userInfo] objectForKey:@"NSFieldEditor"];
	
    if (searchScope == kSearchByTagsTag && !completePosting && !commandHandling) // prevent calling "complete" too often
	{
        completePosting = YES;
        [textView complete:nil];
        completePosting = NO;
    }
}

#pragma mark NSTableViewDataSource methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [_searchResults count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	// Have to implement something so NSTableView doesn't complain in Console.
	return nil;
}

#pragma mark NSTableViewDelegate methods
- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	DXSearchResultCell *cell = (DXSearchResultCell*)aCell;
	
	NSDictionary *postDictionary = [_searchResults objectAtIndex:rowIndex];
	NSString *title = [postDictionary objectForKey:kDXPostDescriptionKey];
	NSString *urlString = [postDictionary objectForKey:kDXPostURLKey];
	NSString *notes = [postDictionary objectForKey:kDXPostExtendedKey];
	NSImage *favicon = nil;
	
	if(title == nil)
		title = @"";
	
	if(urlString == nil)
		urlString = @"";
	else
		favicon = [[DXFaviconDatabase defaultDatabase] faviconForURLString:urlString];
	
	if(notes == nil)
		notes = @"";	
	
	if(favicon == nil)
		favicon = defaultFavicon;
	
	[cell setTitle:title];
	[cell setFavicon:favicon];
	[cell setURLString:urlString];
	[cell setNotes:notes];
}

@end
