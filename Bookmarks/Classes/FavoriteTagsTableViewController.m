//
//  FavoriteTagsTableViewController.m
//  Bookmarks
//
//  Created by Doug on 10/6/08.
//  Copyright 2008 Douglas Richardson. All rights reserved.
//

#import "FavoriteTagsTableViewController.h"
#import "SelectFavoriteTagViewController.h"
#import "DXDeliciousDatabase.h"
#import "BookmarksForTagTableViewController.h"
#import "DeliciousSafariDefinitions.h"

@interface FavoriteTagsTableViewController (private)
-(void)updateFooterText;
-(void)enterEditMode:(id)sender;
-(void)leaveEditMode:(id)sender;
-(void)leaveEditModeNoSave;
-(NSString*)compoundTagForIndexPath:(NSIndexPath*)indexPath;
@end

@implementation FavoriteTagsTableViewController

@synthesize favoriteTags, savedNavigationBarItem, numberFormatter;

- (id)initWithStyle:(UITableViewStyle)style 
{
	if (self = [super initWithStyle:style]) 
	{
		self.favoriteTags = [[DXDeliciousDatabase defaultDatabase] favoriteTags];
		
		footerText = [[UILabel alloc] initWithFrame:CGRectMake(0, 15, self.tableView.frame.size.width, 50)];
		footerText.font = [UIFont systemFontOfSize:18.0];
		footerText.textAlignment = UITextAlignmentCenter;
		footerText.textColor = [UIColor grayColor];
		self.tableView.tableFooterView = footerText;
		
		self.numberFormatter = [[[NSNumberFormatter alloc] init] autorelease];
		[self.numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
		[self.numberFormatter setLocale:[NSLocale currentLocale]];		
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(favoritesUpdated:) name:kFavoriteTagsListUpdatedNotification object:nil];
	}
	return self;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [self.favoriteTags count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *MyIdentifier = @"MyIdentifier";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
	if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MyIdentifier] autorelease];
	}
	
	cell.textLabel.text = [self compoundTagForIndexPath:indexPath];
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {	
	NSArray *favoriteTagArray = [self.favoriteTags objectAtIndex:indexPath.row];
	NSString *tag = [favoriteTagArray objectAtIndex:0]; // Currently, only one tag per favorite entry is allowed.
	
	BookmarksForTagTableViewController *bookmarkListViewController = [[[BookmarksForTagTableViewController alloc] initWithTag:tag] autorelease];
	
	[self.navigationController pushViewController:bookmarkListViewController animated:YES];
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		NSMutableArray *favTags = [[self.favoriteTags mutableCopy] autorelease];
		[favTags removeObjectAtIndex:indexPath.row];
		[[DXDeliciousDatabase defaultDatabase] setFavoriteTags:favTags];
		self.favoriteTags = favTags;
		[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
		
		_isDirty = YES;
		
		[self updateFooterText];
	}
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
	NSMutableArray *favTags = [[self.favoriteTags mutableCopy] autorelease];
	
	NSObject* tmp = [favTags objectAtIndex:fromIndexPath.row];
	[favTags removeObjectAtIndex:fromIndexPath.row];
	[favTags insertObject:tmp atIndex:toIndexPath.row];
	
	self.favoriteTags = favTags;
	
	_isDirty = YES;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[footerText release];
	[numberFormatter release];
	self.savedNavigationBarItem = nil;
	[super dealloc];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	self.savedNavigationBarItem = self.navigationItem.leftBarButtonItem;
	
	self.title = NSLocalizedString(@"Favorites", @"Favorite tags nav bar title");
	[self leaveEditModeNoSave];
}

- (void)viewDidAppear:(BOOL)animated {
	[UIApplication sharedApplication].applicationSupportsShakeToEdit = NO;

	[self updateFooterText];
	[super viewDidAppear:animated];
	
	[[NSUserDefaults standardUserDefaults] setObject:kUserDefault_LastViewFavorites forKey:kUserDefault_LastViewKey];
}

- (void)updateFooterText
{
	if (self.favoriteTags.count == 0)
	{
		if (self.tableView.editing)
			footerText.text = [NSString stringWithString:NSLocalizedString(@"Tap + to select a tag", nil)];
		else
			footerText.text = [NSString stringWithString:NSLocalizedString(@"Tap Edit to add favorite tags", nil)];		
	}
	else if (self.favoriteTags.count == 1)
		footerText.text = [NSString stringWithFormat:NSLocalizedString(@"%d Favorite Tag", nil), self.favoriteTags.count];
	else
		footerText.text = [NSString stringWithFormat:NSLocalizedString(@"%@ Favorite Tags", nil), [self.numberFormatter stringForObjectValue:[NSNumber numberWithInteger:self.favoriteTags.count]]];	
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

-(void)enterEditMode:(id)sender
{	
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
																						   target:self
																						   action:@selector(leaveEditMode:)] autorelease];
	
	self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
																						   target:self
																						   action:@selector(addFavoriteEntry:)] autorelease];
	
	
	[self.tableView setEditing:YES animated:YES];
	[self updateFooterText];
}

-(void)leaveEditModeNoSave
{
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
																							target:self
																							action:@selector(enterEditMode:)] autorelease];
	
	self.navigationItem.leftBarButtonItem = self.savedNavigationBarItem;	
}

-(void)leaveEditMode:(id)sender
{
	[self leaveEditModeNoSave];
	
	[self.tableView setEditing:NO animated:YES];
	[self updateFooterText];

	if(_isDirty)
	{
		[[DXDeliciousDatabase defaultDatabase] setFavoriteTags:self.favoriteTags];
		_isDirty = NO;
	}
}

-(void)addFavoriteEntry:(id)sender
{
	SelectFavoriteTagViewController *selectFavoriteTagViewController = [[[SelectFavoriteTagViewController alloc] initWithNibName:@"SelectFavoriteTagView"
																														  bundle:[NSBundle mainBundle]] autorelease];
	[self presentModalViewController:selectFavoriteTagViewController animated:YES];
}

-(void)favoritesUpdated:(NSNotification*)notification
{
	self.favoriteTags = [[DXDeliciousDatabase defaultDatabase] favoriteTags];
	[self.tableView reloadData];
}

-(NSString*)compoundTagForIndexPath:(NSIndexPath*)indexPath
{
	return [[self.favoriteTags objectAtIndex:indexPath.row] componentsJoinedByString:NSLocalizedString(@"+", "The character used to join strings in the favorite tags list.")];
}

@end
