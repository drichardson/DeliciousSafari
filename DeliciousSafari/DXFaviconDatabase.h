//
//  DXFaviconDatabase.h
//  DeliciousSafari
//
//  Created by Doug on 8/17/08.
//  Copyright 2008 Douglas Richardson. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DXFaviconDatabase : NSObject
{
	NSString *mBaseDirectory;
}

+(DXFaviconDatabase*)defaultDatabase;

-(id)initWithBaseDirectoryPath:(NSString*)path;
-(void)addFavicon:(NSData*)faviconData forURLString:(NSString*)key;
-(NSImage*)faviconForURLString:(NSString*)urlString;
-(BOOL)faviconExistsForURLString:(NSString*)urlString; // A more efficient check than faviconForURLString:

@end
