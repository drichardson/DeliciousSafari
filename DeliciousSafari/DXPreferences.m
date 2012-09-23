//
//  DXPreferences.m
//  DeliciousSafari
//
//  Created by Doug on 3/14/09.
//  Copyright 2009 Douglas Richardson. All rights reserved.
//

#import "DXPreferences.h"
#import "DXDeliciousDatabase.h"

static NSString *kShouldDownloadFaviconsKey				= @"DXShouldDownloadFavicons";
static NSString *kShouldCheckForBookmarksAtStartKey		= @"DXShouldCheckForBookmarksAtStart";
static NSString *kShouldCheckForBookmarksAtIntervalKey	= @"DXShouldCheckForBookmarkAtInterval";
static NSString *kCheckBookmarksIntervalKey				= @"DXCheckBookmarksInterval";
static NSString *kShouldShareBookmarksByDefaultKey		= @"DXShouldShareBookmarksByDefault";

#define kShouldDownloadFavicons_DefaultValue				YES
#define kShouldCheckForBookmarksAtStart_DefaultValue		YES
#define kShouldCheckForBookmarksAtInterval_DefaultValue		YES
#define kCheckBookmarksInterval_DefaultValue				(15.0 * 60.0)
#define kShouldShareBookmarksByDefault_DefaultValue			YES

static DXPreferences *_sharedPreferences;


@interface DXPreferences ()
-(id)initWithDatabase:(DXDeliciousDatabase*)database;
@end


@implementation DXPreferences

+(void)initialize
{
	static BOOL initialized = NO;
	if(!initialized)
	{
		initialized = YES;
		_sharedPreferences = [[DXPreferences alloc] initWithDatabase:[DXDeliciousDatabase defaultDatabase]];
	}
}

+(DXPreferences*)sharedPreferences
{
	return _sharedPreferences;
}

-(id)initWithDatabase:(DXDeliciousDatabase*)database
{
	self = [super init];
	
	if(self)
	{
		_database = [database retain];
	}
	
	return self;
}

-(void)dealloc
{
	[_database release];
	[super dealloc];
}

-(BOOL)shouldDownloadFavicons
{
	return [_database boolForKey:kShouldDownloadFaviconsKey withDefaultValue:kShouldDownloadFavicons_DefaultValue];
}

-(void)setShouldDownloadFavicons:(BOOL)shouldDownloadFavicons
{
	[_database setBool:shouldDownloadFavicons forKey:kShouldDownloadFaviconsKey];
}

-(BOOL)shouldCheckForBookmarksAtStart
{
	return [_database boolForKey:kShouldCheckForBookmarksAtStartKey withDefaultValue:kShouldCheckForBookmarksAtStart_DefaultValue];
}

-(void)setShouldCheckForBookmarksAtStart:(BOOL)shouldCheck
{
	[_database setBool:shouldCheck forKey:kShouldCheckForBookmarksAtStartKey];
}

-(BOOL)shouldCheckForBookmarksAtInterval
{
	return [_database boolForKey:kShouldCheckForBookmarksAtIntervalKey withDefaultValue:kShouldCheckForBookmarksAtInterval_DefaultValue];
}

-(void)setShouldCheckForBookmarksAtInterval:(BOOL)shouldCheck
{
	[_database setBool:shouldCheck forKey:kShouldCheckForBookmarksAtIntervalKey];
}

-(NSTimeInterval)bookmarkCheckInterval
{
	return [_database doubleForKey:kCheckBookmarksIntervalKey withDefaultValue:kCheckBookmarksInterval_DefaultValue];
}

-(void)setBookmarkCheckInterval:(NSTimeInterval)checkInterval
{
	[_database setDouble:checkInterval forKey:kCheckBookmarksIntervalKey];
}

-(BOOL)shouldShareBookmarksByDefault
{
	return [_database boolForKey:kShouldShareBookmarksByDefaultKey withDefaultValue:kShouldShareBookmarksByDefault_DefaultValue];
}

-(void)setShouldShareBookmarksByDefault:(BOOL)shouldSaveByDefault
{
	[_database setBool:shouldSaveByDefault forKey:kShouldShareBookmarksByDefaultKey];
}

-(void)resetToDefaults
{
	[self setShouldDownloadFavicons:kShouldShareBookmarksByDefault_DefaultValue];
	[self setShouldCheckForBookmarksAtStart:kShouldCheckForBookmarksAtStart_DefaultValue];
	[self setShouldCheckForBookmarksAtInterval:kShouldCheckForBookmarksAtInterval_DefaultValue];
	[self setBookmarkCheckInterval:kCheckBookmarksInterval_DefaultValue];
	[self setShouldShareBookmarksByDefault:kShouldShareBookmarksByDefault_DefaultValue];
}

@end
