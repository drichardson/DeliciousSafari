//
//  TesterController.m
//  Safari Delicious Extension Test Code
//
//  Created by Douglas Richardson.
//  Copyright 2007 Douglas Richardson. All rights reserved.
//

#import "TesterController.h"

@implementation TesterController

- (id)init
{
	if([super init])
	{
		mAPI = [[DXDeliciousAPI alloc] init];
		[mAPI setDelegate:self];
		
		mDB = [[DXDeliciousDatabase alloc] initWithDatabasePath:@"~/Desktop/Delicious Database.plist"];
	}
	return self;
}

- (void)dealloc
{
	[mAPI release];
	[mDB release];
	[super dealloc];
}

- (void)addResultText:(NSString*)text
{
	NSAttributedString *attrStr = [[NSAttributedString alloc] initWithString:text];
	[[results textStorage] appendAttributedString:attrStr];
	[attrStr release];
	[results scrollRangeToVisible:NSMakeRange([[results string] length],0)];
}

- (IBAction)getAllPosts:(id)sender
{
	NSLog(@"getAllPosts: %@", sender);
	[mAPI postsAllRequest];
}

- (void) deliciousAPIPostAllResponse:(NSArray*)posts
{
	NSLog(@"deliciousAPIGetTagsResponse: %@", posts);
	
	[self addResultText:@"Start Posts -------------------------------------\n"];
	
	int i;
	int count = [posts count];
	for(i = 0; i < count; ++i)
	{
		NSDictionary *post = [posts objectAtIndex:i];
		NSString *href = [post objectForKey:kDXPostURLKey];
		NSString *description = [post objectForKey:kDXPostDescriptionKey];
		NSArray *tagArray = [post objectForKey:kDXPostTagArrayKey];
		
		[self addResultText:[NSString stringWithFormat:@" href='%@', %@, tags=%@\n", href, description, tagArray]];
	}
	
	[self addResultText:@"End Posts -------------------------------------\n"];
	
	[mDB updateDatabaseWithDeliciousAPIPosts:posts];
}

- (IBAction)getTags:(id)sender
{
	NSLog(@"getTags: %@", sender);
	[mAPI getTagsRequest];
}

- (void) deliciousAPIGetTagsResponse:(NSArray*)tags
{
	NSLog(@"deliciousAPIGetTagsResponse: %@", tags);
	
	[self addResultText:@"Start Tags -------------------------------------\n"];
	
	int i;
	int count = [tags count];
	for(i = 0; i < count; ++i)
	{
		NSDictionary *tag = [tags objectAtIndex:i];
		NSString *tagName = [tag objectForKey:@"tag"];
		NSNumber *tagCount = [tag objectForKey:@"count"];
		[self addResultText:[NSString stringWithFormat:@" %@: %d\n", tagName, [tagCount intValue]]];
	}
	
	[self addResultText:@"End Tags -------------------------------------\n"];
}

- (IBAction)update:(id)sender
{
	NSLog(@"update: %@", sender);
	[mAPI updateRequest];
}

- (IBAction)post:(id)sender
{
	NSLog(@"post: %@", sender);
	
	NSArray *tags = [[postTags stringValue] componentsSeparatedByString:@" "];
	
	[mAPI postAddRequest:[postURL stringValue]
		 withDescription:[postDescription stringValue]
			withExtended:[postExtendedDescription stringValue]
				withTags:tags
		   withDateStamp:nil
	   withShouldReplace:nil
			withIsShared:nil];
}

- (void) deliciousAPIUpdateResponse:(NSDate*)lastUpdatedDate
{
	NSLog(@"deliciousAPIUpdateComplete: %@", lastUpdatedDate);
	[self addResultText:[NSString stringWithFormat:@"Last updated: %@\n", lastUpdatedDate]];
}

- (void) deliciousAPIPostAddResponse:(NSNumber*)didSucceed
{
	if([didSucceed boolValue])
		NSLog(@"Post succeeded :)");
	else
		NSLog(@"Post failed :(");
}

- (NSString*)deliciousAPIGetUsername
{
	return [username stringValue];
}

- (NSString*)deliciousAPIGetPassword
{
	return [password stringValue];
}

- (void)deliciousAPIBadCredentials
{
	[self addResultText:@"Bad Credential Data"];
}

- (IBAction)getAllDatabasePosts:(id)sender
{
	NSLog(@"getAllDatabasePosts: sender: %@", sender);
	
	NSString *tag = [postTags stringValue];
	[self addResultText:@"Database Posts START -----------------------\n"];
	[self addResultText:[NSString stringWithFormat:@"Looking for posts with tag %@\n", tag]];
	
	NSEnumerator *postsEnum = [[mDB postsForTagArray:[NSArray arrayWithObject:tag]] objectEnumerator];
	NSDictionary *post = nil;
	while(post = [postsEnum nextObject])
	{
		[self addResultText:[[post objectForKey:kDXPostURLKey] stringByAppendingString:@"\n"]];
	}
	
	[self addResultText:@"Database Posts END -----------------------\n"];
}

- (IBAction)getAllDatabaseTags:(id)sender
{
	NSLog(@"getAllDatabaseTags: sender: %@", sender);
	
	[self addResultText:@"Database Tags START -----------------------\n"];
	
	NSEnumerator *tagsEnum = [[mDB tags] objectEnumerator];
	NSString *tag = nil;
	while(tag = [tagsEnum nextObject])
	{
		[self addResultText:[tag stringByAppendingString:@"\n"]];
	}
	
	[self addResultText:@"Database Tags END -----------------------\n"];	
}

@end
