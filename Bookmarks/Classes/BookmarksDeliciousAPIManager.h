//
//  DeliciousAPIDelegate.h
//  Bookmarks
//
//  Created by Doug on 10/14/08.
//  Copyright 2008 Douglas Richardson. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DXDeliciousAPI.h"
#import "DXDeliciousDatabase.h"
#import "DeliciousSafariDefinitions.h"

@interface BookmarksDeliciousAPIManager : DXDeliciousAPI <DXDeliciousAPIDelegate> {
	NSDate *_savedLastUpdatedTime;
	BOOL _isUpdating;
	BOOL _isUserLoggedIn;
	DXDeliciousDatabase *_database;
}

+(BookmarksDeliciousAPIManager*)sharedManager;

-(id)initWithUserAgent:(NSString*)userAgent withDatabase:(DXDeliciousDatabase*)database;

@property (nonatomic) BOOL isUpdating;
@property (nonatomic) BOOL isUserLoggedIn;

@property (nonatomic, retain) DXDeliciousDatabase* database;

-(void)logout;

@end
