//
//  DXPreferences.h
//  DeliciousSafari
//
//  Created by Doug on 3/14/09.
//  Copyright 2009 Douglas Richardson. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DXDeliciousDatabase;

@interface DXPreferences : NSObject {
	DXDeliciousDatabase *_database;
}

+(DXPreferences*)sharedPreferences;

-(BOOL)shouldDownloadFavicons;
-(void)setShouldDownloadFavicons:(BOOL)shouldDownloadFavicons;

-(BOOL)shouldCheckForBookmarksAtStart;
-(void)setShouldCheckForBookmarksAtStart:(BOOL)shouldCheck;

-(BOOL)shouldCheckForBookmarksAtInterval;
-(void)setShouldCheckForBookmarksAtInterval:(BOOL)shouldCheck;

-(NSTimeInterval)bookmarkCheckInterval;
-(void)setBookmarkCheckInterval:(NSTimeInterval)checkInterval;

-(BOOL)shouldShareBookmarksByDefault;
-(void)setShouldShareBookmarksByDefault:(BOOL)shouldSaveByDefault;

-(void)resetToDefaults;

@end
