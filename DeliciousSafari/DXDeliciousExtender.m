//
//  DeliciousExtender.m
//  Safari Delicious Extension
//
//  Created by Douglas Richardson on 7/29/07.
//  Copyright 2007 Douglas Richardson. All rights reserved.
//

#import "DXDeliciousExtender.h"
#import "DXDeliciousMenuItem.h"
#import "DXUtilities.h"
#import "DXButtonIconCell.h"
#import "DXToolbarController.h"
#import "DXFaviconDatabase.h"
#import "NSString+DXTruncatedStrings.h"
#import "DXPreferences.h"
#import "DXSearchController.h"
#import "DXTextLimitFormatter.h"

void DXLoadPlugin(void);

static void my_SCNetworkReachabilityCallBack(SCNetworkReachabilityRef target,
											 SCNetworkConnectionFlags flags,
											 void *info);


static NSString * const kTokenFieldSeparator= @",";
static NSString * const kUnfiledDeliciousTag = @"system:unfiled";

static const unsigned kMaxTitleLength				= 255;
static const unsigned kMaxExtendedDescriptionLength = 1000;

@interface DXDeliciousExtender (Private)

+ (void) loadPlugin;

- (void) addMenu;
- (void) createDeliciousMenu;
- (NSMenu*) createRecentMenu;
- (NSMenu*) createDeliciousWebsiteMenu;

-(void)setSavedLastUpdatedTime:(NSDate*)lastUpdatedTime;
-(NSDate*)savedLastUpdatedTime;

- (void) login;
- (void) loginWithFirstResponder:(NSResponder*)firstResponder;

- (void) post;
- (void) manageFavoriteTags;
- (void) menuItemAction;

- (void) annoyanceCheck;

-(void)importNextItem;
-(void)setImportTagsToAdd:(NSArray*)tagArray;
-(void)setEnabledForImporterFields:(BOOL)enabled;

-(void)displayPostErrorAlert:(NSDictionary*)postDictionary;
-(void)setIsOnline:(BOOL)isOnline;

-(void)downloadFaviconsIfEnabled;
@end

@implementation DXDeliciousExtender

// Load is called when the class is added to the Objective-C runtime, which is even before initialize. Don't do much here.
// This method is only used to load DeliciousSafari in the InputManager cause since that is loaded before
// NSApplicationWillFinishLaunchingNotification is generated. For the scripting addition method, DXLoadPlugin() is used.
+ (void) load
{
	//NSLog(@"DeliciousSafari load called");
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(appDidFinishLaunchingNotification:)
												 name:NSApplicationWillFinishLaunchingNotification
											   object:nil];
}

+ (void)appDidFinishLaunchingNotification:(NSNotification*)notification
{
	[self loadPlugin];
}

+ (void) loadPlugin
{
	static BOOL isPluginLoaded = NO;
	
	if(isPluginLoaded)
	{
		//NSLog(@"Plugin already loaded. Skipping.");
		return;
	}

	isPluginLoaded = YES;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
	//NSLog(@"DeliciousSafari load called: Main bundle identifier is %@", bundleIdentifier);
	
	NSArray *bundlesToLoadWith = [NSArray arrayWithObjects:@"com.apple.Safari", nil];
	
	if(bundleIdentifier != nil && [bundlesToLoadWith containsObject:bundleIdentifier])
	{
		//NSLog(@"DeliciousSafari loadPlugin called");
		DXDeliciousExtender* plugin = [[DXDeliciousExtender alloc] init];
		if(plugin)
		{
			[plugin addMenu];
			//NSLog(@"DeliciousSafari loaded");
		}
		// else NSLog(@"Bundles: %@", [NSBundle allBundles]);
	}
	//else NSLog(@"Not loading DeliciousSafari because bundle identifier is %@", bundleIdentifier);
}

- (void)awakeFromNib
{
	// Post window
	
	DXTextLimitFormatter *formatter = [[DXTextLimitFormatter new] autorelease];
	formatter.maximumLength = kMaxTitleLength;
	[postName setFormatter:formatter];
	
	[postNotes setDelegate:self];
	
	[postTags setTokenizingCharacterSet:[NSCharacterSet characterSetWithCharactersInString:kTokenFieldSeparator]];
	
	[postPopularTagsLayoutView setHorizontalPadding:2.0];
	[postPopularTagsLayoutView setVerticalPadding:2.0];
	
	spellCheckingFieldEditor = [[NSTextView alloc] initWithFrame:NSZeroRect];
	[spellCheckingFieldEditor setFieldEditor:YES];
	[spellCheckingFieldEditor setContinuousSpellCheckingEnabled:YES];
	
	// Import window
	[importerAddTags setTokenizingCharacterSet:[NSCharacterSet characterSetWithCharactersInString:kTokenFieldSeparator]];
}

- (void)upgradeOldDatabaseIfNecessary
{
	if([mDB databaseVersion] == 0)
	{
		NSLog(@"Upgrading DeliciousSafari database.");
		[mDB cleanupObsoleteDatabaseFields];
		[mDB setLastUpdated:nil];
		[mDB setDatabaseVersion:1];
	}
}

- (id)init
{
	if([super init])
	{
        deliciousSafariBundle = [[NSBundle bundleWithIdentifier:@"com.delicioussafari.DeliciousSafari"] retain];
        
        id shortVersion = @"0.9"; // Never used. If this ever occurs, there is some sort of problem.
        id bundleVersion = @"000";
        deliciousSafariBundle = [[NSBundle bundleWithIdentifier:@"com.delicioussafari.DeliciousSafari"] retain];
        if(deliciousSafariBundle)
        {
            // Get image resources for the menus.
            NSString* path = [deliciousSafariBundle pathForImageResource:@"url"];
            if(path)
                urlImage = [[NSImage alloc] initWithContentsOfFile:path];
            
            path = [deliciousSafariBundle pathForImageResource:@"toolbaritem"];
            if(path)
                toolbarItemImage = [[NSImage alloc] initWithContentsOfFile:path];
            
            // Get the version number from the Info.plist file.
            id tmpBundleVersion = [deliciousSafariBundle objectForInfoDictionaryKey:@"CFBundleVersion"];
            if(tmpBundleVersion != nil)
                bundleVersion = tmpBundleVersion;
            
            // Get the build number from the Info.plist file.
            id tmpShortVersion = [deliciousSafariBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
            if(tmpShortVersion != nil)
                shortVersion = tmpShortVersion;
        }
        
        if ([deliciousSafariBundle loadNibNamed:@"DXExtenderResources" owner:self topLevelObjects:&deliciousSafariBundleTopLevelObjects])
		{
            // prevent top level objects from deallocating.
            [deliciousSafariBundleTopLevelObjects retain];
            
			mCurrentSheet = nil;
			mIsDeliciousMenuAdded = NO;
			
			mDB = [[DXDeliciousDatabase defaultDatabase] retain];
			[self upgradeOldDatabaseIfNecessary];
			
			[loginWindowUserRegistrationLink setURL:[NSURL URLWithString:@"https://secure.delicious.com/register"]];
			[loginWindowUserRegistrationLink setDelegate:self];
			
			[aboutWindowDeliciousSafariLink setURL:[NSURL URLWithString:@"http://delicioussafari.com"]];
			[aboutWindowDeliciousSafariLink setDelegate:self];
			
			// NSTableView maintains a weak reference to its data source, so don't autorelease it.
			favoritesDataSource = [[DXFavoritesDataSource alloc] initWithTags:[mDB favoriteTags]];
			[favoriteTagsTable setDataSource:favoritesDataSource];
            
            
            NSString *versionFormat = DXLocalizedString(@"Version %@ (%@)",
                                                        @"Version number format string. First argument is short version and second is bundle version.");
            [aboutWindowVersion setStringValue:[NSString stringWithFormat:versionFormat, shortVersion, bundleVersion]];
            
			
            NSBundle *coreTypesBundle = [NSBundle bundleWithPath:@"/System/Library/CoreServices/CoreTypes.bundle"];
            
            if(coreTypesBundle != nil)
            {
                NSString *path = [coreTypesBundle pathForImageResource:@"GenericFolderIcon"];
                if(path)
                {
                    folderImage = [[NSImage alloc] initWithContentsOfFile:path];
                    [folderImage setSize:NSMakeSize(16, 16)];
                }
            }
			
			if(folderImage == nil)
			{
				// Fallback in case the folder image couldn't be loaded from the bundle.
				folderImage = [[NSImage imageNamed:@"folder16"] retain];
			}
			
			
			mAPI = [[DXDeliciousAPI alloc] initWithUserAgent:[NSString stringWithFormat:@"DeliciousSafari/%@", shortVersion]];
			[mAPI setDelegate:self];
			
			
			// ---------------------------------------
			// Setup the toolbar.
			
			// The toolbar item should be displayed the first time this code is run. If the user removes
			// the toolbar button, it should not be readded.
            
            
			NSString *kSafariToolbarItemIdentifiersArrayKey = @"TB Item Identifiers";
			NSString *kAddPostToolbarItemIdentifier = @"DXAddPostToolbarItemIdentifier";
			if(![mDB hasAddedToolbarItemIdentifier:kAddPostToolbarItemIdentifier])
			{
                // The toolbar item has not been added, so add it for discoverability.
                
                // Different versions of Safari store the toolbar under different identifiers.
                // Look for the newest one first and then fallback to the old.
                NSString *kSafariToolbarConfigDictionaryKeyOld = @"NSToolbar Configuration SafariToolbarIdentifier";
                NSString *kSafariToolbarConfigDictionaryKeyNew = @"NSToolbar Configuration BrowserToolbarIdentifier";
                NSString *kSafariToolbarConfigDictionaryKey = kSafariToolbarConfigDictionaryKeyNew;
                
				
				NSMutableDictionary *toolbarConfigDictionary = [[[[NSUserDefaults standardUserDefaults] objectForKey:kSafariToolbarConfigDictionaryKey] mutableCopy] autorelease];
                if (toolbarConfigDictionary == nil) {
                    // fall back to the older identifier
                    kSafariToolbarConfigDictionaryKey = kSafariToolbarConfigDictionaryKeyOld;
                    toolbarConfigDictionary = [[[[NSUserDefaults standardUserDefaults] objectForKey:kSafariToolbarConfigDictionaryKey] mutableCopy] autorelease];
                }
				
				if([toolbarConfigDictionary isKindOfClass:[NSDictionary class]])
				{
					NSMutableArray *itemIdentifiers = [toolbarConfigDictionary objectForKey:kSafariToolbarItemIdentifiersArrayKey];
					if([itemIdentifiers isKindOfClass:[NSArray class]])
					{
						if(![itemIdentifiers containsObject:kAddPostToolbarItemIdentifier])
						{
							itemIdentifiers = [[itemIdentifiers mutableCopy] autorelease];							
							
							// Add the button just before the input fields (InputFieldsToolbarIdentifier), which are the URL and Google search fields.
							// If the input fields are missing, then add the button to the right of the add bookmark button.
							// If that isn't there either, then add it at the end.
							NSUInteger position = [itemIdentifiers indexOfObject:@"InputFieldsToolbarIdentifier"];
							
							if(position != NSNotFound)
								[itemIdentifiers insertObject:kAddPostToolbarItemIdentifier atIndex:position];
							else if((position = [itemIdentifiers indexOfObject:@"AddBookmarkToolbarIdentifier"]) != NSNotFound)
								[itemIdentifiers insertObject:kAddPostToolbarItemIdentifier atIndex:position + 1];
							else
								[itemIdentifiers addObject:kAddPostToolbarItemIdentifier];
							
							[toolbarConfigDictionary setObject:itemIdentifiers forKey:kSafariToolbarItemIdentifiersArrayKey];
							[[NSUserDefaults standardUserDefaults] setObject:toolbarConfigDictionary forKey:kSafariToolbarConfigDictionaryKey];
							
							// Note to self that we have done this once. We don't do it again.
							[mDB setHasAddedToolbarItemIdentifier:kAddPostToolbarItemIdentifier];
						}
					}
				}
			}
			
			// Use a button that looks like the Safari buttons.
			
			NSSize safariButtonSize = NSMakeSize(28, 25);
			NSButton *toolbarButton = [[[NSButton alloc] initWithFrame:NSMakeRect(0, 0, safariButtonSize.width, safariButtonSize.height)] autorelease];
			[toolbarButton setImage:toolbarItemImage]; // toolbarItemImage should be 16x16
			[toolbarButton setButtonType:NSMomentaryPushInButton];
			[toolbarButton setBezelStyle:NSTexturedRoundedBezelStyle];
			[toolbarButton sizeToFit];
			[toolbarButton setAction:@selector(postAction:)];
			[toolbarButton setTarget:self];
			
			
			NSString *saveToDeliciousLabel = DXLocalizedString(@"Save to Delicious", @"Save to Delicious toolbar item label.");
			NSString *saveToDeliciousTooltip = DXLocalizedString(@"Save to Delicious.", @"Save to Delicious toolbar item tooltip.");
			
			NSToolbarItem *postToolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier:kAddPostToolbarItemIdentifier] autorelease];
			[postToolbarItem setLabel:saveToDeliciousLabel];
			[postToolbarItem setPaletteLabel:saveToDeliciousLabel];
			[postToolbarItem setToolTip:saveToDeliciousTooltip];
			[postToolbarItem setView:toolbarButton];
			[postToolbarItem setMinSize:safariButtonSize];
			[postToolbarItem setMaxSize:safariButtonSize];
			
			NSMenuItem *toolbarItemMenuRep = [[[NSMenuItem alloc] initWithTitle:saveToDeliciousLabel
																		 action:[toolbarButton action]
																  keyEquivalent:@""] autorelease];
			[toolbarItemMenuRep setTarget:[toolbarButton target]];
			[postToolbarItem setMenuFormRepresentation:toolbarItemMenuRep];
			
			[[DXToolbarController theController] addToolbarItem:postToolbarItem withDefaultPosition:1];
			
			
			// ---------------------------------------
			// Check for updates every 15 minutes in case the user updates their Delicious bookmarks from the Delicious website.
			const NSTimeInterval kFifteenMinutes = 15 * 60;
			[NSTimer scheduledTimerWithTimeInterval:kFifteenMinutes target:self selector:@selector(updateCheckTimerFired:) userInfo:nil repeats:YES];
			
			// Setup network reachability monitor.
			BOOL usingReachabiltiyMonitor = NO;
			mNetworkReachabilityRef = SCNetworkReachabilityCreateWithName(NULL, "api.del.icio.us");
			if(mNetworkReachabilityRef != NULL)
			{				
				SCNetworkReachabilityContext context;
				bzero(&context, sizeof(context));
				context.version = 0;
				context.info = self;
				context.retain = NULL;
				context.release = NULL;
				context.copyDescription = NULL;
				
				if(SCNetworkReachabilitySetCallback(mNetworkReachabilityRef, my_SCNetworkReachabilityCallBack, &context))
				{
					if(SCNetworkReachabilityScheduleWithRunLoop(mNetworkReachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopCommonModes))
						usingReachabiltiyMonitor = YES;
					else
						NSLog(@"DeliciousSafari - Network state change monitor not added to run loop.");
				}
				else
					NSLog(@"DeliciousSafari - Network state change monitor callback not set.");
			}
			else
				NSLog(@"DeliciousSafari - Network state change monitor not created.");
			
			if(!usingReachabiltiyMonitor)
			{			
				if(mNetworkReachabilityRef != NULL)
				{
					CFRelease(mNetworkReachabilityRef);
					mNetworkReachabilityRef = NULL;
				}
				
				// Since we aren't using the network state change to determine connectivity, just assume we are online.
				[self setIsOnline:YES];
			}
		}
		else
		{
			NSLog(@"Failed to load NIB from DeliciousSafari.bundle.");
			self = nil;
		}
	}
	return self;
}

- (void)dealloc
{
	if(mNetworkReachabilityRef)
		CFRelease(mNetworkReachabilityRef);
	
	[mAPI release];
	[mDB release];
	[mDeliciousMenu release];
	
	// Disconnect the datasource from the favorites NSTableView and free it.
	[favoriteTagsTable setDataSource:nil];
	[favoritesDataSource release];
	[importerDataSource release];
	
	[folderImage release];
	[urlImage release];
	[toolbarItemImage release];
	
	[self setSavedLastUpdatedTime:nil];
	
	[deliciousSafariBundle release];
    [deliciousSafariBundleTopLevelObjects release];
	
	[itemsToImport release];
	[self setImportTagsToAdd:nil];
	
	[mAllTagsController release];
	[mFavoriteTagsController release];
	
	[spellCheckingFieldEditor release];
	
	[super dealloc];
}

- (void) addMenu
{	
	[self createDeliciousMenu];
	
	if(!mIsDeliciousMenuAdded)
	{
		NSMenuItem *newItem = [[NSMenuItem alloc] initWithTitle:@"DeliciousMenuText" // Not localized
														 action:NULL
												  keyEquivalent:@""];		
		[newItem setSubmenu:mDeliciousMenu];
		const unsigned kBookmarksMenuPosition = 5;
		[[NSApp mainMenu] insertItem:newItem atIndex:kBookmarksMenuPosition];
		
#if 0
		NSMenu *mainMenu = [NSApp mainMenu];
		NSEnumerator *enumer = [[mainMenu itemArray] objectEnumerator];
		NSMenuItem *item;
		while(item = [enumer nextObject])
		{
			NSLog(@"Tag is %d for %@", [item tag], [item title]);
		}
#endif
		
		[newItem release];
		mIsDeliciousMenuAdded = YES;
		
		// If there is a user, update the menus.
		if([mDB isLoggedIn])
		{
			//NSLog(@"User logged in: updateRequest");
			[mAPI updateRequest];
		}
		else
		{
			//NSLog(@"User NOT logged in.");
		}
	}
	else
	{
		NSLog(@"Error building delicious menu.");
	}
}

- (void) createDeliciousMenu
{	
	if(mDeliciousMenu == nil)
	{
		NSString *deliciousMenuTitle = DXLocalizedString(@"Delicious", @"Delicious menu title.");
		mDeliciousMenu = [[NSMenu alloc] initWithTitle:deliciousMenuTitle];
	}
	else
	{
		NSEnumerator *itemEnum = [[mDeliciousMenu itemArray] objectEnumerator];
		NSMenuItem *item;
		while(item = [itemEnum nextObject])
			[mDeliciousMenu removeItem:item];
	}
	
	NSMenuItem* mi = nil;
	
	NSString *saveBookmarkTitle = DXLocalizedString(@"Save Bookmark...", @"Title of the Save Bookmark... menu item.");
	
	mi = [mDeliciousMenu addItemWithTitle:saveBookmarkTitle action:@selector(post) keyEquivalent:@"y"];
	[mi setKeyEquivalentModifierMask:NSCommandKeyMask];
	[mi setTarget:self];
	
	// -----------------------------------
	[mDeliciousMenu addItem:[NSMenuItem separatorItem]];
	
	NSMenu *recentMenu = [self createRecentMenu];
	mi = [mDeliciousMenu addItemWithTitle:[recentMenu title] action:NULL keyEquivalent:@""];
	[mi setTarget:self];
	[mi setSubmenu:recentMenu];
	[recentMenu release];
	
	// -----------------------------------
	[mDeliciousMenu addItem:[NSMenuItem separatorItem]];
	
#if 0
	UnsignedWide startTicks, stopTicks;
	Microseconds(&startTicks);
#endif
	
	NSString *tagsMenuTitle = DXLocalizedString(@"Tags", @"Title of the Tags menu item.");
	
	NSMenu *tagsMenu = [[NSMenu alloc] initWithTitle:tagsMenuTitle];
	[mAllTagsController release];
	mAllTagsController = [[DXTagMenuController alloc] initWithDatabase:mDB
															  withMenu:tagsMenu
														  withTagImage:nil
												   withDefaultURLImage:urlImage
													withMenuItemTarget:self
													withMenuItemAction:@selector(menuItemAction:)];
	
	mi = [mDeliciousMenu addItemWithTitle:[tagsMenu title] action:NULL keyEquivalent:@""];
	[mi setTarget:self];
	[mi setSubmenu:tagsMenu];
	[tagsMenu release];
	
#if 0
	Microseconds(&stopTicks);
	NSLog(@"PERFORMANCE: Building main tags menu took %f seconds", ((float)(stopTicks.lo - startTicks.lo)) / 1000000.0);
#endif
	
	NSString *manageFavoriteTagsTitle = DXLocalizedString(@"Manage Favorite Tags...", @"Title of the Manage Favorite Tags... menu item.");
	mi = [mDeliciousMenu addItemWithTitle:manageFavoriteTagsTitle action:@selector(manageFavoriteTags) keyEquivalent:@""];
	[mi setTarget:self];
	
	[mFavoriteTagsController release];
	mFavoriteTagsController = nil;
	
	if([[mDB favoriteTags] count] > 0)
	{
		[mDeliciousMenu numberOfItems];
		mFavoriteTagsController = [[DXTagMenuController alloc] initWithDatabase:mDB
																	   withMenu:mDeliciousMenu
																		atIndex:[mDeliciousMenu numberOfItems]
																   withTagImage:nil
															withDefaultURLImage:urlImage
															 withMenuItemTarget:self
															 withMenuItemAction:@selector(menuItemAction:)
															 withRestrictToTags:[mDB favoriteTags]];
	}
	
	// -----------------------------------
	[mDeliciousMenu addItem:[NSMenuItem separatorItem]];
	
	NSMenu *deliciousWebsiteMenu = [self createDeliciousWebsiteMenu];
	mi = [mDeliciousMenu addItemWithTitle:[deliciousWebsiteMenu title] action:NULL keyEquivalent:@""];
	[mi setTarget:self];
	[mi setSubmenu:deliciousWebsiteMenu];
	[deliciousWebsiteMenu release];
	
	// Login/logout menu
	if([mDB isLoggedIn])
	{
		NSString *loggedInAsTitleFormat = DXLocalizedString(@"Logged in as %@", @"Format string for title of the Logged in as <user> menu.");
		NSString *logoutTitle = DXLocalizedString(@"Logout", @"Title of the Logout menu item.");
		
		NSString *username = [mDB username];
		NSMenu *loggedInAsMenu = [[NSMenu alloc] initWithTitle:[NSString stringWithFormat:loggedInAsTitleFormat, username]];
		mi = [loggedInAsMenu addItemWithTitle:logoutTitle action:@selector(logout) keyEquivalent:@""];
		[mi setTarget:self];
		
		mi = [mDeliciousMenu addItemWithTitle:[loggedInAsMenu title] action:NULL keyEquivalent:@""];
		[mi setTarget:self];
		[mi setSubmenu:loggedInAsMenu];
		[loggedInAsMenu release];
	}
	else
	{
		NSString *loginTitle = DXLocalizedString(@"Login...", @"Title of the Login... menu item.");
		
		mi = [mDeliciousMenu addItemWithTitle:loginTitle action:@selector(login) keyEquivalent:@""];
		[mi setTarget:self];
	}
	
	// -----------------------------------
	[mDeliciousMenu addItem:[NSMenuItem separatorItem]];
	
	NSString *importBookmarksFromSafariTitle = DXLocalizedString(@"Import Bookmarks from Safari...", @"Title of the Import Bookmarks from Safari... menu item.");
	mi = [mDeliciousMenu addItemWithTitle:importBookmarksFromSafariTitle action:@selector(showImportFromSafari) keyEquivalent:@""];
	[mi setTarget:self];
	
	NSString *searchBookmarksTitle = DXLocalizedString(@"Search Bookmarks...", @"Title of the Search Bookmarks... menu item.");
	mi = [mDeliciousMenu addItemWithTitle:searchBookmarksTitle action:@selector(searchBookmarks) keyEquivalent:@"\'"];
	[mi setKeyEquivalentModifierMask:NSCommandKeyMask];
	[mi setTarget:self];
	
	[mDeliciousMenu addItem:[NSMenuItem separatorItem]];
	
#if 0
	// Preferences disabled for Snow Leopard compatibility release.
	NSString *preferencesTitle = DXLocalizedString(@"Preferences...", @"Title of the Preferences menu item.");
	mi = [mDeliciousMenu addItemWithTitle:preferencesTitle action:@selector(showPreferences) keyEquivalent:@""];
	[mi setTarget:self];
#endif
	
	NSString *aboutDeliciousSafariTitle = DXLocalizedString(@"About DeliciousSafari", @"Title of the About DeliciousSafari menu item.");
	mi = [mDeliciousMenu addItemWithTitle:aboutDeliciousSafariTitle action:@selector(showAbout) keyEquivalent:@""];
	[mi setTarget:self];
}

- (NSMenu*) createRecentMenu
{	
	BOOL atLeastOneItem = NO;
	NSString *recentlyBookmarkedTitle = DXLocalizedString(@"Recently Bookmarked", @"Title of the Recently Bookmarked menu.");
	NSMenu *tm = [[NSMenu alloc] initWithTitle:recentlyBookmarkedTitle];
	
	DXFaviconDatabase *faviconDatabase = [DXFaviconDatabase defaultDatabase];
	NSEnumerator *postsEnum = [[mDB recentPosts:15] objectEnumerator];
	NSDictionary *post = nil;
	while(post = [postsEnum nextObject])
	{
		atLeastOneItem = YES;
		NSString *title = [post objectForKey:kDXPostDescriptionKey];
		NSString *url = [post objectForKey:kDXPostURLKey];
		DXDeliciousMenuItem *postMenuItem = [[DXDeliciousMenuItem alloc] initWithTitle:[title stringByTruncatedInMiddleIfLengthExceeds:kDXMaxMenuTitleLength]
																			   withURL:url
																			withTarget:self
																		  withSelector:@selector(menuItemAction:)];
		
		NSImage *icon = [faviconDatabase faviconForURLString:url];
		if(icon == nil)
			icon = urlImage;
		
		[postMenuItem setImage:icon];
		
		[tm addItem:postMenuItem];
		[postMenuItem release];
	}
	
	if(!atLeastOneItem)
	{
		NSString *emptyTitle = DXLocalizedString(@"(Empty)", @"Title of the tags sub-menu when there are no tags.");
		
		NSMenuItem *emptyMenuItem = [[NSMenuItem alloc] initWithTitle:emptyTitle action:NULL keyEquivalent:@""];
		[tm addItem:emptyMenuItem];
		[emptyMenuItem release];
	}
	
	return tm;
}

- (NSMenu*) createDeliciousWebsiteMenu
{
	NSString *deliciousWebsiteTitle = DXLocalizedString(@"Delicious Website", @"Title of the Delicious Website menu item.");
	NSMenu *tm = [[NSMenu alloc] initWithTitle:deliciousWebsiteTitle];
	[tm setAutoenablesItems:NO];
	
	NSString *username = [mDB username];
	BOOL enableUserMenus = [username length] > 0;
	DXDeliciousMenuItem *mi;
	
	NSString *bookmarksOnDeliciousTitle = DXLocalizedString(@"Bookmarks on Delicious", @"Title of the Bookmarks on Delicious menu item.");
	mi = [[DXDeliciousMenuItem alloc] initWithTitle:bookmarksOnDeliciousTitle
											withURL:[@"http://delicious.com/" stringByAppendingString:username]
										 withTarget:self
									   withSelector:@selector(menuItemAction:)];
	[mi setEnabled:enableUserMenus];
	[tm addItem:mi];
	[mi release];
	
	
	NSString *networkTitle = DXLocalizedString(@"Network", @"Title of the Network menu item.");
	mi = [[DXDeliciousMenuItem alloc] initWithTitle:networkTitle
											withURL:[@"http://delicious.com/network/" stringByAppendingString:username]
										 withTarget:self
									   withSelector:@selector(menuItemAction:)];
	[mi setEnabled:enableUserMenus];
	[tm addItem:mi];
	[mi release];
	
	NSString *subscriptionsTitle = DXLocalizedString(@"Subscriptions", @"Title of the Subscriptions menu item.");
	mi = [[DXDeliciousMenuItem alloc] initWithTitle:subscriptionsTitle
											withURL:[@"http://delicious.com/subscriptions/" stringByAppendingString:username]
										 withTarget:self
									   withSelector:@selector(menuItemAction:)];
	[mi setEnabled:enableUserMenus];
	[tm addItem:mi];
	[mi release];
	
	
	NSString *linksForYouTitle = DXLocalizedString(@"Links for You", @"Title of the Links for You menu item.");
	mi = [[DXDeliciousMenuItem alloc] initWithTitle:linksForYouTitle
											withURL:[@"http://delicious.com/for/" stringByAppendingString:username]
										 withTarget:self
									   withSelector:@selector(menuItemAction:)];
	[mi setEnabled:enableUserMenus];
	[tm addItem:mi];
	[mi release];
	
	NSString *accountSettingsTitle = DXLocalizedString(@"Account Settings", @"Title of the Account Settings menu item.");
	mi = [[DXDeliciousMenuItem alloc] initWithTitle:accountSettingsTitle
											withURL:@"https://secure.delicious.com/settings/"
										 withTarget:self
									   withSelector:@selector(menuItemAction:)];
	[mi setEnabled:enableUserMenus];
	[tm addItem:mi];
	[mi release];
	
	// -----------------------------------
	[tm addItem:[NSMenuItem separatorItem]];
	
	
	NSString *homeTitle = DXLocalizedString(@"Home", @"Title of the Home menu item.");
	mi = [[DXDeliciousMenuItem alloc] initWithTitle:homeTitle
											withURL:@"http://delicious.com"
										 withTarget:self
									   withSelector:@selector(menuItemAction:)];
	[tm addItem:mi];
	[mi release];
	
	
	NSString *popularTitle = DXLocalizedString(@"Popular", @"Title of the Popular menu item.");
	mi = [[DXDeliciousMenuItem alloc] initWithTitle:popularTitle
											withURL:@"http://delicious.com/popular"
										 withTarget:self
									   withSelector:@selector(menuItemAction:)];
	[tm addItem:mi];
	[mi release];
	
	
	NSString *recentTitle = DXLocalizedString(@"Recent", @"Title of the Recent menu item.");
	mi = [[DXDeliciousMenuItem alloc] initWithTitle:recentTitle
											withURL:@"http://delicious.com/recent"
										 withTarget:self
									   withSelector:@selector(menuItemAction:)];
	[tm addItem:mi];
	[mi release];
	// -----------------------------------
	[tm addItem:[NSMenuItem separatorItem]];
	
	NSString *aboutDeliciousTitle = DXLocalizedString(@"About Delicious", @"Title of the About Delicious menu item.");
	mi = [[DXDeliciousMenuItem alloc] initWithTitle:aboutDeliciousTitle
											withURL:@"http://delicious.com/about"
										 withTarget:self
									   withSelector:@selector(menuItemAction:)];
	[tm addItem:mi];
	[mi release];
	
#if 0
	// -----------------------------------
	// TODO - Need to lookup hash for this page.
	[tm addItem:[NSMenuItem separatorItem]];
	mi = [[DXDeliciousMenuItem alloc] initWithTitle:@"More about this Page"
											withURL:@"http://delicious.com/url/3bfb42a8a4a3f64a2b265d28f738a5c9"
										 withTarget:self
									   withSelector:@selector(menuItemAction:)];
	[tm addItem:mi];
	[mi release];
#endif
	
	
	return tm;
}

- (void) showSheet:(NSWindow*)window
{
	// Only show a sheet if another sheet it not being shown.
	if(mCurrentSheet == nil)
	{        
		mCurrentSheet = window;
		[NSApp beginSheet:window modalForWindow:[NSApp mainWindow] modalDelegate:self didEndSelector:nil contextInfo:NULL];
	}
}

- (void) hideSheet:(NSWindow*)window
{
	[NSApp endSheet:window];
	[window orderOut:self];
	mCurrentSheet = nil;
	afterLoginCallback = NULL;
}

// Delegate for HyperlinkedTextField
- (void)willGoToURL:(id)sender
{
	if(sender == loginWindowUserRegistrationLink)
	{
		[self hideSheet:loginWindow];
	}
	else if(sender == aboutWindowDeliciousSafariLink)
	{
		[self hideSheet:aboutWindow];
	}
}

- (void) loginWithFirstResponder:(NSResponder*)firstResponder
{
	[loginUsername setStringValue:[mDB username]];
	[loginPassword setStringValue:@""];
	[loginProgress stopAnimation:self];
	[loginProgress setHidden:YES];
	[loginErrorMessage setHidden:YES];
	[loginWindow invalidateCursorRectsForView:loginWindowUserRegistrationLink]; // Do this so hand cursor shows up over the link after the first showing of this window.
	[loginWindow makeFirstResponder:firstResponder];
	[self showSheet:loginWindow];
	
}

- (void) login
{
	[self loginWithFirstResponder:loginUsername];
}

- (void) logout
{
	//NSLog(@"logout pressed");
	[mAPI clearSavedCredentials];
	
	[mDB updateDatabaseWithDeliciousAPIPosts:nil];
	[mDB setUsername:nil];
	[mDB setLastUpdated:nil];
	
	[self createDeliciousMenu];
}

// Execute a command and return the output in an NSString.
static NSData* ExecuteCommand(NSString* command)
{
    NSMutableData* data = [NSMutableData data];
    
    FILE* fp = popen([command UTF8String], "r");
    
    if ( fp == NULL )
    {
        NSLog(@"Error executing command: %@.", command);//, strerror(errno));
        return nil;
    }
    
    char buf[1024*4];
    size_t bytesRead;
    while((bytesRead = fread(buf, 1, sizeof(buf), fp)) > 0)
    {
        [data appendBytes:buf length:bytesRead];
    }
    
    int rc = pclose(fp);
    if ( rc != 0 )
    {
        NSLog(@"DeliciousSafari's ASHelper returned an error: %d", rc);
    }
    
    return data;
}

- (NSString*)executeASHelper:(NSString*)command
{
    NSString* asHelperPath = [deliciousSafariBundle pathForResource:@"ASHelper" ofType:nil];
    NSString* fullCommand = [NSString stringWithFormat:@"'%@' '%@' '%@'", asHelperPath, [[DXUtilities defaultUtilities] applicationName], command];
    NSData* commandResult = ExecuteCommand(fullCommand);
    
    if ( commandResult )
    {
        return [[[NSString alloc] initWithBytes:[commandResult bytes] length:[commandResult length] encoding:NSUTF8StringEncoding] autorelease];
    }
    return nil;
}

- (void)currentDocumentASCommand:(NSString*)command completionHandler:(void (^)(NSString* result))completionHandler
{
    assert(completionHandler);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        NSString* result = [self executeASHelper:command];
        result = result == nil ? @"" : result;
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            completionHandler(result);
        });
    });
}

- (void)currentDocumentTitle:(void (^)(NSString* title))completionHandler
{    
    assert(completionHandler);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        
        NSString *title = nil;
        NSString* html = [self executeASHelper:@"html"];
        
        if(html)
        {
            
            NSRange startRange = [html rangeOfString:@"<title>" options:NSCaseInsensitiveSearch];
            NSRange endRange = [html rangeOfString:@"</title>" options:NSCaseInsensitiveSearch];
            
            if(startRange.location != NSNotFound && endRange.location != NSNotFound &&
               (startRange.location + startRange.length) < endRange.location)
            {
                title = [html substringWithRange:NSMakeRange(startRange.location + startRange.length,
                                                                 endRange.location - (startRange.location + startRange.length))];
                // Fix-up the title. Remove unneeded whitespace.
                title = [title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                NSArray *titleComponents = [title componentsSeparatedByString:@"\n"];
                title = [titleComponents componentsJoinedByString:@" "];
                titleComponents = [title componentsSeparatedByString:@"\r"];
                title = [titleComponents componentsJoinedByString:@" "];
                
                title = [[DXUtilities defaultUtilities] decodeHTMLEntities:title];
            }
        }
        else
        {
            NSLog(@"Error executing command for document title");
        }
        
        title = title == nil ? @"" : title;
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            completionHandler(title);
        });
    });
}

- (void) postAction:(id)sender
{
	[self post];
}

- (void)postSheetWithURL:(NSString*)url withTitle:(NSString*)title withNotes:(NSString*)notes
				withTags:(NSArray*)tags withShouldShare:(BOOL)shouldShare withErrorMessage:(NSString*)errorString
{
	BOOL isErrorStringHidden = NO;
	
	if(errorString == nil)
	{
		errorString = @"";
		isErrorStringHidden = YES;
	}
	
	if([title length] > kMaxTitleLength)
		title = [title substringWithRange:NSMakeRange(0, kMaxTitleLength)];
	
	
	[postURL setStringValue:url];
	[postName setStringValue:title];
	[postNotes setString:notes];
	[postNotesCharactersUsed setStringValue:[NSString stringWithFormat:@"%lu", (unsigned long)[notes length]]];
	[postTags setObjectValue:tags];
	[doNotShare setState:shouldShare ? NSOffState : NSOnState];
	[postWindow makeFirstResponder:postTags];
	[postErrorMessage setHidden:isErrorStringHidden];
	[postErrorMessage setStringValue:errorString];
	[postLoadingPopularTagsProgress setHidden:[url length] <= 0];
	[postLoadingPopularTagsProgress startAnimation:self];		
	[postPopularTagsLayoutView setHidden:YES];
	
	// Set the selection point for tags to the end of the field.
	NSText *fieldEditor = [postWindow fieldEditor:YES forObject:postTags];
	[fieldEditor setSelectedRange:NSMakeRange([tags count], 0)];
	
	// Kick off a URL Info request to get the popular tags. This will call back later.
	[mAPI URLInfoRequest:url];
	
	[self showSheet:postWindow];
}

- (void) post
{	
	if([mDB isLoggedIn])
	{
        // Asynchronoulys fetch the document URL, HTML, and selected text using ASHelper.
        // This used to be done on the main thread but in OS X Lion an AppleScript timeout
        // appeared, which I think was caused by a deadlock (Safari trying to serve the apple
        // script request while also blocked on sending the request - both from the
        // main thread).
        
        [self currentDocumentASCommand:@"url" completionHandler:^(NSString *url) {
            assert([NSThread isMainThread]);
            
            NSString *title = nil;
            NSString *notes = nil;
            NSArray *tags = nil;
            
            NSDictionary *post = [mDB postForURL:url]; // See if this post already exists.
            
            if(post != nil)
            {
                // This entry already exists so display the existing information.
                // At this point, the shared flag isn't available via the API.
                title = [post objectForKey:kDXPostDescriptionKey];
                notes = [post objectForKey:kDXPostExtendedKey];
                tags = [post objectForKey:kDXPostTagArrayKey];
            }
            
            // Make sure all the values are non-nil to avoid AppKit exceptions.
            
            if(tags == nil)
                tags = [NSArray array];
            
            [self currentDocumentASCommand:@"selected-text" completionHandler:^(NSString *selectedText) {
                
                NSString* notesValue = notes;
                
                if(notesValue == nil)
                {
                    notesValue = selectedText ? selectedText : @"";
                }
                
                [self currentDocumentTitle:^(NSString *gottenTitle) {
                    
                    NSString* titleValue = title;
                    
                    if(titleValue == nil)
                    {
                        titleValue = gottenTitle ? gottenTitle : @"";
                    }
                    
                    assert([NSThread isMainThread]);
                    [self postSheetWithURL:url withTitle:titleValue withNotes:notesValue withTags:tags withShouldShare:[mDB shouldShareDefaultValue] withErrorMessage:nil];
                }];
            }];            
        }];
	}
	else
	{
		afterLoginCallback = @selector(post);
		[self login];
	}
}


- (IBAction)postPopularTagPressed:(id)sender
{
	if([sender isKindOfClass:[NSButton class]])
	{
		NSButton *button = (NSButton*)sender;
		NSString *tag = [button title];
		
		NSMutableArray *currentTagArray = [[[postTags objectValue] mutableCopy] autorelease];
		if(currentTagArray == nil || ![currentTagArray isKindOfClass:[NSArray class]])
			currentTagArray = [NSMutableArray array];
		
		if([currentTagArray containsObject:tag])
			[currentTagArray removeObject:tag];
		else
			[currentTagArray addObject:tag];
		
		[postTags setObjectValue:currentTagArray];
		
		NSText *fieldEditor = [postWindow fieldEditor:YES forObject:postTags];
		[fieldEditor setSelectedRange:NSMakeRange([currentTagArray count], 0)];
	}
}

- (void) manageFavoriteTags
{
	[favoriteTagsToAdd setObjectValue:[NSArray array]];
	[favoriteTagsTable selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
	[favoriteTagsTable reloadData];
	[favoriteTagsWindow makeFirstResponder:favoriteTagsToAdd];
	[self showSheet:favoriteTagsWindow];
}

- (void) menuItemAction:(id)sender
{	
	if([sender isKindOfClass:[DXDeliciousMenuItem class]])
	{
		DXDeliciousMenuItem *mi = (DXDeliciousMenuItem*)sender;
		[[DXUtilities defaultUtilities] goToURL:[mi url]];
	}	
}

- (IBAction)loginPressed:(id)sender
{
	//NSLog(@"loginPressed");
	[loginProgress setHidden:NO];
	[loginProgress startAnimation:self];
	[loginErrorMessage setHidden:YES];
	[mAPI clearSavedCredentials];
	[mAPI updateRequest];
}

- (IBAction)loginCancelPressed:(id)sender
{
	[self hideSheet:loginWindow];
}

-(void)setSavedLastUpdatedTime:(NSDate*)lastUpdatedTime
{
	if(mAPILastUpdatedTime != lastUpdatedTime)
	{
		[mAPILastUpdatedTime release];
		mAPILastUpdatedTime = [lastUpdatedTime retain];
	}
}

-(NSDate*)savedLastUpdatedTime
{
	return mAPILastUpdatedTime == nil ? [NSDate distantPast] : mAPILastUpdatedTime;
}


- (void)textDidChange:(NSNotification *)aNotification
{
	if([aNotification object] == postNotes)
	{		
		[postNotesCharactersUsed setStringValue:[NSString stringWithFormat:@"%lu", (unsigned long)[[postNotes string] length]]];
	}	
}

- (BOOL)textView:(NSTextView *)aTextView doCommandBySelector:(SEL)aSelector
{
	if(aTextView == postNotes)
	{
		// If a tab or backtab is entered, then eat the tab and move to the next or previous key view.
		if(aSelector == @selector(insertTab:))
		{
			[postWindow selectNextKeyView:self];
			return YES;
		}
		else if(aSelector == @selector(insertBacktab:))
		{
			//[postWindow selectPreviousKeyView:self]; For some reason this doesn't work, so just make postName the first responder.
			[postWindow makeFirstResponder:postName];
			return YES;
		}
	}
	
	return NO;
}

- (BOOL)textView:(NSTextView *)aTextView shouldChangeTextInRange:(NSRange)affectedCharRange replacementString:(NSString *)replacementString
{
	int proposedLength = [[aTextView string] length] - affectedCharRange.length + [replacementString length];
	return replacementString != nil && proposedLength <= (int)kMaxExtendedDescriptionLength;
}

-(BOOL)postPrevalidate
{
	// Make sure everything looks kosher.
	NSString *url = [postURL stringValue];
	
	if([url length] <= 0)
	{
		NSString *pleaseEnterURL = DXLocalizedString(@"Please enter a URL.", @"Please enter a URL message.");
		
		[postErrorMessage setStringValue:pleaseEnterURL];
		[postErrorMessage setHidden:NO];
		
		// For Tiger, you have to perform after a delay in case the post got triggered by a keyboard return key.
		// Otherwise, the postURL will become the responder only for a moment before the previous view regains
		// control, problbably the result of the keyboard message to it. This method also works fine on Leopard,
		// though a calling makeFirstResponder: directly works as well.
		[postWindow performSelector:@selector(makeFirstResponder:) withObject:postURL afterDelay:0.01];
		return NO;
	}
	
	NSString *description = [postName stringValue];
	if([description length] <= 0)
	{
		NSString *pleaseEnterDescription = DXLocalizedString(@"Please enter a description.", @"Please enter a description message.");
		
		[postErrorMessage setStringValue:pleaseEnterDescription];
		[postErrorMessage setHidden:NO];
		[postWindow performSelector:@selector(makeFirstResponder:) withObject:postName afterDelay:0.01];
		return NO;
	}
	
	return YES;
}

- (IBAction)postPressed:(id)sender
{
	// If tagsString is empty, add the system:unfiled placeholder that Delicious is going to add anyway.
	NSArray *tagArray = [postTags objectValue];
	if(tagArray == nil || [tagArray count] == 0)
		tagArray = [NSArray arrayWithObject:kUnfiledDeliciousTag];
	
	NSNumber *isShared = [NSNumber numberWithBool:[doNotShare state] != NSOnState];
	
	if([self postPrevalidate])
	{
		[mAPI postAddRequest:[postURL stringValue]
			 withDescription:[postName stringValue]
				withExtended:[postNotes string]
					withTags:tagArray
			   withDateStamp:nil
		   withShouldReplace:nil
				withIsShared:isShared];
		
		[self hideSheet:postWindow];
	}
}


-(void)displayPostErrorAlert:(NSDictionary*)postDictionary
{
	// Since the post was processed in the background, the user needs to be informed of the problem.
	// TODO: Should I also have a try again option here? Or try later?
	
	NSString *errorSavingBookmarkShouldDiscard = DXLocalizedString(@"Error saving bookmark. Would you like to review or discard the bookmark?",
																   @"Error saving bookmark/should discard message.");
	
	NSString *review = DXLocalizedString(@"Review...", @"Review button text.");
	
	NSString *discard = DXLocalizedString(@"Discard...", @"Discard button text.");
	
	NSString *deletedRecordsCannotBeRestored = DXLocalizedString(@"Deleted records cannot be restored.",
																 @"Deleted records cannot be restored informative text.");
	
	NSAlert *alert = [NSAlert alertWithMessageText:errorSavingBookmarkShouldDiscard
									 defaultButton:review alternateButton:discard
									   otherButton:nil informativeTextWithFormat:@"%@", deletedRecordsCannotBeRestored];
	[alert setAlertStyle:NSCriticalAlertStyle];
	
	if([alert runModal] == NSAlertDefaultReturn)
	{
		NSString *url = [postDictionary objectForKey:kDXPostURLKey];
		NSString *title = [postDictionary objectForKey:kDXPostDescriptionKey];
		NSString *notes = [postDictionary objectForKey:kDXPostExtendedKey];
		NSArray *tags = [postDictionary objectForKey:kDXPostTagArrayKey];
		NSNumber *shouldShare = [postDictionary objectForKey:kDXPostShouldReplace];
		
		NSString *errorSavingToDelicious = DXLocalizedString(@"Error saving bookmark to Delicious.",
															 @"Error saving bookmark to Delicious message.");
		
		[self postSheetWithURL:url withTitle:title withNotes:notes withTags:tags
			   withShouldShare:[shouldShare boolValue] withErrorMessage:errorSavingToDelicious];
	}
}

- (IBAction)postCancelPressed:(id)sender
{
	[self hideSheet:postWindow];
}

- (IBAction)favoriteMoveUpPressed:(id)sender
{
	NSIndexSet *selectedTags = [favoriteTagsTable selectedRowIndexes];
	
	NSUInteger selectedIndex = [selectedTags firstIndex];
	if(selectedIndex != NSNotFound && selectedIndex > 0)
	{
		NSMutableIndexSet *newSelectionIndexes = [NSMutableIndexSet indexSet];
		
		do
		{
			unsigned int moveToIndex = selectedIndex - 1;
			[newSelectionIndexes addIndex:moveToIndex];
			[favoritesDataSource swapFavoriteAtIndex:selectedIndex withFavoriteAtIndex:moveToIndex];
			selectedIndex = [selectedTags indexGreaterThanIndex:selectedIndex];
		} while(selectedIndex != NSNotFound);
		
		[favoriteTagsTable reloadData];
		[favoriteTagsTable selectRowIndexes:newSelectionIndexes byExtendingSelection:NO];
	}
}

- (IBAction)favoriteMoveDownPressed:(id)sender
{
	NSIndexSet *selectedTags = [favoriteTagsTable selectedRowIndexes];
	
	NSUInteger selectedIndex = [selectedTags lastIndex];
	NSUInteger rowCount = [favoritesDataSource numberOfRowsInTableView:nil];
	if(selectedIndex != NSNotFound && rowCount > 0 && selectedIndex < rowCount - 1)
	{
		NSMutableIndexSet *newSelectionIndexes = [NSMutableIndexSet indexSet];
		
		do
		{
			unsigned int moveToIndex = selectedIndex + 1;
			[newSelectionIndexes addIndex:moveToIndex];
			[favoritesDataSource swapFavoriteAtIndex:selectedIndex withFavoriteAtIndex:moveToIndex];
			selectedIndex = [selectedTags indexLessThanIndex:selectedIndex];
		} while(selectedIndex != NSNotFound);
		
		[favoriteTagsTable reloadData];
		[favoriteTagsTable selectRowIndexes:newSelectionIndexes byExtendingSelection:NO];
	}
}

- (IBAction)favoriteRemovePressed:(id)sender
{
	NSIndexSet *selectedTags = [favoriteTagsTable selectedRowIndexes];
	[favoritesDataSource removeFavoritesAtIndexes:selectedTags];
	[favoriteTagsTable reloadData];
}

- (IBAction)favoriteAddTagPressed:(id)sender
{
	[favoritesDataSource addTagFilterArray:[favoriteTagsToAdd objectValue]];
	[favoriteTagsTable reloadData];
}

- (IBAction)favoriteOKPressed:(id)sender
{
	[self hideSheet:favoriteTagsWindow];
	
	// Save the favorites to the database.
	[mDB setFavoriteTags:[favoritesDataSource favorites]];
	
	[self createDeliciousMenu];
}

- (IBAction)favoriteCancelPressed:(id)sender
{
	[self hideSheet:favoriteTagsWindow];
	
	// Revert the datasource to the contents in the database.
	[favoriteTagsTable selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
	[favoritesDataSource setTags:[mDB favoriteTags]];
	[favoriteTagsTable reloadData];
}

#if 0
-(void)showPreferences
{
	[DXPreferencesController showPreferences];
}
#endif

-(void)showAbout
{
	[aboutWindow center];
	[aboutWindow makeKeyAndOrderFront:self];
	[aboutWindow invalidateCursorRectsForView:aboutWindowDeliciousSafariLink]; // Do this so hand cursor shows up over the link after the first showing of this window.
}

-(void)setEnabledForImporterFields:(BOOL)enabled
{
	[importerAddTags setEditable:enabled]; // Use editable for token field, otherwise tokens are erased.
	[importerWindow makeFirstResponder:nil];
	
	[importerDoNotShareButton setEnabled:enabled];
	[importerShouldReplaceButton setEnabled:enabled];
	[importerImportButton setEnabled:enabled];
	[importerBookmarkOutlineView setEnabled:enabled];
}

-(void)showImportFromSafari
{
	if([mDB isLoggedIn])
	{
		DXSafariBookmarkDataSource *tmpToRelease = importerDataSource;
		importerDataSource = [[DXSafariBookmarkDataSource alloc] init];
		
		NSString *importedTag = DXLocalizedString(@"imported",
												  @"Tag added to bookmarks saved with the importer. Should be a single Delicious tag (single word, no spaces).");
		
		[importerAddTags setObjectValue:[NSArray arrayWithObject:importedTag]];
		
		NSString *importerMessageText = DXLocalizedString(@"Check the bookmarks you'd like to import into Delicious and then press Import. "
														  @"The Safari folder names will be used as Delicious tags. You can also add tags to every "
														  @"item imported using the Extra Tags field above.",
														  @"Instructional text on how to use the Importer.");		
		
		[importerMessage setStringValue:importerMessageText];
		[importerBookmarkOutlineView setDataSource:importerDataSource];
		
		// Don't release the data source until everyone who uses it is switched as the outline view only maintains a weak reference
		// to the data source.
		[tmpToRelease release];
		
		[importerProgress setDoubleValue:0];
		[self setEnabledForImporterFields:YES];
		[importerShouldReplaceButton setState:NSOffState];
		[importerDoNotShareButton setState:[mDB shouldShareDefaultValue] ? NSOffState : NSOnState];		
		
		[self showSheet:importerWindow];
	}
	else
	{
		afterLoginCallback = @selector(showImportFromSafari);
		[self login];
	}
}

-(void)searchBookmarks
{
	DXSearchController *searchController = [DXSearchController sharedController];
	searchController.defaultFavicon = urlImage;
	[searchController showWindow:self];
}

-(void)setImportTagsToAdd:(NSArray*)tagArray
{
	if(importTagsToAdd != tagArray)
	{
		[importTagsToAdd release];
		importTagsToAdd = [tagArray retain];
	}
}

-(void)importNextItem
{	
	if(isImportCancelled)
		return;
	
	if([itemsToImport count] <= 0)
	{
		NSString *importComplete = DXLocalizedString(@"Import complete.", @"Message displayed when the import completes.");
		[importerMessage setStringValue:importComplete];
		return;
	}
	
	NSDictionary *item = [[[itemsToImport lastObject] retain] autorelease];
	[itemsToImport removeLastObject];
	
	NSString *title = [item objectForKey:kImportTitleString];
	NSString *url = [item objectForKey:kImportURLString];
	NSMutableSet *tagSet = [[[item objectForKey:kImportTagsSet] mutableCopy] autorelease];
	
	if(tagSet == nil)
		tagSet = [NSMutableSet setWithArray:importTagsToAdd];
	else
		[tagSet unionSet:[NSSet setWithArray:importTagsToAdd]];
	
	NSArray *tagArray = [tagSet allObjects];
	// If tagsString is empty, add the system:unfiled placeholder that Delicious is going to add anyway.
	if(tagArray == nil || [tagArray count] == 0)
		tagArray = [NSArray arrayWithObject:kUnfiledDeliciousTag];
	
	BOOL shouldReplace = [importerShouldReplaceButton state] == NSOnState;
	BOOL isShared = [importerDoNotShareButton state] == NSOffState;
		
	[mAPI postAddRequest:url
		 withDescription:title
			withExtended:nil
				withTags:tagArray
		   withDateStamp:nil
	   withShouldReplace:[NSNumber numberWithBool:shouldReplace]
			withIsShared:[NSNumber numberWithBool:isShared]];
	
	NSString *importStatusFormat = DXLocalizedString(@"%@\nTags: %@", @"Format string for import status. First string is title. Second is tag list.");
	
	NSString *listSeparator = DXLocalizedString(@", ", @"Punctuation to separate list elements.");
	
	[importerMessage setStringValue:[NSString stringWithFormat:importStatusFormat, title, [tagArray componentsJoinedByString:listSeparator]]];
}

-(void)doImport
{
	[self importNextItem];
}

- (IBAction)importerImportPressed:(id)sender
{
	isImportCancelled = NO;
	
	[self setEnabledForImporterFields:NO];
	
	NSArray *tagArray = [importerAddTags objectValue];
	if(tagArray == nil || [tagArray count] == 0)
		tagArray = [NSArray arrayWithObject:kUnfiledDeliciousTag];
	[self setImportTagsToAdd:tagArray];
	
	// Walk all items and look for checks.
	[itemsToImport release];
	itemsToImport = [[importerDataSource itemsToImport] mutableCopy];
	//NSLog(@"Items to import are: %@", itemsToImport);

	[importerProgress setMinValue:0];
	[importerProgress setMaxValue:[itemsToImport count]];
	[importerProgress setDoubleValue:0];
	
	[self doImport];
}

- (IBAction)importerCancelPressed:(id)sender
{
	isImportCancelled = YES;
	[self hideSheet:importerWindow];
}

- (IBAction)importerItemCheckPressed:(id)sender
{
	//NSLog(@"Item Check pressed. sender is %@ in row %d, item: %@", sender, [sender clickedRow], [importerBookmarkOutlineView itemAtRow:[sender clickedRow]]);
	id item = [importerBookmarkOutlineView itemAtRow:[sender clickedRow]];
	int state = [importerDataSource checkStateOfItem:item];
	
	if(state == NSOnState)
		state = NSOffState;
	else
		state = NSOnState;
	
	[importerDataSource setCheckState:state forItem:item];
	[importerBookmarkOutlineView reloadData];
}

- (void)outlineView:(NSOutlineView *)outlineView
	willDisplayCell:(id)cell
	 forTableColumn:(NSTableColumn *)tableColumn
			   item:(id)item
{	
	if(outlineView == importerBookmarkOutlineView)
	{
		[cell setTitle:[importerDataSource titleForItem:item]];
		
		NSImage *image = nil;
		if([importerDataSource isListItem:item])
			image = folderImage;
		else
			image = urlImage;
		
		[cell setIconImage:image];
		[cell setState:[importerDataSource checkStateOfItem:item]];
	}
}

-(void)downloadFaviconsIfEnabled
{
	if([[DXPreferences sharedPreferences] shouldDownloadFavicons])
		[mDB startFaviconUpdateThread:self];
}

#pragma mark ---- DXDeliciousAPIDelegate Protocol ----

- (NSString*)deliciousAPIGetUsername
{
	//NSLog(@"deliciousAPIGetUsername - username is '%@'", [loginUsername stringValue]);
	return [loginUsername stringValue];
}

- (NSString*)deliciousAPIGetPassword
{
	//NSLog(@"deliciousAPIGetPassword - pasword is '%@'", [loginPassword stringValue]);
	return [loginPassword stringValue];
}

- (void)deliciousAPIBadCredentials
{
	//NSLog(@"deliciousAPIBadCredentials");
	
	if(mCurrentSheet == loginWindow)
	{
		//NSLog(@"deliciousAPIBadCredentials - this is the login window");
		
		NSString *invalidUsernameOrPassword = DXLocalizedString(@"Invalid username or password", @"Invalid username or password error message.");
		
		[loginProgress stopAnimation:self];
		[loginProgress setHidden:YES];
		[loginErrorMessage setStringValue:invalidUsernameOrPassword];
		[loginErrorMessage setHidden:NO];
	}
	else if([mDB isLoggedIn])
	{
		NSString *informativeMessage = DXLocalizedString(@"Your password has probably changed. You need to login to start using DeliciousSafari again.\n\n"
														 @"If you cancel, you will get this message next time DeliciousSafari tries to contact Delicious.\n\n"
														 @"If you logout, you will not be able to use DeliciousSafari until you login again.",
														 @"Invalid credential alert instructions.");
		
		//NSLog(@"DeliciousSafari - Unhandled Bad Credential message! You probably should log out and then login again.");
		NSAlert *alert = [NSAlert alertWithMessageText:DXLocalizedString(@"Your Delicious credentials are invalid.", @"Text of invalid credential alert.")
										 defaultButton:DXLocalizedString(@"Login...", nil)
									   alternateButton:DXLocalizedString(@"Logout", nil)
										   otherButton:DXLocalizedString(@"Cancel", @"Cancel button text.")
							 informativeTextWithFormat:@"%@", informativeMessage];
		
		[alert setAlertStyle:NSCriticalAlertStyle];
		
		switch([alert runModal])
		{
			case NSAlertDefaultReturn:
				[self loginWithFirstResponder:loginPassword];
				break;
			case NSAlertAlternateReturn:
				[self logout];
				break;
			case NSAlertOtherReturn:
			default:
				break;
		}
	}
	else
	{
		// This shouldn't happen, but just in case it does, log the fact.
		NSLog(@"DeliciousSafari got bad credential message even though user is not logged in.");
	}
}

- (void)deliciousAPIConnectionFailedWithError:(NSError*)error
{
	//NSLog(@"deliciousAPIConnectionFailedWithError");
	
	if(mCurrentSheet == loginWindow)
	{
		//NSLog(@"deliciousAPIConnectionFailedWithError - currentSheet is the login window.");
		
		[loginProgress stopAnimation:self];
		[loginProgress setHidden:YES];
		
		if([loginErrorMessage isHidden])
		{
			NSString *connectionFailedFormat = DXLocalizedString(@"Connection failed: %@", @"Connection failed format string.");
			
			// If this error hasn't already been handled somewhere else then show the generic error message now.
			[loginErrorMessage setStringValue:[NSString stringWithFormat:connectionFailedFormat, [error localizedDescription]]];
			[loginErrorMessage setHidden:NO];
		}
	}
}

- (void) deliciousAPIURLInfoResponse:(NSDictionary*)urlInfo
{
	// Stop the animation when this gets called.
	[postLoadingPopularTagsProgress stopAnimation:self];
	[postLoadingPopularTagsProgress setHidden:YES];
	
	if(urlInfo == nil)
		return;
	
	NSArray *currentTags = [postTags objectValue];
	if(currentTags == nil)
		currentTags = [NSArray array];
	
	[postPopularTagsLayoutView removeAllSubviews];
	
	NSDictionary *top_tags = [urlInfo objectForKey:@"top_tags"];
	NSEnumerator *topTagsKeysEnum = [[top_tags allKeys] objectEnumerator];
	NSString *tag = nil;
	while(tag = [topTagsKeysEnum nextObject])
	{
		NSButton *button = [[[NSButton alloc] initWithFrame:NSMakeRect(0, 0, 1, 1)] autorelease];
		[button setTitle:tag];
		[button setBezelStyle:NSRoundRectBezelStyle];
		[button setButtonType:NSPushOnPushOffButton];
		[button sizeToFit];
		[button setTarget:self];
		[button setAction:@selector(postPopularTagPressed:)];
		[postPopularTagsLayoutView addSubview:button];
		
		if([currentTags containsObject:tag])
			[button setState:NSOnState];
		else
			[button setState:NSOffState];
	}
	
	[postPopularTagsLayoutView setHidden:NO];
}

- (void) deliciousAPIUpdateResponse:(NSDate*)lastUpdatedTime
{
	//NSLog(@"deliciousAPIUpdateComplete: %@", lastUpdatedDate);
	if(mCurrentSheet == loginWindow)
	{
		SEL callback = afterLoginCallback;
		[self hideSheet:loginWindow];
		[loginProgress stopAnimation:self];
		[mDB setUsername:[loginUsername stringValue]];
		[mAPI startProcessingPendingBookmarks];
		
		if(callback)
			[self performSelector:callback];
	}
	
	// if lastUpdatedDate > lastUpdated, then we need to refresh.
	//NSLog(@"Last Updated: %@, Last Updated DB: %@", lastUpdatedTime, [mDB lastUpdated]);
	if([lastUpdatedTime compare:[mDB lastUpdated]] != NSOrderedSame)
	{
		// The database needs to be updated.
		//NSLog(@"The Delicious database needs to be updated");
		[self setSavedLastUpdatedTime:lastUpdatedTime];
		[mAPI postsAllRequest];
	}
	else
	{
		// Kick off a favicon update thread, since one won't be run because a post all response won't occur.
		[self downloadFaviconsIfEnabled];
	}
}

- (void) deliciousAPIPostAllResponse:(NSArray*)posts
{
	[mDB setLastUpdated:[self savedLastUpdatedTime]];
	[mDB updateDatabaseWithDeliciousAPIPosts:posts];
	[self createDeliciousMenu];
	
	// In a posts all response, at least one URL has be added, deleted, or changed, so kick off a favicon update thread.
	[self downloadFaviconsIfEnabled];
}

- (void)deliciousAPIPostAddResponse:(BOOL)didSucceed withPost:(NSDictionary*)postDictionary
{
	//NSLog(@"deliciousAPIPostAddResponse: didSucceed = %d", didSucceed);
	
	if(didSucceed)
	{
		if(mCurrentSheet == importerWindow)
		{
			// Update the progress bar.
			[importerProgress incrementBy:1];
			[importerProgress displayIfNeeded];
			
			// Update database.
			[mDB updateDatabaseWithPost:postDictionary];
			
			if([itemsToImport count] > 0)
			{				
				// Import the next item.
				[self importNextItem];
			}
			else
			{
				//[importerProgress stopAnimation:self];
				[self hideSheet:importerWindow];
				
				// Rebuild menus.
				[self createDeliciousMenu];
				
				// Try to get the favicon for the URLs saved during the import.
				[self downloadFaviconsIfEnabled];
			}
		}
		else
		{
			// Update database.
			[mDB updateDatabaseWithPost:postDictionary];
			
			// Rebuild menus.
			[self createDeliciousMenu];
			
			// Try to get the favicon for this URL.
			[self downloadFaviconsIfEnabled];
		}
	}
	else
	{
		if(mCurrentSheet == importerWindow)
		{
			NSLog(@"Error importing bookmarks. Delicious returned an error response code.");
			
			NSString *errorSavingAtThisTime = DXLocalizedString(@"Error saving bookmarks to Delicious at this time. Please try again later.",
																@"Error saving bookmarks to Delicious at this time message.");
			
			[importerMessage setStringValue:errorSavingAtThisTime];
			
			[self setEnabledForImporterFields:YES];
			
			// Rebuild menus. This may be a partially successful import.
			[self createDeliciousMenu];
			
			// Try to get the favicon for the URLs that were saved.
			[self downloadFaviconsIfEnabled];
		}
		else
		{
			[self displayPostErrorAlert:postDictionary];
		}
	}
}

- (void)deliciousAPIPostDeleteResponse:(BOOL)didSucceed withRemovedURL:(NSString*)removedURL
{
}


#pragma mark ---- NSTokenField Delegates ----

-(NSArray *)tokenField:(NSTokenField *)tokenField completionsForSubstring:(NSString *)substring
		  indexOfToken:(NSInteger)tokenIndex
   indexOfSelectedItem:(NSInteger *)selectedIndex
{
	// TODO: Use FDO to search this instead of filtering an array.
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF beginswith[cd] %@", substring];
	return [[mDB tags] filteredArrayUsingPredicate:predicate];
}

-(void) dxDeliciousDatabaseFaviconCallback:(BOOL)somethingChanged
{
	if(somethingChanged)
		[self createDeliciousMenu];
}


-(void)updateCheckTimerFired:(NSTimer*)timer
{
	if([mDB isLoggedIn])
		[mAPI updateRequest];
}

- (id)windowWillReturnFieldEditor:(NSWindow *)window toObject:(id)anObject
{
	if(window == postWindow)
	{
		if(anObject == postName)
			return spellCheckingFieldEditor;
	}
	
	return nil;
}

-(void)setIsOnline:(BOOL)isOnline
{
	if(isOnline && [mDB isLoggedIn])
		[mAPI startProcessingPendingBookmarks];	
}

@end


static void my_SCNetworkReachabilityCallBack(SCNetworkReachabilityRef target,
											 SCNetworkConnectionFlags flags,
											 void *info)
{	
	if(info == NULL)
	{
		NSLog(@"DeliciousSafari internal error. Got nil info parameter for my_SCNetworkReachabilityCallBack");
		return;
	}
	
	DXDeliciousExtender* extender = (DXDeliciousExtender*)info;
	BOOL isOnline = NO;
	
	// From experimenting, it looks like kSCNetworkFlagsReachable is set and
	// kSCNetworkFlagsConnectionRequired is not set when a network connection is working (i.e. can contact the host).
	// However, sometimes kSCNetworkFlagsIsDirect is set when it seems like it shouldn't be. If kSCNetworkFlagsIsDirect
	// is set, then the link is most likely not connected.
	if((flags & kSCNetworkFlagsReachable) && !(flags & kSCNetworkFlagsConnectionRequired) && !(flags & kSCNetworkFlagsIsDirect))
	{
		//NSLog(@"  STATUS: GOOD TO GO\n");
		isOnline = YES;
	}
	
	[extender setIsOnline:isOnline];
}

void DXLoadPlugin(void)
{
	//NSLog(@"DXLoadPlugin called.");
	[DXDeliciousExtender loadPlugin];
}
