//
//  DeliciousDatabase.m
//  Safari Delicious Extension
//
//  Created by Douglas Richardson on 8/5/07.
//  Copyright 2007 Douglas Richardson. All rights reserved.
//

#import "DXDeliciousDatabase.h"
#import "DXUtilities.h"

#ifdef DELICIOUSSAFARI_PLUGIN_TARGET
#import <ApplicationServices/ApplicationServices.h>
#import <CoreServices/CoreServices.h>
#import "DXFaviconDownloader.h"
#endif

#define kCurrentSchemaVersionInt 1
#define kCurrentSchemaVersionStr @"1"

static NSString* const kPostsKeyOBSOLETE = @"posts";
static NSString* const kTagsKeyOBSOLETE = @"tags";
static NSString* const kLastUpdatedKey = @"lastUpdated";
static NSString* const kFavoriteTagsKey = @"favoriteTags";
static NSString* const kUsernameKey = @"username";
static NSString* const kFaviconDatabaseNextRebuildKey = @"FaviconDatabaseNextRebuildDate";
static NSString* const kFaviconHostSkipKey = @"FaviconHostSkipListKey";
static NSString* const kShouldShareByDefaultKey = @"ShouldShareByDefault";
static NSString* const kShouldFetchManually = @"ShouldFetchBookmarksManually";

static NSString* const kDatabaseVersionKey = @"DatabaseVersion";

@interface DXDeliciousDatabase (Private)
-(NSMutableDictionary*)readDatabaseFile;
-(void)saveDatabaseFile:(NSDictionary*)database;
-(void)saveDatabaseFile:(NSDictionary*)database shouldResetCache:(BOOL)shouldResetCache;

#ifdef DELICIOUSSAFARI_PLUGIN_TARGET
-(void)faviconUpdateThread:(id)callbackObject;
-(void)faviconDatabaseUpdatedMainThreadCallback:(NSDictionary*)callbackArgs;
#endif

-(NSString*)stringForKey:(NSString*)key;
-(void)setString:(NSString*)value forKey:(NSString*)key;

-(NSDate*)dateForKey:(NSString*)key;
-(void)setDate:(NSDate*)value forKey:(NSString*)key;

-(NSString*)itemIdentifierKeyFromItemIdentifier:(NSString*)itemIdentifier;

-(BOOL)checkDatabaseIsUpToDate;
-(BOOL)rebuildDatabase;

-(NSMutableDictionary*)postDictionaryFromCurrentRecordSet:(id <FDORecordSet>)recordSet;
-(NSArray*)postsArrayForRecordSet:(id <FDORecordSet>)recordSet;
-(NSArray*)postsForTagArray:(NSArray*)tagArray orderBy:(NSString*)orderByClause;

- (BOOL)addPostsToDatabaseInternal:(NSArray*)posts isDatabaseEmpty:(BOOL)isDatabaseEmpty;
- (void)removePostInternal:(NSString*)urlToRemove useTransactions:(BOOL)useTransactions;

@end

@implementation DXDeliciousDatabase

static DXDeliciousDatabase *_defaultDatabase;

+ (void)initialize
{
	//NSLog(@"Initialize of database");
	static BOOL initialized = NO;
	if(!initialized)
	{
		initialized = YES;
		
#ifdef DELICIOUSSAFARI_IPHONE_TARGET
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES); 
		NSString *documentsDirectory = [paths objectAtIndex:0];
		
		if(documentsDirectory != nil)
		{
			NSString *databaseFilename = [documentsDirectory stringByAppendingPathComponent:@"database.plist"];
			NSString *sqliteDatabasePath = [documentsDirectory stringByAppendingPathComponent:@"database.sqlite3"];
			_defaultDatabase = [[DXDeliciousDatabase alloc] initWithDatabasePath:databaseFilename withSQLiteDatabasePath:sqliteDatabasePath];
		}
		else
			NSLog(@"Error getting documents directory. Default delicious database cannot be created.");		
#else
		NSString *dbPath = [@"~/Library/Preferences/com.delicioussafari.DeliciousSafari.plist" stringByExpandingTildeInPath];
		
		NSString *appSupportPath = [[DXUtilities defaultUtilities] applicationSupportPath];
		//NSLog(@"Using appSupportPath db path of %@", appSupportPath);
		NSString *sqliteDBPath = [appSupportPath stringByAppendingPathComponent:@"database.sqlite"];
		
		//NSLog(@"Using sqlite db path of %@", sqliteDBPath);
		
		_defaultDatabase = [[DXDeliciousDatabase alloc] initWithDatabasePath:dbPath withSQLiteDatabasePath:sqliteDBPath];
#endif
		
	}
}

+ (DXDeliciousDatabase*)defaultDatabase
{
	//NSLog(@"Returning default database of %p", _defaultDatabase);
	return _defaultDatabase;
}

- (id)initWithDatabasePath:(NSString*)dbpath withSQLiteDatabasePath:(NSString*)sqliteDBPath
{
	if([super init])
	{
		mDBPath = [[dbpath stringByExpandingTildeInPath] retain];
		
		@try {
			//NSLog(@"[DXDeliciousDatabase initWithDatabasePath:withSQLiteDatabasePath:] - Opening database at '%@'", sqliteDBPath);
			mDBConnection = FDOCreateSQLiteConnection(sqliteDBPath);
		}
		@catch (NSException * e) {
			NSLog(@"[DXDeliciousDatabase initWithDatabasePath:] Error creating database. %@", e);
			[self release];
			return nil;
		}
				
		if(![self checkDatabaseIsUpToDate])
		{
			NSLog(@"Database is not up to date. Rebuilding.");
			
			if(![self rebuildDatabase])
			{
				NSLog(@"Error building database. Cannot continue.");
				[self release];
				return nil;
			}
		}
		else
		{
			// NSLog(@"Database is up to date.");
		}
	}
	
	return self;
}

- (void)dealloc
{	
	[mDBPath release];
	[mDBCache release];
	[mDBConnection release];
	
	[super dealloc];
}

-(BOOL)checkDatabaseIsUpToDate
{
	BOOL isUpToDate = NO;
	
	@try {
		id <FDORecordSet> recordSet = [mDBConnection execute:@"SELECT version FROM schema"];
		if(recordSet != nil && ![recordSet isEOF] && [recordSet intValueForColumnNamed:@"version"] == kCurrentSchemaVersionInt)
			isUpToDate = YES;
	}
	@catch (NSException * e) {
		NSLog(@"checkDatabaseIsUpToDate caught exception: %@", e);
	}
	
	return isUpToDate;
};

-(void)dropAllTables
{
	NSString *tables[] = { @"bookmark", @"tag", @"bookmark_tag", @"schema" };
	int count = sizeof(tables)/sizeof(tables[0]);
	int i;
	
	for(i = 0; i < count; ++i)
	{
		@try {
			[mDBConnection execute:[NSString stringWithFormat:@"DROP TABLE IF EXISTS %@", tables[i]]];
		}
		@catch (NSException * e) {
			NSLog(@"Error dropping %@ table. %@", tables[i], e);
		}
	}
}

-(BOOL)createAllTables
{
	BOOL succeeded = NO;
	
	NSString* createStatments[] = {
		@"CREATE TABLE bookmark ( \
			id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, \
			url TEXT NOT NULL UNIQUE, \
			title TEXT NOT NULL, \
			notes TEXT NULL, \
			isShared BOOLEAN NOT NULL, \
			timeSaved TIMESTAMP NOT NULL \
		);",
		
		// name_lower is used to perform a case insensitive sort in any language
		// name_display is used to store the name as the user intended
		@"CREATE TABLE tag ( \
			id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, \
			name_lower TEXT NOT NULL UNIQUE, \
			name_display TEXT NOT NULL \
		);",
		
		
		@"CREATE TABLE bookmark_tag( \
			bookmark_id INTEGER NOT NULL REFERENCES bookmark (id), \
			tag_id INTEGER NOT NULL REFERENCES tag (id) \
		);",
		
		@"CREATE INDEX bookmark_tag_bookmark_id ON bookmark_tag (bookmark_id);",
		@"CREATE INDEX bookmark_tag_tag_id ON bookmark_tag (tag_id);",
		
		
		@"CREATE TABLE schema ( \
			version INTEGER NOT NULL \
		);",
		
		@"INSERT INTO schema (version) values (" kCurrentSchemaVersionStr @");"
	};
	
	@try {
		size_t count = sizeof(createStatments)/sizeof(createStatments[0]);
		for(size_t i = 0; i < count; ++i) {
			[mDBConnection execute:createStatments[i]];
		}
		succeeded = YES;
	}
	@catch (NSException * e) {
		NSLog(@"Error creating database item. %@", e);
	}
	
	return succeeded;
}

-(BOOL)rebuildDatabase
{
	[self dropAllTables];
	return [self createAllTables];
}

-(NSArray*)tags
{
	// TODO: It would be less memory intensive if we didn't pre-build the entire array. Instead, we should execute the SQL and then allow
	// access via a forward only enumerator. This should really return something similar to a ADO recordset, rather than an array.
	// However, for now I'm just going to return an array to make sure I don't break compatibility while converting to SQLite from plists.
	
	NSMutableArray *result = [NSMutableArray array];
	
	@try {
		id <FDORecordSet> recordSet = [mDBConnection execute:@"SELECT name_display FROM tag ORDER BY name_lower"];
		
		if(recordSet)
		{
			for(; ![recordSet isEOF]; [recordSet moveNext])
				[result addObject:[recordSet stringValueForColumnNumber:0]];
		}
	}
	@catch (NSException * e) {
		NSLog(@"Error reading tag list from database. %@", e);
	}
	
	return result;
}

-(NSMutableDictionary*)postDictionaryFromCurrentRecordSet:(id <FDORecordSet>)recordSet
{
	NSString *url = [recordSet stringValueForColumnNamed:@"url"];
	NSString *title = [recordSet stringValueForColumnNamed:@"title"];
	NSString *notes = [recordSet stringValueForColumnNamed:@"notes"];
	NSNumber *isShared = [NSNumber numberWithBool:[recordSet intValueForColumnNamed:@"isShared"]];
	NSDate *timeSaved = [recordSet dateValueForColumnNamed:@"timeSaved"];
	
	if(url == nil)
		url = @"";
	
	if(title == nil)
		title = @"";
	
	if(notes == nil)
		notes = @"";
	
	if(timeSaved == nil)
		timeSaved = [NSDate date];
	
	return [NSMutableDictionary dictionaryWithObjectsAndKeys:
			url, kDXPostURLKey,
			title, kDXPostDescriptionKey,
			notes, kDXPostExtendedKey,
			timeSaved, kDXPostTimeKey,
			isShared, kDXPostShouldShare,
			nil];
}

-(NSArray*)postsArrayForRecordSet:(id <FDORecordSet>)recordSet
{
	NSMutableArray *result = [NSMutableArray array];
	
	if(recordSet)
	{
		for(; ![recordSet isEOF]; [recordSet moveNext])
		{
			NSDictionary *post = [self postDictionaryFromCurrentRecordSet:recordSet];
			[result addObject:post];
		}
	}
	
	return result;
}

-(NSArray*)postsForTagArray:(NSArray*)tagArray orderBy:(NSString*)orderByClause
{
	NSString *sqlFragmentFormatString = @"SELECT * FROM bookmark WHERE bookmark.id IN (SELECT bookmark_id FROM bookmark_tag, tag WHERE bookmark_tag.tag_id = tag.id and tag.name_lower = ?%d)";
	NSMutableArray *sqlFragmentArray = [NSMutableArray array];
	int count = [tagArray count];
	for(int i = 1; i <= count; ++i)
		[sqlFragmentArray addObject:[NSString stringWithFormat:sqlFragmentFormatString, i]];
	
	NSString *intersectedSQL = [sqlFragmentArray componentsJoinedByString:@" INTERSECT "];
	
	NSString *completeSQL;
	
	if(orderByClause)
	{
		completeSQL = [intersectedSQL stringByAppendingString:[@" " stringByAppendingString:orderByClause]];
	}
	else
	{
		completeSQL = intersectedSQL;
	}

	
	NSArray *result = nil;
	
	@try {
		id <FDOCommand> command = [mDBConnection newCommand];
		[command prepare:completeSQL];
		
		for(int i = 0; i < count; ++i)
			[command bindString:[tagArray objectAtIndex:i] toParameterNumber:i+1];
		
		id <FDORecordSet> recordSet = [command executeQuery];
		result = [self postsArrayForRecordSet:recordSet];
	}
	@catch (NSException * e) {
		NSLog(@"[DXDelicoiusDatabase postsForTagArrary:] Error getting posts. %@", e);
	}
	
	if(result == nil)
		result = [NSArray array];
	
	return result;	
}

-(NSArray*)postsForTagArray:(NSArray*)tagArray
{
	return [self postsForTagArray:tagArray orderBy:@"ORDER BY timeSaved DESC"];
}

-(NSArray*)postsForTagArrayOrderedByTitle:(NSArray*)tagArray
{
	return [self postsForTagArray:tagArray orderBy:@"ORDER BY lower(title) ASC"];
}

-(NSDictionary*)postForURL:(NSString*)URL
{
	NSMutableDictionary *result = nil;
	
	@try {
		id <FDOCommand> command = [mDBConnection newCommand];
		[command prepare:@"SELECT * FROM bookmark WHERE url = ?1"];
		[command bindString:URL toParameterNumber:1];
		id <FDORecordSet> recordSet = [command executeQuery];
		
		if(recordSet && ![recordSet isEOF])
		{
			FDORowID bookmark_id = [recordSet int64ValueForColumnNamed:@"id"];
			if(bookmark_id == 0)
				NSLog(@"[DXDeliciousDatabase postForURL:] Got bookmark_id of 0. Probably shouldn't have got that.");
			
			id <FDOCommand> tagCommand = [mDBConnection newCommand];
			[tagCommand prepare:@"SELECT name_display FROM tag WHERE id IN (SELECT tag_id FROM bookmark_tag WHERE bookmark_id = ?1)"];
			[tagCommand bindInt64:bookmark_id toParameterNumber:1];
			
			id <FDORecordSet> tagsRS = [tagCommand executeQuery];
			NSMutableArray *tags = [NSMutableArray array];
			if(tagsRS != nil)
			{
				for(; ![tagsRS isEOF]; [tagsRS moveNext])
				{
					NSString *tag_name = [tagsRS stringValueForColumnNumber:0];
					if(tag_name)
						[tags addObject:tag_name];
				}
			}
			
			//NSLog(@"Built tag array is %@", tags);
			
			result = [self postDictionaryFromCurrentRecordSet:recordSet];
			[result setValue:tags forKey:kDXPostTagArrayKey];
		}
	}
	@catch (NSException * e) {
		NSLog(@"[DXDeliciousDatabase postForURL:] Error executing lookup. %@", e);
	}
	
	return result;
}

-(NSDate*)lastUpdated
{
	NSDictionary *db = [self readDatabaseFile];
	NSDate *date = [db objectForKey:kLastUpdatedKey];
	return date != nil && [date isKindOfClass:[NSDate class]] ? date : [NSDate distantPast];
}

-(void)setLastUpdated:(NSDate*)time
{
	NSMutableDictionary *db = [self readDatabaseFile];
	
	if(time == nil)
		[db removeObjectForKey:kLastUpdatedKey];
	else
		[db setObject:time forKey:kLastUpdatedKey];
	
	[self saveDatabaseFile:db];
}

- (void)updateDatabaseWithPost:(NSDictionary*)newPost
{
	NSString *url = [newPost objectForKey:kDXPostURLKey];
	BOOL inTransaction = NO;
	
	if(url == nil)
	{
		NSLog(@"[DXDeliciousDatabase updateDatabaseWithPost:] Bad argument - unexpected nil url for kDXPostURLKey");
		goto bail;
	}
	
	@try {
		
		[mDBConnection beginTransaction];
		inTransaction = YES;
	}
	@catch (NSException * e) {
		NSLog(@"[DXDeliciousDatabase updateDatabaseWithPost:] - Error executing database delete bookmark commands. %@", e);
		goto bail;
	}
	
	[self removePostInternal:url useTransactions:NO];
	
	if(![self addPostsToDatabaseInternal:[NSArray arrayWithObject:newPost] isDatabaseEmpty:NO])
	{
		NSLog(@"[DXDeliciousDatabase updateDatabaseWithPost:] - addPostsToDatabaseInternal failed.");
		goto bail;
	}
	
	if(inTransaction)
	{
		@try {
			[mDBConnection commitTransaction];
			inTransaction = NO;
		}
		@catch (NSException * e) {
			NSLog(@"[DXDeliciousDatabase updateDatabaseWithPost:] - Error committing transaction. %@", e);
		}
	}
	
	
bail:
	if(inTransaction)
	{
		@try {
			[mDBConnection rollbackTransaction];
		}
		@catch (NSException * e) {
			NSLog(@"[DXDeliciousDatabase updateDatabaseWithPost:] - Error rolling back transaction. %@", e);
		}
	}	
}

- (BOOL)cleanDeliciousTables
{
	BOOL succeeded = NO;
	
	NSString *cleanStatements[] = {
		@"DELETE FROM bookmark;",
		@"DELETE FROM tag;",
		@"DELETE FROM bookmark_tag;"
	};
	
	@try {
		for(size_t i = 0; i < sizeof(cleanStatements)/sizeof(cleanStatements[0]); ++i)
			[mDBConnection execute:cleanStatements[i]];
		succeeded = YES;
	}
	@catch (NSException * e) {
		NSLog(@"cleanDeliciousTables failed to delete from a table. %@", e);
	}
	
	return succeeded;
}

- (BOOL)addPostsToDatabaseInternal:(NSArray*)posts isDatabaseEmpty:(BOOL)isDatabaseEmpty
{
	BOOL result = NO;
	
	if(posts == nil)
		posts = [NSArray array];
	
	id <FDOCommand> insertBookmarkStatement = nil;
	id <FDOCommand> insertTagStatement = nil;
	id <FDOCommand> insertBookmarksTagStatement = nil;
	
	// Prepare the statements
	@try {
		NSString *insertBookmarkSQL = @"INSERT INTO bookmark (url, title, notes, isShared, timeSaved) VALUES (?1, ?2, ?3, ?4, ?5)";	
		insertBookmarkStatement = [mDBConnection newCommand];
		[insertBookmarkStatement prepare:insertBookmarkSQL];
	}
	@catch (NSException *e) {
		NSLog(@"[DXDeliciousDatabase addPostsToDatabaseInternal:] Error preparing insert bookmark statement. %@", e);
		goto bail;
	}
	
	@try
	{
		NSString *insertTagSQL = @"INSERT INTO tag (name_lower, name_display) VALUES (LOWER(?1), ?1)";
		insertTagStatement = [mDBConnection newCommand];
		[insertTagStatement prepare:insertTagSQL];
	}
	@catch(NSException *e)
	{
		NSLog(@"[DXDeliciousDatabase addPostsToDatabaseInternal:] Error preparing insert tag statement. %@", e);
		goto bail;
	}
	
	@try
	{
		NSString *insertBookmarksTagSQL = @"INSERT INTO bookmark_tag (bookmark_id, tag_id) VALUES (?1, ?2)";
		insertBookmarksTagStatement = [mDBConnection newCommand];
		[insertBookmarksTagStatement prepare:insertBookmarksTagSQL];
	}
	@catch(NSException *e)
	{
		NSLog(@"[DXDeliciousDatabase addPostsToDatabaseInternal:] Error preparing insert bookmarks tag statement. %@", e);
		goto bail;
	}
	
	
	// If the database is not empty, then a list of the current tags and their IDs is needed since we will not insert those values.
	NSMutableDictionary *tagNameToIDMap = nil;
	if(!isDatabaseEmpty)
	{
		tagNameToIDMap = [NSMutableDictionary dictionary];
		
		@try {
			id <FDOCommand> cmd = [mDBConnection newCommand];
			[cmd prepare:@"SELECT id FROM tag WHERE name_lower = lower(?1)"];
			
			NSEnumerator *postEnum =  [posts objectEnumerator];
			NSDictionary *post;
			while((post = [postEnum nextObject]) != nil)
			{
				NSEnumerator *tagEnum = [[post objectForKey:kDXPostTagArrayKey] objectEnumerator];
				NSString *tag;
				while((tag = [tagEnum nextObject]) != nil)
				{
					[cmd bindString:tag toParameterNumber:1];
					id <FDORecordSet> recordSet = [cmd executeQuery];
					
					if(recordSet != nil && ![recordSet isEOF])
					{
						NSNumber *tag_id = [NSNumber numberWithLongLong:[recordSet int64ValueForColumnNumber:0]];
						
						NSString *tagLower = [tag lowercaseString];
						if(tagLower)
							[tagNameToIDMap setValue:tag_id forKey:tagLower];
						else
							NSLog(@"[DXDeliciousDatabase addPostsToDatabaseInternal:] - BUG: Could not lowercase tag '%@'. Skipping.", tag);
					}
				}
			}
			
		}
		@catch (NSException * e) {
			NSLog(@"[DXDeliciousDatabase addPostsToDatabaseInternal:] - Couldn't get current tags. %@", e);
		}			
	}
	
	//NSLog(@"The tag to id table is %@", tagNameToIDMap);
	
	NSMutableDictionary* tagsDict = [NSMutableDictionary dictionary];
	
	NSEnumerator *postsEnum = [posts objectEnumerator];
	NSDictionary *post;
	while((post = [postsEnum nextObject]) != nil)
	{
		// Insert the bookmark
		NSString *url = [post objectForKey:kDXPostURLKey];
		NSString *title = [post objectForKey:kDXPostDescriptionKey];
		NSString *notes = [post objectForKey:kDXPostExtendedKey];
		NSNumber *isShared = [post objectForKey:kDXPostShouldShare];
		NSDate *timeSaved = [post objectForKey:kDXPostTimeKey];
		
		if(url == nil || title == nil)
		{
			NSLog(@"[DXDeliciousDatabase addPostsToDatabaseInternal:] URL or title is nil. Skipping entry.");
			continue;
		}
		
		if(notes == nil)
			notes = @"";
		
		if(isShared == nil)
			isShared = [NSNumber numberWithBool:YES];
		
		if(timeSaved == nil)
			timeSaved = [NSDate date];
		
		FDORowID bookmark_id;
		
		@try
		{
			[insertBookmarkStatement bindString:url toParameterNumber:1];
			[insertBookmarkStatement bindString:title toParameterNumber:2];
			[insertBookmarkStatement bindString:notes toParameterNumber:3];
			[insertBookmarkStatement bindInt:[isShared boolValue] toParameterNumber:4];
			[insertBookmarkStatement bindDate:timeSaved toParameterNumber:5];
			[insertBookmarkStatement executeQuery];
			
			bookmark_id = [mDBConnection lastInsertRowID];
		}
		@catch(NSException *e)
		{
            // I've seen some failures here when delicious gives me two bookmarks with the same URL.
            // delicious.com doesn't let you create 2 links with the same URL, so I'm not sure
            // how this happened. See the cocos2d bookmark under mofochickamo's account to see what I mean.
			NSLog(@"[DXDeliciousDatabase addPostsToDatabaseInternal:] - Insert bookmark failed %@", e);
			continue;
		}
		
		
		NSNumber *bookmarkIDNumber = [NSNumber numberWithLongLong:bookmark_id];
		
		// Add the bookmark's tags to tagsDict
		NSEnumerator *tagsEnum = [[post objectForKey:kDXPostTagArrayKey] objectEnumerator];
		NSString *tag = nil;
		while(tag = [tagsEnum nextObject])
		{
			tag = [tag lowercaseString];
			// TODO: This should be a case insensitive mutable set, just in case different bookmarks have tags with different cases.
			NSMutableSet *bookmarkIDsForTag = [tagsDict objectForKey:tag];
			
			if(bookmarkIDsForTag == nil)
			{
				bookmarkIDsForTag = [NSMutableSet set];
				[tagsDict setObject:bookmarkIDsForTag forKey:tag];
			}
			
			[bookmarkIDsForTag addObject:bookmarkIDNumber];
		}
	}
	
	// Insert the tags
	NSEnumerator *tagEnum = [tagsDict keyEnumerator];
	NSString *tag;
	while((tag = [tagEnum nextObject]) != nil)
	{
		NSMutableSet *bookmarkIDsForTag = [tagsDict objectForKey:tag];
		if(bookmarkIDsForTag == nil)
		{
			NSLog(@"[DXDeliciousDatabase addPostsToDatabaseInternal:] - Got unexpected nil bookmarkIDsForTag");
			continue;
		}
		
		// Insert the tag.
		FDORowID tag_id;
		
		@try
		{
			NSNumber *tagId = nil;
			
			if(!isDatabaseEmpty)
			{
				NSString *tagLower = [tag lowercaseString];
				if(tagLower)
					tagId = [tagNameToIDMap objectForKey:tagLower];
				else
					NSLog(@"[DXDeliciousDatabase addPostsToDatabaseInternal:] - BUG: Could not lowercase: %@", tag);

			}
			
			if(tagId != nil)
				tag_id = [tagId longLongValue];
			else
			{
				[insertTagStatement bindString:tag toParameterNumber:1];
				[insertTagStatement executeQuery];
				tag_id = [mDBConnection lastInsertRowID];
			}
		}
		@catch(NSException *e)
		{
			NSLog(@"[DXDeliciousDatabase addPostsToDatabaseInternal:] - Error inserting %@ tag. %@", tag, e);
			continue;
		}
		
		// Insert the bookmark IDs for the tag.
		NSEnumerator *bookmarksIDEnum = [bookmarkIDsForTag objectEnumerator];
		NSNumber *bookmarkID;
		while((bookmarkID = [bookmarksIDEnum nextObject]) != nil)
		{
			FDORowID bookmark_id = [bookmarkID longLongValue];
			
			@try
			{
				[insertBookmarksTagStatement bindInt64:bookmark_id toParameterNumber:1];
				[insertBookmarksTagStatement bindInt64:tag_id toParameterNumber:2];
				[insertBookmarksTagStatement executeQuery];
			}
			@catch(NSException *e)
			{
				NSLog(@"[DXDeliciousDatabase addPostsToDatabaseInternal:] - Error executing bookmarks tag statment. %@", e);
				continue;
			}
		}
	}
	
	result = YES;
	
bail:
	
	return result;
}

- (void)updateDatabaseWithDeliciousAPIPosts:(NSArray*)posts
{
	BOOL inTransaction = NO;
	
	@try {
		[mDBConnection beginTransaction];	
		inTransaction = YES;
	} @catch(NSException *e) {
		NSLog(@"[DXDelicousDatabase updateDatabaseWithDeliciousAPIPosts:] Could not start transaction. %@", e);
		goto bail;
	}
	
	// Reset the database.
	if(![self cleanDeliciousTables])
		goto bail;
	
	if(![self addPostsToDatabaseInternal:posts isDatabaseEmpty:YES])
	{
		NSLog(@"[DXDeliciousDatabase updateDatabaseWithDeliciousAPIPosts:] - addPostsToDatabaseInternal failed.");
		goto bail;
	}
	
	@try {
		[mDBConnection commitTransaction];	
		inTransaction = NO;
	} @catch(NSException *e) {
		NSLog(@"[DXDelicousDatabase updateDatabaseWithDeliciousAPIPosts:] Could not commit transaction. %@", e);
	}
	
bail:
	
	if(inTransaction)
	{
		@try {
			[mDBConnection rollbackTransaction];	
		} @catch(NSException *e) {
			NSLog(@"[DXDelicousDatabase updateDatabaseWithDeliciousAPIPosts:] Could not rollback transaction. %@", e);
		}
	}
}

- (void)removePost:(NSString*)urlToRemove
{
	[self removePostInternal:urlToRemove useTransactions:YES];
}

- (void)removePostInternal:(NSString*)urlToRemove useTransactions:(BOOL)useTransactions
{
	BOOL inTransaction = NO;
	
	if(useTransactions)
	{
		@try {
			[mDBConnection beginTransaction];
			inTransaction = YES;
		} @catch(NSException *e) {
			NSLog(@"removePostInternal: Could not begin a transaction. %@", e);
			goto bail;
		}
	}
	
	int64_t bookmark_id;

	@try {
		id <FDOCommand> selectBookmarkIDStatement = [mDBConnection newCommand];
		[selectBookmarkIDStatement prepare:@"SELECT id FROM bookmark WHERE url = ?1"];
		[selectBookmarkIDStatement bindString:urlToRemove toParameterNumber:1];
		id <FDORecordSet> recordSet = [selectBookmarkIDStatement executeQuery];
		
		if(recordSet == nil || [recordSet isEOF]) // There is no post to remove.
			goto bail;
		
		bookmark_id = [recordSet int64ValueForColumnNumber:0];
	} @catch(NSException *e) {
		NSLog(@"removePostInternal: Error selecting bookmark id to delete (%@)", e);
		goto bail;
	}

	// Remove bookmark from bookmark_tag table.
	@try {
		id <FDOCommand> cmd = [mDBConnection newCommand];
		[cmd prepare:@"DELETE FROM bookmark_tag WHERE bookmark_id = ?1"];
		[cmd bindInt64:bookmark_id toParameterNumber:1];
		[cmd executeQuery];
	} @catch(NSException *e) {
		NSLog(@"removePostInternal: Couldn't delete bookmark tags.");
		goto bail;
	}
	
	// Remove bookmark from bookmark table.
	@try {
		id <FDOCommand> cmd = [mDBConnection newCommand];
		[cmd prepare:@"DELETE FROM bookmark WHERE id = ?1"];
		[cmd bindInt64:bookmark_id toParameterNumber:1];
		[cmd executeQuery];
	} @catch(NSException *e) {
		NSLog(@"removePostInternal: Couldn't delete bookmark.");
		goto bail;
	}
		
	// Remove orphan tags (i.e. tags with no associated bookmarks)
	@try {
		id <FDOCommand> cmd = [mDBConnection newCommand];
		[cmd prepare:@"DELETE FROM tag WHERE id NOT IN (SELECT tag_id FROM bookmark_tag)"];
		[cmd executeQuery];
	} @catch(NSException *e) {
		NSLog(@"removePostInternal: Couldn't delete orphan tags.");
		goto bail;
	}
	
	if(useTransactions)
	{
		@try {
			[mDBConnection commitTransaction];
			inTransaction = NO;
		} @catch(NSException *e) {
			NSLog(@"removePostInternal: Could not commit a transaction. %@", e);
			goto bail;
		}
	}
	
bail:
	
	if(useTransactions && inTransaction)
	{
		@try {
			[mDBConnection rollbackTransaction];
		} @catch(NSException *e) {
			NSLog(@"removePostInternal: Could not rollback transaction. %@", e);
		}
	}
}

-(NSArray*)favoriteTags
{
	NSDictionary *db = [self readDatabaseFile];
	NSArray *tags = [db objectForKey:kFavoriteTagsKey];
	NSMutableArray *tagsToReturn = [NSMutableArray array];
	
	NSEnumerator *tagEnum = [tags objectEnumerator];
	NSObject *tagObject = nil;
	while(tagObject = [tagEnum nextObject])
	{
		// Handle new style tag arrays for favorites and old style strings.
		if([tagObject isKindOfClass:[NSArray class]])
			[tagsToReturn addObject:tagObject];
		else
			[tagsToReturn addObject:[NSArray arrayWithObject:tagObject]];
	}
	
	return tagsToReturn;
}

-(void)setFavoriteTags:(NSArray*)tags
{
	NSMutableDictionary *db = [self readDatabaseFile];
	
	if(tags == nil)
		[db removeObjectForKey:kFavoriteTagsKey];
	else
		[db setObject:tags forKey:kFavoriteTagsKey];
	
	[self saveDatabaseFile:db];
}

-(NSMutableDictionary*)readDatabaseFile
{	
	if(mDBCache)
		return mDBCache;
		
	// If the path is set then try reading the database from the file.
	if(mDBPath)
	{
		NSData *plistData = nil;
		
		if([[NSFileManager defaultManager] fileExistsAtPath:mDBPath])
		{
			NSError *error = nil;
			plistData = [NSData dataWithContentsOfFile:mDBPath options:0 error:&error];
		
			if(plistData == nil && error != nil)
				NSLog(@"Error opening DeliciousSafari database. '%@'. Reason: %@", mDBPath, [error localizedDescription]);
		}
		
		if(plistData != nil)
		{
			NSString *strError = nil;
			mDBCache = (NSMutableDictionary*)[NSPropertyListSerialization
											  propertyListFromData:plistData
											  mutabilityOption:NSPropertyListMutableContainersAndLeaves
											  format:NULL
											  errorDescription:&strError];
			
			
			if(mDBCache == nil && strError != nil)
				NSLog(@"Error reading DeliciousSafari database. Reason: %@", strError);
			
			[strError release]; // Docs say you own this (unlike NSError in dataWithContentsOfFile:options:error: call above), so release it.
			
			if(mDBCache != nil && ![mDBCache isKindOfClass:[NSDictionary class]])
				mDBCache = nil;
			
			[mDBCache retain];
		}
	}
		
	// If the path was not set or there was a problem reading the database from the file, then start fresh.
	if(mDBCache == nil)
		mDBCache = [[NSMutableDictionary alloc] init];
	
	return mDBCache;
}

-(void)saveDatabaseFile:(NSDictionary*)database shouldResetCache:(BOOL)shouldResetCache
{
	// If the database path is set, then save this to a file. Otherwise, it
	// is an in memory only database.
	if(mDBPath)
	{
		NSData *plistData = nil;
		NSString *error = nil;
		
		plistData = [NSPropertyListSerialization dataFromPropertyList:database
															   format:NSPropertyListBinaryFormat_v1_0
													 errorDescription:&error];
		
		
		if(plistData)
		{
			// Write atomically to avoid file corruption should the system go down in the middle of writing to disk.
			if(![plistData writeToFile:mDBPath atomically:YES])
			{
				NSLog(@"saveDatabaseFile failed to write DB to file. Using in memory only database (i.e. no local caching)");
			}
		}
		else
		{
			NSLog(@"Error creating binary property list for DeliciousSafari database. %@", error);
			[error release];
		}
	}
	
	if(shouldResetCache)
	{
		[mDBCache release];
		mDBCache = nil;
	}
}

-(void)saveDatabaseFile:(NSDictionary*)database
{
	[self saveDatabaseFile:database shouldResetCache:NO];
}

-(NSArray*)recentPosts:(unsigned int)count
{
	NSArray *result = nil;
	
	@try {
		NSString *sql = [NSString stringWithFormat:@"SELECT * FROM bookmark ORDER BY timeSaved DESC LIMIT %d", count];
		id <FDORecordSet> recordSet = [mDBConnection execute:sql];
		result = [self postsArrayForRecordSet:recordSet];
	}
	@catch (NSException * e) {
		NSLog(@"[DXDeliciousDatabase recentPosts:] - Caught exception. %@", e);
	}
	
	if(result == nil)
		result = [NSArray array];
	
	return result;
}

-(NSString*)stringForKey:(NSString*)key
{
	NSDictionary *db = [self readDatabaseFile];
	id value = [db objectForKey:key];
	if(value == nil || ![value isKindOfClass:[NSString class]])
		value = @"";
	return value;
}

-(void)setString:(NSString*)value forKey:(NSString*)key
{
	NSMutableDictionary *db = [self readDatabaseFile];
	
	if(value == nil)
		[db removeObjectForKey:key];
	else
		[db setObject:value forKey:key];
	
	[self saveDatabaseFile:db];
}

-(BOOL)boolForKey:(NSString*)key withDefaultValue:(BOOL)defaultValue
{
	BOOL value = NO;
	NSDictionary *db = [self readDatabaseFile];
	id objValue = [db objectForKey:key];
	if(objValue == nil || ![objValue isKindOfClass:[NSNumber class]])
		value = defaultValue;
	else
		value = [(NSNumber*)objValue boolValue];
	
	return value;
}

-(BOOL)boolForKey:(NSString*)key
{
	return [self boolForKey:key withDefaultValue:NO];
}

-(void)setBool:(BOOL)value forKey:(NSString*)key
{
	NSMutableDictionary *db = [self readDatabaseFile];
	
	[db setObject:[NSNumber numberWithBool:value] forKey:key];
	
	[self saveDatabaseFile:db];
}

-(int)intForKey:(NSString*)key withDefaultValue:(int)defaultValue
{
	NSDictionary *db = [self readDatabaseFile];
	NSObject* value = [db objectForKey:key];
	int result;
	
	if(value == nil || ![value isKindOfClass:[NSNumber class]])
		result = defaultValue;
	else
		result = [(NSNumber*)value intValue];
	
	return result;	
}

-(int)intForKey:(NSString*)key
{
	return [self intForKey:key withDefaultValue:0];
}

-(void)setInt:(int)value forKey:(NSString*)key
{
	NSMutableDictionary *db = [self readDatabaseFile];
	
	[db setObject:[NSNumber numberWithInt:value] forKey:key];
	
	[self saveDatabaseFile:db];	
}

-(double)doubleForKey:(NSString*)key withDefaultValue:(double)defaultValue
{
	NSDictionary *db = [self readDatabaseFile];
	NSObject* value = [db objectForKey:key];
	double result;
	
	if(value == nil || ![value isKindOfClass:[NSNumber class]])
		result = defaultValue;
	else
		result = [(NSNumber*)value doubleValue];
	
	return result;	
}

-(void)setDouble:(double)value forKey:(NSString*)key
{
	NSMutableDictionary *db = [self readDatabaseFile];
	
	[db setObject:[NSNumber numberWithDouble:value] forKey:key];
	
	[self saveDatabaseFile:db];
}


-(NSDate*)dateForKey:(NSString*)key
{
	NSDictionary *db = [self readDatabaseFile];
	id value = [db objectForKey:key];
	if(value != nil && ![value isKindOfClass:[NSDate class]])
	{
		NSLog(@"Didn't get date for key %@", key);
		value = nil;
	}
	
	return value;
}

-(void)setDate:(NSDate*)value forKey:(NSString*)key
{
	NSMutableDictionary *db = [self readDatabaseFile];
	
	if(value == nil)
		[db removeObjectForKey:key];
	else
		[db setObject:value forKey:key];
	
	[self saveDatabaseFile:db];
}

-(NSString*)username
{
	return [self stringForKey:kUsernameKey];
}

-(void)setUsername:(NSString*)username
{
	[self setString:username forKey:kUsernameKey];
}

-(BOOL)isLoggedIn
{
	return [[self username] length] > 0;
}

#ifdef DELICIOUSSAFARI_PLUGIN_TARGET
-(void)startFaviconUpdateThread:(NSObject <DXDeliciousDatabaseFaviconCallback>*)callbackObject
{
	//NSLog(@"startFaviconUpdateThread called");
	
	// Create a copy of the database to work on so we won't have to worry about thread protecting the data structure.
	NSDictionary *dbCopy = [[[self readDatabaseFile] copy] autorelease];
	NSDictionary *threadArguments = [NSDictionary dictionaryWithObjectsAndKeys:dbCopy, @"dbCopy", callbackObject, @"callbackObject", nil];
	[NSThread detachNewThreadSelector:@selector(faviconUpdateThread:) toTarget:self withObject:threadArguments];
}

-(void)faviconUpdateThread:(id)threadArguments
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	//NSLog(@"faviconUpdateThread called");
	
	NSDictionary *args = (NSDictionary*)threadArguments;
	id callbackObject = [args objectForKey:@"callbackObject"];
	NSDictionary *dbCopy = [args objectForKey:@"dbCopy"];
	
	if(![callbackObject conformsToProtocol:@protocol(DXDeliciousDatabaseFaviconCallback)])
	{
		NSLog(@"Object given to startFaviconUpdateThread for callbackObject does not conform to DXDeliciousDatabaseFaviconCallback protocol.");
		goto bail;
	}
	
	if(![dbCopy isKindOfClass:[NSDictionary class]])
	{
		NSLog(@"Object given to faviconUpdateThread for dbCacheCopy is not an NSDictionary");
		goto bail;
	}
	
	BOOL rebuildFaviconDatabase = NO;
	NSDate *now = [NSDate date];
	NSDate *nextRebuildDate = [dbCopy objectForKey:kFaviconDatabaseNextRebuildKey];
	if(nextRebuildDate == nil || [now laterDate:nextRebuildDate] == now )
	{
		rebuildFaviconDatabase = YES;
		nextRebuildDate = now;
	}
	
	NSMutableSet *faviconHostSkipList = nil;
	
	if(!rebuildFaviconDatabase)
	{
		NSArray *faviconHostSkipListArray = [dbCopy objectForKey:kFaviconHostSkipKey];
		if(faviconHostSkipListArray != nil)
			faviconHostSkipList = [NSMutableSet setWithArray:faviconHostSkipListArray];
	}
		
	if(faviconHostSkipList == nil)
		faviconHostSkipList = [NSMutableSet set];
	
	NSMutableSet *faviconURLs = [NSMutableSet set]; // The set of URLs that will be processed by the thread pool.
	DXFaviconDatabase *faviconDatabase = [DXFaviconDatabase defaultDatabase];
	
	id <FDORecordSet> allPostsRecordSet = nil;
	
	@try {
		id <FDOCommand> command = [mDBConnection newCommand];
		[command prepare:@"SELECT * FROM bookmark ORDER BY timeSaved DESC"]; // Start with newest first so icons for recent menu show up fast.
		
		allPostsRecordSet = [command executeQuery];
	}
	@catch (NSException * e) {
		NSLog(@"[DXDelicoiusDatabase faviconUpdateThread:] Error getting bookmarks. Will not be able to download favicons. Error: %@", e);
		goto bail;
	}	
	
	if(!allPostsRecordSet)
	{
		NSLog(@"[DXDeliciousDatabase faviconUpdateThread:] all posts recordset is nil. Will not be able to download favicons.");
		goto bail;
	}
	
	@try
	{
		// TODO: It is possible the record set gets closed while processing here as a result of a begin/commit or rollback
		// from another thread (i.e. the main thread). However, the consequences of that are minor: the favicon is not update
		// until the favicon thread is kicked off again. I will ignore this problem for now to keep work off the main thread.
		for(; ![allPostsRecordSet isEOF]; [allPostsRecordSet moveNext])
		{
			NSAutoreleasePool *innerPool = [[NSAutoreleasePool alloc] init];
			
			NSDictionary *post = [self postDictionaryFromCurrentRecordSet:allPostsRecordSet];
			
			NSString *href = [post objectForKey:kDXPostURLKey];
			if(href == nil)
				goto nextPost;
			
			NSURL *hrefURL = [NSURL URLWithString:href];
			if(hrefURL == nil)
			{
				NSLog(@"Skipping favicon lookup for malformed URL %@.", href);
				goto nextPost;
			}
			
			NSString *host = [hrefURL host];
			if(host != nil && ![faviconDatabase faviconExistsForURLString:href] && ![faviconHostSkipList containsObject:host])
			{
				NSString *faviconURLString = [NSString stringWithFormat:@"http://%@/favicon.ico", [hrefURL host]];
				NSURL *faviconURL = [NSURL URLWithString:faviconURLString];
				
				// NSLog(@"Trying to get favicon from %@", faviconURLString);
				
				if(faviconURL == nil)
				{
					NSLog(@"Skipping favicon lookup for malformed favicon URL %@.", faviconURLString);
					goto nextPost;
				}
				
				// Add this favicon URL to the set the thread pool will processes.
				[faviconURLs addObject:faviconURL];
			}
			
		nextPost:
			[innerPool release];
		}
	}
	@catch (NSException * e) {
		NSLog(@"[DXDelicoiusDatabase faviconUpdateThread:] Error walking through post record set. Will not be able to download favicons. Error: %@", e);
		goto bail;
	}
	
	// Download and process the favicons and then merge them back into the main favicon database.
	BOOL anyEntriesAdded = NO;
	DXFaviconDownloader *downloader = [[[DXFaviconDownloader alloc] initWithURLArray:[faviconURLs allObjects]] autorelease];
	[downloader waitForDownloadsToComplete];
	anyEntriesAdded = [downloader successfulDownloadCount] > 0;

	NSArray *faviconFailures = [downloader failures];
	if(faviconFailures)
		[faviconHostSkipList addObjectsFromArray:faviconFailures];
	
	
	// Inform the callback of the results.
	NSDictionary *callbackArgs = [NSDictionary dictionaryWithObjectsAndKeys:
								  [faviconHostSkipList allObjects], @"faviconFailures",
								  [NSNumber numberWithBool:rebuildFaviconDatabase], @"shouldRebuild",
								  callbackObject, @"callbackObject",
								  [NSNumber numberWithBool:anyEntriesAdded], @"anyEntriesAdded",
								  nil];
	
	[self performSelectorOnMainThread:@selector(faviconDatabaseUpdatedMainThreadCallback:) withObject:callbackArgs waitUntilDone:NO];
		
bail:
	[pool release];
}

-(void)faviconDatabaseUpdatedMainThreadCallback:(NSDictionary*)callbackArgs
{
	//NSLog(@"faviconDatabaseUpdatedMainThreadCallback called");
	
	NSArray *faviconFailures = [callbackArgs objectForKey:@"faviconFailures"];
	BOOL shouldRebuild = [(NSNumber*)[callbackArgs objectForKey:@"shouldRebuild"] boolValue];
	id <DXDeliciousDatabaseFaviconCallback> callbackObject = [callbackArgs objectForKey:@"callbackObject"];
	BOOL anyEntriesAdded = [(NSNumber*)[callbackArgs objectForKey:@"anyEntriesAdded"] boolValue];

	NSMutableDictionary *db = [self readDatabaseFile];
		
	[db setObject:faviconFailures forKey:kFaviconHostSkipKey];
	
	
	if(shouldRebuild)
	{
		const NSTimeInterval kThirtyDaysInSeconds = 60.0 * 60.0 * 24.0 * 30.0;
		[db setObject:[NSDate dateWithTimeIntervalSinceNow:kThirtyDaysInSeconds] forKey:kFaviconDatabaseNextRebuildKey];
	}
	
	[self saveDatabaseFile:db];
	
	[callbackObject dxDeliciousDatabaseFaviconCallback:anyEntriesAdded];
}
#endif

-(NSString*)itemIdentifierKeyFromItemIdentifier:(NSString*)itemIdentifier
{
	return [@"HasAddedToolbarItem_" stringByAppendingString:itemIdentifier];
}

-(BOOL)hasAddedToolbarItemIdentifier:(NSString*)itemIdentifier
{
	return [self boolForKey:[self itemIdentifierKeyFromItemIdentifier:itemIdentifier]];
}

-(void)setHasAddedToolbarItemIdentifier:(NSString*)itemIdentifier
{
	[self setBool:YES forKey:[self itemIdentifierKeyFromItemIdentifier:itemIdentifier]];
}

-(BOOL)shouldShareDefaultValue
{	
	BOOL result = YES;
	NSDictionary *db = [self readDatabaseFile];
	NSNumber* resultObj = [db objectForKey:kShouldShareByDefaultKey];
	if(resultObj != nil && [resultObj isKindOfClass:[NSNumber class]])
		result = [resultObj boolValue];
	return result;
}

-(void)removePerUserData
{
	[self setLastUpdated:nil];
	[self updateDatabaseWithDeliciousAPIPosts:nil];
#ifdef DELICIOUSSAFARI_PLUGIN_TARGET
// TODO: #warning This is not implemented for the plug-in target because it does not remove the favicon data.
#endif
}

-(void)cleanupObsoleteDatabaseFields
{
	NSMutableDictionary *db = [self readDatabaseFile];
	
	[db removeObjectForKey:kPostsKeyOBSOLETE];
	[db removeObjectForKey:kTagsKeyOBSOLETE];
	
	[self saveDatabaseFile:db];
}

-(BOOL)shouldFetchBookmarksManually
{
	return [self boolForKey:kShouldFetchManually];
}

-(void)setShouldFetchBookmarksManually:(BOOL)shouldFetchManually
{
	[self setBool:shouldFetchManually forKey:kShouldFetchManually];
}

#ifdef DELICIOUSSAFARI_PLUGIN_TARGET
-(int)databaseVersion
{
	return [self intForKey:kDatabaseVersionKey];
}

-(void)setDatabaseVersion:(int)newVersion
{
	[self setInt:newVersion forKey:kDatabaseVersionKey];
}
#endif

-(NSArray*)findTagsBeginningWith:(NSString*)searchString withResultLimit:(NSUInteger)limit
{
	NSMutableArray *result = [NSMutableArray array];
	
	@try {
		id <FDOCommand> tagQuery = [mDBConnection newCommand];
		[tagQuery prepare:[NSString stringWithFormat:@"SELECT name_display FROM tag WHERE name_lower LIKE ?1 LIMIT %lu", (unsigned long)limit]];
		[tagQuery bindString:[searchString stringByAppendingString:@"%"] toParameterNumber:1];
		id <FDORecordSet> recordSet = [tagQuery executeQuery];
		
		if(recordSet)
		{
			for(; ![recordSet isEOF]; [recordSet moveNext])
				[result addObject:[recordSet stringValueForColumnNumber:0]];
		}
		
	}
	@catch (NSException * e) {
		NSLog(@"Error reading tag list in search. %@", e);
	}
	
	return result;
}

-(NSArray*)findBookmarksWithTitlesContaining:(NSString*)searchString withResultLimit:(NSUInteger)limit
{
	NSArray *result = nil;
	
	@try {			
		id <FDOCommand> bookmarkQuery = [mDBConnection newCommand];
		[bookmarkQuery prepare:[NSString stringWithFormat:@"SELECT * FROM bookmark WHERE title LIKE ?1 LIMIT %lu", (unsigned long)limit]];
		[bookmarkQuery bindString:[NSString stringWithFormat:@"%%%@%%", searchString] toParameterNumber:1];
		id <FDORecordSet> recordSet = [bookmarkQuery executeQuery];
		result = [self postsArrayForRecordSet:recordSet];		
	}
	@catch (NSException * e) {
		NSLog(@"Error reading bookmark list in search. %@", e);
	}
	
	if(result == nil)
		result = [NSArray array];
	
	return result;
}

@end
