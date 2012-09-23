//
//  TagListTableViewController.m
//  Bookmarks
//
//  Created by Doug on 10/20/08.
//  Copyright 2008 Douglas Richardson. All rights reserved.
//

#import "BookmarksForTagTableViewController.h"
#import "DXDeliciousDatabase.h"
#import "DeliciousSafariDefinitions.h"


@implementation BookmarksForTagTableViewController

-(id)initWithTag:(NSString*)tag
{
	self = [super init];
	
	if(self != nil)
	{
		_tag = [tag retain];
		self.title = _tag;
		self.postsArray = [[DXDeliciousDatabase defaultDatabase] postsForTagArray:[NSArray arrayWithObject:_tag]];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(postsUpdatedNotification:)
													 name:kDeliciousPostsUpdatedNotification
												   object:nil];
	}
	
	return self;
}

-(void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[_tag release];
	[super dealloc];
}

-(void)postsUpdatedNotification:(NSNotification*)notification
{
	NSLog(@"Tag List - Got posts updated notification.");
	self.postsArray = [[DXDeliciousDatabase defaultDatabase] postsForTagArray:[NSArray arrayWithObject:_tag]];
}

@end
