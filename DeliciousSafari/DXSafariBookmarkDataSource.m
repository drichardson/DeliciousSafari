//
//  DXSafariBookmarkDataSource.m
//  Safari Delicious Extension
//
//  Created by Doug on 1/2/08.
//  Copyright 2008 Douglas Richardson. All rights reserved.
//

#import "DXSafariBookmarkDataSource.h"

static NSString *const kShouldImport = @"ShouldImportToDelicious";

@interface DXSafariBookmarkDataSource (private)
-(void)loadSafariBookmarks;
-(NSInteger)childCount:(id)item;
@end

@implementation DXSafariBookmarkDataSource

-(id)init
{
	if([super init])
	{
		[self loadSafariBookmarks];
	}
	
	return self;
}

-(void)dealloc
{
	[safariBookmarksDict release];
	[super dealloc];
}

NSString *const kImportTagsSet = @"ImportTagsSet";
NSString *const kImportURLString= @"ImportURLString";
NSString *const kImportTitleString = @"ImportTitleString";

static NSString* folderNameToTag(NSString *folderName)
{
	// Remove all spaces in the folder name.
	// Example: Folder name Testing Folder would become TestingFolder.	
	NSMutableString *tagName = [NSMutableString string];
	
	NSArray *tagNameComponents = [folderName componentsSeparatedByString:@" "];
	NSEnumerator *tagNameComponentsEnum = [tagNameComponents objectEnumerator];
	NSString *component = nil;
	
	while(component = [tagNameComponentsEnum nextObject])
	{
		if([component length] > 0)
		{
			[tagName appendString:component];
		}
	}
	
	
	//NSLog(@"Returning tagName: '%@'", tagName);
	return tagName;
}

-(void)itemsToImportRecursive:(NSDictionary*)item 
		 withResultDictionary:(NSMutableDictionary*)resultDictionary
				   withTagSet:(NSSet*)tagSet
{
	if([self isLeafItem:item])
	{
		NSNumber *shouldImport = [item objectForKey:kShouldImport];
		if(shouldImport == nil || [shouldImport boolValue])
		{
			// Add this bookmark to the result dictionary. If it is already in the result dictionary,
			// then union this bookmark's folders with the current result.
			NSString *title = [[item objectForKey:@"URIDictionary"] objectForKey:@"title"];
			NSString *url = [item objectForKey:@"URLString"];
			
			if(title != nil && url != nil)
			{
				NSMutableDictionary *currentValue = [resultDictionary objectForKey:url];
				if(currentValue == nil)
				{
					// This is a new URL so add it to the resultDictionary.
					currentValue = [NSMutableDictionary dictionaryWithObjectsAndKeys:title, kImportTitleString,
									url, kImportURLString,
									[[tagSet mutableCopy] autorelease], kImportTagsSet,
									nil];
					[resultDictionary setObject:currentValue forKey:url];
				}
				else
				{
					// This is an existing bookmark. Union the folders for this item with the exising ones.
					NSMutableSet *currentValueTagsSet = [currentValue objectForKey:kImportTagsSet];
					[currentValueTagsSet unionSet:tagSet];
				}
			}
			else
			{
				NSLog(@"Error processing bookmark because either title (%@) or URL (%@) was nil", title, url);
			}
		}
	}
	else if([self isListItem:item])
	{
		NSString *tagName = folderNameToTag([item objectForKey:@"Title"]);
		NSMutableSet *newTagsSet = [NSMutableSet setWithSet:tagSet];
		
		if([tagName length] > 0)
			[newTagsSet addObject:tagName];
		
		NSMutableArray *children = [item objectForKey:@"Children"];
		NSEnumerator *childEnum = [children objectEnumerator];
		NSMutableDictionary *child = nil;
		
		while(child = [childEnum nextObject])
		{
			[self itemsToImportRecursive:child withResultDictionary:resultDictionary withTagSet:newTagsSet];
		}
	}
}

-(NSArray*)itemsToImport
{
	NSMutableDictionary *results = [NSMutableDictionary dictionary];
	
	[self itemsToImportRecursive:safariBookmarksDict
			withResultDictionary:results
					  withTagSet:[NSSet set]];
	
	return [results allValues];
}

-(void)loadSafariBookmarks
{
	[safariBookmarksDict release];
	
	NSString *bookmarksPlistPath = [@"~/Library/Safari/Bookmarks.plist" stringByExpandingTildeInPath];
	NSData *plistData = [NSData dataWithContentsOfFile:bookmarksPlistPath];
	if(plistData == nil)
		goto bail;
	
	NSString *errorString = nil;
	NSMutableDictionary *plistDictionary = [NSPropertyListSerialization propertyListFromData:plistData
																			mutabilityOption:NSPropertyListMutableContainersAndLeaves
																					  format:NULL
																			errorDescription:&errorString];
	
	if(errorString != nil)
	{
		NSLog(@"Error reading bookmarks '%@'. Reason: %@", bookmarksPlistPath, errorString);
		[errorString release];
	}
	
	safariBookmarksDict = [plistDictionary retain];
	
bail:
	if(safariBookmarksDict == nil)
		safariBookmarksDict = [[NSDictionary dictionary] retain];
}

-(NSInteger)childCount:(id)item
{
	NSInteger count = 0;
	
	if(item == nil)
		item = safariBookmarksDict;
	
	NSArray *children = [item objectForKey:@"Children"];
	
	if(children != nil && [children respondsToSelector:@selector(objectEnumerator)])
	{
		NSDictionary *child;
		NSEnumerator *childEnum = [children objectEnumerator];
		while(child = [childEnum nextObject])
		{
			if([self isListItem:child] || [self isLeafItem:child])
				++count;
		}
	}
	
	return count;
}

-(NSString*)bookmarkType:(id)item
{	
	if(item == nil)
		item = safariBookmarksDict;
	
	NSString *bookmarkType = [item objectForKey:@"WebBookmarkType"];
	if(bookmarkType == nil)
		bookmarkType = @"UNKNOWN TYPE";
	
	return bookmarkType;
}

-(BOOL)isListItem:(id)item
{
	return [[self bookmarkType:item] isEqual:@"WebBookmarkTypeList"];
}

-(BOOL)isLeafItem:(id)item
{
	return [[self bookmarkType:item] isEqual:@"WebBookmarkTypeLeaf"];
}


// Outline Data Source methods
- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	return [self childCount:item];
}


- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	return ([self childCount:item] > 0) ? YES : NO;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
	NSDictionary *child = nil;
	
	if(item == nil)
		item = safariBookmarksDict;
	
	NSArray *children = [item objectForKey:@"Children"];
	
	// The index given is a logical index. The actual index needs to be found by filtering
	// out the unsupported data types. Need to find the index-th object in the list that matches.
	const NSInteger count = [children count];
	NSInteger index_i = -1;
	NSInteger actual_index = 0;
	for(actual_index = 0; actual_index < count; actual_index++)
	{
		NSDictionary *node = [children objectAtIndex:actual_index];
		if([self isLeafItem:node] || [self isListItem:node])
		{
			index_i++;
			if(index_i == index)
			{
				child = node;
				break;
			}
		}
	}
	
	//NSLog(@"Returning child (%d, %d): %@, %@, %d, %d", index, actual_index, child, [self bookmarkType:child], [self isLeafItem:child], [self isListItem:child]);
	
	return child;
}

-(NSString*)titleForItem:(id)item
{
	NSString *title = nil;
	
	if([self isListItem:item])
		title = [item objectForKey:@"Title"];
	else if([self isLeafItem:item])			
		title = [[item objectForKey:@"URIDictionary"] objectForKey:@"title"];
	
	return title;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	id value = nil;
	
	// TODO: Read this value from the actual data store indicating whether or not to import.
	if(tableColumn == nil || [[tableColumn identifier] isEqual:@"checkBox"])
		value = [NSNumber numberWithInt:1];
	
	return value;
}

-(int)checkStateOfItem:(id)item
{
	int state = NSOffState;
	
	if([self isLeafItem:item])
	{
		// A bookmark's state is either NSOffState or NSOnState, depending on the value
		// corresponding to the kShouldImport key.
		// NSOnState if YES or nil.
		// NSOffState if NO.
		NSNumber *shouldImport = [item objectForKey:kShouldImport];
		if(shouldImport == nil || [shouldImport boolValue])
			state = NSOnState;
		else
			state = NSOffState;
	}
	else if([self isListItem:item])
	{
		// A list's state is determined by the state of all decendants. In order of precedence:
		// NSOffState, if none of the children are checked or there are no children.
		// NSOnState, if all of the children are checked.
		// NSMixedState, if there are multiple bookmarks with different states.
		int onCount = 0, offCount = 0;
		NSMutableArray *children = [item objectForKey:@"Children"];
		int i = 0, childCount = [children count];
		for(i = 0; i < childCount; i++)
		{
			NSMutableDictionary *child = [children objectAtIndex:i];
			switch([self checkStateOfItem:child])
			{
				case NSOffState:
					offCount++;
					break;
				case NSOnState:
					onCount++;
					break;
			}
		}
		
		if(childCount <= 0 || offCount == childCount)
			state = NSOffState;
		else if(onCount == childCount)
			state = NSOnState;
		else
			state = NSMixedState;
	}
	
	return state;
}

-(void)setCheckState:(int)state forItem:(id)item
{
	if([self isLeafItem:item])
	{
		[item setObject:[NSNumber numberWithBool:(state == NSOnState) ? YES : NO] forKey:kShouldImport];
	}
	else if([self isListItem:item])
	{
		NSMutableArray *children = [item objectForKey:@"Children"];
		int count = [children count];
		int i = 0;
		for(i = 0; i < count; ++i)
		{
			NSMutableDictionary *child = [children objectAtIndex:i];
			[self setCheckState:state forItem:child];
		}
	}
}

@end
