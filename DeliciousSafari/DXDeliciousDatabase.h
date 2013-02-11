//
//  DeliciousDatabase.h
//  Safari Delicious Extension
//
//  Created by Douglas Richardson on 8/5/07.
//  Copyright 2007 Douglas Richardson. All rights reserved.
//

#ifdef DELICIOUSSAFARI_IPHONE_TARGET
#import <Foundation/Foundation.h>
#else
#import <Cocoa/Cocoa.h>
#endif

#import "DXDeliciousAPI.h"
#import "FoundationDataObjects.h"

#ifdef DELICIOUSSAFARI_PLUGIN_TARGET
@protocol DXDeliciousDatabaseFaviconCallback <NSObject>
-(void) dxDeliciousDatabaseFaviconCallback:(BOOL)somethingChanged;
@end
#endif

@interface DXDeliciousDatabase : NSObject {
	// Preferences database uses a plist.
	NSString *mDBPath;
	NSMutableDictionary *mDBCache;
	
	// Delicious local database uses a SQLite database.
	id <FDOConnection> mDBConnection;
}

+ (DXDeliciousDatabase*)defaultDatabase;

- (id)initWithDatabasePath:(NSString*)databasePath withSQLiteDatabasePath:(NSString*)sqliteDBPath;

-(NSArray*)tags;
-(NSArray*)postsForTagArray:(NSArray*)tagArray;
-(NSArray*)postsForTagArrayOrderedByTitle:(NSArray*)tagArray;
-(NSDictionary*)postForURL:(NSString*)URL;

-(NSDate*)lastUpdated;
-(void)setLastUpdated:(NSDate*)time;

- (void)updateDatabaseWithDeliciousAPIPosts:(NSArray*)posts;
- (void)updateDatabaseWithPost:(NSDictionary*)post;

- (void)removePost:(NSString*)url;

-(NSArray*)favoriteTags;
-(void)setFavoriteTags:(NSArray*)tags;

-(NSArray*)recentPosts:(unsigned int)count;

-(NSString*)username;
-(void)setUsername:(NSString*)username;

-(BOOL)isLoggedIn;

#ifdef DELICIOUSSAFARI_PLUGIN_TARGET
-(void)startFaviconUpdateThread:(NSObject <DXDeliciousDatabaseFaviconCallback>*)callbackObject;
#endif

-(BOOL)hasAddedToolbarItemIdentifier:(NSString*)itemIdentifier;
-(void)setHasAddedToolbarItemIdentifier:(NSString*)itemIdentifier;

-(BOOL)shouldShareDefaultValue;

-(void)removePerUserData;
-(void)cleanupObsoleteDatabaseFields;

-(BOOL)shouldFetchBookmarksManually;
-(void)setShouldFetchBookmarksManually:(BOOL)shouldFetchManually;

#ifdef DELICIOUSSAFARI_PLUGIN_TARGET
-(int)databaseVersion;
-(void)setDatabaseVersion:(int)newVersion;
#endif

// Generic storage for DeliciousSafari preferences. Bookmarks can just use NSUserDefaults.
-(BOOL)boolForKey:(NSString*)key withDefaultValue:(BOOL)defaultValue;
-(BOOL)boolForKey:(NSString*)key;
-(void)setBool:(BOOL)value forKey:(NSString*)key;

-(int)intForKey:(NSString*)key withDefaultValue:(int)defaultValue;
-(int)intForKey:(NSString*)key;
-(void)setInt:(int)value forKey:(NSString*)key;

-(double)doubleForKey:(NSString*)key withDefaultValue:(double)defaultValue;
-(void)setDouble:(double)value forKey:(NSString*)key;

// Search methods
-(NSArray*)findTagsBeginningWith:(NSString*)searchString withResultLimit:(NSUInteger)limit;
-(NSArray*)findBookmarksWithTitlesContaining:(NSString*)searchString withResultLimit:(NSUInteger)limit;

@end
