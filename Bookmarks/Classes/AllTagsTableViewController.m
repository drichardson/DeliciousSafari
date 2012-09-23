//
//  TagListViewController.m
//  DeliciousSafari
//
//  Created by Doug Richardson on 6/21/08.
//  Copyright 2008 Douglas Ryan Richardson. All rights reserved.
//

#import "AllTagsTableViewController.h"
#import "BookmarksForTagTableViewController.h"
#import "DXDeliciousDatabase.h"
#import "DeliciousSafariDefinitions.h"

@interface AllTagsTableViewController (private)
-(void)updateFooterText;
-(void)readDeliciousSafariDatabase;
-(void)postsUpdatedNotification:(NSNotification*)notification;
@end

@implementation AllTagsTableViewController

@synthesize tagsBySection, titleToSectionMap, numberFormatter;

- (id)initWithStyle:(UITableViewStyle)style 
{
	if (self = [super initWithStyle:style]) 
	{
		footerText = [[UILabel alloc] initWithFrame:CGRectMake(0, 15, self.tableView.frame.size.width, 50)];
		footerText.font = [UIFont systemFontOfSize:18.0];
		footerText.textAlignment = UITextAlignmentCenter;
		footerText.textColor = [UIColor grayColor];
		self.tableView.tableFooterView = footerText;
		
		self.title = NSLocalizedString(@"All Tags", @"Tag List View Title");
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(postsUpdatedNotification:)
													 name:kDeliciousPostsUpdatedNotification
												   object:nil];
		
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(postsAddedNotification:)
													 name:kDeliciousPostAddResponseNotification
												   object:nil];
		
		self.numberFormatter = [[[NSNumberFormatter alloc] init] autorelease];
		[self.numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
		[self.numberFormatter setLocale:[NSLocale currentLocale]];
		
		[UIApplication sharedApplication].applicationSupportsShakeToEdit = NO;
	}
	return self;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return [self isTagListEmpty] ? 1 : [tagsBySection count];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [self isTagListEmpty] ? 1 : [[tagsBySection objectAtIndex:section] count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *MyIdentifier = @"MyIdentifier";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MyIdentifier] autorelease];
	}
	
	// Configure the cell
	if(indexPath.section == 0 && indexPath.row == 0 && [self isTagListEmpty]) // Only check for isTagsListEmpty on the first row for performance
	{
		cell.textLabel.text = @"";
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
	}
	else
	{
		cell.textLabel.text = [[tagsBySection objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
		cell.selectionStyle = UITableViewCellSelectionStyleBlue;
		//cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
	
	return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if([self isTagListEmpty])
		return @"";
	
	NSArray *sectionArray = [tagsBySection objectAtIndex:section];
	NSString *firstCharacterOfFirstEntry = [[sectionArray objectAtIndex:0] substringToIndex:1];
	return [firstCharacterOfFirstEntry uppercaseString];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(![self isTagListEmpty])
	{
		NSArray *tagArrayForSection = [tagsBySection objectAtIndex:indexPath.section];
		NSString *tag = [tagArrayForSection objectAtIndex:indexPath.row];
		
		BookmarksForTagTableViewController *bookmarkListViewController = [[[BookmarksForTagTableViewController alloc] initWithTag:tag] autorelease];
		
		[self.navigationController pushViewController:bookmarkListViewController animated:YES];
	}
	
	[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)willAnimateSecondHalfOfRotationFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
													   duration:(NSTimeInterval)duration
{
	// Reload the table view to reset the index list for the new orientation.
	[self.tableView reloadData];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
	if([self isTagListEmpty])
		return [NSArray array];
	
	const NSUInteger kMaxSectionTitlesInPortraitOrientation = 24;
	const NSUInteger kMaxSectionTitles = kMaxSectionTitlesInPortraitOrientation;
	
	const NSUInteger tagCount = [tagsBySection count];
	float interval = ((float)tagCount) / ((float)kMaxSectionTitles);
	NSMutableDictionary *titleSectionMap = [NSMutableDictionary dictionary];
	
	NSMutableArray *sectionIndexTitleArray = [NSMutableArray array];
	
	if(interval < 1.0)
		interval = 1.0; // There is more than enough room to display all the section titles in the index list.
	
	float index = 0;
	for(NSUInteger i = (NSUInteger)index; i < tagCount; i = (NSUInteger)index)
	{
		NSArray *sectionArray = [tagsBySection objectAtIndex:i];
		NSString *firstCharacter = [[[sectionArray objectAtIndex:0] substringToIndex:1] uppercaseString];
		[sectionIndexTitleArray addObject:firstCharacter];
		[titleSectionMap setObject:[NSNumber numberWithUnsignedInt:i] forKey:firstCharacter];
		
		index += interval;
	}
	
	self.titleToSectionMap = titleSectionMap;
	
	return sectionIndexTitleArray;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
	if([self isTagListEmpty])
		return 0;
	
	NSNumber *result = [titleToSectionMap objectForKey:title];
	return [result intValue];	
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[footerText release];
	[tagsBySection release];
	[titleToSectionMap release];
	[numberFormatter release];
	
	[super dealloc];
}

-(void)readDeliciousSafariDatabase
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init]; // Could be a lot of autoreleases here, so make a pool to cleanup asap.
	
	NSString *currentFirstCharacter = nil;
	NSMutableArray *currentSectionTagArray = nil;
	NSMutableArray *sectionArray = [[NSMutableArray alloc] init];
	NSArray* tags = [[DXDeliciousDatabase defaultDatabase] tags];
	
	for(NSString *tag in tags)
	{
		if([tag length] <= 0) // Check just in case the database has a blank tag in it so substring below doesn't crash.
			continue;
		
		NSString *firstCharacter = [tag substringToIndex:1];
		if(currentFirstCharacter == nil || ![currentFirstCharacter isEqual:firstCharacter])
		{
			[currentFirstCharacter release];
			currentFirstCharacter = [firstCharacter retain];
			
			currentSectionTagArray = [[NSMutableArray alloc] init];
			[sectionArray addObject:currentSectionTagArray];
			[currentSectionTagArray release];
		}
		
		[currentSectionTagArray addObject:tag];
	}
	
	[currentFirstCharacter release];
	
	totalTags = tags.count;
	self.tagsBySection = sectionArray;
	[sectionArray release];
		
	[pool release];
}

- (void)viewDidLoad
{
	[self readDeliciousSafariDatabase];
	[super viewDidLoad];
	
	[[NSUserDefaults standardUserDefaults] setObject:kUserDefault_LastViewAllTags forKey:kUserDefault_LastViewKey];
}

- (void)viewWillAppear:(BOOL)animated {
	[self updateFooterText];
	[super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
}

- (void)viewDidDisappear:(BOOL)animated {
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	
	if(self.view == nil)
	{
		self.tagsBySection = nil;
	}
}

- (void)updateFooterText
{
	if (totalTags == 1)
		footerText.text = [NSString stringWithFormat:NSLocalizedString(@"%d Tag", nil), totalTags];
	else
		footerText.text = [NSString stringWithFormat:NSLocalizedString(@"%@ Tags", nil), [self.numberFormatter stringForObjectValue:[NSNumber numberWithInteger:totalTags]]];
}

- (BOOL)isTagListEmpty
{
	return tagsBySection == nil || [tagsBySection count] == 0;
}

- (void)postsUpdatedNotification:(NSNotification*)notification
{
	NSLog(@"All tags - Got posts updated notification. Re-reading database.");
	[self readDeliciousSafariDatabase];
	[self.tableView reloadData];
}

- (void)postsAddedNotification:(NSNotification*)notification
{
	NSNumber *didSucceed = [[notification userInfo] objectForKey:kDeliciousPostAddResponse_DidSucceedKey];
	NSLog(@"All tags - Got post added notification (%@)", didSucceed);
	
	if([didSucceed boolValue])
	{
		[self readDeliciousSafariDatabase];
		[self.tableView reloadData];
	}
}

@end
