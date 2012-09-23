//
//  DeliciousSafariAppDelegate.m
//  DeliciousSafari
//
//  Created by Doug Richardson on 6/21/08.
//  Copyright Douglas Ryan Richardson 2008. All rights reserved.
//

#import "DeliciousSafariAppDelegate.h"
#import "DXDeliciousDatabase.h"
#import "BookmarksDeliciousAPIManager.h"
#import "AllTagsTableViewController.h"
#import "TopLevelViewController.h"
#import "SaveBookmarkViewController.h"

@interface DeliciousSafariAppDelegate (private)
- (void)upgradeOldDatabaseIfNecessary;
@end

@implementation DeliciousSafariAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(UIApplication *)application
{
	[self upgradeOldDatabaseIfNecessary];
	
	[[BookmarksDeliciousAPIManager sharedManager] addObserver:self forKeyPath:@"isUpdating" options:NSKeyValueObservingOptionNew context:nil];
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(badCredentialsNotification:) name:kDeliciousBadCredentialsNotification object:nil];
	[nc addObserver:self selector:@selector(connectionFailedNotification:) name:kDeliciousConnectionFailedNotification object:nil];
	
	TopLevelViewController *topLevelViewController = [[[TopLevelViewController alloc] init] autorelease];
	
	navigationViewController = [[MainNavigationViewController alloc] initWithRootViewController:topLevelViewController];
	navigationViewController.navigationBar.barStyle = UIBarStyleDefault;
	
	[window addSubview:navigationViewController.view];

	NSString *username = [[DXDeliciousDatabase defaultDatabase] username];
	if(username.length > 0)
	{
		if(![[DXDeliciousDatabase defaultDatabase] shouldFetchBookmarksManually])
			[[BookmarksDeliciousAPIManager sharedManager] updateRequest];
	}
	
	// For debugging the save bookmark view, uncomment the following line:
	//[self showSaveBookmarkViewWithURL:@"http://www.google.com" withTitle:@"Google Test URL - REMOVE ME"];
}

-(BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
	// javascript:window.location='dsbookmarks://save?url='+encodeURIComponent(document.location)+'&title='+encodeURIComponent(document.title)
	NSLog(@"Got application handle open URL: %@", url);

	NSArray *myURLSchemes = [NSArray arrayWithObjects:@"dsbookmarks", @"dsbookmarkspro", nil];

	if([url scheme] != nil && [myURLSchemes containsObject:[url scheme]])
	{
		NSString *query = [url query];
		NSLog(@"  the query is %@", query);
		
		NSArray *queryComponents = [query componentsSeparatedByString:@"&"];
		NSLog(@"  components: %@", queryComponents);
		
		NSString *urlString = nil;
		NSString *titleString = nil;
		
		for(NSString *component in [query componentsSeparatedByString:@"&"])
		{
			NSArray *componentParts = [component componentsSeparatedByString:@"="];
			if([componentParts count] != 2)
			{
				NSLog(@"Didn't get 2 component parts for %@. Got %d", component, [componentParts count]);
				continue;
			}
			
			NSString *name = [componentParts objectAtIndex:0];
			NSString *value = [componentParts objectAtIndex:1];
			
			//NSLog(@"value is: raw=%@, c1=%@, c2=%@", value,
			//	  [value stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
			//	  [(NSString*)CFURLCreateStringByReplacingPercentEscapes(NULL, (CFStringRef)value, CFSTR("")) autorelease]);
			
			value = [value stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
			
			if([name isEqual:@"url"])
				urlString = value;
			else if([name isEqual:@"title"])
				titleString = value;
		}
		
		//NSLog(@"urlString = %@, titleString = %@", urlString, titleString);
		
		if(urlString != nil && titleString != nil)
		{			
#if 0
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Good URL"
															message:[NSString stringWithFormat:@"URL: %@\nTitle: %@", urlString, titleString]
														   delegate:nil
												  cancelButtonTitle:@"OK"
												  otherButtonTitles:nil];
			[alert show];
			[alert release];
#endif
			[self showSaveBookmarkViewWithURL:urlString withTitle:titleString animated:NO]; 
			
			return YES;
		}
	}
	
	NSString *urlStringMessage = [NSString stringWithFormat:NSLocalizedString(@"Could not save bookmark at URL %@", @"Diagnostic message for bad custom URL hanadler"), url];
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error Saving Bookmark", @"Title of error saving bookmark message.")
													message:urlStringMessage delegate:nil
										  cancelButtonTitle:NSLocalizedString(@"OK", nil)
										  otherButtonTitles:nil];
	[alert show];
	[alert release];
	
	return NO;
}

-(void)showSaveBookmarkViewWithURL:(NSString*)url withTitle:(NSString*)title animated:(BOOL)shouldAnimate
{
    SaveBookmarkViewController* saveBookmarkViewController = [[SaveBookmarkViewController alloc] initWithNibName:@"SaveBookmarkView" bundle:[NSBundle mainBundle]];
	
	saveBookmarkViewController.urlString = url;
	saveBookmarkViewController.titleString = [title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	[UIApplication sharedApplication].applicationSupportsShakeToEdit = YES;
	[navigationViewController presentModalViewController:saveBookmarkViewController animated:shouldAnimate];
	
	if (url == nil && title == nil)
		[saveBookmarkViewController configureForAdd];
    
    [saveBookmarkViewController release];
}

- (void)createBookmarklet
{
	NSString *bookmarkletURL = @"http://delicioussafari.com/___?javascript:window.location='dsbookmarkspro://save?url='+encodeURIComponent(document.location)+'&title='+encodeURIComponent(document.title)";
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:bookmarkletURL]];
}

- (void)dealloc
{
	[[BookmarksDeliciousAPIManager sharedManager] removeObserver:self forKeyPath:@"isUpdating"];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[window release];
	[navigationViewController release];
	
	[super dealloc];
}

- (void)upgradeOldDatabaseIfNecessary
{
	NSString *databaseVersionKey = @"DatabaseVersion";
	NSUserDefaults *udefs = [NSUserDefaults standardUserDefaults];
	NSInteger databaseVersion = [udefs integerForKey:databaseVersionKey];
	
	if(databaseVersion == 0)
	{
		NSLog(@"Upgrading database.");
		[[DXDeliciousDatabase defaultDatabase] cleanupObsoleteDatabaseFields]; // Remove the old storage.
		[[DXDeliciousDatabase defaultDatabase] setLastUpdated:nil]; // Reset last updated so the database will be repopulated.
		[udefs setInteger:1 forKey:databaseVersionKey];
	}
}

-(void)badCredentialsNotification:(NSNotification*)notification
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Invalid Username or Password", @"Title of invalid username or password error alert.")
													message:NSLocalizedString(@"Go to settings to update your account information.", @"Message text of invalid username or password error alert.")
												   delegate:nil
										  cancelButtonTitle:NSLocalizedString(@"OK", nil)
										  otherButtonTitles:nil];
	[alert show];
	[alert release];
	
}

-(void)connectionFailedNotification:(NSNotification*)notification
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Connection Error", @"Title of connection error alert.")
													message:NSLocalizedString(@"Delicious could not be contacted. Make sure you are connected to the Internet or try again later.", @"Message text of connection error alert.")
												   delegate:nil
										  cancelButtonTitle:NSLocalizedString(@"OK", nil)
										  otherButtonTitles:nil];
	[alert show];
	[alert release];	
}

#pragma mark KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if(object == [BookmarksDeliciousAPIManager sharedManager])
	{
		if([keyPath isEqualToString:@"isUpdating"])
		{
			NSNumber *isUpdating = [change objectForKey:NSKeyValueChangeNewKey];
			[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:[isUpdating boolValue]];
		}
	}
}

@end
