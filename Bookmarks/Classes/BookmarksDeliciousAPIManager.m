//
//  DeliciousAPIDelegate.m
//  Bookmarks
//
//  Created by Doug on 10/14/08.
//  Copyright 2008 Douglas Richardson. All rights reserved.
//

#import "BookmarksDeliciousAPIManager.h"
#import "DeliciousSafariDefinitions.h"
#import "DXDeliciousDatabase.h"

NSString *kIsUserLoggedInKey = @"IsUserLoggedIn";

@interface BookmarksDeliciousAPIManager (private)
-(void)setSavedLastUpdatedTime:(NSDate*)lastUpdatedTime;
@end

@implementation BookmarksDeliciousAPIManager

+(BookmarksDeliciousAPIManager*)sharedManager
{
	static BookmarksDeliciousAPIManager *shared = nil;
	
	if(shared == nil)
	{
		shared = (BookmarksDeliciousAPIManager*)[[self class] sharedInstance];
		[shared setDelegate:shared];
	}
	
	return shared;		
}

@synthesize isUpdating = _isUpdating, database = _database;
@dynamic isUserLoggedIn;

-(id)initWithUserAgent:(NSString*)userAgent
{
	return [self initWithUserAgent:userAgent withDatabase:[DXDeliciousDatabase defaultDatabase]];
}

-(id)initWithUserAgent:(NSString*)userAgent withDatabase:(DXDeliciousDatabase*)database
{
	self = [super initWithUserAgent:userAgent];
	
	if(self != nil)
	{
		[self setSavedLastUpdatedTime:[NSDate distantPast]];
		self.database = database;
		
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		
		if([defaults objectForKey:kIsUserLoggedInKey] != nil)
			_isUserLoggedIn = [defaults boolForKey:kIsUserLoggedInKey]; // This is the 1.1 and later way to check.
		else
			_isUserLoggedIn = [database isLoggedIn]; // This is the pre-1.1 way to check. Need this for the case that someone is upgrading from 1.0.
	}
	
	return self;
}

-(void)dealloc
{
	[self setSavedLastUpdatedTime:nil];
	self.database = nil;
	[super dealloc];
}

-(void)setSavedLastUpdatedTime:(NSDate*)lastUpdatedTime
{
	if(lastUpdatedTime != _savedLastUpdatedTime)
	{
		[_savedLastUpdatedTime release];
		_savedLastUpdatedTime = [lastUpdatedTime retain];
	}
}

-(void)logout
{
	[self clearSavedCredentials];
	
	[_database updateDatabaseWithDeliciousAPIPosts:nil];
	[_database setUsername:nil];
	[_database setLastUpdated:nil];
	
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:kUserDefault_Password];
	
	self.isUserLoggedIn = NO;
}

-(void)setIsUserLoggedIn:(BOOL)newValue
{
	NSString *key = @"isUserLoggedIn";
	
	[self willChangeValueForKey:key];
	_isUserLoggedIn = newValue;
	[[NSUserDefaults standardUserDefaults] setBool:newValue forKey:kIsUserLoggedInKey];
	[self didChangeValueForKey:key];
}

-(BOOL)isUserLoggedIn
{
	return _isUserLoggedIn;
}

#pragma mark DXDeliciousAPI Overrides


- (void)updateRequest
{
	self.isUpdating = YES;
	[super updateRequest];
}


#pragma mark DXDeliciousAPI Delegate Methods

- (void) deliciousAPIUpdateResponse:(NSDate*)lastUpdatedTime
{
	NSLog(@"deliciousAPIUpdateComplete: %@", lastUpdatedTime);
	
	self.isUserLoggedIn = YES;
	
	NSDate *lastUpdatedPref = [_database lastUpdated];
	
	// if lastUpdatedDate > lastUpdated, then we need to refresh.
	NSLog(@"Last Updated: %@, Last Updated DB: %@", lastUpdatedTime, lastUpdatedPref);
	
	if([lastUpdatedTime compare:lastUpdatedPref] != NSOrderedSame)
	{
		// The database needs to be updated.
		NSLog(@"The del.icio.us database needs to be updated");
		[self setSavedLastUpdatedTime:lastUpdatedTime];
		[[BookmarksDeliciousAPIManager sharedManager] postsAllRequest];
	}
	else
	{
		[[NSNotificationCenter defaultCenter] postNotificationName:kDeliciousLoginCompleteNotification object:self];
		self.isUpdating = NO;
	}
}

- (NSString*)deliciousAPIGetUsername
{	
	NSString *username = [_database username];
	//NSLog(@"deliciousAPIGetUsername - username is '%@'", username);	
	return username;
}

- (NSString*)deliciousAPIGetPassword
{
	NSString *password = [[NSUserDefaults standardUserDefaults] stringForKey:kUserDefault_Password];
	//NSLog(@"deliciousAPIGetPassword - pasword is '%@'", password);
	return password;
}

- (void)deliciousAPIBadCredentials
{
	NSLog(@"deliciousAPIBadCredentials");
	[[NSNotificationCenter defaultCenter] postNotificationName:kDeliciousBadCredentialsNotification object:self];
	self.isUpdating = NO;
}

- (void)showAlertWithTitle:(NSString*)title withMessage:(NSString*)message
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
													message:message
												   delegate:nil
										  cancelButtonTitle:NSLocalizedString(@"OK", @"OK button title.")
										  otherButtonTitles:nil];
	
	[alert show];
	[alert release];
}

- (void)deliciousAPIConnectionFailedWithError:(NSError*)error
{
	NSLog(@"deliciousAPIConnectionFailedWithError: %@", error);
	
	[[NSNotificationCenter defaultCenter] postNotificationName:kDeliciousConnectionFailedNotification
														object:self
													  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:error, kDeliciousConnectionFailedNotification_NSErrorKey, nil]];
	
	self.isUpdating = NO;
}

- (void) deliciousAPIPostAllResponse:(NSArray*)posts
{
	NSLog(@"Got deliciousAPIPostAllResponse");
	[_database updateDatabaseWithDeliciousAPIPosts:posts];
	[_database setLastUpdated:_savedLastUpdatedTime];
	
	if([posts count] == 0)
	{
		[self showAlertWithTitle:NSLocalizedString(@"No Tags", @"No tags alert title")
					 withMessage:NSLocalizedString(@"Your Delicious account has no tags.", @"No tags for this delicious account alert message.")];
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:kDeliciousPostsUpdatedNotification object:self];
	[[NSNotificationCenter defaultCenter] postNotificationName:kDeliciousLoginCompleteNotification object:self];
	
	self.isUpdating = NO;
}

- (void)deliciousAPIURLInfoResponse:(NSDictionary*)urlInfo
{
	[[NSNotificationCenter defaultCenter] postNotificationName:kDeliciousURLInfoResponseNotification
														object:self
													  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:urlInfo, kDeliciousURLInfoResponse_URLInfoKey, nil]];
}

- (void)deliciousAPIPostAddResponse:(BOOL)didSucceed withPost:(NSDictionary*)postDictionary
{	
	[_database updateDatabaseWithPost:postDictionary];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:kDeliciousPostAddResponseNotification
														object:self
													  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
																[NSNumber numberWithBool:didSucceed], kDeliciousPostAddResponse_DidSucceedKey,
																postDictionary, kDeliciousPostAddResponse_PostDictionaryKey,
																nil]];
}

- (void)postDeleteRequest:(NSString*)url
{
	self.isUpdating = YES;
	[super postDeleteRequest:url];
}

- (void)deliciousAPIPostDeleteResponse:(BOOL)didSucceed withRemovedURL:(NSString*)removedURL
{
	//NSLog(@"deliciousAPIPostDeleteResponse: didSucceed = %d, %@", didSucceed, removedURL);
	
	if(didSucceed)
		[_database removePost:removedURL];
	
	self.isUpdating = NO;
}

@end
