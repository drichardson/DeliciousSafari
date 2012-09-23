//
//  DXTagMenuController.m
//  Safari Delicious Extension
//
//  Created by Doug on 4/27/08.
//  Copyright 2008 Douglas Richardson. All rights reserved.
//

#import "DXTagMenuController.h"
#import "DXDeliciousMenuItem.h"
#import "NSString+DXTruncatedStrings.h"
#import "DXUtilities.h"
#import "DXFaviconDatabase.h"

@interface DXTagMenuController (private)
-(void)menuNeedsUpdate:(NSMenu*)menu; // NSMenu delegate
-(void)mainMenuNeedsUpdate;
-(void)tagMenuNeedsUpdate:(NSMenu*)menu;

-(void)addTags:(NSArray*)tags toMenu:(NSMenu*)tm;
@end

@implementation DXTagMenuController

-(id)initWithDatabase:(DXDeliciousDatabase*)database
			 withMenu:(NSMenu*)menu
		 withTagImage:(NSImage*)tagImage
  withDefaultURLImage:(NSImage*)defaultURLImage
   withMenuItemTarget:(NSObject*)target
   withMenuItemAction:(SEL)action
{
	return [self initWithDatabase:database
						 withMenu:menu
						  atIndex:0
					 withTagImage:tagImage
			  withDefaultURLImage:defaultURLImage
			   withMenuItemTarget:target
			   withMenuItemAction:action
			   withRestrictToTags:nil];
}

-(id)initWithDatabase:(DXDeliciousDatabase*)database
			 withMenu:(NSMenu*)menu atIndex:(int)menuIndex
		 withTagImage:(NSImage*)tagImage
  withDefaultURLImage:(NSImage*)defaultURLImage
   withMenuItemTarget:(NSObject*)target
   withMenuItemAction:(SEL)action
   withRestrictToTags:(NSArray*)tagArray
{
	self = [super init];
	
	if(self)
	{
		if(menu == nil || database == nil)
		{
			NSLog(@"DXTagMenuController got invalid parameters to initWithDatabase.");
			[self release];
			self = nil;
		}
		else
		{
			mMenu = [menu retain];
			mMenuIndex = menuIndex;
			mDatabase = [database retain];
			mRestrictToTags = [tagArray retain];
			mTagImage = [tagImage retain];
			mDefaultURLImage = [defaultURLImage retain];
			mHasAddedTopLevelItems = NO;
			mMenuToTagArrayMap = [[NSMutableDictionary alloc] init];
			mMenuItemTarget = [target retain];
			mMenuItemAction = action;
			mEmptyTagsTitle = [DXLocalizedString(@"(Empty)", @"Title of the tags sub-menu when there are no tags.") retain];
			
			[mMenu setDelegate:self];
		}
	}
	
	return self;
}

-(void)dealloc
{
	//NSLog(@"tag menu controller dealloc");
	[mDatabase release];
	[mMenu release];
	[mRestrictToTags release];
	[mTagImage release];
	[mDefaultURLImage release];
	[mMenuToTagArrayMap release];
	[mMenuItemTarget release];
	[mEmptyTagsTitle release];
	[super dealloc];
}

// NSMenu delegate to control menu creation on the fly.
-(void)menuNeedsUpdate:(NSMenu*)menu
{
	if(menu == mMenu)
	{
		//NSLog(@"Top menu update");
		[self mainMenuNeedsUpdate];
	}
	else
	{
		//NSLog(@"Tag menu update: %@", [menu title]);
		[self tagMenuNeedsUpdate:menu];
	}
}

-(void)mainMenuNeedsUpdate
{
	if(mHasAddedTopLevelItems)
		goto end;
	
	NSArray *tags = mRestrictToTags != nil ? mRestrictToTags : [mDatabase tags];
	
	[self addTags:tags toMenu:mMenu];
	mHasAddedTopLevelItems = YES;
	
end:
	;
}

// tags can either be an array of NSString objects or an array of NSArray objects.
// If it is an array of NSArray objects, then it represents an intersection.
-(void)addTags:(NSArray*)tags toMenu:(NSMenu*)tm
{	
	NSEnumerator *tagEnum = [tags objectEnumerator];
	BOOL atLeastOneTag = NO;
	NSObject* tagObject = nil; // will be either an NSString or an NSArray.
	int nextMenuIndex = mMenuIndex;
	
	while(tagObject = [tagEnum nextObject])
	{
		atLeastOneTag = YES;
		
		NSArray *tagArray = nil;
		
		if([tagObject isKindOfClass:[NSArray class]])
			tagArray = (NSArray*)tagObject;
		else
			tagArray = [NSArray arrayWithObject:tagObject];
		
		
		NSString *tagDisplayName = [tagArray componentsJoinedByString:@"+"];
		
		NSMenuItem *tagMenuItem = [[[NSMenuItem alloc] initWithTitle:tagDisplayName action:nil keyEquivalent:@""] autorelease];
		NSMenu *tagSubMenu = [[[NSMenu alloc] initWithTitle:tagDisplayName] autorelease];
		[tagSubMenu setDelegate:self];
		
		[tagMenuItem setSubmenu:tagSubMenu];
		[tagMenuItem setImage:mTagImage];
		[mMenuToTagArrayMap setObject:tagArray forKey:[tagSubMenu title]];
		
		[tm insertItem:tagMenuItem atIndex:nextMenuIndex++];
	}
	
	if(!atLeastOneTag)
	{
		NSMenuItem *emptyMenuItem = [[NSMenuItem alloc] initWithTitle:@"(Empty)" action:NULL keyEquivalent:@""];
		[tm addItem:emptyMenuItem];
		[emptyMenuItem release];
	}
}

-(void)tagMenuNeedsUpdate:(NSMenu*)menu
{
	if([menu numberOfItems] > 0)
		goto end;
	
	NSArray *tagArray = [mMenuToTagArrayMap objectForKey:[menu title]];
	if(tagArray == nil)
	{
		NSLog(@"Got unexpected nil tagArray.");
		goto end;
	}
	
	NSString *oneTag = nil;
	NSEnumerator *tagArrayEnum = [tagArray objectEnumerator];
	while(oneTag = [tagArrayEnum nextObject])
	{
		// For each tag in the component array, create a popular on Delicious entry. This is done as the
		// composite entry doesn't seem to give any results for popular items.
		NSString *onDeliciousTitle = [NSString stringWithFormat:@"\"%@\" on Delicious", oneTag];
		NSString *onDeliciousURL = [NSString stringWithFormat:@"http://delicious.com/popular/%@", oneTag];
		DXDeliciousMenuItem *onDeliciousMenuItem = [[DXDeliciousMenuItem alloc] initWithTitle:onDeliciousTitle
																					  withURL:onDeliciousURL
																				   withTarget:mMenuItemTarget
																				 withSelector:mMenuItemAction];
		[onDeliciousMenuItem setImage:mTagImage];
		[menu addItem:onDeliciousMenuItem];
		[onDeliciousMenuItem release];
	}
	
	[menu addItem:[NSMenuItem separatorItem]];
	
	NSArray *postArray;
	
	if([[NSUserDefaults standardUserDefaults] boolForKey:@"DXSortBookmarksByTitle"])
	{
		postArray = [mDatabase postsForTagArrayOrderedByTitle:tagArray];
	}
	else
	{
		postArray = [mDatabase postsForTagArray:tagArray];
	}

	
	NSEnumerator *postEnum = [postArray objectEnumerator];
	NSDictionary *post;
	BOOL tagIsEmpty = YES;
	DXFaviconDatabase *faviconDatabase = [DXFaviconDatabase defaultDatabase];
	
	while(post = [postEnum nextObject])
	{
		tagIsEmpty = NO;
		NSString *title = [post objectForKey:kDXPostDescriptionKey];
		NSString *url = [post objectForKey:kDXPostURLKey];
		DXDeliciousMenuItem *postMenuItem = [[DXDeliciousMenuItem alloc] initWithTitle:[title stringByTruncatedInMiddleIfLengthExceeds:kDXMaxMenuTitleLength]
																			   withURL:url
																			withTarget:mMenuItemTarget
																		  withSelector:mMenuItemAction];
		
		NSImage *icon = [faviconDatabase faviconForURLString:url];
		if(icon == nil)
			icon = mDefaultURLImage;
		
		[postMenuItem setImage:icon];
		
		[menu addItem:postMenuItem];
		[postMenuItem release];
	}
	
	if(tagIsEmpty)
	{
		NSMenuItem *emptyMenuItem = [[NSMenuItem alloc] initWithTitle:mEmptyTagsTitle action:NULL keyEquivalent:@""];
		[emptyMenuItem setImage:mTagImage];
		[menu addItem:emptyMenuItem];
		[emptyMenuItem release];
	}	
	
end:
	;
}

- (BOOL)menuHasKeyEquivalent:(NSMenu *)menu forEvent:(NSEvent *)event target:(id *)target action:(SEL *)action
{
	// This greatly improves performance on application quit and tabbing from the location field to the
	// Google search field. Other places that needs to do a full menu scan (except for help, which unfortunately needs
	// to build the entire menu to do a menu item title search) will also benefit from this.
	return NO;
}

@end
