//
//  DXFaviconDatabase.m
//  DeliciousSafari
//
//  Created by Doug on 8/17/08.
//  Copyright 2008 Douglas Richardson. All rights reserved.
//

#import "DXFaviconDatabase.h"
#include <CommonCrypto/CommonDigest.h>

static NSString* SHA1FilenameFromKey(NSString *url);

@interface DXFaviconDatabase (private)
-(NSString*)filenameFromURLString:(NSString*)url;
@end

@implementation DXFaviconDatabase

+(DXFaviconDatabase*)defaultDatabase
{
	static DXFaviconDatabase *database;
	
	if(database == NULL)
	{
		NSString *dsAppDirPath = [@"~/Library/Application Support/DeliciousSafari" stringByExpandingTildeInPath];
		
		// Create the DeliciousSafari directory, if needed.
		NSFileManager *fm = [NSFileManager defaultManager];
		BOOL isDirectory = NO;
		
		if([fm fileExistsAtPath:dsAppDirPath isDirectory:&isDirectory])
		{
			if(!isDirectory)
				NSLog(@"Favicon database directory path (%@) exists but is not a directory.", dsAppDirPath);
		}
		else
		{
			if(![fm createDirectoryAtPath:dsAppDirPath attributes:nil])
				NSLog(@"Could not create DeliciousSafari application support database directory at path (%@).", dsAppDirPath);
		}
		
		NSString *faviconDatabasePath = [dsAppDirPath stringByAppendingPathComponent:@"Favicon Database"];
		database = [[DXFaviconDatabase alloc] initWithBaseDirectoryPath:faviconDatabasePath];
	}
	
	return database;
}

-(id)initWithBaseDirectoryPath:(NSString*)path
{
	self = [super init];
	
	if(self)
	{
		mBaseDirectory = [path retain];
		
		NSFileManager *fm = [NSFileManager defaultManager];
		BOOL isDirectory = NO;
		
		if([fm fileExistsAtPath:path isDirectory:&isDirectory])
		{
			if(!isDirectory)
			{
				NSLog(@"Favicon database directory path (%@) exists but is not a directory.", path);
				goto bail;
			}
		}
		else
		{
			if(![fm createDirectoryAtPath:path attributes:nil])
			{
				NSLog(@"Could not create favicon database directory at path (%@).", path);
				goto bail;
			}
		}
	}

	return self;
	
bail:
	[self release];
	return nil;
}

-(void)dealloc
{
	[mBaseDirectory release];
	[super dealloc];
}

-(void)addFavicon:(NSData*)faviconData forURLString:(NSString*)url
{
	if(faviconData == nil || url == nil)
	{
		NSLog(@"[DXFaviconDatabase addFavicon:forKey:] - faviconData %p or key %p is nil.", faviconData, url);
		return;
	}
	
	NSString *filename = [self filenameFromURLString:url];
	filename = [mBaseDirectory stringByAppendingPathComponent:filename];
	
	if(![faviconData writeToFile:filename atomically:YES])
		NSLog(@"Error saving favicon to file %@", filename);
	
}

-(NSImage*)faviconForURLString:(NSString*)urlString
{
	if(urlString == nil)
	{
		NSLog(@"[DXFaviconDatabase faviconForURLString:] - urlString is nil.");
		return nil;
	}
	
	NSString *filename = [self filenameFromURLString:urlString];
	filename = [mBaseDirectory stringByAppendingPathComponent:filename];
	
	return [[[NSImage alloc] initWithContentsOfFile:filename] autorelease];
}

-(NSString*)filenameFromURLString:(NSString*)stringURL
{
	NSURL *url = [NSURL URLWithString:stringURL];
	
	if(url == nil)
		return nil;
	
	return SHA1FilenameFromKey([url host]);
}

-(BOOL)faviconExistsForURLString:(NSString*)urlString
{
	NSString *filename = [self filenameFromURLString:urlString];
	return filename && [[NSFileManager defaultManager] fileExistsAtPath:filename];
}

@end

static NSString* SHA1FilenameFromKey(NSString *url)
{
	unsigned char md[CC_SHA1_DIGEST_LENGTH];
	CC_SHA1_CTX ctx;
	
	CC_SHA1_Init(&ctx);
	CC_SHA1_Update(&ctx, [url UTF8String], [url lengthOfBytesUsingEncoding:NSUTF8StringEncoding]);
	CC_SHA1_Final(md, &ctx);
	
	return [NSString stringWithFormat:@"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
			md[0], md[1], md[2], md[3], md[4], md[5], md[6], md[7], md[8], md[9],
			md[10], md[11], md[12], md[13], md[14], md[15], md[16], md[17], md[18], md[19]];
}
