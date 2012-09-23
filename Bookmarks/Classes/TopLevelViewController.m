//
//  TopLevelViewController.m
//  Bookmarks
//
//  Created by Doug on 10/6/08.
//  Copyright 2008 Douglas Richardson. All rights reserved.
//

#import "DeliciousSafariAppDelegate.h"
#import "TopLevelViewController.h"
#import "AllTagsTableViewController.h"
#import "FavoriteTagsTableViewController.h"
#import "BundlesTableViewController.h"
#import "RecentlySavedTableViewController.h"
#import "SettingsTableViewController.h"
#import "BookmarksDeliciousAPIManager.h"
#import "BookmarksForTagTableViewController.h"
#import "UITableViewController+BrowserViewAdditions.h"

#import "DXDeliciousDatabase.h"
#import "DeliciousSafariDefinitions.h"

const NSUInteger kRecentPostCount = 1000000;
const NSUInteger kSearchResultLimit = 100;

@interface TopLevelViewController (private)
- (void)configureCell:(UITableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath;
@end

@implementation TopLevelViewController

enum
{
	kBookmarksSection = 0,
	kExtrasSection,
	kSectionCount
};

enum
{
	kBookmarksAllTagsRow = 0,
	//kBookmarksBundlesRow,
	kBookmarksFavoriteTagsRow,
	kRecentlySavedRow,
	kRefreshAllRow,
	kBookmarksSectionCount
};

enum
{
	kExtrasSettings = 0,
	kExtrasSectionCount
};


- (id)init
{
	if (self = [super initWithNibName:@"TopLevelView" bundle:nil])
	{
		[[BookmarksDeliciousAPIManager sharedManager] addObserver:self forKeyPath:@"isUpdating" options:NSKeyValueObservingOptionNew context:nil];
		self.title = NSLocalizedString(@"Bookmarks", @"Bookmarks application title.");
	}
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[gradientView release];
	[tagSearchResults release];
	[bookmarkSearchResults release];
	[super dealloc];
}

- (void)prepareForEdit
{
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
																							target:self
																							action:@selector(addNewBookmark:)] autorelease];	
}

- (void)addNewBookmark:(id)sender
{
	[(DeliciousSafariAppDelegate *)[[UIApplication sharedApplication] delegate] showSaveBookmarkViewWithURL:nil withTitle:nil animated:YES];
}


#pragma mark TableView Data Source
-(NSInteger)tagSearchResultsSectionNumber
{
	NSInteger result = -1;
	
	if(tagSearchResults != nil && [tagSearchResults count] > 0)
		result = 0;
	
	return result;
}

-(NSInteger)bookmarkSearchResultsSectionNumber
{
	NSInteger result = -1;
	
	if(bookmarkSearchResults != nil && [bookmarkSearchResults count] > 0)
	{
		if([self tagSearchResultsSectionNumber] > -1)
			result = 1;
		else
			result = 0;
	}
	
	return result;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	NSInteger result = 0;
	
	if(tableView == self.searchDisplayController.searchResultsTableView)
	{
		result = [self bookmarkSearchResultsSectionNumber];
		
		if(result == -1)
			result = [self tagSearchResultsSectionNumber];
		
		if(result == -1)
			result = 0;
		else
			result++;
	}
	else
	{
		result = kSectionCount;
	}
	
	return result;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if(tableView == self.searchDisplayController.searchResultsTableView)
	{
		if([self bookmarkSearchResultsSectionNumber] == 1) // If bookmarks is section 1 then All tags is selected, so use section headers to organize results.
		{
			if(section == [self tagSearchResultsSectionNumber])
				return NSLocalizedString(@"Tags", nil);
			else if(section == [self bookmarkSearchResultsSectionNumber])
				return NSLocalizedString(@"Bookmarks", nil);
		}
	}
	
	return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if(tableView == self.searchDisplayController.searchResultsTableView)
	{
		if(section == [self tagSearchResultsSectionNumber])
			return [tagSearchResults count];
		else if(section == [self bookmarkSearchResultsSectionNumber])
			return [bookmarkSearchResults count];
	}
	else
	{
		switch(section)
		{
			case kBookmarksSection:
				return kBookmarksSectionCount;
				
			case kExtrasSection:
				return kExtrasSectionCount;
		}
	}
	
	return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = nil;
	
	if(tableView == self.searchDisplayController.searchResultsTableView)
	{
		if(indexPath.section == [self tagSearchResultsSectionNumber])
		{
			NSString *tagCellIdentifier = @"TopLevelCell";
			cell = [tableView dequeueReusableCellWithIdentifier:tagCellIdentifier];
			
			if (cell == nil)
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:tagCellIdentifier] autorelease];
			
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.textLabel.text = [tagSearchResults objectAtIndex:indexPath.row];
		}
		else if(indexPath.section == [self bookmarkSearchResultsSectionNumber])
		{
			NSString *bookmarkCellIdentifier = @"BookmarkCell";
			cell = [tableView dequeueReusableCellWithIdentifier:bookmarkCellIdentifier];
			UILabel *label = nil;
			
			if (cell == nil)
				cell = CreateBookmarkTableViewCell(bookmarkCellIdentifier);
			
			label = (UILabel*)[cell.contentView viewWithTag:kBookmarkCellLabelViewTag];
			
			// Configure the cell
			NSDictionary *postDictionary = [bookmarkSearchResults objectAtIndex:indexPath.row];
			label.text = [postDictionary objectForKey:kDXPostDescriptionKey];
		}
	}
	else
	{
		NSString *identifier = @"TopLevelCell";
		cell = [tableView dequeueReusableCellWithIdentifier:identifier];
		
		if (cell == nil)
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier] autorelease];
		
		[self configureCell:cell forIndexPath:indexPath];
	}
	
	return cell;
}

- (void)configureCell:(UITableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath {
    	
	switch(indexPath.section)
	{			
		case kBookmarksSection:
		{
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			
			switch(indexPath.row)
			{
				case kBookmarksAllTagsRow:
					cell.imageView.image = [UIImage imageNamed:@"TagIcon.png"];
					cell.textLabel.text = NSLocalizedString(@"All Tags", nil);
					break;
					
#if 0
				case kBookmarksBundlesRow:
					cell.textLabel.text = NSLocalizedString(@"Bundles", @"Delicious bundles");
					break;
#endif
					
				case kBookmarksFavoriteTagsRow:
					cell.imageView.image = [UIImage imageNamed:@"FavoriteItemsIcon.png"];
					cell.textLabel.text = NSLocalizedString(@"Favorite Tags", nil);
					break;
					
				case kRecentlySavedRow:
					cell.imageView.image = [UIImage imageNamed:@"RecentItemsIcon.png"];
					cell.textLabel.text = NSLocalizedString(@"Recently Saved", nil);
					break;
					
				case kRefreshAllRow:
					cell.accessoryType = UITableViewCellAccessoryNone;
					cell.textLabel.text = NSLocalizedString(@"Refresh", nil);
					cell.textLabel.textAlignment = UITextAlignmentCenter;
					break;
			}
			
			break;
		}
			
		case kExtrasSection:
		{
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			
			switch(indexPath.row)
			{
				case kExtrasSettings:
					cell.imageView.image = [UIImage imageNamed:@"GeneralPrefsIcon.png"];
					cell.textLabel.text = NSLocalizedString(@"Settings", nil);
					break;
			}
			
			break;
		}
	}
} 


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(tableView == self.searchDisplayController.searchResultsTableView)
	{
		if(indexPath.section == [self tagSearchResultsSectionNumber])
		{
			NSString *tag = [tagSearchResults objectAtIndex:indexPath.row];	
			BookmarksForTagTableViewController *bookmarkListViewController = [[[BookmarksForTagTableViewController alloc] initWithTag:tag] autorelease];
			[self.navigationController pushViewController:bookmarkListViewController animated:YES];
		}
		else if(indexPath.section == [self bookmarkSearchResultsSectionNumber])
		{
			NSDictionary *postDictionary = [bookmarkSearchResults objectAtIndex:indexPath.row];
			NSString *urlString = [postDictionary objectForKey:kDXPostURLKey];
			//	NSLog(@"Opening URL: %@", urlString);
			
			[self openURLInBrowser:urlString];
		}
	}
	else
	{
		switch(indexPath.section)
		{
			case kBookmarksSection:
			{
				
				switch(indexPath.row)
				{
					case kBookmarksAllTagsRow:
						[self.navigationController pushViewController:[[[AllTagsTableViewController alloc] initWithStyle:UITableViewStylePlain] autorelease] animated:YES];
						break;
						
					case kBookmarksFavoriteTagsRow:
						[self.navigationController pushViewController:[[[FavoriteTagsTableViewController alloc] initWithStyle:UITableViewStylePlain] autorelease] animated:YES];
						break;
						
					case kRecentlySavedRow:
						[self.navigationController pushViewController:[[[RecentlySavedTableViewController alloc] initWithNumberOfRecentPosts:kRecentPostCount] autorelease] animated:YES];
						break;
						
					case kRefreshAllRow:
						[[BookmarksDeliciousAPIManager sharedManager] updateRequest];
						break;
						
	#if 0
					case kBookmarksBundlesRow:
						[self.navigationController pushViewController:[[[BundlesTableViewController alloc] initWithStyle:UITableViewStylePlain] autorelease] animated:YES];
						break;
	#endif
				}
				
				break;
			}
				
			case kExtrasSection:
			{
				switch(indexPath.row)
				{
					case kExtrasSettings:
						[self.navigationController pushViewController:[[[SettingsTableViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease] animated:YES];
						break;
				}
				
				break;
			}
		}
	}
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark UIViewController
- (void)viewDidLoad
{
	[super viewDidLoad];
	
	// set up the search bar
	UISearchBar *searchBar = self.searchDisplayController.searchBar;
    searchBar.scopeButtonTitles = [NSArray arrayWithObjects:
								   NSLocalizedString(@"All", @"All search scope"),
								   NSLocalizedString(@"Tags", @"Tags search scope"),
								   NSLocalizedString(@"Bookmarks", @"Bookmarks search scope"),
								   nil];
	searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
	searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
		
	NSString *lastView = [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefault_LastViewKey];
	if(lastView == nil || ![lastView isKindOfClass:[NSString class]])
		lastView = kUserDefault_LastViewTop;
	
	NSString *username = [[DXDeliciousDatabase defaultDatabase] username];
	if(username.length <= 0)
	{
		[self.navigationController pushViewController:[[[SettingsTableViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease] animated:NO];
	}
	else
	{
		if([lastView isEqualToString:kUserDefault_LastViewFavorites])
		{
			[self.navigationController pushViewController:[[[FavoriteTagsTableViewController alloc] initWithStyle:UITableViewStylePlain] autorelease] animated:NO];
		}
		else if([lastView isEqualToString:kUserDefault_LastViewRecents])
		{
			[self.navigationController pushViewController:[[[RecentlySavedTableViewController alloc] initWithNumberOfRecentPosts:kRecentPostCount] autorelease] animated:NO];
		}
		else if([lastView isEqualToString:kUserDefault_LastViewAllTags])
		{
			[self.navigationController pushViewController:[[[AllTagsTableViewController alloc] initWithStyle:UITableViewStylePlain] autorelease] animated:NO];
		}
	}
	
	if (!gradientView)
		gradientView = [[GradientView alloc] init];
}

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope {
	switch (selectedScope)
	{
		case 0:
			searchBar.placeholder = NSLocalizedString(@"Search All", nil);
			break;
		case 1:
			searchBar.placeholder = NSLocalizedString(@"Search Tags", nil);
			break;
		case 2:
			searchBar.placeholder = NSLocalizedString(@"Search Bookmarks", nil);
			break;			
	}
	
	[[NSUserDefaults standardUserDefaults] setInteger:selectedScope forKey:@"SearchScope"];
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
	[UIApplication sharedApplication].applicationSupportsShakeToEdit = YES;
	return YES;
}

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar {
	[UIApplication sharedApplication].applicationSupportsShakeToEdit = NO;
	return YES;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	if([[BookmarksDeliciousAPIManager sharedManager] isUpdating])
		[self startActivityIndicator];
	else
		[self prepareForEdit];
		
	if (shouldReloadTable)
	{
		shouldReloadTable = NO;
		[self.tableView reloadData];
	}
	
	[self.view addSubview:gradientView];
	
	UISearchBar *searchBar = self.searchDisplayController.searchBar;
	NSInteger currentSelection = [[NSUserDefaults standardUserDefaults] integerForKey:@"SearchScope"];
	[searchBar setSelectedScopeButtonIndex:currentSelection];
	[self searchBar:searchBar selectedScopeButtonIndexDidChange:currentSelection];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
	[UIApplication sharedApplication].applicationSupportsShakeToEdit = NO;
	
	[[NSUserDefaults standardUserDefaults] setObject:kUserDefault_LastViewTop forKey:kUserDefault_LastViewKey];
}

- (void)viewWillDisappear:(BOOL)animated {
}

- (void)viewDidDisappear:(BOOL)animated {
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}


#pragma mark UISearchDisplayController Delegate Methods

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
	BOOL searchTags = NO;
	BOOL searchBookmarks = NO;
	
	switch(self.searchDisplayController.searchBar.selectedScopeButtonIndex)
	{
		case 0: // All
			searchTags = searchBookmarks = YES;
			break;
			
		case 1: // Tags
			searchTags = YES;
			break;
			
		case 2: // Bookmarks
			searchBookmarks = YES;
			break;
	}
	
	[tagSearchResults release];
	tagSearchResults = nil;
	
	[bookmarkSearchResults release];
	bookmarkSearchResults = nil;
	
	if(searchTags)
		tagSearchResults = [[[DXDeliciousDatabase defaultDatabase] findTagsBeginningWith:searchString withResultLimit:kSearchResultLimit] retain];
	
	if(searchBookmarks)
		bookmarkSearchResults = [[[DXDeliciousDatabase defaultDatabase] findBookmarksWithTitlesContaining:searchString withResultLimit:kSearchResultLimit] retain];
    
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}


- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption
{	
    return [self searchDisplayController:controller shouldReloadTableForSearchString:self.searchDisplayController.searchBar.text];
}

- (void)scrollViewDidScroll:(UIScrollView *)sv
{
	float percent = sv.contentOffset.y / sv.contentSize.height;
	percent = 0.5 + (MAX(MIN(1.0f, percent), 0.0f) / 2.0f);
	
	if (0.5f == percent) // top will be visible
	{
		UISearchBar *searchBar = self.searchDisplayController.searchBar;

		CGRect newFrame = CGRectMake(0, [searchBar frame].origin.y, [searchBar frame].size.width, sv.contentOffset.y);
		[gradientView setFrame:newFrame];
	}
	else // bottom will be visible
	{

	}
}

@end
