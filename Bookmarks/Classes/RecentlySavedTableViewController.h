//
//  RecentlySavedTableViewController.h
//  Bookmarks
//
//  Created by Doug on 10/7/08.
//  Copyright 2008 Douglas Richardson. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BookmarkListViewController.h"


@interface RecentlySavedTableViewController : BookmarkListViewController {
	NSUInteger _numberOfRecentPosts;
}

- (id)initWithNumberOfRecentPosts:(NSUInteger)numberOfRecentPosts;

@end
