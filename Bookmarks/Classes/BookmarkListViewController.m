//
//  BookmarkListViewController.m
//  DeliciousSafari
//
//  Created by Doug Richardson on 6/21/08.
//  Copyright 2008 Douglas Ryan Richardson. All rights reserved.
//

#import "BookmarkListViewController.h"
#import "DXDeliciousDatabase.h"
#import "BookmarksDeliciousAPIManager.h"
#import "UITableViewController+BrowserViewAdditions.h"

@interface BookmarkListViewController (private)
- (void)updateFooterText;
@end;

@implementation BookmarkListViewController

@dynamic postsArray;
@synthesize numberFormatter;

- (id)init 
{
	self = [super initWithStyle:UITableViewStylePlain];
	
	footerText = [[UILabel alloc] initWithFrame:CGRectMake(0, 15, self.tableView.frame.size.width, 50)];
	footerText.font = [UIFont systemFontOfSize:18.0];
	footerText.textAlignment = UITextAlignmentCenter;
	footerText.textColor = [UIColor grayColor];
	self.tableView.tableFooterView = footerText;
	
	self.numberFormatter = [[[NSNumberFormatter alloc] init] autorelease];
	[self.numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
	[self.numberFormatter setLocale:[NSLocale currentLocale]];
	
	return self;
}

-(NSArray*)postsArray
{
	return [[_postsArray retain] autorelease];
}

-(void)setPostsArray:(NSArray*)newPostsArray
{
	if(_postsArray != newPostsArray)
	{
		[self willChangeValueForKey:@"postsArray"];
		[_postsArray release];
		_postsArray = [newPostsArray mutableCopy];
		[self didChangeValueForKey:@"postsArray"];
		
		[self.tableView reloadData];
		[self updateFooterText];
	}
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [_postsArray count];
}

UITableViewCell* CreateBookmarkTableViewCell(NSString *reuseIdentifier)
{
	UITableViewCell *cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier] autorelease];
	
	CGRect subviewRect = cell.bounds;
	const CGFloat xOffset = 10.0;
	subviewRect.origin.x += xOffset;
	subviewRect.size.width -= xOffset * 2.0;
	
	UILabel *label = [[[UILabel alloc] initWithFrame:subviewRect] autorelease];
	label.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	label.tag = kBookmarkCellLabelViewTag;
	label.numberOfLines = 2;
	label.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
	label.highlightedTextColor = [UIColor whiteColor];

    // uncomment for unfinished bookmark detail disclosure
	//cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
	
	[cell.contentView addSubview:label];
	
	return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *MyIdentifier = @"MyIdentifier";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
	UILabel *label = nil;
	
	if (cell == nil)
		cell = CreateBookmarkTableViewCell(MyIdentifier);
	
	label = (UILabel*)[cell.contentView viewWithTag:kBookmarkCellLabelViewTag];
	
	// Configure the cell
	NSDictionary *postDictionary = [_postsArray objectAtIndex:indexPath.row];
	label.text = [postDictionary objectForKey:kDXPostDescriptionKey];
		
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{	
	NSDictionary *postDictionary = [_postsArray objectAtIndex:indexPath.row];
	NSString *urlString = [postDictionary objectForKey:kDXPostURLKey];
	//NSLog(@"Opening URL: %@", urlString);
	
	[self openURLInBrowser:urlString];	
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath 
{	
	if (editingStyle == UITableViewCellEditingStyleDelete) 
	{
		NSDictionary *postDictionary = [_postsArray objectAtIndex:indexPath.row];
		NSString *urlString = [postDictionary objectForKey:kDXPostURLKey];
		[[BookmarksDeliciousAPIManager sharedManager] postDeleteRequest:urlString];
		
		[_postsArray removeObjectAtIndex:indexPath.row];
		
		[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
		[self updateFooterText];
	}
}

-(void)prepareForCompletion
{	
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
																							target:self
																							action:@selector(prepareForEdit)] autorelease];
	[self.tableView setEditing:YES animated:YES];
}

- (void)prepareForEdit
{
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
																							target:self
																							action:@selector(prepareForCompletion)] autorelease];
	
	[self.tableView setEditing:NO animated:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
	[self updateFooterText];
	[super viewWillAppear:animated];
	
	[UIApplication sharedApplication].applicationSupportsShakeToEdit = NO;
	
	if([[BookmarksDeliciousAPIManager sharedManager] isUpdating])
		[self startActivityIndicator];
	else
		[self prepareForEdit];	
}

- (void)updateFooterText
{
	if (self.postsArray.count == 1)
		footerText.text = [NSString stringWithFormat:NSLocalizedString(@"%d Bookmark", nil), self.postsArray.count];
	else
		footerText.text = [NSString stringWithFormat:NSLocalizedString(@"%@ Bookmarks", nil), [self.numberFormatter stringForObjectValue:[NSNumber numberWithInteger:self.postsArray.count]]];
}

- (void)dealloc {
	[footerText release];
	[numberFormatter release];
	[super dealloc];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];	
}

@end
