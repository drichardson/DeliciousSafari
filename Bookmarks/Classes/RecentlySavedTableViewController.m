//
//  RecentlySavedTableViewController.m
//  Bookmarks
//
//  Created by Doug on 10/7/08.
//  Copyright 2008 Douglas Richardson. All rights reserved.
//

#import "RecentlySavedTableViewController.h"
#import "DXDeliciousDatabase.h"
#import "DeliciousSafariDefinitions.h"

@interface RecentlySavedTableViewController (private)
- (void)updateFooterText;
@end

@implementation RecentlySavedTableViewController

- (id)initWithNumberOfRecentPosts:(NSUInteger)numberOfRecentPosts 
{
	if (self = [super initWithStyle:UITableViewStylePlain]) 
	{
		self.title = NSLocalizedString(@"Recently Saved", nil);
		
		_numberOfRecentPosts = numberOfRecentPosts;
		self.postsArray = [[DXDeliciousDatabase defaultDatabase] recentPosts:_numberOfRecentPosts];
		
		
		// this is configured here because our superclass' -init method is not called and doesn't do so for us
		footerText = [[UILabel alloc] initWithFrame:CGRectMake(0, 15, self.tableView.frame.size.width, 50)];
		footerText.font = [UIFont systemFontOfSize:18.0];
		footerText.textAlignment = UITextAlignmentCenter;
		footerText.textColor = [UIColor grayColor];
		self.tableView.tableFooterView = footerText;
		
		self.numberFormatter = [[[NSNumberFormatter alloc] init] autorelease];
		[self.numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
		[self.numberFormatter setLocale:[NSLocale currentLocale]];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(postsUpdatedNotification:)
													 name:kDeliciousPostsUpdatedNotification
												   object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(postsAddedNotification:)
													 name:kDeliciousPostAddResponseNotification
												   object:nil];
	}
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

-(void)postsUpdatedNotification:(NSNotification*)notification
{
//	NSLog(@"RecentlySaved - Got posts updated notification.");
	self.postsArray = [[DXDeliciousDatabase defaultDatabase] recentPosts:_numberOfRecentPosts];
}

-(void)postsAddedNotification:(NSNotification*)notification
{
	NSNumber *didSucceed = [[notification userInfo] objectForKey:kDeliciousPostAddResponse_DidSucceedKey];
//	NSLog(@"RecentlySaved - Got post added notification (%@)", didSucceed);
	
	if([didSucceed boolValue])
	{
		self.postsArray = [[DXDeliciousDatabase defaultDatabase] recentPosts:_numberOfRecentPosts];
		[self updateFooterText];
	}
}

- (void)viewDidAppear:(BOOL)animated {
	[self updateFooterText];
	[super viewDidAppear:animated];
	
	[[NSUserDefaults standardUserDefaults] setObject:kUserDefault_LastViewRecents forKey:kUserDefault_LastViewKey];
}

- (void)updateFooterText
{
	if (self.postsArray.count == 1)
		footerText.text = [NSString stringWithFormat:@"%d Bookmark", self.postsArray.count];
	else
		footerText.text = [NSString stringWithFormat:@"%@ Bookmarks", [self.numberFormatter stringForObjectValue:[NSNumber numberWithInteger:self.postsArray.count]]];	
}

@end
